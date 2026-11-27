"""Rigidly attach prop GLBs to a Meshy-rigged hero's hands and export one GLB (free; no generation).

python attach_props_to_hero.py -- <hero .blend> <out .glb> <out .blend> PROP=path.glb@Bone[:mode] [...]

mode "upright": the prop's local +Z (e.g. a staff shaft, origin at the grip) stands vertical in the palm.
mode "upright=Action": vertical in that action's first frame instead of the rest pose (e.g. upright=Idle), so a
       staff stays upright in the idle and in locomotion (the controller's arm-carry layer reuses Idle's arms).
mode "grip=Action[,maxtilt]": like upright=Action, but the prop is skinned to a new bone <PROP>_Grip (child of the
       hand, at the palm) whose rotation is baked in every action so the shaft never tips more than maxtilt degrees
       (default 40) from vertical: the hand still leads the swing, but a staff cannot flip upside down or lie across
       the body in clips authored for an empty hand (e.g. the Mage's library casts).
mode "held":    the prop is held flat beside the hand (e.g. a tome), centred just outside the palm.
mode "aim=Action/x/y/z": like upright=Action, but the prop's +Z points along world direction (x, y, z) in that
       action's first frame (Blender axes: the hero faces -Y, +X is the hero's left), e.g. a dagger held forward.
mode "strap=Action/x/y/z": the prop sits on the outside of the forearm (bone = the ForeArm), centred halfway along
       it, with its +Z (a shield face) pointing along (x, y, z) in that action's first frame.
Each prop is placed in the rest pose relative to the hand and skinned 100% to that bone, like the knight's
sword (see attach_r55_weapons_to_knight.py for why rigid skinning, not bone parenting).
"""
import bpy, sys
from mathutils import Vector, Matrix

import math
from mathutils import Quaternion


GRIP_EXEMPT = {"Dead"}


def add_grip(grip, parent, palm_w, axis_w, max_tilt):
    """New bone at the palm (child of `parent`), then bake per-frame grip rotations into every action so the
    prop axis stays within max_tilt of world-up. Rest-pose (A-pose) world data in, armature space inside."""
    inv = hero.matrix_world.inverted()
    bpy.context.view_layer.objects.active = hero
    bpy.ops.object.mode_set(mode='EDIT')
    eb = hero.data.edit_bones.new(grip)
    eb.head = inv @ palm_w
    eb.tail = inv @ (palm_w + axis_w.normalized() * 0.25)
    eb.parent = hero.data.edit_bones[parent]
    eb.use_connect = False
    eb.use_deform = True
    bpy.ops.object.mode_set(mode='OBJECT')
    axis_arm = (inv.to_3x3() @ axis_w).normalized()
    a_local = (hero.data.bones[grip].matrix_local.to_3x3().inverted() @ axis_arm).normalized()
    up = Vector((0.0, 0.0, 1.0))
    zmin = math.cos(math.radians(max_tilt))
    pb = hero.pose.bones[grip]
    pb.rotation_mode = 'QUATERNION'
    mw3 = hero.matrix_world.to_3x3()
    for act in list(keep):
        hero.animation_data.action = act
        try:
            hero.animation_data.action_slot = act.slots[0]
        except Exception:
            pass
        f0, f1 = [int(x) for x in act.frame_range]
        if act.name in GRIP_EXEMPT:   # e.g. Dead: the staff falls with the hand (rigid), keyed so it never inherits
            for f in (f0, f1):
                pb.rotation_quaternion = Quaternion()
                pb.keyframe_insert("rotation_quaternion", frame=f, group=grip)
            print("grip rigid   %-12s (exempt)" % act.name)
            continue
        worst = 0.0
        for f in range(f0, f1 + 1):
            pb.rotation_quaternion = Quaternion()
            bpy.context.scene.frame_set(f)
            pb.rotation_quaternion = Quaternion()
            bpy.context.view_layer.update()
            m0 = pb.matrix.to_3x3()
            d = (mw3 @ m0 @ a_local).normalized()
            worst = max(worst, math.degrees(math.acos(max(-1.0, min(1.0, d.z)))))
            t = d.copy()
            if t.z < zmin:
                lo, hi = 0.0, 64.0
                for _ in range(40):
                    k = (lo + hi) * 0.5
                    if (d + up * k).normalized().z < zmin: lo = k
                    else: hi = k
                t = (d + up * hi).normalized()
                if t.length < 0.5:
                    t = up
            q_world = d.rotation_difference(t)
            q_arm = (mw3.inverted() @ q_world.to_matrix() @ mw3).to_quaternion()
            basis = (m0.inverted() @ q_arm.to_matrix() @ m0).to_quaternion()
            pb.rotation_quaternion = basis
            pb.keyframe_insert("rotation_quaternion", frame=f, group=grip)
        print("grip baked %-12s frames %d-%d hand-only tilt max %.0f deg -> capped %.0f" % (act.name, f0, f1, worst, max_tilt))


