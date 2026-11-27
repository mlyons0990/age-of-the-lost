"""Build the Rogue's twin daggers and the Cleric's mace and sun shield in Blender (free), matching the approved
class concepts (art/higgsfield_2026-11/classes/rogue_a.png, cleric_a.png).

python make_class_props.py -- <out dir> <shield face png>
Writes rogue_dagger.glb, cleric_mace.glb, cleric_shield.glb (+ class_props.blend).
Origins: weapons at the grip (palm), blade / shaft along +Z; shield at its back centre with the face toward +Z.
Metres, Blender Z-up (glTF Y-up on export). Mesh names carry the gear prefixes the game uses
(WEAPON_ for the hand weapon, SHIELD_ for the off-hand) so tint / rarity looks apply per surface.
"""
import bpy, bmesh, sys, math, os
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
out, face_png = argv[0], argv[1]
os.makedirs(out, exist_ok=True)
bpy.ops.wm.read_homefile(use_empty=True)


def mat(name, rgb, metal=0.0, rough=0.5, emit=None, strength=0.0, image=None):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = strength
    if image:
        t = m.node_tree.nodes.new("ShaderNodeTexImage")
        t.image = bpy.data.images.load(image)
        m.node_tree.links.new(t.outputs["Color"], b.inputs["Base Color"])
    return m

# Same moderate metalness as the Mage props: the game lights props mostly with ambient light.
STEEL = mat("Steel_Bright", (0.82, 0.83, 0.86), 0.5, 0.25)
GOLD = mat("TrimGold", (0.88, 0.64, 0.24), 0.45, 0.32)
LEATHER = mat("GripLeather", (0.30, 0.17, 0.09), 0.0, 0.7)
BLUEWRAP = mat("GripBlue", (0.12, 0.17, 0.48), 0.0, 0.6)
GEM = mat("GemBlue", (0.1, 0.3, 0.95), 0.0, 0.1, (0.1, 0.3, 1.0), 0.6)
WOODBACK = mat("ShieldBack", (0.33, 0.2, 0.11), 0.0, 0.75)
FACE = mat("SunShieldFace", (1, 1, 1), 0.15, 0.45, image=face_png)


def finish(objs, name):
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.object
    o.name = name
    bpy.ops.object.shade_smooth()
    return o


def cyl(r, depth, z, m, verts=16, r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=(0, 0, z))
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=depth, location=(0, 0, z))
    o = bpy.context.object; o.data.materials.append(m); return o


def sphere(r, z, m, x=0.0):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=r, location=(x, 0, z))
    o = bpy.context.object; o.data.materials.append(m); return o


def curved_blade(length=0.30, width=0.045, curve=0.06, thick=0.007, segs=18):
    """A single-edged curved dagger blade in the XZ plane: spine along -X, edge along +X, tip curving to -X."""
    bm = bmesh.new()
    rows = []
    for i in range(segs + 1):
        t = i / segs
        z = 0.02 + t * length
        bend = -curve * t * t                     # the tip sweeps back
        w = width * (1.0 - t ** 1.6) * (0.55 + 0.45 * (1 - t))
        w = max(w, 0.002)
        spine = Vector((bend - w * 0.35, 0, z))
        edge = Vector((bend + w * 0.65, 0, z))
        mid_f = Vector((bend, thick * (1 - t * 0.7), z))
        mid_b = Vector((bend, -thick * (1 - t * 0.7), z))
        rows.append([bm.verts.new(spine), bm.verts.new(mid_f), bm.verts.new(edge), bm.verts.new(mid_b)])
    for i in range(segs):
        a, b = rows[i], rows[i + 1]
        for k in range(4):
            bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]))
    bm.faces.new(rows[0][::-1])
    tip = bm.verts.new(Vector((-curve - 0.004, 0, 0.02 + length + 0.02)))
    last = rows[-1]
    for k in range(4):
        bm.faces.new((last[k], last[(k + 1) % 4], tip))
    me = bpy.data.meshes.new("Blade"); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("Blade", me); bpy.context.collection.objects.link(o)
    o.data.materials.append(STEEL)
    return o


