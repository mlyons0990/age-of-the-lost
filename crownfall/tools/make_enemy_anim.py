"""Turns a green-screen Higgsfield clip into an enemy animation sheet for Godot.

usage: make_enemy_anim.py clip.mp4 ref_still.png out_prefix start-end:count [hue]

- ref_still.png is the enemy's existing keyed sprite (assets/enemies/<key>.png). The clip's
  first frame shows the same pose, so it sets the scale (matched by silhouette height)
  and the feet position. Every frame of the clip gets the same transform (the camera
  is fixed), so motion inside the clip is kept.
- Picks `count` frames evenly from `start` to `end` (inclusive) and writes
  out_prefix.png (a grid of cells) and out_prefix.json (cell size, columns, frame count
  and the feet anchor inside a cell, in the same pixel scale as the still).
- hue: "hexcaller" applies the Gravecaller recolour (violet to spectral green).
"""
import sys, os, json, subprocess, tempfile, glob
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from key_sprite import key

COLS = 6


def bbox(im, thr=60):
    return im.getchannel("A").point(lambda p: 255 if p > thr else 0).getbbox()


def recolor_hexcaller(im):
    """Same shift as the Gravecaller still: violets to sickly teal-green, golds to bone."""
    al = im.getchannel("A")
    hsv = np.asarray(im.convert("RGB").convert("HSV")).astype(float) / 255
    h, s, v = hsv[..., 0].copy(), hsv[..., 1].copy(), hsv[..., 2].copy()
    purple = (h > 0.55) & (h < 0.9) & (s > 0.15)
    h[purple] = 0.43 + (h[purple] - 0.72) * 0.3
    s[purple] = np.minimum(1, s[purple] * 1.15)
    gold = (h > 0.05) & (h < 0.18) & (s > 0.25)
    s[gold] *= 0.35
    v *= 0.92
    out = Image.fromarray((np.stack([h % 1, s, v], -1) * 255).astype("uint8"), "HSV").convert("RGB")
    out.putalpha(al)
    return out


def main():
    clip, ref, out, spec = sys.argv[1:5]
    hue = sys.argv[5] if len(sys.argv) > 5 else ""
    rng, count = spec.split(":")
    a, b = [int(x) for x in rng.split("-")]
    count = int(count)
    tmp = tempfile.mkdtemp()
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", clip, tmp + "/%03d.png"], check=True)
    frames = sorted(glob.glob(tmp + "/*.png"))
    b = min(b, len(frames) - 1)
    ref_im = Image.open(ref).convert("RGBA")
    rb = bbox(ref_im)
    f0 = key(Image.open(frames[0]))
    fb = bbox(f0)
    s = (rb[3] - rb[1]) / (fb[3] - fb[1])
    # work on a generous canvas, then crop every cell to the union of what the frames cover
    cw = int(round(ref_im.width * 4.0))
    ch = int(round(ref_im.height * 3.2))
    ax = cw / 2.0
    ay = ch - ref_im.height * 0.6
    # where the clip's first-frame feet (bottom centre of its silhouette) land in the cell
    fx = (fb[0] + fb[2]) / 2.0 * s
    fy = fb[3] * s
    picks = [round(a + (b - a) * i / max(1, count - 1)) for i in range(count)]
    cells = []
    for i, n in enumerate(picks):
        im = key(Image.open(frames[n]))
        if hue == "hexcaller":
            im = recolor_hexcaller(im)
        im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
        cell = Image.new("RGBA", (cw, ch))
        dx, dy = round(ax - fx), round(ay - fy)
        # paste with clipping (frames can extend past the cell)
        sx, sy = max(0, -dx), max(0, -dy)
        crop = im.crop((sx, sy, min(im.width, cw - dx), min(im.height, ch - dy)))
        cell.alpha_composite(crop, (dx + sx, dy + sy))
        cells.append(cell)
    # union of visible pixels across all frames, plus a small margin
    box = None
    for c in cells:
        bb = c.getchannel("A").point(lambda p: 255 if p > 6 else 0).getbbox()
        if bb:
            box = bb if box is None else (min(box[0], bb[0]), min(box[1], bb[1]), max(box[2], bb[2]), max(box[3], bb[3]))
    box = (max(0, box[0] - 4), max(0, box[1] - 4), min(cw, box[2] + 4), min(ch, box[3] + 4))
    cw, ch = box[2] - box[0], box[3] - box[1]
    ax, ay = ax - box[0], ay - box[1]
    rows = (count + COLS - 1) // COLS
    sheet = Image.new("RGBA", (cw * min(COLS, count), ch * rows))
    for i, c in enumerate(cells):
        sheet.alpha_composite(c.crop(box), ((i % COLS) * cw, (i // COLS) * ch))
    sheet.save(out + ".png")
    # the anchor is where the still's feet sit; the still is drawn at (-w/2, -h + 8)
    meta = {"frames": count, "cols": min(COLS, count), "cw": cw, "ch": ch, "ax": ax, "ay": ay,
            "source": os.path.basename(clip), "range": [a, b], "scale": round(s, 4)}
    json.dump(meta, open(out + ".json", "w"), indent=1)
    print(out, sheet.size, "scale", round(s, 3))


if __name__ == "__main__":
    main()
