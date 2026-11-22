"""Assemble a zone from a kit (free, local): ground layers, paths, prop placements, collision and minimap overview.

Input  assets/zones/src/<zone>.kitzone.json:
  {"name", "kit": "assets/kit/forest", "size": [W, H] painting px, "ppm", "pitch", "hero_px_1080",
   "ground_base": "grass",
   "paths": [{"pts": [[u, v], ...], "width": px, "layer": "flagstone"}],
   "patches": [{"at": [u, v], "r": px, "layer": "dirt"|"flagstone"|"water"}],
   "setpieces": [{"prop": name, "at": [u, v] (foot point), "scale": 1}],
   "pois": [{"prop": name, "at": [u, v], "scale": 1, "name": "..."}],
   "scatter": [{"prop": name, "count": n, "min_dist": px, "scale": [a, b], "keep_off_paths": px}],
   "exits": [{"name", "to", "setpiece": index, "arrive": [u, v]}], "waypoint_setpiece": index, "waypoint": {"id", "name"},
   "spawn": [u, v], "seed": 1}
Output assets/zones/<zone>.json (runtime) + assets/zones/<zone>/splat.png (R=flagstone G=dirt B=water) + overview.png.
Every placed prop records its footprint (collision circle) and occlusion, so movement is free between props and the
hero hides behind trees and rocks. usage: python build_kit_zone.py <src.kitzone.json>"""
import json, math, os, random, sys
import numpy as np, cv2
from PIL import Image

