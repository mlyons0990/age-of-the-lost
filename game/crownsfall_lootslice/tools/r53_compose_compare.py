#!/usr/bin/env python3
"""Place the real Godot R52/R53 renders side by side with labels, and build the R53 Slash GIF.
usage: r53_compose_compare.py <capture dir> <out dir>"""
import sys, glob, os
from PIL import Image, ImageDraw, ImageFont, ImageChops
src, out = sys.argv[1:3]
os.makedirs(out, exist_ok=True)
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 30)
except OSError:
    font = ImageFont.load_default()
for a in sorted(glob.glob(os.path.join(src, "r52_*.png"))):
    tag = os.path.basename(a)[4:-4]
    l, r = Image.open(a).convert("RGB"), Image.open(os.path.join(src, "r53_" + tag + ".png")).convert("RGB")
    # crop both to the union of the character's pixels (background is flat), then enlarge
    bg = l.getpixel((2, 2))
    bl = ImageChops.difference(l, Image.new("RGB", l.size, bg)).convert("L").point(lambda v: 255 if v > 12 else 0).getbbox()
    br = ImageChops.difference(r, Image.new("RGB", r.size, bg)).convert("L").point(lambda v: 255 if v > 12 else 0).getbbox()
    bx = (min(bl[0], br[0]) - 20, min(bl[1], br[1]) - 20, max(bl[2], br[2]) + 20, max(bl[3], br[3]) + 20)
    k = 760 / (bx[3] - bx[1])
    l = l.crop(bx).resize((round((bx[2] - bx[0]) * k), 760), Image.LANCZOS)
    r = r.crop(bx).resize(l.size, Image.LANCZOS)
    im = Image.new("RGB", (l.width + r.width, l.height + 50), (22, 23, 28))
    im.paste(l, (0, 50)); im.paste(r, (l.width, 50))
    d = ImageDraw.Draw(im)
    d.text((20, 10), "R52 — " + tag.replace("Slash_FullBody_R50", "Slash").replace("_f", " f"), font=font, fill=(235, 220, 190))
    d.text((l.width + 20, 10), "R53 arm skin", font=font, fill=(160, 220, 255))
    im.save(os.path.join(out, "r53_vs_r52_" + tag + ".jpg"), quality=88)
frames = [Image.open(f).convert("RGB").resize((450, 450)) for f in sorted(glob.glob(os.path.join(src, "gif", "slash_*.png")))]
if frames:
    frames[0].save(os.path.join(out, "r53_slash_godot.gif"), save_all=True, append_images=frames[1:], duration=1000 // 15, loop=0)
print("written", out)
