"""Crownsfall plaza floor texture (free, procedural): weathered limestone flagstones with a gold-and-blue
compass-rose mosaic in the centre, after the owner's plaza reference. Writes assets/env/plaza_floor.png (4096^2,
covers 28 m) and plaza_floor_normal.png."""
import numpy as np, math, sys
from PIL import Image, ImageDraw, ImageFilter
N = 4096; M = 28.0; px = N / M
rng = np.random.default_rng(11)
def noise(scale, oct=4):
    acc = np.zeros((N, N), np.float32); amp = 1.0; tot = 0
    for o in range(oct):
        s = max(2, int(N / (scale / (2 ** o))))
        n = rng.random((s, s)).astype(np.float32)
        acc += np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((N, N), Image.BICUBIC), np.float32) / 255 * amp
        tot += amp; amp *= 0.5
    return acc / tot
lime = np.array([176, 164, 142], np.float32)
img = np.ones((N, N, 3), np.float32) * lime
n1 = noise(N / 6); n2 = noise(N / 60, 3)
img *= (0.86 + 0.22 * n1)[..., None] * (0.94 + 0.1 * n2)[..., None]
# flagstones: 1 m courses, staggered, each stone its own tint
mask = Image.new("L", (N, N), 0); d = ImageDraw.Draw(mask)
grout = Image.new("L", (N, N), 0); g = ImageDraw.Draw(grout)
row_h = int(px * 1.6)
for r in range(0, N, row_h):
    off = int(rng.random() * px)
    x = -off
    while x < N:
        w = int(px * rng.choice([1.6, 2.0, 2.4, 2.8]))
        t = int(rng.normal(0, 9))
        d.rectangle([x, r, x + w, r + row_h], fill=128 + t)
        g.rectangle([x, r, x + w, r + row_h], outline=255, width=5)
        x += w
tint = (np.asarray(mask, np.float32) - 128) / 255.0
img *= (1 + tint * 0.9)[..., None]
gr = np.asarray(grout.filter(ImageFilter.GaussianBlur(2)), np.float32) / 255
img = img * (1 - gr[..., None] * 0.45)
# compass rose mosaic (centre, radius 5.5 m)
rose = Image.new("RGBA", (N, N), (0, 0, 0, 0)); rd = ImageDraw.Draw(rose)
c = N / 2; R = 3.6 * px
gold = (168, 124, 58, 255); goldl = (198, 158, 88, 255); blue = (44, 74, 138, 255); blued = (28, 46, 92, 255); cream = (170, 160, 140, 255)
rd.ellipse([c - R, c - R, c + R, c + R], fill=blued); rd.ellipse([c - R * 0.94, c - R * 0.94, c + R * 0.94, c + R * 0.94], fill=cream)
rd.ellipse([c - R * 0.9, c - R * 0.9, c + R * 0.9, c + R * 0.9], fill=blue)
rd.ellipse([c - R * 0.86, c - R * 0.86, c + R * 0.86, c + R * 0.86], fill=cream)
for k in range(32):                                   # tick ring
    a = 2 * math.pi * k / 32
    rd.line([c + math.cos(a) * R * 0.9, c + math.sin(a) * R * 0.9, c + math.cos(a) * R * 0.94, c + math.sin(a) * R * 0.94], fill=gold, width=10)
for k in sorted(range(16), key=lambda k: (k % 4 == 0, k % 2 == 0)):   # 16-point star, long points on top
    a = 2 * math.pi * k / 16 - math.pi / 2
    L = R * (0.84 if k % 4 == 0 else (0.62 if k % 2 == 0 else 0.42)); wdt = 0.30 if k % 4 == 0 else 0.22
    tip = (c + math.cos(a) * L, c + math.sin(a) * L)
    l = (c + math.cos(a - wdt) * R * 0.30, c + math.sin(a - wdt) * R * 0.30); r_ = (c + math.cos(a + wdt) * R * 0.30, c + math.sin(a + wdt) * R * 0.30)
    rd.polygon([(c, c), l, tip], fill=gold if k % 2 == 0 else blue, outline=(70,52,30,255), width=4); rd.polygon([(c, c), r_, tip], fill=goldl if k % 2 == 0 else blued, outline=(70,52,30,255), width=4)
rd.ellipse([c - R * 0.16, c - R * 0.16, c + R * 0.16, c + R * 0.16], fill=blued); rd.ellipse([c - R * 0.1, c - R * 0.1, c + R * 0.1, c + R * 0.1], fill=gold)
ra = np.asarray(rose, np.float32); al = ra[..., 3:4] / 255
tess = (0.9 + 0.16 * noise(N / 300, 2))[..., None]            # mosaic tesserae variation + wear
wear = (0.85 + 0.2 * n1)[..., None]
img = img * (1 - al) + ra[..., :3] * tess * wear * al
img = img * (1 - gr[..., None] * 0.25 * al)
Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).resize((2048, 2048), Image.LANCZOS).save(sys.argv[1] + "/plaza_floor.png")
h = np.asarray(Image.fromarray(np.clip(img.mean(-1), 0, 255).astype(np.uint8)).resize((2048, 2048), Image.LANCZOS), np.float32) / 255
h = h - np.asarray(Image.fromarray((gr * 255).astype(np.uint8)).resize((2048, 2048)), np.float32) / 255 * 0.6
gy, gx = np.gradient(h); nrm = np.dstack([-gx * 6, -gy * 6, np.ones_like(h)]); nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
Image.fromarray(((nrm * 0.5 + 0.5) * 255).astype(np.uint8)).save(sys.argv[1] + "/plaza_floor_normal.png")
print("ok")