spec = json.load(open(sys.argv[1]))
name = os.path.basename(sys.argv[1]).replace(".kitzone.json", "")
kit_dir = spec["kit"]
cat = json.load(open(os.path.join(kit_dir, "catalog.json")))
W, H = spec["size"]; rnd = random.Random(spec.get("seed", 1))
SPLAT_K = 8                                            # 1 splat px = 8 painting px
sw, sh = W // SPLAT_K, H // SPLAT_K
splat = np.zeros((sh, sw, 3), np.float32)
CH = {"flagstone": 0, "dirt": 1, "water": 2}
noise = cv2.resize(np.random.RandomState(spec.get("seed", 1)).rand(sh // 6 + 2, sw // 6 + 2).astype(np.float32), (sw, sh), interpolation=cv2.INTER_CUBIC)
def stamp(mask, ch):
    m = cv2.GaussianBlur(mask, (0, 0), 3.0)
    m = np.clip((m - 0.5 + 0.35 * (noise - 0.5)) * 2.2 + 0.5, 0, 1)   # ragged, organic edges
    splat[..., ch] = np.maximum(splat[..., ch], m)
path_mask = np.zeros((sh, sw), np.float32)
for p in spec.get("paths", []):
    pts = (np.array(p["pts"], np.float32) / SPLAT_K).astype(np.int32)
    m = np.zeros((sh, sw), np.float32)
    cv2.polylines(m, [pts], False, 1.0, thickness=max(1, int(p["width"] / SPLAT_K)), lineType=cv2.LINE_AA)
    stamp(m, CH[p.get("layer", "flagstone")]); path_mask = np.maximum(path_mask, m)
water = []
for pt in spec.get("patches", []):
    m = np.zeros((sh, sw), np.float32)
    rx = pt["r"] / SPLAT_K; ry = rx * pt.get("squash", 0.5)
    cv2.ellipse(m, (int(pt["at"][0] / SPLAT_K), int(pt["at"][1] / SPLAT_K)), (int(rx), int(ry)), 0, 0, 360, 1.0, -1, cv2.LINE_AA)
    stamp(m, CH[pt["layer"]])
    if pt["layer"] == "water": water.append([pt["at"][0], pt["at"][1], pt["r"], pt["r"] * pt.get("squash", 0.5)])
os.makedirs(f"assets/zones/{name}", exist_ok=True)
Image.fromarray((splat * 255).astype(np.uint8)).save(f"assets/zones/{name}/splat.png")

placed = []                                             # {prop, at, scale, flip}
occupied = []                                           # (u, v, r) keep-out discs for scatter
def add(prop, at, scale=1.0, flip=False, keep=None):
    c = cat["props"][prop]
    placed.append({"prop": prop, "at": [round(at[0]), round(at[1])], "scale": scale, "flip": flip})
    r = keep if keep is not None else max(c["size"][0] * scale * 0.42, c["footprint_px"] * scale)
    occupied.append((at[0], at[1], r))
setpieces = []
for sp in spec.get("setpieces", []):
    add(sp["prop"], sp["at"], sp.get("scale", 1.0), keep=cat["props"][sp["prop"]]["size"][0] * sp.get("scale", 1.0) * 0.6)
    setpieces.append(len(placed) - 1)
for p in spec.get("pois", []):
    add(p["prop"], p["at"], p.get("scale", 1.0))
for w in water: occupied.append((w[0], w[1], w[2] * 1.1))
dist_path = cv2.distanceTransform((path_mask < 0.5).astype(np.uint8), cv2.DIST_L2, 5) * SPLAT_K
for sc in spec.get("scatter", []):
    n, tries = 0, 0
    while n < sc["count"] and tries < sc["count"] * 400:
        tries += 1
        u, v = rnd.uniform(60, W - 60), rnd.uniform(120, H - 30)
        if dist_path[min(sh - 1, int(v / SPLAT_K)), min(sw - 1, int(u / SPLAT_K))] < sc.get("keep_off_paths", 200): continue
        if any((u - a) ** 2 + (v - b) ** 2 < (r + sc["min_dist"] * 0.5) ** 2 for a, b, r in occupied): continue
        s = rnd.uniform(*sc.get("scale", [1, 1]))
        add(sc["prop"], (u, v), s, rnd.random() < 0.5, keep=sc["min_dist"] * 0.5)
        n += 1
    print(sc["prop"], "placed", n)

def local_to_zone(pi, pt):
    p = placed[pi]; c = cat["props"][p["prop"]]; s = p["scale"]
    dx = (pt[0] - c["foot"][0]) * s * (-1 if p["flip"] else 1)
    return [round(p["at"][0] + dx), round(p["at"][1] + (pt[1] - c["foot"][1]) * s)]
exits = []
for ex in spec.get("exits", []):
    pi = setpieces[ex["setpiece"]]; c = cat["props"][placed[pi]["prop"]]
    exits.append({"name": ex["name"], "to": ex["to"], "arrive": ex["arrive"],
                  "poly": [local_to_zone(pi, q) for q in c["trigger"]], "aura": {"poly": [local_to_zone(pi, q) for q in c["aura"]]}})
waypoints = []
if "waypoint_setpiece" in spec:
    pi = setpieces[spec["waypoint_setpiece"]]; c = cat["props"][placed[pi]["prop"]]
    at = local_to_zone(pi, c["waypoint"])
    waypoints.append({"id": spec["waypoint"]["id"], "name": spec["waypoint"]["name"], "at": at, "centre_of": at, "radius_px": spec["waypoint"].get("radius_px", 200)})
# collision: per-prop footprints + set-piece blockers + water
solids = []
for i, p in enumerate(placed):
    c = cat["props"][p["prop"]]
    if c.get("footprint_px", 0) > 0: solids.append([p["at"][0], p["at"][1], round(c["footprint_px"] * p["scale"])])
    for b in c.get("blockers", []):
        q = local_to_zone(i, b[:2]); solids.append([q[0], q[1], round(b[2] * p["scale"])])
for w in water: solids.append([w[0], w[1], round(w[2] * 0.9), round(w[3] * 0.9)])
# minimap overview (1/8 scale): ground colours + props
ov = np.zeros((sh, sw, 3), np.float32)
gcol = {k: np.asarray(Image.open(os.path.join(kit_dir, g["image"])).convert("RGB"), np.float32).mean((0, 1)) for k, g in cat["ground"].items()}
ov[:] = gcol[spec.get("ground_base", "grass")]
for k, ch in (("flagstone", 0), ("dirt", 1)):
    ov = ov * (1 - splat[..., ch:ch + 1]) + gcol[k] * splat[..., ch:ch + 1]
ov = ov * (1 - splat[..., 2:3]) + np.array([70, 110, 130], np.float32) * splat[..., 2:3]
ovi = Image.fromarray(ov.clip(0, 255).astype(np.uint8)).convert("RGBA")
for p in sorted(placed, key=lambda p: p["at"][1]):
    c = cat["props"][p["prop"]]; im = Image.open(os.path.join(kit_dir, c["image"])).convert("RGBA")
    s = p["scale"] / SPLAT_K; w2, h2 = max(1, int(c["size"][0] * s)), max(1, int(c["size"][1] * s))
    im = im.resize((w2, h2), Image.LANCZOS)
    if p["flip"]: im = im.transpose(Image.FLIP_LEFT_RIGHT)
    fx = c["size"][0] - c["foot"][0] if p["flip"] else c["foot"][0]
    ovi.alpha_composite(im, (max(0, int(p["at"][0] / SPLAT_K - fx * s)), max(0, int(p["at"][1] / SPLAT_K - c["foot"][1] * s))))
ovi.convert("RGB").save(f"assets/zones/{name}/overview.png")
rt = {k: spec[k] for k in ("name", "size", "ppm", "pitch", "hero_px_1080", "spawn") if k in spec}
rt.update({"kit": "res://" + kit_dir, "ground_base": spec.get("ground_base", "grass"), "splat": f"{name}/splat.png",
           "splat_k": SPLAT_K, "overview": f"{name}/overview.png", "props": placed, "solids": solids,
           "walkable": [[[40, 100], [W - 40, 100], [W - 40, H - 20], [40, H - 20]]], "exits": exits, "waypoints": waypoints,
           "targets": spec.get("targets", []), "ground_ratio": 0.51})
json.dump(rt, open(f"assets/zones/{name}.json", "w"), indent=1)
print(name, W, "x", H, "props", len(placed), "solids", len(solids), "exits", len(exits), "waypoints", len(waypoints))
