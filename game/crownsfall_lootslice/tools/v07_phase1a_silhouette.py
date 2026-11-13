"""AOTL V07 Phase 1A: reversible shoulder/chest/tunic silhouette edits.

Run inside Blender 5.2 using the V06 Blender source (Higgsfield revision 12).
This script refuses to apply twice. Source mesh datablocks are retained with
fake users under V06_R12_BACKUP__*. No skeleton, weights, actions or sockets edit.

Higgsfield hosted scene checkpoint: revision 13.
"""
import bpy

RIG_NAME = "RIG_AOTL_Master_Humanoid_58"
TARGETS = (
    "V02_GEAR_ShoulderPlateL", "V02_GEAR_ShoulderPlateR",
    "V02_GEAR_ShoulderRimL", "V02_GEAR_ShoulderRimR",
    "V02_GEAR_LayeredCuirass", "V02_SKIN_FittedTunic",
)

rig = bpy.data.objects[RIG_NAME]
assert len(rig.data.bones) == 58, "Skeleton changed"
assert rig.animation_data.action.name == "AOTL_Reel_V06"
assert all(name in bpy.data.objects for name in TARGETS)
assert not any(
    bpy.data.objects[name].get("AOTL_V07_SILHOUETTE_PHASE1A", False)
    for name in TARGETS
), "Already applied; refusing to double-shape"

report = []
for name in TARGETS:
    obj = bpy.data.objects[name]
    backup = obj.data.copy()
    backup.name = "V06_R12_BACKUP__" + name
    backup.use_fake_user = True

    working = obj.data.copy()
    working.name = "V07_P1A__" + name
    obj.data = working
    moved, biggest = 0, 0.0

    for vertex in working.vertices:
        previous = vertex.co.copy()
        x, y, z = tuple(vertex.co)
        if "ShoulderPlate" in name or "ShoulderRim" in name:
            sign = -1.0 if name.endswith("L") else 1.0
            outer_factor = max(0.0, min(1.0, (abs(x) - 0.34) / 0.19))
            vertex.co.x += sign * (
                0.019 if "Plate" in name else 0.021
            ) * outer_factor ** 2
            if z > 1.46:
                vertex.co.z += 0.014 * outer_factor * max(
                    0.0, min(1.0, (z - 1.46) / 0.12)
                )
            if outer_factor > 0.25:
                vertex.co.y *= 1.0 - 0.06 * outer_factor
        elif "LayeredCuirass" in name:
            top = max(0.0, min(1.0, (z - 1.28) / 0.21))
            vertex.co.x *= 1.0 + 0.025 * top - 0.035 * (1.0 - top)
            if y < -0.05:
                vertex.co.y -= 0.008 * top
        elif "FittedTunic" in name:
            waist = max(0.0, 1.0 - abs(z - 1.08) / 0.23)
            vertex.co.x *= 1.0 - 0.025 * waist

        d = (vertex.co - previous).length
        if d > 1e-6:
            moved += 1
            biggest = max(biggest, d)

    obj["AOTL_V07_SILHOUETTE_PHASE1A"] = True
    obj["AOTL_V07_RESTORE_MESH"] = backup.name
    report.append((name, moved, round(biggest, 5)))

rig["AOTL_V07_PHASE1A"] = (
    "Six reversible meshes: pauldrons/rims, chest, waist; no bones changed."
)
bpy.context.scene.frame_set(1)

assert len(rig.data.bones) == 58
assert all(len(bpy.data.objects[name].vertex_groups) for name in TARGETS)
print("V07_PHASE1A_GEOMETRY_APPLIED", report)

# To revert a given object without changing other work:
# obj = bpy.data.objects["V02_GEAR_ShoulderPlateL"]
# original = bpy.data.meshes[obj["AOTL_V07_RESTORE_MESH"]]
# obj.data = original.copy()
# del obj["AOTL_V07_SILHOUETTE_PHASE1A"]
