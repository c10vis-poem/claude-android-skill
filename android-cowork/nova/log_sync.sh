#!/data/data/com.termux/files/usr/bin/bash
# Sync interaction logs from Razr to Jetson
# Runs hourly via cron. Add new log entries, never overwrite.

JETSON_IP="${JETSON_IP:-jetson.local}"
JETSON_USER="${JETSON_USER:-derek}"
NOVA_LOGS="$HOME/nova/logs"
REMOTE_LOGS="/home/$JETSON_USER/nova/logs"

if ! ping -c 1 -W 2 "$JETSON_IP" > /dev/null 2>&1; then
  echo "$(date): Jetson unreachable, skipping sync" >> "$HOME/nova/logs/sync.log"
  exit 0
fi

# Append-only sync: only send new entries, never delete
rsync -az --append-verify \
  "$NOVA_LOGS/interaction_logs.jsonl" \
  "$NOVA_LOGS/voice_transcripts/" \
  "$JETSON_USER@$JETSON_IP:$REMOTE_LOGS/" \
  2>> "$HOME/nova/logs/sync.log"

echo "$(date): Sync complete" >> "$HOME/nova/logs/sync.log"
