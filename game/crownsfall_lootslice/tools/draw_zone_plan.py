"""Free master-layout plan sketch for a zone (Whisperwood, 3 x 3 tiles): existing painting in place, main paths,
points of interest, off-path rewards, biome gradient. Agreed with the owner before paying for the master painting, and
(--clean) used as its composition reference.
Zone rules (owner 11-22): at least 3 x 3 tiles (3x3 tiles of 21:9 at the 31-degree camera cover ~square ground, so
zones fit together), the whole forest floor is walkable (only trunks, rocks, water and ruins block), paths guide but
going off-path is rewarded.
usage: python draw_zone_plan.py <out.png> [--clean]"""
import sys, random, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter
out = sys.argv[1]; clean = "--clean" in sys.argv
random.seed(7)
TW, TH, NC, NR = 640, 275, 3, 3
W, H = TW * NC, TH * NR
img = Image.new("RGB", (W, H))
px = img.load()
for x in range(W):
    for y in range(H):
        t = min(1, max(0, (x / W) * 0.6 + (y / H) * 0.6 - 0.15))
        px[x, y] = (int(78 - 32 * t), int(100 - 24 * t), int(60 + 12 * t))
d = ImageDraw.Draw(img)
def font(b, s):
    try: return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf" % ("-Bold" if b else ""), s)
    except Exception: return ImageFont.load_default()
F, f = font(True, 15), font(False, 12)
W1 = (1, 0)
img.paste(Image.open("assets/zones/whisperwood_w1.png").convert("RGB").resize((TW, TH)), (W1[0] * TW, W1[1] * TH))
d = ImageDraw.Draw(img)
# trees: canopy blobs with a small trunk dot (only the trunk blocks; the floor between trees is walkable)
for i in range(520):
    x = random.randint(0, W); y = random.randint(0, H)
    if W1[0] * TW <= x < (W1[0] + 1) * TW and y < TH: continue
    r = random.randint(10, 20)
    d.ellipse([x - r, y - r, x + r, y + r], fill=(40 + random.randint(0, 20), 68 + random.randint(0, 20), 42), outline=(30, 50, 32))
    if not clean: d.ellipse([x - 2, y + r - 6, x + 2, y + r - 2], fill=(55, 38, 28))
for (x, y, rx, ry) in [(1500, 690, 60, 22), (1650, 640, 70, 26), (1800, 720, 55, 20), (1060, 740, 70, 26), (1220, 790, 50, 18), (1700, 560, 40, 15)]:
    d.ellipse([x - rx, y - ry, x + rx, y + ry], fill=(70, 110, 128), outline=(160, 200, 210))
