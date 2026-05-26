#!/data/data/com.termux/files/usr/bin/bash
# Sync all N0.V4 docs to Markor-accessible shared storage
# Run this once after setup, then it's handled by weekly_audit.sh automatically

SRC="$HOME/android-cowork"
DST="$HOME/storage/shared/N0VA"

echo "Syncing N0.V4 docs to Markor..."
echo ""

# Check shared storage is available
if [ ! -d "$HOME/storage/shared" ]; then
  echo "Shared storage not set up. Run this first:"
  echo "  termux-setup-storage"
  echo "Then re-run this script."
  exit 1
fi

mkdir -p "$DST/docs"
mkdir -p "$DST/audit"
mkdir -p "$DST/config"

# Copy all markdown docs
for f in SETUP_GUIDE.md SKILL.md; do
  cp "$SRC/$f" "$DST/docs/$f" 2>/dev/null && echo "  docs/$f" || true
done

# Copy audit files
for f in audit/weekly_audit_terminal.md audit/failure_log.md; do
  cp "$SRC/$f" "$DST/docs/$(basename $f)" 2>/dev/null && echo "  docs/$(basename $f)" || true
done

# Copy config reference files (read-only reference, not the live ones)
for f in config/vertex_env.sh config/ob1_mcp.json; do
  cp "$SRC/$f" "$DST/config/$(basename $f)" 2>/dev/null && echo "  config/$(basename $f)" || true
done

echo ""
echo "Done. In Markor, look in the N0VA/ folder."
echo ""
echo "Folder structure:"
echo "  N0VA/"
echo "  ├── docs/"
echo "  │   ├── SETUP_GUIDE.md"
echo "  │   ├── SKILL.md"
echo "  │   ├── weekly_audit_terminal.md"
echo "  │   └── failure_log.md"
echo "  ├── audit/         ← weekly handoff files go here"
echo "  └── config/        ← config file references"
