"""Converts a GIF into a spritesheet PNG, since Godot can't import GIFs.

usage: python3 tools/gif_to_sheet.py assets/usb.gif assets/usb_sheet.png [columns] [extra.png ...]
Extra PNGs (same size as the gif) are appended after the gif's frames.
Prints the grid size and frame duration to put on the Sprite2D.
"""
import sys

from PIL import Image, ImageSequence

src, dst = sys.argv[1], sys.argv[2]
columns = int(sys.argv[3]) if len(sys.argv) > 3 else 10

gif = Image.open(src)
frames = [f.convert("RGBA") for f in ImageSequence.Iterator(gif)]
gif_frames = len(frames)
frames += [Image.open(path).convert("RGBA") for path in sys.argv[4:]]
width, height = frames[0].size
rows = -(-len(frames) // columns)
sheet = Image.new("RGBA", (width * columns, height * rows), (0, 0, 0, 0))
for i, frame in enumerate(frames):
    sheet.paste(frame, ((i % columns) * width, (i // columns) * height))
sheet.save(dst, optimize=True)
print(f"{gif_frames} gif + {len(frames) - gif_frames} extra frames, hframes={columns} vframes={rows}, {gif.info.get('duration')} ms per frame")
