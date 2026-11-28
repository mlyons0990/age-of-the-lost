#!/usr/bin/env python3
"""Write a greybox wild-zone kit spec (forest kit) from a short layout description.

    python3 tools/make_wild_spec.py <layout.json>

layout: {"id", "name", "world_id", "size", "seed", "main": [[x,y]...] (main road), "road": "flagstone"|"dirt",
 "branches": [[[x,y]...], ...] (dirt trails), "rooms": [[x,y,r,layer]] (clearings: flagstone|dirt), "pools": [[x,y,r]],
 "sea": "north"|"south"|"east"|null, "trees": [[name, w]...], "tree_spacing", "tree_cut", "rocks": n,
 "exits": [...kit exits], "waypoint": [x, y, id, name], "spawn": [x,y], "pois": [...], "grade": {...},
 "mist": "pools"|"none"}
"""
import json, os, sys
L = json.load(open(sys.argv[1]))
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.dirname(here)
z = json.load(open(os.path.join(root, "assets/zones/src/greyfen_causeway.kitzone.json")))
W, H = L["size"]
z.update({"name": L["name"], "world_id": L["world_id"], "seed": L.get("seed", 5), "size": [W, H], "ground_base": L.get("ground", "grass_old")})
z.pop("enclose", None)
road = L.get("road", "flagstone")
z["paths"] = [{"pts": L["main"], "width": 240 if road == "flagstone" else 210, "layer": road} | ({} if road == "flagstone" else {"style": "trail", "taper_end": False})]
z["paths"] += [{"pts": b, "width": 170, "layer": "dirt", "style": "trail", "taper_end": False} for b in L.get("branches", [])]
rooms = L.get("rooms", [])
z["patches"] = [{"at": r[:2], "r": r[2], "layer": r[3] if len(r) > 3 else "flagstone", "squash": 0.515} for r in rooms]
pools = list(L.get("pools", []))
sea = L.get("sea")
if sea == "south": pools += [[x, H + 20, 1000] for x in range(0, W + 800, 800)]
if sea == "north": pools += [[x, -60, 900] for x in range(0, W + 800, 800)]
if sea == "east": pools += [[W + 300, y, 850] for y in range(0, H + 700, 700)]
z["patches"] += [{"at": p[:2], "r": p[2], "layer": "water", "squash": 0.52} for p in pools]
for s in L.get("sand", []): z["patches"].insert(0, {"at": s[:2], "r": s[2], "layer": "dirt", "squash": 0.5})
z["clear"] = [[e["at"][0], e["at"][1], 400] for e in L["exits"]] + [[r[0], r[1], r[2] + 150] for r in rooms]
f = z["forest"]
f["trees"] = L.get("trees", [["gnarled_a", 3], ["gnarled_b", 3], ["silver", 3], ["oak_b", 1]])
f["spacing"] = L.get("tree_spacing", 800); f["cut"] = L.get("tree_cut", 0.7); f["rock_clusters"] = L.get("rocks", 40)
if "rocks_big" in L: f["rocks_big"] = L["rocks_big"]
z["light"]["open"] = [[r[0], r[1], r[2] * 1.1, 0.45] for r in rooms]
z["light"]["shafts"] = [[r[0], r[1] - 220, 420] for r in rooms[:2]]
z["light"]["canopy"] = L.get("canopy", 0.3)
z["light"]["mist"] = [[p[0], p[1], p[2] * 1.5] for p in L.get("pools", [])] if L.get("mist", "pools") == "pools" else []
z["exits"] = L["exits"]
wx, wy, wid, wname = L["waypoint"]
z["waypoints"] = [{"id": wid, "name": wname, "at": [wx, wy], "radius_px": 200}]
z["spawn"] = L.get("spawn", [620, 2470])
z["map_pois"] = L.get("pois", [])
z["grade"] = L.get("grade", {})
# organic dressing and per-zone character (build_kit_zone: rim, dress, forest overrides, canals)
for k in ("rim", "dress", "light_extra"):
    if k in L: z[k] = L[k]
for k, v in L.get("forest", {}).items(): z["forest"][k] = v
for c in L.get("canals", []): z["paths"].append({"pts": c[0], "width": c[1], "layer": "water", "wander": 0.5})
out = os.path.join(root, "assets/zones/src", L["id"] + ".kitzone.json")
json.dump(z, open(out, "w"), indent=1)
print("wrote", out)
