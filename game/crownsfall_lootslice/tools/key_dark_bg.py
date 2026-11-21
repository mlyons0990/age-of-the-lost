"""Cut a HUD asset generated on a black background with a soft glow halo (free, local).
Foreground = textured or bright pixels (the art is detailed; the halo is a smooth gradient), holes filled so the
statue is fully opaque, halo removed, edges anti-aliased. usage: python key_dark_bg.py <in.png> <out.png>"""
import sys, numpy as np, cv2
from PIL import Image
im = cv2.imread(sys.argv[1]); h, w = im.shape[:2]
g = cv2.cvtColor(im, cv2.COLOR_BGR2GRAY).astype(np.float32)
hsv = cv2.cvtColor(im, cv2.COLOR_BGR2HSV)
mu = cv2.blur(g, (9, 9)); sd = np.sqrt(np.maximum(cv2.blur(g * g, (9, 9)) - mu * mu, 0))
tex = (sd > 7.0) & (g > 28)                                     # carved detail: high local contrast
bright = g > 125                                               # lit stone / bronze
red = ((hsv[..., 0] < 10) | (hsv[..., 0] > 165)) & (hsv[..., 1] > 110) & (hsv[..., 2] > 40)
m = (tex | bright | red).astype(np.uint8)
m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, np.ones((25, 25), np.uint8))
m = cv2.morphologyEx(m, cv2.MORPH_OPEN, np.ones((9, 9), np.uint8))
n, lab, st, _ = cv2.connectedComponentsWithStats(m)
m = (lab == 1 + np.argmax(st[1:, 4])).astype(np.uint8)
cs, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
m = np.zeros_like(m); cv2.drawContours(m, cs, -1, 1, -1)       # fill every interior hole (solid statue)
m = cv2.erode(m, np.ones((5, 5), np.uint8))                    # shave the halo fringe
a = cv2.GaussianBlur(m.astype(np.float32), (0, 0), 1.3)
a = np.clip((a - 0.5) * 2.4 + 0.5, 0, 1)
rgba = cv2.cvtColor(im, cv2.COLOR_BGR2RGBA); rgba[..., 3] = (a * 255).astype(np.uint8)
Image.fromarray(rgba).save(sys.argv[2]); print("kept", round(float(m.mean()), 3))
