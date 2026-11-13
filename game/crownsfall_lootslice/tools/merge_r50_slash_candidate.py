#!/usr/bin/env python3
"""Append a validated R50 full-body Slash as an opt-in seventh glTF animation.

Never overwrites the original R39 six-action GLB. Source nodes, skins,
mesh geometry and existing animation accessors retain their indices.
"""
import argparse
import copy
import hashlib
import json
import pathlib
import struct

JSON_TYPE = 0x4E4F534A
BIN_TYPE = 0x004E4942
CLIPS = ["Idle", "Walk", "Run", "Dodge", "Slash", "Cast"]
CANDIDATE = "Slash_FullBody_R50"


def read_glb(path):
    raw = pathlib.Path(path).read_bytes()
    if len(raw) < 20:
        raise ValueError("Truncated GLB")
    magic, version, length = struct.unpack_from("<4sII", raw, 0)
    if magic != b"glTF" or version != 2 or length != len(raw):
        raise ValueError("Invalid glTF 2.0 header")
    pos = 12
    chunks = []
    while pos < len(raw):
        length, kind = struct.unpack_from("<II", raw, pos)
        pos += 8
        chunk = raw[pos:pos + length]
        if len(chunk) != length:
            raise ValueError("Truncated GLB chunk")
        chunks.append((kind, chunk))
        pos += length
    if pos != len(raw) or len(chunks) < 2:
        raise ValueError("Malformed GLB chunk structure")
    if chunks[0][0] != JSON_TYPE or chunks[1][0] != BIN_TYPE:
        raise ValueError("Wrong GLB chunk ordering")
    return json.loads(chunks[0][1].decode("utf-8").rstrip("\x00 \t\r\n")), chunks[1][1]


def pad(data, byte):
    return data + byte * ((-len(data)) % 4)


def merge(base_path, candidate_path, destination):
    base, bbin = read_glb(base_path)
    source, sbin = read_glb(candidate_path)
    if [a["name"] for a in base.get("animations", [])] != CLIPS:
        raise ValueError("Unexpected base clip list; refusing to replace source")
    if len(source.get("animations", [])) != 1:
        raise ValueError("Expected a single animation from Blender snapshot")
    for key in ("nodes", "meshes"):
        if [x.get("name") for x in base[key]] != [x.get("name") for x in source[key]]:
            raise ValueError(f"Incompatible {key} index layout")
    if base["skins"] != source["skins"]:
        raise ValueError("Mismatched skeleton joint mapping")
    if base["buffers"][0]["byteLength"] > len(bbin):
        raise ValueError("Base BIN is truncated")
    data = bytearray(pad(bbin[:base["buffers"][0]["byteLength"]], b"\x00"))
    original = copy.deepcopy(base)
    anim = copy.deepcopy(source["animations"][0])
    maps = {"views": {}, "accessors": {}}

    def copy_view(old):
        if old in maps["views"]:
            return maps["views"][old]
        v = copy.deepcopy(source["bufferViews"][old])
        if v.get("buffer", 0) != 0:
            raise ValueError("Only GLB buffer index zero is allowed")
        start = v.get("byteOffset", 0)
        payload = sbin[start:start + v["byteLength"]]
        if len(payload) != v["byteLength"]:
            raise ValueError("Candidate bufferView is out of bounds")
        v["byteOffset"] = len(data)
        v["buffer"] = 0
        data.extend(payload)
        while len(data) % 4:
            data.append(0)
        maps["views"][old] = len(base["bufferViews"])
        base["bufferViews"].append(v)
        return maps["views"][old]

    def copy_accessor(old):
        if old in maps["accessors"]:
            return maps["accessors"][old]
        a = copy.deepcopy(source["accessors"][old])
        if "bufferView" in a:
            a["bufferView"] = copy_view(a["bufferView"])
        if "sparse" in a:
            for role in ("indices", "values"):
                a["sparse"][role]["bufferView"] = copy_view(a["sparse"][role]["bufferView"])
        maps["accessors"][old] = len(base["accessors"])
        base["accessors"].append(a)
        return maps["accessors"][old]

    for sampler in anim["samplers"]:
        sampler["input"] = copy_accessor(sampler["input"])
        sampler["output"] = copy_accessor(sampler["output"])
    for channel in anim["channels"]:
        idx = channel["target"].get("node")
        if not isinstance(idx, int) or idx < 0 or idx >= len(base["nodes"]):
            raise ValueError("Animation channel references an unknown node")
    anim["name"] = CANDIDATE
    base["animations"].append(anim)
    base["buffers"][0]["byteLength"] = len(data)
    base.setdefault("asset", {}).setdefault("extras", {})["aotl_r50"] = {
        "candidate_action": CANDIDATE,
        "source_blender_action": "R50_Slash_Grounded_IKBaked_V3",
        "source_higgsfield_revision": 51,
        "prior_production_actions_unchanged": True,
    }
    blob = pad(json.dumps(base, separators=(",", ":")).encode("utf-8"), b" ")
    body = pad(bytes(data), b"\x00")
    final = (
        struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(blob) + 8 + len(body))
        + struct.pack("<II", len(blob), JSON_TYPE) + blob
        + struct.pack("<II", len(body), BIN_TYPE) + body
    )
    destination = pathlib.Path(destination)
    destination.write_bytes(final)
    again, _ = read_glb(destination)
    if [a["name"] for a in again["animations"]] != CLIPS + [CANDIDATE]:
        raise ValueError("Failed seven-clip readback")
    if again["meshes"] != original["meshes"] or again["skins"] != original["skins"]:
        raise ValueError("Accidentally modified production geometry or skin")
    duration = max(
        again["accessors"][sampler["input"]].get("max", [0])[0]
        for sampler in again["animations"][-1]["samplers"]
    )
    report = {
        "status": "BINARY_VALIDATED_IMPORT_PENDING",
        "name": destination.name,
        "bytes": len(final),
        "sha256": hashlib.sha256(final).hexdigest(),
        "clips": CLIPS + [CANDIDATE],
        "new_clip_duration": duration,
        "new_clip_channels": len(anim["channels"]),
        "skins": len(again["skins"]),
        "skin_joints": len(again["skins"][0]["joints"]),
        "meshes": len(again["meshes"]),
        "source_glb_sha256": hashlib.sha256(pathlib.Path(base_path).read_bytes()).hexdigest(),
        "candidate_single_clip_sha256": hashlib.sha256(pathlib.Path(candidate_path).read_bytes()).hexdigest(),
        "validation": [
            "GLB readback valid",
            "Original six animation names preserved",
            "Mesh geometry and skin references preserved",
            "Seventh animation uses independently copied accessor and view bytes",
        ],
        "remaining": "Godot animation import, visual articulation and playback QA",
    }
    destination.with_suffix(".audit.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", required=True)
    parser.add_argument("--candidate", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    print(json.dumps(merge(args.base, args.candidate, args.out), indent=2))
