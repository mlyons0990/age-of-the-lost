"""Build the Whisperwood forest kit from the Higgsfield kit art (K1-K7, 2026-11-22). Free, local, deterministic.

Ground (K1): top-down seamless 2048 tiles, copied as-is (verified seamless). Each gets its real-world repeat in metres.
Props (K2-K7): transparent PNGs painted at the game camera. Single props are cropped to their alpha; sheets are split
into pieces by connected components. For every piece we record:
  foot      image px where it meets the ground (trees: trunk base; bushes/rocks: bottom-centre contact; decals: centre)
  ppm       image px per metre, from the piece's real size, so build_kit_zone can place it at true scale in any zone
  footprint collision radius in image px (0 = walk through: undergrowth, decals)
  occludes  stands up and hides actors behind it
  kind      tree | bush | rock | decal
usage: python tools/build_forest_kit.py <raw_dir> <kit_out_dir>"""
import json, math, os, shutil, sys
import numpy as np, cv2
from PIL import Image

RAW, OUT = sys.argv[1], sys.argv[2]
COS = math.cos(math.radians(31.0))
os.makedirs(OUT + "/props", exist_ok=True); os.makedirs(OUT + "/ground", exist_ok=True)
cat = {"version": 2, "ground": {}, "props": {}}

# ground: repeat size in metres (measured from the stones / tufts against the W1 painting: W1 flagstones ~1.1 m)
for name, src, metres in (("grass", "g1_grass_lush", 7.0), ("grass_old", "k1_grass", 7.0), ("dirt", "k1_dirt", 6.0), ("flagstone", "k1_flag", 13.0)):
    shutil.copy(f"{RAW}/{src}.png", f"{OUT}/ground/{name}.png")
    cat["ground"][name] = {"image": f"ground/{name}.png", "tile_m": metres}

def load(n):
    return np.asarray(Image.open(f"{RAW}/{n}.png").convert("RGBA"))

def clean_alpha(rgba):
    """Kill faint haze (alpha < 8) and un-premultiply edge fringes so soft edges don't carry a dark/pink rim."""
    a = rgba[..., 3].astype(np.float32)
    a[a < 8] = 0
    out = rgba.copy(); out[..., 3] = a.astype(np.uint8)
    return out

def split_contact_shadow(rgba, fy):
    """The image model paints a soft grey contact shadow as semi-transparent pixels round the base. Drawn over our
    ground it reads as grey/purple haze. Cut it out of the prop (alpha 0) and return it as a mask, so the zone builder
    bakes it into the light map instead: a real shadow that darkens whatever ground is underneath (grass stays green)."""
    a = rgba[..., 3].astype(np.float32); rgb = rgba[..., :3].astype(np.float32)
    mx, mn = rgb.max(2), rgb.min(2); sat = (mx - mn) / np.maximum(mx, 1)
    core = cv2.dilate((a > 225).astype(np.uint8), np.ones((7, 7), np.uint8)) > 0
    # ramp in over 8% of the height (a hard start row leaves a straight edge across the soft base)
    ramp = np.clip((np.arange(a.shape[0])[:, None] - (fy - 0.22 * a.shape[0])) / (0.08 * a.shape[0]), 0, 1)
    sh = (a > 0) & (a < 225) & (sat < 0.32) & ~core & (ramp > 0)
    if sh.sum() < 50: return rgba, None
    w = np.where(sh, ramp, 0.0)
    mask = (a * w).astype(np.uint8)
    out = rgba.copy(); out[..., 3] = (a * (1 - w)).astype(np.uint8)
    return out, mask

def clean_decal_edge(rgba):
    """Decals were painted with a pale, washed-out haze in their feathered edge, which leaves milky rings on the
    ground. Drop the faint grey haze and tighten the falloff so the edge fades straight into the ground colour."""
    a = rgba[..., 3].astype(np.float32); rgb = rgba[..., :3].astype(np.float32)
    mx, mn = rgb.max(2), rgb.min(2); sat = (mx - mn) / np.maximum(mx, 1)
    haze = (a < 170) & (sat < 0.30)
    a = np.where(haze, 0, a)
    a = np.clip((a - 60) / 150.0, 0, 1)
    a = cv2.GaussianBlur(a, (0, 0), 1.2) * 255
    out = rgba.copy(); out[..., 3] = a.astype(np.uint8)
    return out

