# N0.V4 Stack — Complete Setup Guide

**Architecture:** Razr Ultra 25 (edge) + Jetson Orin Nano Super (hub) + Cloud (frontier)

---

## Build Order

Do these in order. Each step depends on the previous.

```
Phase 1 — Voice agent on Razr (do this first)
Phase 2 — Jetson hub + Tailscale
Phase 3 — LoRA training (gated, comes last)
```

---

## Phase 1: Voice Agent on Razr (Start Here)

### 1a — Termux bootstrap

See SETUP_GUIDE.md Steps 1-4. Run these first.

### 1b — Local model (Omni Neural / Edge)

```
bash ~/android-cowork/setup/5_omni_neural.sh
```

Pull a 4B model:

```
ollama pull qwen2.5:4b
```

Test it:

```
ollama run qwen2.5:4b "Hello, are you local?"
```

### 1c — Voice bridge with local model

Edit voice_bridge.py to route to local model:

```
nano ~/android-cowork/voice/voice_bridge.py
```

Change the Claude endpoint to local:

```
LOCAL_MODEL_URL = "http://localhost:11434/v1/chat/completions"
```

Test full voice loop:

```
python3 ~/android-cowork/voice/voice_bridge.py --test
```

### 1d — Set up N0.V4 log structure

```
bash ~/android-cowork/nova/wiki_structure.sh
```

### 1e — Set up automated scheduling

```
bash ~/android-cowork/nova/cron_setup.sh
```

---

## Phase 2: Jetson Hub

### 2a — Run Jetson setup (ON the Jetson, not Razr)

```
bash ~/android-cowork/setup/7_jetson_setup.sh
```

### 2b — Set up Tailscale tunnel

On Razr:

```
bash ~/android-cowork/setup/6_tailscale.sh
```

On Jetson:

```
curl -fsSL https://tailscale.com/install.sh | sh
```

```
sudo tailscale up
```

Get Jetson's Tailscale IP:

```
tailscale ip -4
```

### 2c — Update routing rules with Jetson IP

```
nano ~/android-cowork/nova/routing_rules.json
```

Replace `jetson.local` with your Tailscale IP.

### 2d — Set up SSH key auth (Razr → Jetson)

```
ssh-keygen -t ed25519 -f ~/.ssh/jetson_key
```

```
ssh-copy-id -i ~/.ssh/jetson_key derek@JETSON-IP
```

### 2e — Test log sync

```
bash ~/android-cowork/nova/log_sync.sh
```

### 2f — Start Docker CLI #1 and #2 on Jetson

Copy scripts to Jetson:

```
scp ~/android-cowork/nova/docker_cli1.sh derek@JETSON-IP:~/nova/
```

```
scp ~/android-cowork/nova/docker_cli2.py derek@JETSON-IP:~/nova/
```

Test Docker CLI #1:

```
ssh derek@JETSON-IP 'bash ~/nova/docker_cli1.sh'
```

---

## Phase 3: LoRA Training (Gated)

Do NOT start Phase 3 until all gates pass.

Check gate status:

```
python3 ~/android-cowork/nova/lora_pipeline.py
```

Gates:
- Base agent stable 2+ weeks
- 500+ interaction log entries
- Jetson Postgres operational
- Dip metrics live
- Docker CLI #2 validated on historical logs
- Cost estimate completed

---

## Daily Usage

Voice agent (what you want most):

```
source ~/android-cowork/config/vertex_env.sh
```

```
python3 ~/android-cowork/voice/voice_bridge.py
```

Local model only (offline):

```
ollama run qwen2.5:4b
```

Claude Code with Vertex:

```
source ~/android-cowork/config/vertex_env.sh && claude
```

---

## Endpoint Quick Reference

See `nova/endpoints.md` for the full list.
Sync to Markor: `bash ~/android-cowork/audit/markor_sync.sh`
