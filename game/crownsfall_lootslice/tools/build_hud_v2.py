"""Cut and size the owner-approved Higgsfield HUD v2 art (items 1-6) into runtime assets (free, local).

Inputs (art/higgsfield_2026-11/hud_v2): hp_a_cut.png (HP corner, keyed), mp_a.png (mana corner), rail_b.png, caps_a.png,
frame_b.png, sockets.png. Outputs to <out>: hud2_*.png (+@2x) and hud2.json (1080p units).
usage: python build_hud_v2.py <src_dir> <out_dir>
"""
import json, sys
import numpy as np, cv2
from PIL import Image

SRC, OUT = sys.argv[1], sys.argv[2]
GLASS_R_1080 = 90.0          # on-screen glass radius at 1080p (same as the approved layout)

def load(f):
    return np.asarray(Image.open(f"{SRC}/{f}").convert("RGBA")).astype(np.float32)

def save(a, name, k):
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    w, h = im.size
    im.resize((max(1, round(w * k * 2)), max(1, round(h * k * 2))), Image.LANCZOS).save(f"{OUT}/{name}@2x.png")
    im.resize((max(1, round(w * k)), max(1, round(h * k))), Image.LANCZOS).save(f"{OUT}/{name}.png")
    return [round(w * k, 2), round(h * k, 2)]

def bbox(a, thr=24):
    ys, xs = np.where(a[..., 3] > thr)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1

def glass(a, hue):
    hsv = cv2.cvtColor(a[..., :3].astype(np.uint8), cv2.COLOR_RGB2HSV)
    m = (hue(hsv[..., 0]) & (hsv[..., 1] > 110) & (hsv[..., 2] > 40)).astype(np.uint8)
    m = cv2.morphologyEx(m, cv2.MORPH_OPEN, np.ones((9, 9), np.uint8))
    n, lab, st, _ = cv2.connectedComponentsWithStats(m)
    k = 1 + np.argmax(st[1:, 4]); x, y, w, h = st[k, :4]
    return x + w / 2, y + h / 2, w / 2, (lab == k)

