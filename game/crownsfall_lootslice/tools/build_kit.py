"""Build a placeholder environment kit (free, local) from art we already own, so the kit system can be built and
tested before any kit art is bought. Real kit art (Higgsfield, per-prop on transparent background) replaces these
files one for one; the catalog format stays.

Props: cut out with OpenCV GrabCut from a source painting (rect + optional sure-background margin), feathered alpha.
Each prop records its foot point (where it meets the ground, image px), footprint radius (painting px, collision) and
whether it occludes (stands up: hides actors behind it). Set pieces (large ground-level compositions) use a feathered
ellipse mask instead of GrabCut.
Ground: tileable textures made by wrap-blending a painted patch with itself (seamless when repeated).
usage: python build_kit.py <kit_out_dir>"""
import json, os, sys
import numpy as np, cv2
from PIL import Image

OUT = sys.argv[1]
SRC = "art/kit_src/ww_stitch_src.png"      # upscaled Whisperwood master sections (seam test), ~ppm 85.6
SRC_PPM = 85.6
os.makedirs(OUT + "/props", exist_ok=True); os.makedirs(OUT + "/ground", exist_ok=True)
src = np.asarray(Image.open(SRC).convert("RGB"))

def grabcut(box, keep_bottom=0.0, iters=6):
    x0, y0, x1, y1 = box
    img = src[y0:y1, x0:x1].copy()
    m = np.zeros(img.shape[:2], np.uint8)
    pad = 6
    rect = (pad, pad, img.shape[1] - 2 * pad, img.shape[0] - 2 * pad)
    bg = np.zeros((1, 65), np.float64); fg = np.zeros((1, 65), np.float64)
    cv2.grabCut(img, m, rect, bg, fg, iters, cv2.GC_INIT_WITH_RECT)
    a = np.where((m == cv2.GC_FGD) | (m == cv2.GC_PR_FGD), 255, 0).astype(np.uint8)
    # largest component only, holes filled, soft edge
    n, lab, st, _ = cv2.connectedComponentsWithStats(a)
    if n > 1:
        a = np.where(lab == 1 + np.argmax(st[1:, 4]), 255, 0).astype(np.uint8)
    a = cv2.morphologyEx(a, cv2.MORPH_CLOSE, np.ones((9, 9), np.uint8))
    a = cv2.GaussianBlur(a, (0, 0), 1.6)
    return img, a

def ellipse_mask(shape, feather=0.18):
    h, w = shape
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.sqrt(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2)
    return (np.clip((1 - r) / feather, 0, 1) * 255).astype(np.uint8)

PROPS = {
    # name: kind, source box, foot point (source px), footprint radius (painting px), occludes, mode
    "tree_oak":   ("tree",  (5410, 1050, 6335, 1850), (5820, 1800), 70, True,  "grabcut"),
    "stele":      ("poi",   (6420, 360, 7290, 1250),  (6840, 1150), 150, True, "grabcut"),
    "chest":      ("cache", (8140, 610, 8580, 880),   (8350, 850),  40, False, "grabcut"),
    "rock_mossy": ("rock",  (7900, 1140, 8370, 1350), (8110, 1320), 120, True, "grabcut"),
    "shrine_ruins": ("setpiece", (1720, 320, 3340, 1420), (2530, 1300), 0, False, "ellipse"),
    "crownsfall_stairs": ("setpiece", (0, 0, 1300, 820), (650, 780), 0, False, "ellipse"),
}
catalog = {"ppm": SRC_PPM, "props": {}}
for name, (kind, box, foot, rad, occ, mode) in PROPS.items():
    if mode == "grabcut":
        img, a = grabcut(box)
    else:
        img = src[box[1]:box[3], box[0]:box[2]].copy(); a = ellipse_mask(img.shape[:2])
    ys, xs = np.where(a > 40)
    cx0, cx1, cy0, cy1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    rgba = np.dstack([img, a])[cy0:cy1, cx0:cx1]
    Image.fromarray(rgba, "RGBA").save(f"{OUT}/props/{name}.png")
    fx, fy = foot[0] - box[0] - cx0, foot[1] - box[1] - cy0
    catalog["props"][name] = {"kind": kind, "image": f"props/{name}.png", "size": [int(cx1 - cx0), int(cy1 - cy0)],
                              "foot": [int(fx), int(fy)], "footprint_px": rad, "occludes": occ}
    print(name, rgba.shape[1], "x", rgba.shape[0], "foot", fx, fy)

def tileable(box, size=512):
    """Mirror-tiled ground texture: [p | flip(p)] over [flipud ...] - seamless by construction in both directions
    (a wrap-blend leaves the shifted copy's own seam crossing the middle). The shader's rotated second sample and
    noise blend hide the mirror symmetry."""
    p = src[box[1]:box[3], box[0]:box[2]].astype(np.float32)
    p = cv2.resize(p, (size, size), interpolation=cv2.INTER_AREA)
    row = np.concatenate([p, p[:, ::-1]], 1)
    t = np.concatenate([row, row[::-1]], 0)
    n = t.shape[0]
    big = np.tile(t, (3, 3, 1))                                    # wrap-around blur keeps it seamless
    blur = cv2.GaussianBlur(big, (0, 0), n / 14)[n:2 * n, n:2 * n]
    t = t - blur + blur.mean((0, 1))                               # flatten large light/shade blobs
    return np.clip(t, 0, 255).astype(np.uint8)
GROUND = {"grass": (7420, 850, 7980, 1150), "flagstone": (1000, 1260, 1800, 1760), "dirt": (3300, 1180, 3800, 1480)}
catalog["ground"] = {}
for n, b in GROUND.items():
    Image.fromarray(tileable(b)).save(f"{OUT}/ground/{n}.png")
    # tile repeats every 'tile_px' painting px (source patch width, so scale matches the props)
    catalog["ground"][n] = {"image": f"ground/{n}.png", "tile_px": 2 * (b[2] - b[0])}   # mirrored: 2x the patch
# set-piece extras in prop-local image px: solid blockers [x, y, r], portal edge/aura/trigger, waypoint centre
EXTRA = {
    "shrine_ruins": {"blockers": [[195, 675, 45], [360, 540, 45], [592, 405, 40], [795, 420, 40], [930, 435, 40],
                                  [1080, 450, 40], [1275, 600, 40], [1350, 615, 40], [322, 690, 50], [1275, 682, 60]],
                     "waypoint": [750, 698]},
    "crownsfall_stairs": {"aura": [[420, 390], [870, 300], [1050, 570], [630, 705]],
                          "trigger": [[300, 330], [860, 260], [800, 150], [300, 200]],
                          "blockers": [[400, 470, 55], [930, 330, 55], [1080, 520, 55], [600, 700, 55]]},
}
for k, v in EXTRA.items(): catalog["props"][k].update(v)
json.dump(catalog, open(f"{OUT}/catalog.json", "w"), indent=1)
print("kit written:", OUT)
