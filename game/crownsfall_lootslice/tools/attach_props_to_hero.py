"""Rigidly attach prop GLBs to a Meshy-rigged hero's hands and export one GLB (free; no generation).

python attach_props_to_hero.py -- <hero .blend> <out .glb> <out .blend> PROP=path.glb@Bone[:mode] [...]

mode "upright": the prop's local +Z (e.g. a staff shaft, origin at the grip) stands vertical in the palm.
mode "upright=Action": vertical in that action's first frame instead of the rest pose (e.g. upright=Idle), so a
       staff stays upright in the idle and in locomotion (the controller's arm-carry layer reuses Idle's arms).
mode "held":    the prop is held flat beside the hand (e.g. a tome), centred just outside the palm.
Each prop is placed in the rest pose relative to the hand and skinned 100% to that bone, like the knight's
sword (see attach_r55_weapons_to_knight.py for why rigid skinning, not bone parenting).
"""
import bpy, sys
from mathutils import Vector, Matrix

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
    fore = hero.matrix_world @ hero.data.bones[bone.replace("Hand", "ForeArm")].head_local
    hand = hero.matrix_world @ hero.data.bones[bone].head_local
    palm = hand + (hand - fore).normalized() * 0.07
    if mode == "held":
        place = Matrix.Translation(palm + Vector((side * 0.06, -0.02, -0.02))) @ Matrix.Rotation(1.5708, 4, 'Z')
    elif mode.startswith("upright="):
        act = bpy.data.actions[mode.split("=", 1)[1]]
        hero.animation_data_create(); hero.animation_data.action = act
        try:
            hero.animation_data.action_slot = act.slots[0]
        except Exception:
            pass
        bpy.context.scene.frame_set(int(act.frame_range[0]))
        rest_q = (hero.matrix_world @ hero.data.bones[bone].matrix_local).to_quaternion()
        pose_q = (hero.matrix_world @ hero.pose.bones[bone].matrix).to_quaternion()
        delta = pose_q @ rest_q.inverted()
        want = delta.inverted() @ Vector((0.0, 0.0, 1.0))      # rest-space direction that becomes world-up
        rot = Vector((0.0, 0.0, 1.0)).rotation_difference(want).to_matrix().to_4x4()
        place = Matrix.Translation(palm) @ rot
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
        g = o.vertex_groups.new(name=bone)
        g.add(list(range(len(o.data.vertices))), 1.0, 'REPLACE')
        m = o.modifiers.new("Armature", 'ARMATURE'); m.object = hero
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
