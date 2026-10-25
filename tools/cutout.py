# ABOUTME: Shared image helper for the asset tools: removes a photo's white background.
# ABOUTME: Flood fills near-white in from the borders, so white inside the subject survives.
from collections import deque

import numpy as np
from PIL import Image

WHITE_TOLERANCE = 60 # also takes the soft floor shadow under stock photos


def cut_out(img: Image.Image, tolerance: int = WHITE_TOLERANCE) -> Image.Image:
    rgba = np.asarray(img.convert("RGBA")).copy()
    h, w = rgba.shape[:2]
    white = (255 - rgba[..., :3].astype(int)).max(axis=2) <= tolerance
    seen = np.zeros((h, w), bool)
    queue = deque((y, x) for y in range(h) for x in (0, w - 1)) + deque((y, x) for x in range(w) for y in (0, h - 1))
    while queue:
        y, x = queue.popleft()
        if seen[y, x] or not white[y, x]: continue
        seen[y, x] = True
        queue.extend(p for p in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)) if 0 <= p[0] < h and 0 <= p[1] < w)
    rgba[seen, 3] = 0
    out = Image.fromarray(rgba)
    return out.crop(out.getbbox())
