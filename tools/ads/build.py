# ABOUTME: Pre-composes each popup ad into a retro window PNG, and cuts the virus cutscene's buttons out of their white backgrounds.
# ABOUTME: Usage: build.py REPO_DIR STICKER_SRC_DIR   (STICKER_SRC_DIR holds submit-fake.jpg and "virus button.jpg")
import re
import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

WINDOW = "assets/Retro Dekstop/UI/2X/Windows_Med_Active.png"
TITLE_H = 34 # title bar plus the rule under it, in window texture pixels
BUTTONS_W = 54 # minimize, maximize, close on the right of the title bar
BORDER = 4
MAX_AD = (220, 160)
PAD = 4
PAPER = (241, 238, 230)
WHITE_TOLERANCE = 60 # also takes the soft floor shadow under the stock photos
VIRUS_FOOTER = 26 # shutterstock strip along the bottom


def _stretch(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    return img.resize((max(size[0], 1), max(size[1], 1)), Image.NEAREST)


# 9-slice of the window texture where the title bar keeps its buttons unstretched
def window(content: tuple[int, int], src: Image.Image) -> Image.Image:
    w, h = content[0] + 2 * BORDER, content[1] + TITLE_H + BORDER
    sw, sh = src.size
    out = Image.new("RGBA", (w, h))
    out.paste(src.crop((0, 0, BORDER, TITLE_H)), (0, 0))
    out.paste(_stretch(src.crop((BORDER, 0, sw - BUTTONS_W, TITLE_H)), (w - BORDER - BUTTONS_W, TITLE_H)), (BORDER, 0))
    out.paste(src.crop((sw - BUTTONS_W, 0, sw, TITLE_H)), (w - BUTTONS_W, 0))
    body_h = h - TITLE_H - BORDER
    out.paste(_stretch(src.crop((0, TITLE_H, BORDER, sh - BORDER)), (BORDER, body_h)), (0, TITLE_H))
    out.paste(_stretch(src.crop((BORDER, TITLE_H, sw - BORDER, sh - BORDER)), (w - 2 * BORDER, body_h)), (BORDER, TITLE_H))
    out.paste(_stretch(src.crop((sw - BORDER, TITLE_H, sw, sh - BORDER)), (BORDER, body_h)), (w - BORDER, TITLE_H))
    out.paste(src.crop((0, sh - BORDER, BORDER, sh)), (0, h - BORDER))
    out.paste(_stretch(src.crop((BORDER, sh - BORDER, sw - BORDER, sh)), (w - 2 * BORDER, BORDER)), (BORDER, h - BORDER))
    out.paste(src.crop((sw - BORDER, sh - BORDER, sw, sh)), (w - BORDER, h - BORDER))
    return out


# wide enough for the title to clear the buttons, narrow ads sit centred
def popup(ad: Image.Image, title: str, src: Image.Image) -> Image.Image:
    ad = ad.convert("RGBA")
    ad.thumbnail(MAX_AD, Image.LANCZOS)
    font = ImageFont.load_default(13)
    title_w = int(font.getlength(title)) + 8 + BUTTONS_W + 6 - 2 * BORDER
    content = (max(ad.width + 2 * PAD, title_w), ad.height + 2 * PAD)
    out = window(content, src)
    out.alpha_composite(ad, (BORDER + (content[0] - ad.width) // 2, TITLE_H + PAD))
    ImageDraw.Draw(out).text((8, 4), title, font=font, fill="white")
    return out


def slug(name: str) -> str: return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


# flood fill near-white from the borders to transparent, so white inside the button survives
def cut_out(img: Image.Image) -> Image.Image:
    rgba = np.asarray(img.convert("RGBA")).copy()
    h, w = rgba.shape[:2]
    white = (255 - rgba[..., :3].astype(int)).max(axis=2) <= WHITE_TOLERANCE
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


def paper_back(sticker: Image.Image) -> Image.Image:
    alpha = sticker.getchannel("A")
    back = Image.new("RGBA", sticker.size, PAPER + (255,))
    shade = Image.linear_gradient("L").resize(sticker.size).point(lambda v: 255 - v // 6)
    back = Image.composite(back, Image.new("RGBA", sticker.size, (200, 196, 188, 255)), shade)
    back.putalpha(alpha)
    return back


def main(repo: Path, sticker_src: Path) -> None:
    src = Image.open(repo / WINDOW).convert("RGBA")
    out_dir = repo / "assets/ads/windows"
    out_dir.mkdir(parents=True, exist_ok=True)
    for path in sorted((repo / "assets/Popup Ads").iterdir()):
        if path.suffix.lower() not in {".png", ".jpg", ".jpeg", ".gif"}: continue
        ad = Image.open(path) # a gif opens on its first frame
        popup(ad, path.stem.upper(), src).save(out_dir / f"{slug(path.stem)}.png")
    virus_dir = repo / "assets/cutscenes/virus"
    virus_dir.mkdir(parents=True, exist_ok=True)
    submit = cut_out(Image.open(sticker_src / "submit-fake.jpg"))
    submit.save(virus_dir / "submit_sticker.png")
    paper_back(submit).save(virus_dir / "sticker_back.png")
    virus = Image.open(sticker_src / "virus button.jpg")
    cut_out(virus.crop((0, 0, virus.width, virus.height - VIRUS_FOOTER))).save(virus_dir / "virus_button.png")
    print(f"{len(list(out_dir.glob('*.png')))} windows, stickers in {virus_dir}")


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]))
