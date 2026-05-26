---
name: android-cowork
description: >
  Android AI Workstation — run Claude Code, SuperClaude (30 commands, 20 agents),
  and full agentic pipelines on Android via Termux. Routes model calls through
  Vertex AI (use your GCP credits), runs Whisper STT and Piper TTS fully offline,
  connects to OB1 Open Brain for persistent vector memory, and feeds ReasoningBank
  so every session makes the agent smarter. Use when: setting up Android as an AI
  cowork device, enabling voice-driven Claude interaction on mobile, wiring Vertex AI
  credits for API calls, connecting OB1 memory, or running background agentic tasks.
tools: Bash, Read, Write, Edit
---

# Android AI Co-Work Skill

Turn any Android device into a full AI workstation:

| Layer | Technology | Purpose |
|-------|-----------|--------|
| Runtime | Termux (Linux on Android) | Run Node.js, Python, shell scripts |
| AI CLI | Claude Code + SuperClaude | 30 commands, 20 specialist agents |
| Model API | Vertex AI (GCP) | Use your 1200+ credits, not Anthropic quota |
| STT | Whisper.cpp (local) | Offline speech recognition, no cloud |
| TTS | Piper TTS (local) | Offline neural voice synthesis |
| Memory | OB1 Open Brain (Supabase) | Persistent thoughts across all sessions |
| Learning | ReasoningBank | Agent self-improves from trajectory memory |

## Architecture

```
┌────────────────────────────────────────────────────┐
│                  ANDROID DEVICE                     │
│  Termux                                             │
│  ├── Claude Code CLI  (npm i -g @anthropic-ai/...)  │
│  ├── SuperClaude      (pipx install superclaude)    │
│  ├── Whisper.cpp      (offline STT)                 │
│  ├── Piper TTS        (offline neural voice)        │
│  └── voice_bridge.py (mic → Claude → speaker)      │
│                                                     │
│  Chrome → claude.ai/code  (web sessions)            │
└───────────────────┬────────────────────────────────┘
                    │  CLAUDE_CODE_USE_VERTEX=1
┌───────────────────▼────────────────────────────────┐
│              GOOGLE CLOUD PLATFORM                  │
│  Vertex AI                                          │
│  ├── Claude 3.7 Sonnet  (via Anthropic on Vertex)  │
│  └── Gemini 2.5 Flash/Pro  (for lighter tasks)     │
└───────────────────┬────────────────────────────────┘
                    │  MCP + pgvector
┌───────────────────▼────────────────────────────────┐
│         OB1 OPEN BRAIN + REASONINGBANK              │
│  ├── Supabase (vector search, thought storage)      │
│  ├── OB1 MCP server  (recall, capture, search)      │
│  └── ReasoningBank  (trajectory → persistent mem)   │
└────────────────────────────────────────────────────┘
```

## Quick Reference

| Want to... | Do this |
|------------|--------|
| First-time setup | Run scripts in `setup/` numbered 1→4 |
| Talk to Claude by voice | `python3 ~/android-cowork/voice/voice_bridge.py` |
| Run an agentic task | `~/android-cowork/agent/android_task_runner.sh "task"` |
| Use GCP credits | `source ~/android-cowork/config/vertex_env.sh` |
| Check brain memory | `/sc:research` then ask about past context |
| Add to OB1 brain | `termux-clipboard-get \| python3 capture_thought.py` |

## Workflow Decision Tree

**Setting up for the first time?**
→ Follow `SETUP_GUIDE.md` top to bottom (~30 min)
→ Run `setup/1_termux_bootstrap.sh` first

**Want voice interaction?**
→ `python3 voice/voice_bridge.py`
→ Press Enter to start speaking, Enter again to stop
→ Claude responds via Piper (local) or Android TTS (fallback)

**Running background agentic tasks?**
→ `agent/android_task_runner.sh "your task description"`
→ Works while phone screen is off
→ Gets Termux notification when done

**Want to save GCP credits and offload from Anthropic quota?**
→ `source config/vertex_env.sh` before any Claude Code session
→ All API calls route through Vertex AI automatically

**Session finished — store what was learned?**
→ Automatic via the Stop hook in `config/claude_settings_android.json`
→ Or manually: `python3 agent/reasoning_capture.py`

## Core Principles

1. **Offline-first voice** — STT and TTS never touch the cloud
2. **Credits-aware routing** — Vertex AI for GCP budget, direct API as fallback
3. **Brain persistence** — OB1 stores all context; nothing is lost between sessions
4. **Self-improving** — ReasoningBank learns from every success and failure
5. **SuperClaude-enhanced** — Full 30-command, 20-agent system always available
