#!/usr/bin/env python3
"""AOTL R36 binary import gate. Requires only Python 3.9+ (no Blender/Godot).

Usage:
  python tools/verify_r36_glb.py models/AOTL_Warrior_R36.glb
  python tools/verify_r36_glb.py path/to/export.glb --report path/to/audit.json

This tool checks the *exported bytes*, not the Blender source scene. It
deliberately rejects an export with no playable animation clips or no skin.
"""
from __future__ import annotations

import argparse
import json
import os
import struct
import sys
from pathlib import Path

MAGIC = b"glTF"
JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942
REQUIRED_BONES = (
    "Root", "Hips", "ThighL", "KneeL", "ShinL", "AnkleL", "FootL",
    "ThighR", "KneeR", "ShinR", "AnkleR", "FootR",
)
REQUIRED_ACTIONS = ("Idle", "Walk", "Run", "Dodge", "Slash", "Cast")


def load_glb_json(path: Path) -> tuple[dict, dict]:
    size = path.stat().st_size
    if size < 20:
        raise ValueError("GLB file is too small to contain a valid header")
    with path.open("rb") as handle:
        header = handle.read(12)
        magic, version, claimed_size = struct.unpack("<4sII", header)
        if magic != MAGIC or version != 2:
            raise ValueError("Expected a glTF 2.0 GLB")
        if claimed_size != size:
            raise ValueError(f"GLB length mismatch: header={claimed_size}, actual={size}")
        chunk_type = None
        found = None
        bin_chunks = 0
        while handle.tell() < size:
            chunk_header = handle.read(8)
            if len(chunk_header) != 8:
                raise ValueError("Truncated GLB chunk header")
            chunk_length, chunk_type = struct.unpack("<II", chunk_header)
            if chunk_length % 4:
                raise ValueError("GLB chunk length is not 4-byte aligned")
            if chunk_length > size - handle.tell():
                raise ValueError("Truncated GLB chunk payload")
            if chunk_type == JSON_CHUNK:
                if found is not None:
                    raise ValueError("Multiple JSON chunks are not supported")
                found = handle.read(chunk_length)
            elif chunk_type == BIN_CHUNK:
                bin_chunks += 1
                handle.seek(chunk_length, os.SEEK_CUR)
            else:
                handle.seek(chunk_length, os.SEEK_CUR)
        if found is None:
            raise ValueError("No JSON chunk in GLB")
        raw = json.loads(found.decode("utf-8").rstrip(" \t\r\n\x00"))
        if not isinstance(raw, dict):
            raise ValueError("Invalid glTF JSON root")
    return raw, {"bytes": size, "bin_chunks": bin_chunks}


def canonical_action_name(name: str) -> str:
    return name.replace("\\", "/").split("/")[-1].split("|")[-1]


def inspect_document(document: dict, binary_info: dict, expected_size: int | None = None) -> dict:
    nodes = document.get("nodes", [])
    names = [node.get("name", "") for node in nodes]
    skins = document.get("skins", [])
    joints = set()
    for skin in skins:
        joints.update(skin.get("joints", []))
    joint_names = {names[index] for index in joints if isinstance(index, int) and 0 <= index < len(names)}
    animations = document.get("animations", [])
    action_names = {canonical_action_name(a.get("name", "")) for a in animations}
    meshes = document.get("meshes", [])
    skinned_primitives = sum(
        "JOINTS_0" in primitive.get("attributes", {})
        and "WEIGHTS_0" in primitive.get("attributes", {})
        for mesh in meshes for primitive in mesh.get("primitives", [])
    )
    missing_bones = sorted(set(REQUIRED_BONES) - joint_names)
    missing_actions = sorted(set(REQUIRED_ACTIONS) - action_names)
    warnings = []
    if expected_size is not None and binary_info["bytes"] != expected_size:
        warnings.append(f"GLB differs from expected Higgsfield preview size: {binary_info['bytes']} vs {expected_size}")
    if len(joint_names) < 58:
        warnings.append("Fewer than 58 exported skeleton joints detected")
    if "V33_KneeStable_IK_Comparison" not in action_names:
        warnings.append("Knee-stable IK authoring action not present; Godot can still run procedural IK")
    if "V36_StepUp_PlantedWindow" not in action_names:
        warnings.append("R36 terrain step authoring action not present")
    if not any(mesh.get("primitives") for mesh in meshes):
        warnings.append("No mesh primitives available")
    failures = []
    if not skins:
        failures.append("No skins present")
    if not skinned_primitives:
        failures.append("No skinned mesh primitives with JOINTS_0/WEIGHTS_0")
    if missing_bones:
        failures.append("Missing required skin-joint bones: " + ", ".join(missing_bones))
    if missing_actions:
        failures.append("Missing required clips: " + ", ".join(missing_actions))
    return {
        "pass": not failures,
        "failure_reasons": failures,
        "warnings": warnings,
        "counts": {
            "bytes": binary_info["bytes"],
            "skin_count": len(skins),
            "joint_count": len(joint_names),
            "mesh_count": len(meshes),
            "skinned_primitives": skinned_primitives,
            "animation_count": len(animations),
        },
        "missing_bones": missing_bones,
        "animation_names": sorted(action_names),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("glb", type=Path, help="Path to binary GLB")
    parser.add_argument("--report", type=Path, help="Optional JSON report destination")
    parser.add_argument("--expected-size", type=int, default=6946144)
    args = parser.parse_args()
    try:
        document, binary_info = load_glb_json(args.glb)
        report = inspect_document(document, binary_info, args.expected_size)
    except (OSError, ValueError, TypeError, KeyError, struct.error) as exc:
        report = {"pass": False, "failure_reasons": [str(exc)]}
    payload = json.dumps(report, indent=2, ensure_ascii=False)
    print(payload)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(payload + "\n", encoding="utf-8")
    return 0 if report["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
