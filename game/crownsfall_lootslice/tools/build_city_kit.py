"""Build the Crownsfall city kit (free, local, deterministic) from the A1 / A1-T Higgsfield art (2026-11-28).

The kit is the forest kit (assets/kit/forest_hf: grass, bushes, rocks, decals) plus:
  ground  A1-T seamless top-down tiles. 'flagstone' (the path channel) = ivory cobbles, 'dirt' = garden gravel; the
          rest are base grounds a zone can pick (plaza, terrace, lawn, cobble_grass, cobble_worn, market, medallion, grid).
  props   A1 pieces cut by tools/cut_crownsfall_kit.py (assets/kit/crownsfall/*.png), each given its real height in
          metres so build_kit_zone places it at true scale, a collision footprint, and its painted contact shadow split
          off into a shadow mask (as in build_forest_kit).
usage: python tools/build_city_kit.py"""
import json, math, os, shutil
import numpy as np, cv2
from PIL import Image

SRC_FOREST = "assets/kit/forest_hf"
SRC_PROPS = "assets/kit/crownsfall"
SRC_GROUND = "../../art/higgsfield_2026-11/crownsfall_terrain/raw"
OUT = "assets/kit/city"
COS = math.cos(math.radians(31.0))

if os.path.isdir(OUT): shutil.rmtree(OUT)
shutil.copytree(SRC_FOREST, OUT, ignore=shutil.ignore_patterns("*.import"))
cat = json.load(open(f"{OUT}/catalog.json"))

# ground: name -> (A1-T tile, repeat in metres). Cobbles ~0.25 m, flagstones ~0.8 m, terrace slabs ~1.2 m.
GROUND = {"flagstone": ("cobble_ivory", 6.0), "dirt": ("gravel_path", 5.0), "plaza": ("flagstone_plaza", 9.0),
          "terrace": ("stone_terrace", 11.0), "lawn": ("grass_garden", 7.0), "cobble_grass": ("cobble_grass", 6.0),
          "cobble_worn": ("cobble_worn", 6.0), "market": ("packed_earth_market", 6.0), "grid": ("paving_grid", 10.0)}
# NOT ground: plaza_medallion has flower beds painted top-down; anything with height must be a 31-degree prop
# (docs/AOTL_ACT1_ART_QUOTE.md, standing art rule). Left out of the kit on purpose.
for k, (src, m) in GROUND.items():
    im = Image.open(f"{SRC_GROUND}/{src}.png").convert("RGB").resize((2048, 2048), Image.LANCZOS)
    if k == "lawn":          # the painted lawn is a flat, saturated green: calm it toward the forest grass
        from PIL import ImageEnhance
        im = ImageEnhance.Brightness(ImageEnhance.Color(im).enhance(0.72)).enhance(0.86)
    im.save(f"{OUT}/ground/city_{k}.png", optimize=True)
    cat["ground"][k] = {"image": f"ground/city_{k}.png", "tile_m": m}

def split_contact_shadow(rgba, fy):
    """Same as build_forest_kit: the faint grey contact shadow round the base becomes a light-map shadow mask."""
    a = rgba[..., 3].astype(np.float32); rgb = rgba[..., :3].astype(np.float32)
    mx, mn = rgb.max(2), rgb.min(2); sat = (mx - mn) / np.maximum(mx, 1)
    core = cv2.dilate((a > 225).astype(np.uint8), np.ones((7, 7), np.uint8)) > 0
    ramp = np.clip((np.arange(a.shape[0])[:, None] - (fy - 0.22 * a.shape[0])) / (0.08 * a.shape[0]), 0, 1)
    sh = (a > 0) & (a < 225) & (sat < 0.32) & ~core & (ramp > 0)
    if sh.sum() < 50: return rgba, None
    w = np.where(sh, ramp, 0.0)
    out = rgba.copy(); out[..., 3] = (a * (1 - w)).astype(np.uint8)
    return out, (a * w).astype(np.uint8)

