# Weekly Audit — Terminal / Claude Code Edition

*Run once a week in Termux. Generates output files to `~/storage/shared/N0VA/audit/`.*
*Or run the automated script: `bash ~/android-cowork/audit/weekly_audit.sh`*

---

## PURPOSE

Termux Claude Code sessions accumulate in `~/.reasoning-bank/sessions.jsonl`.
This audit consolidates the week's sessions, surfaces failure patterns,
and generates a handoff context file for the next week's CLAUDE.md.

---

## STEP 1 — Session Review

Run this to see the week's sessions:

```
python3 ~/android-cowork/agent/reasoning_capture.py --summarize
```

For each session, note:
- **What worked** — tasks completed cleanly, tools used correctly
- **What failed** — errors, retries, unexpected stops
- **Pattern** — was it a prompt issue, a tool issue, or an environment issue?

Record failures in `~/storage/shared/N0VA/audit/failure_log.md`
using the entry format below.

---

## STEP 2 — Failure Log Entries

For each notable failure from the week, add an entry to `failure_log.md`:

```
### [DATE] — [TASK/PROJECT]

Symptom: what happened
Expected: what should have happened
Root cause: what actually went wrong
Failure type: Context Degradation / Specification Drift / Sycophantic Confirmation
             / Tool Selection Error / Cascading Failure / Silent Failure
Blast radius: Low/Medium/High/Critical — Reversible: Yes/No — Frequency: Once/Recurring
Fix applied: what resolved it
Prevention: config change, guardrail, or test case
Test case: input → expected output → pass/fail
```

---

## STEP 3 — Frequency Tracker Update

Update `failure_log.md` frequency table:

| Type | This Week | Total | Trend |
|------|-----------|-------|-------|
| Context Degradation | | | |
| Specification Drift | | | |
| Sycophantic Confirmation | | | |
| Tool Selection Error | | | |
| Cascading Failure | | | |
| Silent Failure | | | |

---

## STEP 4 — OB1 Brain Review

Check what was captured to OB1 this week:

```
curl -s "$SUPABASE_URL/rest/v1/thoughts?order=created_at.desc&limit=20" \
  -H "apikey: $SUPABASE_SERVICE_KEY" | python3 -m json.tool | head -80
```

Note any patterns in what got stored. Are the captures useful?
Are there gaps where important decisions weren't captured?

---

## STEP 5 — Generate Handoff File

Run the automated script:

```
bash ~/android-cowork/audit/weekly_audit.sh
```

This generates `~/storage/shared/N0VA/audit/handoff_YYYY-MM-DD.md`
with session stats, tool usage, and context for next week.

Or write it manually. The handoff file should contain:

- **Active project status** — one paragraph per active project
- **Recent decisions** — architecture, routing, scope changes this week
- **Pending actions** — what you need to execute, in priority order
- **Open questions** — unresolved decisions, blocked items
- **Vertex AI spend** — approximate GCP credit usage this week
- **Voice/OB1 status** — are all integrations working?
- **Failure patterns** — top 1-3 from frequency tracker + prevention notes
- **Next week focus** — what this setup needs to improve

---

## STEP 6 — CLAUDE.md Update

Copy the handoff into the project CLAUDE.md context:

```
cp ~/storage/shared/N0VA/audit/handoff_$(date +%Y-%m-%d).md \
   ~/android-cowork/CLAUDE.md
```

Next week Claude Code reads this automatically on session start.

---

## DECISION POINT

1. **Continue** — context healthy, keep going, re-audit in 7 days
2. **Reset session context** — run `/compact` in Claude Code to compress history
3. **Full reset** — archive CLAUDE.md, start fresh with handoff as new context

---

## NOTES

- Audit cadence: weekly. Run early if: OB1 feels stale, Vertex spend spiking,
  voice errors increasing, or 3+ silent failures in one week.
- The Stop hook captures data automatically — this audit is for reviewing
  and synthesizing it, not for data entry.
- Failure log lives in Markor (`N0VA/audit/failure_log.md`) — edit it there
  between sessions as failures happen, not just at audit time.
