# ABOUTME: Turns the subway clip's camera flow into the runner's moves, printed as a GDScript table for CaptchaMaps.
# ABOUTME: Usage: moves.py FLOW.npy FIRST_BEAT_S BPM   (flow from flow.py, beat grid from the clip's Song)
import sys
from dataclasses import dataclass
from typing import Literal

import numpy as np

FPS = 30
LANE_THRESHOLD = 1.5
QUANTUM_BEATS = 0.25
MIN_GAP_S = 0.3 # a lane change this close to a jump or roll is the camera wobbling

Direction = Literal["left", "right", "up", "down"]


@dataclass
class Move:
    time_s: float
    direction: Direction
    strength: float


# vertical camera flow can't tell a roll from a landing, so these were labelled by eye from frame strips
VERTICAL: list[Move] = [
    Move(2.65, "down", 9.0),   # rolls under the striped barrier
    Move(5.8, "down", 9.0),    # rolls under the next one
    Move(19.1, "up", 9.0),     # jump
    Move(20.6, "up", 9.0),     # jumps up onto the train
    Move(26.9, "up", 9.0),     # jump
]


def detrend(a: np.ndarray, window: int = 31) -> np.ndarray:
    pad = np.pad(a, window // 2, mode="edge")
    base = np.array([np.median(pad[i:i + window]) for i in range(len(a))])
    return np.convolve(a - base, np.ones(3) / 3, mode="same")


# scene sliding right means the camera, and runner, moved left
def lane_changes(flow: np.ndarray) -> list[Move]:
    x = detrend(flow[:, 0])
    moves, i = [], 0
    while i < len(x):
        if abs(x[i]) <= LANE_THRESHOLD:
            i += 1
            continue
        j = i
        while j < len(x) and abs(x[j]) > LANE_THRESHOLD: j += 1
        peak = i + int(np.argmax(np.abs(x[i:j])))
        moves.append(Move(i / FPS, "left" if x[peak] > 0 else "right", float(abs(x[peak]))))
        i = j
    return moves


# strongest set of lane changes that never leaves the three lanes, brute force since there are few
def valid_lanes(moves: list[Move]) -> list[Move]:
    best, best_strength = [], -1.0
    for mask in range(1 << len(moves)):
        subset = [m for i, m in enumerate(moves) if mask >> i & 1]
        lane, low, high = 0, 0, 0
        for m in subset:
            lane += -1 if m.direction == "left" else 1
            low, high = min(low, lane), max(high, lane)
        strength = sum(m.strength for m in subset)
        if high - low <= 2 and strength > best_strength: best, best_strength = subset, strength
    return best


def main(flow_path: str, first_beat_s: float, bpm: float) -> None:
    lanes = [m for m in lane_changes(np.load(flow_path)) if all(abs(m.time_s - v.time_s) >= MIN_GAP_S for v in VERTICAL)]
    moves = sorted(valid_lanes(lanes) + VERTICAL, key=lambda m: m.time_s)
    print("const SUBWAY_MOVES := [ # [beat, direction], from tools/subway/moves.py")
    for m in moves:
        beat = round((m.time_s - first_beat_s) * bpm / 60 / QUANTUM_BEATS) * QUANTUM_BEATS
        print(f'\t[{beat}, Vector2.{m.direction.upper()}], # {m.time_s:.2f}s')
    print("]")


if __name__ == "__main__":
    main(sys.argv[1], float(sys.argv[2]), float(sys.argv[3]))
