# N0.V4 — All Endpoints Reference

> Keep this file private. Update with your actual API keys and IPs.
> Syncs to Markor via: `bash ~/android-cowork/audit/markor_sync.sh`

---

## On-Device (Razr Ultra 25)

### Omni Neural 4B — Local Edge Model
```
http://localhost:11434/v1/chat/completions
```
- Type: Ollama / llama.cpp
- Hardware: Snapdragon 8 Elite (Vulkan GPU acceleration)
- Offline: Yes
- Model file: `~/models/omni-neural-4b.gguf`

### Claude Code CLI
```
Termux command: claude
```
- Not an HTTP endpoint — runs as CLI process
- Routes through Vertex AI when `vertex_env.sh` is sourced
- Logs to: `~/.reasoning-bank/sessions.jsonl`

### Voice Bridge
```
Termux command: python3 ~/android-cowork/voice/voice_bridge.py
```
- STT: Whisper Tiny EN (CPU / ARM Neon)
- TTS: Kokoro-82M (Vulkan) → Piper fallback → termux-tts-speak

---

## Jetson Hub (Jetson Orin Nano Super)

### Jetson Ollama (7B+ models)
```
http://jetson.local:11434/api/chat
http://[TAILSCALE-IP]:11434/api/chat
```
- Type: Ollama with CUDA acceleration
- Hardware: 1024-core Ampere GPU, 40 TOPS
- Runs: Docker CLI #1 and #2 models

### PTL MCP Server (Prompt Translation Layer)
```
http://jetson.local:8080
http://[TAILSCALE-IP]:8080
```
- Cleans STT output before sending to frontier
- Logs every cleaned prompt to Postgres
- MCP tools: `translate_prompt`, `get_ptl_stats`

### Jetson Postgres + pgvector
```
postgresql://nova:PASSWORD@jetson.local:5432/nova_brain
```
- Self-hosted (no Supabase dependency)
- Stores: PTL logs, wiki index, training pairs
- pgvector for semantic search

### Jetson SSH (for Claude Code remote)
```
ssh derek@jetson.local
ssh derek@[TAILSCALE-IP]
```

---

## Cloud — Frontier Models

### Claude via Vertex AI (your GCP credits)
```
https://api.anthropic.com/v1/messages
```
- Activate: `source ~/android-cowork/config/vertex_env.sh`
- Sonnet: `claude-sonnet-4-6`
- Haiku: `claude-haiku-4-5`
- Opus: `claude-opus-4-7`

### Gemini Flash (fast / cheap)
```
https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent
```
- API key: `GOOGLE_API_KEY` env var
- Use for: PTL fallback, quick classification

### Gemini Pro (heavy reasoning)
```
https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent
```

### Perplexity (web search)
```
https://api.perplexity.ai/chat/completions
```
- Model: `llama-3.1-sonar-large-128k-online`
- API key: `PERPLEXITY_API_KEY` env var

---

## Memory & Brain

### OB1 — Supabase (current)
```
https://YOUR-PROJECT.supabase.co/rest/v1/thoughts
```
- Key: `SUPABASE_SERVICE_KEY` env var
- MCP tools: capture_thought, search_thoughts, recall_context

### Nova Brain — Jetson Postgres (self-hosted, Phase 2)
```
postgresql://nova:PASSWORD@jetson.local:5432/nova_brain
```
- Replaces Supabase when Jetson is operational
- Keeps all data on your hardware

---

## Horizons UI (PWA)
```
https://cdn.jsdelivr.net/gh/c10vis-poem/claude-skills@claude/busy-wright-OKBXH/horizons/index.html
```
- Add to Home Screen in Chrome for standalone install
- Manages all endpoint toggles
- Toggle 1: Artifact API ON
- Toggle 2: Artifact API OFF (external PWAs)
- Toggle 3: Pure edge (Omni Neural only)

---

## Wiki & Logs (local only — never pushed to public GitHub)
```
/nova/logs/          ← raw interaction logs (Razr)
/nova/wiki/          ← compiled knowledge (Jetson)
/nova/config/        ← schema files
~/storage/shared/N0VA/  ← Markor/Obsidian accessible
```
