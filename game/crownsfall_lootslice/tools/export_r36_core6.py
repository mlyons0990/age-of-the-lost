"""Export the six production Warrior clips from an existing Blender .blend.

Blender 5.2:
  blender --background AOTL_Warrior_R36.blend \
      --python tools/export_r36_core6.py -- \
      --output models/AOTL_Warrior_R36.glb

Changes are applied ONLY in Blender process memory. Source .blend is never saved.
The 62-bone rig and mesh data remain unchanged. All 6 core source actions survive
in the export; experimental action variants remain in the original .blend backup.
"""
import argparse
import json
import struct
import sys
import time
from pathlib import Path
import bpy

CORE = ("Idle", "Walk", "Run", "Dodge", "Slash", "Cast")
RIG_NAME = "RIG_AOTL_Master_Humanoid_58"


def get_args():
    params = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args(params)


def main():
    args = get_args()
    armature = bpy.data.objects.get(RIG_NAME)
    if armature is None or armature.type != "ARMATURE":
        raise RuntimeError("Expected AOTL 62-bone Warrior rig was not found")
    if armature.animation_data is None:
        armature.animation_data_create()
    missing = [a for a in CORE if a not in bpy.data.actions]
    if missing:
        raise RuntimeError(f"Missing source actions: {missing}")
    # Preserve authoring source; discard non-production actions only in this
    # transient Blender process to avoid hundreds of expensive constraint bakes.
    for action in list(bpy.data.actions):
        if action.name not in CORE:
            bpy.data.actions.remove(action)
    armature.animation_data.action = bpy.data.actions["Idle"]
    removed = 0
    for pose_bone in armature.pose.bones:
        for constraint in list(pose_bone.constraints):
            pose_bone.constraints.remove(constraint)
            removed += 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    bpy.ops.export_scene.gltf(
        filepath=str(args.output.resolve()),
        export_format="GLB",
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_skins=True,
        export_anim_single_armature=True,
    )
    # Read back the actual exported glTF JSON; action presence in the source
    # does not prove it survived binary export.
    with args.output.open("rb") as f:
        magic, version, actual_size = struct.unpack("<4sII", f.read(12))
        json_length, chunk_type = struct.unpack("<II", f.read(8))
        if magic != b"glTF" or version != 2 or chunk_type != 0x4E4F534A:
            raise RuntimeError("Export is not a glTF 2.0 GLB")
        gltf = json.loads(f.read(json_length).decode("utf-8").rstrip(" \x00"))
    if actual_size != args.output.stat().st_size:
        raise RuntimeError("GLB header length mismatch")
    exported = {
        a.get("name", "").replace("\\", "/").split("/")[-1].split("|")[-1]
        for a in gltf.get("animations", [])
    }
    if set(CORE) - exported:
        raise RuntimeError(f"GLB missing core action(s): {sorted(set(CORE)-exported)}")
    if not gltf.get("skins") or not gltf.get("meshes"):
        raise RuntimeError("GLB missing skinned geometry")
    print(json.dumps({
        "source_rig": RIG_NAME,
        "bone_count": len(armature.data.bones),
        "removed_export_only_constraints": removed,
        "exported_clips": sorted(exported),
        "meshes": len(gltf["meshes"]),
        "skins": len(gltf["skins"]),
        "bytes": actual_size,
        "elapsed_seconds": round(time.monotonic() - started, 1),
        "output": str(args.output.resolve()),
        "source_blend_overwritten": False,
    }, indent=2))


if __name__ == "__main__":
    main()
