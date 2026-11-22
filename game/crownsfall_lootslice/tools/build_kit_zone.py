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
    if pt["layer"] != "water": path_mask = np.maximum(path_mask, m)       # paved/dirt clearings stay clear of planting
    if pt["layer"] == "water": water.append([pt["at"][0], pt["at"][1], pt["r"], pt["r"] * pt.get("squash", 0.5)])
os.makedirs(f"assets/zones/{name}", exist_ok=True)
Image.fromarray((splat * 255).astype(np.uint8)).save(f"assets/zones/{name}/splat.png")

dist_path = cv2.distanceTransform((path_mask < 0.5).astype(np.uint8), cv2.DIST_L2, 5) * SPLAT_K
def dist_path_lk(lw, lh): return cv2.resize(dist_path, (lw, lh), interpolation=cv2.INTER_LINEAR)
def dist_path_at(u, v): return dist_path[min(sh - 1, max(0, int(v / SPLAT_K))), min(sw - 1, max(0, int(u / SPLAT_K)))]
placed = []                                             # {prop, at, scale, flip}
occupied = []                                           # (u, v, r) keep-out discs for scatter
ZPPM = float(spec["ppm"])
def add(prop, at, scale=1.0, flip=False, keep=None):
    c = cat["props"][prop]
    if "ppm" in c: scale = scale * ZPPM / c["ppm"]          # v2 kits: true size in metres, any zone scale
    placed.append({"prop": prop, "at": [round(at[0]), round(at[1])], "scale": round(scale, 4), "flip": flip})
    if c["kind"] == "decal":
        return
    r = keep if keep is not None else max(c["size"][0] * scale * 0.42, c["footprint_px"] * scale)
    occupied.append((at[0], at[1], r))
setpieces = []
for sp in spec.get("setpieces", []):
    add(sp["prop"], sp["at"], sp.get("scale", 1.0), keep=cat["props"][sp["prop"]]["size"][0] * sp.get("scale", 1.0) * 0.6)
    setpieces.append(len(placed) - 1)
for p in spec.get("pois", []):
    add(p["prop"], p["at"], p.get("scale", 1.0))
for w in water: occupied.append((w[0], w[1], w[2] * 1.1))
def pick(names): return names[rnd.randrange(len(names))] if isinstance(names, list) else names
for q in spec.get("place", []):                      # deliberate composition: [prop, u, v, scale?, flip?]
    add(q[0], (q[1], q[2]), q[3] if len(q) > 3 else 1.0, bool(q[4]) if len(q) > 4 else False, keep=0)
def clear_of_solid(u, v, gap):
    for pl in placed:
        c = cat["props"][pl["prop"]]
        if c["kind"] in ("tree", "rock") and (u - pl["at"][0]) ** 2 + ((v - pl["at"][1]) / 0.6) ** 2 < (c["footprint_px"] * pl["scale"] + gap) ** 2: return False
    return True
for ed in spec.get("edges", []):                     # planting along both edges of a path
    pts = np.array(spec["paths"][ed["path"]]["pts"], np.float32); half = spec["paths"][ed["path"]]["width"] * 0.5
    seg = np.linalg.norm(np.diff(pts, axis=0), axis=1); L = seg.sum(); t = rnd.uniform(0, ed["spacing"])
    while t < L:
        i = int(np.searchsorted(np.cumsum(seg), t)); i = min(i, len(seg) - 1)
        f = (t - (np.cumsum(seg)[i] - seg[i])) / seg[i]; P = pts[i] + (pts[i + 1] - pts[i]) * f
        d_ = (pts[i + 1] - pts[i]) / seg[i]; nrm = np.array([-d_[1], d_[0]])
        for side in (-1, 1):
            if rnd.random() > ed.get("density", 0.8): continue
            off = half + ed.get("offset", 40) + rnd.uniform(0, ed.get("jitter", 60))
            Q = P + nrm * side * off * np.array([1.0, 0.55])
            if 0 < Q[0] < W and 0 < Q[1] < H and clear_of_solid(Q[0], Q[1], 20) and dist_path_at(Q[0], Q[1]) >= ed.get("min_gap", 0):
                add(pick(ed["props"]), (float(Q[0]), float(Q[1])), rnd.uniform(*ed.get("scale", [0.8, 1.15])), rnd.random() < 0.5, keep=0)
        t += ed["spacing"] * rnd.uniform(0.7, 1.3)
for rg in spec.get("rings", []):                     # undergrowth / decals around tree bases and rocks
    for k in range(rg["count"]):
        a_ = rnd.uniform(0, 2 * math.pi); r_ = rnd.uniform(*rg["r"])
        u, v = rg["at"][0] + math.cos(a_) * r_, rg["at"][1] + math.sin(a_) * r_ * 0.55
        if dist_path_at(u, v) < rg.get("keep_off_paths", 0): continue
        add(pick(rg["props"]), (u, v), rnd.uniform(*rg.get("scale", [0.8, 1.15])), rnd.random() < 0.5, keep=0)
