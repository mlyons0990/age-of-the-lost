"""Build a dodge-roll strip from a green-screen clip, re-centred on every frame.
usage: make_roll_strip.py clip.mp4 idle_ref.png out.png frame,frame,...
Like make_attack_strip.py (512 px frames, the 384 px idle pose centred), but each frame's
silhouette is moved back under the knight's feet: the game moves him across the ground,
so the travel inside the clip would otherwise be doubled."""
import sys, subprocess, tempfile, glob, os
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from key_sprite import key
clip, idle, out, picks = sys.argv[1], sys.argv[2], sys.argv[3], [int(x) for x in sys.argv[4].split(',')]
tmp = tempfile.mkdtemp()
subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', clip, tmp + '/%03d.png'], check=True)
frames = sorted(glob.glob(tmp + '/*.png'))
bbox = lambda im: im.getchannel('A').point(lambda p: 255 if p > 60 else 0).getbbox()
ib = bbox(Image.open(idle).convert('RGBA'))
fb = bbox(key(Image.open(frames[0])))
s = (ib[3] - ib[1]) / (fb[3] - fb[1])
F, M = 512, 64
sheet = Image.new('RGBA', (F * len(picks), F))
for i, n in enumerate(picks):
    im = key(Image.open(frames[n]))
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    b = bbox(im)
    # this frame's silhouette: centre x and bottom y onto the idle pose's
    dx = M + (ib[0] + ib[2]) / 2 - (b[0] + b[2]) / 2
    dy = M + ib[3] - b[3]
    cell = Image.new('RGBA', (F, F))
    cell.paste(im, (round(dx), round(dy)), im)
    sheet.paste(cell, (i * F, 0))
sheet.save(out); print(out, sheet.size, 'scale', round(s, 3))
