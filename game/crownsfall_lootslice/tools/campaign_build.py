#!/usr/bin/env python3
"""Build the campaign framework from the bible register + tools/campaign_design.py.

    python3 tools/campaign_build.py [--acts 1] [--zones key,key] [--no-maps]

For every designed zone: an organic kit-zone layout (wild / town / dungeon / between / arena) with exits placed
toward its neighbours, built by tools/build_kit_zone.py; monster families, packs, guardians and bosses
(data/monster_types.json, data/encounters.json); the campaign quest chain Q_A0x_yy with the bible's names and
text (data/quests.json); NPCs (data/npcs.json); lorecast sites and skills (data/lorecasts.json, data/skills/lore);
the per-act world map (assets/zones/world.json); and data/campaign_built.json (positions the tests use).
Greybox on the forest kit, each zone with its own biome grade; curated art comes later (owner 11-28).
"""
import argparse, copy, json, math, os, random, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.dirname(here)
sys.path.insert(0, here)
import campaign_design as CD
os.chdir(root)

ap = argparse.ArgumentParser()
ap.add_argument("--acts", default="1")
ap.add_argument("--zones", default="")
ap.add_argument("--no-maps", action="store_true")
args = ap.parse_args()
ACTS = [int(a) for a in args.acts.split(",")]
ONLY = set(z for z in args.zones.split(",") if z)

REG = {z["id"]: z for z in json.load(open("data/campaign_zones.json"))}
def RG(zid):
    d = DESIGN.get(zid, {})
    if d.get("reg"): return dict(d["reg"], id=zid)
    return REG[zid]
DESIGN = {}; EDGES = []; POS = {}
for act in range(1, 8):
    d = getattr(CD, f"ACT{act}", None)
    if d is None: continue
    DESIGN.update(d); EDGES += getattr(CD, f"ACT{act}_EDGES", []); POS.update(getattr(CD, f"ACT{act}_POS", {}))
LEVELS = {1: (1, 10), 2: (11, 20), 3: (21, 30), 4: (31, 40), 5: (41, 50), 6: (51, 60), 7: (61, 70)}
ACT_NAMES = {1: "The Crown That Remembers", 2: "Scars of the World", 3: "The Age of Gold", 4: "The Day the World Ended",
             5: "The Unwritten Kingdoms", 6: "War Against the Hour", 7: "Age of the Lost"}

# ---------------------------------------------------------------- biomes (forest kit + grade until each has its own art)
TREES_ALL = ["oak_a", "oak_b", "gnarled_a", "gnarled_b", "silver"]
ROCKS_BIG = ["a_rock_flat", "b_rock_flat", "a_rock_pair", "b_rock_pair", "a_rock_tall", "b_rock_tall"]
BUSH = ["a_bush_round", "b_bush_round", "a_bush_yellow", "b_bush_yellow"]
FLOWERS = ["a_lavender", "b_lavender", "a_shrub_white", "b_shrub_white"]
FERNS = ["a_fern", "b_fern", "a_grass_tall", "b_grass_tall"]
def G(mul, desat, lift, mist, water): return {"mul": mul, "desat": desat, "lift": lift, "mist": mist, "water": water}
BIOMES = {
 # name: road, clear (clearing layer), ground, trees [(tree, w)], spacing, cut, rocks, clumps {kind: w}, pools (n, rmin, rmax), grade, dress props, rim props, mist
 "farmland":   dict(road="flagstone", clear="dirt", ground="grass", trees=[("oak_b", 3), ("oak_a", 2), ("silver", 1)], spacing=1300, cut=0.84, rocks=24,
                    clumps={"mixed": 3, "lavender": 2, "white": 3, "bushes": 2, "ferns": 1}, pools=(2, 260, 420), meadows=5,
                    grade=G([1.06, 1.02, 0.86], 0.08, [0.04, 0.03, 0.0, 1.0], [0.9, 0.86, 0.78], [0.3, 0.45, 0.5]), dress=ROCKS_BIG + BUSH, rim=BUSH + ["a_grass_tall"], mist=False),
 "orchard":    dict(road="dirt", clear="dirt", ground="grass_old", trees=[("oak_b", 4), ("oak_a", 3), ("gnarled_a", 1)], spacing=760, cut=0.62, rocks=20,
                    clumps={"bushes": 3, "white": 2, "mixed": 3, "lavender": 1}, pools=(1, 400, 600), meadows=3,
                    grade=G([1.12, 0.96, 0.78], 0.1, [0.06, 0.02, 0.0, 1.0], [0.95, 0.82, 0.7], [0.3, 0.42, 0.45]), dress=ROCKS_BIG + BUSH, rim=BUSH + FERNS, mist=False),
 "forest":     dict(road="dirt", clear="dirt", ground="grass_old", trees=[("oak_a", 3), ("oak_b", 3), ("gnarled_a", 2), ("gnarled_b", 2), ("silver", 2)], spacing=520, cut=0.55, rocks=30,
                    clumps={"ferns": 4, "lavender": 2, "white": 2, "bushes": 3, "mixed": 3}, pools=(2, 260, 380), meadows=2,
                    grade=G([1, 1, 1], 0.0, [0, 0, 0, 0], [0.74, 0.64, 0.88], [0.32, 0.48, 0.55]), dress=ROCKS_BIG, rim=FERNS + BUSH, mist=True),
 "hamlet":     dict(road="dirt", clear="dirt", ground="grass_old", trees=[("gnarled_a", 2), ("oak_b", 2), ("silver", 1)], spacing=900, cut=0.7, rocks=18,
                    clumps={"ferns": 3, "mixed": 3, "white": 2, "bushes": 2}, pools=(1, 700, 900), meadows=3,
                    grade=G([0.9, 1.02, 0.9], 0.18, [0.03, 0.06, 0.04, 1.0], [0.7, 0.82, 0.74], [0.24, 0.4, 0.4]), dress=ROCKS_BIG + ["a_mushrooms"], rim=FERNS + ["a_moss"], mist=True),
 "echo_grove": dict(road="dirt", clear="dirt", ground="grass_old", trees=[("silver", 5), ("oak_a", 2), ("oak_b", 1)], spacing=620, cut=0.55, rocks=16,
                    clumps={"white": 3, "ferns": 3, "lavender": 2, "mixed": 2}, pools=(1, 300, 400), meadows=1,
                    grade=G([1.16, 1.0, 0.72], 0.2, [0.08, 0.05, 0.0, 1.0], [1.0, 0.86, 0.6], [0.5, 0.45, 0.3]), dress=["a_shrub_white", "b_shrub_white", "a_rock_small"], rim=["a_shrub_white", "b_shrub_white"] + FERNS, mist=True),
 "ash_road":   dict(road="flagstone", clear="dirt", ground="grass_old", trees=[("gnarled_b", 3), ("gnarled_a", 2)], spacing=1250, cut=0.82, rocks=55,
                    clumps={"mixed": 2, "ferns": 1, "bushes": 1}, pools=(0, 0, 0), meadows=6,
                    grade=G([0.72, 0.66, 0.62], 0.62, [0.05, 0.03, 0.02, 1.0], [0.55, 0.5, 0.48], [0.2, 0.22, 0.24]), dress=ROCKS_BIG + ["a_rock_small", "b_rock_small"], rim=["a_rock_small", "b_rock_small", "a_grass_tall"], mist=False),
 "mill_river": dict(road="flagstone", clear="flagstone", ground="grass", trees=[("silver", 2), ("oak_b", 2), ("gnarled_a", 1)], spacing=1050, cut=0.76, rocks=22,
                    clumps={"ferns": 3, "mixed": 2, "white": 2, "bushes": 2}, pools=(3, 420, 700), meadows=2, canals=2,
                    grade=G([0.96, 1.0, 1.02], 0.12, [0.02, 0.04, 0.05, 1.0], [0.78, 0.84, 0.9], [0.24, 0.42, 0.52]), dress=ROCKS_BIG + BUSH, rim=FERNS, mist=True),
 "city":       dict(road="flagstone", clear="flagstone", ground="flagstone", trees=[("silver", 1), ("oak_b", 1)], spacing=1700, cut=0.88, rocks=10,
                    clumps={"white": 3, "lavender": 3, "bushes": 3}, pools=(2, 160, 240), meadows=0, beds=14, plaza=1100,
                    grade=G([1.08, 1.04, 0.96], 0.1, [0.06, 0.05, 0.04, 1.0], [0.9, 0.88, 0.84], [0.3, 0.5, 0.62]), dress=BUSH + FLOWERS, rim=FLOWERS + BUSH, mist=False, paved=True),
 "citadel":    dict(road="flagstone", clear="flagstone", ground="flagstone", trees=[("silver", 1)], spacing=1900, cut=0.9, rocks=12,
                    clumps={"white": 2, "lavender": 2, "bushes": 2}, pools=(1, 160, 220), meadows=0, beds=10, plaza=1200,
                    grade=G([1.02, 0.9, 0.88], 0.16, [0.08, 0.04, 0.06, 1.0], [0.86, 0.72, 0.86], [0.3, 0.4, 0.55]), dress=BUSH + FLOWERS, rim=FLOWERS, mist=False, paved=True),
 "merchant_crypt": dict(dungeon=True, ground="dirt", grade=G([0.7, 0.62, 0.52], 0.4, [0.04, 0.03, 0.01, 1.0], [0.6, 0.5, 0.4], [0.2, 0.2, 0.2]), wall=ROCKS_BIG),
 "cistern":    dict(dungeon=True, ground="dirt", water_rooms=True, grade=G([0.56, 0.66, 0.72], 0.4, [0.02, 0.04, 0.06, 1.0], [0.5, 0.6, 0.66], [0.12, 0.24, 0.3]), wall=ROCKS_BIG),
 "crypt":      dict(dungeon=True, ground="dirt", grade=G([0.6, 0.58, 0.7], 0.45, [0.03, 0.02, 0.06, 1.0], [0.56, 0.5, 0.7], [0.18, 0.16, 0.24]), wall=ROCKS_BIG),
 "cathedral":  dict(dungeon=True, ground="grass_old", grade=G([0.7, 0.6, 0.86], 0.4, [0.06, 0.02, 0.1, 1.0], [0.6, 0.45, 0.85], [0.4, 0.2, 0.6]), wall=["a_rock_tall", "b_rock_tall"]),
 "anchor":     dict(between=True, ground="dirt", grade=G([0.95, 0.82, 0.66], 0.3, [0.06, 0.04, 0.02, 1.0], [0.75, 0.6, 0.9], [0.22, 0.1, 0.34])),
}
def mk(template, grade, **over):
    b = copy.deepcopy(BIOMES[template]); b["grade"] = grade; b.update(over); return b
