# ABOUTME: Checks processed tracks stay on their beat grid: circular mean of onset phase per 15 s window.
# ABOUTME: Usage: check.py OUT_DIR [track ...]
import json, sys
import librosa
import numpy as np

tracks = {t["name"]: t for t in json.load(open(sys.argv[1] + "/tracks.json"))}
names = sys.argv[2:] or ["vivaldi_summer", "moonlight_3rd", "ad_music", "scream_mix"]
for name in names:
    t = tracks[name]
    y, sr = librosa.load(f"{sys.argv[1]}/{name}.ogg", sr=22050, mono=True)
    hop = 128
    env = librosa.onset.onset_strength(y=y, sr=sr, hop_length=hop)
    times = librosa.frames_to_time(np.arange(len(env)), sr=sr, hop_length=hop)
    period = 60 / t["bpm"]
    angle = 2 * np.pi * (times - t["first_beat_s"]) / period
    rows = []
    for start in range(0, int(times[-1]) - 5, 15):
        m = (times >= start) & (times < start + 15)
        z = np.sum(env[m] * np.exp(1j * angle[m])) / np.sum(env[m])
        rows.append(f"{np.angle(z) / (2 * np.pi) * period * 1000:+.0f}ms(R{abs(z):.2f})")
    print(f"{name} @ {t['bpm']}: " + " ".join(rows))