def dagger():
    parts = [curved_blade()]
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.012))
    g = bpy.context.object; g.scale = (0.11, 0.022, 0.018); bpy.ops.object.transform_apply(scale=True)
    g.data.materials.append(GOLD); parts.append(g)
    for sx in (-1, 1):                                   # guard finials
        parts.append(sphere(0.013, 0.012, GOLD, x=sx * 0.058))
    parts.append(sphere(0.012, 0.03, GEM))              # gem at the guard
    parts.append(cyl(0.014, 0.10, -0.045, LEATHER, 12, r2=0.016))
    for z in (-0.02, -0.06):
        parts.append(cyl(0.017, 0.008, z, GOLD, 12))
    parts.append(sphere(0.02, -0.105, GOLD))
    return finish(parts, "WEAPON_Dagger")


def mace():
    parts = [cyl(0.016, 0.50, 0.14, BLUEWRAP, 14)]      # shaft: grip -0.11 .. 0.39
    for z in (-0.02, 0.10, 0.22, 0.33):
        parts.append(cyl(0.021, 0.014, z, GOLD, 14))
    parts.append(sphere(0.026, -0.125, GOLD))           # pommel
    parts.append(cyl(0.028, 0.04, 0.41, GOLD, 16))      # collar
    parts.append(sphere(0.055, 0.49, STEEL))            # head core
    for i in range(8):                                   # flanges: heavy wedge plates
        a = i / 8 * math.tau
        bpy.ops.mesh.primitive_cube_add(size=1, location=(math.cos(a) * 0.052, math.sin(a) * 0.052, 0.49))
        f = bpy.context.object
        f.scale = (0.05, 0.024, 0.13); f.rotation_euler = (0, 0, a)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        bm = bmesh.new(); bm.from_mesh(f.data)
        for v in bm.verts:                               # taper the flange to a point outward and at both ends
            r = Vector((v.co.x, v.co.y, 0)).length
            v.co.z *= 1.0 - 0.4 * max(0.0, (r - 0.035)) / 0.05
        bm.to_mesh(f.data); bm.free()
        f.data.materials.append(STEEL); parts.append(f)
    parts.append(cyl(0.012, 0.06, 0.57, STEEL, 12, r2=0.0))  # top spike
    return finish(parts, "WEAPON_Mace")


def shield():
    R = 0.27
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=R, depth=0.025, location=(0, 0, 0.0125))
    disc = bpy.context.object
    # face UVs: planar projection of the top cap onto the painted face texture
    me = disc.data
    me.materials.append(FACE); me.materials.append(WOODBACK)
    uv = me.uv_layers.active or me.uv_layers.new()
    for poly in me.polygons:
        n = poly.normal
        poly.material_index = 0 if n.z > 0.5 else 1
        for li in poly.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            uv.data[li].uv = (0.5 + co.x / (2 * R) * 0.98, 0.5 + co.y / (2 * R) * 0.98)
    # slight dome: push the face centre out
    bm = bmesh.new(); bm.from_mesh(me)
    for v in bm.verts:
        if v.co.z > 0.02:
            r = Vector((v.co.x, v.co.y)).length / R
            v.co.z += 0.03 * (1 - r * r)
    bm.to_mesh(me); bm.free()
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.subdivide(number_cuts=0); bpy.ops.object.mode_set(mode='OBJECT')
    parts = [disc]
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=0.016, major_segments=64, minor_segments=10, location=(0, 0, 0.025))
    rim = bpy.context.object; rim.data.materials.append(GOLD); parts.append(rim)
    for i in range(16):                                  # rim studs
        a = i / 16 * math.tau
        parts.append(sphere(0.011, 0.04, GOLD, x=0)); s = parts[-1]
        s.location = (math.cos(a) * (R - 0.028), math.sin(a) * (R - 0.028), 0.038)
    parts.append(sphere(0.04, 0.05, GOLD)); parts[-1].scale = (1, 1, 0.6)   # boss
    # back straps (on the forearm side, -Z)
    for y in (-0.07, 0.07):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, y, -0.01))
        st = bpy.context.object; st.scale = (0.2, 0.03, 0.012)
        st.data.materials.append(LEATHER); parts.append(st)
    for o in parts: o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return finish(parts, "SHIELD_Sun")


for fn, name in [(dagger, "rogue_dagger"), (mace, "cleric_mace"), (shield, "cleric_shield")]:
    bpy.ops.object.select_all(action='DESELECT')
    o = fn()
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(out, name + ".glb"), export_format='GLB', use_selection=True)
    print("wrote", name, [round(d, 3) for d in o.dimensions])
    o.hide_set(True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, "class_props.blend"), compress=True)
