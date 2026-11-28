#!/usr/bin/env python3
"""Scatter monster packs over a built kit zone and write them to data/encounters.json.

    python3 tools/gen_encounters.py <encounter spec .json>

Spec: {"zone": id, "levels": [lo, hi], "packs": n, "seed": s,
       "groups": [[weight, [types...], elite?], ...],   # a pack is one group picked by weight
       "fixed": [ ...pack dicts written as they are (guardians, bosses, set encounters)... ],
       "keep_clear": [[x, y, r], ...]}                     # spawn, waypoints, exits are added automatically
Packs land on walkable ground: off water (splat blue), clear of trunks/rocks (solids) and of each other.
"""
import json, math, os, random, sys
from PIL import Image
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.dirname(here)
spec = json.load(open(sys.argv[1]))
zid = spec["zone"]
z = json.load(open(os.path.join(root, "assets/zones", zid + ".json")))
W, H = z["size"]
splat = Image.open(os.path.join(root, "assets/zones", z["splat"])).convert("RGB")
sw, sh = splat.size
rng = random.Random(spec.get("seed", 7))
clear = [list(c) for c in spec.get("keep_clear", [])]
clear.append([z["spawn"][0], z["spawn"][1], 700])
for w in z.get("waypoints", []): clear.append([w["at"][0], w["at"][1], 450])
for e in z.get("exits", []):
    pts = e["poly"]; clear.append([sum(q[0] for q in pts) / len(pts), sum(q[1] for q in pts) / len(pts), 600])
fixed = spec.get("fixed", [])
for f in fixed: clear.append([f["at"][0], f["at"][1], 650])

def ok(x, y):
    if not (300 < x < W - 300 and 350 < y < H - 300): return False
    for dx in (-140, 0, 140):
        for dy in (-80, 0, 80):
            r, g, b = splat.getpixel((min(sw - 1, int((x + dx) / W * sw)), min(sh - 1, int((y + dy) / H * sh))))
            if b > 60: return False
    for s in z.get("solids", []):
        if math.hypot((x - s[0]), (y - s[1]) / 0.52) < s[2] + 160: return False
    for c in clear:
        if math.hypot(x - c[0], (y - c[1]) / 0.52) < c[2]: return False
    return True

groups = spec["groups"]; tot = sum(g[0] for g in groups)
packs = []
tries = 0
while len(packs) < spec["packs"] and tries < 40000:
    tries += 1
    x, y = rng.uniform(0, W), rng.uniform(0, H)
    if not ok(x, y): continue
    if any(math.hypot(x - p["at"][0], (y - p["at"][1]) / 0.52) < spec.get("spacing", 1100) for p in packs): continue
    k = rng.uniform(0, tot)
    for g in groups:
        k -= g[0]
        if k <= 0: break
    packs.append({"at": [int(x), int(y)], "types": list(g[1]), "elite": bool(g[2]) if len(g) > 2 else False})
enc_p = os.path.join(root, "data/encounters.json")
enc = json.load(open(enc_p))
enc[zid] = {"levels": spec["levels"], "packs": packs + fixed}
json.dump(enc, open(enc_p, "w"), indent=1)
print(zid, len(packs), "packs,", sum(len(p["types"]) for p in packs), "monsters, +", len(fixed), "fixed (", tries, "tries)")
