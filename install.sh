#!/data/data/com.termux/files/usr/bin/bash
# N0.V4 Android AI Workstation — Termux Bootstrap
# Usage:
#   REPO=https://raw.githubusercontent.com/c10vis-poem/claude-android-skill/claude/busy-wright-OKBXH
#   curl -fsSL $REPO/install.sh | bash

set -e

BRANCH="claude/busy-wright-OKBXH"
REPO_URL="https://github.com/c10vis-poem/claude-android-skill.git"
CLONE_DIR="$HOME/claude-android-skill"
LINK_DIR="$HOME/android-cowork"

echo ""
echo "======================================"
echo "  N0.V4 Android AI Workstation Setup  "
echo "======================================"
echo ""

# Install base packages
pkg install -y git curl wget python nodejs-lts cmake clang \
  termux-api openssh ffmpeg sox jq nano 2>/dev/null || true

# Clone repo
if [ -d "$CLONE_DIR" ]; then
  echo "Repo already cloned, pulling latest..."
  git -C "$CLONE_DIR" pull
else
  echo "Cloning N0.V4 setup repo..."
  git clone -b "$BRANCH" "$REPO_URL" "$CLONE_DIR"
fi

# Create symlink so paths are clean
if [ ! -L "$LINK_DIR" ] && [ ! -d "$LINK_DIR" ]; then
  ln -s "$CLONE_DIR/android-cowork" "$LINK_DIR"
  echo "Created shortcut: ~/android-cowork -> repo/android-cowork"
elif [ -d "$LINK_DIR" ] && [ ! -L "$LINK_DIR" ]; then
  # Real directory exists (from bad previous clone), fix it
  echo "Fixing path — removing old clone and creating symlink..."
  rm -rf "$LINK_DIR"
  ln -s "$CLONE_DIR/android-cowork" "$LINK_DIR"
  echo "Fixed: ~/android-cowork -> repo/android-cowork"
fi

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
