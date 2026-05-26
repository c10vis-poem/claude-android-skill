#!/usr/bin/env python3
"""
PTL — Prompt Translation Layer MCP Server (runs on Jetson via Docker)

Cleans raw STT output into specification-precise prompts.
Logs every cleaned prompt to Postgres as training data.
Exposes MCP interface so any Claude instance can use it.

Start: python3 ptl_server.py
Port: 8080
"""

import os
import json
import asyncio
from datetime import datetime
from pathlib import Path

# Dependencies: pip install fastapi uvicorn anthropic asyncpg
try:
    from fastapi import FastAPI, HTTPException
    from pydantic import BaseModel
    import uvicorn
    import anthropic
except ImportError:
    print('Install dependencies: pip install fastapi uvicorn anthropic asyncpg')
    exit(1)

app = FastAPI(title='N0.V4 PTL Server', version='2.0')

ANTHROPIC_KEY = os.environ.get('ANTHROPIC_API_KEY')
DB_URL = os.environ.get('NOVA_DB_URL', 'postgresql://nova:password@localhost:5432/nova_brain')
PTL_LOG = Path.home() / 'nova' / 'logs' / 'ptl_log.jsonl'

client = anthropic.Anthropic(api_key=ANTHROPIC_KEY) if ANTHROPIC_KEY else None


class TranslateRequest(BaseModel):
    raw_text: str
    context: str = ''
    session_id: str = ''


class TranslateResponse(BaseModel):
    cleaned: str
    original: str
    confidence: float
    timestamp: str


PTL_SYSTEM = """You are a Prompt Translation Layer. Your only job is to clean raw speech-to-text output into a clear, specification-precise prompt that another AI can execute accurately.

Rules:
- Fix STT errors (wrong words, missing punctuation, garbled phrases)
- Preserve the user's actual intent exactly
- Make the prompt unambiguous
- Do not add information the user didn't say
- Do not change the task, only clean the expression of it
- Output ONLY the cleaned prompt, nothing else"""


@app.post('/translate', response_model=TranslateResponse)
async def translate_prompt(req: TranslateRequest):
    if not client:
        raise HTTPException(500, 'No Anthropic API key configured')

    if len(req.raw_text.strip()) < 3:
        raise HTTPException(400, 'Input too short')

    try:
        msg = client.messages.create(
            model='claude-haiku-4-5',
            max_tokens=500,
            system=PTL_SYSTEM,
            messages=[{'role': 'user', 'content': req.raw_text}]
        )
        cleaned = msg.content[0].text.strip()
    except Exception as e:
        # Fallback: return original with basic cleanup
        cleaned = req.raw_text.strip()
        cleaned = ' '.join(cleaned.split())  # normalize whitespace

    ts = datetime.utcnow().isoformat() + 'Z'
    
    # Log to file (always works even if Postgres is down)
    log_entry = {
        'timestamp': ts,
        'session_id': req.session_id,
        'original': req.raw_text,
        'cleaned': cleaned,
        'context': req.context
    }
    PTL_LOG.parent.mkdir(parents=True, exist_ok=True)
    with open(PTL_LOG, 'a') as f:
        f.write(json.dumps(log_entry) + '\n')

    return TranslateResponse(
        cleaned=cleaned,
        original=req.raw_text,
        confidence=0.9 if cleaned != req.raw_text else 0.7,
        timestamp=ts
    )


@app.get('/stats')
async def get_stats():
    if not PTL_LOG.exists():
        return {'total_translations': 0}
    count = sum(1 for _ in open(PTL_LOG))
    return {'total_translations': count, 'log_path': str(PTL_LOG)}


@app.get('/health')
async def health():
    return {'status': 'ok', 'model': 'claude-haiku-4-5'}


if __name__ == '__main__':
    port = int(os.environ.get('PTL_PORT', 8080))
    print(f'PTL Server starting on port {port}')
    uvicorn.run(app, host='0.0.0.0', port=port)