GOLD = lambda m=1.0: G([1.12 * m, 1.06 * m, 0.9 * m], 0.05, [0.08, 0.07, 0.04, 1.0], [1.0, 0.94, 0.8], [0.32, 0.55, 0.7])
BIOMES.update({
 # Act II: frontier (Atlas: mists in the frontier; Veyr silver/indigo)
 "refuge":       mk("hamlet", G([0.96, 0.92, 0.86], 0.25, [0.05, 0.04, 0.03, 1.0], [0.8, 0.78, 0.74], [0.25, 0.35, 0.4]), pools=(0, 0, 0), meadows=6),
 "bog":          mk("hamlet", G([0.82, 0.92, 0.82], 0.32, [0.03, 0.06, 0.04, 1.0], [0.62, 0.74, 0.66], [0.18, 0.3, 0.27]), trees=[("gnarled_a", 3), ("gnarled_b", 3), ("silver", 1)], pools=(7, 380, 760), spacing=820),
 "echo_marsh":   mk("hamlet", G([0.86, 0.98, 1.06], 0.35, [0.05, 0.08, 0.1, 1.0], [0.8, 0.92, 1.0], [0.4, 0.62, 0.7]), trees=[("silver", 4)], pools=(8, 360, 700), spacing=900),
 "conifer":      mk("forest", G([0.72, 0.8, 0.74], 0.3, [0.0, 0.02, 0.02, 1.0], [0.5, 0.58, 0.56], [0.2, 0.3, 0.32]), trees=[("gnarled_b", 4), ("gnarled_a", 3)], spacing=560, cut=0.55),
 "mountain":     mk("ash_road", G([0.92, 0.94, 0.98], 0.4, [0.06, 0.06, 0.08, 1.0], [0.82, 0.84, 0.9], [0.3, 0.4, 0.5]), rocks=95, trees=[("gnarled_a", 1), ("silver", 1)], meadows=3),
 "veyr":         mk("city", G([0.88, 0.9, 1.08], 0.3, [0.04, 0.05, 0.1, 1.0], [0.72, 0.76, 0.95], [0.28, 0.36, 0.6])),
 "snow":         mk("ash_road", G([0.96, 0.98, 1.04], 0.55, [0.26, 0.28, 0.32, 1.0], [0.92, 0.94, 1.0], [0.5, 0.6, 0.7]), rocks=80, trees=[("gnarled_b", 2), ("silver", 1)], meadows=5),
 "quarry":       mk("ash_road", G([0.92, 0.82, 1.02], 0.35, [0.06, 0.03, 0.1, 1.0], [0.74, 0.6, 0.9], [0.45, 0.28, 0.65]), rocks=120, ground="dirt", meadows=7),
 "bastion":      mk("crypt", G([0.74, 0.8, 0.9], 0.4, [0.03, 0.04, 0.07, 1.0], [0.6, 0.68, 0.82], [0.2, 0.26, 0.36])),
 "coast":        mk("hamlet", G([0.94, 0.98, 1.02], 0.3, [0.04, 0.06, 0.08, 1.0], [0.8, 0.84, 0.9], [0.16, 0.32, 0.42]), sea="south", pools=(2, 260, 420), trees=[("silver", 2), ("gnarled_b", 1)], spacing=1100),
 "harbor_echo":  mk("city", GOLD(), sea="south"),
 "causeway":     mk("anchor", G([0.86, 0.88, 0.92], 0.4, [0.04, 0.05, 0.07, 1.0], [0.7, 0.74, 0.82], [0.24, 0.32, 0.4])),
 "between_rain": mk("anchor", G([0.76, 0.82, 0.9], 0.45, [0.02, 0.04, 0.07, 1.0], [0.6, 0.66, 0.78], [0.2, 0.26, 0.38])),
 "vault":        mk("crypt", G([0.8, 0.82, 0.96], 0.4, [0.04, 0.05, 0.08, 1.0], [0.66, 0.7, 0.9], [0.22, 0.26, 0.4])),
 "observatory":  mk("crypt", G([0.8, 0.82, 1.02], 0.35, [0.05, 0.05, 0.1, 1.0], [0.7, 0.72, 0.95], [0.24, 0.26, 0.5])),
 # Act III: the Golden Age (Atlas: ivory, white-gold, luminous, brilliant clarity)
 "golden_gate":    mk("city", GOLD(1.05)),
 "golden_city":    mk("city", GOLD()),
 "golden_canal":   mk("mill_river", GOLD(), canals=3, pools=(4, 380, 700)),
 "golden_orchard": mk("orchard", G([1.12, 1.06, 0.8], 0.05, [0.07, 0.06, 0.02, 1.0], [1.0, 0.94, 0.8], [0.3, 0.52, 0.68])),
 "golden_workshop":mk("city", G([1.1, 0.96, 0.78], 0.15, [0.07, 0.04, 0.0, 1.0], [0.95, 0.85, 0.7], [0.3, 0.42, 0.5])),
 "golden_academy": mk("crypt", G([0.86, 0.94, 1.14], 0.15, [0.04, 0.06, 0.12, 1.0], [0.8, 0.88, 1.0], [0.2, 0.4, 0.8])),
 "golden_garden":  mk("orchard", G([1.06, 1.08, 0.94], 0.05, [0.06, 0.06, 0.04, 1.0], [0.96, 0.96, 0.86], [0.3, 0.55, 0.68]), pools=(3, 200, 320)),
 "golden_foundry": mk("crypt", G([1.06, 0.84, 0.66], 0.25, [0.08, 0.03, 0.0, 1.0], [1.0, 0.7, 0.5], [0.5, 0.25, 0.1])),
 "golden_archive": mk("crypt", G([1.08, 1.0, 0.82], 0.2, [0.06, 0.05, 0.02, 1.0], [1.0, 0.92, 0.75], [0.3, 0.4, 0.5])),
 "golden_perimeter": mk("city", GOLD(0.98), rocks=40),
 "golden_lab":     mk("crypt", G([1.04, 1.04, 1.06], 0.35, [0.1, 0.1, 0.11, 1.0], [0.95, 0.95, 1.0], [0.4, 0.55, 0.6])),
 "golden_spire":   mk("crypt", GOLD(1.08)),
 # Act IV: the final day (Atlas: fire, fractures, ash, chronal stormlight)
 "golden_dawn":    mk("city", G([1.14, 0.98, 0.84], 0.1, [0.1, 0.05, 0.02, 1.0], [1.0, 0.85, 0.7], [0.32, 0.45, 0.6])),
 "cinder":         mk("orchard", G([1.02, 0.78, 0.6], 0.35, [0.08, 0.03, 0.0, 1.0], [0.7, 0.55, 0.45], [0.3, 0.25, 0.25])),
 "reservoir":      mk("mill_river", G([0.98, 0.94, 0.86], 0.3, [0.05, 0.04, 0.03, 1.0], [0.8, 0.78, 0.7], [0.3, 0.4, 0.48]), pools=(5, 420, 800)),
 "siege":          mk("city", G([0.86, 0.78, 0.74], 0.4, [0.04, 0.02, 0.02, 1.0], [0.6, 0.52, 0.5], [0.2, 0.24, 0.28])),
 "golden_hall":    mk("crypt", G([0.98, 0.9, 0.74], 0.3, [0.05, 0.03, 0.0, 1.0], [0.9, 0.78, 0.6], [0.3, 0.3, 0.3])),
 "burning":        mk("ash_road", G([0.95, 0.62, 0.56], 0.35, [0.1, 0.02, 0.06, 1.0], [0.7, 0.45, 0.7], [0.4, 0.2, 0.5])),
 "cathedral_intact": mk("crypt", G([0.92, 0.96, 1.12], 0.1, [0.06, 0.06, 0.1, 1.0], [0.85, 0.85, 1.0], [0.3, 0.4, 0.8]), wall=["a_rock_tall", "b_rock_tall"]),
 "ash_senate":     mk("city", G([0.8, 0.76, 0.74], 0.55, [0.06, 0.05, 0.05, 1.0], [0.6, 0.58, 0.58], [0.2, 0.2, 0.22])),
 "access":         mk("crypt", G([0.82, 0.78, 0.78], 0.45, [0.04, 0.02, 0.06, 1.0], [0.7, 0.5, 0.8], [0.3, 0.15, 0.45])),
 "sundering":      mk("ash_road", G([0.78, 0.62, 0.92], 0.5, [0.08, 0.02, 0.12, 1.0], [0.6, 0.45, 0.85], [0.5, 0.25, 0.75])),
 "between_empty":  mk("anchor", G([0.8, 0.82, 0.88], 0.7, [0.06, 0.06, 0.08, 1.0], [0.6, 0.62, 0.7], [0.18, 0.18, 0.24])),
 "between_court":  mk("anchor", G([0.86, 0.9, 1.0], 0.45, [0.05, 0.06, 0.08, 1.0], [0.75, 0.8, 0.95], [0.25, 0.3, 0.45])),
 "between_choir":  mk("anchor", G([0.6, 0.56, 0.7], 0.55, [0.02, 0.0, 0.05, 1.0], [0.4, 0.35, 0.55], [0.12, 0.08, 0.2])),
 "between_lantern": mk("anchor", G([1.08, 0.92, 0.72], 0.2, [0.08, 0.05, 0.0, 1.0], [0.9, 0.75, 0.5], [0.3, 0.2, 0.35])),
 "engine":         mk("crypt", G([1.04, 0.9, 0.7], 0.3, [0.08, 0.06, 0.03, 1.0], [0.95, 0.85, 0.7], [0.4, 0.3, 0.15])),
 # Act V: the Unwritten and the erased epochs (bible: Rain slate/canals, Verdant roots, Iron soot/kiln red, Moonfall silver)
 "broken_observatory": mk("ash_road", G([0.86, 0.86, 1.0], 0.4, [0.04, 0.04, 0.09, 1.0], [0.7, 0.7, 0.9], [0.3, 0.3, 0.55]), rocks=70),
 "between_glass":  mk("anchor", G([0.9, 0.95, 1.06], 0.5, [0.08, 0.09, 0.12, 1.0], [0.85, 0.9, 1.0], [0.3, 0.36, 0.5])),
 "epoch_rain":     mk("mill_river", G([0.72, 0.8, 0.9], 0.45, [0.02, 0.04, 0.07, 1.0], [0.6, 0.66, 0.78], [0.16, 0.26, 0.36]), canals=3, pools=(6, 420, 800)),
 "epoch_verdant":  mk("forest", G([0.86, 1.12, 0.8], 0.0, [0.0, 0.06, 0.02, 1.0], [0.7, 0.95, 0.7], [0.25, 0.45, 0.35]), spacing=460, cut=0.5),
 "epoch_iron":     mk("city", G([0.86, 0.66, 0.6], 0.45, [0.06, 0.01, 0.0, 1.0], [0.55, 0.45, 0.42], [0.3, 0.12, 0.08]), ground="dirt"),
 "epoch_moon":     mk("city", G([0.86, 0.9, 1.06], 0.55, [0.08, 0.09, 0.14, 1.0], [0.8, 0.85, 1.0], [0.3, 0.36, 0.55])),
 "between_orchard": mk("anchor", G([1.0, 1.04, 0.9], 0.2, [0.06, 0.07, 0.04, 1.0], [0.95, 0.95, 0.8], [0.25, 0.25, 0.4]), ground="grass"),
 "between_mirror": mk("anchor", G([0.94, 0.96, 1.04], 0.6, [0.1, 0.1, 0.12, 1.0], [0.9, 0.9, 1.0], [0.4, 0.42, 0.5])),
 "between_bridges": mk("anchor", G([0.9, 0.84, 0.96], 0.4, [0.05, 0.03, 0.08, 1.0], [0.75, 0.65, 0.9], [0.3, 0.18, 0.5])),
 "crownsfall_ages": mk("city", G([1.06, 1.0, 0.94], 0.2, [0.06, 0.05, 0.06, 1.0], [0.9, 0.86, 0.92], [0.3, 0.45, 0.62])),
 "royal_archive":  mk("crypt", G([0.86, 0.86, 1.04], 0.3, [0.04, 0.04, 0.08, 1.0], [0.75, 0.75, 0.95], [0.2, 0.25, 0.5])),
 # Act VI: war (Atlas: war camps, deserts, arsenals, relays)
 "siege_city":     mk("city", G([0.88, 0.82, 0.8], 0.35, [0.05, 0.03, 0.04, 1.0], [0.62, 0.56, 0.6], [0.2, 0.25, 0.32])),
 "fracture_forest": mk("forest", G([0.94, 0.98, 1.04], 0.3, [0.14, 0.15, 0.18, 1.0], [0.85, 0.88, 0.95], [0.32, 0.45, 0.55])),
 "flood":          mk("mill_river", G([0.82, 0.88, 0.92], 0.35, [0.02, 0.04, 0.06, 1.0], [0.66, 0.72, 0.8], [0.2, 0.3, 0.38]), pools=(8, 500, 900)),
 "between_futures": mk("anchor", G([0.84, 0.92, 0.98], 0.6, [0.1, 0.12, 0.14, 1.0], [0.8, 0.88, 0.95], [0.25, 0.3, 0.38])),
 "between_clock":  mk("anchor", G([1.0, 0.92, 0.78], 0.35, [0.07, 0.06, 0.03, 1.0], [0.9, 0.82, 0.65], [0.3, 0.22, 0.12])),
 "choir_march":    mk("ash_road", G([0.8, 0.7, 0.92], 0.45, [0.04, 0.02, 0.08, 1.0], [0.55, 0.45, 0.75], [0.35, 0.2, 0.55]), trees=[("gnarled_a", 2), ("oak_b", 1)], meadows=4),
 "camp":           mk("hamlet", G([1.0, 0.96, 0.88], 0.15, [0.06, 0.05, 0.03, 1.0], [0.88, 0.84, 0.78], [0.25, 0.38, 0.45]), pools=(0, 0, 0), meadows=7),
 "gate":           mk("anchor", G([1.02, 0.92, 0.72], 0.3, [0.08, 0.06, 0.02, 1.0], [0.95, 0.85, 0.65], [0.35, 0.25, 0.12])),
 "engine_horizon": mk("crypt", G([1.1, 1.0, 0.82], 0.25, [0.14, 0.12, 0.08, 1.0], [1.0, 0.95, 0.85], [0.45, 0.35, 0.2])),
 # Act VII: the Chronicle core (Atlas: cosmic engine-space, voids, regulator architecture; keep blue-gold/ivory)
 "engine_index":   mk("anchor", G([1.04, 1.02, 0.96], 0.35, [0.14, 0.14, 0.14, 1.0], [0.95, 0.95, 0.92], [0.15, 0.15, 0.2])),
 "engine_rings":   mk("anchor", G([1.06, 0.94, 0.72], 0.3, [0.1, 0.08, 0.04, 1.0], [0.95, 0.88, 0.7], [0.18, 0.14, 0.08])),
 "mercy":          mk("crypt", G([1.0, 1.02, 1.04], 0.55, [0.14, 0.14, 0.15, 1.0], [0.95, 0.95, 0.98], [0.4, 0.45, 0.5])),
 "oris_ruin":      mk("ash_road", G([1.02, 0.94, 0.78], 0.3, [0.06, 0.05, 0.02, 1.0], [0.9, 0.85, 0.7], [0.3, 0.35, 0.4]), road="flagstone"),
 "cathedral_restored": mk("crypt", G([0.94, 0.96, 1.12], 0.15, [0.08, 0.08, 0.12, 1.0], [0.88, 0.88, 1.0], [0.3, 0.4, 0.8]), wall=["a_rock_tall", "b_rock_tall"]),
 "shore":          mk("anchor", G([0.86, 0.94, 1.02], 0.35, [0.04, 0.07, 0.1, 1.0], [0.75, 0.85, 0.95], [0.25, 0.55, 0.75])),
 "engine_core":    mk("crypt", G([1.1, 1.04, 0.9], 0.3, [0.16, 0.15, 0.12, 1.0], [1.0, 0.98, 0.92], [0.45, 0.3, 0.6])),
 "decision":       mk("crypt", G([0.98, 0.98, 1.02], 0.5, [0.1, 0.1, 0.12, 1.0], [0.9, 0.9, 0.95], [0.3, 0.3, 0.4])),
 "crownsfall_reborn": mk("city", G([1.08, 1.04, 0.98], 0.08, [0.07, 0.06, 0.05, 1.0], [0.92, 0.9, 0.9], [0.3, 0.5, 0.65])),
 "frontier_new":   mk("farmland", G([1.04, 1.04, 0.96], 0.1, [0.05, 0.05, 0.04, 1.0], [0.9, 0.9, 0.88], [0.3, 0.48, 0.58])),
 "memorial":       mk("orchard", G([1.04, 1.0, 0.94], 0.15, [0.06, 0.05, 0.05, 1.0], [0.94, 0.9, 0.9], [0.3, 0.45, 0.6]), pools=(2, 220, 340)),
})
BIOMES.update({"bastion_ruin": mk("hamlet", G([0.86, 0.94, 0.96], 0.36, [0.05, 0.07, 0.08, 1.0], [0.66, 0.8, 0.86], [0.22, 0.34, 0.36]), rocks=80, pools=(5, 360, 520), meadows=4),
               "harbor": mk("city", G([0.98, 1.0, 1.02], 0.22, [0.05, 0.06, 0.08, 1.0], [0.8, 0.84, 0.88], [0.2, 0.36, 0.45]), sea="south")})
