"""Bake a painted zone's foreground depth map (free, local).

Every painting pixel gets the image row where the thing drawn there touches the ground ("base row"). Flat ground is its
own base row. Railings, lamps and planters in front of the walkable floor get the base row of their foot line, so the
runtime shader can push those pixels toward the camera and 3D actors walking behind them are hidden.

Zone JSON "occluders": [{"line": [[u0, v0], [u1, v1]], "x": [xmin, xmax], "pad": 20}, ...]
  line: the occluder's foot on the plaza side (a straight line in image pixels); everything south of it inside x is
  foreground ("exclude": [[x0, y0, x1, y1], ...] boxes are never foreground), plus non-floor pixels north of it (lamps, finials, flowers) that are attached to it.
Output: <image>_depth.png, 8-bit L, value = (base_row - row) / 4 (0 = flat ground).
usage: python build_zone_depth.py <zone.json>
"""
import json, os, sys
import numpy as np, cv2
from PIL import Image

zp = sys.argv[1]
z = json.load(open(zp))
d = os.path.dirname(zp)
im = np.asarray(Image.open(os.path.join(d, z["image"])).convert("RGB"))
H, W = im.shape[:2]
hsv = cv2.cvtColor(im, cv2.COLOR_RGB2HSV).astype(np.float32)
S, V = hsv[..., 1] / 255, hsv[..., 2] / 255
# floor = pale, low-saturation stone (lit or in leaf shadow); anything else is "object"
obj = ((V < 0.50) | (S > 0.32)).astype(np.uint8)
obj = cv2.morphologyEx(obj, cv2.MORPH_CLOSE, np.ones((7, 7), np.uint8))
delta = np.zeros((H, W), np.float32)
yy, xx = np.mgrid[0:H, 0:W]
for oc in z.get("occluders", []):
    (u0, v0), (u1, v1) = oc["line"]
    pad = float(oc.get("pad", 20))
    x0, x1 = oc["x"]
    k = (v1 - v0) / float(u1 - u0)
    line = v0 + (xx - u0) * k
    inx = (xx >= x0) & (xx < x1)
    south = inx & (yy >= line)
    near = inx & (yy < line) & (yy > line - 520) & (obj > 0)
    # attached objects: connected to the south band
    cand = (south | near).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(cand)
    keep = np.isin(lab, np.unique(lab[south & (lab > 0)]))
    m = (keep & (south | near)).astype(np.uint8)
    # fill holes (lamp glass, planter gaps)
    cs, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    filled = np.zeros_like(m); cv2.drawContours(filled, cs, -1, 1, -1)
    m = (filled > 0) & (inx) & ((yy >= line) | (yy > line - 520))
    for ex0, ey0, ex1, ey1 in oc.get("exclude", []):      # props behind the floor that touch the occluder
        m &= ~((xx >= ex0) & (xx < ex1) & (yy >= ey0) & (yy < ey1))
    base = line + pad
    delta = np.where(m, np.maximum(delta, base - yy), delta)
out = os.path.join(d, os.path.splitext(z["image"])[0] + "_depth.png")
Image.fromarray(np.clip(delta / 4.0, 0, 255).astype(np.uint8), "L").save(out)
print(out, "foreground px", int((delta > 0).sum()))
