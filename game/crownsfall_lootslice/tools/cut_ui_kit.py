#!/usr/bin/env python3
"""Cut the painted AOTL UI kit (art/higgsfield_2026-11/ui_kit, GPT Image 2.6 on transparent backgrounds, 2026-11-27)
into game textures in assets/ui/kit/.

Sheets are split by connected alpha components (sorted row by row), whole panels are trimmed to their alpha bounds
and scaled to the size they are drawn at, so 9-slice margins stay crisp. The crown on the window frames is lifted out
into its own sprite and the top edge under it is patched with the plain edge next to it, so the frame can 9-slice.

    python3 tools/cut_ui_kit.py [--src ../../art/higgsfield_2026-11/ui_kit] [--out assets/ui/kit]
"""
import argparse, json, os
import cv2
import numpy as np
from PIL import Image

ap = argparse.ArgumentParser()
here = os.path.dirname(os.path.abspath(__file__))
ap.add_argument("--src", default=os.path.normpath(os.path.join(here, "../../../art/higgsfield_2026-11/ui_kit")))
ap.add_argument("--out", default=os.path.normpath(os.path.join(here, "../assets/ui/kit")))
ap.add_argument("--debug", default="")
a = ap.parse_args()
os.makedirs(a.out, exist_ok=True)
meta = {}


def load(name):
    return Image.open(os.path.join(a.src, name + ".png")).convert("RGBA")


def trim(im, thr=24):
    al = np.array(im)[:, :, 3]
    ys, xs = np.where(al > thr)
    return im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def clean_alpha(im, lo=10):
    """Drop the faint haze the model leaves around shapes (alpha < lo) so 9-slice edges stay clean."""
    arr = np.array(im)
    arr[arr[:, :, 3] < lo] = 0
    return Image.fromarray(arr)


def components(im, min_area=900, thr=40, close=9):
    al = (np.array(im)[:, :, 3] > thr).astype(np.uint8)
    al = cv2.morphologyEx(al, cv2.MORPH_CLOSE, np.ones((close, close), np.uint8))
    n, lab, stats, cent = cv2.connectedComponentsWithStats(al, 8)
    boxes = [tuple(stats[i][:4]) for i in range(1, n) if stats[i][4] >= min_area]
    # row-major order: group by vertical centre (rows are well separated in every sheet)
    boxes.sort(key=lambda b: (b[1] + b[3] / 2))
    rows, cur = [], []
    for b in boxes:
        if cur and (b[1] + b[3] / 2) - (cur[-1][1] + cur[-1][3] / 2) > min(b[3], cur[-1][3]) * 0.5:
            rows.append(cur); cur = []
        cur.append(b)
    if cur: rows.append(cur)
    out = []
    for r in rows: out += sorted(r, key=lambda b: b[0])
    return out


def save(im, name, scale=None, size=None, **info):
    if size is not None: im = im.resize(size, Image.LANCZOS)
    elif scale is not None: im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
    im.save(os.path.join(a.out, name + ".png"))
    meta[name] = dict(size=[im.width, im.height], **info)
    return im


def remove_crest(im, x0f, x1f, band_f):
    """A crownless copy for 9-slicing: the crest (centred on the top edge) is replaced by the plain edge to its left
    and right, copied in, and everything above the rim is cleared."""
    arr = np.array(im)
    h, w = arr.shape[:2]
    al = arr[:, :, 3] > 40
    top = int(np.where(al.sum(1) > w * 0.8)[0][0])
    x0, x1 = int(w * x0f), int(w * x1f)
    band = int(h * band_f)
    half = (x1 - x0) // 2
    left = arr[:band, x0 - half:x0].copy()
    right = arr[:band, x1:x1 + (x1 - x0 - half)].copy()
    arr[:band, x0:x0 + half] = left
    arr[:band, x0 + half:x1] = right
    arr[:top, :, 3] = 0
    return Image.fromarray(arr)


