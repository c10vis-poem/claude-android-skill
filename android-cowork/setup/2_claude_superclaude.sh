#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# Android AI Workstation — Step 2: Claude Code + SuperClaude
# ============================================================
set -euo pipefail

source "$HOME/.bashrc" 2>/dev/null || true

echo "==> Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code

echo "==> Verifying Claude Code installation..."
claude --version

echo "==> Installing SuperClaude framework..."
pipx install superclaude || pip install superclaude

echo "==> Running SuperClaude installer (commands + agents + skills)..."
superclaude install

echo "==> Verifying SuperClaude installation..."
ls ~/.claude/commands/sc/ | wc -l | xargs -I{} echo "   {} slash commands installed"
ls ~/.claude/agents/      | wc -l | xargs -I{} echo "   {} agents installed"

echo "==> Merging Android co-work MCP settings..."
SETTINGS="$HOME/.claude/settings.json"
ANDROID_SETTINGS="$HOME/android-cowork/config/claude_settings_android.json"

if [ -f "$ANDROID_SETTINGS" ]; then
  if [ ! -f "$SETTINGS" ]; then
    cp "$ANDROID_SETTINGS" "$SETTINGS"
    echo "   Created settings.json from android template"
  else
    echo "   settings.json already exists — manually merge from:"
    echo "   $ANDROID_SETTINGS"
  fi
fi

echo ""
echo "==> Step 2 complete!"
echo ""
echo "    Set your Anthropic API key (fallback when Vertex is not active):"
echo "    export ANTHROPIC_API_KEY=\"sk-ant-...\""
echo ""
echo "    Next: bash ~/android-cowork/setup/3_vertex_ai_auth.sh"
