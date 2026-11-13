#!/usr/bin/env python3
"""Combine six single-action Higgsfield GLB previews into one playable GLB.

Input snapshots share the same rig, meshes, skin and packed materials.
Only animation accessor/bufferView payloads are copied into the canonical
Idle GLB. No remeshing, rebinding or resampling is performed.

Use: python3 assemble_aotl_warrior.py /path/to/export_folder
Outputs: AOTL_Warrior_R39_Gameplay6.glb and audit JSON in the export folder.
"""
import copy
import hashlib
import json
import pathlib
import struct
import sys

CLIPS = [
    ("Idle", "AOTL_46_Idle.glb"),
    ("Walk", "AOTL_R41_Walk.glb"),
    ("Run", "AOTL_42_Run.glb"),
    ("Dodge", "AOTL_43_Dodge.glb"),
    ("Slash", "AOTL_44_Slash.glb"),
    ("Cast", "AOTL_45_Cast.glb"),
]
JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942


def read_glb(path):
    data = pathlib.Path(path).read_bytes()
    if len(data) < 20:
        raise ValueError(f"{path}: too small")
    magic, version, declared = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or declared != len(data):
        raise ValueError(f"{path}: malformed header")
    offset = 12
    chunks = []
    while offset < len(data):
        length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunks.append((chunk_type, data[offset:offset + length]))
        offset += length
    if offset != len(data):
        raise ValueError(f"{path}: malformed chunk boundary")
    if len(chunks) < 2 or chunks[0][0] != JSON_CHUNK or chunks[1][0] != BIN_CHUNK:
        raise ValueError(f"{path}: requires JSON and BIN chunks")
    payload = json.loads(chunks[0][1].decode("utf-8").rstrip(" \t\r\n\x00"))
    return payload, chunks[1][1]


def align4(data):
    return data + b"\x00" * ((-len(data)) % 4)


