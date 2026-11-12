"""Build an attack sprite strip from a green-screen clip.
usage: make_attack_strip.py clip.mp4 idle_ref.png out.png frame,frame,...
The clip's first frame shows the same pose as idle_ref, so it is used to match scale and position.
Output frames are 512x512 with the 384x384 idle frame centred inside, so both share one sprite offset."""
import sys, subprocess, tempfile, glob, os
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from key_sprite import key
clip, idle, out, picks = sys.argv[1], sys.argv[2], sys.argv[3], [int(x) for x in sys.argv[4].split(',')]
tmp = tempfile.mkdtemp()
subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', clip, tmp + '/%03d.png'], check=True)
frames = sorted(glob.glob(tmp + '/*.png'))
bbox = lambda im: im.getchannel('A').point(lambda p: 255 if p > 60 else 0).getbbox()
ib = bbox(Image.open(idle).convert('RGBA'))
f0 = key(Image.open(frames[0])); fb = bbox(f0)
s = (ib[3] - ib[1]) / (fb[3] - fb[1])
F, M = 512, 64
sheet = Image.new('RGBA', (F * len(picks), F))
for i, n in enumerate(picks):
    im = key(Image.open(frames[n]))
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    # align the clip's first-frame bbox onto the idle bbox (centre x, bottom y)
    dx = M + (ib[0] + ib[2]) / 2 - (fb[0] + fb[2]) / 2 * s
    dy = M + ib[3] - fb[3] * s
    cell = Image.new('RGBA', (F, F)); cell.alpha_composite(im, (round(dx), round(dy))) if 0 <= round(dx) and 0 <= round(dy) else cell.paste(im, (round(dx), round(dy)), im)
    sheet.paste(cell, (i * F, 0))
sheet.save(out); print(out, sheet.size, 'scale', round(s, 3))
