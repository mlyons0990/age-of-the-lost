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

_img_cache = {}
def img_alpha(rel):
    if rel not in _img_cache:
        _img_cache[rel] = np.asarray(Image.open(os.path.join(kit_dir, rel)).getchannel("A") if not rel.endswith("_shadow.png") else Image.open(os.path.join(kit_dir, rel)))
    return _img_cache[rel]
def warp_max(dst, src, M, factor=1.0):
    """dst = max(dst, warpAffine(src, M) * factor), computed only over the warped bounding box (fast on big maps)."""
    h, w = src.shape[:2]
    corners = np.array([[0, 0, 1], [w, 0, 1], [0, h, 1], [w, h, 1]], np.float32) @ M.T
    x0, y0 = np.floor(corners.min(0)).astype(int) - 2; x1, y1 = np.ceil(corners.max(0)).astype(int) + 2
    x0, y0 = max(0, x0), max(0, y0); x1, y1 = min(dst.shape[1], x1), min(dst.shape[0], y1)
    if x1 <= x0 or y1 <= y0: return
    M2 = M.copy(); M2[0, 2] -= x0; M2[1, 2] -= y0
    roi = cv2.warpAffine(src, M2, (x1 - x0, y1 - y0), flags=cv2.INTER_LINEAR)
    np.maximum(dst[y0:y1, x0:x1], roi * factor, out=dst[y0:y1, x0:x1])
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
def catmull(pts, n=12):
    pts = np.asarray(pts, np.float32); P = np.vstack([pts[0], pts, pts[-1]]); out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for t in np.linspace(0, 1, n, endpoint=False):
            t2, t3 = t * t, t * t * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(P[-2]); return np.array(out, np.float32)
trail_rs = np.random.RandomState(spec.get("seed", 1) + 3)
for p in spec.get("paths", []):
    m = np.zeros((sh, sw), np.float32)
    if p.get("style") == "trail" or not p.get("straight", False):
        # worn trail: smooth meandering curve, width that swells and narrows, tapering out where it ends
        c_ = catmull(p["pts"], 24)
        seg = np.linalg.norm(np.diff(c_, axis=0), axis=1); L = np.concatenate([[0], np.cumsum(seg)]); tot = L[-1]
        trail = p.get("style") == "trail"
        k = max(4, int(tot / (350 if trail else 520))); wob = np.interp(L, np.linspace(0, tot, k), trail_rs.uniform(-1, 1, k))
        wid = np.interp(L, np.linspace(0, tot, k), trail_rs.uniform(0.7, 1.2, k) if trail else trail_rs.uniform(0.8, 1.25, k)) * p["width"]
        # a second, finer wobble so roads do not read as smooth splines
        k2 = max(8, int(tot / 160)); wob = wob + 0.35 * np.interp(L, np.linspace(0, tot, k2), trail_rs.uniform(-1, 1, k2))
        wob *= p.get("wander", 1.0 if trail else 1.6)
        taper = np.ones_like(L)
        if p.get("taper_start", False): taper *= np.clip(L / (0.18 * tot), 0.15, 1)
        if p.get("taper_end", trail): taper *= np.clip((tot - L) / (0.22 * tot), 0.1, 1)
        d_ = np.gradient(c_, axis=0); d_ /= np.maximum(np.linalg.norm(d_, axis=1, keepdims=True), 1e-6)
        nrm = np.stack([-d_[:, 1], d_[:, 0]], 1)
        cen = c_ + nrm * (wob * p["width"] * 0.35)[:, None] * np.array([1.0, 0.55])
        for (x, y), r in zip(cen / SPLAT_K, wid * taper / 2 / SPLAT_K):
            cv2.ellipse(m, (int(x), int(y)), (max(1, int(r)), max(1, int(r * 0.6))), 0, 0, 360, 1.0, -1, cv2.LINE_AA)
        m = cv2.GaussianBlur(m, (0, 0), 1.5)
        p["_curve"] = (cen).tolist()
    else:
        pts = (np.array(p["pts"], np.float32) / SPLAT_K).astype(np.int32)
        cv2.polylines(m, [pts], False, 1.0, thickness=max(1, int(p["width"] / SPLAT_K)), lineType=cv2.LINE_AA)
    stamp(m, CH[p.get("layer", "flagstone")]); path_mask = np.maximum(path_mask, m)
water = []
blob_rs = np.random.RandomState(spec.get("seed", 1) + 11)
def blob(m, cx, cy, rx, ry, round_=False):
    """An irregular clearing / pool: a lobed outline (three harmonics + jitter), stretched and turned at random."""
    if round_:
        cv2.ellipse(m, (int(cx), int(cy)), (int(rx), int(ry)), 0, 0, 360, 1.0, -1, cv2.LINE_AA); return
    th = np.linspace(0, 2 * np.pi, 56, endpoint=False)
    amp = [blob_rs.uniform(0.10, 0.22), blob_rs.uniform(0.06, 0.14), blob_rs.uniform(0.03, 0.09)]
    ph = blob_rs.uniform(0, 2 * np.pi, 3)
    rr = 1 + sum(a * np.sin((i + 1) * th + p_) for i, (a, p_) in enumerate(zip(amp, ph))) + blob_rs.uniform(-0.04, 0.04, th.size)
    stretch = blob_rs.uniform(0.8, 1.25); rot = blob_rs.uniform(-0.6, 0.6)
    x = np.cos(th) * rr * rx * stretch; y = np.sin(th) * rr * ry / stretch
    xr = x * np.cos(rot) - y * np.sin(rot) * (rx / max(ry, 1)) * 0.35; yr = y + x * np.sin(rot) * (ry / max(rx, 1)) * 0.35
    cv2.fillPoly(m, [np.stack([cx + xr, cy + yr], 1).astype(np.int32)], 1.0, cv2.LINE_AA)