for sc in spec.get("scatter", []):
    n, tries = 0, 0
    while n < sc["count"] and tries < sc["count"] * 400:
        tries += 1
        u, v = rnd.uniform(60, W - 60), rnd.uniform(120, H - 30)
        if dist_path_at(u, v) < sc.get("keep_off_paths", 200): continue
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
for wp in spec.get("waypoints", []):
    waypoints.append({"id": wp["id"], "name": wp["name"], "at": wp["at"], "centre_of": wp["at"], "radius_px": wp.get("radius_px", 200), "rot_deg": wp.get("rot_deg", 22.9)})
# collision: per-prop footprints + set-piece blockers + water
solids = []
for i, p in enumerate(placed):
    c = cat["props"][p["prop"]]
    if c["kind"] == "decal": continue
    if c.get("footprint_px", 0) > 0: solids.append([p["at"][0], p["at"][1], round(c["footprint_px"] * p["scale"])])
    for b in c.get("blockers", []):
        q = local_to_zone(i, b[:2]); solids.append([q[0], q[1], round(b[2] * p["scale"])])
for w in water: solids.append([w[0], w[1], round(w[2] * 0.9), round(w[3] * 0.9)])
# light map (R: light/2, 0.5 = neutral) and fx map (R mist, G shafts), LK painting px per texel
light_name = fx_name = None
if "light" in spec:
    LS = spec["light"]; LK = 2; lw, lh = W // LK, H // LK
    rs = np.random.RandomState(spec.get("seed", 1))
    def fbm(scale_px, octaves=4):
        acc = np.zeros((lh, lw), np.float32); amp = 1.0; tot = 0
        for o in range(octaves):
            g = rs.rand(int(lh / (scale_px / LK)) + 3, int(lw / (scale_px / LK)) + 3).astype(np.float32)
            acc += amp * cv2.resize(g, (lw, lh), interpolation=cv2.INTER_CUBIC); tot += amp; amp *= 0.5; scale_px /= 2
        return acc / tot
    shadow = np.zeros((lh, lw), np.float32); ao = np.zeros((lh, lw), np.float32); trees_d = np.zeros((lh, lw), np.float32)
    a_sh, b_sh = LS.get("shift", [0.30, 0.16])          # canopy shadow offset per row of height (sun upper-left)
    for pl in placed:
        c = cat["props"][pl["prop"]]; sc_ = pl["scale"] / LK
        fx_ = (c["size"][0] - c["foot"][0]) if pl["flip"] else c["foot"][0]
        if c["kind"] == "tree":
            al = np.asarray(Image.open(os.path.join(kit_dir, c["image"])).getchannel("A"), np.float32) / 255
            if pl["flip"]: al = al[:, ::-1]
            fy_ = c["foot"][1]
            al[int(fy_ - 0.32 * fy_):] = 0                      # canopy only (trunk shadow is the contact shadow)
            # image px -> light texels: canopy point (x, y) lands at foot + (x - fx + a*(fy - y), b*(fy - y))
            ox, oy = pl["at"][0] / LK, pl["at"][1] / LK
            M = np.float32([[sc_, -a_sh * sc_, ox - fx_ * sc_ + a_sh * fy_ * sc_], [0, -b_sh * sc_, oy + b_sh * fy_ * sc_]])
            shadow = np.maximum(shadow, cv2.warpAffine(al, M, (lw, lh), flags=cv2.INTER_LINEAR))
            cv2.circle(trees_d, (int(ox), int(oy)), max(1, int(c["size"][0] * sc_ * 0.35)), 1.0, -1)
        if c["kind"] in ("tree", "rock", "bush"):
            r = c["size"][0] * sc_ * (0.22 if c["kind"] == "tree" else 0.42)
            cv2.ellipse(ao, (int(pl["at"][0] / LK), int(pl["at"][1] / LK)), (max(1, int(r)), max(1, int(r * 0.45))), 0, 0, 360, 1.0, -1)
    dapple = np.clip((fbm(LS.get("dapple_px", 40), 3) - 0.45) * 5.0, 0, 1)       # sun flecks through the leaves
    shadow = cv2.GaussianBlur(np.clip((shadow - 0.3) * 2.0, 0, 1), (0, 0), 1.2) * (1 - 0.6 * dapple)
    ao = cv2.GaussianBlur(ao, (0, 0), 10)
    # the overhead canopy beyond the placed trees: a dappled shade field over the whole zone, thinner where open
    # stamped from the kit's own canopy silhouettes (leaf-shaped edges, like the shade painted in W1)
    canopies = []
    for k, c in cat["props"].items():
        if c["kind"] == "tree":
            al = np.asarray(Image.open(os.path.join(kit_dir, c["image"])).getchannel("A"), np.float32) / 255
            al = al[: int(c["foot"][1] * 0.62)]                                   # canopy rows
            canopies.append(al)
    over = np.zeros((lh, lw), np.float32)
    rsc = random.Random(spec.get("seed", 1) + 99)
    n_st = int(W * H / 1e6 * LS.get("over_density", 6))
    for _ in range(n_st):
        al = canopies[rsc.randrange(len(canopies))]
        if rsc.random() < 0.5: al = al[:, ::-1]
        sc2 = rsc.uniform(0.18, 0.32) * ZPPM / 71.8
        w2, h2 = max(2, int(al.shape[1] * sc2)), max(2, int(al.shape[0] * sc2 * 0.55))  # canopy seen from below: squashed
        st_ = cv2.resize(al, (w2, h2), interpolation=cv2.INTER_AREA)
        x0, y0 = rsc.randrange(-w2 // 2, lw), rsc.randrange(-h2 // 2, lh)
        xa, ya, xb, yb = max(0, x0), max(0, y0), min(lw, x0 + w2), min(lh, y0 + h2)
        if xb > xa and yb > ya: over[ya:yb, xa:xb] = np.maximum(over[ya:yb, xa:xb], st_[ya - y0:yb - y0, xa - x0:xb - x0])
    over = np.clip((over - 0.35) * 2.5, 0, 1) * LS.get("overhead", 0.0)
    openm = np.zeros((lh, lw), np.float32)
    for o_ in LS.get("open", []):
        cv2.ellipse(openm, (int(o_[0] / LK), int(o_[1] / LK)), (int(o_[2] / LK), int(o_[2] * 0.52 / LK)), 0, 0, 360, o_[3], -1)
    openm = cv2.GaussianBlur(openm, (0, 0), 25)
    shadow = np.maximum(shadow, cv2.GaussianBlur(over, (0, 0), 1.0) * (1 - openm))
    pools = (fbm(900, 3) - 0.5) * LS.get("pools", 0.25)                          # broad sunlit / shaded areas
    light = (1.0 + pools) * (1 - LS.get("canopy", 0.5) * np.clip(shadow, 0, 1)) * (1 - LS.get("contact", 0.45) * np.clip(ao, 0, 1))
    light *= LS.get("exposure", 1.04)
    Image.fromarray((np.clip(light / 2, 0, 1) * 255).astype(np.uint8)).save(f"assets/zones/{name}/light.png")
    light_name = f"{name}/light.png"
    for pl in placed:                                   # undergrowth and rocks take the light at their foot
        if cat["props"][pl["prop"]]["kind"] in ("bush", "rock"):
            pl["tint"] = round(float(np.clip(light[min(lh - 1, int(pl["at"][1] / LK)), min(lw - 1, int(pl["at"][0] / LK))], 0.55, 1.1)), 3)
    # mist: pooled among tree bases and toward the canopy edges; shafts where the spec asks
    mist = cv2.GaussianBlur(trees_d, (0, 0), 80) * LS.get("tree_mist", 1.0) * np.clip(fbm(500, 3) * 1.6 - 0.3, 0, 1)
    for m_ in LS.get("mist", []):
        e = np.zeros((lh, lw), np.float32); cv2.ellipse(e, (int(m_[0] / LK), int(m_[1] / LK)), (int(m_[2] / LK), int(m_[2] * 0.5 / LK)), 0, 0, 360, m_[3] if len(m_) > 3 else 1.0, -1)
        mist = np.maximum(mist, cv2.GaussianBlur(e, (0, 0), m_[2] / LK * 0.35))
    mist *= np.clip(dist_path_lk(lw, lh) / 160.0, 0.15, 1)          # keep the walkways clear
    shafts = np.zeros((lh, lw), np.float32)
    for s_ in LS.get("shafts", []):
        e = np.zeros((lh, lw), np.float32); cv2.ellipse(e, (int(s_[0] / LK), int(s_[1] / LK)), (int(s_[2] / LK), int(s_[2] * 0.6 / LK)), -35, 0, 360, 1.0, -1)
        shafts = np.maximum(shafts, cv2.GaussianBlur(e, (0, 0), s_[2] / LK * 0.4))
    for pl in placed:                                   # props standing in mist pick it up at their base
        if cat["props"][pl["prop"]]["kind"] in ("tree", "bush", "rock"):
            mv = float(np.clip(mist[min(lh - 1, int(pl["at"][1] / LK)), min(lw - 1, int(pl["at"][0] / LK))], 0, 1))
            if mv > 0.02: pl["mist"] = round(mv * 0.45, 3)
    fx = np.dstack([np.clip(mist, 0, 1), np.clip(shafts, 0, 1), np.zeros_like(mist)])
    Image.fromarray((fx * 255).astype(np.uint8)).save(f"assets/zones/{name}/fx.png"); fx_name = f"{name}/fx.png"
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
if light_name: rt["light"] = light_name; rt["fx"] = fx_name
if "walkable" in spec: rt["walkable"] = spec["walkable"]
json.dump(rt, open(f"assets/zones/{name}.json", "w"), indent=1)
print(name, W, "x", H, "props", len(placed), "solids", len(solids), "exits", len(exits), "waypoints", len(waypoints))
