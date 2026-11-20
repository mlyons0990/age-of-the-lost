#!/usr/bin/env python3
"""Apply R55 to a copy of the verified R54 GLB: arm skin weights (in place) and the forearm-guard
scallop (POSITION in place, same formula as tools/r55_clip_safe_elbow.py, in Blender axes
gx = bx, gy = bz, gz = -by). Animations, rig and every other byte are kept from R54.

usage: r55_patch_glb.py <R54 .glb> <r55 data .json> <out .glb>
"""
import json, struct, sys, hashlib
from pathlib import Path
import numpy as np
sys.path.insert(0, str(Path(__file__).parent))
from merge_r52_armor_and_animations import read_glb, align4, JSON_CHUNK, BIN_CHUNK
from r53_patch_glb_arm_weights import view
from r54_patch_glb_elbow_helper import Blob, patch_weights


def scallop(Q, sc):
    h, ax, inn = np.array(sc["head"]), np.array(sc["axis"]), np.array(sc["inner"])
    d = Q - h; a = d @ ax; rv = d - a[:, None] * ax
    dth = np.arctan2(rv @ np.cross(ax, inn), rv @ inn)
    half = sc["half"]
    cut = sc["depth"] * np.where(np.abs(dth) < half, np.cos(dth / half * np.pi / 2) ** 2, 0)
    a0, a1 = a.min(), a.max()
    a_new = a1 - (a1 - a) * (a1 - a0 - cut) / (a1 - a0)
    return Q + (a_new - a)[:, None] * ax


def main(src, data, out):
    j, b = read_glb(src)
    blob = Blob(j, b)
    D = json.load(open(data))
    patch_weights(blob, {k: v for k, v in D.items() if k.startswith("V04_")})
    for key in ("guard_L", "guard_R"):
        g = D[key]
        node = next(n for n in j["nodes"] if n.get("name") == g["object"])
        if any(k in node for k in ("translation", "rotation", "scale", "matrix")):
            raise ValueError("guard node has a transform; formula assumes armature space")
        for p in j["meshes"][node["mesh"]]["primitives"]:
            off, cnt, n, dt = view(j, blob.b, p["attributes"]["POSITION"])
            pos = np.frombuffer(bytes(blob.b[off:off + cnt * 12]), np.float32).reshape(-1, 3).astype(float)
            pb = np.c_[pos[:, 0], -pos[:, 2], pos[:, 1]]
            q = scallop(pb, g["scallop"])
            new = np.c_[q[:, 0], q[:, 2], -q[:, 1]].astype(np.float32)
            blob.b[off:off + new.nbytes] = new.tobytes()
            acc = j["accessors"][p["attributes"]["POSITION"]]
            acc["min"] = new.min(0).tolist(); acc["max"] = new.max(0).tolist()
            print(g["object"], cnt, "vertices scalloped, max shift %.4f m" % np.abs(new - pos).max())
    js = align4(json.dumps(j, separators=(",", ":")).encode(), b" ")
    bb = align4(bytes(blob.b), b"\0")
    raw = struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(js) + 8 + len(bb)) + struct.pack("<II", len(js), JSON_CHUNK) + js + struct.pack("<II", len(bb), BIN_CHUNK) + bb
    Path(out).write_bytes(raw)
    print(out, len(raw), hashlib.sha256(raw).hexdigest())


if __name__ == "__main__":
    main(*sys.argv[1:4])
