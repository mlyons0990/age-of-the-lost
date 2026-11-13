"""AOTL Warrior: make six gameplay animation actions deterministic.

Blender 5.2:
  blender --background Warrior_R39.blend --python tools/normalize_warrior_actions.py \
    -- --output Warrior_R40_PoseStable.blend

Does NOT overwrite the source .blend. All deliberately keyed animation channels
are preserved (including Dodge's complete rotation); only previously unkeyed
bone rotation and location channels get neutral pose keys at clip endpoints.
"""
import argparse
import json
import sys
from pathlib import Path
import bpy

CORE = ("Idle", "Walk", "Run", "Dodge", "Slash", "Cast")
RIG = "RIG_AOTL_Master_Humanoid_58"


def normalize():
    rig = bpy.data.objects.get(RIG)
    if rig is None or rig.type != "ARMATURE":
        raise RuntimeError("Cannot find AOTL 62-bone armature")
    if len(rig.data.bones) != 62:
        raise RuntimeError("Unexpected bone count: " + str(len(rig.data.bones)))
    if rig.animation_data is None:
        rig.animation_data_create()
    report = {}
    for name in CORE:
        action = bpy.data.actions.get(name)
        if action is None or len(action.slots) != 1:
            raise RuntimeError("Missing or ambiguous slotted action: " + name)
        rig.animation_data.action = action
        rig.animation_data.action_slot = action.slots[0]
        bag = action.layers[0].strips[0].channelbag(action.slots[0])
        keyed = {curve.data_path for curve in bag.fcurves}
        start, end = [int(n) for n in action.frame_range]
        added_rotation = added_location = 0
        for pose in rig.pose.bones:
            prefix = 'pose.bones["' + pose.name + '"]'
            if not any(path.startswith(prefix + '.rotation_') for path in keyed):
                pose.rotation_mode = "XYZ"
                pose.rotation_euler = (0.0, 0.0, 0.0)
                for frame in (start, end):
                    pose.keyframe_insert(data_path="rotation_euler", frame=frame, group="R40 neutral pose")
                added_rotation += 1
            if prefix + ".location" not in keyed:
                pose.location = (0.0, 0.0, 0.0)
                for frame in (start, end):
                    pose.keyframe_insert(data_path="location", frame=frame, group="R40 neutral pose")
                added_location += 1
        action.use_fake_user = True
        report[name] = {
            "reset_rotation_bones": added_rotation,
            "reset_location_bones": added_location,
            "original_keyed_channels_unchanged": True
        }
    idle = bpy.data.actions["Idle"]
    rig.animation_data.action = idle
    rig.animation_data.action_slot = idle.slots[0]
    bpy.context.scene.frame_set(1)
    return report


def parse():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args(args)


def main():
    args = parse()
    output = args.output.expanduser().resolve()
    source = Path(bpy.data.filepath).resolve()
    if not str(bpy.data.filepath):
        raise RuntimeError("Open the source .blend first")
    if output == source:
        raise RuntimeError("Refusing to overwrite source Blender file")
    if output.suffix.lower() != ".blend":
        raise RuntimeError("Output must be a .blend file")
    details = normalize()
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output))
    print(json.dumps({"source": str(source), "output": str(output), "actions": details}, indent=2))


if __name__ == "__main__":
    main()
