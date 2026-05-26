# Multi-Device Setup — Replicate N0.V4 on Any Android

The entire setup lives in GitHub. Any Android device with Termux
can join your N0.V4 network in under an hour.

---

## What Each Device Gets

| Component | Every Device | Razr Only | Jetson Only |
|-----------|-------------|-----------|-------------|
| Claude Code CLI | Yes | | |
| Voice bridge | Yes | | |
| Vertex AI routing | Yes | | |
| OB1 brain access | Yes | | |
| Omni Neural (local) | Optional | Primary | |
| Hexagon NPU model | No | Yes | |
| Docker CLI #1/#2 | No | | Yes |
| Postgres brain | No | | Yes |
| LoRA training | No | | Yes |

---

## Setup on a New Android Device

### Step 1 — Install apps

From F-Droid:

```
Termux
```

```
Termux:API
```

Grant Termux:API microphone + notification permissions.

### Step 2 — Run bootstrap

Open Termux. Copy line 1:

```
REPO=https://raw.githubusercontent.com/c10vis-poem/claude-android-skill/claude/busy-wright-OKBXH
```

Copy line 2:

```
curl -fsSL $REPO/install.sh | bash
```

### Step 3 — Claude Code

```
bash ~/android-cowork/setup/2_claude_superclaude.sh
```

### Step 4 — Vertex AI auth

```
bash ~/android-cowork/setup/3_vertex_ai_auth.sh
```

Sign in with your GCP account in the browser that opens.

Edit your project ID:

```
nano ~/android-cowork/config/vertex_env.sh
```

### Step 5 — Connect to shared OB1 brain

Set your Supabase credentials:

```
export SUPABASE_URL="https://YOUR-PROJECT.supabase.co"
```

```
export SUPABASE_SERVICE_KEY="your-service-key"
```

Copy settings:

```
cp ~/android-cowork/config/claude_settings_android.json ~/.claude/settings.json
```

Now this device shares the same memory as your Razr.

### Step 6 — (Optional) Connect to Jetson hub

Install Tailscale on the device (Play Store app).
Sign into your Tailscale account.
Jetson becomes accessible at its Tailscale IP.

Update routing rules to use Jetson for heavy tasks:

```
nano ~/android-cowork/nova/routing_rules.json
```

Change `jetson.local` to your Jetson's Tailscale IP.

---

## What Stays the Same Across All Devices

- All devices share OB1 brain (same Supabase project)
- All devices use same Vertex AI project (same GCP credits)
- All devices get same SuperClaude commands
- All devices write to ReasoningBank (same JSONL format)
- Horizons UI works on all devices (PWA, no install needed)

## What's Device-Specific

- GCP auth (each device needs its own `gcloud auth` login)
- Local model (only Razr has Omni Neural on Hexagon NPU)
- Voice bridge (works on any device with Termux:API + mic)
- Notification delivery (per-device)

---

## Devices That Can Join

- Any Android 10+ phone or tablet
- Android-based Chromebook (with Linux/Termux)
- Fire tablets (sideload F-Droid, then Termux)
- Android TV (limited, no voice)

---

## Activate on Any Device (Daily)

```
source ~/android-cowork/config/vertex_env.sh
```

```
claude
```
