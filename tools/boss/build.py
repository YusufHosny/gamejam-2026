# ABOUTME: Builds the final boss art: the submit button, round osu-style versions and angry red variants, steel shields split from the sheet, laser and lightsaber glows.
# ABOUTME: Usage: build.py REPO_DIR SRC_DIR   (SRC_DIR holds submit.png and sheilds.jpg)
import colorsys
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

sys.path.insert(0, str(Path(__file__).parent.parent))
from cutout import cut_out

SHIELD_DARK = 90 # luminance below this is shield body, the rest is its rim
WORK_SCALE = 4
OUT_SCALE = 2
STEEL_TOP = np.array([168, 180, 196])
STEEL_BOTTOM = np.array([72, 84, 100])
RIM = np.array([236, 242, 248])
LASER_RED = (255, 36, 48)
ROUND_SIZE = 256
BLUE = (30, 144, 255)
RED = (214, 0, 0)


# the blue button turned red and a little darker, white text untouched
def angry(button: Image.Image) -> Image.Image:
    rgba = np.asarray(button).astype(float) / 255
    out = rgba.copy()
    for y in range(rgba.shape[0]):
        for x in range(rgba.shape[1]):
            r, g, b, a = rgba[y, x]
            h, s, v = colorsys.rgb_to_hsv(r, g, b)
            if s > 0.25: out[y, x, :3] = colorsys.hsv_to_rgb(0.0, min(1.0, s * 1.15), v * 0.85)
    return Image.fromarray((out * 255).astype(np.uint8))


# osu style hit circle: white rim, lighter top, the button's own label
def round_button(color: tuple[int, int, int], label: str) -> Image.Image:
    size = ROUND_SIZE
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse((4, 4, size - 4, size - 4), fill=(20, 20, 28, 255))
    draw.ellipse((10, 10, size - 10, size - 10), fill=(255, 255, 255, 255))
    inner = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shade = Image.linear_gradient("L").resize((size, size))
    top = tuple(min(255, int(c * 1.25) + 30) for c in color)
    body = Image.composite(Image.new("RGBA", (size, size), color + (255,)), Image.new("RGBA", (size, size), top + (255,)), shade)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((22, 22, size - 22, size - 22), fill=255)
    inner.paste(body, (0, 0), mask)
    img.alpha_composite(inner)
    font = ImageFont.load_default(54)
    width = draw.textlength(label, font=font)
    draw.text(((size - width) / 2, size / 2 - 34), label, font=font, fill=(255, 255, 255, 255))
    return img


# connected dark blobs on the sheet, each cut out and recoloured to steel
def shields(sheet: Image.Image) -> list[Image.Image]:
    gray = np.asarray(sheet.convert("L"))
    dark = gray < SHIELD_DARK
    labels = np.zeros(dark.shape, int)
    boxes = []
    for y, x in zip(*np.nonzero(dark)):
        if labels[y, x]: continue
        stack, ys, xs = [(y, x)], [], []
        labels[y, x] = len(boxes) + 1
        while stack:
            cy, cx = stack.pop()
            ys.append(cy)
            xs.append(cx)
            for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                if 0 <= ny < dark.shape[0] and 0 <= nx < dark.shape[1] and dark[ny, nx] and not labels[ny, nx]:
                    labels[ny, nx] = len(boxes) + 1
                    stack.append((ny, nx))
        if len(ys) > 500: boxes.append((min(xs), min(ys), max(xs) + 1, max(ys) + 1))
    # a shield's outline and its body are separate blobs, keep only the outer box
    boxes = [b for b in boxes if not any(o != b and o[0] <= b[0] and o[1] <= b[1] and o[2] >= b[2] and o[3] >= b[3] for o in boxes)]
    boxes.sort(key=lambda b: (b[1] // 100, b[0])) # rows then columns
    out = []
    for left, top, right, bottom in boxes:
        out.append(_steel(sheet.crop((left - 4, top - 4, right + 4, bottom + 4))))
    return out


# worked at 4x so the outline and rim come out smooth, saved at 2x the size it's drawn
def _steel(crop: Image.Image) -> Image.Image:
    big = cut_out(crop.resize((crop.width * WORK_SCALE, crop.height * WORK_SCALE), Image.LANCZOS), tolerance=40)
    big = ImageOps.expand(big, border=WORK_SCALE * 2, fill=(0, 0, 0, 0)) # room for the feathered edge
    rgba = np.asarray(big).astype(float)
    soft = np.asarray(big.getchannel("A").filter(ImageFilter.GaussianBlur(WORK_SCALE * 0.6))).astype(float)
    gray = rgba[..., :3].mean(axis=2)
    t = np.linspace(0, 1, rgba.shape[0])[:, None, None]
    steel = STEEL_TOP * (1 - t) + STEEL_BOTTOM * t
    rim = np.clip((gray - 60) / 120, 0, 1)[..., None] # 0 shield body .. 1 white rim, smooth in between
    rgba[..., :3] = steel * (1 - rim) + RIM * rim
    rgba[..., 3] = soft
    out = Image.fromarray(rgba.astype(np.uint8))
    return out.resize((out.width * OUT_SCALE // WORK_SCALE, out.height * OUT_SCALE // WORK_SCALE), Image.LANCZOS)


# white core with a slight blur over a heavy red blur
def glow_line(size: tuple[int, int], start: tuple[int, int], end: tuple[int, int], core: int, glow: int) -> Image.Image:
    red = Image.new("RGBA", size, LASER_RED + (0,))
    ImageDraw.Draw(red).line([start, end], fill=LASER_RED + (255,), width=glow)
    red = red.filter(ImageFilter.GaussianBlur(glow * 0.6))
    white = Image.new("RGBA", size, (255, 255, 255, 0))
    ImageDraw.Draw(white).line([start, end], fill=(255, 255, 255, 255), width=core)
    white = white.filter(ImageFilter.GaussianBlur(1.2))
    return Image.alpha_composite(red, white)


def laser() -> Image.Image: return glow_line((512, 64), (32, 32), (480, 32), core=6, glow=18)


# blade points up, solid black hilt at the bottom
def saber() -> Image.Image:
    img = glow_line((80, 360), (40, 24), (40, 284), core=8, glow=20)
    draw = ImageDraw.Draw(img)
    draw.rectangle((30, 280, 50, 352), fill=(0, 0, 0, 255))
    for y in (292, 304, 316):
        draw.line((30, y, 50, y), fill=(70, 70, 76, 255), width=2)
    draw.rectangle((26, 280, 54, 286), fill=(0, 0, 0, 255))
    return img


def main(repo: Path, src: Path) -> None:
    out = repo / "assets/boss"
    (out / "shields").mkdir(parents=True, exist_ok=True)
    button = cut_out(Image.open(src / "submit.png"))
    button.save(out / "submit.png")
    angry(button).save(out / "submit_angry.png")
    round_button(BLUE, "Submit").save(out / "submit_round.png")
    round_button(RED, "Submit").save(out / "submit_round_angry.png")
    for i, shield in enumerate(shields(Image.open(src / "sheilds.jpg").convert("RGB"))):
        shield.save(out / "shields" / f"shield_{i + 1}.png")
    laser().save(out / "laser.png")
    saber().save(out / "saber.png")
    print(f"{len(list((out / 'shields').glob('*.png')))} shields, buttons, laser and saber in {out}")


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]))
