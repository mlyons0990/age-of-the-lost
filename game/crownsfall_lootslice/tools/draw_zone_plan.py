"""Free master-layout plan sketch for a zone (Whisperwood): tile grid, existing painting in place, paths, POIs, biome
gradient. Used to agree the layout before paying for the master painting, and as its composition reference.
usage: python draw_zone_plan.py <out.png> [--clean]   (--clean: no labels/grid, for use as a generation reference)"""
import sys, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter
out = sys.argv[1]; clean = "--clean" in sys.argv
random.seed(7)
TW, TH = 640, 275
W, H = TW * 3, TH * 2
img = Image.new("RGB", (W, H))
for x in range(W):
    for y in range(H):
        t = min(1, max(0, (x / W) * 0.7 + (y / H) * 0.5 - 0.1))
        img.putpixel((x, y), (int(74 - 30 * t), int(96 - 22 * t), int(62 + 8 * t)))
img = img.filter(ImageFilter.GaussianBlur(2)); d = ImageDraw.Draw(img)
def font(b, s):
    try: return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf" % ("-Bold" if b else ""), s)
    except Exception: return ImageFont.load_default()
F, f = font(True, 15), font(False, 12)
w1 = Image.open("assets/zones/whisperwood_w1.png").convert("RGB").resize((TW, TH))
img.paste(w1, (TW, 0))
if not clean: d.rectangle([TW, 0, 2 * TW - 1, TH - 1], outline=(242, 210, 122), width=3)
for i in range(260):
    x = random.randint(0, W); y = random.randint(0, H)
    if TW <= x < 2 * TW and y < TH: continue
    r = random.randint(10, 22); d.ellipse([x - r, y - r, x + r, y + r], fill=(38 + random.randint(0, 20), 66 + random.randint(0, 20), 40), outline=(28, 48, 30))
for (x, y, rx, ry) in [(1580, 470, 70, 26), (1700, 430, 55, 20), (1450, 500, 40, 16), (1820, 500, 60, 22), (1110, 500, 45, 17)]:
    d.ellipse([x - rx, y - ry, x + rx, y + ry], fill=(70, 110, 128), outline=(160, 200, 210))
mist = Image.new("L", (W, H), 0); md = ImageDraw.Draw(mist)
for i in range(60):
    x = random.randint(int(W * 0.45), W); y = random.randint(int(H * 0.35), H); r = random.randint(40, 110)
    md.ellipse([x - r, y - r // 2, x + r, y + r // 2], fill=70)
mist = mist.filter(ImageFilter.GaussianBlur(25))
img = Image.composite(Image.new("RGB", (W, H), (190, 170, 220)), img, mist); d = ImageDraw.Draw(img)
def road(pts, w=16):
    d.line(pts, fill=(120, 104, 84), width=w + 6, joint="curve"); d.line(pts, fill=(222, 206, 176), width=w, joint="curve")
road([(2 * TW - 6, 12), (1380, 60), (1500, 120), (1600, 170), (1720, 250), (1760, 330), (1720, 420), (1760, 500), (1880, 520), (W, 515)])
road([(TW + 6, 250), (590, 268), (470, 300), (360, 330), (250, 330), (150, 300)])
road([(1500, 120), (1430, 230), (1360, 330), (1250, 420), (1100, 470)], 12)
# POI features (drawn in clean mode too, as shapes)
d.ellipse([1640, 270, 1740, 330], outline=(60, 40, 30), width=6)                       # elder grove ring
for a in range(8):
    import math; x = 1690 + 62 * math.cos(a * math.pi / 4); y = 300 + 26 * math.sin(a * math.pi / 4)
    d.ellipse([x - 12, y - 12, x + 12, y + 12], fill=(48, 34, 26))
d.rectangle([1600, 130, 1616, 168], fill=(205, 200, 190))                               # stele
d.ellipse([170, 300, 230, 330], fill=(170, 200, 255))                                    # moonwell
d.rectangle([1128, 455, 1150, 470], fill=(190, 180, 170))                                # altar
d.arc([W - 40, 490, W + 10, 545], 180, 360, fill=(170, 165, 150), width=8)               # arch
GOLD = (242, 210, 122); BLUE = (150, 200, 255); RED = (240, 110, 95); PURP = (205, 160, 255); GREEN = (160, 230, 160)
def poi(x, y, sym, title, lines, col):
    if clean: return
    d.ellipse([x - 17, y - 17, x + 17, y + 17], fill=(20, 18, 24), outline=col, width=3)
    d.text((x, y), sym, font=F, fill=col, anchor="mm")
    tw = max(d.textlength(title, font=F), *(d.textlength(l, font=f) for l in lines)) + 12
    bx = x + 24 if x + 24 + tw < W - 4 else x - 24 - tw; by = y - 22
    d.rectangle([bx, by, bx + tw, by + 20 + 15 * len(lines)], fill=(15, 13, 18))
    d.text((bx + 6, by + 3), title, font=F, fill=col)
    for i, l in enumerate(lines): d.text((bx + 6, by + 21 + 15 * i), l, font=f, fill=(230, 222, 205))
poi(TW + 182, 16, "▲", "EXIT — Crownsfall", ["stairs up to town (existing)"], GOLD)
poi(TW + 330, 200, "◆", "WAYPOINT — Fallen Shrine", ["existing, centred in ruins"], BLUE)
poi(1608, 150, "✦", "LORE — Weeping Stele", ["lorecasting unlock"], PURP)
poi(1690, 300, "☠", "RARE BOSS — Elder Grove", ["ring of giant trees,", "the Thornmother may spawn"], RED)
poi(200, 315, "?", "SECRET — Moonwell Glade", ["hidden behind a root tunnel"], GREEN)
poi(1140, 462, "✦", "LORE — Drowned Altar", ["half-sunk in a pool"], PURP)
poi(W - 26, 515, "▲", "EXIT — Hollowmere", ["mossy stone arch, misty marsh"], GOLD)
if not clean:
    for c in range(1, 3): d.line([(c * TW, 0), (c * TW, H)], fill=(255, 255, 255), width=1)
    d.line([(0, TH), (W, TH)], fill=(255, 255, 255), width=1)
    for r in range(2):
        for c in range(3): d.text((c * TW + 6, r * TH + TH - 18), "tile %d,%d" % (c, r) + (" (existing W1)" if (c, r) == (1, 0) else ""), font=f, fill=(255, 255, 255))
    d.text((14, H - 36), "WEST: tended paths, lanterns, close to Crownsfall", font=f, fill=(240, 235, 220))
    d.text((W - 14, 22), "EAST/SOUTH: wilder, wetter, thicker lavender mist  ->  marsh (next zone: Hollowmere)", font=f, fill=(240, 235, 220), anchor="ra")
    o = Image.new("RGB", (W, H + 46), (14, 12, 16)); o.paste(img, (0, 46)); ImageDraw.Draw(o).text((12, 10), "WHISPERWOOD — master layout plan (free sketch; 6 tiles = 3 x 2, each tile 3840x1648 at game scale)", font=F, fill=GOLD)
    img = o
img.save(out); print(img.size)