for pt in spec.get("patches", []):
    m = np.zeros((sh, sw), np.float32)
    rx = pt["r"] / SPLAT_K; ry = rx * pt.get("squash", 0.5)
    blob(m, pt["at"][0] / SPLAT_K, pt["at"][1] / SPLAT_K, rx, ry, pt.get("round", False))
    stamp(m, CH[pt["layer"]])
    if pt["layer"] != "water": path_mask = np.maximum(path_mask, m)       # paved/dirt clearings stay clear of planting
    if pt["layer"] == "water": water.append([pt["at"][0], pt["at"][1], pt["r"], pt["r"] * pt.get("squash", 0.5)])
os.makedirs(f"assets/zones/{name}", exist_ok=True)
# the Between ("void"): only the islands and bridges (paths + clearings) are ground; everything else is the violet
# void (drawn as the zone's water colour, solid like water), with a ragged lip so islands do not read as stamps
if spec.get("void"):
    edge = cv2.GaussianBlur(np.clip(path_mask * 1.8, 0, 1), (0, 0), 2.0)
    vm = np.clip((0.5 - edge + 0.45 * (noise - 0.5)) * 3.0 + 0.5, 0, 1)
    splat[..., 2] = np.maximum(splat[..., 2], vm)

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
# organic set dressing: props hugging the edge of each clearing ("rim") and themed clusters at points of interest
# ("dress": [{"at", "r", "props", "n", "scale"}]): the eye reads landmarks, not stamped circles
dress_rs = random.Random(spec.get("seed", 1) + 23)
def _free_spot(u, v, rad, on_path=False):
    if not (40 < u < W - 40 and 40 < v < H - 40): return False
    x, y = min(sw - 1, int(u / SPLAT_K)), min(sh - 1, int(v / SPLAT_K))
    if splat[y, x, 2] > 0.3 or (path_mask[y, x] > 0.35 and not on_path): return False
    return not any((u - a_) ** 2 + (v - b_) ** 2 < (r_ * 0.6 + rad) ** 2 for a_, b_, r_ in occupied)
rim = spec.get("rim")
if rim:
    for pt in spec.get("patches", []):
        if pt["layer"] == "water" or pt.get("no_rim"): continue
        n = int(pt["r"] / 90 * rim.get("density", 1.0))
        for i in range(n):
            if dress_rs.random() > rim.get("chance", 0.55): continue
            a_ = dress_rs.uniform(0, 2 * math.pi)
            rr = pt["r"] * dress_rs.uniform(1.05, 1.35)
            u, v = pt["at"][0] + math.cos(a_) * rr, pt["at"][1] + math.sin(a_) * rr * pt.get("squash", 0.5)
            pr = dress_rs.choice(rim["props"])
            if _free_spot(u, v, 40): add(pr, (u, v), dress_rs.uniform(*rim.get("scale", [0.8, 1.2])), dress_rs.random() < 0.5)
for d in spec.get("dress", []):
    for i in range(d.get("n", 8)):
        for _try in range(12):
            a_ = dress_rs.uniform(0, 2 * math.pi); rr = d["r"] * math.sqrt(dress_rs.random())
            u, v = d["at"][0] + math.cos(a_) * rr, d["at"][1] + math.sin(a_) * rr * 0.55
            if _free_spot(u, v, 30, d.get("on_path", False)):
                add(dress_rs.choice(d["props"]), (u, v), dress_rs.uniform(*d.get("scale", [0.8, 1.25])), dress_rs.random() < 0.5); break
for q in spec.get("place", []):                      # deliberate composition: [prop, u, v, scale?, flip?]
    add(q[0], (q[1], q[2]), q[3] if len(q) > 3 else 1.0, bool(q[4]) if len(q) > 4 else False, keep=None if spec.get("place_keep") else 0)
def paving_overlap(prop, at, scale, flip):
    """Fraction of a tree/rock's base (roots, lowest 30% of the image) that lies on paths or paved clearings."""
    c = cat["props"][prop]; s_ = scale * (ZPPM / c["ppm"] if "ppm" in c else 1.0)
    al = img_alpha(c["image"])
    if flip: al = al[:, ::-1]
    fx_ = (c["size"][0] - c["foot"][0]) if flip else c["foot"][0]
    y0 = int(c["size"][1] * 0.70)
    ys, xs = np.where(al[y0:] > 128)
    if len(ys) == 0: return 0.0
    u = ((xs - fx_) * s_ + at[0]) / SPLAT_K; v = ((ys + y0 - c["foot"][1]) * s_ + at[1]) / SPLAT_K
    ok = (u >= 0) & (u < sw) & (v >= 0) & (v < sh)
    if not ok.any(): return 0.0
    return float((path_mask[v[ok].astype(int), u[ok].astype(int)] > 0.3).mean())
bad = []
for q in spec.get("place", []):
    if cat["props"][q[0]]["kind"] in ("tree", "rock"):
        ov = paving_overlap(q[0], (q[1], q[2]), q[3] if len(q) > 3 else 1.0, bool(q[4]) if len(q) > 4 else False)
        if ov > spec.get("max_paving_overlap", 0.03): bad.append(f"{q[0]} at ({q[1]},{q[2]}): {ov:.0%} of its base is on the path")
if bad:
    raise SystemExit("Trees/rocks placed on paths (move them):\n  " + "\n  ".join(bad))
