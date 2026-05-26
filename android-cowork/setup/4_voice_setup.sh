#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# Android AI Workstation — Step 4: Local Voice (STT + TTS)
# Builds Whisper.cpp (STT) and installs Piper TTS for offline
# voice interaction. No cloud, no API keys needed for voice.
# ============================================================
set -euo pipefail

VOICE_DIR="$HOME/voice"
mkdir -p "$VOICE_DIR"

# ---- Whisper.cpp (Speech-to-Text) ----------------------------
echo "==> Building Whisper.cpp for ARM64..."
echo "    This takes ~10 minutes on most Android devices. Stay patient."

cd "$VOICE_DIR"
if [ ! -d whisper.cpp ]; then
  git clone --depth 1 https://github.com/ggerganov/whisper.cpp
else
  echo "   whisper.cpp already cloned, skipping"
fi

cd whisper.cpp
mkdir -p build
cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_NATIVE=ON \
  -DWHISPER_BUILD_TESTS=OFF \
  -DWHISPER_BUILD_EXAMPLES=ON
cmake --build build --config Release -j"$(nproc)"

WHISPER_BIN="$VOICE_DIR/whisper.cpp/build/bin/whisper-cli"
# Older versions use 'main' as binary name
[ -f "$WHISPER_BIN" ] || WHISPER_BIN="$VOICE_DIR/whisper.cpp/build/bin/main"

echo "==> Downloading Whisper base.en model (142 MB)..."
bash ./models/download-ggml-model.sh base.en

echo "    Model saved to: $VOICE_DIR/whisper.cpp/models/ggml-base.en.bin"

# Write whisper wrapper script
cat > "$VOICE_DIR/transcribe.sh" << WEOF
#!/data/data/com.termux/files/usr/bin/bash
# Usage: transcribe.sh audio.wav
AUDIO_FILE="\$1"
"$WHISPER_BIN" \
  -m "$VOICE_DIR/whisper.cpp/models/ggml-base.en.bin" \
  -f "\$AUDIO_FILE" \
  -nt \
  --output-txt \
  --output-file "\${AUDIO_FILE%.wav}"
cat "\${AUDIO_FILE%.wav}.txt" 2>/dev/null
WEOF
chmod +x "$VOICE_DIR/transcribe.sh"

# ---- Piper TTS (Text-to-Speech) ------------------------------
echo "==> Installing Piper TTS (ARM64 binary)..."
PIPER_DIR="$VOICE_DIR/piper"
mkdir -p "$PIPER_DIR/voices"

PIPER_RELEASE="2023.11.14-2"
PIPER_URL="https://github.com/rhasspy/piper/releases/download/${PIPER_RELEASE}/piper_linux_aarch64.tar.gz"

wget -q --show-progress -O /tmp/piper.tar.gz "$PIPER_URL"
tar -xzf /tmp/piper.tar.gz -C "$PIPER_DIR" --strip-components=1
rm /tmp/piper.tar.gz
chmod +x "$PIPER_DIR/piper"

echo "==> Downloading Ryan voice model (en_US-ryan-high, 60 MB)..."
BASE_URL="https://huggingface.co/rhasspy/piper-voices/resolve/main/en_US/en_US-ryan-high/high"
wget -q --show-progress -O "$PIPER_DIR/voices/en_US-ryan-high.onnx" "$BASE_URL/en_US-ryan-high.onnx"
wget -q --show-progress -O "$PIPER_DIR/voices/en_US-ryan-high.onnx.json" "$BASE_URL/en_US-ryan-high.onnx.json"

# Write piper speak wrapper
cat > "$VOICE_DIR/speak.sh" << SEOF
#!/data/data/com.termux/files/usr/bin/bash
# Usage: speak.sh "text to speak"
# Outputs to /tmp/speech.wav and plays via Termux media player
TEXT="\$*"
OUT="/tmp/speech_\$\$.wav"
echo "\$TEXT" | "$PIPER_DIR/piper" \
  --model "$PIPER_DIR/voices/en_US-ryan-high.onnx" \
  --output_file "\$OUT" 2>/dev/null
termux-media-player play "\$OUT" 2>/dev/null || \
  termux-tts-speak "\$TEXT" 2>/dev/null || \
  echo "[TTS] \$TEXT"
rm -f "\$OUT"
SEOF
chmod +x "$VOICE_DIR/speak.sh"

# Write convenience env additions
grep -q 'VOICE_DIR' "$HOME/.bashrc" 2>/dev/null || cat >> "$HOME/.bashrc" << 'BEOF'

# Android AI Workstation — voice tools
export VOICE_DIR="$HOME/voice"
export WHISPER_BIN="$VOICE_DIR/whisper.cpp/build/bin/whisper-cli"
export WHISPER_MODEL="$VOICE_DIR/whisper.cpp/models/ggml-base.en.bin"
export PIPER_BIN="$VOICE_DIR/piper/piper"
export PIPER_MODEL="$VOICE_DIR/piper/voices/en_US-ryan-high.onnx"
export PATH="$VOICE_DIR:$PATH"
BEOF

echo ""
echo "==> Step 4 complete! Testing voice pipeline..."
"$VOICE_DIR/speak.sh" "Voice setup complete. Android AI Workstation is ready."
echo ""
echo "    To start voice interaction:"
echo "    python3 ~/android-cowork/voice/voice_bridge.py"
