#!/usr/bin/env python3
"""
Monitor performance dip triggers defined in failure_rules.json.
Runs every 6 hours via cron. Sends Termux notification if threshold crossed.
"""

import json
import os
import subprocess
from pathlib import Path
from datetime import datetime, timedelta

NOVA = Path.home() / 'nova'
LOGS = NOVA / 'logs' / 'interaction_logs.jsonl'
RULES = Path.home() / 'android-cowork' / 'nova' / 'failure_rules.json'


def load_rules():
    with open(RULES) as f:
        return json.load(f)


def load_recent_logs(hours=24):
    if not LOGS.exists():
        return []
    cutoff = datetime.utcnow() - timedelta(hours=hours)
    entries = []
    with open(LOGS) as f:
        for line in f:
            try:
                e = json.loads(line.strip())
                ts = datetime.fromisoformat(e['timestamp'].replace('Z', ''))
                if ts > cutoff:
                    entries.append(e)
            except Exception:
                pass
    return entries


def notify(title, message):
    try:
        subprocess.run([
            'termux-notification',
            '--title', title,
            '--content', message,
            '--priority', 'high'
        ], check=True)
    except Exception:
        print(f'ALERT: {title} — {message}')


def check_user_corrections(logs, threshold):
    """Count sessions with more than threshold corrections."""
    by_session = {}
    for e in logs:
        sid = e.get('session_id', 'unknown')
        if 'correction' in str(e.get('user', '')).lower():
            by_session[sid] = by_session.get(sid, 0) + 1
    flagged = [s for s, c in by_session.items() if c >= threshold]
    return len(flagged)


def main():
    if not RULES.exists():
        print('failure_rules.json not found')
        return

    rules = load_rules()
    triggers = rules.get('dip_triggers', {})
    logs_24h = load_recent_logs(hours=24)
    logs_48h = load_recent_logs(hours=48)

    print(f'Dip check: {datetime.utcnow().isoformat()}')
    print(f'Logs last 24h: {len(logs_24h)}')

    alerts = []

    # User corrections check
    corr_threshold = triggers.get('user_corrections_per_session', {}).get('threshold', 3)
    high_correction_sessions = check_user_corrections(logs_24h, corr_threshold)
    if high_correction_sessions > 0:
        alerts.append(f'{high_correction_sessions} session(s) with {corr_threshold}+ corrections')

    if alerts:
        msg = ' | '.join(alerts)
        notify('N0.V4 Dip Alert', msg)
        print(f'ALERTS: {msg}')

        # Write to dip log
        dip_log = NOVA / 'logs' / 'dip_alerts.jsonl'
        with open(dip_log, 'a') as f:
            f.write(json.dumps({
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'alerts': alerts
            }) + '\n')
    else:
        print('No dip triggers crossed.')


if __name__ == '__main__':
    main()
