"""Make a perfectly symmetric TOP-DOWN waypoint texture from the generated (oblique) waypoint art (free, local).

The generated painting is not exactly symmetric (star points, steps and rim differ around the circle). This tool
un-tilts it to a top-down view (undo the art's own foreshortening and the raised parts' lift), takes the cleanest
wedge (the far side: pure top surfaces, no step risers), mirrors it about the star point it contains and repeats it
8 times. The result is used as the top texture of a real 3D waypoint mesh (scripts/three_d/waypoint_mesh.gd), so
the waypoint is uniform all the way round and correct at any camera angle.
usage: python build_waypoint_topdown.py <src.png> <out.png> <basin_x> <basin_y> [size]
Prints the radial profile (alpha / brightness) used to place the mesh rings.
"""
import math, sys, json
import numpy as np, cv2
from PIL import Image

src, out, bx, by = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4])
N = int(sys.argv[5]) if len(sys.argv) > 5 else 2048
a = np.asarray(Image.open(src).convert("RGBA")).astype(np.float32)
m = a[..., 3] > 128
ys, xs = np.where(m)
x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
cx = (x0 + x1) / 2.0
R = (x1 - x0) / 2.0                       # star tip radius (the art's widest extent is star tip to tip)
# footprint centre: the star base's own centre; the art's bbox bottom includes the base's thickness, so take the
# horizontal tips' row as the base centre row
row_l = ys[xs == x0].mean(); row_r = ys[xs == x1 - 1].mean()
cy = (row_l + row_r) / 2.0
top_tip = y0                              # far star tip
r_src = (cy - top_tip) / R                # art foreshortening (height/width of a ground circle)
D = by - cy                               # lift of the basin relative to the base (px, negative = up)
def wt(rad):                              # height weight by top-down radius: basin 1 .. outer star 0
    return np.clip((1.0 - rad) / (1.0 - 0.55), 0.0, 1.0)
# top-down output grid: u,v in [-1,1] (R = 1)
g = (np.arange(N, dtype=np.float32) + 0.5) / N * 2.0 - 1.0
U, V = np.meshgrid(g, g)
rad = np.sqrt(U * U + V * V)
ang = np.arctan2(V, U)                    # 0 = +x (right), -pi/2 = far side (up in the art)
# fold every direction into the far-side wedge: star point at -90 deg, wedge -90 +- 22.5, mirrored
k = math.pi / 4.0
rel = np.mod(ang + math.pi / 2.0 + k / 2.0, k) - k / 2.0   # -22.5..22.5 around a star point
rel = np.abs(rel)                                           # mirror
fa = -math.pi / 2.0 + rel
sx = cx + R * rad * np.cos(fa)
sy = cy + R * rad * np.sin(fa) * r_src + D * wt(rad)
o = cv2.remap(a, sx.astype(np.float32), sy.astype(np.float32), cv2.INTER_LANCZOS4,
              borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0))
Image.fromarray(np.clip(o, 0, 255).astype(np.uint8), "RGBA").save(out)
# radial profile along the star-point axis and along the valley axis (for ring radii)
prof = []
for i in range(0, 200):
    r = i / 200.0
    p = o[int((-r * 0.999 + 1) / 2 * N), N // 2]
    q_ang = -math.pi / 2.0 + k / 2.0
    qx = int((r * math.cos(q_ang) + 1) / 2 * N); qy = int((r * math.sin(q_ang) + 1) / 2 * N)
    q = o[min(N - 1, qy), min(N - 1, qx)]
    prof.append((round(r, 3), int(p[3]), int(p[:3].mean()), int(q[3]), int(q[:3].mean())))
print(json.dumps({"R_px": R, "r_src": round(r_src, 3), "lift_px": round(D, 1)}))
for row in prof[::4]: print(row)