def save(name, rgba, kind, foot, metres, occludes, footprint_frac=0.0, measure="height"):
    ys, xs = np.where(rgba[..., 3] > 8)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    pad = 4
    x0, y0 = max(0, x0 - pad), max(0, y0 - pad); x1, y1 = min(rgba.shape[1], x1 + pad), min(rgba.shape[0], y1 + pad)
    crop = rgba[y0:y1, x0:x1]
    fx, fy = foot[0] - x0, foot[1] - y0
    if measure == "height":      # upright: foot-to-top rows = H * cos(pitch) metres on screen
        ppm = (fy - (ys.min() - y0)) / (metres * COS)
    else:                        # flat: width in metres
        ppm = (xs.max() - xs.min()) / metres
    shadow = None
    if kind != "decal" and not name.startswith(("ga_", "gb_")):   # G2 ground cover has no painted shadow
        crop, shadow = split_contact_shadow(crop, fy)
    else:
        crop = clean_decal_edge(crop)
    Image.fromarray(crop, "RGBA").save(f"{OUT}/props/{name}.png", optimize=True)
    cat["props"][name] = {"kind": kind, "image": f"props/{name}.png", "size": [int(crop.shape[1]), int(crop.shape[0])],
                          "foot": [int(round(fx)), int(round(fy))], "ppm": round(float(ppm), 2),
                          "footprint_px": int(round(footprint_frac)), "occludes": occludes}
    if shadow is not None:
        Image.fromarray(shadow, "L").save(f"{OUT}/props/{name}_shadow.png", optimize=True)
        cat["props"][name]["shadow"] = f"props/{name}_shadow.png"
    print(f"{name:14s} {kind:5s} {crop.shape[1]}x{crop.shape[0]} foot ({fx:.0f},{fy:.0f}) ppm {ppm:.1f}")

def tree(name, src, metres):
    rgba = clean_alpha(load(src)); a = rgba[..., 3] > 128
    ys, xs = np.where(a); bot = ys.max(); top = ys.min(); h = bot - top
    # trunk: the narrowest solid band between 55% and 85% of the height (below the canopy, above the root flare)
    best = None
    for y in range(int(top + 0.55 * h), int(top + 0.85 * h)):
        row = np.where(a[y])[0]
        if len(row) < 10: continue
        # widest contiguous run that contains the row's median (the trunk, not stray leaves)
        runs = np.split(row, np.where(np.diff(row) > 3)[0] + 1)
        run = max(runs, key=len)
        if best is None or len(run) < best[1]: best = (y, len(run), run.mean())
    trunk_w, trunk_cx = best[1], best[2]
    # foot: where the trunk meets the ground = centre of the root flare, ~1.3 trunk widths above the lowest root tip
    fy = bot - 0.55 * trunk_w
    save(name, rgba, "tree", (trunk_cx, fy), metres, True, footprint_frac=trunk_w * 0.62)

tree("oak_a", "k2_oak_a", 13.0)
tree("oak_b", "k2_oak_b", 13.0)
tree("silver", "k3_silver_a", 11.0)          # silver B has a halo baked into its alpha: not used
tree("gnarled_a", "k4_gnarled_a", 12.0)
tree("gnarled_b", "k4_gnarled_b", 12.0)

def sheet(prefix, src, kind, spec, merge=25, min_area=4000):
    """Split a sheet into pieces (reading order); spec[i] = (name, metres, occludes, footprint_frac_of_width, measure)."""
    rgba = clean_alpha(load(src)); a = (rgba[..., 3] > 20).astype(np.uint8)
    m = cv2.dilate(a, np.ones((merge, merge), np.uint8))
    n, lab, st, cen = cv2.connectedComponentsWithStats(m)
    comps = [i for i in range(1, n) if st[i, 4] >= min_area]
    # reading order: row bands then x
    comps.sort(key=lambda i: (round(cen[i][1] / 400), cen[i][0]))
    if len(comps) != len(spec):
        raise SystemExit(f"{src}: found {len(comps)} pieces, expected {len(spec)}")
    for i, (nm, metres, occ, fp, measure) in zip(comps, spec):
        if nm is None: continue
        piece = rgba.copy(); piece[..., 3] = np.where(lab == i, piece[..., 3], 0)
        ys, xs = np.where(piece[..., 3] > 128)
        w = xs.max() - xs.min(); h = ys.max() - ys.min()
        if kind == "decal":
            foot = (xs.mean(), ys.mean())
        else:  # contact: bottom-centre, lifted by the depth of the contact shadow / base
            foot = (xs.min() + w * 0.5, ys.max() - h * (0.10 if kind == "bush" else 0.14))
        save(f"{prefix}{nm}", piece, kind, foot, metres, occ, footprint_frac=w * fp, measure=measure)

