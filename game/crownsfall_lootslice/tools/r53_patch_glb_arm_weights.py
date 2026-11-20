#!/usr/bin/env python3
"""Write the R53 arm skin weights into a copy of the verified R52 seven-clip GLB.

usage: r53_patch_glb_arm_weights.py <R52 .glb> <r53 weights .json> <out .glb>

Only the JOINTS_0 / WEIGHTS_0 bytes of the two V04_SKIN_ArticulatedArm primitives change,
in place (same accessor sizes). Every other byte — node order, 62-joint skin, meshes,
materials, the seven animation clips — is copied verbatim, so the R52 export and its
R50 animation transplant stay exactly as tested. GLB vertices are matched to Blender
vertices by index when the exporter kept Blender's vertex order (checked: same count, median
rest-position distance under 0.1 mm, none over 1 cm — the R52 export baked the arms'
corrective-smooth modifier, which moves 166 vertices by up to 6 mm), otherwise by nearest
rest position within 0.05 mm (glTF Y-up: gx = bx, gy = bz, gz = -by). Anything else is refused.
"""
import json, struct, sys, hashlib
from pathlib import Path
import numpy as np
sys.path.insert(0, str(Path(__file__).parent))
from merge_r52_armor_and_animations import read_glb, align4, JSON_CHUNK, BIN_CHUNK

CT = {5121: np.uint8, 5123: np.uint16, 5126: np.float32}
NC = {"VEC3": 3, "VEC4": 4}


def view(j, b, acc_i):
    a = j["accessors"][acc_i]; bv = j["bufferViews"][a["bufferView"]]
    n = NC[a["type"]]; dt = np.dtype(CT[a["componentType"]])
    stride = bv.get("byteStride", n * dt.itemsize)
    if stride != n * dt.itemsize:
        raise ValueError("strided accessor not supported")
    off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    return off, a["count"], n, dt


def nearest(pb, bl):
    cnt = len(pb); match = np.empty(cnt, int); err = np.empty(cnt)
    for i0 in range(0, cnt, 512):
        dd = np.linalg.norm(pb[i0:i0 + 512, None, :] - bl[None], axis=2)
        match[i0:i0 + 512] = dd.argmin(1); err[i0:i0 + 512] = dd.min(1)
    if err.max() > 5e-5:
        raise ValueError("GLB vertex %.6f m from any Blender vertex" % err.max())
    return match


def main(src, wjson, out):
    j, b = read_glb(src)
    b = bytearray(b)
    W = json.load(open(wjson))
    joints = [j["nodes"][k]["name"] for k in j["skins"][0]["joints"]]
    for name, d in W.items():
        node = next(n for n in j["nodes"] if n.get("name") == name)
        prims = j["meshes"][node["mesh"]]["primitives"]
        bl = np.array(d["local_positions"]); bw = np.array(d["weights"])
        jidx = [joints.index(x) for x in d["bones"]]
        for p in prims:
            match = None
            off, cnt, n, dt = view(j, b, p["attributes"]["POSITION"])
            pos = np.frombuffer(bytes(b[off:off + cnt * 12]), np.float32).reshape(-1, 3)
            pb = np.c_[pos[:, 0], -pos[:, 2], pos[:, 1]]
            if cnt == len(bl):
                e = np.linalg.norm(pb - bl, axis=1)
                if np.median(e) < 1e-4 and e.max() < 1e-2:
                    match = np.arange(cnt)
                    print(name, "same vertex order: median %.1e m, max %.1e m" % (np.median(e), e.max()))
            if cnt != len(bl) or match is None:
                match = nearest(pb, bl)
            jo, jc, jn, jdt = view(j, b, p["attributes"]["JOINTS_0"])
            wo, wc, wn, wdt = view(j, b, p["attributes"]["WEIGHTS_0"])
            if jdt != np.uint8 or wdt != np.float32 or jc != cnt or wc != cnt:
                raise ValueError("unexpected skin accessor layout")
            J = np.zeros((cnt, 4), np.uint8); WW = np.zeros((cnt, 4), np.float32)
            for i, m in enumerate(match):
                nz = np.nonzero(bw[m])[0]
                nz = nz[np.argsort(-bw[m][nz])][:4]
                J[i, :len(nz)] = [jidx[k] for k in nz]
                WW[i, :len(nz)] = bw[m][nz]
            WW /= WW.sum(1, keepdims=True)
            b[jo:jo + J.nbytes] = J.tobytes(); b[wo:wo + WW.nbytes] = WW.tobytes()
            print(name, cnt, "vertices rewritten")
    js = align4(json.dumps(j, separators=(",", ":")).encode(), b" ")
    bb = align4(bytes(b), b"\0")
    raw = struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(js) + 8 + len(bb)) + struct.pack("<II", len(js), JSON_CHUNK) + js + struct.pack("<II", len(bb), BIN_CHUNK) + bb
    Path(out).write_bytes(raw)
    print(out, len(raw), hashlib.sha256(raw).hexdigest())


if __name__ == "__main__":
    main(*sys.argv[1:4])
