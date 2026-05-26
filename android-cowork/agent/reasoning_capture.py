#!/usr/bin/env python3
"""
ReasoningBank + OB1 Session Capture

Called by Claude Code's Stop hook at the end of every session.
Captures session insights, errors encountered, and successful patterns
to both OB1 (persistent memory) and a local ReasoningBank log.

Usage:
  python3 reasoning_capture.py              # Auto-capture from Claude session
  python3 reasoning_capture.py --dry-run    # Print what would be stored
  python3 reasoning_capture.py --summarize  # Summarize recent captures

Environment variables:
  SUPABASE_URL          OB1 Supabase instance URL
  SUPABASE_SERVICE_KEY  OB1 service role key
  CLAUDE_HOOK_EVENT     JSON blob from Claude Code Stop hook (auto-set by hook)
"""
import argparse
import json
import os
import subprocess
import sys
import datetime
from pathlib import Path

HOME = Path.home()
REASON_LOG = HOME / ".reasoning-bank" / "sessions.jsonl"
REASON_LOG.parent.mkdir(parents=True, exist_ok=True)


def get_session_event() -> dict:
    """Parse the CLAUDE_HOOK_EVENT env var set by Claude Code's Stop hook."""
    raw = os.environ.get("CLAUDE_HOOK_EVENT", "{}")
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def extract_insights(event: dict) -> dict:
    """Extract meaningful learning signals from a session event."""
    session_id  = event.get("session_id", "unknown")
    stop_reason = event.get("stop_reason", "unknown")
    tool_uses   = event.get("tool_uses", [])
    messages    = event.get("messages", [])

    errors = [
        m.get("content", "")[:200]
        for m in messages
        if "error" in str(m.get("content", "")).lower()
    ][:5]

    tools_used = list({t.get("name") for t in tool_uses if t.get("name")})

    # Try to extract last assistant message as session summary
    last_assistant = ""
    for m in reversed(messages):
        if m.get("role") == "assistant":
            last_assistant = str(m.get("content", ""))[:500]
            break

    return {
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "session_id": session_id,
        "stop_reason": stop_reason,
        "tools_used": tools_used,
        "error_count": len(errors),
        "errors_sample": errors,
        "session_summary": last_assistant,
        "device": "android",
        "source": "claude-code-stop-hook",
    }


def append_to_local_bank(insights: dict) -> None:
    """Append insights to the local JSONL reasoning log."""
    with open(REASON_LOG, "a") as f:
        f.write(json.dumps(insights) + "\n")
    print(f"  [ReasoningBank] Saved to {REASON_LOG}")


def push_to_ob1(insights: dict) -> bool:
    """Push session summary to OB1 Open Brain via MCP or direct Supabase."""
    supabase_url = os.environ.get("SUPABASE_URL")
    supabase_key = os.environ.get("SUPABASE_SERVICE_KEY")

    if not supabase_url or not supabase_key:
        print("  [OB1] SUPABASE_URL / SUPABASE_SERVICE_KEY not set — skipping OB1 push")
        return False

    thought_content = (
        f"Claude Code session on Android [{insights['timestamp']}]\n"
        f"Tools used: {', '.join(insights['tools_used']) or 'none'}\n"
        f"Stop reason: {insights['stop_reason']}\n"
        f"Errors encountered: {insights['error_count']}\n\n"
        f"Session summary:\n{insights['session_summary']}"
    )

    payload = json.dumps({
        "content": thought_content,
        "source": "android-claude-code",
        "metadata": {
            "session_id": insights["session_id"],
            "device": "android",
            "error_count": insights["error_count"],
        }
    })

    try:
        result = subprocess.run(
            [
                "curl", "-s", "-X", "POST",
                f"{supabase_url}/rest/v1/thoughts",
                "-H", "Content-Type: application/json",
                "-H", f"apikey: {supabase_key}",
                "-H", f"Authorization: Bearer {supabase_key}",
                "-d", payload,
            ],
            capture_output=True, text=True, timeout=15
        )
        if result.returncode == 0 and "error" not in result.stdout.lower():
            print("  [OB1] Session summary stored in Open Brain")
            return True
        else:
            print(f"  [OB1] Push failed: {result.stdout[:200]}")
    except Exception as e:
        print(f"  [OB1] Push error: {e}")
    return False


def main() -> None:
    parser = argparse.ArgumentParser(description="Capture session to ReasoningBank + OB1")
    parser.add_argument("--dry-run",  action="store_true", help="Print without storing")
    parser.add_argument("--summarize", action="store_true", help="Show recent captures")
    args = parser.parse_args()

    if args.summarize:
        if not REASON_LOG.exists():
            print("No sessions captured yet.")
            return
        lines = REASON_LOG.read_text().strip().split("\n")
        recent = [json.loads(l) for l in lines[-10:] if l]
        print(f"\nLast {len(recent)} sessions:\n")
        for s in recent:
            print(f"  {s['timestamp'][:16]}  tools={len(s['tools_used'])}  errors={s['error_count']}")
            if s.get("session_summary"):
                print(f"    {s['session_summary'][:100]}...\n")
        return

    event    = get_session_event()
    insights = extract_insights(event)

    if args.dry_run:
        print("\n[Dry run] Would capture:")
        print(json.dumps(insights, indent=2))
        return

    print("\n[reasoning_capture] Storing session insights...")
    append_to_local_bank(insights)
    push_to_ob1(insights)
    print("[reasoning_capture] Done.\n")


if __name__ == "__main__":
    main()
