"""Chroma-key the Higgsfield HUD redraw (A1-A3, green #00FF00 background), crop to content, measure the slot wells,
key plates and globe discs automatically, and write 1080p-scaled PNGs + hud_redraw.json for arpg_hud.gd (free)."""
import sys, json, numpy as np
from PIL import Image
import cv2
SRC, OUT = sys.argv[1], sys.argv[2]

def key(path):
    im = np.asarray(Image.open(path).convert("RGB")).astype(np.float32) / 255
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    green = g - np.maximum(r, b)                          # chroma distance
    a = np.clip(1.0 - (green - 0.10) / 0.22, 0, 1)        # soft key: 0 on pure green, 1 on art
    a = cv2.GaussianBlur(a, (0, 0), 0.8)
    spill = np.clip(g - np.maximum(r, b) * 1.02, 0, None)  # despill: pull green down to max(r,b) on edges
    out = im.copy(); out[..., 1] = g - spill * (1 - a * 0.0) * (a < 0.999)
    out[..., 1] = np.where(a < 0.999, np.minimum(g, np.maximum(r, b) * 1.02), g)
    rgba = np.dstack([out, a])
    ys, xs = np.where(a > 0.5)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    return rgba[y0:y1, x0:x1], (x0, y0)

def wells(rgba, box, dark=0.16):
    """dark rectangles (slot wells / key plates) inside a rough box -> list of [x,y,w,h]"""
    x0, y0, x1, y1 = box
    lum = rgba[y0:y1, x0:x1, :3].mean(-1)
    m = ((lum < dark) & (rgba[y0:y1, x0:x1, 3] > 0.9)).astype(np.uint8)
    m = cv2.morphologyEx(m, cv2.MORPH_OPEN, np.ones((9, 9), np.uint8))
    n, lab, st, _ = cv2.connectedComponentsWithStats(m)
    rs = [st[i] for i in range(1, n) if st[i, cv2.CC_STAT_AREA] > 4000]
    rs = sorted(rs, key=lambda s: s[0])
    return [[int(s[0] + x0), int(s[1] + y0), int(s[2]), int(s[3])] for s in rs]

def disc(rgba, hue_ok):
    hsv = cv2.cvtColor((rgba[..., :3] * 255).astype(np.uint8), cv2.COLOR_RGB2HSV)
    m = (hue_ok(hsv[..., 0]) & (hsv[..., 1] > 110) & (hsv[..., 2] > 50)).astype(np.uint8)
    m = cv2.morphologyEx(m, cv2.MORPH_OPEN, np.ones((15, 15), np.uint8))
    n, lab, st, _ = cv2.connectedComponentsWithStats(m)
    k = 1 + np.argmax(st[1:, cv2.CC_STAT_AREA]); x, y, w, h = st[k, :4]
    return [float(x + w / 2), float(y + h / 2), float(w / 2), float(h / 2)]

PV = 1600 / 6336          # preview thumbnail scale used for the hand measurements
DISC_1080 = 74.0
LAYOUT = {   # preview px: disc (cx, cy, r), wells [x0,x1] with shared y, plates y
    # the left art is composed a little shorter than the right; scale it so both corner pieces stand the same
    # height on screen (statue, globe ring and panel line up) while each keeps its own artwork
    "left":  {"src": "a1_left_raw.png", "disc": (465, 345, 215), "disc_1080": 74.0 * 225.0 / 212.0, "wells": [(765, 900), (915, 1048), (1063, 1196), (1212, 1346), (1380, 1530)],
              "well_y": (335, 525), "plate_y": (533, 588)},
    "right": {"src": "a2_right_raw.png", "disc": (1210, 385, 210), "wells": [(176, 318), (336, 476), (494, 634), (652, 792), (810, 950)],
              "well_y": (355, 527), "plate_y": (545, 610)},
}
meta = {"source": "Higgsfield nano_banana_2_1 redraw of the owner's HUD mockup (A1-A3, owner-approved 8 cr), chroma-keyed by "
        "tools/key_hud_redraw.py. Coordinates are in the scaled PNG pixels (drawn 1:1 at 1080p); @2x files for >1080p.",
        "disc_1080": DISC_1080}
