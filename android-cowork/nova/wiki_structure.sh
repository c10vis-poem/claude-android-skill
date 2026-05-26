#!/data/data/com.termux/files/usr/bin/bash
# Create the N0.V4 wiki and log directory structure
# Run on Razr for the local structure
# Run on Jetson for the hub structure

set -e

NOVA="$HOME/nova"

echo "Creating N0.V4 directory structure at $NOVA"

# Raw layer (immutable logs)
mkdir -p "$NOVA/logs"
touch "$NOVA/logs/interaction_logs.jsonl"
touch "$NOVA/logs/.gitkeep"
mkdir -p "$NOVA/logs/voice_transcripts"

# Compiled wiki layer
mkdir -p "$NOVA/wiki/entities"
mkdir -p "$NOVA/wiki/patterns"
mkdir -p "$NOVA/wiki/synthesis"

# Create wiki index
cat > "$NOVA/wiki/index.md" << 'EOF'
# N0.V4 Wiki Index

> Compiled by Docker CLI #2. Opt-in entries only.
> Max ~200 active pages. Sparsity is the signal.

## Patterns
<!-- Links to /wiki/patterns/ entries -->

## Entities
<!-- Links to /wiki/entities/ entries (people, tools, concepts) -->

## Synthesis
<!-- Links to /wiki/synthesis/ entries (cross-cutting analyses) -->
EOF

# Append-only log
cat > "$NOVA/wiki/log.md" << 'EOF'
# N0.V4 Wiki Log

> Chronological append-only. Never edited, only appended.

EOF

# Config layer
mkdir -p "$NOVA/config"

# Copy schema files if they exist
SRC="$HOME/android-cowork/nova"
for f in routing_rules.json failure_rules.json sharpening_gates.json; do
  [ -f "$SRC/$f" ] && cp "$SRC/$f" "$NOVA/config/$f" && echo "Copied: $f"
done

# Training data (Phase 3)
mkdir -p "$NOVA/training/approved"
mkdir -p "$NOVA/training/pending"
mkdir -p "$NOVA/training/rejected"
touch "$NOVA/training/approved/.gitkeep"

echo ""
echo "Structure created at $NOVA"
echo ""
echo "  nova/logs/                ← raw immutable logs (never modified)"
echo "  nova/wiki/index.md        ← opt-in wiki catalog"
echo "  nova/wiki/log.md          ← append-only chronological log"
echo "  nova/wiki/patterns/       ← failure + success patterns"
echo "  nova/wiki/entities/       ← people, tools, concepts"
echo "  nova/wiki/synthesis/      ← cross-cutting analysis"
echo "  nova/config/              ← schema JSON files"
echo "  nova/training/            ← approved LoRA training pairs"
echo ""
echo "IMPORTANT: /nova/logs/ is immutable. Never edit log files."
echo "Wiki entries are compiled by Docker CLI #2 only."
