#!/usr/bin/env python3
"""Cut the painted enemy poses (art/higgsfield_2026-11/enemies/<enemy>_<pose>.png, GPT Image 2.6 on transparent
backgrounds, 2026-11-27) into game sprites: trim to the alpha bounds, scale every pose of an enemy by the same factor
(its idle pose becomes IDLE_PX tall) so the creature keeps one size in every pose, and save
assets/enemies/poses/<enemy>_<pose>.png. The game draws each pose bottom-centred on the monster's feet.

    python3 tools/cut_enemy_poses.py
"""
import json, os
import numpy as np
from PIL import Image

here = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.normpath(os.path.join(here, "../../../art/higgsfield_2026-11/enemies"))
OUT = os.path.normpath(os.path.join(here, "../assets/enemies/poses"))
POSES = ["idle", "walk", "windup", "strike", "hit", "death"]
IDLE_PX = 512
os.makedirs(OUT, exist_ok=True)
meta = {}
for enemy in ["slime", "revenant", "brute"]:
    if not all(os.path.exists(os.path.join(SRC, "%s_%s.png" % (enemy, p))) for p in POSES):
        print("skip", enemy, "(poses missing)")
        continue
    ims = {}
    for p in POSES:
        im = Image.open(os.path.join(SRC, "%s_%s.png" % (enemy, p))).convert("RGBA")
        a = np.array(im)
        a[a[:, :, 3] < 14] = 0
        im = Image.fromarray(a)
        ims[p] = im.crop(im.getbbox())
    k = IDLE_PX / ims["idle"].height
    meta[enemy] = {}
    for p, im in ims.items():
        im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
        im.save(os.path.join(OUT, "%s_%s.png" % (enemy, p)))
        meta[enemy][p] = [im.width, im.height]
json.dump({"idle_px": IDLE_PX, "poses": meta}, open(os.path.join(OUT, "poses.json"), "w"), indent=1)
print(json.dumps(meta))
