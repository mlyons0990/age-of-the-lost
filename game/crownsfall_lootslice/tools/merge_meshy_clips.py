"""Add Higgsfield `3d_rigging` library clips to the retargeted knight and export one GLB.

python merge_meshy_clips.py -- <knight .blend> <out .glb> <out .blend> NAME=clip.glb [NAME=clip.glb ...]

Each clip GLB carries the same Meshy rig plus one action. The tool checks that every mapped bone's
rest matrix matches the knight's (so local-space keys transfer exactly), copies the action under NAME,
removes the imported duplicate character, and exports all actions on the knight.
"""
import bpy, sys
from mathutils import Matrix


def set_action(a, act):
    a.animation_data_create(); a.animation_data.action = act
    try:
        a.animation_data.action_slot = act.slots[0]
    except Exception:
        pass


def world_transfer(src, tgt, src_act, name):
    """Bake src_act onto tgt by world-space rotation deltas (same bone names, different rest poses)."""
    sw, tw = src.matrix_world, tgt.matrix_world
    names = [b.name for b in tgt.data.bones if b.name in src.data.bones]
    r_s = {n: (sw @ src.data.bones[n].matrix_local).to_quaternion() for n in names}
    r_t = {n: (tw @ tgt.data.bones[n].matrix_local).to_quaternion() for n in names}
    hs, ht = sw @ src.data.bones["Hips"].head_local, tw @ tgt.data.bones["Hips"].head_local
    k = ht.z / hs.z
    set_action(src, src_act)
    out = bpy.data.actions.new(name)
    set_action(tgt, out)
    for b in tgt.pose.bones:
        b.rotation_mode = 'QUATERNION'
    f0, f1 = [int(x) for x in src_act.frame_range]
    for f in range(f0, f1 + 1):
        bpy.context.scene.frame_set(f)
        for n in names:
            pw = sw @ src.pose.bones[n].matrix
            rot = (pw.to_quaternion() @ r_s[n].inverted()) @ r_t[n]
            pb = tgt.pose.bones[n]
            cur = tw @ pb.matrix
            head = ht + (pw.translation - hs) * k if n == "Hips" else cur.translation.copy()
            pb.matrix = tw.inverted() @ Matrix.LocRotScale(head, rot, cur.to_scale())
            bpy.context.view_layer.update()
        for n in names:
            pb = tgt.pose.bones[n]
            pb.keyframe_insert("rotation_quaternion", frame=f - f0 + 1)
            if n == "Hips":
                pb.keyframe_insert("location", frame=f - f0 + 1)
    out.use_fake_user = True
    return out

argv = sys.argv[sys.argv.index("--") + 1:]
src, out_glb, out_blend = argv[:3]
pairs = [a.split("=", 1) for a in argv[3:]]
bpy.ops.wm.open_mainfile(filepath=src)
knight = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
mesh = [o for o in bpy.data.objects if o.type == 'MESH']
for name, path in pairs:
    before = set(bpy.data.objects); acts_before = set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    arm = [o for o in new if o.type == 'ARMATURE'][0]
    worst = 0.0
    for b in knight.data.bones:
        m1, m2 = b.matrix_local, arm.data.bones[b.name].matrix_local
        worst = max(worst, max(abs(m1[i][j] - m2[i][j]) for i in range(3) for j in range(3)),
                    (m1.translation - m2.translation).length * 0.01)
    act = [a for a in bpy.data.actions if a not in acts_before][0]
    if worst > 1e-3:
        print("%s: rest pose differs from the knight (%.4f); transferring in world space" % (name, worst))
        act.name = name + "_SRC"
        act = world_transfer(arm, knight, act, name) or act
        bpy.data.actions.remove(bpy.data.actions[name + "_SRC"])
    else:
        act.name = name
        act.use_fake_user = True
    for o in new:
        bpy.data.objects.remove(o, do_unlink=True)
    print("merged", name, "frames", tuple(act.frame_range), "rest diff %.2e" % worst)
for a in list(bpy.data.actions):
    if not a.use_fake_user and a.users == 0:
        bpy.data.actions.remove(a)
bpy.ops.object.select_all(action='DESELECT')
knight.select_set(True)
for m in mesh:
    m.select_set(True)
bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB', use_selection=True,
                          export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True)
bpy.ops.wm.save_as_mainfile(filepath=out_blend, compress=True)
print("wrote", out_glb, sorted(a.name for a in bpy.data.actions))
