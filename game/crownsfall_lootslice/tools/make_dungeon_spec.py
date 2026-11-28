#!/usr/bin/env python3
"""Write a greybox dungeon kit-zone spec (walled corridors and rooms on the forest kit, see build_kit_zone 'enclose')
from a short layout description.

    python3 tools/make_dungeon_spec.py <layout.json>

layout: {"id", "name", "world_id", "size": [w, h], "seed", "rooms": [[x, y, r, "label"?]], "links": [[a, b, width?]],
         "entry": room index (west exit), "exit_to": zone, "exit_arrive": [x, y], "waypoint": [room, id, name],
         "pois": [...map_pois], "grade": {...}, "ground": "dirt"}
"""
import json, os, sys
L = json.load(open(sys.argv[1]))
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.dirname(here)
base = json.load(open(os.path.join(root, "assets/zones/src/mossbarrow_crypts.kitzone.json")))
z = json.loads(json.dumps(base))
W, H = L["size"]
rooms = L["rooms"]
z.update({"name": L["name"], "world_id": L["world_id"], "seed": L.get("seed", 5), "size": [W, H], "ground_base": L.get("ground", "dirt")})
z["paths"] = [{"pts": [rooms[a][:2], rooms[b][:2]], "width": (lk[2] if len(lk) > 2 else 300), "layer": "flagstone"} for lk in L["links"] for a, b in [lk[:2]]]
e = rooms[L.get("entry", 0)]
z["paths"].insert(0, {"pts": [[-80, e[1]], e[:2]], "width": 330, "layer": "flagstone"})
z["patches"] = [{"at": r[:2], "r": r[2], "layer": "flagstone", "squash": 0.515} for r in rooms]
z["patches"] += [{"at": w[:2], "r": w[2], "layer": "water", "squash": 0.52} for w in L.get("water", [])]
z["clear"] = [[160, e[1], 300]]
z["light"]["open"] = [[r[0], r[1], r[2] * 0.8, 0.6] for r in rooms]
z["light"]["shafts"] = [[r[0], r[1] - 200, 380] for r in rooms if len(r) > 3 and r[3] == "lit"]
z["exits"] = [{"name": L["exit_name"], "to": L["exit_to"], "at": [140, e[1]], "r": 170, "arrive": L["exit_arrive"]}] + L.get("more_exits", [])
z["spawn"] = [620, e[1]]
wr, wid, wname = L["waypoint"]
z["waypoints"] = [{"id": wid, "name": wname, "at": rooms[wr][:2], "radius_px": 200}]
z["map_pois"] = L.get("pois", [])
if "grade" in L: z["grade"] = L["grade"]
out = os.path.join(root, "assets/zones/src", L["id"] + ".kitzone.json")
json.dump(z, open(out, "w"), indent=1)
print("wrote", out)