BIOMES.update({"coast_war":      mk("coast", G([0.84, 0.84, 0.88], 0.45, [0.05, 0.04, 0.05, 1.0], [0.62, 0.6, 0.64], [0.16, 0.24, 0.3]))})
BIOMES.update({"winter":         mk("snow", G([0.94, 0.98, 1.06], 0.5, [0.3, 0.32, 0.36, 1.0], [0.9, 0.94, 1.0], [0.5, 0.6, 0.72]))})
BIOMES.update({"caldera":        mk("quarry", G([1.0, 0.72, 0.92], 0.3, [0.1, 0.02, 0.1, 1.0], [0.8, 0.5, 0.85], [0.75, 0.3, 0.8]))})
BIOMES.update({"wall":           mk("mountain", G([0.9, 0.9, 0.92], 0.4, [0.05, 0.05, 0.06, 1.0], [0.75, 0.75, 0.8], [0.25, 0.3, 0.38]), road="flagstone")})
KIND_ICON = {"farmland": "heath", "orchard": "forest", "forest": "forest", "hamlet": "town", "echo_grove": "forest", "ash_road": "heath", "mill_river": "marsh",
             "city": "town", "citadel": "town", "merchant_crypt": "dungeon", "cistern": "dungeon", "crypt": "dungeon", "cathedral": "dungeon", "anchor": "archive"}

