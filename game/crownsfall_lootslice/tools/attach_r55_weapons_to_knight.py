"""Attach the R55 sword and shield meshes to the retargeted knight (free; no generation).

python attach_r55_weapons_to_knight.py -- <knight .blend> <R55 .blend> <out .glb> <out .blend>

Sides follow the retarget mapping: R52 HandR (sword) -> knight LeftHand, R52 HandL (shield) -> knight RightHand.
Each mesh keeps its rest orientation and moves by (knight hand head - R52 hand head), then is skinned rigidly
(100% to the hand bone). Bone-parenting was tried first: Blender parents to the bone *tail*, and Meshy's
centimetre-scale bones are metres long, so the prop landed ~3 m away in the export.
Because the retarget transfers world-space rotation deltas, a mesh placed this way follows the knight's hand
exactly as it followed the R52 hand. Armature modifiers are dropped and bevels applied (rigid props).
"""
import bpy, sys

argv = sys.argv[sys.argv.index("--") + 1:]
knight_blend, r55_blend, out_glb, out_blend = argv[:4]
PAIRS = {"WEAPON_": ("HandR", "LeftHand"), "SHIELD_": ("HandL", "RightHand")}
bpy.ops.wm.open_mainfile(filepath=r55_blend)
src_rig = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
src_heads = {b: (src_rig.matrix_world @ src_rig.data.bones[b].head_local).copy() for b in ("HandR", "HandL")}
names = [o.name for o in bpy.data.objects if o.type == 'MESH' and o.name.startswith(tuple(PAIRS))]
bpy.ops.wm.open_mainfile(filepath=knight_blend)
knight = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
with bpy.data.libraries.load(r55_blend, link=False) as (src, dst):
    dst.objects = names
for o in dst.objects:
    bpy.context.scene.collection.objects.link(o)
    o.data = o.data.copy()
bpy.context.view_layer.update()   # linked objects keep a stale matrix_world until the depsgraph runs
for o in dst.objects:
    for m in list(o.modifiers):
        if m.type == 'ARMATURE':
            o.modifiers.remove(m)
    o.vertex_groups.clear()
    bpy.context.view_layer.objects.active = o
    for m in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)
    prefix = next(p for p in PAIRS if o.name.startswith(p))
    sb, tb = PAIRS[prefix]
    mw = o.matrix_world.copy()
    o.parent = None
    o.matrix_world = mw
    bpy.context.view_layer.update()
    # bake the world placement into the vertices, shifted to the knight's hand
    shift = (knight.matrix_world @ knight.data.bones[tb].head_local) - src_heads[sb]
    o.data.transform(o.matrix_world)
    o.matrix_world = __import__("mathutils").Matrix.Identity(4)
    for v in o.data.vertices:
        v.co += shift
    # rigid skin to the hand bone, in the knight armature's space
    o.parent = knight
    o.matrix_parent_inverse = knight.matrix_world.inverted()
    g = o.vertex_groups.new(name=tb)
    g.add(list(range(len(o.data.vertices))), 1.0, 'REPLACE')
    mod = o.modifiers.new("Armature", 'ARMATURE')
    mod.object = knight
    print("attached", o.name, "->", tb)
# the library load drags the R55 rig (and its actions) in as the weapons' old parent: drop them
for o in list(bpy.data.objects):
    if o.type == 'ARMATURE' and o != knight:
        bpy.data.objects.remove(o, do_unlink=True)
for a in list(bpy.data.actions):
    if not a.use_fake_user:
        bpy.data.actions.remove(a)
bpy.ops.object.select_all(action='DESELECT')
for o in bpy.context.view_layer.objects:
    if o == knight or o.parent == knight:
        o.select_set(True)
bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB', use_selection=True, export_apply=False,
                          export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True)
bpy.ops.wm.save_as_mainfile(filepath=out_blend, compress=True)
print("wrote", out_glb)
