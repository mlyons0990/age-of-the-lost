"""PoE-style HUD parts (free, local). Panels and wells are drawn procedurally - exact straight bevels, no AI wobble.

Writes to <out_dir>:
  hud_corner_left.png / hud_corner_right.png (+@2x): statue + globe ring cut from the current painted bar, trimmed to a
      clean circle on the inner side (placeholders until the approved corner redraw).
  hud_panel_frame.png (+@2x): 9-patch bronze-bevelled frame with a dark stone fill (skill block, flask belt).
  hud_well.png (+@2x): 9-patch recessed slot well with a thin bronze rim.
  hud_xp_frame.png (+@2x): 9-patch thin XP bar frame.
  hud_corners.json: globe discs and corner sizes (1920-wide units).
usage: python build_hud_poe.py <assets/ui/arpg_hud>
"""
import json, sys
import numpy as np
from PIL import Image

D = sys.argv[1]
rng = np.random.default_rng(7)

def save2(arr, name):
    im = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    im.save(f"{D}/{name}@2x.png")
    im.resize((im.width // 2, im.height // 2), Image.LANCZOS).save(f"{D}/{name}.png")

def stone(h, w, base=(30, 26, 30)):
    n = rng.normal(0, 1, (h // 4 + 2, w // 4 + 2))
    n = np.asarray(Image.fromarray(((n - n.min()) / (np.ptp(n) + 1e-6) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)) / 255.0
    f = rng.normal(0, 1, (h, w)) * 0.035
    v = 0.82 + 0.3 * n + f
    return np.dstack([np.full((h, w), c, float) * v for c in base] + [np.full((h, w), 255.0)])

BRONZE_HI, BRONZE, BRONZE_LO, EDGE = np.array([176, 136, 92]), np.array([112, 84, 58]), np.array([58, 42, 32]), np.array([10, 8, 9])

def bevel_frame(w, h, border, inset_dark=True):
    """Outer dark line, bronze bevel (lit top-left, shadowed bottom-right), inner dark line, stone fill."""
    a = stone(h, w)
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.minimum.reduce([xx, yy, w - 1 - xx, h - 1 - yy])            # distance to the outer edge
    ring = (d >= 1) & (d < border - 1)
    t = (d - 1) / max(1, border - 2)                                    # 0 outer .. 1 inner across the bevel
    lit = (xx + yy) < (w + h) / 2                                       # top-left half catches the light
    prof = np.where(t < 0.5, 1 - np.abs(t - 0.25) * 2.2, 0.55 - (t - 0.5) * 0.9)   # rounded rim profile
    col = np.where(lit[..., None], BRONZE_HI * 0.55 + BRONZE * 0.45, BRONZE * 0.8 + BRONZE_LO * 0.2) * (0.62 + 0.5 * prof[..., None])
    grain = rng.normal(0, 6, (h, w, 1))
    a[ring, :3] = (col + grain)[ring]
    a[d == 0, :3] = EDGE
    a[d == border - 1, :3] = EDGE * 1.5
    if inset_dark:
        inner = (d >= border) & (d < border + 3)
        a[inner, :3] *= np.linspace(0.45, 0.8, 3)[(d[inner] - border)][:, None]
    return a

# --- stone tile for the continuous frame body (seamless enough at UI scale)
st = stone(256, 256)
save2(st, "hud_stone")
# --- panel frame (skill block / flask belt): 9-patch 96x96 @2x, border 14 @2x
save2(bevel_frame(96, 96, 14), "hud_panel_frame")
# --- slot well: recessed, thin rim
w = bevel_frame(64, 64, 6, inset_dark=False)
yy, xx = np.mgrid[0:64, 0:64]
d = np.minimum.reduce([xx, yy, 63 - xx, 63 - yy])
inside = d >= 6
w[inside, :3] = np.array([16, 13, 15]) + (np.clip((d[inside] - 6) / 10, 0, 1) * 10)[:, None]      # inner shadow
save2(w, "hud_well")
# --- XP frame: thin bevelled channel
save2(bevel_frame(64, 32, 6), "hud_xp_frame")

# --- corner placeholders from the current painted bar
full = np.asarray(Image.open(f"{D}/hud_full@2x.png").convert("RGBA")).astype(float)
meta = json.load(open(f"{D}/hud_full.json"))
H2 = full.shape[0]
out = {}
for side in ("left", "right"):
    cx, cy, r, _ = [v * 2 for v in meta["disc_" + side]]
    R = r * 1.2                                                          # glass + bronze ring
    if side == "left":
        x0, x1 = 0, int(np.ceil(cx + R)) + 2
    else:
        x0, x1 = int(np.floor(cx - R)) - 2, full.shape[1]
    c = full[:, x0:x1].copy()
    hh, ww = c.shape[:2]
    yy, xx = np.mgrid[0:hh, 0:ww]
    ccx = cx - x0
    dist = np.sqrt((xx - ccx) ** 2 + (yy - cy) ** 2)
    # keep the statue column untouched; everywhere else trim to the ring's own circle, so the painted slab behind the
    # ring top (which ended in a hard vertical cut) is removed and the ring reads as a clean round frame
    # outside the ring circle keep only the statue + its rock (pale stone, found by colour and connected to the screen
    # edge), so neither the slab behind the ring nor any straight crop line survives
    import cv2
    Rr = r * 1.175
    rgb = c[..., :3] / 255.0
    lum = rgb.mean(-1); sat = rgb.max(-1) - rgb.min(-1)
    pale = ((lum > 0.22) & (sat < 0.32) & (c[..., 3] > 128)).astype(np.uint8)
    pale = cv2.morphologyEx(pale, cv2.MORPH_CLOSE, np.ones((15, 15), np.uint8))
    n, lab, st, _ = cv2.connectedComponentsWithStats(pale)
    edge_col = 0 if side == "left" else ww - 1
    keep_ids = set(lab[:, edge_col][lab[:, edge_col] > 0].tolist())
    statue = np.isin(lab, list(keep_ids)).astype(np.uint8)
    cs, _ = cv2.findContours(statue, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    statue = np.zeros_like(statue); cv2.drawContours(statue, cs, -1, 1, -1)
    statue = cv2.GaussianBlur(statue.astype(np.float32), (0, 0), 1.2)
    ring = np.clip((Rr - dist) / 2.0 + 0.5, 0, 1)                         # anti-aliased circle
    inner_side = (xx > ccx) if side == "left" else (xx < ccx)
    # the dark painted slab wedged between the statue's head and the ring top: band beside the statue, above the ring
    band = (~inner_side) & (yy < cy - 0.3 * r) & ((xx > ccx - 1.05 * r) if side == "left" else (xx < ccx + 1.05 * r))
    dark = cv2.GaussianBlur((lum < 0.22).astype(np.float32), (0, 0), 1.2)
    dark = cv2.morphologyEx((dark > 0.5).astype(np.uint8), cv2.MORPH_OPEN, np.ones((3, 3), np.uint8)).astype(np.float32)
    keep = np.ones_like(ring)
    keep = np.where(inner_side, ring, keep)                              # globe's open side: clean ring circle
    keep = np.where(band, np.maximum(ring, 1.0 - cv2.GaussianBlur(dark, (0, 0), 1.0)), keep)
    near = band & ((xx > ccx - 0.62 * r) if side == "left" else (xx < ccx + 0.62 * r))   # above the ring itself
    keep = np.where(near, ring, keep)                                    # nothing but the ring circle there
    c[..., 3] = c[..., 3] * keep
    # drop floating scraps (ornament bits left outside the ring): keep only the main connected body
    solid = (c[..., 3] > 100).astype(np.uint8)
    n2, lab2, st2, _ = cv2.connectedComponentsWithStats(solid)
    big = 1 + np.argmax(st2[1:, cv2.CC_STAT_AREA])
    main = cv2.dilate((lab2 == big).astype(np.uint8), np.ones((3, 3), np.uint8)).astype(np.float32)
    # thin ornament wisps outside the ring that are attached by a thread: open them away in the band only
    opened = cv2.morphologyEx((lab2 == big).astype(np.uint8), cv2.MORPH_OPEN, np.ones((13, 13), np.uint8))
    n3, lab3, st3, _ = cv2.connectedComponentsWithStats(opened)
    opened = (lab3 == 1 + np.argmax(st3[1:, cv2.CC_STAT_AREA])).astype(np.float32)
    main = np.where(band & (ring < 0.5), opened, main)
    c[..., 3] = c[..., 3] * cv2.GaussianBlur(main, (0, 0), 0.8)
    im = Image.fromarray(c.astype(np.uint8), "RGBA")
    im.save(f"{D}/hud_corner_{side}@2x.png")
    im.resize((im.width // 2, im.height // 2), Image.LANCZOS).save(f"{D}/hud_corner_{side}.png")
    out[side] = {"size": [im.width / 2, im.height / 2], "disc": [(cx - x0) / 2, cy / 2, r / 2, r / 2], "ring_r": Rr / 2}
json.dump(out, open(f"{D}/hud_corners.json", "w"), indent=1)
print(out)
