"""Green-screen key + crop for a single sprite image. usage: key_sprite.py in.png out.png [height]"""
import sys, numpy as np
from PIL import Image
def key(im):
    a = np.asarray(im.convert('RGB')).astype(float); r, g, b = a[..., 0], a[..., 1], a[..., 2]
    m = np.maximum(r, b); spill = g - m
    alpha = np.clip(1 - (spill - 20) / 50, 0, 1)
    g2 = np.where(spill > 0, m + spill * 0.1, g)
    # green light bleeding through violet mist turns it teal: pull those pixels back toward violet
    teal = (b > r) & (g2 > (r + b) / 2)
    g2 = np.where(teal, (r + b) / 2, g2)
    return Image.fromarray(np.dstack([r, g2, b, alpha * 255]).clip(0, 255).astype(np.uint8), 'RGBA')
if __name__ == '__main__':
    im = key(Image.open(sys.argv[1]))
    box = im.getchannel('A').point(lambda p: 255 if p > 40 else 0).getbbox()
    im = im.crop(box)
    if len(sys.argv) > 3:
        h = int(sys.argv[3]); im = im.resize((round(im.width * h / im.height), h), Image.LANCZOS)
    im.save(sys.argv[2]); print(sys.argv[2], im.size)
