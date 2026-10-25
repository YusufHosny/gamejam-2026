# ABOUTME: Turns tools/music/fetch.sh downloads into fixed-tempo game music (.ogg) plus bpm / first beat data.
# ABOUTME: Drifting live recordings are time-warped so every beat lands on an exact grid. Usage: process.py RAW_DIR OUT_DIR [track ...]
import json
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

import librosa
import numpy as np
import pyloudnorm as pyln
import soundfile as sf

SR = 44100
N_FFT = 2048
HOP = 512
SMOOTH_BEATS = 9
DRUMS_GAIN = 0.8
GLASS_GAIN = 0.9
SCREAM_UNDER_LU = 1.0 # the scream sits this far under the drums
LOUDNESS_LUFS = -16.0 # every track is brought to this so sections don't jump in volume
TRIM_DB: dict[str, float] = { # by ear, on top of the loudness match
    "vivaldi_summer": 0.0,
    "moonlight_3rd": 0.0,
    "ad_music": 0.0,
    "scream_mix": 0.0,
    "subway_surfers": 0.0,
}
LIMIT = 0.95 # quiet tracks get boosted, the limiter keeps their peaks from clipping


@dataclass
class Track:
    name: str
    bpm: float
    first_beat_s: float
    duration_s: float
    warped: bool
    max_drift_ms: float


def load(path: Path, max_s: float | None = None) -> np.ndarray:
    y, _ = librosa.load(path, sr=SR, mono=False, duration=max_s)
    return np.atleast_2d(y)


def beats_of(y: np.ndarray) -> np.ndarray:
    mono = librosa.to_mono(y)
    _, beats = librosa.beat.beat_track(y=mono, sr=SR, hop_length=HOP, units="time")
    return beats


