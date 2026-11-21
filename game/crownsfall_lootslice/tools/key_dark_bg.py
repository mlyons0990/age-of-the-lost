"""Cut a HUD asset generated on a dark background (with a soft glow halo) - OpenCV GrabCut seeded by brightness.
usage: python key_dark_bg.py <in.png> <out.png>"""
import sys, numpy as np, cv2
from PIL import Image
im = cv2.imread(sys.argv[1]); h, w = im.shape[:2]
s = 0.5
small = cv2.resize(im, (int(w * s), int(h * s)), interpolation=cv2.INTER_AREA)
hsv = cv2.cvtColor(small, cv2.COLOR_BGR2HSV); lum = small.mean(-1)
mask = np.full(small.shape[:2], cv2.GC_PR_BGD, np.uint8)
mask[lum > 55] = cv2.GC_PR_FGD
mask[(lum > 95) | ((hsv[..., 1] > 120) & (hsv[..., 2] > 60))] = cv2.GC_FGD
mask[lum < 18] = cv2.GC_BGD
bgd = np.zeros((1, 65)); fgd = np.zeros((1, 65))
cv2.grabCut(small, mask, None, bgd, fgd, 6, cv2.GC_INIT_WITH_MASK)
m = np.where((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD), 255, 0).astype(np.uint8)
n, lab, st, _ = cv2.connectedComponentsWithStats(m)
m = np.where(lab == 1 + np.argmax(st[1:, 4]), 255, 0).astype(np.uint8)
cs, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
m = np.zeros_like(m); cv2.drawContours(m, cs, -1, 255, -1)
m = cv2.resize(m, (w, h), interpolation=cv2.INTER_LINEAR)
m = cv2.GaussianBlur(m, (0, 0), 1.6); m = np.clip((m.astype(np.float32) - 128) * 2.2 + 128, 0, 255).astype(np.uint8)
rgba = cv2.cvtColor(im, cv2.COLOR_BGR2RGBA); rgba[..., 3] = m
Image.fromarray(rgba).save(sys.argv[2]); print("kept", round(float((m > 128).mean()), 3))
