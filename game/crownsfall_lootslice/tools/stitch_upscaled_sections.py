"""Stitch upscaled master sections into one zone canvas (free, local).
Every section was cut from the master at the same size (CW x CH) with overlap, so each upscale has the same scale
factor k. Each is placed at (x0*k, y0*k); in overlaps the sections are blended with a linear ramp, so joins vanish.
usage: python stitch_upscaled_sections.py <out.png> <master_w> <master_h> <section_json>
  section_json: [{"img": path, "x0": int, "y0": int, "cw": 1408, "ch": 613}, ...]"""
import sys, json
import numpy as np
from PIL import Image
out = sys.argv[1]; MW, MH = int(sys.argv[2]), int(sys.argv[3]); secs = json.loads(sys.argv[4])
first = Image.open(secs[0]["img"]); k = first.width / secs[0]["cw"]
print("scale factor", round(k, 4), "upscaled size", first.size)
bx0 = min(s["x0"] for s in secs); by0 = min(s["y0"] for s in secs)
bx1 = max(s["x0"] + s["cw"] for s in secs); by1 = max(s["y0"] + s["ch"] for s in secs)
W, H = round((bx1 - bx0) * k), round((by1 - by0) * k)
acc = np.zeros((H, W, 3), np.float64); wsum = np.zeros((H, W), np.float64)
for s in secs:
    im = np.asarray(Image.open(s["img"]).convert("RGB").resize((round(s["cw"] * k), round(s["ch"] * k)), Image.LANCZOS), np.float64)
    h, w = im.shape[:2]
    # weight: 1 in the middle, falling linearly to ~0 over the overlap margin at each edge
    m = 64 * k
    wx = np.clip(np.minimum(np.arange(w) + 0.5, w - np.arange(w) - 0.5) / m, 0.02, 1)
    wy = np.clip(np.minimum(np.arange(h) + 0.5, h - np.arange(h) - 0.5) / m, 0.02, 1)
    # outer zone edges are not overlaps: full weight there
    if s["x0"] == bx0: wx[: int(m)] = 1
    if s["x0"] + s["cw"] == bx1: wx[-int(m):] = 1
    if s["y0"] == by0: wy[: int(m)] = 1
    if s["y0"] + s["ch"] == by1: wy[-int(m):] = 1
    wgt = wy[:, None] * wx[None, :]
    X, Y = round((s["x0"] - bx0) * k), round((s["y0"] - by0) * k)
    acc[Y:Y + h, X:X + w] += im * wgt[..., None]; wsum[Y:Y + h, X:X + w] += wgt
img = (acc / np.maximum(wsum, 1e-6)[..., None]).clip(0, 255).astype(np.uint8)
Image.fromarray(img).save(out); print(out, img.shape[1], "x", img.shape[0])
