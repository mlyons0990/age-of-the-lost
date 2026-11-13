#!/usr/bin/env python3
"""Phase19 Higgsfield Citadel v6: read-only geometry/art-safety gate.
Run from Blender 5.2 on the exact editable .blend. Never alters the scene.
This is not approval of the final camera grade, live Godot F5 travel or physics.
"""
import bpy, json, sys
from math import isclose

problems=[]
meshes=[o for o in bpy.data.objects if o.type=="MESH"]
treads=[bpy.data.objects.get(f"STAIR_Tread_{i:02}") for i in range(1,10)]
arch=[o for o in meshes if o.name.startswith("GATE_Gothic_Voussoir_")]
rosettes=[o for o in meshes if o.name.startswith("PH18_Parapet_GothicRosette_")]
fountains=[o for o in meshes if o.name.startswith("PH19_Fountain_")]
expected_parts=("BackRelief","StonePlinth","BasinLip","ConcaveBasin",
                "FlutedPier_L","FlutedPier_R","Cornice","Spout",
                "BlueMosaic","WaterStream","CarvedFleur_00",
                "CarvedFleur_01","CarvedFleur_02")
if len(meshes)!=507: problems.append(f"Expected 507 scene meshes, got {len(meshes)}")
if len(arch)!=32:problems.append(f"Expected 32 pointed Gothic voussoirs, got {len(arch)}")
if len(rosettes)!=18:problems.append(f"Expected 18 earlier rosettes, got {len(rosettes)}")
if len(fountains)!=26:problems.append(f"Expected 26 fountain mesh details, got {len(fountains)}")
if any(o is None for o in treads):problems.append("One or more stone stair treads missing")
else:
    for i,t in enumerate(treads,1):
        if abs(t.location.y-(-9.5+i))>.015:problems.append(f"{t.name}: moved along travel axis")
        if abs(t.location.z+t.dimensions.z/2*1 - 0) > 5:problems.append(f"{t.name}: out-of-bounds position")
        if abs(t.location.z+t.dimensions.z/2-i*.2)>.015:problems.append(f"{t.name}: top elevation changed")
        if abs(t.dimensions.x-7.5)>.015:problems.append(f"{t.name}: corridor width changed")
for side in ("L","R"):
    for part in expected_parts:
        name=f"PH19_Fountain_{side}_{part}"
        if name not in bpy.data.objects:problems.append(f"Missing {name}")
for o in fountains:
    if o.get("AOTL_visual_only") is not True or o.get("AOTL_collision") is not False:
        problems.append(f"{o.name}: art-only flags missing")
    xs=[(o.matrix_world @ __import__("mathutils").Vector(c)).x for c in o.bound_box]
    if min(abs(min(xs)),abs(max(xs)))<3.75 or min(xs)<3.75<max(xs) or min(xs)<-3.75<max(xs):
        problems.append(f"{o.name}: could intrude into the 7.5m central route")
for side in ("L","R"):
    water=bpy.data.objects.get(f"PH19_Fountain_{side}_WaterStream")
    basin=bpy.data.objects.get(f"PH19_Fountain_{side}_ConcaveBasin")
    if water and basin:
        if not water.data.materials or water.data.materials[0].name!="MAT_Phase19_FountainWater":
            problems.append(f"{side}: water material not applied")
        if water.location.z < basin.location.z-1.0:
            problems.append(f"{side}: water mesh position inconsistent")
unpacked=[im.name for im in bpy.data.images if im.source=="FILE" and not im.packed_file]
if unpacked:problems.append("External image dependencies: "+str(unpacked))
report={"schema":"aotl.citadel.phase19.sculpt_qa.v1",
        "status":"PASS" if not problems else "FAIL",
        "scene_meshes":len(meshes),"treads":len([x for x in treads if x]),
        "gothic_arch_stones":len(arch),"phase18_rosettes":len(rosettes),
        "phase19_fountain_details":len(fountains),"packed_images":len([im for im in bpy.data.images if im.packed_file]),
        "unpacked_images":unpacked,"actual_godot_f5_verified":False,
        "canon_art_approved":False,"errors":problems}
print(json.dumps(report,indent=2))
if problems:sys.exit(1)
