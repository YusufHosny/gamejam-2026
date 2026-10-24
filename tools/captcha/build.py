# ABOUTME: Builds assets/captcha from the source dog photos and the dog-or-bagel meme grid.
# ABOUTME: Usage: build.py SRC_DIR OUT_DIR (SRC_DIR holds dog1-5.jpg, dogb1-4.jpg, dogbagels.png)
import sys
from pathlib import Path
from PIL import Image, ImageDraw

SIZE = 128
src, out = Path(sys.argv[1]), Path(sys.argv[2])
COLS = [(3, 104), (105, 206), (207, 307), (309, 408)]
ROWS = [(26, 126), (128, 229)]
# meme tiles read left to right, row by row; the top row is cut off in the source
MEME = [["dog", "bagel", "dog", "bagel"], ["bagel", "dog", "bagel", "dog"]]
WATERMARK_TILE = (1, 3) # "Twitter" badge in its bottom right corner

def square(img: Image.Image) -> Image.Image:
    w, h = img.size
    side = min(w, h)
    left, top = (w - side) // 2, (h - side) // 2
    return img.crop((left, top, left + side, top + side)).resize((SIZE, SIZE), Image.LANCZOS)

sets: dict[str, list[Image.Image]] = {"dog": [], "dogb": [], "bagel": []}
for i in range(1, 6): sets["dog"].append(square(Image.open(src / f"dog{i}.jpg").convert("RGB")))
for i in range(1, 5): sets["dogb"].append(square(Image.open(src / f"dogb{i}.jpg").convert("RGB")))
meme = Image.open(src / "dogbagels.png").convert("RGB")
for r, (top, bottom) in enumerate(ROWS):
    for c, (left, right) in enumerate(COLS):
        if (r, c) == WATERMARK_TILE: bottom = 210
        sets[MEME[r][c]].append(square(meme.crop((left + 1, top + 1, right, bottom))))

sheet = Image.new("RGB", (SIZE * 9, (SIZE + 20) * 3), "white")
draw = ImageDraw.Draw(sheet)
for row, (name, images) in enumerate(sets.items()):
    (out / name).mkdir(parents=True, exist_ok=True)
    for i, img in enumerate(images):
        img.save(out / name / f"{name}{i + 1}.png")
        sheet.paste(img, (i * SIZE, row * (SIZE + 20) + 20))
        draw.text((i * SIZE + 4, row * (SIZE + 20) + 4), f"{name}{i + 1}", fill="black")
sheet.save(out / "contact_sheet.png")
print({k: len(v) for k, v in sets.items()})