def dress_roots():
    """Ground round every tree: moss/clover/leaf litter under the root tips and a few tufts at the ends, so roots
    grow out of the ground instead of sitting on it."""
    rd = spec.get("root_dressing")
    if not rd: return
    for pl in [p_ for p_ in placed if cat["props"][p_["prop"]]["kind"] == "tree"]:
        c = cat["props"][pl["prop"]]
        al = img_alpha(c["image"])
        if pl["flip"]: al = al[:, ::-1]
        fx_ = (c["size"][0] - c["foot"][0]) if pl["flip"] else c["foot"][0]
        ys, xs = np.where(al[c["foot"][1] - int(0.05 * c["size"][1]):] > 128)
        if len(xs) == 0: continue
        spread = max(abs(xs.min() - fx_), abs(xs.max() - fx_)) * pl["scale"]          # root reach, zone px
        for k in range(rd.get("decals", 6)):
            a_ = rnd.uniform(0, 2 * math.pi); r_ = spread * rnd.uniform(0.45, 0.95)
            u, v = pl["at"][0] + math.cos(a_) * r_, pl["at"][1] + math.sin(a_) * r_ * 0.4
            if dist_path_at(u, v) < 20: continue
            add(pick(rd["decal_props"]), (u, v), rnd.uniform(1.0, 1.5), rnd.random() < 0.5, keep=0)
        for k in range(rd.get("tufts", 3)):
            a_ = rnd.uniform(0.15 * math.pi, 0.85 * math.pi) if rnd.random() < 0.6 else rnd.uniform(0, 2 * math.pi)
            r_ = spread * rnd.uniform(0.75, 1.05)
            u, v = pl["at"][0] + math.cos(a_) * r_, pl["at"][1] + math.sin(a_) * r_ * 0.4
            if dist_path_at(u, v) < 60: continue
            add(pick(rd["tuft_props"]), (u, v), rnd.uniform(0.75, 1.0), rnd.random() < 0.5, keep=0)
def clear_of_solid(u, v, gap):
    for pl in placed:
        c = cat["props"][pl["prop"]]
        if c["kind"] in ("tree", "rock") and (u - pl["at"][0]) ** 2 + ((v - pl["at"][1]) / 0.6) ** 2 < (c["footprint_px"] * pl["scale"] + gap) ** 2: return False
    return True
def in_clear(u, v, pad=0.0):
    for c_ in spec.get("clear", []):
        if (u - c_[0]) ** 2 + ((v - c_[1]) / 0.55) ** 2 < (c_[2] + pad) ** 2: return True
    return False
solid_pts = []                                           # (u, v, r) trunks and rocks, for fast spacing checks
def solid_clear(u, v, gap):
    for a, b, r in solid_pts:
        if (u - a) ** 2 + ((v - b) / 0.6) ** 2 < (r + gap) ** 2: return False
    return True
for pl in placed:
    c = cat["props"][pl["prop"]]
    if c["kind"] in ("tree", "rock"): solid_pts.append((pl["at"][0], pl["at"][1], c["footprint_px"] * pl["scale"]))
def noise_field(scale_px, seed):
    g = np.random.RandomState(seed).rand(int(sh / (scale_px / SPLAT_K)) + 3, int(sw / (scale_px / SPLAT_K)) + 3).astype(np.float32)
    return cv2.resize(g, (sw, sh), interpolation=cv2.INTER_CUBIC)
_canopy_pts = {}
def canopy_cover(prop, at, scale, flip, mask):
    """Fraction of a tree's canopy (as drawn from the game camera, i.e. the image rows above the trunk) that lands
    on `mask` (paths, clearings). Trees standing just in front of a road would otherwise hide it under leaves."""
    c = cat["props"][prop]; s_ = scale * (ZPPM / c["ppm"] if "ppm" in c else 1.0)
    if prop not in _canopy_pts:
        al = img_alpha(c["image"])[: int(c["foot"][1] * 0.7)]
        ys, xs = np.where(al[::6, ::6] > 128); _canopy_pts[prop] = (xs * 6, ys * 6)
    xs, ys = _canopy_pts[prop]
    if len(xs) == 0: return 0.0
    fx_ = c["foot"][0]
    dx = (xs - fx_) * (-1 if flip else 1)
    u = ((dx * s_) + at[0]) / SPLAT_K; v = ((ys - c["foot"][1]) * s_ + at[1]) / SPLAT_K
    ok = (u >= 0) & (u < sw) & (v >= 0) & (v < sh)
    if not ok.any(): return 0.0
    return float((mask[v[ok].astype(int), u[ok].astype(int)] > 0.3).sum() / len(xs))
