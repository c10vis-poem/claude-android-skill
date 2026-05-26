#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# Android AI Workstation — Step 4b: Kokoro TTS (better voice)
# Installs Kokoro neural TTS — higher quality than Piper.
# Run this after 4_voice_setup.sh or instead of it.
# ============================================================
set -euo pipefail

echo "==> Installing Kokoro TTS and audio dependencies..."
pip install kokoro soundfile onnxruntime

echo "==> Testing Kokoro (first run downloads ~100 MB model)..."
python3 - << 'PYEOF'
from kokoro import KPipeline
import soundfile as sf
print("Downloading Kokoro model on first use (100 MB, one-time only)...")
pipeline = KPipeline(lang_code='a')
for i, (gs, ps, audio) in enumerate(pipeline("Kokoro voice setup complete. Android AI Workstation is ready.", voice='af_heart')):
    sf.write('/tmp/kokoro_test.wav', audio, 24000)
    break
print("Model ready. Audio saved to /tmp/kokoro_test.wav")
PYEOF

termux-media-player play /tmp/kokoro_test.wav 2>/dev/null || \
  termux-tts-speak "Kokoro test complete" 2>/dev/null || true

echo ""
echo "==> Kokoro installed! Available voices:"
python3 -c "
voices = ['af_heart (warm, natural)', 'af_bella (bright)', 'af_nova (clear)', 'am_michael (male)', 'am_fenrir (deep male)']
[print(f'   {v}') for v in voices]
"
echo ""
echo "    To change voice: set KOKORO_VOICE=am_michael (or any voice above)"
echo "    Default voice: af_heart"