# beat tracker output jitters by a frame, so tempo is smoothed before warping to it
def smoothed(beats: np.ndarray) -> np.ndarray:
    intervals = np.diff(beats)
    median = np.median(intervals)
    intervals = np.where((intervals < median * 0.6) | (intervals > median * 1.6), median, intervals)
    kernel = np.ones(SMOOTH_BEATS) / SMOOTH_BEATS
    padded = np.pad(intervals, SMOOTH_BEATS // 2, mode="edge")
    intervals = np.convolve(padded, kernel, mode="valid")
    return np.concatenate([[beats[0]], beats[0] + np.cumsum(intervals)])


def max_drift_ms(beats: np.ndarray) -> float:
    k = np.arange(len(beats))
    slope, intercept = np.polyfit(k, beats, 1)
    return float(np.abs(beats - (slope * k + intercept)).max() * 1000)


# phase vocoder that reads the source at a per-frame position instead of a fixed rate
def warp(y: np.ndarray, beats: np.ndarray) -> tuple[np.ndarray, float]:
    period = float(np.median(np.diff(beats)))
    grid = beats[0] + period * np.arange(len(beats))
    out_frames = int((grid[-1] + (y.shape[-1] / SR - beats[-1])) * SR / HOP)
    out_times = np.arange(out_frames) * HOP / SR
    # identity before the first beat, slope 1 after the last
    in_times = np.interp(out_times, grid, beats, left=None, right=None)
    in_times = np.where(out_times < grid[0], out_times, in_times)
    in_times = np.where(out_times > grid[-1], beats[-1] + (out_times - grid[-1]), in_times)
    steps = in_times * SR / HOP

    channels = []
    for channel in y:
        stft = librosa.stft(channel, n_fft=N_FFT, hop_length=HOP)
        stft = np.pad(stft, [(0, 0), (0, 2)])
        steps_c = np.clip(steps, 0, stft.shape[1] - 2.001)
        advance = np.linspace(0, np.pi * HOP, stft.shape[0])
        phase = np.angle(stft[:, 0])
        out = np.zeros((stft.shape[0], len(steps_c)), dtype=np.complex64)
        for t, step in enumerate(steps_c):
            left = int(step)
            alpha = step - left
            a, b = stft[:, left], stft[:, left + 1]
            out[:, t] = ((1 - alpha) * np.abs(a) + alpha * np.abs(b)) * np.exp(1j * phase)
            delta = np.angle(b) - np.angle(a) - advance
            delta -= 2 * np.pi * np.round(delta / (2 * np.pi))
            phase += advance + delta
        channels.append(librosa.istft(out, hop_length=HOP))
    return np.stack(channels), 60 / period


# perceived loudness (ITU-R BS.1770), a voice reads far louder than drums at the same rms
def lufs(y: np.ndarray) -> float: return float(pyln.Meter(SR).integrated_loudness(np.atleast_2d(y).T))


def gain_to(clip: np.ndarray, target_lufs: float) -> float:
    return float(10 ** ((target_lufs - lufs(clip)) / 20))


def fade(y: np.ndarray, out_s: float = 2.0) -> np.ndarray:
    n = int(out_s * SR)
    y = y.copy()
    y[..., -n:] *= np.linspace(1, 0, n)
    return y


# loudness matched to LOUDNESS_LUFS plus the track's trim, then limited
def export(y: np.ndarray, path: Path) -> None:
    y = y * gain_to(y, LOUDNESS_LUFS + TRIM_DB.get(path.stem, 0.0))
    wav = path.with_suffix(".wav")
    sf.write(wav, y.T, SR, subtype="FLOAT")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-af", f"alimiter=limit={LIMIT}:level=disabled", "-c:a", "libvorbis", "-q:a", "5", path], check=True)
    wav.unlink()


def process_music(raw: Path, out: Path, name: str, max_s: float | None, do_warp: bool) -> Track:
    y = load(raw / f"{name}.wav", max_s)
    beats = beats_of(y)
    drift = max_drift_ms(beats)
    if do_warp:
        y, bpm = warp(y, smoothed(beats))
        beats = beats_of(y)
    else:
        bpm = 60 / float(np.polyfit(np.arange(len(beats)), beats, 1)[0])
    bpm = round(bpm, 2)
    # anchor beat 0 on the grid that best fits all detected beats
    period = 60 / bpm
    first = float(np.median(beats - period * np.arange(len(beats))))
    first %= period
    if max_s is not None: y = fade(y)
    export(y, out / f"{name}.ogg")
    print(f"{name}: bpm={bpm} first={first:.3f}s drift before={drift:.0f}ms after={max_drift_ms(beats):.0f}ms")
    return Track(name, bpm, round(first, 4), round(y.shape[-1] / SR, 2), do_warp, round(max_drift_ms(beats), 1))


# drum beat with glass breaks on the downbeats and the scream looped over it
def scream_mix(raw: Path, out: Path, length_s: float) -> Track:
    drums = load(raw / "drums.wav", length_s + 4)
    glass = load(raw / "glass.wav")
    scream = load(raw / "scream.wav")
    beats = beats_of(drums)
    bpm = 100.0
    period = 60 / bpm
    first = float(np.median(beats - period * np.arange(len(beats)))) % period
    bar = 4 * period

    glass_onsets = librosa.onset.onset_detect(y=librosa.to_mono(glass), sr=SR, units="samples", backtrack=True)
    crash = glass[..., glass_onsets[0]: glass_onsets[0] + int(2.5 * SR)]
    scream = scream[..., np.argmax(np.abs(librosa.to_mono(scream)) > 0.05):]

    mix = drums[..., : int(length_s * SR)] * DRUMS_GAIN
    target = lufs(mix) - SCREAM_UNDER_LU
    scream_gain = gain_to(scream, target)
    def add(clip: np.ndarray, at_s: float, gain: float) -> None:
        start = int(at_s * SR)
        end = min(start + clip.shape[-1], mix.shape[-1])
        if start < end: mix[..., start:end] += clip[..., : end - start] * gain
    for i, at in enumerate(np.arange(first, length_s, 8 * bar)):
        add(crash, at, GLASS_GAIN)
    for at in np.arange(first + 2 * bar, length_s, 5 * bar):
        add(scream, at, scream_gain)
    mix /= max(1.0, np.abs(mix).max())
    mix = fade(mix)
    export(mix, out / "scream_mix.ogg")
    print(f"scream_mix: bpm={bpm} first={first:.3f}s length={length_s}s scream gain={scream_gain:.3f} ({target:.1f} LUFS)")
    return Track("scream_mix", bpm, round(first, 4), round(length_s, 2), False, 0.0)


BUILDS = {
    "vivaldi_summer": lambda raw, out: process_music(raw, out, "vivaldi_summer", None, do_warp=True),
    "moonlight_3rd": lambda raw, out: process_music(raw, out, "moonlight_3rd", 120.0, do_warp=True),
    "ad_music": lambda raw, out: process_music(raw, out, "ad_music", None, do_warp=False),
    "scream_mix": lambda raw, out: scream_mix(raw, out, 90.0),
    "subway_surfers": lambda raw, out: process_music(raw, out, "subway_surfers", None, do_warp=False),
}


# rebuilds the named tracks (default all) and merges them into tracks.json
def main(raw: Path, out: Path, names: list[str]) -> None:
    out.mkdir(parents=True, exist_ok=True)
    index = out / "tracks.json"
    tracks = {t["name"]: t for t in json.loads(index.read_text())} if index.exists() else {}
    for name in names or list(BUILDS):
        tracks[name] = asdict(BUILDS[name](raw, out))
    index.write_text(json.dumps(list(tracks.values()), indent=2))


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3:])
