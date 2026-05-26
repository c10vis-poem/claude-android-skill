#!/bin/bash
# Docker CLI #1 — Daily Driver (runs on Jetson Orin Nano Super)
# Reads new log entries, detects patterns via local Jetson model
# Output feeds Docker CLI #2 for audit

NOVA="$HOME/nova"
LOGS="$NOVA/logs/interaction_logs.jsonl"
OUTPUT="$NOVA/logs/cli1_output_$(date +%Y-%m-%d).jsonl"
JETSON_MODEL="${JETSON_MODEL:-llama3:8b}"
OLLAMA_URL="http://localhost:11434/api/chat"

echo "Docker CLI #1 — $(date)"
echo "Model: $JETSON_MODEL"
echo ""

if [ ! -f "$LOGS" ]; then
  echo "No interaction logs found at $LOGS"
  exit 0
fi

# Get today's entries
TODAY=$(date +%Y-%m-%d)
ENTRIES=$(grep "$TODAY" "$LOGS" 2>/dev/null || echo "")

if [ -z "$ENTRIES" ]; then
  echo "No entries for $TODAY"
  exit 0
fi

COUNT=$(echo "$ENTRIES" | wc -l)
echo "Processing $COUNT entries from $TODAY"

# Send to local Jetson model for pattern detection
python3 - << PYEOF
import json, requests, sys
from datetime import datetime

entries_raw = """$ENTRIES"""
entries = []
for line in entries_raw.strip().split('\n'):
    try:
        entries.append(json.loads(line))
    except:
        pass

if not entries:
    print('No valid entries to process')
    sys.exit(0)

# Summarize for pattern detection
summary = '\n'.join([
    f"User: {e.get('user','')[:100]}\nResponse: {e.get('response','')[:100]}\nEndpoint: {e.get('endpoint','')}"
    for e in entries[:20]  # Cap at 20 to avoid context overflow
])

prompt = f"""Analyze these {len(entries)} AI interactions for patterns.
Focus on: failure types, routing decisions, user corrections, quality issues.
Return JSON with: patterns[], failure_flags[], quality_score (0-1), notes.

Interactions:
{summary}"""

try:
    resp = requests.post('$OLLAMA_URL', json={
        'model': '$JETSON_MODEL',
        'messages': [{'role': 'user', 'content': prompt}],
        'stream': False
    }, timeout=120)
    
    result = resp.json().get('message', {}).get('content', '')
    
    output = {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'date': '$TODAY',
        'entries_analyzed': len(entries),
        'analysis': result,
        'status': 'complete'
    }
except Exception as e:
    output = {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'date': '$TODAY',
        'entries_analyzed': len(entries),
        'analysis': None,
        'error': str(e),
        'status': 'error'
    }

with open('$OUTPUT', 'a') as f:
    f.write(json.dumps(output) + '\n')

print(f"CLI #1 output written to $OUTPUT")
PYEOF
