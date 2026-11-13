#!/usr/bin/env python3
"""Read-only Blender 5.2 QA for the editable Higgsfield Phase18 Citadel v5 sculpt.

Usage:
  blender --background AOTL_Citadel_Higgsfield_Phase18_v05.blend --python tools/validate_citadel_sculpt_v18.py

This script never applies modifiers or alters the scene; only reports geometry
and exits nonzero if this sculpt does not meet its own isolated design envelope.
It does NOT establish Godot F5 approval or canonical art quality.
"""
import bpy
import json
import math
import sys

errors = []
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
treads = [bpy.data.objects.get(f"STAIR_Tread_{i:02}") for i in range(1,10)]
rosettes = [bpy.data.objects.get(f"PH18_Parapet_GothicRosette_{s}_{i:02}")
            for s in ("L","R") for i in range(1,10)]
voussoirs = [o for o in meshes if o.name.startswith("GATE_Gothic_Voussoir_")]
if len(meshes) != 481:
    errors.append(f"Expected 481 mesh objects, got {len(meshes)}")
if len(voussoirs) != 32:
    errors.append(f"Expected 32 Gothic arch voussoirs, got {len(voussoirs)}")
if any(t is None for t in treads):
    errors.append("Missing one or more of the nine original stone tread objects")
if any(o is None for o in rosettes):
    errors.append("Missing one or more of the eighteen rosettes")
if all(t is not None for t in treads):
    for i, tread in enumerate(treads):
        surface = tread.location.z + tread.dimensions.z * 0.5
        expected_surface = (i+1) * 0.2
        if abs(surface - expected_surface) > .015:
            errors.append(f"{tread.name}: top surface {surface:.3f}, expected {expected_surface:.3f}")
        if abs(tread.location.y - (-8.5+i)) > .015:
            errors.append(f"{tread.name}: incorrect one-metre step spacing")
        if abs(tread.dimensions.x - 7.5) > .015:
            errors.append(f"{tread.name}: central corridor width changed")
if all(o is not None for o in rosettes):
    if len({o.data.as_pointer() for o in rosettes}) != 1:
        errors.append("Decorative rosettes no longer share the same mesh datablock")
    for r in rosettes:
        if abs(r.location.x) <= 3.75:
            errors.append(f"{r.name}: protrudes into player corridor")
        if r.get("AOTL_visual_only") is not True or r.get("AOTL_collision") is not False:
            errors.append(f"{r.name}: art-only flag lost")
        if not r.data.materials or r.data.materials[0].name != "MAT_Brushed_Royal_Brass":
            errors.append(f"{r.name}: incorrect material")
unpacked = [im.name for im in bpy.data.images if im.source == "FILE" and not im.packed_file]
if unpacked:
    errors.append(f"Missing packed external texture guarantees: {unpacked}")
report = {
    "schema": "aotl.citadel.phase18.blender_sculpt_qa.v1",
    "status": "PASS" if not errors else "FAIL",
    "mesh_count": len(meshes),
    "tread_count": sum(t is not None for t in treads),
    "voussoir_count": len(voussoirs),
    "rosette_count": sum(o is not None for o in rosettes),
    "packed_images": sum(bool(im.packed_file) for im in bpy.data.images),
    "unpacked_images": unpacked,
    "art_only": True,
    "godot_f5_playable_verified": False,
    "approved_canon_art_quality": False,
    "errors": errors,
}
print(json.dumps(report, indent=2))
if errors:
    sys.exit(1)
