#!/usr/bin/env python3
"""Read-only glTF 2.0 skin-weight audit for the experimental AOTL Warrior.

No Blender, Godot, or third-party Python packages required.
Never edits the GLB. Reports per-joint coverage and mesh weight anomalies.
"""
import argparse
import collections
import json
import pathlib
import struct

COMPONENTS = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
              5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
SHAPES = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def load_glb(path):
    raw = pathlib.Path(path).read_bytes()
    if len(raw) < 20:
        raise ValueError("GLB truncated")
    magic, version, length = struct.unpack_from("<4sII", raw)
    if (magic, version, length) != (b"glTF", 2, len(raw)):
        raise ValueError("Not a complete glTF 2.0 GLB")
    offset = 12
    chunks = []
    while offset < len(raw):
        if offset + 8 > len(raw):
            raise ValueError("Truncated chunk header")
        size, kind = struct.unpack_from("<II", raw, offset)
        offset += 8
        if offset + size > len(raw):
            raise ValueError("Truncated chunk data")
        chunks.append((kind, memoryview(raw)[offset:offset + size]))
        offset += size
    if len(chunks) < 2 or chunks[0][0] != 0x4E4F534A or chunks[1][0] != 0x004E4942:
        raise ValueError("Expected JSON and BIN chunks")
    return json.loads(bytes(chunks[0][1]).decode("utf-8")), chunks[1][1]


def accessor_rows(doc, binary, index):
    a = doc["accessors"][index]
    if "sparse" in a:
        raise ValueError("Sparse accessors require a separate validation pass")
    if "bufferView" not in a:
        raise ValueError("Accessor without bufferView is unsupported")
    view = doc["bufferViews"][a["bufferView"]]
    if view.get("buffer", 0) != 0:
        raise ValueError("External buffer is unsupported")
    fmt, width = COMPONENTS[a["componentType"]]
    n = SHAPES[a["type"]]
    packed = width * n
    stride = view.get("byteStride", packed)
    if stride < packed:
        raise ValueError("Invalid accessor stride")
    start = view.get("byteOffset", 0) + a.get("byteOffset", 0)
    end = view.get("byteOffset", 0) + view["byteLength"]
    if end > len(binary):
        raise ValueError("BufferView exceeds BIN chunk")
    unpack = struct.Struct("<" + fmt * n)
    values = []
    for row in range(a["count"]):
        pos = start + row * stride
        if pos + packed > end:
            raise ValueError("Accessor exceeds bufferView")
        v = unpack.unpack_from(binary, pos)
        if a.get("normalized") and a["componentType"] != 5126:
            bits = 8 * width
            if a["componentType"] in (5120, 5122):
                v = tuple(max(-1.0, x / ((1 << (bits - 1)) - 1)) for x in v)
            else:
                v = tuple(x / ((1 << bits) - 1) for x in v)
        values.append(v)
    return values


