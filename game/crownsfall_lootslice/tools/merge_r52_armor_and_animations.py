#!/usr/bin/env python3
"""Preserve the complete R52 armored mesh/skin and the seven tested R50 clips.

Read two independently validated glTF 2.0 binary files:
- R52 Blender export: improved hard-surface armor skinning, single active action
- R50 gameplay GLB: six original actions plus independent full-body Slash

Copy glTF *animation data only* from R50 to R52. Do not use an R50 mesh
as the base, or the R52 armor improvements would silently disappear.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import struct

JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942
REQUIRED = ["Idle", "Walk", "Run", "Dodge", "Slash", "Cast", "Slash_FullBody_R50"]


def read_glb(path):
    raw = Path(path).read_bytes()
    if len(raw) < 28:
        raise ValueError("GLB truncated")
    magic, version, length = struct.unpack_from("<4sII", raw)
    if magic != b"glTF" or version != 2 or length != len(raw):
        raise ValueError("Expected complete glTF 2 GLB")
    pos = 12
    chunks = []
    while pos + 8 <= len(raw):
        length, kind = struct.unpack_from("<II", raw, pos)
        pos += 8
        blob = raw[pos:pos + length]
        if len(blob) != length:
            raise ValueError("Truncated GLB chunk")
        chunks.append((kind, blob))
        pos += length
    if pos != len(raw) or len(chunks) != 2:
        raise ValueError("Expected exactly JSON and BIN chunks")
    if chunks[0][0] != JSON_CHUNK or chunks[1][0] != BIN_CHUNK:
        raise ValueError("Unexpected GLB chunk types")
    return json.loads(chunks[0][1].decode().rstrip(" \t\r\n\0")), chunks[1][1]


def align4(data, pad_byte):
    return data + pad_byte * ((-len(data)) % 4)


def make(r52_mesh, r50_animations, output):
    mesh, mesh_bin = read_glb(r52_mesh)
    source, source_bin = read_glb(r50_animations)
    if [a.get("name") for a in source["animations"]] != REQUIRED:
        raise ValueError("R50 seven-action source is unexpected")
    if len(mesh.get("animations", [])) != 1:
        raise ValueError("R52 must be the single-action geometry export")
    if [n.get("name") for n in mesh["nodes"]] != [n.get("name") for n in source["nodes"]]:
        raise ValueError("Rig node order or names changed")
    if [m.get("name") for m in mesh["meshes"]] != [m.get("name") for m in source["meshes"]]:
        raise ValueError("Mesh object order changed")
    if mesh["skins"] != source["skins"]:
        raise ValueError("Skins and joint mappings differ")
    for path in [r52_mesh, r50_animations]:
        if Path(path).stat().st_size > 250000000:
            raise ValueError("Unexpected huge input model")
    if mesh["buffers"][0]["byteLength"] > len(mesh_bin) or source["buffers"][0]["byteLength"] > len(source_bin):
        raise ValueError("Incomplete source BIN data")
    expected_meshes = copy.deepcopy(mesh["meshes"])
    expected_skins = copy.deepcopy(mesh["skins"])
    expected_nodes = copy.deepcopy(mesh["nodes"])
    mesh["animations"] = []
    raw_buffer = bytearray(align4(mesh_bin[:mesh["buffers"][0]["byteLength"]], b"\0"))
    view_map = {}
    accessor_map = {}

    def import_view(index):
        if index in view_map:
            return view_map[index]
        view = copy.deepcopy(source["bufferViews"][index])
        if view.get("buffer", 0) != 0:
            raise ValueError("Unexpected external animation buffer")
        start, n = view.get("byteOffset", 0), view["byteLength"]
        section = source_bin[start:start+n]
        if len(section) != n:
            raise ValueError("Out-of-range animation view")
        view["byteOffset"] = len(raw_buffer)
        view["buffer"] = 0
        raw_buffer.extend(section)
        while len(raw_buffer) % 4:
            raw_buffer.append(0)
        view_map[index] = len(mesh["bufferViews"])
        mesh["bufferViews"].append(view)
        return view_map[index]

    def import_accessor(index):
        if index in accessor_map:
            return accessor_map[index]
        a = copy.deepcopy(source["accessors"][index])
        if "bufferView" in a:
            a["bufferView"] = import_view(a["bufferView"])
        if "sparse" in a:
            for entry in ("indices", "values"):
                a["sparse"][entry]["bufferView"] = import_view(a["sparse"][entry]["bufferView"])
        accessor_map[index] = len(mesh["accessors"])
        mesh["accessors"].append(a)
        return accessor_map[index]

    for original in source["animations"]:
        animation = copy.deepcopy(original)
        for sampler in animation["samplers"]:
            sampler["input"] = import_accessor(sampler["input"])
            sampler["output"] = import_accessor(sampler["output"])
        for channel in animation["channels"]:
            index = channel["target"].get("node")
            if not isinstance(index, int) or index < 0 or index >= len(mesh["nodes"]):
                raise ValueError("Animation channel targets missing node")
        mesh["animations"].append(animation)

    mesh["buffers"][0]["byteLength"] = len(raw_buffer)
    mesh.setdefault("asset", {}).setdefault("extras", {})["aotl_r52"] = {
        "armor_skinning": "shoulder plates 100% upper arm, cuirass 100% chest",
        "source_higgsfield_revision": 52,
        "animation_source": "R50 existing seven-clip model",
        "stable_r50_asset_unchanged": True,
    }
    json_bytes = align4(json.dumps(mesh, separators=(",", ":")).encode(), b" ")
    bin_bytes = align4(bytes(raw_buffer), b"\0")
    raw = struct.pack("<4sII", b"glTF", 2, 12+8+len(json_bytes)+8+len(bin_bytes))
    raw += struct.pack("<II", len(json_bytes), JSON_CHUNK) + json_bytes
    raw += struct.pack("<II", len(bin_bytes), BIN_CHUNK) + bin_bytes
    destination = Path(output)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(raw)
    check, checked_bin = read_glb(destination)
    assert [a["name"] for a in check["animations"]] == REQUIRED
    assert check["meshes"] == expected_meshes
    assert check["skins"] == expected_skins
    assert check["nodes"] == expected_nodes
    assert len(check["skins"][0]["joints"]) == 62
    assert len(check["meshes"]) == 92
    report = {
        "result": "VALID_GLB_UNTIL_GODOT_IMPORT",
        "file": destination.name,
        "sha256": hashlib.sha256(raw).hexdigest(),
        "bytes": len(raw),
        "clips": REQUIRED,
        "meshes": len(check["meshes"]),
        "skin_joints": len(check["skins"][0]["joints"]),
        "animations_channels": [len(a["channels"]) for a in check["animations"]],
        "r52_geometry_glb_sha256": hashlib.sha256(Path(r52_mesh).read_bytes()).hexdigest(),
        "r50_animations_glb_sha256": hashlib.sha256(Path(r50_animations).read_bytes()).hexdigest(),
        "geometry_and_skin_preserved": True,
        "old_six_clips_and_r50_slash_preserved": True,
        "remaining": "Actual Godot GLB import, recorded bone pose and gameplay collision verification",
    }
    destination.with_suffix(".audit.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


if __name__ == "__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--r52-geometry", required=True)
    p.add_argument("--r50-animation", required=True)
    p.add_argument("--out", required=True)
    args=p.parse_args()
    print(json.dumps(make(args.r52_geometry, args.r50_animation, args.out), indent=2))