mist = Image.new("L", (W, H), 0); md = ImageDraw.Draw(mist)
for i in range(90):
    x = random.randint(int(W * 0.4), W); y = random.randint(int(H * 0.4), H); r = random.randint(40, 120)
    md.ellipse([x - r, y - r // 2, x + r, y + r // 2], fill=75)
mist = mist.filter(ImageFilter.GaussianBlur(28))
img = Image.composite(Image.new("RGB", (W, H), (190, 170, 220)), img, mist); d = ImageDraw.Draw(img)
def road(pts, w=16):
    d.line(pts, fill=(120, 104, 84), width=w + 6, joint="curve"); d.line(pts, fill=(222, 206, 176), width=w, joint="curve")
# main paths: W1 top-right exit -> east (stele) -> south (elder grove) -> south-east arch
road([(2 * TW - 6, 12), (1380, 60), (1500, 120), (1600, 190), (1700, 300), (1720, 420), (1690, 520), (1740, 600), (1800, 700), (1850, 780), (W, 800)])
# W1 bottom-left exit -> west -> moonwell glade (west middle)
road([(TW + 6, 250), (560, 290), (430, 340), (300, 400), (200, 420)])
# branch south from the main path to the drowned altar pool (bottom middle)
road([(1690, 520), (1500, 560), (1330, 640), (1180, 700), (1100, 730)], 12)
# POI features
for a in range(8):
    x = 1720 + 62 * math.cos(a * math.pi / 4); y = 420 + 26 * math.sin(a * math.pi / 4)
    d.ellipse([x - 12, y - 12, x + 12, y + 12], fill=(48, 34, 26))
d.rectangle([1600, 170, 1616, 208], fill=(205, 200, 190))
d.ellipse([140, 405, 210, 440], fill=(170, 200, 255))
d.rectangle([1090, 728, 1112, 743], fill=(190, 180, 170))
d.arc([W - 40, 775, W + 10, 830], 180, 360, fill=(170, 165, 150), width=8)
GOLD = (242, 210, 122); BLUE = (150, 200, 255); RED = (240, 110, 95); PURP = (205, 160, 255); GREEN = (160, 230, 160); TEAL = (120, 230, 210)
def poi(x, y, sym, title, lines, col):
    if clean: return
    d.ellipse([x - 17, y - 17, x + 17, y + 17], fill=(20, 18, 24), outline=col, width=3)
    d.text((x, y), sym, font=F, fill=col, anchor="mm")
    tw = max(d.textlength(title, font=F), *(d.textlength(l, font=f) for l in lines)) + 12
    bx = x + 24 if x + 24 + tw < W - 4 else x - 24 - tw; by = max(4, min(y - 22, H - 22 - 15 * len(lines)))
    d.rectangle([bx, by, bx + tw, by + 20 + 15 * len(lines)], fill=(15, 13, 18))
    d.text((bx + 6, by + 3), title, font=F, fill=col)
    for i, l in enumerate(lines): d.text((bx + 6, by + 21 + 15 * i), l, font=f, fill=(230, 222, 205))
def cache(x, y, txt):
    if clean: return
    d.rectangle([x - 7, y - 6, x + 7, y + 6], fill=(150, 105, 45), outline=(255, 220, 140), width=2)
    right = x + 11 + d.textlength(txt, font=f) < W - 4
    d.text((x + 11, y) if right else (x - 11, y), txt, font=f, fill=(255, 225, 150), anchor="lm" if right else "rm")
poi(TW + 182, 22, "▲", "EXIT — Crownsfall", ["stairs up to town (existing)"], GOLD)
poi(TW + 330, 200, "◆", "WAYPOINT — Fallen Shrine", ["existing, centred in ruins"], BLUE)
poi(1608, 190, "✦", "LORE — Weeping Stele", ["lorecasting unlock"], PURP)
poi(1720, 420, "☠", "RARE BOSS — Elder Grove", ["ring of giant trees,", "the Thornmother may spawn"], RED)
poi(175, 422, "?", "SECRET — Moonwell Glade", ["hidden behind a root tunnel"], GREEN)
poi(1100, 735, "✦", "LORE — Drowned Altar", ["half-sunk in a forest pool"], PURP)
poi(W - 26, 800, "▲", "EXIT — Hollowmere", ["mossy stone arch, misty marsh"], GOLD)
poi(330, 700, "❀", "OFF-PATH — Fae Ring", ["mushroom circle event"], TEAL)
poi(980, 470, "⌂", "OFF-PATH — Hunter's Camp", ["abandoned camp, journal page"], TEAL)
cache(240, 120, "hidden cache"); cache(560, 560, "hidden cache"); cache(1320, 420, "hidden cache"); cache(1880, 220, "hidden cache"); cache(1500, 800, "hidden cache")
if not clean:
    for c in range(1, NC): d.line([(c * TW, 0), (c * TW, H)], fill=(255, 255, 255), width=1)
    for r in range(1, NR): d.line([(0, r * TH), (W, r * TH)], fill=(255, 255, 255), width=1)
    for r in range(NR):
        for c in range(NC): d.text((c * TW + 6, r * TH + TH - 18), "tile %d,%d" % (c, r) + (" (existing W1)" if (c, r) == W1 else ""), font=f, fill=(255, 255, 255))
    d.rectangle([W1[0] * TW, W1[1] * TH, (W1[0] + 1) * TW - 1, (W1[1] + 1) * TH - 1], outline=GOLD, width=3)
    o = Image.new("RGB", (W, H + 92), (14, 12, 16)); o.paste(img, (0, 46)); od = ImageDraw.Draw(o)
    od.text((12, 10), "WHISPERWOOD — master layout plan v2 (free sketch): 3 x 3 tiles, ~square ground at the 31° camera", font=F, fill=GOLD)
    od.text((12, H + 54), "Whole forest floor walkable — only trunks (dots), rocks, water and ruins block.  Paths guide; off-path: caches, Fae Ring, Hunter's Camp, secret glade, lore.", font=f, fill=(235, 230, 215))
    od.text((12, H + 72), "NW: tended, lanterns, white stone (near Crownsfall)  ->  SE: wilder, wetter, pools, reeds, thick lavender mist (into Hollowmere marsh)", font=f, fill=(235, 230, 215))
    img = o
img.save(out); print(img.size)