def grow_forest(F):
    """Natural woodland: tree groves where a density field is high (and a thick frame along the zone edges),
    open glades where it is low; trees never on paths or in clearings. Then undergrowth clumps, grass tufts
    everywhere off the paving, scattered ground litter and rock clusters."""
    dens = noise_field(F.get("grove_px", 1500), spec.get("seed", 1) + 5) * 0.75 + noise_field(500, spec.get("seed", 1) + 6) * 0.25
    yy, xx = np.mgrid[0:sh, 0:sw] * SPLAT_K
    edge = np.minimum(np.minimum(xx, W - xx), np.minimum(yy, H - yy) / 0.55)
    dens = dens + np.clip(1 - edge / F.get("frame_px", 900), 0, 1) * F.get("frame", 0.45)
    def D(u, v): return dens[min(sh - 1, max(0, int(v / SPLAT_K))), min(sw - 1, max(0, int(u / SPLAT_K)))]
    keep_seen = (path_mask > 0.3).astype(np.float32)          # ground that must stay visible: roads + clearings
    for c_ in spec.get("clear", []):
        cv2.ellipse(keep_seen, (int(c_[0] / SPLAT_K), int(c_[1] / SPLAT_K)), (int(c_[2] * 0.8 / SPLAT_K), int(c_[2] * 0.8 * 0.55 / SPLAT_K)), 0, 0, 360, 1.0, -1)
    trees = F["trees"]; names = [t[0] for t in trees]; wts = [t[1] for t in trees]
    sp = F.get("spacing", 420); cut = F.get("cut", 0.5); n_try = int(W * H / (sp * sp * 0.55) * 6); n_tree = 0
    for _ in range(n_try):
        u, v = rnd.uniform(-60, W + 60), rnd.uniform(60, H + 120)
        d = D(u, v)
        if d < cut or in_clear(u, v, 180): continue
        if dist_path_at(u, v) < F.get("path_gap", 170): continue
        sp_here = sp * (1.25 - 0.5 * min(1.0, (d - cut) / 0.4))          # denser at the heart of a grove
        if not solid_clear(u, v, sp_here * 0.5): continue
        nm = rnd.choices(names, wts)[0]; sc_ = rnd.uniform(*F.get("tree_scale", [0.85, 1.15])); fl = rnd.random() < 0.5
        if paving_overlap(nm, (u, v), sc_, fl) > 0.0: continue
        if canopy_cover(nm, (u, v), sc_, fl, keep_seen) > F.get("max_canopy_cover", 0.06): continue
        add(nm, (u, v), sc_, fl, keep=0)
        placed[-1]["tint"] = round(rnd.uniform(0.9, 1.04), 3)
        solid_pts.append((u, v, cat["props"][nm]["footprint_px"] * placed[-1]["scale"])); n_tree += 1
    # rocks: clusters of a big stone with smaller ones round it
    big = F.get("rocks_big", []); small = F.get("rocks_small", []); n_rock = 0
    for _ in range(F.get("rock_clusters", 0) * 20):
        if n_rock >= F.get("rock_clusters", 0): break
        u, v = rnd.uniform(200, W - 200), rnd.uniform(300, H - 100)
        if in_clear(u, v, 100) or dist_path_at(u, v) < 150 or not solid_clear(u, v, 160): continue
        nm = pick(big); fl = rnd.random() < 0.5; sc_ = rnd.uniform(0.8, 1.15)
        if paving_overlap(nm, (u, v), sc_, fl) > 0.0: continue
        add(nm, (u, v), sc_, fl, keep=0); solid_pts.append((u, v, cat["props"][nm]["footprint_px"] * placed[-1]["scale"])); n_rock += 1
        for k in range(rnd.randint(1, 3)):
            a_ = rnd.uniform(0, 2 * math.pi); r_ = rnd.uniform(140, 260)
            u2, v2 = u + math.cos(a_) * r_, v + math.sin(a_) * r_ * 0.5
            nm2 = pick(small); sc2 = rnd.uniform(0.7, 1.1); fl2 = rnd.random() < 0.5
            if dist_path_at(u2, v2) < 100 or paving_overlap(nm2, (u2, v2), sc2, fl2) > 0.0 or not solid_clear(u2, v2, 40): continue
            add(nm2, (u2, v2), sc2, fl2, keep=0); solid_pts.append((u2, v2, cat["props"][nm2]["footprint_px"] * placed[-1]["scale"]))
    # undergrowth clumps: denser near trees and in groves, a few out in the open
    tree_pts = [(pl["at"][0], pl["at"][1]) for pl in placed if cat["props"][pl["prop"]]["kind"] == "tree"]
    tg = np.zeros((sh, sw), np.float32)
    for a, b in tree_pts:
        if 0 <= a < W and 0 <= b < H: tg[int(b / SPLAT_K), int(a / SPLAT_K)] = 1
    near = np.clip(cv2.GaussianBlur(tg, (0, 0), 45) * 900, 0, 1)
    def N(u, v): return near[min(sh - 1, max(0, int(v / SPLAT_K))), min(sw - 1, max(0, int(u / SPLAT_K)))]
    n_cl = int(W * H / 1e6 * F.get("clumps_per_mpx", 10)); n_c = 0
    for _ in range(n_cl * 6):
        if n_c >= n_cl: break
        u, v = rnd.uniform(40, W - 40), rnd.uniform(140, H - 20)
        if rnd.random() > 0.25 + 0.75 * N(u, v): continue
        if in_clear(u, v) or dist_path_at(u, v) < 70: continue
        kind = rnd.choices(list(F["clumps"].keys()), [F["clumps"][k]["w"] for k in F["clumps"]])[0]; ck = F["clumps"][kind]
        n_c += 1
        for k in range(rnd.randint(*ck["n"])):
            a_ = rnd.uniform(0, 2 * math.pi); r_ = rnd.uniform(0, ck.get("r", 160))
            u2, v2 = u + math.cos(a_) * r_, v + math.sin(a_) * r_ * 0.55
            if dist_path_at(u2, v2) < 50 or in_clear(u2, v2) or not solid_clear(u2, v2, 15): continue
            add(pick(ck["props"]), (u2, v2), rnd.uniform(*ck.get("scale", [0.8, 1.15])), rnd.random() < 0.5, keep=0)
    # grass tufts and small flowers everywhere off the paving (breaks up the base grass)
    n_tuft = int(W * H / 1e6 * F.get("tufts_per_mpx", 40)); n_t = 0
    for _ in range(n_tuft * 3):
        if n_t >= n_tuft: break
        u, v = rnd.uniform(30, W - 30), rnd.uniform(130, H - 10)
        if dist_path_at(u, v) < 40 or in_clear(u, v, -60) or not solid_clear(u, v, 10): continue
        add(pick(F["tufts"]), (u, v), rnd.uniform(0.55, 0.95), rnd.random() < 0.5, keep=0); n_t += 1
    # ground cover: grass / wildflower / moss patches layered over the base grass, in drifts (meadowy where a
    # noise field is high, thinner elsewhere) so the base texture never reads as one repeated carpet
    CV = F.get("cover")
    n_cv = 0
    if CV:
        drift = noise_field(CV.get("drift_px", 900), spec.get("seed", 1) + 13)
        def Dr(u, v): return drift[min(sh - 1, max(0, int(v / SPLAT_K))), min(sw - 1, max(0, int(u / SPLAT_K)))]
        target = int(W * H / 1e6 * CV["per_mpx"])
        for _ in range(target * 4):
            if n_cv >= target: break
            u, v = rnd.uniform(20, W - 20), rnd.uniform(120, H - 5)
            if rnd.random() > 0.2 + 0.8 * Dr(u, v): continue
            if dist_path_at(u, v) < CV.get("path_gap", 35) or in_clear(u, v, -80) or not solid_clear(u, v, 10): continue
            add(pick(CV["props"]), (u, v), rnd.uniform(*CV.get("scale", [0.8, 1.25])), rnd.random() < 0.5, keep=0); n_cv += 1
    # ground litter: leaves and pebbles, mushrooms near trunks
    n_lit = int(W * H / 1e6 * F.get("litter_per_mpx", 14)); n_l = 0
    for _ in range(n_lit * 3):
        if n_l >= n_lit: break
        u, v = rnd.uniform(30, W - 30), rnd.uniform(130, H - 10)
        if dist_path_at(u, v) < 25 or in_clear(u, v): continue
        nm = pick(F["litter_near_trees"]) if rnd.random() < N(u, v) else pick(F["litter"])
        add(nm, (u, v), rnd.uniform(0.9, 1.4), rnd.random() < 0.5, keep=0); n_l += 1
    # leaf litter on the ground under groves (dirt layer, ragged), never over the paving
    lit = np.clip(cv2.GaussianBlur(tg, (0, 0), 30) * 1400, 0, 1) * np.clip(noise_field(300, spec.get("seed", 1) + 9) * 1.8 - 0.35, 0, 1)
    splat[..., 1] = np.maximum(splat[..., 1], lit * F.get("litter_ground", 0.7) * (1 - splat[..., 0]))
    print(f"forest: {n_tree} trees, {n_rock} rock clusters, {n_c} undergrowth clumps, {n_t} tufts, {n_cv} ground cover, {n_l} litter")