def combine(folder):
    folder = pathlib.Path(folder)
    assets = [(name, *read_glb(folder / filename)) for name, filename in CLIPS]
    base_name, output, base_bin = assets[0]
    output = copy.deepcopy(output)
    base_nodes = [node.get("name") for node in output.get("nodes", [])]
    base_mesh = [mesh.get("name") for mesh in output.get("meshes", [])]
    base_skins = output.get("skins", [])
    original_binary = base_bin[:output["buffers"][0]["byteLength"]]
    data = bytearray(align4(original_binary))
    output["animations"] = []
    stats = []

    for name, doc, payload in assets:
        if [node.get("name") for node in doc.get("nodes", [])] != base_nodes:
            raise ValueError(f"{name}: incompatible node indices")
        if [mesh.get("name") for mesh in doc.get("meshes", [])] != base_mesh:
            raise ValueError(f"{name}: incompatible mesh indices")
        if doc.get("skins", []) != base_skins:
            raise ValueError(f"{name}: incompatible skin joint mapping")
        if len(doc.get("animations", [])) != 1:
            raise ValueError(f"{name}: expected exactly one action snapshot")
        anim = copy.deepcopy(doc["animations"][0])
        source_accessors = doc.get("accessors", [])
        source_views = doc.get("bufferViews", [])
        accessor_map = {}
        view_map = {}

        def import_view(old):
            if old in view_map:
                return view_map[old]
            source = source_views[old]
            if source.get("buffer", 0) != 0:
                raise ValueError(f"{name}: unexpected second buffer")
            start = source.get("byteOffset", 0)
            end = start + source["byteLength"]
            if end > len(payload):
                raise ValueError(f"{name}: truncated bufferView")
            target_start = len(data)
            data.extend(payload[start:end])
            while len(data) % 4:
                data.append(0)
            replacement = copy.deepcopy(source)
            replacement["buffer"] = 0
            replacement["byteOffset"] = target_start
            view_map[old] = len(output["bufferViews"])
            output["bufferViews"].append(replacement)
            return view_map[old]

        def import_accessor(old):
            if old in accessor_map:
                return accessor_map[old]
            acc = copy.deepcopy(source_accessors[old])
            if "bufferView" in acc:
                acc["bufferView"] = import_view(acc["bufferView"])
            if "sparse" in acc:
                for section in ("indices", "values"):
                    acc["sparse"][section]["bufferView"] = import_view(
                        acc["sparse"][section]["bufferView"]
                    )
            accessor_map[old] = len(output["accessors"])
            output["accessors"].append(acc)
            return accessor_map[old]

        for sampler in anim["samplers"]:
            sampler["input"] = import_accessor(sampler["input"])
            sampler["output"] = import_accessor(sampler["output"])
        for channel in anim["channels"]:
            index = channel["target"].get("node")
            if not isinstance(index, int) or not 0 <= index < len(base_nodes):
                raise ValueError(f"{name}: invalid animation target")
        anim["name"] = name
        output["animations"].append(anim)
        input_maxima = []
        for sampler in anim["samplers"]:
            acc = output["accessors"][sampler["input"]]
            input_maxima.extend(acc.get("max", []))
        duration = max(input_maxima, default=0)
        if duration <= 0 or len(anim["channels"]) < 30:
            raise ValueError(f"{name}: empty or degenerate animation")
        stats.append({"name": name, "duration_seconds": round(duration, 5),
                      "channels": len(anim["channels"]),
                      "imported_accessors": len(accessor_map)})

    output["buffers"][0]["byteLength"] = len(data)
    output.setdefault("asset", {}).setdefault("extras", {})["aotl"] = {
        "release": "R39_Gameplay6",
        "base_revision": 39,
        "authoring_backup_revision": 36,
        "production_fallback_revision": 37,
        "action_sources": dict(CLIPS),
    }
    json_chunk = json.dumps(output, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    json_chunk += b" " * ((-len(json_chunk)) % 4)
    bin_chunk = align4(bytes(data))
    total = 12 + 8 + len(json_chunk) + 8 + len(bin_chunk)
    encoded = (
        struct.pack("<4sII", b"glTF", 2, total)
        + struct.pack("<II", len(json_chunk), JSON_CHUNK) + json_chunk
        + struct.pack("<II", len(bin_chunk), BIN_CHUNK) + bin_chunk
    )
    output_path = folder / "AOTL_Warrior_R39_Gameplay6.glb"
    output_path.write_bytes(encoded)
    back, packed_bin = read_glb(output_path)
    if len(back["animations"]) != len(CLIPS):
        raise ValueError("Readback animation count mismatch")
    names = [a["name"] for a in back["animations"]]
    if names != [c[0] for c in CLIPS]:
        raise ValueError(f"Readback clip names invalid: {names}")
    joint_indices = {i for skin in back["skins"] for i in skin.get("joints", [])}
    bones = {base_nodes[i] for i in joint_indices}
    required = {"Root","Hips","ThighL","KneeL","ShinL","AnkleL","FootL",
                "ThighR","KneeR","ShinR","AnkleR","FootR"}
    if required - bones:
        raise ValueError(f"Missing skin joints: {required-bones}")
    report = {
        "result": "PASS",
        "file": output_path.name,
        "bytes": len(encoded),
        "sha256": hashlib.sha256(encoded).hexdigest(),
        "skins": len(back["skins"]),
        "skin_joints": len(bones),
        "meshes": len(back["meshes"]),
        "actions": stats,
        "known_limitations": [
            "Structural validation is not a Godot rendering or gameplay test.",
            "Visual material fidelity requires manual Godot comparison."
        ],
    }
    (folder / "AOTL_Warrior_R39_Gameplay6.audit.json").write_text(
        json.dumps(report, indent=2) + "\n"
    )
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    combine(sys.argv[1] if len(sys.argv) > 1 else "/home/user/aotl_exports")
