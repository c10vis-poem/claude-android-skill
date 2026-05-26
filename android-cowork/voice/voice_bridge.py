#!/usr/bin/env python3
"""
Android Voice Bridge for Claude Code

Orchestrates: mic → Whisper STT → Claude Code → Kokoro/Piper TTS → speaker

Usage:
  python3 voice_bridge.py              # Interactive voice loop
  python3 voice_bridge.py --test       # Test pipeline (no microphone needed)
  python3 voice_bridge.py --once       # Single voice command, then exit
  python3 voice_bridge.py --text ".." # Skip STT, send text directly
  python3 voice_bridge.py --voice am_michael  # Choose Kokoro voice

Voice options (Kokoro): af_heart, af_bella, af_nova, am_michael, am_fenrir
TTS priority: Kokoro > Piper > Android TTS (termux-tts-speak)

Requires:
  - Termux:API installed + microphone permission granted
  - Whisper.cpp built (setup/4_voice_setup.sh)
  - Kokoro TTS (setup/4b_kokoro_tts.sh) OR Piper (setup/4_voice_setup.sh)
  - Claude Code CLI installed (setup/2_claude_superclaude.sh)
"""
import argparse
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

# ── Configuration ──────────────────────────────────────────────────────────────
HOME = Path.home()
VOICE_DIR = HOME / "voice"

WHISPER_BIN   = os.environ.get("WHISPER_BIN",   str(VOICE_DIR / "whisper.cpp/build/bin/whisper-cli"))
WHISPER_MODEL = os.environ.get("WHISPER_MODEL", str(VOICE_DIR / "whisper.cpp/models/ggml-base.en.bin"))
PIPER_BIN     = os.environ.get("PIPER_BIN",     str(VOICE_DIR / "piper/piper"))
PIPER_MODEL   = os.environ.get("PIPER_MODEL",   str(VOICE_DIR / "piper/voices/en_US-ryan-high.onnx"))
KOKORO_VOICE  = os.environ.get("KOKORO_VOICE",  "af_heart")

RECORD_DURATION    = int(os.environ.get("RECORD_SECONDS", "8"))
MAX_RESPONSE_SPEAK = int(os.environ.get("MAX_SPEAK_CHARS", "600"))
WORK_DIR           = os.environ.get("CLAUDE_WORKDIR", str(HOME))

STOP_WORDS = {"stop", "exit", "quit", "goodbye", "bye", "cancel"}


# ── TTS: Kokoro (best quality) ─────────────────────────────────────────────────────

_kokoro_pipeline = None

def _get_kokoro(voice: str):
    """Lazy-load Kokoro pipeline (downloads model on first call)."""
    global _kokoro_pipeline
    try:
        from kokoro import KPipeline  # type: ignore
        if _kokoro_pipeline is None:
            print("  [Kokoro] Loading voice model...")
            _kokoro_pipeline = KPipeline(lang_code='a')
        return _kokoro_pipeline, voice
    except ImportError:
        return None, None


def speak_kokoro(text: str, voice: str = KOKORO_VOICE) -> bool:
    """Speak with Kokoro TTS. Returns True if successful."""
    try:
        import soundfile as sf  # type: ignore
        pipeline, v = _get_kokoro(voice)
        if pipeline is None:
            return False

        tmp = tempfile.mktemp(suffix=".wav", prefix="kokoro_")
        for i, (gs, ps, audio) in enumerate(pipeline(text, voice=v)):
            sf.write(tmp, audio, 24000)
            subprocess.run(["termux-media-player", "play", tmp],
                          capture_output=True, timeout=60)
            word_count = len(text.split())
            time.sleep(max(1.5, word_count / 2.5))
            Path(tmp).unlink(missing_ok=True)
            break
        return True
    except Exception as e:
        print(f"  [Kokoro error: {e}]")
        return False


def speak_piper(text: str) -> bool:
    """Speak with Piper TTS. Returns True if successful."""
    if not Path(PIPER_BIN).exists() or not Path(PIPER_MODEL).exists():
        return False
    tmp = tempfile.mktemp(suffix=".wav", prefix="piper_")
    try:
        subprocess.run(
            [PIPER_BIN, "--model", PIPER_MODEL, "--output_file", tmp],
            input=text.encode(), capture_output=True, timeout=30
        )
        subprocess.run(["termux-media-player", "play", tmp],
                      capture_output=True, timeout=60)
        time.sleep(max(1.5, len(text.split()) / 2.5))
        return True
    except Exception as e:
        print(f"  [Piper error: {e}]")
        return False
    finally:
        Path(tmp).unlink(missing_ok=True)


def speak(text: str, voice: str = KOKORO_VOICE) -> None:
    """Speak text. Priority: Kokoro > Piper > Android TTS."""
    text = text[:MAX_RESPONSE_SPEAK].strip()
    if not text:
        return
    if speak_kokoro(text, voice):
        return
    if speak_piper(text):
        return
    # Final fallback: Android built-in TTS
    try:
        subprocess.run(["termux-tts-speak", text], timeout=60)
    except Exception:
        print(f"  [TTS]: {text}")


