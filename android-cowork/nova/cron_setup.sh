#!/data/data/com.termux/files/usr/bin/bash
# Set up automated N0.V4 scheduling in Termux
# Handles: hourly log sync, 6-hour dip checks, weekly audit

set -e

echo "=== N0.V4 Cron Setup ==="
echo ""

# Install cronie if not present
if ! command -v crond > /dev/null 2>&1; then
  echo "Installing cronie..."
  pkg install cronie -y
fi

# Start crond (add to .bashrc so it starts with Termux)
if ! pgrep crond > /dev/null 2>&1; then
  crond
  echo "crond started"
fi

# Make sure crond starts automatically
if ! grep -q 'crond' ~/.bashrc; then
  echo '' >> ~/.bashrc
  echo '# Start cron daemon if not running'
  echo 'pgrep crond > /dev/null || crond' >> ~/.bashrc
  echo "Added crond autostart to ~/.bashrc"
fi

# Write cron jobs
crontab - << 'CRON'
# N0.V4 Automated Schedule
# Hourly: sync logs to Jetson
0 * * * * bash ~/android-cowork/nova/log_sync.sh

# Every 6 hours: check dip metrics
0 */6 * * * python3 ~/android-cowork/nova/dip_check.py

# Daily at 11pm: run Docker CLI #1 pattern detection (via Jetson SSH)
0 23 * * * ssh derek@jetson.local 'bash ~/nova/docker_cli1.sh' 2>/dev/null || true

# Weekly Sunday 8am: full audit + Markor sync
0 8 * * 0 bash ~/android-cowork/audit/weekly_audit.sh

# Weekly Sunday 8:30am: sync docs to Markor
30 8 * * 0 bash ~/android-cowork/audit/markor_sync.sh
CRON

echo ""
echo "Cron schedule installed:"
echo ""
echo "  Hourly      — log sync to Jetson"
echo "  Every 6hrs  — dip metric check"
echo "  Daily 11pm  — Docker CLI #1 pattern detection"
echo "  Sunday 8am  — weekly audit"
echo "  Sunday 8:30 — Markor doc sync"
echo ""
echo "View schedule: crontab -l"
echo "Edit schedule: crontab -e"
echo ""

# Also set up Claude.ai Routines note
cat << 'EOF'
--- CLAUDE.AI ROUTINES ---
In Claude.ai sidebar > Routines, you can also set up:

Weekly (Sunday morning):
  "Run my weekly N0.V4 audit. Review sessions.jsonl summary,
   update failure log patterns, and generate handoff for next week."

This triggers a Claude.ai conversation automatically.
Termux cron handles the automated file operations.
Claude.ai Routines handles the review conversation.
---
EOF
