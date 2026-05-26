#!/data/data/com.termux/files/usr/bin/bash
# Append an interaction to the raw immutable log
# Usage: log_interaction.sh "user prompt" "model response" "endpoint used"
# Called automatically by voice_bridge.py and android_task_runner.sh

USER_PROMPT="$1"
MODEL_RESPONSE="$2"
ENDPOINT="${3:-unknown}"
LOG="$HOME/nova/logs/interaction_logs.jsonl"

mkdir -p "$HOME/nova/logs"

python3 - << PYEOF
import json, datetime, os, sys

entry = {
    "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
    "user": """$USER_PROMPT""",
    "response": """$MODEL_RESPONSE""",
    "endpoint": "$ENDPOINT",
    "device": os.environ.get("DEVICE_NAME", "razr-ultra-25"),
    "session_id": os.environ.get("CLAUDE_SESSION_ID", "unknown")
}

with open("$LOG", "a") as f:
    f.write(json.dumps(entry) + "\n")
PYEOF