# ── STT: Whisper.cpp ─────────────────────────────────────────────────────────────────

def record_audio(duration: int = RECORD_DURATION) -> str:
    tmp = tempfile.mktemp(suffix=".wav", prefix="claude_voice_")
    print(f"  [Recording {duration}s… speak now]")
    result = subprocess.run(
        ["termux-microphone-record", "-l", str(duration), "-f", "wav", "-o", tmp],
        capture_output=True, text=True, timeout=duration + 10
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Mic failed: {result.stderr}\n"
            "Check: Termux:API app installed + mic permission granted in Android Settings."
        )
    return tmp


def transcribe(audio_path: str) -> str:
    if not Path(WHISPER_BIN).exists():
        raise FileNotFoundError(
            f"Whisper not found at {WHISPER_BIN}\n"
            "Run: bash ~/android-cowork/setup/4_voice_setup.sh"
        )
    out_base = audio_path.replace(".wav", "")
    subprocess.run(
        [WHISPER_BIN, "-m", WHISPER_MODEL, "-f", audio_path,
         "-nt", "--output-txt", "--output-file", out_base],
        capture_output=True, text=True, timeout=60
    )
    txt = Path(out_base + ".txt")
    text = txt.read_text().strip() if txt.exists() else ""
    txt.unlink(missing_ok=True)
    return text


# ── Claude ───────────────────────────────────────────────────────────────────────────

def ask_claude(prompt: str) -> str:
    result = subprocess.run(
        ["claude", "--print", prompt],
        capture_output=True, text=True,
        cwd=WORK_DIR, env=os.environ.copy(), timeout=180
    )
    if result.returncode != 0:
        return f"Error: {result.stderr.strip() or 'Claude exited with error'}"
    return result.stdout.strip()


# ── Main loop ────────────────────────────────────────────────────────────────────────

def voice_loop(once: bool = False, voice: str = KOKORO_VOICE) -> None:
    print("\n╔═══════════════════════════════════════╗")
    print("║  Android Voice Bridge — Claude Code   ║")
    print("║  Voice: {:30s}  ║".format(voice))
    print("╚═══════════════════════════════════════╝")
    print("Press Enter to record. Say 'stop' to quit.\n")

    speak("Voice bridge ready. Press enter to begin.", voice)

    while True:
        try:
            input("[Press Enter to speak] ")
        except (KeyboardInterrupt, EOFError):
            speak("Goodbye.", voice)
            break

        audio_path = None
        try:
            audio_path = record_audio()
            print("  [Transcribing...]")
            text = transcribe(audio_path)

            if not text or len(text.strip()) < 3:
                print("  [No speech detected]")
                continue

            print(f"\n  You: {text}")

            if any(w in text.lower().split() for w in STOP_WORDS):
                speak("Goodbye.", voice)
                break

            speak("Got it. Asking Claude.", voice)
            print("  [Asking Claude...]")
            response = ask_claude(text)
            print(f"\n  Claude: {response}\n")
            speak(response, voice)

        except KeyboardInterrupt:
            speak("Goodbye.", voice)
            break
        except Exception as e:
            print(f"  [!] {e}")
            speak("Error occurred. Try again.", voice)
        finally:
            if audio_path:
                Path(audio_path).unlink(missing_ok=True)

        if once:
            break


def test_pipeline(voice: str = KOKORO_VOICE) -> None:
    print("Testing voice pipeline...\n")

    print("  [1/3] TTS test...")
    speak("Voice pipeline test. Step one of three.", voice)
    print("  TTS: OK")

    print("  [2/3] Claude Code test...")
    response = ask_claude("Reply with exactly five words: voice bridge test is successful")
    print(f"  Claude: {response[:80]}")

    print("  [3/3] Whisper presence check...")
    whisper_ok = Path(WHISPER_BIN).exists()
    model_ok   = Path(WHISPER_MODEL).exists()
    print(f"  Whisper binary : {'OK' if whisper_ok else 'MISSING — run setup/4_voice_setup.sh'}")
    print(f"  Whisper model  : {'OK' if model_ok  else 'MISSING — run setup/4_voice_setup.sh'}")

    speak("Test complete. Check terminal for results.", voice)
    print("\nAll tests done.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Android Voice Bridge for Claude Code")
    parser.add_argument("--test",  action="store_true")
    parser.add_argument("--once",  action="store_true")
    parser.add_argument("--text",  type=str, default=None)
    parser.add_argument("--voice", type=str, default=KOKORO_VOICE,
                        help="Kokoro voice: af_heart af_bella af_nova am_michael am_fenrir")
    args = parser.parse_args()

    if args.test:
        test_pipeline(args.voice)
    elif args.text:
        print(f"Sending: {args.text}")
        response = ask_claude(args.text)
        print(f"Claude: {response}")
        speak(response, args.voice)
    else:
        voice_loop(once=args.once, voice=args.voice)


if __name__ == "__main__":
    main()