def audit(doc, binary, tolerance=0.025):
    names = [n.get("name", "node_" + str(i)) for i, n in enumerate(doc.get("nodes", []))]
    skins = doc.get("skins", [])
    mesh_to_skins = collections.defaultdict(set)
    for node in doc.get("nodes", []):
        if "mesh" in node and "skin" in node:
            mesh_to_skins[node["mesh"]].add(node["skin"])
    result = {"asset": doc.get("asset", {}).get("generator", "unknown"),
              "skins": len(skins), "meshes": len(doc.get("meshes", [])),
              "skinned_primitives": 0, "skinned_vertices": 0,
              "weight_sum_outliers": 0, "zero_influence_vertices": 0,
              "invalid_joint_references": 0, "unused_skin_joints": {},
              "mesh_reports": [], "warnings": []}
    coverage = {s: collections.Counter() for s in range(len(skins))}
    for mesh_index, mesh in enumerate(doc.get("meshes", [])):
        skin_ids = sorted(mesh_to_skins.get(mesh_index, []))
        if not skin_ids:
            continue
        for prim_index, prim in enumerate(mesh.get("primitives", [])):
            attrs = prim.get("attributes", {})
            if "POSITION" not in attrs:
                continue
            if "JOINTS_0" not in attrs or "WEIGHTS_0" not in attrs:
                result["warnings"].append(f"Mesh {mesh_index} primitive {prim_index}: skinned without JOINTS_0/WEIGHTS_0")
                continue
            sets = []
            for suffix in ("0", "1"):
                j, w = "JOINTS_" + suffix, "WEIGHTS_" + suffix
                if (j in attrs) != (w in attrs):
                    raise ValueError(f"Unpaired joint/weight attribute in mesh {mesh_index}")
                if j in attrs:
                    sets.append((accessor_rows(doc, binary, attrs[j]),
                                 accessor_rows(doc, binary, attrs[w])))
            count = doc["accessors"][attrs["POSITION"]]["count"]
            for jrows, wrows in sets:
                if len(jrows) != count or len(wrows) != count:
                    raise ValueError("Joint/weight attribute count mismatch")
            local = {"mesh": mesh.get("name", f"mesh_{mesh_index}"), "mesh_index": mesh_index,
                     "primitive": prim_index, "vertices": count, "skin_indices": skin_ids,
                     "sum_outliers": 0, "zero_influence": 0, "invalid_joint_references": 0,
                     "joint_influences": {}}
            influences = collections.Counter()
            for vertex in range(count):
                weights = []
                for jrows, wrows in sets:
                    weights.extend(zip(jrows[vertex], wrows[vertex]))
                positive = [(int(j), float(w)) for j, w in weights if w > 1e-6]
                total = sum(w for _, w in positive)
                if abs(total - 1.0) > tolerance:
                    local["sum_outliers"] += 1
                if not positive:
                    local["zero_influence"] += 1
                for joint, weight in positive:
                    influences[joint] += 1
                    if any(joint >= len(skins[s]["joints"]) or joint < 0 for s in skin_ids):
                        local["invalid_joint_references"] += 1
                    else:
                        for s in skin_ids:
                            coverage[s][joint] += 1
            local["joint_influences"] = {
                names[skins[skin_ids[0]]["joints"][j]] if 0 <= j < len(skins[skin_ids[0]]["joints"]) else f"INVALID_{j}": c
                for j, c in sorted(influences.items())
            }
            result["skinned_primitives"] += 1
            result["skinned_vertices"] += count
            for key, source in (("weight_sum_outliers", "sum_outliers"),
                                ("zero_influence_vertices", "zero_influence"),
                                ("invalid_joint_references", "invalid_joint_references")):
                result[key] += local[source]
            result["mesh_reports"].append(local)
    for s, skin in enumerate(skins):
        result["unused_skin_joints"][str(s)] = [
            names[node] for i, node in enumerate(skin["joints"]) if coverage[s][i] == 0
        ]
    if not result["skinned_vertices"]:
        result["warnings"].append("No skinned vertices encountered; inspect node-to-skin mappings")
    if result["invalid_joint_references"]:
        result["warnings"].append("Joint indices outside skin palette")
    if result["weight_sum_outliers"]:
        result["warnings"].append("Weight sums outside configured tolerance")
    if result["zero_influence_vertices"]:
        result["warnings"].append("Vertices with zero effective skin influences")
    result["status"] = "needs_review" if result["warnings"] else "structural_pass"
    result["note"] = "Structural skinning only; no claim about silhouette, anatomical deformation or visual parity."
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--glb", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--tolerance", type=float, default=0.025)
    parser.add_argument("--strict", action="store_true", help="Fail on structural anomalies")
    args = parser.parse_args()
    if not 0 <= args.tolerance <= 1:
        parser.error("tolerance must be between 0 and 1")
    doc, binary = load_glb(args.glb)
    report = audit(doc, binary, args.tolerance)
    pathlib.Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(args.out).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in report.items() if k not in ("mesh_reports", "unused_skin_joints")}, indent=2))
    if args.strict and report["status"] != "structural_pass":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