for name, L in LAYOUT.items():
    rgba, (ox, oy) = key(f"{SRC}/{L['src']}")
    H, W = rgba.shape[:2]
    k = L.get("disc_1080", DISC_1080) / (L["disc"][2] / PV)
    al = rgba[..., 3]
    mid = int((L["well_y"][0] + L["well_y"][1]) / 2 / PV - oy)       # a row through the slot wells
    opaque = np.where(al[mid] > 0.5)[0]
    if name == "left":
        # outer (screen) edge: mirror the statue's stone outward so every row it occupies reaches x = 0
        gap = int(30 / k)
        for y in range(H):
            xs = np.where(al[y] > 0.5)[0]
            if len(xs) and 0 < xs[0] <= gap:
                x0 = xs[0]
                src = np.clip(2 * x0 - np.arange(x0) , 0, W - 1)
                rgba[y, :x0] = rgba[y, src]; rgba[y, :x0, 3] = 1.0
        panel_edge = int(opaque.max())                                   # inner edge of the potion belt
    else:
        gap = int(30 / k)
        for y in range(H):
            xs = np.where(al[y] > 0.5)[0]
            if len(xs) and W - 1 - gap <= xs[-1] < W - 1:
                x1 = xs[-1]
                n = W - 1 - x1
                src = np.clip(2 * x1 - (x1 + 1 + np.arange(n)), 0, W - 1)
                rgba[y, x1 + 1:] = rgba[y, src]; rgba[y, x1 + 1:, 3] = 1.0
        # drop the small baked XP ledge left of the skill panel: the live XP strip slots in there instead
        panel_edge = int(opaque.min())
        rgba[:, :panel_edge, 3] = 0.0
    P = lambda px, py: [round((px / PV - ox) * k, 2), round((py / PV - oy) * k, 2)]
    img = Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")
    tw, th = round(W * k), round(H * k)
    img.resize((tw, th), Image.LANCZOS).save(f"{OUT}/hud_{name}_hd.png")
    img.resize((tw * 2, th * 2), Image.LANCZOS).save(f"{OUT}/hud_{name}_hd@2x.png")
    c = P(L["disc"][0], L["disc"][1])
    wl, pl = [], []
    for x0, x1 in L["wells"]:
        a, b = P(x0, L["well_y"][0]), P(x1, L["well_y"][1]); wl.append([a[0], a[1], round(b[0] - a[0], 2), round(b[1] - a[1], 2)])
        a, b = P(x0, L["plate_y"][0]), P(x1, L["plate_y"][1]); pl.append([a[0], a[1], round(b[0] - a[0], 2), round(b[1] - a[1], 2)])
    dr = L.get("disc_1080", DISC_1080)
    meta[name] = {"file": f"hud_{name}_hd.png", "size": [tw, th], "disc": [c[0], c[1], round(dr, 2), round(dr, 2)], "wells": wl, "plates": pl,
                  "panel_inner_x": round(panel_edge * k, 2),
                  "panel_bottom_band": [round((H - 0.11 * H) * k, 2), round(H * k, 2)]}
    print(name, "scale %.4f" % k, (tw, th), "disc", meta[name]["disc"], "well0", wl[0])
# XP strip
rgba, off = key(f"{SRC}/a3_xp_raw.png")
H, W = rgba.shape[:2]
img = Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")
th = 30; tw = round(W * th / H)
img.resize((tw, th), Image.LANCZOS).save(f"{OUT}/hud_xp_strip.png")
img.resize((tw * 2, th * 2), Image.LANCZOS).save(f"{OUT}/hud_xp_strip@2x.png")
meta["xp_strip"] = {"file": "hud_xp_strip.png", "size": [tw, th], "inner_frac": [0.05, 0.33, 0.90, 0.40],
                    "cap_frac": 0.035}
json.dump(meta, open(f"{OUT}/hud_redraw.json", "w"), indent=1)
print("xp", (tw, th))