UNDER = [("bush_round", 1.4, True, 0, "height"), ("shrub_white", 0.9, False, 0, "height"), ("fern", 1.0, False, 0, "height"),
         ("lavender", 0.8, False, 0, "height"), ("grass_tall", 1.1, False, 0, "height"), ("bush_yellow", 0.9, False, 0, "height")]
sheet("a_", "k5_under_a", "bush", UNDER)
sheet("b_", "k5_under_b", "bush", UNDER)
DEC = [("moss", 1.6, False, 0, "width"), ("leaves", 1.4, False, 0, "width"), ("roots", 1.6, False, 0, "width"),
       ("pebbles", 0.8, False, 0, "width"), ("edgestones", 1.5, False, 0, "width"), ("clover", 1.2, False, 0, "width"),
       ("dirt", 1.6, False, 0, "width"), ("mushrooms", 0.6, False, 0, "width")]
sheet("a_", "k6_decals_a", "decal", DEC, merge=15, min_area=1500)
# decal sheet B: the leaf scatter splits into loose fragments; sheet A covers all 8 decal types
ROCKS = [("rock_flat", 2.6, True, 0.36, "width"), ("rock_tall", 1.8, True, 0.36, "width"),
         ("rock_pair", 2.4, True, 0.36, "width"), ("rock_small", 0.9, True, 0.36, "width")]
sheet("a_", "k7_rocks_a", "rock", ROCKS)
sheet("b_", "k7_rocks_b", "rock", ROCKS)
def mushrooms_only(name, metres):
    """The mushroom decal was painted on a pale, washed-out grass patch that shows as a light blotch on our ground.
    Keep only the mushrooms (warm caps and stems) with a sliver of their base, and stand them up as a small plant."""
    c = cat["props"][name]; rgba = np.asarray(Image.open(f"{OUT}/{c['image']}").convert("RGBA")).copy()
    # hand-measured on the 431x308 decal crop (sheet K6-A): three mushrooms, cap ellipse + tapered stem each
    keep = np.zeros(rgba.shape[:2], np.uint8)
    for (cx, cy, rx, ry), stem in (((197, 88, 70, 37), [(180, 112), (214, 112), (228, 180), (184, 182)]),
                                    ((269, 133, 37, 21), [(258, 145), (278, 145), (281, 172), (255, 173)]),
                                    ((149, 188, 37, 24), [(138, 202), (160, 202), (165, 236), (134, 236)])):
        cv2.ellipse(keep, (cx, cy), (rx - 4, ry - 3), 0, 0, 360, 1, -1)
        cv2.fillPoly(keep, [np.array(stem, np.int32)], 1)
    a = cv2.GaussianBlur(keep.astype(np.float32), (0, 0), 1.5) * rgba[..., 3]
    rgba[..., 3] = a.astype(np.uint8)
    ys, xs = np.where(rgba[..., 3] > 128)
    foot = (xs.mean(), ys.max() - 6)
    del cat["props"][name]
    save(name, rgba, "bush", foot, metres, False)
mushrooms_only("a_mushrooms", 0.45)
# G2 grass overlay (2026-11-26): low ground cover layered over the base grass, walk-through, never occludes
GROUND_COVER = [("tallgrass", 0), ("longgrass", 0), ("whiteflowers", 0), ("lavenderpatch", 0), ("moss", 0), ("clover", 0),
                ("edge", 0), ("meadow", 0)]
sheet("ga_", "g2_overlay_a", "bush", [(n, 1.1, False, 0, "width") for n, _ in GROUND_COVER])
sheet("gb_", "g2_overlay_b", "bush", [(n, 2.1, False, 0, "width") for n, _ in GROUND_COVER])
json.dump(cat, open(f"{OUT}/catalog.json", "w"), indent=1)
print("kit:", OUT, len(cat["props"]), "props")
