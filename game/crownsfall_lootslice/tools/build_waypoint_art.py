"""Fit the Higgsfield waypoint platform art to the game camera (free, local).

The generated art is drawn from a steeper angle than the game's 52-degree orthographic camera (its round footprint
is 0.90 as tall as wide; flat ground at 52 degrees projects to sin(52) = 0.79), so laid on the ground it read as
tilted toward the viewer. This squashes it vertically so the footprint matches the camera, crops to the footprint
so its centre is the image centre, and adds a soft contact shadow so it sits into the painted ground.
usage: python build_waypoint_art.py <src.png> <out.png> <basin_x> <basin_y>   (basin centre in source pixels)
Prints the basin centre's offset from the footprint centre as a fraction of the output height.
"""
import math, sys, json
import numpy as np, cv2
from PIL import Image

src, out, bx, by = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4])
a = np.asarray(Image.open(src).convert("RGBA")).astype(np.float32)
m = a[..., 3] > 128
ys, xs = np.where(m)
x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
a = a[y0:y1, x0:x1]
bx, by = bx - x0, by - y0
w, h = a.shape[1], a.shape[0]
target = math.sin(math.radians(52.0))
k = target * w / h                                   # vertical squash so footprint height/width == sin(52)
nh = int(round(h * k))
im = Image.fromarray(a.astype(np.uint8), "RGBA").resize((w, nh), Image.LANCZOS)
by *= k
pad = int(w * 0.06)
canvas = np.zeros((nh + 2 * pad, w + 2 * pad, 4), np.float32)
body = np.asarray(im).astype(np.float32)
# contact shadow: the footprint's alpha, blurred and nudged down-right (painted light comes from the upper left)
alpha = np.zeros(canvas.shape[:2], np.float32)
alpha[pad:pad + nh, pad:pad + w] = body[..., 3] / 255.0
sh = cv2.GaussianBlur(alpha, (0, 0), w * 0.012)
M = np.float32([[1, 0, w * 0.006], [0, 1, w * 0.010]])
sh = cv2.warpAffine(sh, M, (sh.shape[1], sh.shape[0]))
canvas[..., 3] = np.clip(sh * 0.55, 0, 1) * 255
canvas[..., :3] = 18.0
fa = body[..., 3:4] / 255.0
reg = canvas[pad:pad + nh, pad:pad + w]
reg[..., :3] = body[..., :3] * fa + reg[..., :3] * (1 - fa)
reg[..., 3] = np.maximum(body[..., 3], reg[..., 3])
Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8), "RGBA").save(out)
H, W = canvas.shape[:2]
info = {"size": [W, H], "footprint_w_frac": w / W, "basin_offset_v": (H / 2 - (by + pad)) / H}
print(json.dumps(info))