SIZES = {"L": (11520, 4944), "S": (7680, 4944)}

# acts without hand-placed map positions: lay them out along the route, register order left to right
import math as _m
for _act in range(1, 8):
    _z = [z for z in sorted(DESIGN) if int(z[3:5]) == _act]
    for _i, _zid in enumerate(_z):
        _k = DESIGN[_zid]["key"]
        if _k not in POS:
            POS[_k] = (round(0.07 + 0.86 * _i / max(1, len(_z) - 1), 3), round(0.5 + 0.3 * _m.sin(_i * 1.7 + _act), 3))
def key_of(zid): return DESIGN[zid]["key"]
ZID_OF = {d["key"]: zid for zid, d in DESIGN.items()}

def neighbours(key):
    out = []
    for a, b in EDGES:
        if a == key: out.append(b)
        elif b == key: out.append(a)
    return out

def side_toward(a, b):
    ax, ay = POS[a]; bx, by = POS[b]
    dx, dy = bx - ax, (by - ay) * 1.6
    if abs(dx) >= abs(dy): return "E" if dx > 0 else "W"
    return "S" if dy > 0 else "N"

# ---------------------------------------------------------------- fixed (hand-built) zones: their exits
FIXED_EXITS = {
 "crownsfall": {"highward_steps": {"at": [840, 330], "arrive": [1000, 700]}, "kingsroad_fields": {"at": [2220, 1630], "arrive": [2220, 1450]}},
 "whisperwood_forest": {"kingsroad_fields": {"at": [140, 2630], "arrive": [700, 2630]}, "hollowmere": {"at": [10720, 4190], "arrive": [10300, 3950]},
                        "mossbarrow_crypts": {"at": [9250, 700], "arrive": [9250, 1000]}, "silverroot_grove": {"at": [6450, 4420], "arrive": [6450, 4050]}},
}

def lerp(a, b, t): return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]

def exit_point(side, W, H, rng, used):
    for _ in range(50):
        if side == "W": p = [140, rng.uniform(1100, H - 900)]
        elif side == "E": p = [W - 140, rng.uniform(1100, H - 900)]
        elif side == "N": p = [rng.uniform(1600, W - 1600), 190]
        else: p = [rng.uniform(1600, W - 1600), H - 170]
        if all(math.hypot(p[0] - q[0], (p[1] - q[1]) / 0.55) > 1800 for q in used): return [int(p[0]), int(p[1])]
    return [int(p[0]), int(p[1])]

def inward(p, W, H, d=480):
    x, y = p
    if x < 300: return [x + d, y]
    if x > W - 300: return [x - d, y]
    if y < 400: return [x, y + d * 0.8]
    return [x, y - d * 0.8]

def dist_to_polyline(p, pts):
    best = 1e9
    for a, b in zip(pts, pts[1:]):
        ax, ay = a; bx, by = b; px, py = p
        dx, dy = bx - ax, by - ay; L2 = dx * dx + dy * dy or 1
        t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / L2))
        qx, qy = ax + t * dx, ay + t * dy
        best = min(best, math.hypot(px - qx, (py - qy) / 0.55))
    return best

def nearest_on(p, pts):
    best = None; bd = 1e9
    for a, b in zip(pts, pts[1:]):
        for t in [i / 10 for i in range(11)]:
            q = lerp(a, b, t); dd = math.hypot(p[0] - q[0], (p[1] - q[1]) / 0.55)
            if dd < bd: bd, best = dd, q
    return best

