#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# Android Agentic Task Runner
#
# Runs Claude Code as a background agent on Android.
# Sends a Termux notification when the task completes.
#
# Usage:
#   android_task_runner.sh "refactor the auth module and run tests"
#   android_task_runner.sh --dir /path/to/project "task description"
#   android_task_runner.sh --model claude-sonnet-4-5 "task"
# ============================================================
set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
WORK_DIR="$(pwd)"
MODEL=""
TASK=""
LOG_DIR="$HOME/.claude-task-logs"
mkdir -p "$LOG_DIR"

# ── Argument parsing ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)   WORK_DIR="$2"; shift 2 ;;
    --model) MODEL="$2";    shift 2 ;;
    *)       TASK="$TASK $1"; shift ;;
  esac
done
TASK="${TASK## }"

if [ -z "$TASK" ]; then
  echo "Usage: android_task_runner.sh [--dir PATH] [--model MODEL] \"task description\""
  exit 1
fi

# ── Activate Vertex AI if configured ──────────────────────────────────────────
VERTEX_ENV="$HOME/android-cowork/config/vertex_env.sh"
[ -f "$VERTEX_ENV" ] && source "$VERTEX_ENV" 2>/dev/null || true

# ── Build Claude command ───────────────────────────────────────────────────────
TS="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/task_${TS}.log"
TASK_SHORT="$(echo "$TASK" | cut -c1-60)"

CLAUDE_CMD=("claude" "--print")
[ -n "$MODEL" ] && CLAUDE_CMD+=("--model" "$MODEL")
CLAUDE_CMD+=(
  "You are running as an autonomous background agent on an Android device."
  "Working directory: $WORK_DIR"
  "Task: $TASK"
  "\n"
  "Use SuperClaude commands if helpful (/sc:implement, /sc:research, etc.)."
  "Produce concrete results. Log progress. When complete, output a summary"
  "starting with the word DONE: followed by a one-sentence result summary."
)

termux-notification \
  --title "Claude Agent Starting" \
  --content "Task: ${TASK_SHORT}..." \
  --id 42 2>/dev/null || true

echo "==> Task started at $(date)" | tee "$LOG_FILE"
echo "    Working dir: $WORK_DIR"   | tee -a "$LOG_FILE"
echo "    Task: $TASK"              | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ── Run agent ──────────────────────────────────────────────────────────────────
SET_EXIT=0
"${CLAUDE_CMD[@]}" > >(tee -a "$LOG_FILE") 2>&1 || SET_EXIT=$?

# ── Extract DONE summary ───────────────────────────────────────────────────────
DONE_LINE="$(grep -m1 '^DONE:' "$LOG_FILE" 2>/dev/null || echo "Task completed (exit $SET_EXIT)")"

echo "" | tee -a "$LOG_FILE"
echo "==> Task finished at $(date) (exit code $SET_EXIT)" | tee -a "$LOG_FILE"

# ── Notify ─────────────────────────────────────────────────────────────────────
STATUS_ICON="$([ $SET_EXIT -eq 0 ] && echo '✓' || echo '✗')"
termux-notification \
  --title "Claude Agent ${STATUS_ICON} Done" \
  --content "${DONE_LINE}" \
  --id 42 2>/dev/null || true

# Optional: speak completion notice
[ -f "$HOME/voice/speak.sh" ] && \
  bash "$HOME/voice/speak.sh" "Task complete. ${DONE_LINE}" 2>/dev/null || true

echo ""
echo "Full log: $LOG_FILE"
echo "Result:   $DONE_LINE"
exit $SET_EXIT
