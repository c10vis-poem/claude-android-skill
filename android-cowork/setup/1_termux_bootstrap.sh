#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# Android AI Workstation — Step 1: Termux Bootstrap
# Run this first in a fresh Termux install.
# ============================================================
set -euo pipefail

echo "==> Granting storage access..."
termux-setup-storage || true
sleep 2

echo "==> Updating package lists..."
pkg update -y
pkg upgrade -y

echo "==> Installing core dependencies..."
pkg install -y \
  git curl wget \
  nodejs-lts \
  python python-pip \
  cmake clang make \
  termux-api \
  openssh \
  zip unzip \
  ffmpeg \
  sox \
  jq

echo "==> Installing pipx for isolated Python tools..."
pip install --upgrade pip pipx
pipx ensurepath

echo "==> Configuring npm global path..."
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'

echo "==> Writing shell profile additions..."
PROFILE="$HOME/.bashrc"
grep -q 'NPM_GLOBAL' "$PROFILE" 2>/dev/null || cat >> "$PROFILE" << 'PROFILE_EOF'

# Android AI Workstation
export NPM_PREFIX="$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
PROFILE_EOF

source "$PROFILE" 2>/dev/null || true

echo "==> Cloning android-cowork scripts..."
REPO_DIR="$HOME/android-cowork"
if [ ! -d "$REPO_DIR" ]; then
  git clone --branch claude/busy-wright-OKBXH \
    https://github.com/c10vis-poem/claude-android-skill.git \
    /tmp/claude-android-skill-tmp
  cp -r /tmp/claude-android-skill-tmp/android-cowork "$REPO_DIR"
  rm -rf /tmp/claude-android-skill-tmp
else
  echo "   android-cowork dir already exists, skipping clone"
fi

chmod +x "$REPO_DIR"/setup/*.sh
chmod +x "$REPO_DIR"/agent/*.sh 2>/dev/null || true

echo ""
echo "==> Step 1 complete!"
echo "    Next: bash ~/android-cowork/setup/2_claude_superclaude.sh"