def hand_of(forearm):
    return hero.matrix_world @ hero.data.bones[forearm.replace("ForeArm", "Hand")].head_local


argv = sys.argv[sys.argv.index("--") + 1:]
src, out_glb, out_blend = argv[:3]
specs = argv[3:]
bpy.ops.wm.open_mainfile(filepath=src)
hero = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
keep = set(bpy.data.actions)
for spec in specs:
    name, rest = spec.split("=", 1)
    path, bone_mode = rest.split("@", 1)
    bone, mode = (bone_mode.split(":") + ["upright"])[:2]
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == 'MESH']
    side = 1.0 if bone.startswith("Left") else -1.0          # +X is the hero's left (faces −Y)
    hand_bone = bone.replace("ForeArm", "Hand")
    fore = hero.matrix_world @ hero.data.bones[hand_bone.replace("Hand", "ForeArm")].head_local
    hand = hero.matrix_world @ hero.data.bones[hand_bone].head_local
    palm = hand + (hand - fore).normalized() * 0.07
    if mode == "held":
        place = Matrix.Translation(palm + Vector((side * 0.06, -0.02, -0.02))) @ Matrix.Rotation(1.5708, 4, 'Z')
    elif mode.startswith("upright=") or mode.startswith("grip=") or mode.startswith("aim=") or mode.startswith("strap="):
        spec_ = mode.split("=", 1)[1]
        act = bpy.data.actions[spec_.split(",")[0].split("/")[0]]
        hero.animation_data_create(); hero.animation_data.action = act
        try:
            hero.animation_data.action_slot = act.slots[0]
        except Exception:
            pass
        bpy.context.scene.frame_set(int(act.frame_range[0]))
        rest_q = (hero.matrix_world @ hero.data.bones[bone].matrix_local).to_quaternion()
        pose_q = (hero.matrix_world @ hero.pose.bones[bone].matrix).to_quaternion()
        delta = pose_q @ rest_q.inverted()
        target = Vector((0.0, 0.0, 1.0))
        if mode.startswith("aim=") or mode.startswith("strap="):
            target = Vector([float(v) for v in spec_.split("/")[1:4]]).normalized()
        want = delta.inverted() @ target                       # rest-space direction that becomes the target
        rot = Vector((0.0, 0.0, 1.0)).rotation_difference(want).to_matrix().to_4x4()
        at = palm
        if mode.startswith("strap="):
            fa_head = hero.matrix_world @ hero.data.bones[bone].head_local
            fa_tail = hand_of(bone)
            mid = fa_head + (fa_tail - fa_head) * 0.42
            at = mid + target * 0.105                            # strapped on the outside of the forearm, clear of the hand
        place = Matrix.Translation(at) @ rot
        print("upright in", act.name, "- shaft rest direction", [round(c, 2) for c in want])
    else:
        place = Matrix.Translation(palm)
    for o in meshes:
        mw = o.matrix_world.copy()
        o.parent = None
        o.data = o.data.copy()
        o.data.transform(place @ mw)
        o.matrix_world = Matrix.Identity(4)
        o.name = name
        o.parent = hero
        o.matrix_parent_inverse = hero.matrix_world.inverted()
        g = o.vertex_groups.new(name=bone if not mode.startswith("grip=") else name + "_Grip")
        g.add(list(range(len(o.data.vertices))), 1.0, 'REPLACE')
        m = o.modifiers.new("Armature", 'ARMATURE'); m.object = hero
    if mode.startswith("grip="):
        add_grip(name + "_Grip", bone, palm, rot.to_3x3() @ Vector((0.0, 0.0, 1.0)),
                 float(mode.split(",")[1]) if "," in mode else 40.0)
    for o in new:
        if o.type != 'MESH':
            bpy.data.objects.remove(o, do_unlink=True)
    print("attached", name, "->", bone, mode)
for a in list(bpy.data.actions):
    if a not in keep:
        bpy.data.actions.remove(a)
bpy.ops.object.select_all(action='DESELECT')
for o in bpy.context.view_layer.objects:
    if o == hero or o.parent == hero:
        o.select_set(True)
bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB', use_selection=True, export_apply=False,
                          export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True)
bpy.ops.wm.save_as_mainfile(filepath=out_blend, compress=True)
print("wrote", out_glb)