# name: (kind, height m, occludes, footprint as a fraction of the image width)
#   rock = solid structure (lit at its foot, collides), bush = walk-through planting, tree = canopy
SPEC = {
 # buildings (A1)
 "bld_citizen_home": ("rock", 11.0, True, 0.34), "bld_merchant_guild": ("rock", 14.0, True, 0.36),
 "bld_archive_hall": ("rock", 13.0, True, 0.36), "bld_temple_sanctum": ("rock", 22.0, True, 0.34),
 "bld_guard_barracks": ("rock", 10.0, True, 0.36), "bld_royal_manor": ("rock", 16.0, True, 0.36),
 # landmarks
 "lm_fountain_a": ("rock", 4.2, True, 0.36), "lm_fountain_b": ("rock", 4.5, True, 0.38), "lm_fountain_c": ("rock", 4.0, True, 0.3),
 "lm_statue_a": ("rock", 6.5, True, 0.22), "lm_statue_b": ("rock", 6.0, True, 0.3),
 "lm_arch_a": ("rock", 7.5, True, 0.0), "lm_arch_b": ("rock", 7.5, True, 0.0),        # walk under (pillars added below)
 "lm_gazebo_a": ("rock", 6.0, True, 0.3), "lm_gazebo_b": ("rock", 6.0, True, 0.3),
 # street furniture
 "lamppost_double": ("rock", 4.2, True, 0.06), "lamppost_single": ("rock", 3.8, True, 0.06),
 "banner_bracket": ("rock", 3.4, True, 0.1), "banner_pole": ("rock", 3.6, True, 0.08), "bench": ("rock", 1.1, False, 0.25),
 "notice_board": ("rock", 2.8, True, 0.2), "wall_banner_wisteria": ("rock", 3.4, True, 0.1), "banner_standard": ("rock", 3.2, True, 0.08),
 # market
 "market_stall_fruit": ("rock", 3.2, True, 0.3), "market_stall_cloth": ("rock", 3.2, True, 0.3), "covered_wagon": ("rock", 2.8, True, 0.3),
 "crate_stack": ("rock", 1.8, True, 0.3), "barrels_sacks": ("rock", 1.5, True, 0.3), "crates_wisteria": ("rock", 1.9, True, 0.3),
 "book_crates": ("rock", 1.3, True, 0.3), "apple_basket": ("bush", 0.8, False, 0.0), "flower_barrel": ("rock", 1.4, False, 0.2),
 # stonework
 "balustrade_straight": ("rock", 1.2, True, 0.18), "balustrade_corner": ("rock", 1.5, True, 0.2), "pillar_post": ("rock", 2.0, True, 0.16),
 "stone_urn": ("rock", 1.7, True, 0.18), "flower_planter": ("rock", 1.1, False, 0.25), "flower_pedestal": ("rock", 1.8, True, 0.18),
 # foliage
 "tree_green": ("tree", 6.5, True, 0.0), "tree_blossom": ("tree", 6.0, True, 0.0), "tree_amber": ("tree", 6.0, True, 0.0),
 "sapling": ("tree", 3.2, True, 0.0), "topiary_urn": ("rock", 1.9, True, 0.18),
 "hydrangea_bush": ("bush", 1.3, False, 0.0), "hydrangea_blue": ("bush", 1.0, False, 0.0), "flower_white": ("bush", 0.9, False, 0.0),
 "lavender": ("bush", 0.8, False, 0.0), "flower_basket": ("bush", 1.0, False, 0.0), "ivy_hang": ("bush", 1.4, False, 0.0),
 "wisteria_hang": ("rock", 2.4, True, 0.12),
 # flower beds at the 31-degree camera (A1-F, 11-28): knee-high kerbs; solid, low enough not to hide the hero
 "bed_straight_long": ("rock", 1.1, False, 0.3), "bed_corner": ("rock", 1.1, False, 0.3), "bed_end": ("rock", 1.3, False, 0.3),
 "bed_straight_short": ("rock", 1.1, False, 0.3), "bed_tee": ("rock", 1.1, False, 0.3), "bed_square": ("rock", 1.1, False, 0.3),
 "bed_round_large": ("rock", 1.2, False, 0.34), "bed_oval": ("rock", 1.1, False, 0.34), "bed_round_small": ("rock", 1.0, False, 0.32),
 "bed_halfmoon": ("rock", 1.6, False, 0.3), "bed_tree_ring": ("rock", 3.0, True, 0.3), "bed_crescent": ("rock", 1.1, False, 0.28),
 "hedge_straight": ("rock", 1.0, False, 0.3), "hedge_corner": ("rock", 1.3, False, 0.3), "hedge_end": ("rock", 1.4, False, 0.3),
 "hedge_topiary_square": ("rock", 1.8, True, 0.3), "wisteria_trellis": ("rock", 2.6, True, 0.3), "wisteria_arch_bed": ("rock", 2.8, True, 0.3),
 "drift_lavender": ("bush", 0.7, False, 0.0), "drift_white": ("bush", 0.6, False, 0.0), "drift_mixed": ("bush", 0.7, False, 0.0),
 "drift_wildflower": ("bush", 0.6, False, 0.0), "drift_ivy": ("bush", 0.4, False, 0.0), "drift_step_hydrangea": ("rock", 1.4, False, 0.25),
 # magic dressing (C3, 11-28)
 "lantern_float_large": ("bush", 2.6, False, 0.0), "lantern_float_mid": ("bush", 2.2, False, 0.0), "lantern_float_small": ("bush", 1.8, False, 0.0),
 "crystal_lamp": ("rock", 3.6, True, 0.1), "arcane_brazier": ("rock", 1.8, True, 0.25), "light_motes": ("bush", 1.8, False, 0.0),
 "rune_circle": ("decal", 0.0, False, 0.0), "crystal_float": ("rock", 2.6, True, 0.25), "orb_levitating": ("rock", 2.4, True, 0.25),
 "wisteria_wisp": ("rock", 2.8, True, 0.12), "sigil_stone": ("rock", 2.0, True, 0.2), "magic_spring": ("rock", 1.6, True, 0.3),
}
for name, (kind, metres, occ, fp) in SPEC.items():
    rgba = np.asarray(Image.open(f"{SRC_PROPS}/{name}.png").convert("RGBA")).copy()
    rgba[..., 3][rgba[..., 3] < 8] = 0
    a = rgba[..., 3] > 128; ys, xs = np.where(a)
    fy = int(ys.max()); h, w = rgba.shape[:2]
    if kind == "tree":       # trunk base: centre of the solid pixels in the bottom 6% (above the flower ring's tips)
        band = a[int(fy - 0.12 * h):fy + 1]; bx = np.where(band.any(0))[0]; fx = float(bx.mean())
    else:
        fx = float(xs.mean()); fy = int(fy - 0.02 * h)          # contact line sits a little above the lowest pixel
    ppm = (fy - ys.min()) / (metres * COS) if kind != "decal" else (xs.max() - xs.min()) / 4.0
    if kind == "decal": fx, fy = w / 2.0, h / 2.0
    crop, shadow = split_contact_shadow(rgba, fy) if kind != "decal" else (rgba, None)
    pname = "c_" + name
    Image.fromarray(crop, "RGBA").save(f"{OUT}/props/{pname}.png", optimize=True)
    c = {"kind": kind, "image": f"props/{pname}.png", "size": [w, h], "foot": [int(round(fx)), fy], "ppm": round(float(ppm), 2),
         "footprint_px": int(round(w * fp)), "occludes": occ}
    if kind == "tree": c["footprint_px"] = int(round(w * 0.05))
    if name.startswith("lm_arch"):   # two pillar footprints, open in the middle
        c["blockers"] = [[int(w * 0.16), fy, int(w * 0.1)], [int(w * 0.84), fy, int(w * 0.1)]]
    if shadow is not None:
        Image.fromarray(shadow, "L").save(f"{OUT}/props/{pname}_shadow.png", optimize=True)
        c["shadow"] = f"props/{pname}_shadow.png"
    cat["props"][pname] = c
    print(f"{pname:24s} {kind:5s} {w}x{h} foot ({fx:.0f},{fy}) ppm {ppm:.1f} fp {c['footprint_px']}")
cat["note"] = "forest_hf + Crownsfall city (A1 props, A1-T ground), tools/build_city_kit.py"
json.dump(cat, open(f"{OUT}/catalog.json", "w"), indent=1)
print("city kit:", len(cat["props"]), "props,", len(cat["ground"]), "grounds")