if "forest" in spec: grow_forest(spec["forest"])
Image.fromarray((splat * 255).astype(np.uint8)).save(f"assets/zones/{name}/splat.png")
dress_roots()
for ed in spec.get("edges", []):                     # planting along both edges of a path
    pth = spec["paths"][ed["path"]]
    pts = np.array(pth.get("_curve", pth["pts"]), np.float32)[::(6 if "_curve" in pth else 1)]; half = pth["width"] * 0.5
    seg = np.linalg.norm(np.diff(pts, axis=0), axis=1); L = seg.sum(); t = rnd.uniform(0, ed["spacing"])
    while t < L:
        i = int(np.searchsorted(np.cumsum(seg), t)); i = min(i, len(seg) - 1)
        f = (t - (np.cumsum(seg)[i] - seg[i])) / seg[i]; P = pts[i] + (pts[i + 1] - pts[i]) * f
        d_ = (pts[i + 1] - pts[i]) / seg[i]; nrm = np.array([-d_[1], d_[0]])
        for side in (-1, 1):
            if rnd.random() > ed.get("density", 0.8): continue
            off = half + ed.get("offset", 40) + rnd.uniform(0, ed.get("jitter", 60))
            Q = P + nrm * side * off * np.array([1.0, 0.55])
            pr_ = pick(ed["props"]); s_ = rnd.uniform(*ed.get("scale", [0.8, 1.15]))
            gap_ = max(20, cat["props"][pr_]["footprint_px"] * s_ * ZPPM / cat["props"][pr_].get("ppm", ZPPM) * ed.get("gap_mult", 1.0))
            if any((Q[0] - k_[0]) ** 2 + ((Q[1] - k_[1]) / 0.55) ** 2 < k_[2] ** 2 for k_ in spec.get("edge_keep_out", [])): continue
            if 0 < Q[0] < W and 0 < Q[1] < H and clear_of_solid(Q[0], Q[1], gap_) and dist_path_at(Q[0], Q[1]) >= ed.get("min_gap", 0):
                add(pr_, (float(Q[0]), float(Q[1])), s_, rnd.random() < 0.5, keep=0)
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
    if "at" in ex:                                       # an exit where a path leaves the zone: glow on the path end
        u, v = ex["at"]; r = ex.get("r", 180)
        quad = [[u - r, v - r * 0.55], [u + r, v - r * 0.55], [u + r, v + r * 0.55], [u - r, v + r * 0.55]]
        exits.append({"name": ex["name"], "to": ex["to"], "arrive": ex["arrive"], "poly": quad, "aura": {"poly": quad}})
        continue
    pi = setpieces[ex["setpiece"]]; c = cat["props"][placed[pi]["prop"]]
    exits.append({"name": ex["name"], "to": ex["to"], "arrive": ex["arrive"],
                  "poly": [local_to_zone(pi, q) for q in c["trigger"]], "aura": {"poly": [local_to_zone(pi, q) for q in c["aura"]]}})