# ---------------------------------------------------------------- layouts
def layout_open(zid, d, rng, W, H, exits):
    """wild / town: roads from every exit to a hub, points of interest off the roads on trails, organic clearings."""
    bio = BIOMES[d.get("biome", "forest")]
    town = d["kind"] == "town"
    hub = [int(rng.uniform(W * 0.38, W * 0.62)), int(rng.uniform(H * 0.4, H * 0.6))]
    roads = []
    for e in exits:
        a = e["at"]; b = hub
        n = rng.randint(2, 3)
        pts = [a, inward(a, W, H, 380)]
        for i in range(1, n + 1):
            t = i / (n + 1); m = lerp(pts[1], b, t)
            dx, dy = b[0] - a[0], b[1] - a[1]; L = math.hypot(dx, dy) or 1
            off = rng.uniform(-0.22, 0.22) * L
            pts.append([m[0] - dy / L * off, m[1] + dx / L * off * 0.55])
        pts.append(b)
        roads.append([[int(x), int(y)] for x, y in pts])
    if len(exits) == 1:   # a dead-end zone still needs a road through it: carry it on past the hub
        far = [W - exits[0]["at"][0], H - exits[0]["at"][1]]
        far = [min(W - 900, max(900, far[0])), min(H - 900, max(900, far[1]))]
        roads.append([hub, lerp(hub, far, 0.5), [int(far[0]), int(far[1])]])
    # points of interest: far from roads and from each other
    pois = []
    names = d.get("pois", [])
    for i, nm in enumerate(names):
        best = None; bs = -1
        for _ in range(500):
            p = [rng.uniform(700, W - 700), rng.uniform(650, H - (1500 if bio.get("sea") else 550))]
            dr = min(dist_to_polyline(p, r) for r in roads)
            if dr < (500 if town else 700) or dr > 2600: continue
            dp = min([math.hypot(p[0] - q[0], (p[1] - q[1]) / 0.55) for q in pois] + [9e9])
            de = min(math.hypot(p[0] - e["at"][0], (p[1] - e["at"][1]) / 0.55) for e in exits)
            if de < 1400: continue
            sc = min(dp, 4000) + rng.uniform(0, 400)
            if sc > bs: bs, best = sc, p
        if best is None: best = [rng.uniform(900, W - 900), rng.uniform(900, H - 900)]
        pois.append([int(best[0]), int(best[1])])
    trails = []
    for p in pois:
        allr = [pt for r in roads for pt in r]
        q = min(((math.hypot(p[0] - a[0], (p[1] - a[1]) / 0.55), a) for a in allr))[1]
        q = nearest_on(p, min(roads, key=lambda r: dist_to_polyline(p, r)))
        m = lerp(p, q, 0.5); m = [m[0] + rng.uniform(-300, 300), m[1] + rng.uniform(-180, 180)]
        trails.append([[int(x), int(y)] for x, y in (q, m, p)])
    paths = [{"pts": r, "width": (320 if town else 240) if bio["road"] == "flagstone" else 210, "layer": bio["road"]} for r in roads]
    # each landmark gets its own treatment so no two read as the same stamp: an open clearing, a grove (trees and rocks
    # close around a small glade), a ring of standing stones, or nothing at all (the trail just fades out at a feature)
    boss_poi = d.get("boss_poi", -1)
    styles = []
    for i, p in enumerate(pois):
        st = "clearing" if (i == boss_poi or i == d.get("npc_poi") or town) else rng.choice(["clearing", "grove", "ring", "open"])
        styles.append(st)
    paths += [{"pts": t, "width": int(rng.uniform(130, 190)) if not town else 220, "layer": "dirt" if not town else "flagstone", "style": "trail",
               "taper_end": styles[i] in ("open", "grove")} for i, t in enumerate(trails)]
    patches = [{"at": hub, "r": bio.get("plaza", 440), "layer": "flagstone", "squash": 0.515}]
    for i, p in enumerate(pois):
        st = styles[i]
        if st == "open": continue
        r = rng.uniform(360, 520) * (1.5 if i == boss_poi else 1.0) * (0.6 if st == "grove" else 1.0)
        patches.append({"at": p, "r": int(r), "layer": bio["clear"] if st != "ring" else rng.choice(["dirt", "flagstone"]), "squash": 0.515})
    # meadows / ash fields / salt pans: loose dirt patches that break the green
    for _ in range(bio.get("beds", 0)):
        p = [rng.uniform(600, W - 600), rng.uniform(600, H - 500)]
        if min(dist_to_polyline(p, r) for r in roads) < 420: continue
        patches.insert(0, {"at": [int(p[0]), int(p[1])], "r": int(rng.uniform(260, 480)), "layer": "dirt", "squash": 0.5})
    for _ in range(bio.get("meadows", 0)):
        p = [rng.uniform(600, W - 600), rng.uniform(600, H - 500)]
        patches.insert(0, {"at": [int(p[0]), int(p[1])], "r": int(rng.uniform(380, 760)), "layer": "dirt", "squash": 0.5, "no_rim": True})
    pools = []
    sea = [[x, H + 60, 1000] for x in range(0, W + 900, 900)] if bio.get("sea") == "south" else []
    n, rmin, rmax = bio.get("pools", (0, 0, 0))
    for _ in range(n * 6):
        if len(pools) >= n: break
        p = [rng.uniform(700, W - 700), rng.uniform(700, H - 600)]; r = rng.uniform(rmin, rmax)
        if min(dist_to_polyline(p, rr) for rr in [x["pts"] for x in paths]) < r + 300: continue
        if any(math.hypot(p[0] - q[0], (p[1] - q[1]) / 0.55) < r + 700 for q in pois + [hub]): continue
        pools.append([int(p[0]), int(p[1]), int(r)])
    patches += [{"at": p[:2], "r": p[2], "layer": "water", "squash": 0.52} for p in pools + sea]
    canals = []
    for _ in range(bio.get("canals", 0)):   # mill races: dead-end channels from the zone edge into a pond, never across a road
        if not pools: break
        p = rng.choice(pools); top = [p[0] + rng.uniform(-500, 500), 40 if p[1] < H / 2 else H - 40]
        if min(dist_to_polyline(top, x["pts"]) for x in paths) < 400: continue
        canals.append([[int(top[0]), int(top[1])], [int(p[0] + rng.uniform(-200, 200)), int((top[1] + p[1]) / 2)], [p[0], p[1]]])
    paths += [{"pts": c, "width": 150, "layer": "water", "wander": 0.4} for c in canals if all(dist_to_polyline(q, x["pts"]) > 260 for x in paths if x["layer"] != "water" for q in c[:2])]
    return dict(hub=hub, pois=pois, paths=paths, patches=patches, pools=pools, roads=roads, styles=styles)

