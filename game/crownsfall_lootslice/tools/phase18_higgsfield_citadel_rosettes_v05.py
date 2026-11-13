"""Phase18 Higgsfield Blender v5 decorative pass. Run only on the verified v4 Citadel sculpt.

Idempotent, visual-only and safe for geometry inspection; no navigation/collider edits.
The live game does NOT automatically import this sculpt. It is different from the v17
procedural art GLB. Source project: 0361ff9b-2829-4595-a64e-564f39e1eeac.
"""
import bpy
import math

def install_rosettes():
    material = bpy.data.materials.get("MAT_Brushed_Royal_Brass")
    if material is None:
        raise ValueError("Missing canonical royal brass material")
    expected = [f"STAIR_Coping_{i:02}_{side}" for side in ("L", "R") for i in range(1, 10)]
    missing = [name for name in expected if name not in bpy.data.objects]
    if missing:
        raise ValueError(f"Missing step rail source: {missing}")
    known = [o for o in bpy.data.objects if o.name.startswith("PH18_Parapet_GothicRosette_")]
    if known:
        raise ValueError(f"Refusing duplicate rosettes: {len(known)} exist")
    mesh = bpy.data.meshes.new("PH18_Shared_Gothic_Rosette_8Petal")
    vertices = [(0, -0.025, 0)]
    faces = []
    segments = 8
    for i in range(segments * 2):
        angle = 2 * math.pi * i / (segments * 2)
        radius = 0.155 if i % 2 == 0 else 0.075
        vertices.append((math.cos(angle) * radius, 0, math.sin(angle) * radius))
    for i in range(1, segments * 2 + 1):
        faces.append((0, i, 1 if i == segments * 2 else i + 1))
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    mesh.materials.append(material)
    made = []
    for side, outward in (("L", -1), ("R", 1)):
        for i in range(1, 10):
            base = bpy.data.objects[f"STAIR_Coping_{i:02}_{side}"]
            rosette = bpy.data.objects.new(f"PH18_Parapet_GothicRosette_{side}_{i:02}", mesh)
            bpy.context.scene.collection.objects.link(rosette)
            rosette.location = (base.location.x + outward * 0.06,
                                base.location.y, base.location.z + 0.16)
            rosette.rotation_euler.x = math.radians(90)
            rosette.scale = (0.82, 0.82, 0.82)
            rosette["AOTL_visual_only"] = True
            rosette["AOTL_collision"] = False
            made.append(rosette.name)
    assert len(made) == 18
    return made

if __name__ == "__main__":
    print(install_rosettes())
