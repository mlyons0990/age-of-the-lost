"""Post-process the keyed HUD redraw (run after key_hud_redraw.py) - free, local:

1. Despill: remove the faint chroma-green fringe left on the right piece's edges.
2. XP frame: a seamless, horizontally tileable strip built from the skill panel's own top and bottom bronze-and-stone
   borders with a recessed groove between them, so the XP bar is framed in the same material as the panels.
Updates hud_redraw.json in place.
"""
import json, sys
import numpy as np
import cv2
from PIL import Image

D = sys.argv[1]
meta = json.load(open(f"{D}/hud_redraw.json"))
R = meta["right"]

def despill(a):
    rgb = a[..., :3].astype(np.float32)
    m = np.maximum(rgb[..., 0], rgb[..., 2])
    rgb[..., 1] = np.minimum(rgb[..., 1], m * 1.04 + 2)
    a[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    return a

def recolor_red(a, cx, cy, r):
    """blue glass -> deep red glass inside the disc; low-saturation highlights and the statue stay as they are."""
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    inside = (xx - cx) ** 2 + (yy - cy) ** 2 <= (r * 1.04) ** 2
    hsv = cv2.cvtColor(a[..., :3], cv2.COLOR_RGB2HSV).astype(np.float32)
    blue = inside & (hsv[..., 0] > 88) & (hsv[..., 0] < 140) & (hsv[..., 1] > 55)
    soft = cv2.GaussianBlur(blue.astype(np.float32), (0, 0), 1.2)
    out = hsv.copy()
    out[..., 0] = 178                                   # deep crimson
    out[..., 1] = np.clip(hsv[..., 1] * 1.02, 0, 255)
    out[..., 2] = np.clip(hsv[..., 2] * 0.86, 0, 255)
    red = cv2.cvtColor(out.astype(np.uint8), cv2.COLOR_HSV2RGB).astype(np.float32)
    rgb = a[..., :3].astype(np.float32)
    a[..., :3] = np.clip(rgb * (1 - soft[..., None]) + red * soft[..., None], 0, 255).astype(np.uint8)
    return a

def rect_mirror(v, W):
    return [round(W - v[0] - v[2], 2), v[1], v[2], v[3]]

for side in ("left", "right"):
    for suffix in ("", "@2x"):
        a = np.array(Image.open(f"{D}/hud_{side}_hd{suffix}.png").convert("RGBA"))
        Image.fromarray(despill(a)).save(f"{D}/hud_{side}_hd{suffix}.png")

# ---- XP frame from the panel's borders (2x source rows, measured on hud_right_hd@2x.png) ----
src = np.array(Image.open(f"{D}/hud_right_hd@2x.png").convert("RGBA")).astype(np.float32)
x0, x1 = 150, 590                                  # the panel border's run between its corners (no globe, no wells)
top = src[200:220, x0:x1]                          # outer rim + inner bronze line
stone = src[226:232, x0:x1]                        # plain panel stone
bot = src[422:446, x0:x1]                          # inner line + rim + bottom edge
gw = x1 - x0
groove_h = 22
g = np.zeros((groove_h, gw, 4), np.float32)
bronze = np.array([150, 112, 78, 255], np.float32)
dark = np.array([20, 16, 18, 255], np.float32)
for y in range(groove_h):
    t = y / (groove_h - 1)
    g[y] = dark * (0.75 + 0.35 * t)                # recessed: darker at the top (inner shadow)
    g[y, :, 3] = 255
g[0] = bronze * 0.85; g[0, :, 3] = 255             # thin bronze bevel lines, like the key plates
g[1] = bronze * 0.45; g[1, :, 3] = 255
g[-1] = bronze * 0.95; g[-1, :, 3] = 255
g[-2] = bronze * 0.5; g[-2, :, 3] = 255
tile = np.concatenate([top, stone, g, stone, bot], axis=0)
# seamless: cross-fade the last 40 px into the first 40 px
f = 50
ramp = np.linspace(0, 1, f)[None, :, None]
tile[:, :f] = tile[:, :f] * ramp + tile[:, -f:] * (1 - ramp)
tile = tile[:, : gw - f]
tile2 = np.clip(tile, 0, 255).astype(np.uint8)
Image.fromarray(tile2).save(f"{D}/hud_xp_frame@2x.png")
h2, w2 = tile2.shape[:2]
Image.fromarray(tile2).resize((w2 // 2, h2 // 2), Image.LANCZOS).save(f"{D}/hud_xp_frame.png")
gy = top.shape[0] + stone.shape[0]
meta["xp_frame"] = {"file": "hud_xp_frame.png", "size": [w2 // 2, h2 // 2],
                    "groove": [0, (gy + 2) / 2.0, w2 // 2, (groove_h - 4) / 2.0]}
json.dump(meta, open(f"{D}/hud_redraw.json", "w"), indent=1)
print("xp frame", meta["xp_frame"])
