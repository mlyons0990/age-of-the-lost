#!/usr/bin/env python3
"""Apply the R54 elbow helper to a copy of the verified R53 GLB.

usage: r54_patch_glb_elbow_helper.py <R53 .glb> <r54 weights .json> <out .glb>

1. Arm skin weights (JOINTS_0 / WEIGHTS_0) are replaced in place, as in R53, now including Elbow.
2. In every animation, for each side, with glTF local transforms (Elbow = T(te)R(re), Forearm = T(tf)R(rf)):
     Δ  = rf · rf_rest⁻¹                  forearm bend in the Elbow frame (about the forearm head)
     q  = slerp(1, swing(Δ, forearm axis), ALPHA)
     Elbow'   = T(te + R(re)(tf − R(q) tf)) · R(re · q)      (rotates by q about the forearm head)
     Forearm' = T(tf) · R(q⁻¹ · rf)                            (so Elbow'·Forearm' = Elbow·Forearm)
   Keys are written at the Forearm rotation's own key times and interpolation. Nothing else changes.
Same ALPHA and swing/twist split as tools/r54_elbow_helper.py (the Blender source of truth).
"""
import json, struct, sys, hashlib
from pathlib import Path
import numpy as np
sys.path.insert(0, str(Path(__file__).parent))
from merge_r52_armor_and_animations import read_glb, align4, JSON_CHUNK, BIN_CHUNK
from r53_patch_glb_arm_weights import view, nearest

ALPHA = 0.5


def qmul(a, b):  # xyzw
    ax, ay, az, aw = np.moveaxis(a, -1, 0); bx, by, bz, bw = np.moveaxis(b, -1, 0)
    return np.stack([aw*bx + ax*bw + ay*bz - az*by, aw*by - ax*bz + ay*bw + az*bx,
                     aw*bz + ax*by - ay*bx + az*bw, aw*bw - ax*bx - ay*by - az*bz], -1)


def qinv(q):
    return q * np.array([-1, -1, -1, 1.0])


def qrot(q, v):
    p = np.concatenate([v, np.zeros(v.shape[:-1] + (1,))], -1)
    return qmul(qmul(q, p), qinv(q))[..., :3]


def qslerp_id(q, t):
    q = np.where(q[..., 3:4] < 0, -q, q)
    ang = 2 * np.arccos(np.clip(q[..., 3], -1, 1))
    s = np.sin(ang / 2)
    ax = np.where(s[..., None] > 1e-9, q[..., :3] / np.maximum(s[..., None], 1e-12), 0)
    h = ang * t / 2
    return np.concatenate([ax * np.sin(h)[..., None], np.cos(h)[..., None]], -1)


def swing(q, axis):
    proj = axis * (q[..., :3] @ axis)[..., None]
    tw = np.concatenate([proj, q[..., 3:4]], -1)
    n = np.linalg.norm(tw, axis=-1, keepdims=True)
    tw = np.where(n > 1e-9, tw / np.maximum(n, 1e-12), np.array([0, 0, 0, 1.0]))
    return qmul(q, qinv(tw))


class Blob:
    def __init__(self, j, b):
        self.j, self.b = j, bytearray(b)

    def read(self, acc):
        off, cnt, n, dt = view(self.j, self.b, acc)
        return np.frombuffer(bytes(self.b[off:off + cnt * n * dt.itemsize]), dt).reshape(cnt, n) if n > 1 else \
            np.frombuffer(bytes(self.b[off:off + cnt * dt.itemsize]), dt)

    def read_scalar(self, acc):
        a = self.j["accessors"][acc]; bv = self.j["bufferViews"][a["bufferView"]]
        off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        return np.frombuffer(bytes(self.b[off:off + a["count"] * 4]), np.float32)

    def add(self, arr, typ):
        arr = np.ascontiguousarray(arr, np.float32)
        while len(self.b) % 4:
            self.b += b"\0"
        self.j["bufferViews"].append({"buffer": 0, "byteOffset": len(self.b), "byteLength": arr.nbytes})
        self.b += arr.tobytes()
        self.j["accessors"].append({"bufferView": len(self.j["bufferViews"]) - 1, "componentType": 5126,
                                    "count": len(arr), "type": typ})
        return len(self.j["accessors"]) - 1


