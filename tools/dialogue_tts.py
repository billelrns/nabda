#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Nabda Dialogue TTS Generator (أداة توليد الأصوات الحوارية لنبضة)
===============================================================
Generates multi-voice dialogue audio for Nabda short video scripts using
ElevenLabs' Text to Dialogue API (POST /v1/text-to-dialogue).

Features:
- Parses dialogue scripts with speaker turns and emotional tone tags ([excited], [warmly], etc.).
- Maps speakers to verified voice IDs in brand_nabda/dialogues/voices.json.
- Splits dialogue into turns-aware batches (<= 2000 chars per batch).
- Concatenates audio batches with smooth silence gaps using FFmpeg.
- Normalizes loudness to -14 LUFS (standard for TikTok, Instagram Reels, YouTube Shorts).
- Generates optional .srt subtitle files for rapid video captioning.
- Dry-run mode for counting characters and budgeting without making paid calls.
- Lists available ElevenLabs voices to pick character voices.
"""

import os
import sys
import json
import re
import shutil
import argparse
import subprocess
from pathlib import Path
from typing import List, Dict, Tuple, Optional

# Ensure UTF-8 output on Windows consoles
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

# Optional dotenv loading
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# Try importing requests
try:
    import requests
except ImportError:
    print("Error: 'requests' package is required. Install with: pip install requests", file=sys.stderr)
    sys.exit(1)

# Default paths relative to workspace root (C:\nabda_app)
WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
DIALOGUES_DIR = WORKSPACE_ROOT / "brand_nabda" / "dialogues"
VOICES_FILE = DIALOGUES_DIR / "voices.json"
SCRIPTS_DIR = DIALOGUES_DIR / "scripts"
OUT_DIR = DIALOGUES_DIR / "out"

DEFAULT_MODEL_ID = "eleven_v3"
MAX_BATCH_CHARS = 2000
API_BASE_URL = "https://api.elevenlabs.io/v1"


def get_ffmpeg_binary() -> str:
    """Finds the ffmpeg executable on PATH or via imageio_ffmpeg."""
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg:
        return ffmpeg
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        pass
    print("Error: FFmpeg not found on PATH and 'imageio-ffmpeg' is not available.", file=sys.stderr)
    print("Please install FFmpeg or run: pip install imageio-ffmpeg", file=sys.stderr)
    sys.exit(1)


def get_api_key() -> str:
    """Retrieves ElevenLabs API key strictly from environment / .env."""
    key = os.getenv("ELEVENLABS_API_KEY") or os.getenv("XI_API_KEY")
    if not key:
        env_path = WORKSPACE_ROOT / ".env"
        if env_path.exists():
            with open(env_path, "r", encoding="utf-8-sig") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("ELEVENLABS_API_KEY=") or line.startswith("XI_API_KEY="):
                        val = line.split("=", 1)[1].strip().strip('"').strip("'")
                        if val:
                            return val
        print("❌ Error: ELEVENLABS_API_KEY is not set.", file=sys.stderr)
        print(f"Please add your ElevenLabs API key to {WORKSPACE_ROOT / '.env'}:", file=sys.stderr)
        print("   ELEVENLABS_API_KEY=sk_...", file=sys.stderr)
        sys.exit(1)
    return key.strip()


def load_voices_config() -> Dict[str, str]:
    """Loads speaker-to-voice_id mappings from voices.json."""
    if not VOICES_FILE.exists():
        print(f"❌ Error: voices.json not found at {VOICES_FILE}", file=sys.stderr)
        sys.exit(1)
    try:
        with open(VOICES_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            return {k.strip().lower(): (v.strip() if isinstance(v, str) else "") for k, v in data.items()}
    except Exception as e:
        print(f"❌ Error reading voices.json: {e}", file=sys.stderr)
        sys.exit(1)


class DialogueTurn:
    def __init__(self, speaker: str, text: str, line_no: int):
        self.speaker = speaker.strip().lower()
        self.text = text.strip()
        self.line_no = line_no
        self.char_count = len(self.text)
        self.tone_tags = re.findall(r"\[([^\]]+)\]", self.text)

    def __repr__(self):
        return f"<Turn {self.speaker} ({self.char_count} chars): {self.text[:35]}...>"


class DialogueScript:
    def __init__(self, filepath: Path):
        self.filepath = filepath
        self.name = filepath.stem
        self.title = ""
        self.declared_speakers = []
        self.turns: List[DialogueTurn] = []
        self.total_chars = 0
        self.speakers_used = set()
        self._parse()

    def _parse(self):
        if not self.filepath.exists():
            raise FileNotFoundError(f"Script file not found: {self.filepath}")

        with open(self.filepath, "r", encoding="utf-8") as f:
            lines = f.readlines()

        for idx, line in enumerate(lines, start=1):
            s = line.strip()
            if not s:
                continue
            if s.startswith("#"):
                meta = s[1:].strip()
                if meta.lower().startswith("title:"):
                    self.title = meta.split(":", 1)[1].strip()
                elif meta.lower().startswith("speakers:"):
                    sp_str = meta.split(":", 1)[1].strip()
                    self.declared_speakers = [x.strip().lower() for x in sp_str.split(",") if x.strip()]
                continue

            if ":" in s:
                speaker_part, text_part = s.split(":", 1)
                speaker = speaker_part.strip().lower()
                text = text_part.strip()
                if not text:
                    continue
                turn = DialogueTurn(speaker, text, idx)
                self.turns.append(turn)
                self.speakers_used.add(speaker)
                self.total_chars += turn.char_count
            else:
                # Malformed turn line
                print(f"⚠️ Warning: Line {idx} ignored in {self.filepath.name} (missing 'speaker: text' format): {s}")

        if not self.title:
            self.title = self.name


def split_into_batches(turns: List[DialogueTurn], max_chars: int = MAX_BATCH_CHARS) -> List[List[DialogueTurn]]:
    """
    Greedily partitions turns into batches under max_chars without cutting across turns.
    """
    batches = []
    current_batch = []
    current_chars = 0

    for turn in turns:
        if current_batch and (current_chars + turn.char_count > max_chars):
            batches.append(current_batch)
            current_batch = [turn]
            current_chars = turn.char_count
        else:
            current_batch.append(turn)
            current_chars += turn.char_count

    if current_batch:
        batches.append(current_batch)

    return batches


def cmd_list_voices(args):
    """Lists available voices in the ElevenLabs account."""
    api_key = get_api_key()
    print("🔄 Fetching available voices from ElevenLabs API...")
    url = f"{API_BASE_URL}/voices"
    headers = {"xi-api-key": api_key}

    try:
        resp = requests.get(url, headers=headers, timeout=20)
        if resp.status_code != 200:
            print(f"❌ ElevenLabs API error ({resp.status_code}): {resp.text}", file=sys.stderr)
            sys.exit(1)
        data = resp.json()
        voices = data.get("voices", [])
        print(f"\n✅ Total voices available: {len(voices)}")

        # Check voices.json to highlight currently assigned voices
        assigned = {}
        if VOICES_FILE.exists():
            assigned = load_voices_config()

        print("-" * 95)
        print(f"{'Voice ID':<24} | {'Name':<22} | {'Category':<14} | {'Labels / Description'}")
        print("-" * 95)

        for v in voices:
            vid = v.get("voice_id", "")
            name = v.get("name", "")
            cat = v.get("category", "")
            labels = v.get("labels", {}) or {}
            labels_str = ", ".join([f"{k}:{val}" for k, val in labels.items() if val])
            
            # Check if this voice is already mapped in voices.json
            matched_roles = [role for role, assigned_id in assigned.items() if assigned_id == vid]
            role_tag = f" 🌟 [Assigned: {', '.join(matched_roles)}]" if matched_roles else ""

            print(f"{vid:<24} | {name:<22} | {cat:<14} | {labels_str}{role_tag}")

        print("-" * 95)
        print("\n💡 Copy desired Voice IDs and paste them into 'brand_nabda/dialogues/voices.json'.")
        print("Example voices.json:")
        print('{\n  "amina": "EOqeBn9r5h39ZDHmwXGa",\n  "sara": "<voice_id_from_above>",\n  "karim": "<voice_id_from_above>"\n}')

    except Exception as e:
        print(f"❌ Request failed: {e}", file=sys.stderr)
        sys.exit(1)


def build_single_script(
    script_path: Path,
    voices_config: Dict[str, str],
    dry_run: bool = False,
    model_id: Optional[str] = None,
    ffmpeg_bin: Optional[str] = None,
    mode: str = "turns"
) -> Tuple[bool, int]:
    """Processes and builds dialogue audio for a single script."""
    print(f"\n==================================================================")
    print(f"📄 SCRIPT: {script_path.name}")
    print(f"==================================================================")

    try:
        script = DialogueScript(script_path)
    except Exception as e:
        print(f"❌ Error loading script {script_path}: {e}", file=sys.stderr)
        return False, 0

    if not script.turns:
        print("⚠️ Warning: No valid dialogue turns found in script.", file=sys.stderr)
        return False, 0

    print(f"📌 Title: {script.title}")
    print(f"👥 Speakers Used ({len(script.speakers_used)}): {', '.join(sorted(script.speakers_used))}")
    print(f"💬 Turns Count: {len(script.turns)}")
    print(f"🔤 Total Characters: {script.total_chars}")

    # Check speakers count (Google policy & dialogue guidelines: 2 to 3 speakers)
    if len(script.speakers_used) < 2 or len(script.speakers_used) > 3:
        print(f"⚠️ Notice: Script has {len(script.speakers_used)} speakers (recommended: 2 or 3 speakers for conversational short video format).")

    # Validate voices
    missing_speakers = []
    empty_voice_ids = []
    for sp in sorted(script.speakers_used):
        if sp not in voices_config:
            missing_speakers.append(sp)
        elif not voices_config[sp]:
            empty_voice_ids.append(sp)

    if missing_speakers:
        print(f"❌ Error: Speaker(s) not defined in voices.json: {', '.join(missing_speakers)}", file=sys.stderr)
        return False, 0

    # Display detailed turn table
    print("\nDialogue Turns Preview:")
    print("-" * 75)
    for i, turn in enumerate(script.turns, start=1):
        vid = voices_config.get(turn.speaker, "")
        vid_display = vid if vid else "[NOT SET]"
        tones = f"({', '.join(turn.tone_tags)})" if turn.tone_tags else ""
        print(f"[{i:02d}] {turn.speaker.upper():<7} [{turn.char_count:3d} chars] {tones:<15} : {turn.text}")
    print("-" * 75)

    # Batching check
    batches = split_into_batches(script.turns, max_chars=MAX_BATCH_CHARS)
    print(f"\n📦 Generation Plan: {len(batches)} batch(es) (<= {MAX_BATCH_CHARS} chars each)")
    for b_idx, batch in enumerate(batches, start=1):
        b_chars = sum(t.char_count for t in batch)
        print(f"   Batch {b_idx}: {len(batch)} turns | {b_chars} chars | Script lines [{batch[0].line_no}..{batch[-1].line_no}]")
        if b_chars > MAX_BATCH_CHARS:
            print(f"   ⚠️ Batch {b_idx} exceeds {MAX_BATCH_CHARS} chars (a single turn is too long) — split that turn into shorter lines.")

    # If DRY-RUN mode: stop here!
    if dry_run:
        print("\n✨ [DRY RUN ACTIVE] — Character budget checked. No API requests were sent.")
        if empty_voice_ids:
            print(f"ℹ️ Reminder: Before running without --dry-run, please set voice_id for: {', '.join(empty_voice_ids)} in voices.json")
        return True, script.total_chars

    # In REAL mode: verify all voice IDs are filled
    if empty_voice_ids:
        print(f"\n❌ Error: The following speaker(s) have empty voice_id in voices.json:", file=sys.stderr)
        for sp in empty_voice_ids:
            print(f"   - '{sp}': '' (empty)", file=sys.stderr)
        print("\nPlease run 'python tools/dialogue_tts.py list-voices' to select voices and configure them in brand_nabda/dialogues/voices.json", file=sys.stderr)
        return False, 0

    api_key = get_api_key()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    temp_dir = OUT_DIR / f"_temp_{script.name}"
    temp_dir.mkdir(parents=True, exist_ok=True)

    batch_audio_files = []

    headers = {
        "xi-api-key": api_key,
        "Content-Type": "application/json"
    }
    if model_id is None:
        model_id = "eleven_v4" if mode == "turns" else DEFAULT_MODEL_ID
    print(f"\n🚀 Starting synthesis — mode: {mode} | model: {model_id}")

    try:
        if mode == "turns":
            # One Text-to-Speech request per turn (best quality with eleven_v4 and
            # cloned Algerian voices), then cleaned, levelled and joined with natural gaps.
            for t_idx, turn in enumerate(script.turns, start=1):
                print(f"   🎙️ Turn {t_idx}/{len(script.turns)} ({turn.speaker}, {turn.char_count} chars)...", end="", flush=True)
                resp = requests.post(f"{API_BASE_URL}/text-to-speech/{voices_config[turn.speaker]}",
                                     headers=headers, json={"text": turn.text, "model_id": model_id}, timeout=90)
                if resp.status_code != 200:
                    print(" ❌ FAILED")
                    print(f"API Error ({resp.status_code}): {resp.text}", file=sys.stderr)
                    return False, 0
                t_out = temp_dir / f"turn_{t_idx:02d}.mp3"
                with open(t_out, "wb") as f_out:
                    f_out.write(resp.content)
                print(" ✅ OK")
                batch_audio_files.append(t_out)
            batches = [[t] for t in script.turns]

        for b_idx, batch in (enumerate(batches, start=1) if mode == "dialogue" else []):
            inputs_payload = []
            for turn in batch:
                inputs_payload.append({
                    "text": turn.text,
                    "voice_id": voices_config[turn.speaker]
                })

            payload = {
                "inputs": inputs_payload,
                "model_id": model_id
            }

            b_chars = sum(t.char_count for t in batch)
            print(f"   🎙️ Generating Batch {b_idx}/{len(batches)} ({b_chars} chars)...", end="", flush=True)

            resp = requests.post(f"{API_BASE_URL}/text-to-dialogue", headers=headers, json=payload, timeout=90)
            if resp.status_code != 200:
                print(" ❌ FAILED")
                print(f"API Error ({resp.status_code}): {resp.text}", file=sys.stderr)
                return False, 0

            batch_out = temp_dir / f"batch_{b_idx:02d}.mp3"
            with open(batch_out, "wb") as f_out:
                f_out.write(resp.content)
            print(" ✅ OK")
            batch_audio_files.append(batch_out)

        # -------------------------------------------------------------
        # Audio Concatenation & Silence Gaps
        # -------------------------------------------------------------
        raw_output_mp3 = OUT_DIR / f"{script.name}.mp3"

        gap = 0.15 if mode == "turns" else 0.25
        # Same EQ/compression/level on every line so the voices sit together, slightly faster pace for energy
        clean = ("silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.03,areverse,"
                 "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.06,areverse,"
                 "highpass=f=85,lowpass=f=11500,equalizer=f=250:t=q:w=1:g=-2,equalizer=f=3200:t=q:w=1.2:g=2,"
                 "acompressor=threshold=-22dB:ratio=3:attack=5:release=90:makeup=2,"
                 "loudnorm=I=-16:TP=-2:LRA=6,atempo=1.04") if mode == "turns" else "anull"
        if len(batch_audio_files) == 1 and mode == "dialogue":
            shutil.copy2(batch_audio_files[0], raw_output_mp3)
        else:
            print(f"🔗 Concatenating {len(batch_audio_files)} clips with {gap}s gap...")
            # Decode every batch to the same PCM format (44.1 kHz mono WAV) so the
            # concat demuxer never mixes streams with different channels/bitrates.
            wav_files = []
            for idx, b_file in enumerate(batch_audio_files):
                wav = temp_dir / f"batch_{idx:02d}.wav"
                subprocess.run([ffmpeg_bin, "-y", "-i", str(b_file), "-af", clean, "-ar", "44100", "-ac", "1", str(wav)],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
                wav_files.append(wav)
            silence_wav = temp_dir / "silence_gap.wav"
            subprocess.run([
                ffmpeg_bin, "-y", "-f", "lavfi", "-t", str(gap),
                "-i", "anullsrc=r=44100:cl=mono", str(silence_wav)
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

            concat_list = temp_dir / "concat_list.txt"
            with open(concat_list, "w", encoding="utf-8") as f_list:
                for idx, w_file in enumerate(wav_files):
                    f_list.write(f"file '{w_file.resolve().as_posix()}'\n")
                    if idx < len(wav_files) - 1:
                        f_list.write(f"file '{silence_wav.resolve().as_posix()}'\n")

            subprocess.run([
                ffmpeg_bin, "-y", "-f", "concat", "-safe", "0",
                "-i", str(concat_list), "-c:a", "libmp3lame", "-b:a", "192k",
                str(raw_output_mp3)
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

        print(f"💾 Raw audio saved: {raw_output_mp3}")

        # -------------------------------------------------------------
        # Loudness Normalization to -14 LUFS (EBU R128 / ITU-R BS.1770)
        # Standard for TikTok, Instagram Reels, YouTube Shorts
        # -------------------------------------------------------------
        norm_output_mp3 = OUT_DIR / f"{script.name}_norm.mp3"
        print(f"🎚️ Normalizing audio to -14 LUFS (loudnorm filter)...")

        subprocess.run([
            ffmpeg_bin, "-y", "-i", str(raw_output_mp3),
            "-af", ("aecho=0.85:0.7:22|41:0.07|0.04,acompressor=threshold=-18dB:ratio=2:attack=10:release=150,"
                    "loudnorm=I=-14:TP=-1.5:LRA=6") if mode == "turns" else "loudnorm=I=-14:LRA=11:TP=-1.5",
            "-ar", "44100", "-b:a", "192k",
            str(norm_output_mp3)
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

        print(f"✅ Normalized audio saved: {norm_output_mp3}")

        # -------------------------------------------------------------
        # Generate Turn-based Subtitles (.srt)
        # -------------------------------------------------------------
        srt_output = OUT_DIR / f"{script.name}.srt"
        generate_turn_subtitles(script, norm_output_mp3, srt_output, ffmpeg_bin)

        # Cleanup temporary files
        try:
            shutil.rmtree(temp_dir)
        except Exception:
            pass

        return True, script.total_chars

    except Exception as e:
        print(f"❌ Error during dialogue generation: {e}", file=sys.stderr)
        return False, 0


def generate_turn_subtitles(script: DialogueScript, audio_path: Path, srt_path: Path, ffmpeg_bin: str):
    """
    Generates structured turn-based subtitles (.srt) proportional to turn character lengths.
    """
    try:
        # Get total audio duration via ffprobe or ffmpeg
        duration_cmd = [
            ffmpeg_bin, "-i", str(audio_path), "-hide_banner"
        ]
        res = subprocess.run(duration_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        dur_match = re.search(r"Duration:\s*(\d+):(\d+):(\d+\.\d+)", res.stderr)
        if not dur_match:
            return

        hours, minutes, seconds = dur_match.groups()
        total_seconds = int(hours) * 3600 + int(minutes) * 60 + float(seconds)

        total_chars = max(1, script.total_chars)
        current_time = 0.1  # slight start offset

        with open(srt_path, "w", encoding="utf-8") as f:
            for idx, turn in enumerate(script.turns, start=1):
                # Turn duration proportional to characters with slight pause padding
                turn_dur = (turn.char_count / total_chars) * (total_seconds - 0.2)
                start_sec = current_time
                end_sec = min(total_seconds, start_sec + turn_dur)
                current_time = end_sec + 0.05

                # Clean tone tags for clean visual captions (e.g. remove [laughs])
                caption_text = re.sub(r"\s*\[[^\]]+\]\s*", " ", turn.text).strip()

                start_fmt = format_srt_time(start_sec)
                end_fmt = format_srt_time(end_sec)

                f.write(f"{idx}\n{start_fmt} --> {end_fmt}\n{caption_text}\n\n")

        print(f"📝 Subtitles (.srt) generated: {srt_path}")
        print("   ℹ️ Timings are estimated from text length — review them in CapCut/Premiere before publishing.")
    except Exception as e:
        print(f"⚠️ Note: Subtitle generation skipped ({e})")


def format_srt_time(seconds: float) -> str:
    hrs = int(seconds // 3600)
    mins = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int(round((seconds - int(seconds)) * 1000))
    if millis >= 1000:
        millis = 999
    return f"{hrs:02d}:{mins:02d}:{secs:02d},{millis:03d}"


def cmd_build(args):
    """Builds dialogue audio for a specified script file."""
    ffmpeg_bin = get_ffmpeg_binary()
    voices_config = load_voices_config()

    script_path = Path(args.script)
    if not script_path.exists():
        # Check in default scripts folder
        candidate = SCRIPTS_DIR / args.script
        if candidate.exists():
            script_path = candidate
        else:
            print(f"❌ Error: Script file not found at: {script_path}", file=sys.stderr)
            sys.exit(1)

    success, chars = build_single_script(
        script_path=script_path,
        voices_config=voices_config,
        dry_run=args.dry_run,
        model_id=args.model_id,
        ffmpeg_bin=ffmpeg_bin,
        mode=args.mode
    )
    if not success and not args.dry_run:
        sys.exit(1)


def cmd_build_all(args):
    """Builds dialogue audio for all script files in brand_nabda/dialogues/scripts."""
    ffmpeg_bin = get_ffmpeg_binary()
    voices_config = load_voices_config()

    if not SCRIPTS_DIR.exists():
        print(f"❌ Error: Scripts directory not found at: {SCRIPTS_DIR}", file=sys.stderr)
        sys.exit(1)

    script_files = sorted(list(SCRIPTS_DIR.glob("*.txt")))
    if not script_files:
        print(f"ℹ️ No .txt scripts found in {SCRIPTS_DIR}")
        return

    print(f"🎯 Found {len(script_files)} script(s) in {SCRIPTS_DIR}\n")
    total_corpus_chars = 0
    success_count = 0

    for script_file in script_files:
        success, chars = build_single_script(
            script_path=script_file,
            voices_config=voices_config,
            dry_run=args.dry_run,
            model_id=args.model_id,
            ffmpeg_bin=ffmpeg_bin,
            mode=args.mode
        )
        if success or args.dry_run:
            total_corpus_chars += chars
            success_count += 1

    print("\n" + "=" * 60)
    print("📊 BATCH PROCESSING SUMMARY:")
    print(f"   Scripts Processed: {success_count}/{len(script_files)}")
    print(f"   Total Characters Across All Scripts: {total_corpus_chars}")
    if args.dry_run:
        print("   Status: Dry Run Completed (No API quota used)")
    print("=" * 60)


def main():
    parser = argparse.ArgumentParser(
        description="Nabda Dialogue TTS — Multi-voice Dialogue Generator via ElevenLabs API"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Subcommand: list-voices
    subparsers.add_parser(
        "list-voices",
        help="List available ElevenLabs voices with their Voice IDs"
    )

    # Subcommand: build
    build_parser = subparsers.add_parser(
        "build",
        help="Build dialogue audio from a single script file"
    )
    build_parser.add_argument("script", help="Path to script .txt file")
    build_parser.add_argument("--dry-run", action="store_true", help="Inspect character count & batches without calling API")
    build_parser.add_argument("--model-id", default=None, help="ElevenLabs model ID (default: eleven_v4 in turns mode, eleven_v3 in dialogue mode)")
    build_parser.add_argument("--mode", choices=["turns", "dialogue"], default="turns", help="turns = one TTS call per line (recommended); dialogue = Text-to-Dialogue API")

    # Subcommand: build-all
    build_all_parser = subparsers.add_parser(
        "build-all",
        help="Build dialogue audio for all scripts in brand_nabda/dialogues/scripts"
    )
    build_all_parser.add_argument("--dry-run", action="store_true", help="Inspect character count & batches without calling API")
    build_all_parser.add_argument("--model-id", default=None, help="ElevenLabs model ID (default: eleven_v4 in turns mode, eleven_v3 in dialogue mode)")
    build_all_parser.add_argument("--mode", choices=["turns", "dialogue"], default="turns", help="turns = one TTS call per line (recommended); dialogue = Text-to-Dialogue API")

    args = parser.parse_args()

    if args.command == "list-voices":
        cmd_list_voices(args)
    elif args.command == "build":
        cmd_build(args)
    elif args.command == "build-all":
        cmd_build_all(args)


if __name__ == "__main__":
    main()
