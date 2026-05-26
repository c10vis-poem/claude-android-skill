#!/data/data/com.termux/files/usr/bin/bash
# N0.V4 Android AI Workstation — Termux Bootstrap
# Paste this URL into Termux:
#   curl -fsSL https://raw.githubusercontent.com/c10vis-poem/claude-android-skill/claude/busy-wright-OKBXH/install.sh | bash

set -e

BRANCH="claude/busy-wright-OKBXH"
BASE="https://raw.githubusercontent.com/c10vis-poem/claude-android-skill/$BRANCH/android-cowork/setup"

echo ""
echo "======================================"
echo "  N0.V4 Android AI Workstation Setup  "
echo "======================================"
echo ""
echo "Running Step 1: Termux bootstrap..."
echo ""

curl -fsSL "$BASE/1_termux_bootstrap.sh" | bash

echo ""
echo "======================================"
echo "  Bootstrap complete!"
echo ""
echo "  Next — run each line one at a time:"
echo ""
echo "  bash ~/android-cowork/setup/2_claude_superclaude.sh"
echo ""
echo "  bash ~/android-cowork/setup/3_vertex_ai_auth.sh"
echo ""
echo "  bash ~/android-cowork/setup/4_voice_setup.sh"
echo "======================================"
echo ""
