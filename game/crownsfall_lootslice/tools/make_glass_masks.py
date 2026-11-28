"""Glass-only masks for the HUD drain shader (exact red/blue glass pixels; statue and ring excluded). Free, local."""
import numpy as np, json, cv2, sys
from PIL import Image
D = sys.argv[1]; m = json.load(open(f"{D}/hud_full.json"))
im = np.asarray(Image.open(f"{D}/hud_full@2x.png").convert("RGB"))
hsv = cv2.cvtColor(im, cv2.COLOR_RGB2HSV)
H, W = im.shape[:2]
for side, hue in [("left", lambda h: (h < 10) | (h > 165)), ("right", lambda h: (h > 95) & (h < 135))]:
    cx, cy, r, _ = [v * 2 for v in m["disc_" + side]]
    n = int(round(2 * r))
    x0, y0 = int(round(cx - r)), int(round(cy - r))
    # canvas = the disc's square; sample the image where it exists
    sub = np.zeros((n, n, 3), np.uint8)
    sx0, sy0, sx1, sy1 = max(0, x0), max(0, y0), min(W, x0 + n), min(H, y0 + n)
    sub[sy0 - y0:sy1 - y0, sx0 - x0:sx1 - x0] = hsv[sy0:sy1, sx0:sx1]
    mk = (hue(sub[..., 0]) & (sub[..., 1] > 70) & (sub[..., 2] > 35)).astype(np.uint8) * 255
    yy, xx = np.mgrid[0:n, 0:n]
    mk[(xx - r) ** 2 + (yy - r) ** 2 > r * r] = 0
    mk = cv2.morphologyEx(mk, cv2.MORPH_CLOSE, np.ones((9, 9), np.uint8))
    cnt, lab, st, _ = cv2.connectedComponentsWithStats(mk)
    k = 1 + np.argmax(st[1:, 4]); mk = np.where(lab == k, 255, 0).astype(np.uint8)
    cs, _ = cv2.findContours(mk, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    mk = np.zeros_like(mk); cv2.drawContours(mk, cs, -1, 255, -1)          # include the specular highlight
    mk = cv2.GaussianBlur(cv2.erode(mk, np.ones((3, 3), np.uint8)), (0, 0), 1.0)
    Image.fromarray(mk).save(f"{D}/glass_mask_{side}.png")
    print(side, mk.shape, round(float((mk > 128).mean()), 3))
