#!/usr/bin/env python3
"""Place the real Godot R52/R53 renders side by side with labels, and build the R53 Slash GIF.
usage: r53_compose_compare.py <capture dir> <out dir> [before prefix] [after prefix] [after label]
Defaults compare r52_ with r53_ (R53); R54 uses: r53 r54 "R54 elbow helper"."""
import sys, glob, os
from PIL import Image, ImageDraw, ImageFont, ImageChops
src, out = sys.argv[1:3]
pa, pb = (sys.argv[3:5] if len(sys.argv) > 4 else ("r52", "r53"))
after_label = sys.argv[5] if len(sys.argv) > 5 else after_label
gif_name = pb + ("_slash_godot.gif")
os.makedirs(out, exist_ok=True)
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 30)
except OSError:
    font = ImageFont.load_default()
for a in sorted(glob.glob(os.path.join(src, pa + "_*.png"))):
    tag = os.path.basename(a)[len(pa) + 1:-4]
    l, r = Image.open(a).convert("RGB"), Image.open(os.path.join(src, pb + "_" + tag + ".png")).convert("RGB")
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
    d.text((20, 10), pa.upper() + " — " + tag.replace("Slash_FullBody_R50", "Slash").replace("_f", " f"), font=font, fill=(235, 220, 190))
    d.text((l.width + 20, 10), after_label, font=font, fill=(160, 220, 255))
    im.save(os.path.join(out, pb + "_vs_" + pa + "_" + tag + ".jpg"), quality=88)
frames = [Image.open(f).convert("RGB").resize((450, 450)) for f in sorted(glob.glob(os.path.join(src, "gif", "slash_*.png")))]
if frames:
    frames[0].save(os.path.join(out, gif_name), save_all=True, append_images=frames[1:], duration=1000 // 15, loop=0)
print("written", out)
