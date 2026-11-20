"""Build the Mage's staff and tome in Blender (free), matching the approved item art:
art/item_taxonomy/2026-11-12/runtime_items/aotl_caster_mystic_staff_002.png and aotl_off_hand_tome_002.png.

python make_mage_props.py -- <out dir>
Writes mage_staff.glb, mage_tome.glb and mage_props.blend. Origins: staff at the grip (palm), shaft along +Z;
tome at its spine centre. Metres, Blender Z-up (glTF Y-up on export).
"""
import bpy, sys, math, os
from mathutils import Vector

out = sys.argv[sys.argv.index("--") + 1]
os.makedirs(out, exist_ok=True)
bpy.ops.wm.read_homefile(use_empty=True)

def mat(name, rgb, metal=0.0, rough=0.5, emit=None, strength=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = strength
    return m

# Metalness kept moderate: the game lights props mostly with ambient light, where fully metallic
# surfaces with no environment reflections render dark.
WOOD = mat("StaffWood", (0.45, 0.16, 0.07), 0.0, 0.55)
SILVER = mat("StaffSilver", (0.82, 0.77, 0.7), 0.45, 0.3)
GOLD = mat("TrimGold", (0.85, 0.62, 0.25), 0.45, 0.35)
CRYSTAL = mat("ArcaneCrystal", (0.1, 0.32, 0.95), 0.0, 0.1, (0.1, 0.35, 1.0), 0.8)
LEATHER = mat("TomeLeather", (0.33, 0.16, 0.08), 0.0, 0.7)
PAGES = mat("TomePages", (0.86, 0.78, 0.6), 0.0, 0.9)
IRON = mat("TomeIron", (0.6, 0.6, 0.62), 0.4, 0.4)

def obj(o, m, name):
    o.name = name; o.data.materials.append(m); return o

def staff():
    parts = []
    L = 1.30  # shaft length; grip at 0.55 m above the foot (total with head ≈ 1.62 m)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.017, depth=L, location=(0, 0, L / 2 - 0.55))
    parts.append(obj(bpy.context.object, WOOD, "Staff_Shaft"))
    # silver spiral wrap
    pts = []
    for i in range(240):
        t = i / 239.0
        z = -0.45 + t * 1.25
        a = t * math.tau * 9
        pts.append((math.cos(a) * 0.019, math.sin(a) * 0.019, z))
    cu = bpy.data.curves.new("SpiralCurve", 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = 0.0045; cu.bevel_resolution = 2
    sp = cu.splines.new('POLY'); sp.points.add(len(pts) - 1)
    for p, c in zip(sp.points, pts): p.co = (*c, 1)
    so = bpy.data.objects.new("Staff_Spiral", cu); bpy.context.collection.objects.link(so)
    bpy.context.view_layer.objects.active = so; so.select_set(True); bpy.ops.object.convert(target='MESH')
    so.data.materials.append(SILVER); parts.append(so)
    top = L - 0.55
    # collar + gem rings
    for z, r in [(top - 0.06, 0.03), (-0.5, 0.026)]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=r, depth=0.06, location=(0, 0, z))
        parts.append(obj(bpy.context.object, SILVER, "Staff_Collar"))
    # pommel
    bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.028, radius2=0.0, depth=0.08, location=(0, 0, -0.58), rotation=(math.pi, 0, 0))
    parts.append(obj(bpy.context.object, SILVER, "Staff_Pommel"))
    # crescent moon head: outer disc minus an offset inner disc, opening to the upper right, extruded
    import bmesh
    R, r_in, off, thick = 0.13, 0.105, Vector((0.045, 0.0, 0.05)), 0.03
    centre = Vector((0, 0, top + 0.12))
    def inside_inner(p):
        return (p - off).length < r_in
    outer = []
    n = 72
    for i in range(n):
        a = math.tau * i / n
        p = Vector((math.cos(a) * R, 0, math.sin(a) * R))
        if not inside_inner(p):
            outer.append(p)
    # walk the inner arc between the two crossings, from the end of the outer arc back to its start
    def crossing_angles():
        pts = []
        for i in range(720):
            a = math.tau * i / 720
            p = Vector((math.cos(a) * R, 0, math.sin(a) * R))
            pts.append(inside_inner(p))
        return pts
    # build the polygon in angular order: outer arc (outside the inner disc), then inner arc reversed
    ang = lambda p: math.atan2(p.z, p.x) % math.tau
    flags = crossing_angles()
    # first angle where we leave the inner disc (start of outer arc)
    k0 = next(i for i in range(720) if flags[i - 1] and not flags[i])
    outer_pts = []
    for j in range(720):
        i = (k0 + j) % 720
        if flags[i]:
            break
        a = math.tau * i / 720
        if j % 8 == 0:
            outer_pts.append(Vector((math.cos(a) * R, 0, math.sin(a) * R)))
    a_end = math.atan2(outer_pts[-1].z, outer_pts[-1].x)
    a_start = math.atan2(outer_pts[0].z, outer_pts[0].x)
    # inner arc points (on the inner circle, inside the outer disc), from end back to start
    ie = math.atan2(outer_pts[-1].z - off.z, outer_pts[-1].x - off.x)
    is_ = math.atan2(outer_pts[0].z - off.z, outer_pts[0].x - off.x)
    # of the two inner arcs between the crossings, use the one that lies inside the outer disc
    span = (is_ - ie) % math.tau
    mid = off + Vector((math.cos(ie + span / 2) * r_in, 0, math.sin(ie + span / 2) * r_in))
    if mid.length > R:
        span -= math.tau
    inner_pts = [off + Vector((math.cos(ie + span * t / 40) * r_in, 0, math.sin(ie + span * t / 40) * r_in)) for t in range(41)]
    poly = outer_pts + inner_pts
    me = bpy.data.meshes.new("Crescent"); bm = bmesh.new()
    vs = [bm.verts.new(p + centre) for p in poly]
    f = bm.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    bmesh.ops.translate(bm, vec=(0, thick, 0), verts=[e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)])
    bmesh.ops.translate(bm, vec=(0, -thick / 2, 0), verts=bm.verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    moon = bpy.data.objects.new("Staff_Crescent", me); bpy.context.collection.objects.link(moon)
    moon.data.materials.append(SILVER)
    parts.append(moon)
    # crystal (elongated octahedron) inside the crescent
    bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=3, radius=0.05, location=(0, 0, top + 0.12))
    cr = obj(bpy.context.object, CRYSTAL, "Staff_Crystal"); cr.scale = (0.75, 0.75, 1.7)
    parts.append(cr)
    # small blue jewel on the collar
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.014, location=(0, -0.03, top - 0.06))
    parts.append(obj(bpy.context.object, CRYSTAL, "Staff_Jewel"))
    return parts

