"""Key the single edge-to-edge HUD bar (Higgsfield R1 variant A, owner-approved 6 cr) and write the runtime assets.

The bar is ONE painted piece: statue + HP globe + potion panel + XP groove + skill panel + MP globe + statue, so there
are no seams between elements. This script (free, local):
  * chroma-keys the #00FF00 background with a soft edge and removes green spill,
  * extends the outer statues to the image edges and fills the bottom rows so the bar sits flush on 3 screen edges,
  * writes hud_full.png (1920 px wide, drawn 1:1 at 1080p) and hud_full@2x.png (3840 px), plus hud_full.json with every
    well, key plate, globe disc and the XP groove in 1920-wide pixels.
usage: python key_hud_full.py <raw.png> <out_dir>
"""
import json, sys
import numpy as np
import cv2
from PIL import Image

SRC, OUT = sys.argv[1], sys.argv[2]
im = np.asarray(Image.open(SRC).convert("RGB")).astype(np.float32) / 255
H, W = im.shape[:2]
r, g, b = im[..., 0], im[..., 1], im[..., 2]
green = g - np.maximum(r, b)
a = np.clip(1.0 - (green - 0.10) / 0.22, 0, 1)
a = cv2.GaussianBlur(a, (0, 0), 1.2)
rgb = im.copy()
rgb[..., 1] = np.minimum(g, np.maximum(r, b) * 1.03 + 0.01)       # despill everywhere (the art has no true greens)
# drop faint keyed haze (a painted green smudge at the potion panel's corner) and tiny islands
a[a < 0.35] = 0.0
solid = (a > 0.5).astype(np.uint8)
n, lab, st, _ = cv2.connectedComponentsWithStats(solid)
keep = np.zeros(n, bool); keep[1:] = st[1:, cv2.CC_STAT_AREA] > 20000
a = np.where(keep[lab] | (a < 0.5) & (cv2.dilate(keep[lab].astype(np.uint8), np.ones((9, 9))) > 0), a, 0.0)
# outer edges: mirror the statues' stone outward so every row they occupy reaches the image edge
gap = 220
for y in range(H):
    xs = np.where(a[y] > 0.5)[0]
    if not len(xs):
        continue
    if 0 < xs[0] <= gap:
        x0 = xs[0]; src = np.clip(2 * x0 - np.arange(x0), 0, W - 1)
        rgb[y, :x0] = rgb[y, src]; a[y, :x0] = 1.0
    if W - 1 - gap <= xs[-1] < W - 1:
        x1 = xs[-1]; m = W - 1 - x1; src = np.clip(2 * x1 - (x1 + 1 + np.arange(m)), 0, W - 1)
        rgb[y, x1 + 1:] = rgb[y, src]; a[y, x1 + 1:] = 1.0
# bottom edge: fill any keyed gaps in the last rows from the row above, so the bar sits on the screen edge
for y in range(H - 24, H):
    hole = a[y] < 0.95
    rgb[y, hole] = rgb[y - 1, hole]; a[y, hole] = np.maximum(a[y, hole], a[y - 1, hole])
# repair the painted smudge where the potion panel steps down into the XP base: clear above the base and rebuild the
# base's top rim from a clean stretch of the same rim further along (same rows, no groove frame involved)
SX0, SX1, CLEAN = 3896, 4330, 4760
a[:1040, SX0:SX1] = 0.0
rgb[1040:1125, SX0:SX1] = rgb[1040:1125, CLEAN:CLEAN + (SX1 - SX0)]
a[1040:1125, SX0:SX1] = a[1040:1125, CLEAN:CLEAN + (SX1 - SX0)]
rgba = np.dstack([np.clip(rgb, 0, 1), a])
img = Image.fromarray((rgba * 255).astype(np.uint8), "RGBA")
k = 1920.0 / W
img.resize((1920, round(H * k)), Image.LANCZOS).save(f"{OUT}/hud_full.png")
img.resize((3840, round(H * k * 2)), Image.LANCZOS).save(f"{OUT}/hud_full@2x.png")

S = lambda v: round(v * k, 2)
box = lambda x0, x1, y0, y1: [S(x0), S(y0), S(x1 - x0), S(y1 - y0)]
WELL_Y, PLATE_Y = (606, 1103), (1154, 1298)
potion_x = [(1797, 2140), (2197, 2535), (2591, 2929), (2983, 3319), (3374, 3737)]
# the skill panel's first well sits above the end of the XP groove and has no key plate: it shows the primary
# attack (display only); the six wells with plates are the skill slots
primary_x = (7349, 7703)
skill_x = [(7763, 8135), (8150, 8556), (8563, 8959), (9014, 9374), (9430, 9780), (9837, 10183)]
meta = {
    "source": "Higgsfield nano_banana_2_1 4K 8:1, R1 variant A (job c70f970d-7b8d-43f4-9362-e5890f3020d9), keyed by "
              "tools/key_hud_full.py. Coordinates in 1920-wide pixels; scale by screen_width / 1920.",
    "size": [1920, round(H * k)],
    "disc_left": [S(1020), S(757), S(541), S(541)],
    "disc_right": [S(10899), S(764), S(549), S(549)],
    "potion_wells": [box(x0, x1, *WELL_Y) for x0, x1 in potion_x],
    "potion_plates": [box(x0, x1, *PLATE_Y) for x0, x1 in potion_x],
    "skill_wells": [box(x0, x1, *WELL_Y) for x0, x1 in skill_x],
    "skill_plates": [box(x0, x1, *PLATE_Y) for x0, x1 in skill_x],
    "primary_well": box(primary_x[0], primary_x[1], WELL_Y[0], 1082),
    "xp_groove": box(4349, 7521, 1176, 1302),
    "panel_top_left": S(521), "panel_top_right": S(518),
}
json.dump(meta, open(f"{OUT}/hud_full.json", "w"), indent=1)
print("hud_full", meta["size"], "discs", meta["disc_left"], meta["disc_right"], "groove", meta["xp_groove"])
