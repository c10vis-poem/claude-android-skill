#!/data/data/com.termux/files/usr/bin/bash
# Weekly audit script for N0.V4 terminal sessions
# Reads ~/.reasoning-bank/sessions.jsonl and generates handoff + stats

set -e

DATE=$(date +%Y-%m-%d)
WEEK_AGO=$(date -d '7 days ago' +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -v-7d +%Y-%m-%dT%H:%M:%S)
OUTDIR="$HOME/storage/shared/N0VA/audit"
SESSIONS="$HOME/.reasoning-bank/sessions.jsonl"

# Create output dir if needed
mkdir -p "$OUTDIR"

echo "=== N0.V4 Weekly Audit — $DATE ==="
echo ""

# --- Session stats ---
if [ ! -f "$SESSIONS" ]; then
  echo "No session log found at $SESSIONS"
  echo "Run at least one Claude Code session with the Stop hook active first."
  exit 1
fi

TOTAL=$(wc -l < "$SESSIONS")
echo "Total sessions logged: $TOTAL"

# Count this week's sessions (rough date filter)
WEEK_COUNT=$(grep -c "$(date +%Y-%m)" "$SESSIONS" 2>/dev/null || echo "0")
echo "Sessions this month: $WEEK_COUNT"
echo ""

# --- Tool usage ---
echo "--- Tool Usage (all time) ---"
grep -o '"tools_used": \[[^]]*\]' "$SESSIONS" 2>/dev/null | \
  grep -o '"[^"]*"' | sort | uniq -c | sort -rn | head -10 || echo "No tool data"
echo ""

# --- Error patterns ---
ERRORS=$(grep -c '"errors": \[' "$SESSIONS" 2>/dev/null || echo "0")
echo "Sessions with errors: $ERRORS"
echo ""

# --- Recent sessions ---
echo "--- Last 5 Sessions ---"
tail -5 "$SESSIONS" | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        s = json.loads(line.strip())
        sid = s.get('session_id','?')[:12]
        ts  = s.get('timestamp','?')[:16]
        reason = s.get('stop_reason','?')
        msg = (s.get('last_assistant_message') or '')[:80]
        print(f'  {ts}  [{reason}]  {msg}...')
    except:
        pass
" 2>/dev/null || echo "Could not parse sessions"
echo ""

# --- Generate handoff ---
HANDOFF="$OUTDIR/handoff_$DATE.md"
cat > "$HANDOFF" << HANDOFF
# Handoff — $DATE

## Session Stats
- Total sessions logged: $TOTAL
- Sessions this month: $WEEK_COUNT
- Sessions with errors: $ERRORS

## Active Projects
<!-- Fill in one paragraph per active project -->

- **N0.V4 Android Setup:** 
- **Horizons UI:** 
- **OB1 Brain:** 
- **ReasoningBank:** 

## Recent Decisions
<!-- Architecture, routing, scope changes from this week -->

## Pending Actions
<!-- What needs to happen next, in priority order -->
1. 
2. 
3. 

## Open Questions
<!-- Unresolved decisions, blocked items -->

## Vertex AI Spend
<!-- Approximate GCP credit usage this week -->

## Integration Status
- [ ] Vertex AI routing active
- [ ] Voice bridge (Whisper + Kokoro) working
- [ ] OB1 MCP connected
- [ ] ReasoningBank Stop hook firing
- [ ] Markor sync working

## Failure Patterns
<!-- Top 1-3 from failure_log.md frequency tracker -->

## Next Week Focus
<!-- What this setup needs to improve -->

HANDOFF

echo "Handoff written to: $HANDOFF"
echo ""

# --- Sync docs to Markor ---
DOCSRC="$HOME/android-cowork"
DOCDST="$HOME/storage/shared/N0VA/docs"
mkdir -p "$DOCDST"

for f in SETUP_GUIDE.md SKILL.md audit/weekly_audit_terminal.md audit/failure_log.md; do
  if [ -f "$DOCSRC/$f" ]; then
    DEST_FILE="$DOCDST/$(basename $f)"
    cp "$DOCSRC/$f" "$DEST_FILE"
    echo "Synced: $f → $DOCDST/"
  fi
done

echo ""
echo "=== Audit complete ==="
echo ""
echo "Files written to: $OUTDIR"
echo "Open in Markor: N0VA/audit/handoff_$DATE.md"
echo "Open in Markor: N0VA/audit/failure_log.md"
echo ""
