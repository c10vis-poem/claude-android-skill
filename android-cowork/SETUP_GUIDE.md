# Android AI Workstation — Setup Guide

Estimated time: 30–45 min on a 2021+ Android device.

> **Mobile tip:** Copy and paste **one line at a time**. Each command block
> below contains a single command. Do not copy multiple blocks at once.

---

## Before You Begin

### Install These Apps First (from F-Droid)

1. **Termux** — [f-droid.org/packages/com.termux](https://f-droid.org/packages/com.termux/)
2. **Termux:API** — [f-droid.org/packages/com.termux.api](https://f-droid.org/packages/com.termux.api/)

> Do **not** use the Play Store versions — they are outdated.

After installing both apps, open **Android Settings → Apps → Termux:API**
and grant **Microphone** and **Notifications** permissions.

### Accounts You Need

- Google Cloud account with Vertex AI enabled
- Claude.ai Pro account (or Anthropic API key)
- Supabase project for OB1 brain (free tier works)

---

## Step 1 — Bootstrap Termux

Open Termux. Copy and paste **line 1**, press Enter, wait for it to finish.
Then copy and paste **line 2**, press Enter.

**Line 1:**
```
REPO=https://raw.githubusercontent.com/c10vis-poem/claude-android-skill/claude/busy-wright-OKBXH
```

**Line 2:**
```
curl -fsSL $REPO/install.sh | bash
```

This installs: git, python, nodejs, cmake, clang, ffmpeg, sox, termux-api, pipx.

Wait for it to finish (2–5 min depending on connection speed).

---

## Step 2 — Install Claude Code + SuperClaude

Copy and paste this one line:

```
bash ~/android-cowork/setup/2_claude_superclaude.sh
```

This installs Claude Code CLI and all 30 SuperClaude slash commands.

When it finishes, set your API key:

```
export ANTHROPIC_API_KEY="sk-ant-YOUR-KEY-HERE"
```

---

## Step 3 — Connect Your GCP Credits (Vertex AI)

Run this:

```
bash ~/android-cowork/setup/3_vertex_ai_auth.sh
```

It will open a browser for Google login. Sign in with your GCP account.

Then edit the config to add your project ID:

```
nano ~/android-cowork/config/vertex_env.sh
```

Change `YOUR_GCP_PROJECT_ID` to your actual project ID. Save: **Ctrl+X → Y → Enter**.

Activate Vertex AI for the current session:

```
source ~/android-cowork/config/vertex_env.sh
```

To activate automatically every time Termux opens:

```
echo 'source ~/android-cowork/config/vertex_env.sh' >> ~/.bashrc
```

---

## Step 4 — Local Voice (Offline STT + TTS)

Run this (takes ~10 min — it builds Whisper from source):

```
bash ~/android-cowork/setup/4_voice_setup.sh
```

Install Kokoro TTS (preferred voice engine):

```
bash ~/android-cowork/setup/4b_kokoro_tts.sh
```

Test that voice works:

```
python3 ~/android-cowork/voice/voice_bridge.py --test
```

---

## Step 5 — OB1 Persistent Brain

Set your Supabase credentials (one line each):

```
export SUPABASE_URL="https://YOUR-PROJECT.supabase.co"
```

```
export SUPABASE_SERVICE_KEY="your-service-role-key"
```

Copy the Claude Code settings:

```
cp ~/android-cowork/config/claude_settings_android.json ~/.claude/settings.json
```

Edit the settings file to fill in your Supabase credentials:

```
nano ~/.claude/settings.json
```

Save: **Ctrl+X → Y → Enter**.

---

## Step 6 — Test ReasoningBank Hook

```
python3 ~/android-cowork/agent/reasoning_capture.py --dry-run
```

If it prints session info without errors, you're set.
From now on the hook fires automatically at the end of every Claude session.

---

## Daily Usage

### Voice Mode

Activate Vertex (if not in ~/.bashrc yet):

```
source ~/android-cowork/config/vertex_env.sh
```

Start voice loop:

```
python3 ~/android-cowork/voice/voice_bridge.py
```

Press **Enter** → speak → press **Enter** to stop. Claude replies via Kokoro TTS.
Say **"stop"** or **"exit"** to quit.

### Standard Claude Code

```
source ~/android-cowork/config/vertex_env.sh
```

```
claude
```

### Background Task

```
~/android-cowork/agent/android_task_runner.sh "your task here"
```

You get a phone notification when it finishes.

---

## Horizons UI (Installable App)

Open this URL in Chrome on your phone:

```
https://cdn.jsdelivr.net/gh/c10vis-poem/claude-skills@claude/busy-wright-OKBXH/horizons/index.html
```

Tap **3-dot menu → Add to Home Screen** to install it as a standalone app.

---

## Troubleshooting

**`command not found: claude`**

```
npm install -g @anthropic-ai/claude-code
```

**Vertex AI auth fails**

```
gcloud auth application-default login
```

**Microphone not working**
- Make sure Termux:API app is installed (not just Termux)
- Grant microphone permission to Termux:API in Android Settings

**Whisper build fails**

```
pkg install cmake clang
```

Then re-run step 4.

**OB1 MCP not connecting**
- Check SUPABASE_URL starts with `https://`
- Verify your service role key (not the anon key)
- Run: `node --version` — must be 18 or higher
