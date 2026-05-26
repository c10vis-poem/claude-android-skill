#!/data/data/com.termux/files/usr/bin/bash
# Initialize your Obsidian vault as a git repo
# and set up Claude Code to work inside it

set -e

VAULT="$HOME/storage/shared/N0VA"

echo "=== Obsidian Vault Git Setup ==="
echo ""

# Check vault exists
if [ ! -d "$VAULT" ]; then
  echo "Vault not found at $VAULT"
  echo ""
  echo "First create the vault in Obsidian:"
  echo "  1. Open Obsidian"
  echo "  2. Create new vault named: N0VA"
  echo "  3. Choose: Store in device storage"
  echo "  4. Re-run this script"
  exit 1
fi

cd "$VAULT"

# Init git if not already
if [ ! -d ".git" ]; then
  git init
  echo "Git initialized in $VAULT"
else
  echo "Git already initialized"
fi

# Create .gitignore for Obsidian
cat > .gitignore << 'EOF'
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/cache
.trash/
.DS_Store
*.swp
EOF

echo "Created .gitignore"

# Create default folder structure if empty
mkdir -p docs audit config
mkdir -p "Daily Notes"
mkdir -p Projects
mkdir -p Resources

# Create index note if it doesn't exist
if [ ! -f "00 - Index.md" ]; then
cat > "00 - Index.md" << EOF
# N0VA Knowledge Base

Welcome to your Obsidian vault. This is your index.

## Projects
- [[Projects/N0VA]] — Android AI workstation

## Daily Notes
See the Daily Notes/ folder for dated session logs.

## Docs
- [[docs/SETUP_GUIDE]] — N0VA Termux setup
- [[docs/weekly_audit_terminal]] — Weekly audit protocol

## Resources
- [[Resources/Links]] — useful references
EOF
echo "Created: 00 - Index.md"
fi

# Sync docs from android-cowork into vault
SRC="$HOME/android-cowork"
for f in SETUP_GUIDE.md SKILL.md audit/weekly_audit_terminal.md audit/failure_log.md; do
  DEST="$VAULT/docs/$(basename $f)"
  cp "$SRC/$f" "$DEST" 2>/dev/null && echo "Synced: docs/$(basename $f)" || true
done

# Initial commit
git add -A
git commit -m "Initial vault setup" 2>/dev/null || echo "(nothing to commit or already committed)"

echo ""
echo "=== Vault ready ==="
echo ""
echo "Your vault is at: $VAULT"
echo "Visible in: Obsidian, Markor, Termux, Claude Code"
echo ""
echo "To push to GitHub, run these lines one at a time:"
echo ""
echo "  git remote add origin https://github.com/YOUR-USERNAME/n0va-vault.git"
echo ""
echo "  git push -u origin main"
echo ""
echo "(Create the repo on GitHub first, then paste your repo URL above)"
echo ""
echo "To open vault in Claude Code:"
echo "  cd ~/storage/shared/N0VA && claude"
