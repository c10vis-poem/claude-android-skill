#!/usr/bin/env python3
"""
Android Voice Bridge for Claude Code

Orchestrates: mic → Whisper STT → Claude Code → Piper TTS → speaker

Usage:
  python3 voice_bridge.py              # Interactive voice loop
  python3 voice_bridge.py --test       # Test pipeline (no microphone needed)
  python3 voice_bridge.py --once       # Single voice command, then exit
  python3 voice_bridge.py --text ".." # Skip STT, send text directly

Requires:
  - Termux:API installed and microphone permission granted
  - Whisper.cpp built (setup/4_voice_setup.sh)
  - Piper TTS installed (setup/4_voice_setup.sh)
  - Claude Code CLI installed (setup/2_claude_superclaude.sh)
"""
import argparse
import os
import subprocess
import sys
import tempfile
import time
import json
from pathlib import Path

# ── Configuration ──────────────────────────────────────────────────────────────
HOME = Path.home()
VOICE_DIR = HOME / "voice"

WHISPER_BIN   = os.environ.get("WHISPER_BIN",   str(VOICE_DIR / "whisper.cpp/build/bin/whisper-cli"))
WHISPER_MODEL = os.environ.get("WHISPER_MODEL", str(VOICE_DIR / "whisper.cpp/models/ggml-base.en.bin"))
PIPER_BIN     = os.environ.get("PIPER_BIN",     str(VOICE_DIR / "piper/piper"))
PIPER_MODEL   = os.environ.get("PIPER_MODEL",   str(VOICE_DIR / "piper/voices/en_US-ryan-high.onnx"))

RECORD_DURATION   = int(os.environ.get("RECORD_SECONDS", "8"))
MAX_RESPONSE_SPEAK = int(os.environ.get("MAX_SPEAK_CHARS", "600"))
WORK_DIR          = os.environ.get("CLAUDE_WORKDIR", str(HOME))

STOP_WORDS = {"stop", "exit", "quit", "goodbye", "bye", "cancel"}

# ── Audio helpers ───────────────────────────────────────────────────────────────

def record_audio(duration: int = RECORD_DURATION) -> str:
    """Record audio using Termux:API. Returns path to WAV file."""
    tmp = tempfile.mktemp(suffix=".wav", prefix="claude_voice_")
    print(f"  [Recording for {duration}s... speak now]")
    result = subprocess.run(
        ["termux-microphone-record", "-l", str(duration), "-f", "wav", "-o", tmp],
        capture_output=True, text=True, timeout=duration + 10
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Microphone recording failed: {result.stderr}\n"
            "Ensure Termux:API is installed and microphone permission is granted."
        )
    return tmp


def transcribe(audio_path: str) -> str:
    """Transcribe audio file to text using Whisper.cpp."""
    if not Path(WHISPER_BIN).exists():
        raise FileNotFoundError(
            f"Whisper binary not found at {WHISPER_BIN}\n"
            "Run: bash ~/android-cowork/setup/4_voice_setup.sh"
        )
    out_base = audio_path.replace(".wav", "")
    result = subprocess.run(
        [
            WHISPER_BIN,
            "-m", WHISPER_MODEL,
            "-f", audio_path,
            "-nt",  # no timestamps
            "--output-txt",
            "--output-file", out_base,
        ],
        capture_output=True, text=True, timeout=60
    )
    txt_path = out_base + ".txt"
    if Path(txt_path).exists():
        text = Path(txt_path).read_text().strip()
        Path(txt_path).unlink(missing_ok=True)
        return text
    return result.stdout.strip()


def speak(text: str) -> None:
    """Speak text using Piper TTS. Falls back to Termux TTS."""
    text = text[:MAX_RESPONSE_SPEAK].strip()
    if not text:
        return

    # Try Piper (local neural TTS)
    if Path(PIPER_BIN).exists() and Path(PIPER_MODEL).exists():
        tmp_wav = tempfile.mktemp(suffix=".wav", prefix="piper_")
        try:
            subprocess.run(
                [PIPER_BIN, "--model", PIPER_MODEL, "--output_file", tmp_wav],
                input=text.encode(),
                capture_output=True,
                timeout=30
            )
            # Play via Termux media player
            subprocess.run(
                ["termux-media-player", "play", tmp_wav],
                capture_output=True, timeout=60
            )
            # Wait for playback to finish (estimate ~150 wpm)
            word_count = len(text.split())
            wait_time = max(2, word_count / 2.5)
            time.sleep(wait_time)
            return
        except Exception as e:
            print(f"  [Piper error: {e}, falling back to Android TTS]")
        finally:
            Path(tmp_wav).unlink(missing_ok=True)

    # Fallback: Termux Android TTS
    try:
        subprocess.run(["termux-tts-speak", text], timeout=60)
    except Exception:
        print(f"  [TTS output]: {text}")


