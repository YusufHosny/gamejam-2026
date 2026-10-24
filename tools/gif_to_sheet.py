"""Converts a GIF into a spritesheet PNG, since Godot can't import GIFs.

usage: python3 tools/gif_to_sheet.py assets/usb.gif assets/usb_sheet.png [columns]
Prints the grid size and frame duration to put on the Sprite2D.
"""
import sys

from PIL import Image, ImageSequence

src, dst = sys.argv[1], sys.argv[2]
columns = int(sys.argv[3]) if len(sys.argv) > 3 else 10

gif = Image.open(src)
frames = [f.convert("RGBA") for f in ImageSequence.Iterator(gif)]
width, height = frames[0].size
rows = -(-len(frames) // columns)
sheet = Image.new("RGBA", (width * columns, height * rows), (0, 0, 0, 0))
for i, frame in enumerate(frames):
    sheet.paste(frame, ((i % columns) * width, (i // columns) * height))
sheet.save(dst, optimize=True)
print(f"{len(frames)} frames, hframes={columns} vframes={rows}, {gif.info.get('duration')} ms per frame")