def layout_rooms(zid, d, rng, W, H, exits, between=False):
    """dungeon / between / arena: rooms (islands) joined by bending corridors (bridges); exits on the room nearest each edge."""
    n = {"arena": 4, "between": 7, "dungeon": 8}[d["kind"]]
    rooms = []
    for i in range(n * 40):
        if len(rooms) >= n: break
        big = d["kind"] == "arena" and len(rooms) == n - 1
        r = rng.uniform(820, 1000) if big else rng.uniform(430, 640)
        p = [rng.uniform(r + 500, W - r - 500), rng.uniform(r * 0.6 + 600, H - r * 0.6 - 500)]
        if big: p = [W - r - 700, H / 2 + rng.uniform(-400, 400)]
        if all(math.hypot(p[0] - q[0], (p[1] - q[1]) / 0.55) > r + q[2] + 650 for q in rooms):
            rooms.append([int(p[0]), int(p[1]), int(r)])
    # minimum spanning tree + a few loops
    links = []; inside = {0}
    while len(inside) < len(rooms):
        best = min(((math.hypot(rooms[a][0] - rooms[b][0], (rooms[a][1] - rooms[b][1]) / 0.55), a, b) for a in inside for b in range(len(rooms)) if b not in inside))
        links.append((best[1], best[2])); inside.add(best[2])
    for _ in range(2 if d["kind"] != "arena" else 1):
        a, b = rng.sample(range(len(rooms)), 2)
        if (a, b) not in links and (b, a) not in links: links.append((a, b))
    paths = []
    for i, (a, b) in enumerate(links):
        A, Bb = rooms[a], rooms[b]
        mx, my = (A[0] + Bb[0]) / 2, (A[1] + Bb[1]) / 2; dx, dy = Bb[0] - A[0], Bb[1] - A[1]; L = math.hypot(dx, dy) or 1
        off = rng.uniform(-0.25, 0.25) * L
        paths.append({"pts": [A[:2], [int(mx - dy / L * off), int(my + dx / L * off * 0.55)], Bb[:2]], "width": int(rng.uniform(260, 340)), "layer": "flagstone" if not between else "dirt", "wander": 0.8})
    for e in exits:   # corridor from the nearest room to the exit
        r = min(rooms, key=lambda q: math.hypot(q[0] - e["at"][0], (q[1] - e["at"][1]) / 0.55))
        # the last stretch to the exit is straight, so the arrival point just inside it always lands on the corridor
        paths.append({"pts": [e["at"], inward(e["at"], W, H, 700)], "width": 320, "layer": "flagstone" if not between else "dirt", "straight": True})
        paths.append({"pts": [inward(e["at"], W, H, 650), r[:2]], "width": 300, "layer": "flagstone" if not between else "dirt", "wander": 0.6})
    patches = [{"at": r[:2], "r": r[2], "layer": "flagstone" if not between else rng.choice(["flagstone", "dirt"]), "squash": 0.515} for r in rooms]
    pools = []
    if BIOMES[d["biome"]].get("water_rooms"):
        for r in rooms[1:]:
            if rng.random() < 0.6:
                pools.append([r[0] + int(rng.uniform(-r[2] * 0.3, r[2] * 0.3)), r[1] + int(r[2] * 0.25), int(r[2] * 0.32)])
        patches += [{"at": p[:2], "r": p[2], "layer": "water", "squash": 0.52} for p in pools]
    entry = exits[0]["at"] if exits else [0, H / 2]
    order = sorted(range(len(rooms)), key=lambda i: math.hypot(rooms[i][0] - entry[0], rooms[i][1] - entry[1]))
    hub = rooms[order[len(order) // 2]][:2]
    # points of interest: the farthest rooms first (boss last-but-farthest), the hub room keeps the waypoint
    far = [rooms[i][:2] for i in reversed(order) if rooms[i][:2] != hub]
    pois = far[:max(1, len(d.get("pois", [])))]
    boss_room = far[0]
    return dict(hub=hub, pois=pois, paths=paths, patches=patches, pools=pools, rooms=rooms, boss_room=boss_room)

def write_spec(zid, d, lay, W, H, exits):
    bio = BIOMES[d["biome"]]
    base = json.load(open("assets/zones/src/greyfen_causeway.kitzone.json"))
    z = copy.deepcopy(base)
    key = d["key"]
    z.update({"name": RG(zid)["name"], "world_id": key, "seed": abs(hash(key)) % 9973, "size": [W, H], "ground_base": bio.get("ground", "grass_old")})
    for k in ("enclose", "void", "setpieces"): z.pop(k, None)
    z["paths"] = lay["paths"]; z["patches"] = lay["patches"]
    z["clear"] = [[e["at"][0], e["at"][1], 380] for e in exits] + [[p[0], p[1], 300] for p in lay["pois"]]
    z["place"] = []
    f = z["forest"]
    if bio.get("dungeon") or bio.get("between"):
        f.update({"spacing": 99999, "trees": [["silver", 1]], "rock_clusters": 0, "clumps_per_mpx": 0, "tufts_per_mpx": 0, "litter_per_mpx": 0})
        f["cover"]["per_mpx"] = 10 if bio.get("dungeon") else 0
        z["edges"] = []; z["root_dressing"] = {"decals": 0, "tufts": 0, "decal_props": ["a_leaves"], "tuft_props": ["a_grass_tall"]}
        if bio.get("dungeon"):
            z["enclose"] = {"props": bio["wall"], "spacing": 240, "fill": 0.5, "scale": [1.0, 1.5]}
        else:
            z["void"] = True
        z["light"] = {"canopy": 0.5, "contact": 0.4, "pools": 0.3, "dapple_px": 40, "shift": [0.3, 0.16], "exposure": 0.78, "overhead": 0.0, "over_density": 0,
                      "tree_mist": 0.0, "open": [[r[0], r[1], r[2] * 0.85, 0.6] for r in lay.get("rooms", [])], "shafts": [[lay["boss_room"][0], lay["boss_room"][1] - 220, 420]],
                      "prop_mist": False, "mist": []}
        # rooms / islands carry small debris and decals along their edges (on the walkable floor, kept off the centre)
        z["dress"] = [{"at": r[:2], "r": r[2] * 0.95, "props": ["a_pebbles", "a_moss", "a_leaves", "a_pebbles"] + (["a_mushrooms"] if bio.get("dungeon") else ["a_edgestones"]),
                       "n": 10, "on_path": True, "scale": [0.7, 1.1]} for r in lay.get("rooms", [])]
    else:
        f["trees"] = [list(t) for t in bio["trees"]]; f["spacing"] = bio["spacing"]; f["cut"] = bio["cut"]; f["rock_clusters"] = bio["rocks"]
        cl = {"ferns": FERNS[:2], "lavender": ["a_lavender", "b_lavender"], "white": ["a_shrub_white", "b_shrub_white"], "bushes": BUSH,
              "mixed": ["a_fern", "a_grass_tall", "b_grass_tall", "a_lavender", "b_shrub_white", "b_bush_round"]}
        f["clumps"] = {k: {"w": w, "n": [2, 6], "r": 170, "props": cl[k]} for k, w in bio["clumps"].items()}
        z["light"]["open"] = [[p[0], p[1], 560, 0.45] for p in lay["pois"]] + [[lay["hub"][0], lay["hub"][1], 600, 0.5]]
        z["light"]["shafts"] = [[lay["hub"][0], lay["hub"][1] - 220, 420]]
        z["light"]["canopy"] = 0.22 if bio["spacing"] > 1000 else 0.34
        z["light"]["mist"] = [[p[0], p[1], p[2] * 1.6] for p in lay["pools"]] if bio.get("mist") else []
        z["rim"] = {"props": bio["rim"], "density": 1.0, "chance": 0.5}
        if bio.get("paved"):    # streets and squares: planting stays in the beds and along the edges
            f["clumps_per_mpx"] = 3; f["tufts_per_mpx"] = 0; f["litter_per_mpx"] = 4; f["cover"]["per_mpx"] = 4; f["rock_clusters"] = 4
        dress = []
        for p, st in zip(lay["pois"], lay.get("styles", ["clearing"] * len(lay["pois"]))):
            if st == "grove":
                dress.append({"at": p, "r": 520, "props": [t[0] for t in bio["trees"]] + bio["dress"], "n": 9})
            elif st == "ring":
                dress.append({"at": p, "r": 470, "props": ["a_rock_tall", "b_rock_tall", "a_rock_pair"], "n": 8, "scale": [0.7, 1.0]})
            elif st == "open":
                dress.append({"at": p, "r": 380, "props": bio["dress"] + ["a_moss", "a_pebbles"], "n": 10})
            else:
                dress.append({"at": p, "r": 420, "props": bio["dress"], "n": 6})
        z["dress"] = dress
        z["edges"] = [{"path": 0, "spacing": 170, "offset": 120, "jitter": 120, "density": 0.7, "min_gap": 40, "props": bio["rim"], "scale": [0.85, 1.2]}]
    z["exits"] = [{"name": e["name"], "to": e["to"], "at": e["at"], "r": 170, "arrive": e["arrive"]} for e in exits]
    z["waypoints"] = [{"id": key + "_wp", "name": RG(zid)["name"], "at": lay["hub"], "radius_px": 200}]
    z["spawn"] = exits[0]["inside"] if exits else lay["hub"]
    z["map_pois"] = [{"name": nm, "kind": "landmark", "at": p, "blurb": RG(zid)["look"]} for nm, p in zip(d.get("pois", []), lay["pois"])]
    z["map_pois"] += [{"name": e["name"], "kind": "landmark", "at": e["at"], "blurb": "To " + e["name"] + "."} for e in exits]
    z["grade"] = bio["grade"]
    json.dump(z, open(f"assets/zones/src/{key}.kitzone.json", "w"), indent=1)

# ---------------------------------------------------------------- run
built = json.load(open("data/campaign_built.json")) if os.path.exists("data/campaign_built.json") else {}
todo = [zid for zid in DESIGN if int(zid[3:5]) in ACTS and (not ONLY or DESIGN[zid]["key"] in ONLY)]

# exits for every designed zone, both ways
EXITS = {}
for zid in DESIGN:
    key = DESIGN[zid]["key"]; d = DESIGN[zid]
    if d["kind"] == "fixed": continue
    W, H = SIZES[d.get("size", "L" if d["kind"] in ("wild",) else "S")]
    rng = random.Random(abs(hash(key + "exits")) % 99991)
    used = []; ex = []
    for nb in neighbours(key):
        sd = side_toward(key, nb)
        if sd == "S" and BIOMES.get(d.get("biome", ""), {}).get("sea"):   # the south edge is sea: leave east or west
            sd = "E" if POS[nb][0] >= POS[key][0] else "W"
        if d["kind"] in ("dungeon", "between", "arena") and not ex: sd = "W"   # the way in is on the west
        p = exit_point(sd, W, H, rng, used); used.append(p)
        ex.append({"to": nb, "at": p, "inside": [int(v) for v in inward(p, W, H, 420)]})
    EXITS[key] = dict(W=W, H=H, list=ex)
def arrive_in(target, from_key):
    """Where a hero lands in `target` coming from `from_key`: just inside target's exit back to from_key."""
    if target in FIXED_EXITS: return FIXED_EXITS[target][from_key]["arrive"]
    for e in EXITS[target]["list"]:
        if e["to"] == from_key: return e["inside"]
    return [620, 2470]
def zname(key):
    return RG(ZID_OF[key])["name"] if key in ZID_OF else key

maps = {}
for zid in todo:
    d = DESIGN[zid]; key = d["key"]
    if d["kind"] == "fixed": continue
    E = EXITS[key]; W, H = E["W"], E["H"]
    exits = [{"name": zname(e["to"]), "to": e["to"], "at": e["at"], "inside": e["inside"], "arrive": arrive_in(e["to"], key)} for e in E["list"]]
    rng = random.Random(abs(hash(key)) % 99991)
    if d["kind"] in ("wild", "town"): lay = layout_open(zid, d, rng, W, H, exits)
    else: lay = layout_rooms(zid, d, rng, W, H, exits, d["kind"] == "between")
    write_spec(zid, d, lay, W, H, exits)
    maps[key] = lay
    built[key] = {"zid": zid, "W": W, "H": H, "hub": lay["hub"], "pois": lay["pois"], "boss": lay.get("boss_room"),
                  "exits": [{"to": e["to"], "at": e["at"], "inside": e["inside"]} for e in exits], "kind": d["kind"]}
    if not args.no_maps:
        r = subprocess.run([sys.executable, "tools/build_kit_zone.py", f"assets/zones/src/{key}.kitzone.json"], capture_output=True, text=True)
        print(r.stdout.strip().splitlines()[-1] if r.returncode == 0 else ("BUILD FAILED " + key + "\n" + r.stderr[-1500:]))

# fixed zones: patch their exits to the campaign graph
for zid in todo:
    d = DESIGN[zid]
    if d["kind"] != "fixed": continue
    key = d["key"]
    p = f"assets/zones/{key}.json"; z = json.load(open(p))
    if key == "whisperwood_forest":
        new = []
        for to, fx in FIXED_EXITS[key].items():
            x, y = fx["at"]; r = 150
            poly = [[x - r, y - r * 0.55], [x + r, y - r * 0.55], [x + r, y + r * 0.55], [x - r, y + r * 0.55]]
            new.append({"name": zname(to), "to": to, "arrive": arrive_in(to, key), "poly": poly, "aura": {"poly": poly}})
        z["exits"] = new
        z["name"] = RG(zid)["name"]
        z["map_pois"] = [q for q in z.get("map_pois", []) if q["name"] not in ("Mossy Arch", "Barrow Stair", "Greyfen Road", "Fae Ring") and q["name"] not in [zname(t) for t in FIXED_EXITS[key]]]
        z["map_pois"] += [{"name": zname(to), "kind": "landmark", "at": fx["at"], "blurb": "To " + zname(to) + "."} for to, fx in FIXED_EXITS[key].items()]
        json.dump(z, open(p, "w"), indent=1)
        built[key] = {"zid": zid, "W": z["size"][0], "H": z["size"][1], "hub": [5650, 3000], "pois": d.get("fixed_pois", []), "boss": None,
                      "exits": [{"to": to, "at": fx["at"], "inside": fx["arrive"]} for to, fx in FIXED_EXITS[key].items()], "kind": "fixed"}
    elif key == "crownsfall":
        for e in z["exits"]:
            if e["to"] in FIXED_EXITS[key]: e["arrive"] = arrive_in(e["to"], key); e["name"] = zname(e["to"])
        json.dump(z, open(p, "w"), indent=1)
        built[key] = {"zid": zid, "W": 3840, "H": 1648, "hub": [1924, 838], "pois": [], "boss": None,
                      "exits": [{"to": to, "at": fx["at"], "inside": fx["arrive"]} for to, fx in FIXED_EXITS[key].items()], "kind": "fixed"}

json.dump(built, open("data/campaign_built.json", "w"), indent=1)

# ---------------------------------------------------------------- content: monsters, encounters, NPCs, quests, lorecasts, world map
ART_BASE = {"revenant": dict(hp=66.0, dmg=13.0, speed=2.4, range=1.3, atk_cd=1.7, wind=0.5, rad=0.42, xp=1.4, height=1.95, speed_m=3.3),
            "slime": dict(hp=30.0, dmg=9.0, speed=2.5, range=1.0, atk_cd=1.2, wind=0.4, rad=0.36, xp=1.0, height=1.05, speed_m=3.4),
            "brute": dict(hp=130.0, dmg=20.0, speed=1.6, range=1.7, atk_cd=2.4, wind=0.75, rad=0.65, xp=2.4, height=2.55, speed_m=2.5)}
mt = json.load(open("data/monster_types.json")) if os.path.exists("data/monster_types.json") else {}
enc = json.load(open("data/encounters.json"))
npcs = json.load(open("data/npcs.json")) if os.path.exists("data/npcs.json") else {"safe_zones": ["crownsfall"], "zones": {}}
qdoc = json.load(open("data/quests.json"))
lore = json.load(open("data/lorecasts.json"))
lore["requires_quest"] = "Q_A01_06"
world = json.load(open("assets/zones/world.json"))

def main_route(act):
    zs = [z for z in DESIGN if int(z[3:5]) == act and not DESIGN[z].get("side")]
    if any("order" in DESIGN[z] for z in zs): return sorted(zs, key=lambda z: DESIGN[z].get("order", 99))
    return sorted(zs)
def level_band(zid):
    act = int(zid[3:5]); lo, hi = LEVELS[act]
    if DESIGN[zid].get("levels"): return list(DESIGN[zid]["levels"])
    mr = main_route(act)
    if "order" in DESIGN[zid]:
        i = max(0, mr.index(zid) - 1); n = max(1, len(mr) - 2)
        a = lo + (hi - lo) * i / n
        return [max(lo, int(a)), min(hi, int(a) + 1)]
    combat = [z for z in sorted(DESIGN) if int(z[3:5]) == act and DESIGN[z]["kind"] != "fixed" or (int(z[3:5]) == act and z != f"ACT0{act}_Z01" and DESIGN[z]["kind"] == "fixed")]
    i = combat.index(zid) if zid in combat else 0
    n = max(1, len(combat) - 1)
    a = lo + (hi - lo) * i / n
    return [max(lo, int(a)), min(hi, int(a) + 1)]

def xp_need(level): return int(60.0 * level ** 1.6)

QUESTS = []
for zid in sorted(DESIGN):
    if int(zid[3:5]) not in ACTS: continue
    d = DESIGN[zid]; key = d["key"]; reg = RG(zid); b = built.get(key, {})
    act = int(zid[3:5]); lv = level_band(zid)
    safe = (d["kind"] == "town" and not d.get("combat") and d["mech"][0] in ("talk", "arrive")) or key == "crownsfall"
    # monster families
    fam = []
    for i, (nm, art, tint) in enumerate(d.get("foes", [])):
        k = f"{key}_{i}"; base = dict(ART_BASE[art])
        mt[k] = {"name": nm, **{kk: base[kk] for kk in ("hp", "dmg", "speed", "range", "atk_cd", "wind", "rad", "xp")}, "art": art, "tint": list(tint), "height": base["height"], "speed_m": base["speed_m"]}
        fam.append(k)
    mech = d["mech"]; qid = reg["quest"]
    boss_key = None
    if mech[0] == "boss":
        boss_key = f"{key}_boss"; art = mech[2]; base = dict(ART_BASE[art])
        mt[boss_key] = {"name": mech[1], "hp": round(base["hp"] * (2.6 if art != "brute" else 1.4) + 20 * act, 1), "dmg": round(base["dmg"] * 1.6, 1), "speed": base["speed"], "range": base["range"] + 0.2,
                        "atk_cd": base["atk_cd"], "wind": base["wind"], "rad": base["rad"] + 0.1, "xp": 3.4 + 0.2 * act, "art": art,
                        "tint": list(d.get("boss_tint", d["foes"][0][2] if d.get("foes") else (1, 1, 1))), "height": d.get("boss_height", base["height"] * 1.18), "speed_m": base["speed_m"]}
        if fam: mt[boss_key]["adds"] = fam[0]
    # NPCs
    zl = []
    for i, n in enumerate(d.get("npcs", [])):
        nid, nm, model, tint, idle, vendor = n[:6]
        if len(n) > 7: at = [n[6], n[7]]
        elif d.get("npc_poi") is not None and b.get("pois"): at = b["pois"][min(d["npc_poi"], len(b["pois"]) - 1)]
        else: at = b.get("hub", [1920, 1200])
        at = [int(at[0] + 160 * i), int(at[1] + 60)]
        nd = {"id": nid, "name": nm, "model": model, "at": at, "tint": list(tint), "height": 1.8 if model == "knight" else 1.7, "idle": idle}
        if vendor: nd["vendor"] = True
        if d.get("art", {}).get(nid): nd["art"] = d["art"][nid]
        zl.append(nd)
    if zl: npcs["zones"][key] = zl
    if safe and key not in npcs["safe_zones"]: npcs["safe_zones"].append(key)
    # encounters
    pois = b.get("pois", [])
    fixed = []
    q = {"id": qid, "name": reg["quest_name"], "zone_id": zid, "giver": d.get("turnin", ""), "auto": not d.get("turnin") and mech[0] != "talk",
         "steps": {"active": {"objective": reg["quest_text"][:1].upper() + reg["quest_text"][1:], "markers": []}},
         "reward": {"xp": int(xp_need(lv[1]) * 0.6), "gold": 30 * lv[1] + 20},
         "talk": {}}
    if mech[0] == "talk":
        q["giver"] = mech[1]; q["talk_complete"] = True
        q["steps"]["active"]["markers"] = [{"zone": key, "npc": mech[1]}]
        nn = next(n for n in d["npcs"] if n[0] == mech[1])
        q["talk"]["active"] = [nn[1], reg["quest_text"][:1].upper() + reg["quest_text"][1:] + ".", reg["reveal"]]
    elif mech[0] == "collect":
        q["count"] = 3; q["item_name"] = mech[1]
        spots = (d.get("fixed_pois") or pois)[:3]
        while len(spots) < 3: spots.append(b.get("hub"))
        for i, gname in enumerate(mech[2]):
            at = spots[i]; page = f"{qid}_{i + 1}"
            fixed.append({"at": [at[0], at[1] + 60], "types": fam[1:2] * 2 if len(fam) > 1 else [], "elite": False, "guardian": f"{key}_g{i + 1}",
                          "elite_type": fam[i % len(fam)] if fam else "slime", "elite_name": gname, "page": page})
            q["steps"]["active"]["markers"].append({"zone": key, "at": at, "r": 430, "label": gname, "page": page})
    elif mech[0] == "boss":
        q["boss"] = f"{key}_boss_u"; q["count"] = 1
        at = d.get("fixed_boss") or (pois[d["boss_poi"]] if d.get("boss_poi") is not None and pois else (b.get("boss") or (pois[0] if pois else b.get("hub"))))
        fixed.append({"at": at, "types": [], "boss": f"{key}_boss_u", "boss_type": boss_key, "boss_name": mech[1], "needs_quest": qid})
        q["steps"]["active"]["markers"] = [{"zone": key, "at": at, "r": 560, "label": mech[1]}]
        q["boss_at"] = at
    elif mech[0] == "arrive":
        q["arrive_zone"] = key
    if d.get("turnin"):
        tn = next(n for n in d["npcs"] if n[0] == d["turnin"])
        q["steps"]["ready"] = {"objective": "Speak with " + tn[1], "markers": [{"zone": key, "npc": d["turnin"]}]}
        q["talk"]["active"] = [tn[1], reg["quest_text"][:1].upper() + reg["quest_text"][1:] + "."]
        q["talk"]["ready"] = [tn[1], reg["reveal"]]
    if mech[0] in ("collect", "boss"):
        q["reward"]["item_rarity"] = 1 if mech[0] == "collect" else (2 if d.get("epilogue") is None else 3)
    if d.get("memory"): q["epilogue"] = d["memory"]
    if d.get("also"): q["also"] = list(d["also"])
    if d.get("side"): q["side"] = True
    if d.get("epilogue"): q["epilogue"] = d["epilogue"]
    QUESTS.append(q)
    if d["kind"] != "fixed" or key == "whisperwood_forest":
        if not safe:
            keep = [[n["at"][0], n["at"][1], 700] for n in zl] + [[f_["at"][0], f_["at"][1], 700] for f_ in fixed]
            if d.get("lorecast") and pois: lp = pois[min(d["lorecast"]["poi"], len(pois) - 1)]; keep.append([lp[0], lp[1], 800])
            big = b.get("kind") in ("wild", "fixed") or key == "whisperwood_forest"
            small = b.get("W", 11520) < 10000
            spec = {"zone": key, "levels": lv, "packs": (20 if small else 30) if big else (14 if b.get("kind") != "town" else 18), "seed": abs(hash(key)) % 997,
                    "spacing": 1050 if big else 700,
                    "groups": [[5, [fam[0], fam[0]]], [3, [fam[1]] * 3], [3, [fam[0], fam[1], fam[1]]], [2, [fam[2]], True], [2, [fam[2], fam[0]]], [1, [fam[0]] * 3, True]] if len(fam) == 3 else [],
                    "fixed": fixed, "keep_clear": keep}
            json.dump(spec, open(f"data/encounter_specs/{key}.json", "w"), indent=1)
        else:
            enc.pop(key, None)
    # lorecast site
    if d.get("lorecast"):
        L = d["lorecast"]; lp = pois[min(L["poi"], len(pois) - 1)] if pois else b["hub"]
        res = L.get("skill_res")
        if not res:
            s = L["skill"]; res = f"res://data/skills/lore/{s['id']}.tres"
            nums = ",\n".join(f'"{k}": {v}' for k, v in s["nums"].items())
            open(f"data/skills/lore/{s['id']}.tres", "w").write(f'''[gd_resource type="Resource" script_class="SkillData" format=3]

[ext_resource type="Texture2D" path="res://assets/skill_tiles/{s['icon']}.png" id="1_lc"]
[ext_resource type="Script" path="res://scripts/game/data/skill_data.gd" id="2_lc"]

[resource]
script = ExtResource("2_lc")
id = "{s['id']}"
display_name = "{s['name']}"
icon = ExtResource("1_lc")
description = "{s['desc']}"
animation = "{s['anim']}"
shape = "{s['shape']}"
mana_cost = {s['cost']}
cooldown = {s['cd']}
numbers = {{
{nums}
}}
''')
            etype = f"{key}_echo"
        etype = f"{key}_echo"
        mt[etype] = {"name": L["echo"], "hp": 130.0, "dmg": 16.0 + 2 * act, "speed": 2.3, "range": 1.6, "atk_cd": 1.8, "wind": 0.55, "rad": 0.5, "xp": 3.0, "art": "revenant",
                     "tint": [1.0, 0.9, 0.62], "height": 2.2, "speed_m": 3.2}
        lore["sites"] = [x for x in lore["sites"] if x["id"] != L["id"]] + [{"id": L["id"], "zone": key, "at": lp, "figure": L["figure"], "remains": L["remains"],
            "skill": res, "echo": {"type": etype, "name": L["echo"]}, "lore": L["lore"]}]

# keep only lorecast sites whose zone is in the campaign (older placeholder dungeons are retired)
camp_keys = {d["key"] for d in DESIGN.values()}
lore["sites"] = [s for s in lore["sites"] if s["zone"] in camp_keys]

# chain the quests in register order: each quest's "next" is the next zone's quest
main_ids = []
for _a in range(1, 8): main_ids += [RG(z)["quest"] for z in main_route(_a)]
byid = {q["id"]: q for q in QUESTS}
for q in QUESTS:
    if q["id"] in main_ids:
        i = main_ids.index(q["id"])
        if i + 1 < len(main_ids): q["next"] = main_ids[i + 1]
QUESTS.sort(key=lambda q: (main_ids.index(q["id"]) if q["id"] in main_ids else 999, q["zone_id"]))
keep_ids = {q["id"] for q in QUESTS}
others = [q for q in qdoc["quests"] if q["id"].startswith("Q_A") and q["id"] not in keep_ids and int(q["id"][3:5]) not in ACTS]
qdoc["quests"] = QUESTS + others
qdoc["first"] = "Q_A01_01"
json.dump(qdoc, open("data/quests.json", "w"), indent=1)
json.dump(mt, open("data/monster_types.json", "w"), indent=1)
json.dump(npcs, open("data/npcs.json", "w"), indent=1)
json.dump(lore, open("data/lorecasts.json", "w"), indent=1)
json.dump(enc, open("data/encounters.json", "w"), indent=1)
for zid in todo:
    key = DESIGN[zid]["key"]
    if os.path.exists(f"data/encounter_specs/{key}.json") and not ((DESIGN[zid]["kind"] == "town" and not DESIGN[zid].get("combat") and DESIGN[zid]["mech"][0] in ("talk", "arrive")) or key == "crownsfall"):
        r = subprocess.run([sys.executable, "tools/gen_encounters.py", f"data/encounter_specs/{key}.json"], capture_output=True, text=True)
        print(r.stdout.strip() if r.returncode == 0 else "ENCOUNTERS FAILED " + key + r.stderr[-800:])

# world map: one act per page
nodes = [n for n in world["map"]["nodes"] if int(n.get("act", 1)) not in ACTS]
for zid in sorted(DESIGN):
    act = int(zid[3:5])
    if act not in ACTS: continue
    d = DESIGN[zid]; key = d["key"]; lv = level_band(zid)
    safe = (d["kind"] == "town" and not d.get("combat") and d["mech"][0] in ("talk", "arrive")) or key == "crownsfall"
    kind = "town" if key == "crownsfall" else KIND_ICON.get(d.get("biome", "forest"), "forest")
    nid = "whisperwood" if key == "whisperwood_forest" else key
    nodes.append({"id": nid, "zone": key, "name": RG(zid)["name"], "kind": kind, "at": list(POS[key]), "act": act, "locked": False,
                  "levels": "Sanctuary" if safe else "Monster level %d–%d" % (lv[0], lv[1]), "blurb": RG(zid)["look"] + ". " + RG(zid)["state"].capitalize() + "."})
world["map"]["nodes"] = nodes
nid_of = lambda k: "whisperwood" if k == "whisperwood_forest" else k
world["map"]["links"] = [[nid_of(a), nid_of(b)] for a, b in EDGES]
world["map"]["title"] = "Crownsfall and the Known Lands"
world["map"]["acts"] = [{"act": a, "name": ACT_NAMES[a]} for a in range(1, 8)]
world["lab_zones"] = sorted(set(world.get("lab_zones", [])) | {DESIGN[z]["key"] for z in DESIGN if DESIGN[z]["kind"] != "fixed" and int(z[3:5]) in ACTS} | {"whisperwood_forest"})
world["lab_zones"] = [z for z in world["lab_zones"] if z in camp_keys]
json.dump(world, open("assets/zones/world.json", "w"), indent=1, ensure_ascii=False)
print("campaign: %d quests, %d monster types, %d NPC zones, %d lorecast sites" % (len(QUESTS), len(mt), len(npcs["zones"]), len(lore["sites"])))