def tome():
    parts = []
    w, h, d = 0.17, 0.23, 0.06
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0)); b = bpy.context.object; b.scale = (w, d, h)
    parts.append(obj(b, LEATHER, "Tome_Cover"))
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.008, 0, 0)); p = bpy.context.object; p.scale = (w - 0.012, d - 0.012, h - 0.012)
    p.location.x = 0.008; parts.append(obj(p, PAGES, "Tome_Pages"))
    for sx in (-1, 1):
        for sz in (-1, 1):
            bpy.ops.mesh.primitive_cube_add(size=1, location=(sx * (w / 2 - 0.015), 0, sz * (h / 2 - 0.015)))
            cc = bpy.context.object; cc.scale = (0.035, d + 0.006, 0.035); parts.append(obj(cc, IRON, "Tome_Corner"))
    bpy.ops.mesh.primitive_cube_add(size=1, location=(w / 2 + 0.002, 0, 0)); cl = bpy.context.object; cl.scale = (0.03, d + 0.01, 0.045)
    parts.append(obj(cl, GOLD, "Tome_Clasp"))
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.012, depth=h, location=(-w / 2, 0, 0)); sp = bpy.context.object
    parts.append(obj(sp, LEATHER, "Tome_Spine"))
    return parts

def export(parts, path, name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts: o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.join(); bpy.context.object.name = name
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True)
    return bpy.context.object

s = export(staff(), os.path.join(out, "mage_staff.glb"), "MAGE_Staff")
t = export(tome(), os.path.join(out, "mage_tome.glb"), "MAGE_Tome")
t.location.x = 0.5
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, "mage_props.blend"), compress=True)
print("wrote staff + tome", [round(x, 3) for x in s.dimensions], [round(x, 3) for x in t.dimensions])
