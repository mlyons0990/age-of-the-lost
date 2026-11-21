"""Fit the Higgsfield waypoint platform art to the game camera (free, local).

The generated art is drawn from a steeper angle than the game's 52-degree orthographic camera (its round footprint
is 0.90 as tall as wide; flat ground at 52 degrees projects to sin(52) = 0.79), so laid on the ground it read as
tilted toward the viewer. This squashes it vertically so the footprint matches the camera, crops to the footprint
so its centre is the image centre, and adds a soft contact shadow so it sits into the painted ground.
usage: python build_waypoint_art.py <src.png> <out.png> <basin_x> <basin_y> [rotate_deg] [ground_ratio]
  (basin centre in source pixels; rotate_deg turns the platform on the ground, + = bottom point swings right.
  The rotation is done in ground space about the point midway between footprint and basin centre, so the raised
  centre leans by at most ~(basin offset x sin(angle)); fine for the small turns used to aim a point.)
Prints the basin centre's offset from the footprint centre as a fraction of the output height.
"""
import math, sys, json
import numpy as np, cv2
from PIL import Image

src, out, bx, by = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4])
rot = float(sys.argv[5]) if len(sys.argv) > 5 else 0.0
# height/width of a ground circle in the PAINTINGS (measured: Whisperwood shrine rings 0.47-0.54, Crownsfall compass
# rose ~0.47). The paintings are drawn from a lower angle than the 52-degree camera, so match the painting, not the camera.
GROUND_RATIO = float(sys.argv[6]) if len(sys.argv) > 6 else 0.51
a = np.asarray(Image.open(src).convert("RGBA")).astype(np.float32)
m = a[..., 3] > 128
ys, xs = np.where(m)
x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
a = a[y0:y1, x0:x1]
bx, by = bx - x0, by - y0
w, h = a.shape[1], a.shape[0]
if rot != 0.0:
    # unsquash to a top-down view, rotate about the footprint/basin midpoint, then squash back to the art's own ratio
    r0 = h / w
    td_h = int(round(h / r0))
    td = cv2.resize(a, (w, td_h), interpolation=cv2.INTER_LANCZOS4)
    px, py = (w / 2 + bx) / 2, (h / 2 + by) / 2 / r0
    big = int(max(w, td_h) * 1.5)
    M = cv2.getRotationMatrix2D((px, py), rot, 1.0)
    M[0, 2] += (big - w) / 2; M[1, 2] += (big - td_h) / 2
    td = cv2.warpAffine(td, M, (big, big), flags=cv2.INTER_LANCZOS4, borderValue=(0, 0, 0, 0))
    bpt = M @ np.array([bx, by / r0, 1.0])
    a = cv2.resize(td, (big, int(round(big * r0))), interpolation=cv2.INTER_LANCZOS4)
    bx, by = bpt[0], bpt[1] * r0
    m2 = a[..., 3] > 128
    ys, xs = np.where(m2)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    a = a[y0:y1, x0:x1]; bx -= x0; by -= y0
    w, h = a.shape[1], a.shape[0]
target = GROUND_RATIO
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
