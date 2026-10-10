# -*- coding: utf-8 -*-
import os
import sys
import requests
import subprocess
import speech_recognition as sr
from pathlib import Path
import imageio_ffmpeg

sys.stdout.reconfigure(encoding='utf-8')

ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
key = 'sk_a2ca57acbebeef7c89b4af0783dbf79d05cd95a4de286004'
headers = {'xi-api-key': key, 'Content-Type': 'application/json'}

script_file = Path(r'C:\nabda_app\brand_nabda\dialogues\scripts\d02_al_qareen_dua.txt')
out_dir = Path(r'C:\nabda_app\brand_nabda\dialogues\out')
out_dir.mkdir(parents=True, exist_ok=True)

# Voices: Callum for Qareen, Amina for Fatat
voices = {
    'qareen': 'N2lVS1w4EtoT3dr4eOWO',
    'fatat': 'EOqeBn9r5h39ZDHmwXGa'
}

with open(script_file, 'r', encoding='utf-8') as f:
    lines = [l.strip() for l in f if l.strip() and not l.startswith('#')]

clips = []
for idx, line in enumerate(lines, 1):
    speaker, text = line.split(':', 1)
    speaker = speaker.strip().lower()
    text = text.strip()
    vid = voices[speaker]
    
    print(f'Synthesizing Turn {idx} ({speaker}): {text[:40]}...')
    payload = {
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
            'stability': 0.40 if speaker == 'qareen' else 0.55,
            'similarity_boost': 0.85
        }
    }
    r = requests.post(f'https://api.elevenlabs.io/v1/text-to-speech/{vid}', headers=headers, json=payload, timeout=30)
    raw_mp3 = out_dir / f'turn_{idx}_{speaker}.mp3'
    with open(raw_mp3, 'wb') as out_f:
        out_f.write(r.content)
        
    # If qareen, apply demonic whisper pitch effect via ffmpeg
    if speaker == 'qareen':
        filtered_mp3 = out_dir / f'turn_{idx}_{speaker}_fx.mp3'
        subprocess.run([
            ffmpeg_exe, '-y', '-i', str(raw_mp3),
            '-af', 'asetrate=44100*0.88,aresample=44100,aecho=0.8:0.85:35:0.35',
            str(filtered_mp3)
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        clips.append(filtered_mp3)
    else:
        clips.append(raw_mp3)

# Concatenate all clips
concat_txt = out_dir / 'concat_corrected.txt'
with open(concat_txt, 'w', encoding='utf-8') as f:
    for c in clips:
        f.write(f"file '{c.resolve().as_posix()}'\n")

merged_mp3 = out_dir / 'd02_al_qareen_dua.mp3'
subprocess.run([
    ffmpeg_exe, '-y', '-f', 'concat', '-safe', '0', '-i', str(concat_txt), '-c', 'copy', str(merged_mp3)
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

# Normalize to -14 LUFS
norm_mp3 = out_dir / 'd02_al_qareen_dua_norm.mp3'
subprocess.run([
    ffmpeg_exe, '-y', '-i', str(merged_mp3),
    '-af', 'loudnorm=I=-14:LRA=11:TP=-1.5',
    '-ar', '44100', '-b:a', '192k',
    str(norm_mp3)
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

print('\n✅ SUCCESS! Corrected and normalized audio saved to:', norm_mp3)

# Speech recognition test
wav_test = out_dir / 'test_final.wav'
subprocess.run([ffmpeg_exe, '-y', '-i', str(norm_mp3), '-ar', '16000', '-ac', '1', str(wav_test)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
r_stt = sr.Recognizer()
with sr.AudioFile(str(wav_test)) as src:
    a_test = r_stt.record(src)
print('\n🎧 Speech Recognition Verification:')
print(r_stt.recognize_google(a_test, language='ar'))
