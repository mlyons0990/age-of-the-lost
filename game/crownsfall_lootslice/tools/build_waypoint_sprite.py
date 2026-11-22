"""Prepare a waypoint painted AT THE GAME CAMERA (WP3) for direct use as a ground sprite (free, local, no warping).

Finds the eight star tips (convex-hull corners of the silhouette). Tips lie on the ground plane in opposite pairs, so
their mean is the platform's exact ground centre, and an ellipse through them gives the painting's ground ratio and
the tip radius. Writes the cropped image plus a JSON sidecar the game reads to centre, size and (if a zone's floor
is drawn slightly flatter/steeper) gently match the ground angle.
usage: python build_waypoint_sprite.py <src.png> <out.png>
"""
import json, sys
import numpy as np, cv2
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
a = np.asarray(Image.open(src).convert("RGBA"))
m = (a[..., 3] > 128).astype(np.uint8)
cs, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
c = max(cs, key=cv2.contourArea)
hull = cv2.convexHull(c)
eps = 0.01 * cv2.arcLength(hull, True)
tips = cv2.approxPolyDP(hull, eps, True).reshape(-1, 2).astype(float)
# keep the 8 most "pointed" hull vertices (star tips): those farthest from the centroid
cen = c.reshape(-1, 2).mean(0)
d = np.linalg.norm(tips - cen, axis=1)
tips = tips[np.argsort(-d)[:8]]
ctr = tips.mean(0)
(ex, ey), (ea, eb), ang = cv2.fitEllipse(tips.astype(np.float32))
a_ax, b_ax = max(ea, eb) / 2, min(ea, eb) / 2
ratio = b_ax / a_ax
ys, xs = np.where(m > 0)
pad = 8
x0, x1, y0, y1 = max(0, xs.min() - pad), min(a.shape[1], xs.max() + 1 + pad), max(0, ys.min() - pad), min(a.shape[0], ys.max() + 1 + pad)
crop = a[y0:y1, x0:x1]
Image.fromarray(crop, "RGBA").save(out)
H, W = crop.shape[:2]
meta = {"size": [W, H], "centre_uv": [(ctr[0] - x0) / W, (ctr[1] - y0) / H], "tip_radius_frac": a_ax / W,
        "ground_ratio": round(ratio, 3), "tips": [[round(t[0] - x0), round(t[1] - y0)] for t in tips]}
json.dump(meta, open(out.replace(".png", ".json"), "w"), indent=1)
print(json.dumps({k: v for k, v in meta.items() if k != "tips"}))
