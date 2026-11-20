"""Retarget the hand-made Warrior clips (R55 source, 62-bone rig) onto a Meshy auto-rigged knight (24 bones).

Run with Blender 5.2 (or the `bpy` 5.2 module):
  python retarget_r55_to_meshy.py -- <R55 .blend> <meshy rigged .glb> <out .glb> [<out .blend>]

Free alternative to paid `3d_rigging` clips (Higgsfield pilot, 2026-11-20).

Method: world-space rotation transfer. For each mapped pair, the target bone's armature-space
rotation per frame is  Δ_src(t) · R_tgt_rest, with  Δ_src(t) = R_src_pose(t) · R_src_rest⁻¹.
Because Δ is measured in world space it ignores bone roll, rest axes and the different bone counts
(source twist/elbow/knee helpers fold into the next mapped bone). Hips translation is the source
hips offset scaled by the hip-height ratio. Sides are mapped by position, not name: the R52 rig's
"L" bones sit on the character's anatomical right (−X when facing −Y).
"""
import bpy, sys
from mathutils import Matrix, Vector

CLIPS = {"Slash": "R50_Slash_Grounded_IKBaked_V3", "Dodge": "Dodge", "Idle": "Idle", "Walk": "Walk", "Run": "Run", "Cast": "Cast"}
MAP = {  # target (Meshy) : source (R52-R55)
    "Hips": "Hips", "Spine02": "SpineA", "Spine01": "Chest", "Spine": "UpperChest", "neck": "Neck", "Head": "Head",
    "LeftShoulder": "ClavicleR", "LeftArm": "UpperArmR", "LeftForeArm": "ForearmR", "LeftHand": "HandR",
    "RightShoulder": "ClavicleL", "RightArm": "UpperArmL", "RightForeArm": "ForearmL", "RightHand": "HandL",
    "LeftUpLeg": "ThighR", "LeftLeg": "ShinR", "LeftFoot": "FootR", "LeftToeBase": "ToeR",
    "RightUpLeg": "ThighL", "RightLeg": "ShinL", "RightFoot": "FootL", "RightToeBase": "ToeL",
}


def set_action(arm, act):
    arm.animation_data_create()
    arm.animation_data.action = act
    try:
        arm.animation_data.action_slot = act.slots[0]
    except Exception:
        pass


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    src_blend, meshy, out_glb = argv[:3]
    out_blend = argv[3] if len(argv) > 3 else None
    bpy.ops.wm.open_mainfile(filepath=src_blend)
    src = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
    keep_actions = set(bpy.data.actions.keys())
    bpy.ops.import_scene.gltf(filepath=meshy)
    tgt = [o for o in bpy.context.selected_objects if o.type == 'ARMATURE'][0]
    tmesh = [o for o in bpy.context.selected_objects if o.type == 'MESH']
    # remove everything that is not the Meshy knight from the scene we export
    sw, tw = src.matrix_world, tgt.matrix_world
    # rest data (world space)
    r_src = {s: (sw @ src.data.bones[s].matrix_local).to_quaternion() for s in MAP.values()}
    r_tgt = {t: (tw @ tgt.data.bones[t].matrix_local).to_quaternion() for t in MAP}
    hip_s = (sw @ src.data.bones["Hips"].head_local)
    hip_t = (tw @ tgt.data.bones["Hips"].head_local)
    k = hip_t.z / hip_s.z
    order = [b.name for b in tgt.data.bones if b.name in MAP]   # parents before children
    for b in tgt.pose.bones:
        b.rotation_mode = 'QUATERNION'
    made = []
    for out_name, src_name in CLIPS.items():
        act_s = bpy.data.actions[src_name]
        set_action(src, act_s)
        f0, f1 = [int(x) for x in act_s.frame_range]
        act_t = bpy.data.actions.new("KNIGHT_" + out_name)
        set_action(tgt, act_t)
        for f in range(f0, f1 + 1):
            bpy.context.scene.frame_set(f)
            for tb in order:
                sb = MAP[tb]
                pose_world = sw @ src.pose.bones[sb].matrix
                delta = pose_world.to_quaternion() @ r_src[sb].inverted()
                rot_world = delta @ r_tgt[tb]
                pb = tgt.pose.bones[tb]
                cur = tw @ pb.matrix   # current world matrix (head from the parent chain)
                head = cur.translation.copy()
                if tb == "Hips":
                    head = hip_t + (pose_world.translation - hip_s) * k
                sc = cur.to_scale()
                new_world = Matrix.LocRotScale(head, rot_world, sc)
                pb.matrix = tw.inverted() @ new_world
                bpy.context.view_layer.update()
            for tb in order:
                pb = tgt.pose.bones[tb]
                pb.keyframe_insert("rotation_quaternion", frame=f - f0 + 1)
                if tb == "Hips":
                    pb.keyframe_insert("location", frame=f - f0 + 1)
        act_t.use_fake_user = True
        made.append(out_name)
        print("retargeted", out_name, "frames", f1 - f0 + 1)
    # drop the source character and its actions from the export scene
    for o in list(bpy.data.objects):
        if o != tgt and o not in tmesh:
            bpy.data.objects.remove(o, do_unlink=True)
    for a in list(bpy.data.actions):
        if a.name in keep_actions:
            bpy.data.actions.remove(a)
    for name in made:
        bpy.data.actions["KNIGHT_" + name].name = name
    for a in list(bpy.data.actions):
        if a.name not in made:   # Meshy's own bind clip
            bpy.data.actions.remove(a)
    set_action(tgt, bpy.data.actions[made[0]])
    bpy.ops.object.select_all(action='DESELECT')
    tgt.select_set(True)
    for m in tmesh:
        m.select_set(True)
    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB', use_selection=True,
                              export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True)
    if out_blend:
        bpy.ops.wm.save_as_mainfile(filepath=out_blend, compress=True)
    print("wrote", out_glb, "clips", [a.name for a in bpy.data.actions])


if __name__ == "__main__":
    main()
