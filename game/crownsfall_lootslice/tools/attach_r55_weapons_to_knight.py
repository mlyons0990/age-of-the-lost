"""Attach the R55 sword and shield meshes to the retargeted knight (free; no generation).

python attach_r55_weapons_to_knight.py -- <knight .blend> <R55 .blend> <out .glb> <out .blend> [--right-handed]

--right-handed: sword in the knight's anatomical RightHand, shield on LeftHand (needed by right-hand library
attacks such as Left_Slash #97). Props are mirrored across the hand so the shield face still points outward.

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
RIGHT_HANDED = "--right-handed" in argv
PAIRS = ({"WEAPON_": ("HandR", "RightHand"), "SHIELD_": ("HandL", "LeftHand")} if RIGHT_HANDED
         else {"WEAPON_": ("HandR", "LeftHand"), "SHIELD_": ("HandL", "RightHand")})
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
    if RIGHT_HANDED:
        # mirror across the source hand's x so the prop keeps its outward face on the other side
        hx = src_heads[sb].x
        for v in o.data.vertices:
            v.co.x = 2 * hx - v.co.x
        o.data.flip_normals()
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
if RIGHT_HANDED:
    # Re-grip the sword for library attacks: handle in the palm, blade forward out of the fist (−Y = the
    # knight's forward in Blender) at the rest pose. The R52 placement hung the blade straight down, which
    # trailed behind the hand in Meshy's Left_Slash.
    from mathutils import Vector, Matrix
    parts = {o.name.split(".")[0]: o for o in dst.objects if o.name.startswith("WEAPON_")}
    centre = lambda o: sum((v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
    hilt, tip = centre(parts["WEAPON_Crossguard"]), centre(parts["WEAPON_Tip"])
    handle = centre(parts["WEAPON_Handle"])
    rot = (tip - hilt).normalized().rotation_difference(Vector((0.0, -1.0, 0.0))).to_matrix().to_4x4()
    fore = knight.matrix_world @ knight.data.bones["RightForeArm"].head_local
    hand = knight.matrix_world @ knight.data.bones["RightHand"].head_local
    palm = hand + (hand - fore).normalized() * 0.07
    xf = Matrix.Translation(palm) @ rot @ Matrix.Translation(-handle)
    for o in parts.values():
        o.data.transform(xf)
    print("re-gripped sword: blade forward from the right palm")
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
