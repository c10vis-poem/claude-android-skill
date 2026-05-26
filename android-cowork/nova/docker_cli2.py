#!/usr/bin/env python3
"""
Docker CLI #2 — Auditor / Failure Watchdog (runs on Jetson Orin Nano Super)

Reads Docker CLI #1 output. Applies confidence scoring.
Detects failure types from failure_rules.json.
Generates wiki entries for approved patterns.
Surfaces low-confidence items for Derek's review.
BLOCKS training if self-gaslighting detected.
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime

NOVA = Path.home() / 'nova'
RULES_PATH = Path.home() / 'android-cowork' / 'nova' / 'failure_rules.json'
GATES_PATH = Path.home() / 'android-cowork' / 'nova' / 'sharpening_gates.json'


def load_rules():
    with open(RULES_PATH) as f:
        return json.load(f)


def load_latest_cli1():
    """Find today's CLI #1 output."""
    today = datetime.utcnow().strftime('%Y-%m-%d')
    pattern = NOVA / 'logs' / f'cli1_output_{today}.jsonl'
    if not pattern.exists():
        return []
    entries = []
    with open(pattern) as f:
        for line in f:
            try:
                entries.append(json.loads(line.strip()))
            except Exception:
                pass
    return entries


def score_confidence(analysis_text, failure_types):
    """Simple keyword-based confidence scoring. Replace with LLM scorer in Phase 3."""
    text = analysis_text.lower()
    flags = []
    score = 0.75  # baseline

    for ftype, fdata in failure_types.items():
        for keyword in fdata.get('detection', []):
            if any(word in text for word in keyword.lower().split()[:3]):
                flags.append(ftype)
                if fdata.get('severity') == 'critical':
                    score -= 0.2
                elif fdata.get('severity') == 'high':
                    score -= 0.1
                break

    return max(0.0, min(1.0, score)), flags


def write_wiki_entry(entry, flags, confidence):
    """Write a wiki patterns entry for approved analysis."""
    today = datetime.utcnow().strftime('%Y-%m-%d')
    wiki_file = NOVA / 'wiki' / 'patterns' / f'{today}_cli2_audit.md'
    wiki_file.parent.mkdir(parents=True, exist_ok=True)

    with open(wiki_file, 'a') as f:
        f.write(f"""\n## Audit — {entry.get('timestamp', today)}

**Entries analyzed:** {entry.get('entries_analyzed', 0)}
**Confidence:** {confidence:.2f}
**Flags:** {', '.join(flags) if flags else 'none'}

### Analysis
{entry.get('analysis', 'No analysis available')}

---
""")

    # Append to log
    with open(NOVA / 'wiki' / 'log.md', 'a') as f:
        f.write(f"- {today}: CLI #2 audit written to patterns/{today}_cli2_audit.md\n")


def generate_review_report(results):
    """Generate report for Derek's review gate."""
    report_path = NOVA / 'logs' / f'cli2_review_{datetime.utcnow().strftime("%Y-%m-%d")}.md'
    blocks_training = any(r.get('blocks_training') for r in results)

    with open(report_path, 'w') as f:
        f.write(f"""# Docker CLI #2 Review — {datetime.utcnow().strftime('%Y-%m-%d')}

**Training blocked:** {'YES — self-gaslighting detected' if blocks_training else 'No'}

## Items Requiring Your Review

""")
        needs_review = [r for r in results if r.get('needs_human_review')]
        if needs_review:
            for i, r in enumerate(needs_review, 1):
                f.write(f"### Item {i}\n")
                f.write(f"Confidence: {r.get('confidence', 0):.2f}\n")
                f.write(f"Flags: {', '.join(r.get('flags', []))}\n")
                f.write(f"Analysis excerpt:\n{str(r.get('analysis', ''))[:500]}\n\n---\n")
        else:
            f.write("No items need review today.\n")

        f.write("\n## Auto-Approved (confidence >= 0.85)\n")
        auto = [r for r in results if r.get('auto_approved')]
        f.write(f"{len(auto)} items auto-approved.\n")

    return report_path, blocks_training


def main():
    print(f"Docker CLI #2 Auditor — {datetime.utcnow().isoformat()}")

    if not RULES_PATH.exists():
        print('failure_rules.json not found')
        sys.exit(1)

    rules = load_rules()
    failure_types = rules.get('failure_types', {})
    thresholds = rules.get('confidence_scoring', {})
    auto_approve = thresholds.get('auto_approve_threshold', 0.85)
    human_review = thresholds.get('human_review_threshold', 0.6)
    auto_reject = thresholds.get('auto_reject_threshold', 0.3)

    cli1_entries = load_latest_cli1()
    if not cli1_entries:
        print('No CLI #1 output found for today')
        return

    print(f'Processing {len(cli1_entries)} CLI #1 entries')
    results = []

    for entry in cli1_entries:
        if entry.get('status') == 'error':
            continue

        analysis = entry.get('analysis', '')
        confidence, flags = score_confidence(analysis, failure_types)
        blocks_training = 'self_gaslighting' in flags

        result = {
            'timestamp': entry.get('timestamp'),
            'confidence': confidence,
            'flags': flags,
            'analysis': analysis,
            'blocks_training': blocks_training,
            'auto_approved': confidence >= auto_approve and not blocks_training,
            'needs_human_review': confidence < human_review or blocks_training,
            'auto_rejected': confidence < auto_reject
        }
        results.append(result)

        if result['auto_approved']:
            write_wiki_entry(entry, flags, confidence)
            print(f'  Auto-approved (confidence: {confidence:.2f})')
        elif blocks_training:
            print(f'  BLOCKED — self-gaslighting detected')
        elif result['needs_human_review']:
            print(f'  Flagged for review (confidence: {confidence:.2f}, flags: {flags})')

    report_path, blocks_training = generate_review_report(results)
    print(f'\nReview report: {report_path}')

    if blocks_training:
        print('\n*** TRAINING BLOCKED — Review report before approving any training. ***')
        try:
            import subprocess
            subprocess.run([
                'termux-notification',
                '--title', 'N0.V4 Training BLOCKED',
                '--content', 'Self-gaslighting detected. Review CLI #2 report before approving.',
                '--priority', 'max'
            ])
        except Exception:
            pass


if __name__ == '__main__':
    main()