waypoints = []
if "waypoint_setpiece" in spec:
    pi = setpieces[spec["waypoint_setpiece"]]; c = cat["props"][placed[pi]["prop"]]
    at = local_to_zone(pi, c["waypoint"])
    waypoints.append({"id": spec["waypoint"]["id"], "name": spec["waypoint"]["name"], "at": at, "centre_of": at, "radius_px": spec["waypoint"].get("radius_px", 200)})
# waypoints stand on clear ground: nothing planted on or right round the platform
for wp in spec.get("waypoints", []):
    rr = wp.get("radius_px", 200) * 1.45
    placed[:] = [p_ for p_ in placed if cat["props"][p_["prop"]]["kind"] in ("tree", "rock", "setpiece")
                 or (p_["at"][0] - wp["at"][0]) ** 2 + ((p_["at"][1] - wp["at"][1]) / 0.55) ** 2 > rr ** 2]
for wp in spec.get("waypoints", []):
    waypoints.append({"id": wp["id"], "name": wp["name"], "at": wp["at"], "centre_of": wp["at"], "radius_px": wp.get("radius_px", 200), "rot_deg": wp.get("rot_deg", 22.9)})
# dungeons ("enclose"): everything off the corridors and rooms (paths + paved/dirt patches) is rock wall: a rock
# prop every few cells (looks) and a solid on every cell (seals the gaps)
enclose_solids = []
if "enclose" in spec:
    E = spec["enclose"]; step = E.get("spacing", 230); erng = random.Random(spec.get("seed", 1) + 99)
    keep_off = [tuple(c) for c in spec.get("clear", [])]
    for v in range(0, H + step, int(step * 0.55)):
        for u in range(0, W + step, step):
            uu = u + (step // 2 if (v // int(step * 0.55)) % 2 else 0)
            x, y = min(sw - 1, int(uu / SPLAT_K)), min(sh - 1, int(v / SPLAT_K))
            if path_mask[y, x] > 0.05: continue
            if any((uu - c[0]) ** 2 + ((v - c[1]) / 0.55) ** 2 < c[2] ** 2 for c in keep_off): continue
            enclose_solids.append([uu, v, int(step * 0.62)])
            # a wall rock rises above its foot: only where nothing walkable lies under the image (north walls read as
            # walls; the south side of a corridor stays open dark ground so the corridor is never hidden)
            pr = erng.choice(E["props"]); sc = erng.uniform(*E.get("scale", [0.9, 1.4]))
            c = cat["props"][pr]; hh = c["size"][1] * sc; ww = c["size"][0] * sc * 0.5
            y0 = max(0, int((v - hh) / SPLAT_K)); x0 = max(0, int((uu - ww) / SPLAT_K)); x1 = min(sw, int((uu + ww) / SPLAT_K) + 1)
            if path_mask[y0:y + 1, x0:x1].max() > 0.05: continue
            below = path_mask[y:min(sh, y + int(hh * 0.6 / SPLAT_K) + 2), x0:x1].max() > 0.05
            if below or erng.random() < E.get("fill", 0.35):
                placed.append({"prop": pr, "at": [uu, v], "scale": round(sc, 4), "flip": erng.random() < 0.5, "wall": True})
# nothing grows out of open water (the scatter's keep-out discs miss the squashed edges of pools and seas)
def _wet(u, v):
    x, y = min(sw - 1, max(0, int(u / SPLAT_K))), min(sh - 1, max(0, int(v / SPLAT_K)))   # frame trees stand past the edge
    return splat[y, x, 2] > 0.35
placed[:] = [p_ for p_ in placed if cat["props"][p_["prop"]]["kind"] == "setpiece" or not _wet(p_["at"][0], p_["at"][1])]
# collision: per-prop footprints + set-piece blockers + water
solids = []
for i, p in enumerate(placed):
    c = cat["props"][p["prop"]]
    if c["kind"] == "decal": continue
    if p.get("wall"): continue          # dungeon wall dressing: the enclosure cells are the collision, not the art
    if c.get("footprint_px", 0) > 0: solids.append([p["at"][0], p["at"][1], round(c["footprint_px"] * p["scale"])])
    for b in c.get("blockers", []):
        q = local_to_zone(i, b[:2]); solids.append([q[0], q[1], round(b[2] * p["scale"])])
# water is solid where it is painted (organic pools / seas): a disc every ~110 px inside the water mask
_ws = 14
for y_ in range(0, sh, _ws):
    for x_ in range(0, sw, _ws):
        if splat[y_, x_, 2] > 0.55: solids.append([x_ * SPLAT_K, y_ * SPLAT_K, int(_ws * SPLAT_K * 0.62)])
solids += enclose_solids
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
            al = img_alpha(c["image"]).astype(np.float32) / 255
            if pl["flip"]: al = al[:, ::-1]
            fy_ = c["foot"][1]
            al = al.copy(); al[int(fy_ - 0.32 * fy_):] = 0       # canopy only (trunk shadow is the contact shadow)
            # image px -> light texels: canopy point (x, y) lands at foot + (x - fx + a*(fy - y), b*(fy - y))
            ox, oy = pl["at"][0] / LK, pl["at"][1] / LK
            M = np.float32([[sc_, -a_sh * sc_, ox - fx_ * sc_ + a_sh * fy_ * sc_], [0, -b_sh * sc_, oy + b_sh * fy_ * sc_]])
            warp_max(shadow, np.ascontiguousarray(al), M)
            cv2.circle(trees_d, (int(ox), int(oy)), max(1, int(c["size"][0] * sc_ * 0.35)), 1.0, -1)
        if "shadow" in c:                                   # the art's own contact shadow, as real shade
            sm = img_alpha(c["shadow"]).astype(np.float32) / 255
            if pl["flip"]: sm = sm[:, ::-1]
            M2 = np.float32([[sc_, 0, pl["at"][0] / LK - fx_ * sc_], [0, sc_, pl["at"][1] / LK - c["foot"][1] * sc_]])
            warp_max(ao, np.ascontiguousarray(sm), M2, 0.9)
        if c["kind"] in ("tree", "rock", "bush"):
            r = c["size"][0] * sc_ * (0.16 if c["kind"] == "tree" else 0.30)
            cv2.ellipse(ao, (int(pl["at"][0] / LK), int(pl["at"][1] / LK)), (max(1, int(r)), max(1, int(r * 0.45))), 0, 0, 360, 1.0, -1)
    dapple = np.clip((fbm(LS.get("dapple_px", 40), 3) - 0.45) * 5.0, 0, 1)       # sun flecks through the leaves
    shadow = cv2.GaussianBlur(np.clip((shadow - 0.3) * 2.0, 0, 1), (0, 0), 1.2) * (1 - 0.6 * dapple)
    ao = cv2.GaussianBlur(ao, (0, 0), 7)
    # the overhead canopy beyond the placed trees: a dappled shade field over the whole zone, thinner where open
    # stamped from the kit's own canopy silhouettes (leaf-shaped edges, like the shade painted in W1)
    canopies = []
    for k, c in cat["props"].items():
        if c["kind"] == "tree":
            al = img_alpha(c["image"]).astype(np.float32)[: int(c["foot"][1] * 0.62)] / 255   # canopy rows
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
    mist = cv2.GaussianBlur(trees_d, (0, 0), 80) * LS.get("tree_mist", 0.0) * np.clip(fbm(500, 3) * 1.6 - 0.3, 0, 1)
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
            if mv > 0.02 and LS.get("prop_mist", False): pl["mist"] = round(mv * 0.45, 3)
    fx = np.dstack([np.clip(mist, 0, 1), np.clip(shafts, 0, 1), np.zeros_like(mist)])
    Image.fromarray((fx * 255).astype(np.uint8)).save(f"assets/zones/{name}/fx.png"); fx_name = f"{name}/fx.png"
# minimap overview (1/8 scale): ground colours + props
def ground_layer(k):
    """The ground texture tiled exactly as the game draws it (world metres, foreshortened by the camera), at 1/8."""
    g = cat["ground"][k]; im = Image.open(os.path.join(kit_dir, g["image"])).convert("RGB")
    if "tile_m" in g:
        tw = max(4, int(round(g["tile_m"] * ZPPM / SPLAT_K))); th = max(2, int(round(g["tile_m"] * ZPPM * math.sin(math.radians(spec.get("pitch", 31.0))) / SPLAT_K)))
    else:
        tw = th = max(4, int(g["tile_px"] / SPLAT_K))
    big = np.tile(np.asarray(im), (3, 3, 1))                  # resize a 3x3 repeat, keep the middle: seamless edges
    t = np.asarray(Image.fromarray(big).resize((tw * 3, th * 3), Image.LANCZOS), np.float32)[th:2 * th, tw:2 * tw]
    return np.tile(t, (sh // th + 2, sw // tw + 2, 1))[:sh, :sw]
ov = ground_layer(spec.get("ground_base", "grass"))
for k, ch in (("dirt", 1), ("flagstone", 0)):
    ov = ov * (1 - splat[..., ch:ch + 1]) + ground_layer(k) * splat[..., ch:ch + 1]
gcol = {}
_wc = spec.get("grade", {}).get("water")      # the zone's own water colour (rift pools are violet)
_wrgb = np.array([c * 255 * 0.9 for c in _wc], np.float32) if _wc else np.array([70, 110, 130], np.float32)
ov = ov * (1 - splat[..., 2:3]) + _wrgb * splat[..., 2:3]
if light_name:                                          # same canopy shade and sun pools as in game
    ov = ov * cv2.resize(light, (sw, sh), interpolation=cv2.INTER_AREA)[..., None]
ovi = Image.fromarray(ov.clip(0, 255).astype(np.uint8)).convert("RGBA")
_ov_src = {}; _ov_sized = {}
for p in sorted(placed, key=lambda p: p["at"][1]):
    c = cat["props"][p["prop"]]
    if c["image"] not in _ov_src:          # downscale each image once (overview is 1/8 scale)
        im0 = Image.open(os.path.join(kit_dir, c["image"])).convert("RGBA")
        _ov_src[c["image"]] = im0.resize((max(1, im0.width // 4), max(1, im0.height // 4)), Image.LANCZOS)
    s = p["scale"] / SPLAT_K; w2, h2 = max(1, int(c["size"][0] * s)), max(1, int(c["size"][1] * s))
    key = (c["image"], w2, h2)
    if key not in _ov_sized: _ov_sized[key] = _ov_src[c["image"]].resize((w2, h2), Image.BILINEAR)
    im = _ov_sized[key]
    if p["flip"]: im = im.transpose(Image.FLIP_LEFT_RIGHT)
    fx = c["size"][0] - c["foot"][0] if p["flip"] else c["foot"][0]
    ovi.alpha_composite(im, (max(0, int(p["at"][0] / SPLAT_K - fx * s)), max(0, int(p["at"][1] / SPLAT_K - c["foot"][1] * s))))
ovi.convert("RGB").save(f"assets/zones/{name}/overview.png")
# full-screen map: same picture at 1/4 scale (ground + light upsampled, props re-drawn at the higher resolution)
MK = 4; mw, mh = W // MK, H // MK
def ground_layer_k(k, K):
    g = cat["ground"][k]; im = Image.open(os.path.join(kit_dir, g["image"])).convert("RGB")
    tw = max(4, int(round(g["tile_m"] * ZPPM / K))); th = max(2, int(round(g["tile_m"] * ZPPM * math.sin(math.radians(spec.get("pitch", 31.0))) / K)))
    big = np.tile(np.asarray(im), (3, 3, 1))
    t = np.asarray(Image.fromarray(big).resize((tw * 3, th * 3), Image.LANCZOS), np.float32)[th:2 * th, tw:2 * tw]
    return np.tile(t, (mh // th + 2, mw // tw + 2, 1))[:mh, :mw]
if all("tile_m" in g for g in cat["ground"].values()):
    spl = cv2.resize(splat, (mw, mh), interpolation=cv2.INTER_LINEAR)
    mp = ground_layer_k(spec.get("ground_base", "grass"), MK)
    for k, ch in (("dirt", 1), ("flagstone", 0)):
        mp = mp * (1 - spl[..., ch:ch + 1]) + ground_layer_k(k, MK) * spl[..., ch:ch + 1]
    mp = mp * (1 - spl[..., 2:3]) + np.array([70, 110, 130], np.float32) * spl[..., 2:3]
    if light_name: mp = mp * cv2.resize(light, (mw, mh), interpolation=cv2.INTER_LINEAR)[..., None]
    mpi = Image.fromarray(mp.clip(0, 255).astype(np.uint8)).convert("RGBA")
    src2 = {}; sized2 = {}
    for p in sorted(placed, key=lambda p: p["at"][1]):
        c = cat["props"][p["prop"]]
        if c["kind"] == "decal" or (c["kind"] == "bush" and c["size"][0] * p["scale"] / MK < 6): continue
        if c["image"] not in src2:
            im0 = Image.open(os.path.join(kit_dir, c["image"])).convert("RGBA")
            src2[c["image"]] = im0.resize((max(1, im0.width // 2), max(1, im0.height // 2)), Image.LANCZOS)
        s = p["scale"] / MK; w2, h2 = max(1, int(c["size"][0] * s)), max(1, int(c["size"][1] * s))
        key = (c["image"], w2, h2)
        if key not in sized2: sized2[key] = src2[c["image"]].resize((w2, h2), Image.BILINEAR)
        im = sized2[key]
        if p["flip"]: im = im.transpose(Image.FLIP_LEFT_RIGHT)
        fx = c["size"][0] - c["foot"][0] if p["flip"] else c["foot"][0]
        x0, y0 = int(p["at"][0] / MK - fx * s), int(p["at"][1] / MK - c["foot"][1] * s)
        if x0 + im.width <= 0 or y0 + im.height <= 0 or x0 >= mw or y0 >= mh: continue
        if x0 < 0 or y0 < 0:
            im = im.crop((max(0, -x0), max(0, -y0), im.width, im.height)); x0, y0 = max(0, x0), max(0, y0)
        mpi.alpha_composite(im, (x0, y0))
    mpi.convert("RGB").save(f"assets/zones/{name}/map.jpg", quality=90)
rt = {k: spec[k] for k in ("name", "size", "ppm", "pitch", "hero_px_1080", "spawn") if k in spec}
rt.update({"kit": "res://" + kit_dir, "ground_base": spec.get("ground_base", "grass"), "splat": f"{name}/splat.png", "map": f"{name}/map.jpg",
           "splat_k": SPLAT_K, "overview": f"{name}/overview.png", "props": placed, "solids": solids,
           "walkable": [[[40, 100], [W - 40, 100], [W - 40, H - 20], [40, H - 20]]], "exits": exits, "waypoints": waypoints,
           "targets": spec.get("targets", []), "ground_ratio": 0.51})
if light_name: rt["light"] = light_name; rt["fx"] = fx_name
if "walkable" in spec: rt["walkable"] = spec["walkable"]
for k in ("map_pois", "world_id", "grade"):
    if k in spec: rt[k] = spec[k]
# the minimap overview and zone map get the same biome grade the runtime applies to the kit art
if "grade" in spec:
    g = spec["grade"]
    mul = np.array(g.get("mul", [1, 1, 1]), np.float32); lift = np.array(g.get("lift", [0, 0, 0, 0]), np.float32)
    for fn in (f"assets/zones/{name}/overview.png", f"assets/zones/{name}/map.jpg"):
        if not os.path.exists(fn): continue
        im = Image.open(fn); mode = im.mode
        a_ = np.asarray(im.convert("RGBA")).astype(np.float32) / 255.0
        c = a_[:, :, :3]
        lum = (c * np.array([0.299, 0.587, 0.114], np.float32)).sum(2, keepdims=True)
        c = c + (lum - c) * float(g.get("desat", 0.0))
        c = c * mul + lift[:3] * lift[3]
        a_[:, :, :3] = c.clip(0, 1)
        out = Image.fromarray((a_ * 255).astype(np.uint8), "RGBA")
        if fn.endswith(".jpg"): out.convert("RGB").save(fn, quality=90)
        else: out.convert(mode).save(fn)
json.dump(rt, open(f"assets/zones/{name}.json", "w"), indent=1)
print(name, W, "x", H, "props", len(placed), "solids", len(solids), "exits", len(exits), "waypoints", len(waypoints))