meta = {"source": "Higgsfield gpt_image_2_6 HUD v2 (owner-approved 24.5 cr plan, 2026-11-21)"}
mask_out = {}
for side, f, hue in [("left", "hp_a_cut.png", lambda h: (h < 8) | (h > 168)),
                     ("right", "mp_a.png", lambda h: (h > 100) & (h < 135))]:
    a = load(f)
    cx, cy, r, gm = glass(a, hue)
    H, W = a.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W]
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    x0, y0, x1, y1 = bbox(a)
    if side == "left":
        x0 = 0                                       # figure runs off the screen edge
    else:
        x1 = W
    a = a[y0:y1, x0:x1]; gm = gm[y0:y1, x0:x1]
    k = GLASS_R_1080 / r
    size = save(a, f"hud2_corner_{side}", k)
    # inner-side silhouette per 1080p row: where the corner art ends (left piece: rightmost opaque x; right piece:
    # leftmost), so panels and the XP bar can butt exactly against the art with no gap and no overlap
    sm = np.asarray(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA").resize((max(1, round(a.shape[1] * k)), max(1, round(a.shape[0] * k))), Image.LANCZOS))[..., 3]
    edge = []
    for yy_ in range(sm.shape[0]):
        xs_ = np.where(sm[yy_] > 160)[0]
        if len(xs_) == 0: edge.append(-1.0 if side == "left" else float(sm.shape[1]))
        else: edge.append(float(xs_.max() + 1) if side == "left" else float(xs_.min()))
    meta[side] = {"size": size, "disc": [round((cx - x0) * k, 2), round((cy - y0) * k, 2), GLASS_R_1080, GLASS_R_1080],
                  "ring_r": round(r * 1.15 * k, 2), "edge": edge}
    # glass mask for the drain shader: disc-sized square around the glass
    n = int(round(2 * r))
    gx0, gy0 = int(round(cx - x0 - r)), int(round(cy - y0 - r))
    sq = np.zeros((n, n), np.uint8)
    hh, ww = gm.shape
    sx0, sy0, sx1, sy1 = max(0, gx0), max(0, gy0), min(ww, gx0 + n), min(hh, gy0 + n)
    sq[sy0 - gy0:sy1 - gy0, sx0 - gx0:sx1 - gx0] = gm[sy0:sy1, sx0:sx1] * 255
    cs, _ = cv2.findContours(sq, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    sq = np.zeros_like(sq); cv2.drawContours(sq, cs, -1, 255, -1)
    sq = cv2.GaussianBlur(cv2.erode(sq, np.ones((5, 5), np.uint8)), (0, 0), 2.0)
    Image.fromarray(sq).resize((360, 360), Image.LANCZOS).save(f"{OUT}/hud2_glass_{side}.png")

# --- rail: crop the band, find the motif period and keep exactly one period so it tiles seamlessly
a = load("rail_b.png")
x0, y0, x1, y1 = bbox(a, 128)
band = a[y0:y1, :]
L = band[..., :3].mean(-1)
# one motif cell centred on the middle boss (bosses repeat every ~640 px at x ~1276, 1920, 2564), wrapped with a
# cross-fade so the tile repeats seamlessly
C0, C1, FADE = 1598, 2242, 64
cell = band[:, C0:C1 + FADE].copy()
w = C1 - C0
ramp = np.linspace(0, 1, FADE)[None, :, None]
cell[:, :FADE] = cell[:, :FADE] * ramp + cell[:, w:w + FADE] * (1 - ramp)
tile = cell[:, :w]
period, best = w, 1.0
# XP groove: the dark recessed channel (rows ~200-285 of the band), inside its bronze bevel
g0, g1 = 200, 285
RAIL_H = 44.0
k = RAIL_H / band.shape[0]
size = save(tile, "hud2_rail", k)
meta["rail"] = {"tile": size, "height": RAIL_H, "groove": [round(g0 * k, 2), round((g1 - g0 + 1) * k, 2)],
                "period_px": int(period), "period_corr": round(float(best), 3)}

# --- ornament caps: two components
a = load("caps_a.png")
m = (a[..., 3] > 128).astype(np.uint8)
n, lab, st, _ = cv2.connectedComponentsWithStats(m)
comps = sorted([i for i in range(1, n) if st[i, 4] > 20000], key=lambda i: st[i, 0])[:2]
CAP_H = 64.0
for name, i in zip(["cap_belt", "cap_skill"], comps):
    x, y, w, h = st[i, :4]
    piece = a[y:y + h, x:x + w].copy()
    piece[..., 3] *= (lab[y:y + h, x:x + w] == i)
    meta[name] = {"size": save(piece, f"hud2_{name}", CAP_H / h)}

# --- frame kit (9-slice): corner margin measured as the rosette extent
a = load("frame_b.png")
x0, y0, x1, y1 = bbox(a, 128)
fr = a[y0:y1, x0:x1]
FR_SIZE = 220.0
kf = FR_SIZE / fr.shape[1]
meta["frame"] = {"size": save(fr, "hud2_frame", kf), "margin": round(fr.shape[1] * 0.135 * kf, 1),
                 "border": round(fr.shape[1] * 0.075 * kf, 1)}

# --- sockets: square (skill) and tall (potion)
a = load("sockets.png")
m = (a[..., 3] > 128).astype(np.uint8)
n, lab, st, _ = cv2.connectedComponentsWithStats(m)
comps = sorted([i for i in range(1, n) if st[i, 4] > 20000], key=lambda i: st[i, 0])[:2]
for name, i, target in zip(["socket_skill", "socket_potion"], comps, [64.0, 48.0]):
    x, y, w, h = st[i, :4]
    piece = a[y:y + h, x:x + w].copy()
    piece[..., 3] *= (lab[y:y + h, x:x + w] == i)
    kk = target / w
    meta[name] = {"size": save(piece, f"hud2_{name}", kk), "margin": round(w * 0.11 * kk, 1)}

json.dump(meta, open(f"{OUT}/hud2.json", "w"), indent=1)
print(json.dumps(meta, indent=1))
