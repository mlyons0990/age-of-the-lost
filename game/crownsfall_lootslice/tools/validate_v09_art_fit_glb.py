#!/usr/bin/env python3
"""Verify the V09 Higgsfield artwork-fit GLB before importing it into Godot.

Usage: python tools/validate_v09_art_fit_glb.py path/to/AOTL_Warrior_V09_Topology.glb
Read-only. Standard library, no Godot/Blender dependencies.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import struct
import sys

REQUIRED = {
    "AnatomicalHead": 2882,
    "HAIR_Crown": 1346,
    "LayeredCuirass": 6274,
    "RoyalBlueCape": 8514,
    "RoyalTabard": 242,
    "ShoulderPlateL": 4034,
    "ShoulderPlateR": 4034,
}
EXPECTED_SHA256 = "cdf263322cd86db6d86389904ea851297eb5942cf79134e57dd3a9adb3ab6a5d"
UV_MATERIALS = ("V08_BODY_", "V08_GEAR_")
def check(path: Path) -> dict:
    data = path.read_bytes()
    assert data[:4] == b"glTF", "Not a binary glTF"
    assert struct.unpack_from("<I", data, 8)[0] == len(data), "Invalid GLB length"
    actual_sha = hashlib.sha256(data).hexdigest()
    assert actual_sha == EXPECTED_SHA256, "Not approved V09 revision 25 export"
    size, chunk_type = struct.unpack_from("<II", data, 12)
    assert chunk_type == 0x4E4F534A
    document = json.loads(data[20:20+size])
    assert len(document["skins"]) == 1 and len(document["skins"][0]["joints"]) == 58
    assert len(document["animations"]) == 1
    assert len(document["animations"][0]["channels"]) >= 174
    assert len(document.get("textures", [])) >= 12
    materials = document["materials"]
    required = {}
    for suffix, min_verts in REQUIRED.items():
        found = [m for m in document["meshes"] if suffix in m["name"]]
        assert len(found) == 1, f"Missing or duplicate mesh: {suffix}"
        prim = found[0]["primitives"][0]
        a = prim["attributes"]
        assert {"POSITION", "NORMAL", "JOINTS_0", "WEIGHTS_0"}.issubset(a)
        assert "TEXCOORD_0" in a
        vertex_count = document["accessors"][a["POSITION"]]["count"]
        # GLB may split Blender vertices at UV seams; never fewer than the
        # topology-approved Blender vertex count.
        assert vertex_count >= min_verts, f"{suffix} lost topology"
        m = materials[prim["material"]]
        assert m["name"].startswith(UV_MATERIALS), f"{suffix} not UV-paintable"
        texcoord = m.get("pbrMetallicRoughness", {}).get("baseColorTexture", {}).get("texCoord", 0)
        assert f"TEXCOORD_{texcoord}" in a, f"{suffix} wrong atlas UV channel"
        required[suffix] = {"vertices": vertex_count, "UV": texcoord}
    named = {image.get("name") for image in document["images"]}
    assert {"V08_BODY_PaintPlaceholder_2K", "V08_GEAR_PaintPlaceholder_2K"}.issubset(named)
    return {"sha256": actual_sha, "joints": 58, "channels": len(document["animations"][0]["channels"]), "meshes": required}
if __name__ == "__main__":
    try:
        print("AOTL_V09_GLTF_OK", json.dumps(check(Path(sys.argv[1])), sort_keys=True))
    except (AssertionError, IndexError, FileNotFoundError) as exc:
        print("AOTL_V09_GLTF_FAIL", str(exc), file=sys.stderr)
        sys.exit(1)