# ---- window frames: whole (crowned) at the sizes they are drawn, plus a crownless 9-slice frame ----
tall = clean_alpha(trim(load("window_tall")))
wide = clean_alpha(trim(load("window_wide")))
save(tall, "window_tall", scale=720 / tall.width)
save(tall, "window_tall_small", scale=500 / tall.width)
save(wide, "window_wide", scale=1440 / wide.width)
plain = remove_crest(wide, 0.375, 0.635, 0.17)
p9 = save(trim(plain), "frame9", scale=900 / plain.width)
meta["frame9"]["margin"] = round(p9.width * 0.052)
# where the inner slate starts (fraction of the frame), for laying out content inside the whole frames
for nm, im in [("window_tall", tall), ("window_wide", wide)]:
    arr = np.array(im)
    lum = arr[:, :, :3].mean(2)
    cy = arr.shape[0] // 2
    row = lum[cy]
    # the slate is dark (< 70) and wide: first dark run from the left edge after the bronze
    xs = np.where((row < 70) & (arr[cy, :, 3] > 200))[0]
    meta[nm]["inner_x"] = round(float(xs[0]) / arr.shape[1], 4)
    meta[nm]["inner_right"] = round(float(xs[-1]) / arr.shape[1], 4)
    cx = arr.shape[1] // 2
    col = lum[:, cx]
    ys = np.where((col < 70) & (arr[:, cx, 3] > 200))[0]
    meta[nm]["inner_top"] = round(float(ys[0]) / arr.shape[0], 4)
    meta[nm]["inner_bottom"] = round(float(ys[-1]) / arr.shape[0], 4)
meta["window_tall_small"].update({k: meta["window_tall"][k] for k in ("inner_x", "inner_right", "inner_top", "inner_bottom")})

im = clean_alpha(trim(load("tooltip")))
t = save(im, "tooltip", scale=420 / im.width)
meta["tooltip"]["margin"] = 34

im = clean_alpha(trim(load("title_plaque")))
save(im, "title_plaque", scale=96 / im.height)

im = clean_alpha(trim(load("class_card")))
save(im, "class_card", scale=380 / im.width)

im = clean_alpha(trim(load("medallion")))
save(im, "medallion", scale=256 / im.width)

# ---- buttons: 3 states ----
src = clean_alpha(load("buttons"))
bx = components(src, min_area=20000)
assert len(bx) == 3, ("buttons", bx)
for (x, y, w, h), st in zip(bx, ["normal", "hover", "pressed"]):
    b = save(src.crop((x, y, x + w, y + h)), "button_" + st, scale=64 / h)
    meta["button_" + st]["margin_x"] = round(b.height * 0.75)

# ---- equipment slots: 3x3 ----
src = clean_alpha(load("equip_slots"))
bx = components(src, min_area=40000)
assert len(bx) == 9, ("equip_slots", bx)
for (x, y, w, h), nm in zip(bx, ["helm", "amulet", "gloves", "weapon", "armor", "offhand", "ring", "belt", "boots"]):
    save(src.crop((x, y, x + w, y + h)), "slot_" + nm, size=(128, 128))

# ---- small parts ----
src = clean_alpha(load("parts"))
bx = components(src, min_area=1500)
names = ["cell", "close", "plus", "check_off", "check_on", "slider_track", "slider_knob", "tab", "tab_on", "divider"]
assert len(bx) == len(names), ("parts", len(bx), bx)
sizes = {"cell": 96, "close": 64, "plus": 64, "check_off": 48, "check_on": 48, "slider_knob": 48, "tab": 72, "tab_on": 72}
for (x, y, w, h), nm in zip(bx, names):
    piece = src.crop((x, y, x + w, y + h))
    if nm in ("slider_track", "divider"): save(piece, nm, scale=(24 if nm == "slider_track" else 28) / h)
    elif nm in ("tab", "tab_on"): save(piece, nm, scale=sizes[nm] / h)
    else: save(piece, nm, size=(sizes[nm], round(sizes[nm] * h / w)) if nm not in ("cell",) else (96, 96))

# ---- skill tree parts ----
src = clean_alpha(load("skill_parts"))
bx = components(src, min_area=1200)
names = ["node_locked", "node_open", "node_master", "pip_off", "pip_on", "connector", "choice", "choice_on"]
assert len(bx) == len(names), ("skill_parts", len(bx), bx)
for (x, y, w, h), nm in zip(bx, names):
    piece = src.crop((x, y, x + w, y + h))
    if nm.startswith("node"): save(piece, nm, scale=128 / w)
    elif nm.startswith("pip"): save(piece, nm, size=(32, 32))
    elif nm == "connector": save(piece, nm, scale=96 / h)
    else: save(piece, nm, scale=72 / h)

# ---- opaque backdrops ----
im = load("skill_bg").convert("RGB"); save(im, "skill_bg", size=(1344, 760))
im = load("char_bg").convert("RGB"); save(im, "char_bg", size=(584, 782))

json.dump(meta, open(os.path.join(a.out, "kit.json"), "w"), indent=1)
print(json.dumps(meta, indent=1))
