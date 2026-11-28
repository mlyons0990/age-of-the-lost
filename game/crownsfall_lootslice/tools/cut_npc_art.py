#!/usr/bin/env python3
"""Cut the painted NPC art (art/higgsfield_2026-11/npcs/<id>_idle.png and <id>_talk.png, transparent backgrounds)
into game sprites: both poses trimmed and scaled by one factor (idle = IDLE_PX tall) so the NPC keeps its size, plus
a square dialogue portrait (head and shoulders) cropped from the idle painting around the top of the figure.
Writes assets/npcs/<id>_idle.png, <id>_talk.png, <id>_portrait.png.

    python3 tools/cut_npc_art.py
"""
import os
import numpy as np
from PIL import Image

here = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.normpath(os.path.join(here, "../../../art/higgsfield_2026-11/npcs"))
OUT = os.path.normpath(os.path.join(here, "../assets/npcs"))
IDLE_PX = 900
os.makedirs(OUT, exist_ok=True)


def clean(im):
    a = np.array(im.convert("RGBA"))
    a[a[:, :, 3] < 14] = 0
    im = Image.fromarray(a)
    return im.crop(im.getbbox())


for npc in ["ralden", "quartermaster"]:
    paths = {k: os.path.join(SRC, "%s_%s.png" % (npc, k)) for k in ("idle", "talk")}
    if not all(os.path.exists(p) for p in paths.values()):
        print("skip", npc, "(art missing)")
        continue
    idle, talk = clean(Image.open(paths["idle"])), clean(Image.open(paths["talk"]))
    k = IDLE_PX / idle.height
    for name, im in (("idle", idle), ("talk", talk)):
        im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS).save(os.path.join(OUT, "%s_%s.png" % (npc, name)))
    # portrait: square of 36% of the figure height, centred on the head (mean x of the top 12% of opaque pixels)
    a = np.array(idle)[:, :, 3] > 40
    h = idle.height
    ys, xs = np.where(a[: int(h * 0.12)])
    cx = int(xs.mean()) if len(xs) else idle.width // 2
    side = int(h * 0.36)
    left = max(0, min(idle.width - side, cx - side // 2)) if idle.width >= side else 0
    box = (left, 0, left + side, side)
    por = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    por.alpha_composite(idle.crop(box))
    por.resize((384, 384), Image.LANCZOS).save(os.path.join(OUT, "%s_portrait.png" % npc))
    print(npc, "idle", idle.size, "talk", talk.size, "portrait box", box)
