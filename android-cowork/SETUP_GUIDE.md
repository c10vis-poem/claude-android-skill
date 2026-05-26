# Android AI Workstation — Complete Setup Guide

Estimated time: 30–45 minutes on a modern Android device (2021+).

## Prerequisites

### Hardware
- Android 10+ (ARM64 / aarch64)
- 4 GB RAM minimum, 8 GB recommended for Whisper
- 8 GB free storage (models + tools)
- Stable internet for initial downloads (offline after setup)

### Accounts
- **Google Cloud** account with Vertex AI enabled and billing
- **Claude.ai** Pro account (or Anthropic API key as fallback)
- **Supabase** project for OB1 brain (free tier works)
- **GitHub** account (for cloning repos)

### Apps to Install First
1. **Termux** — install from [F-Droid](https://f-droid.org/packages/com.termux/) (NOT Play Store — the Play Store version is outdated)
2. **Termux:API** — from [F-Droid](https://f-droid.org/packages/com.termux.api/)
3. Grant Termux:API microphone and notification permissions in Android Settings

---

## Step 1 — Termux Bootstrap

Open Termux and run:

```bash
curl -fsSL https://raw.githubusercontent.com/c10vis-poem/claude-android-skill/claude/busy-wright-OKBXH/android-cowork/setup/1_termux_bootstrap.sh | bash
```

Or copy the script and run it. This installs:
- Core packages (git, curl, wget, python, nodejs-lts, cmake, clang)
- Termux:API bridge (`pkg install termux-api`)
- pipx for Python tool isolation
- Storage permission grant

---

## Step 2 — Claude Code + SuperClaude

```bash
bash ~/android-cowork/setup/2_claude_superclaude.sh
```

This installs:
- Claude Code CLI: `npm install -g @anthropic-ai/claude-code`
- SuperClaude framework: `pipx install superclaude && superclaude install`
- All 30 slash commands + 20 agents in `~/.claude/`

After running, set your API key (used as fallback when Vertex is not set):
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

---

## Step 3 — Vertex AI Authentication (Use Your GCP Credits)

```bash
bash ~/android-cowork/setup/3_vertex_ai_auth.sh
```

This:
1. Installs Google Cloud SDK in Termux
2. Runs `gcloud auth application-default login` (opens browser)
3. Sets `CLAUDE_CODE_USE_VERTEX=1` in your shell profile
4. Writes `~/android-cowork/config/vertex_env.sh` with your project settings

Edit `config/vertex_env.sh` to fill in your project ID and region:
```bash
export ANTHROPIC_VERTEX_PROJECT_ID="your-actual-project-id"
export CLOUD_ML_REGION="us-east5"   # us-east5 has best Claude availability
```

To activate Vertex AI routing for any session:
```bash
source ~/android-cowork/config/vertex_env.sh
claude  # Now uses your GCP credits
```

---

## Step 4 — Local Voice (Whisper STT + Piper TTS)

```bash
bash ~/android-cowork/setup/4_voice_setup.sh
```

This builds:
- **Whisper.cpp** from source (ARM64 optimized, ~10 min build)
  - Downloads `ggml-base.en.bin` model (142 MB, fast on mobile)
  - Optionally `ggml-small.en.bin` (466 MB, more accurate)
- **Piper TTS** pre-compiled binary for aarch64 (no build needed)
  - Downloads `en_US-ryan-high` voice model (60 MB, natural sounding)

Test voice round-trip:
```bash
python3 ~/android-cowork/voice/voice_bridge.py --test
```

---

## Step 5 — OB1 Open Brain Connection

You need a Supabase project with OB1 schema. See the [OB1 setup guide](https://github.com/c10vis-poem/ob1/blob/main/docs/01-getting-started.md).

Once you have Supabase credentials, set them:
```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_SERVICE_KEY="your-service-role-key"
```

Install and configure the OB1 MCP server:
```bash
npm install -g @ob1/mcp-server   # or local install from the ob1 repo
```

Copy the MCP config into Claude Code's project settings:
```bash
mkdir -p ~/.claude
cp ~/android-cowork/config/claude_settings_android.json ~/.claude/settings.json
```

Edit `~/.claude/settings.json` to fill in your OB1 server path and Supabase credentials.

---

## Step 6 — ReasoningBank Memory Hook

The Stop hook in `config/claude_settings_android.json` automatically calls
`agent/reasoning_capture.py` at the end of every Claude Code session.
This stores session summaries and learned patterns into OB1.

To test manually:
```bash
python3 ~/android-cowork/agent/reasoning_capture.py --dry-run
```

---

## Daily Usage

### Voice Mode (Hands-Free)
```bash
source ~/android-cowork/config/vertex_env.sh
python3 ~/android-cowork/voice/voice_bridge.py
```
Press **Enter** → speak → press **Enter** again to stop recording.
Claude responds via Piper TTS. Say "stop" or "exit" to quit.

### Standard CLI Mode
```bash
source ~/android-cowork/config/vertex_env.sh
claude  # Full Claude Code with SuperClaude
```

Super-Claude commands always available:
- `/sc:implement` — code generation with confidence checks
- `/sc:research` — web research + OB1 brain recall
- `/sc:pm` — project management and task breakdown
- `@android-cowork-agent` — Android-specific agentic help

### Agentic Background Task
```bash
~/android-cowork/agent/android_task_runner.sh "refactor the auth module and run tests"
# Phone notification when complete
```

### Claude.ai Web (No Terminal Needed)
Open Chrome → `claude.ai/code` — full Claude Code experience in browser,
no Termux needed. Uses your Pro account.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `command not found: claude` | Run `npm install -g @anthropic-ai/claude-code` and add `~/.npm-global/bin` to PATH |
| Vertex AI auth fails | Re-run `gcloud auth application-default login` in Termux |
| Microphone not working | Check Termux:API app is installed + microphone permission granted |
| Whisper build fails | Try `pkg install cmake clang` then re-run build |
| Piper binary fails | Re-download aarch64 release from GitHub |
| OB1 MCP not connecting | Verify SUPABASE_URL and key are correct; check Node version ≥18 |

---

## Resource Usage

| Component | RAM | Storage | Battery |
|-----------|-----|---------|--------|
| Claude Code CLI | ~80 MB | 200 MB | Low |
| Whisper base.en | ~200 MB | 142 MB | Medium (inference) |
| Piper TTS | ~100 MB | 60 MB | Low |
| OB1 MCP server | ~50 MB | — | Low |
| **Total idle** | ~430 MB | ~400 MB | Low |