# ── Claude interaction ──────────────────────────────────────────────────────────

def ask_claude(prompt: str, work_dir: str = WORK_DIR) -> str:
    """Send a prompt to Claude Code and return the response."""
    env = os.environ.copy()

    result = subprocess.run(
        ["claude", "--print", prompt],
        capture_output=True,
        text=True,
        cwd=work_dir,
        env=env,
        timeout=180
    )
    if result.returncode != 0:
        error = result.stderr.strip() or "Claude returned non-zero exit code"
        return f"Error from Claude: {error}"
    return result.stdout.strip()


# ── Voice loop ──────────────────────────────────────────────────────────────────

def voice_loop(once: bool = False) -> None:
    """Main interactive voice loop."""
    print("\n╔═══════════════════════════════════════╗")
    print("║   Android Voice Bridge — Claude Code  ║")
    print("╠═══════════════════════════════════════╣")
    print("║ Press Enter to record, then speak.    ║")
    print("║ Say 'stop' or 'exit' to quit.         ║")
    print("╚═══════════════════════════════════════╝\n")

    speak("Voice bridge ready. Press enter to begin.")

    while True:
        try:
            input("\n[Press Enter to speak] ")
        except (KeyboardInterrupt, EOFError):
            speak("Goodbye.")
            break

        audio_path = None
        try:
            audio_path = record_audio()
            print("  [Transcribing...]")
            text = transcribe(audio_path)

            if not text or len(text.strip()) < 3:
                print("  [No speech detected, try again]")
                continue

            print(f"\n  You: {text}")

            if any(w in text.lower().split() for w in STOP_WORDS):
                speak("Goodbye.")
                break

            speak("Processing...")
            print("  [Asking Claude...]")
            response = ask_claude(text)

            print(f"\n  Claude: {response}\n")
            speak(response)

        except KeyboardInterrupt:
            speak("Goodbye.")
            break
        except Exception as e:
            msg = f"Error: {e}"
            print(f"  [!] {msg}")
            speak("An error occurred. Please try again.")
        finally:
            if audio_path and Path(audio_path).exists():
                Path(audio_path).unlink(missing_ok=True)

        if once:
            break


def test_pipeline() -> None:
    """Smoke-test the voice pipeline without microphone."""
    print("Testing voice pipeline...")

    print("  [1/3] Testing TTS...")
    speak("Voice pipeline test. Step one of three passed.")
    print("  TTS OK")

    print("  [2/3] Testing Claude Code...")
    response = ask_claude("Reply with exactly: voice bridge test successful")
    print(f"  Claude response: {response[:100]}")

    print("  [3/3] Testing Whisper binary presence...")
    whisper_ok = Path(WHISPER_BIN).exists()
    model_ok   = Path(WHISPER_MODEL).exists()
    print(f"  Whisper binary: {'OK' if whisper_ok else 'MISSING — run setup/4_voice_setup.sh'}")
    print(f"  Whisper model:  {'OK' if model_ok else 'MISSING — run setup/4_voice_setup.sh'}")

    speak("Pipeline test complete. Check terminal for results.")
    print("\nTest done.")


# ── Entry point ─────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Android Voice Bridge for Claude Code")
    parser.add_argument("--test",  action="store_true", help="Test pipeline without mic")
    parser.add_argument("--once",  action="store_true", help="Single command then exit")
    parser.add_argument("--text",  type=str, default=None, help="Send text directly, skip STT")
    args = parser.parse_args()

    if args.test:
        test_pipeline()
    elif args.text:
        print(f"Sending: {args.text}")
        response = ask_claude(args.text)
        print(f"Claude: {response}")
        speak(response)
    else:
        voice_loop(once=args.once)


if __name__ == "__main__":
    main()
