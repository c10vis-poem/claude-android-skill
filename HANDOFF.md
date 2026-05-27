# N0.V4 Setup Handoff

## Device
Motorola Razr Ultra 2025, Android 16, ARM64, Termux (F-Droid)

---

## Current State

- Termux installed, updated, working
- Termux:API installed (versionCode 1002)
- termux-services installed
- Broken clone at `~/android-cowork/` — needs to be fixed first

---

## Step 0 — Fix the broken clone

Run one at a time:

```
rm -rf ~/android-cowork
```

```
git clone -b claude/busy-wright-OKBXH https://github.com/c10vis-poem/claude-android-skill.git ~/claude-android-skill
```

```
ln -s ~/claude-android-skill/android-cowork ~/android-cowork
```

---

## Step 1 — Claude Code + SuperClaude

```
bash ~/android-cowork/setup/2_claude_superclaude.sh
```

---

## Step 2 — Vertex AI (GCP credits)

```
bash ~/android-cowork/setup/3_vertex_ai_auth.sh
```

---

## Step 3 — Voice (Whisper STT + Kokoro TTS)

```
bash ~/android-cowork/setup/4_voice_setup.sh
```

```
bash ~/android-cowork/setup/4b_kokoro_tts.sh
```

---

## Step 4 — Local Model (Ollama + Vulkan)

```
bash ~/android-cowork/setup/5_omni_neural.sh
```

```
ollama pull qwen2.5:4b
```

---

## Step 5 — N0.V4 Structure + Automation

```
bash ~/android-cowork/nova/wiki_structure.sh
```

```
bash ~/android-cowork/nova/cron_setup.sh
```

---

## Step 6 — Markor Sync

```
bash ~/android-cowork/audit/markor_sync.sh
```

---

## Rules for the Model Helping with This

- One command at a time
- Wait for confirmation before the next
- User is on mobile — short commands, never multi-line pastes
- Read the actual error output before suggesting fixes
- No Supabase — use local JSONL only
- GCP project ID, Anthropic API key available when needed
- Goal: Claude Code + Vertex AI first. Voice second. Everything else after.

---

## Architecture Reference

Full stack doc: `~/android-cowork/nova/NOVA_STACK_GUIDE.md`
All endpoints: `~/android-cowork/nova/endpoints.md`
Horizons UI: `https://cdn.jsdelivr.net/gh/c10vis-poem/claude-skills@claude/busy-wright-OKBXH/horizons/index.html`