def patch_weights(blob, W):
    j, b = blob.j, blob.b
    joints = [j["nodes"][k]["name"] for k in j["skins"][0]["joints"]]
    for name, d in W.items():
        node = next(n for n in j["nodes"] if n.get("name") == name)
        bl, bw = np.array(d["local_positions"]), np.array(d["weights"])
        jidx = [joints.index(x) for x in d["bones"]]
        for p in j["meshes"][node["mesh"]]["primitives"]:
            pos = blob.read(p["attributes"]["POSITION"])
            pb = np.c_[pos[:, 0], -pos[:, 2], pos[:, 1]]
            e = np.linalg.norm(pb - bl, axis=1) if len(pb) == len(bl) else None
            match = np.arange(len(pb)) if e is not None and np.median(e) < 1e-4 and e.max() < 1e-2 else nearest(pb, bl)
            jo, cnt, _, _ = view(j, b, p["attributes"]["JOINTS_0"])
            wo, _, _, _ = view(j, b, p["attributes"]["WEIGHTS_0"])
            J = np.zeros((cnt, 4), np.uint8); WW = np.zeros((cnt, 4), np.float32)
            for i, m in enumerate(match):
                nz = np.nonzero(bw[m])[0]; nz = nz[np.argsort(-bw[m][nz])][:4]
                J[i, :len(nz)] = [jidx[k] for k in nz]; WW[i, :len(nz)] = bw[m][nz]
            WW /= WW.sum(1, keepdims=True)
            b[jo:jo + J.nbytes] = J.tobytes(); b[wo:wo + WW.nbytes] = WW.tobytes()
            print(name, cnt, "vertices reweighted")


def patch_animations(blob):
    j = blob.j
    idx = {n.get("name"): i for i, n in enumerate(j["nodes"])}
    for side in "LR":
        ne, nf, nh = idx["Elbow" + side], idx["Forearm" + side], idx["Hand" + side]
        rf_rest = np.array(j["nodes"][nf].get("rotation", [0, 0, 0, 1.0]))
        axis = qrot(rf_rest, np.array(j["nodes"][nh].get("translation", [0, 1, 0]), float))
        axis /= np.linalg.norm(axis)
        for a in j["animations"]:
            ch = {(c["target"]["node"], c["target"]["path"]): c for c in a["channels"]}
            def value(node, path, default):
                c = ch.get((node, path))
                if c is None:
                    return None, np.array(default, float)
                s = a["samplers"][c["sampler"]]
                return s, blob.read(s["output"]).astype(float)
            sr, rf = value(nf, "rotation", rf_rest)
            if sr is None:
                continue
            times_acc, interp = sr["input"], sr.get("interpolation", "LINEAR")
            _, tf = value(nf, "translation", j["nodes"][nf].get("translation", [0, 0, 0]))
            _, re = value(ne, "rotation", j["nodes"][ne].get("rotation", [0, 0, 0, 1]))
            _, te = value(ne, "translation", j["nodes"][ne].get("translation", [0, 0, 0]))
            for arr in (tf, re, te):
                if arr.ndim == 2 and np.abs(arr - arr[0]).max() > 1e-6:
                    raise ValueError("%s %s: Elbow/Forearm translation or Elbow rotation is animated; unsupported" % (a["name"], side))
            tf, re, te = [arr[0] if arr.ndim == 2 else arr for arr in (tf, re, te)]
            delta = qmul(rf, qinv(rf_rest))
            q = qslerp_id(swing(delta, axis), ALPHA)
            new_rf = qmul(qinv(q), rf)
            new_re = qmul(np.broadcast_to(re, q.shape), q)
            new_te = te + qrot(np.broadcast_to(re, q.shape), tf - qrot(q, np.broadcast_to(tf, q[..., :3].shape)))
            sr["output"] = blob.add(new_rf, "VEC4")
            for path, arr, typ in (("rotation", new_re, "VEC4"), ("translation", new_te, "VEC3")):
                c = ch.get((ne, path))
                s = {"input": times_acc, "interpolation": interp, "output": blob.add(arr, typ)}
                if c is None:
                    a["samplers"].append(s); a["channels"].append({"sampler": len(a["samplers"]) - 1, "target": {"node": ne, "path": path}})
                else:
                    a["samplers"][c["sampler"]] = s if sum(1 for cc in a["channels"] if cc["sampler"] == c["sampler"]) == 1 else a["samplers"].append(s) or a["samplers"][-1]
                    if a["samplers"][c["sampler"]] is not s:
                        c["sampler"] = len(a["samplers"]) - 1
            print("%s %s: %d keys (%s), max helper angle %.1f°" % (a["name"], side, len(q), interp, np.degrees(2 * np.arccos(np.clip(np.abs(q[:, 3]), 0, 1))).max()))


def main(src, wjson, out):
    j, b = read_glb(src)
    blob = Blob(j, b)
    patch_weights(blob, json.load(open(wjson)))
    patch_animations(blob)
    j["buffers"][0]["byteLength"] = len(blob.b) + (-len(blob.b)) % 4
    js = align4(json.dumps(j, separators=(",", ":")).encode(), b" ")
    bb = align4(bytes(blob.b), b"\0")
    raw = struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(js) + 8 + len(bb)) + struct.pack("<II", len(js), JSON_CHUNK) + js + struct.pack("<II", len(bb), BIN_CHUNK) + bb
    Path(out).write_bytes(raw)
    print(out, len(raw), hashlib.sha256(raw).hexdigest())


if __name__ == "__main__":
    main(*sys.argv[1:4])
