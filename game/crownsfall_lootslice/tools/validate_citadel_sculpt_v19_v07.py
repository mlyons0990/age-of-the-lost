#!/usr/bin/env python3
"""Read-only production safety audit of Higgsfield Citadel v7.
Does not authorize any merge into the actual approved Godot project.
Use: blender -b AOTL_Citadel_Art_v07.blend --python tools/validate_citadel_sculpt_v19_v07.py
"""
import bpy,json,sys
from mathutils import Vector

failures=[]
meshes=[o for o in bpy.data.objects if o.type=="MESH"]
def check(ok:bool,message:str):
    if not ok:failures.append(message)
def collection(prefix:str):
    return [o for o in meshes if o.name.startswith(prefix)]
check(len(meshes)==571,f"scene meshes {len(meshes)} expected 571")
stair=[bpy.data.objects.get(f"STAIR_Tread_{i:02}") for i in range(1,10)]
check(all(stair),"nine original tread source meshes")
if all(stair):
    for i,o in enumerate(stair,1):
        check(abs(o.location.y-(-9.5+i))<.015,f"{o.name} one-metre stair travel spacing")
        check(abs(o.location.z+o.dimensions.z/2-i*.2)<.015,f"{o.name} top equals graded elevation")
        check(abs(o.dimensions.x-7.5)<.015,f"{o.name} clear width still 7.5m")
check(len(collection("GATE_Gothic_Voussoir_"))==32,"32 original Gothic voussoirs retained")
check(len(collection("PH18_Parapet_GothicRosette_"))==18,"18 Phase18 rosettes retained")
fountains=collection("PH19_Fountain_")
check(len(fountains)==26,"26 paired terrace fountain details")
arch_detail=collection("PH19_Arch_")
check(len(arch_detail)==64,"64 fine chisel-carved arch details")
for o in fountains:
    check(o.get("AOTL_collision") is False and o.get("AOTL_visual_only") is True,
          f"{o.name} no collision and visual-only")
    xs=[(o.matrix_world @ Vector(corner)).x for corner in o.bound_box]
    check(min(xs)>3.75 or max(xs)<-3.75,f"{o.name} remains outside player corridor")
for i in range(1,33):
    source=bpy.data.objects.get(f"GATE_Gothic_Voussoir_{i:02}")
    crest=bpy.data.objects.get(f"PH19_Arch_LancetRelief_{i:02}")
    groove=bpy.data.objects.get(f"PH19_Arch_ShadowCut_{i:02}")
    check(source is not None and crest is not None and groove is not None,
          f"arch stone {i:02} decorative pieces available")
    if source and crest and groove:
        src=[source.matrix_world @ v.co for v in source.data.vertices]
        face_front=min(v.y for v in src)
        for detail in (crest,groove):
            check(detail.get("AOTL_collision") is False and
                  detail.get("AOTL_visual_only") is True,f"{detail.name} art-only")
            detail_vertices=[detail.matrix_world @ v.co for v in detail.data.vertices]
            check(all(v.z>5.0 for v in detail_vertices),
                  f"{detail.name} well above 1.8m player stair level")
            check(all(v.y<face_front+.002 for v in detail_vertices),
                  f"{detail.name} remains in the front detail plane")
unpacked=[im.name for im in bpy.data.images if im.source=="FILE" and not im.packed_file]
check(not unpacked,"all external image sources packed into Blender scene")
report={"schema":"aotl.citadel.phase19.v7.blender_qa.v1",
        "status":"PASS" if not failures else "FAIL",
        "mesh_count":len(meshes),"treads":len([x for x in stair if x]),
        "gothic_stones":len(collection("GATE_Gothic_Voussoir_")),
        "phase18_rosettes":len(collection("PH18_Parapet_GothicRosette_")),
        "phase19_fountains":len(fountains),"phase19_arch_details":len(arch_detail),
        "packed_images":sum(bool(im.packed_file) for im in bpy.data.images),
        "live_godot_f5_approved":False,"canonical_art_approved":False,
        "failures":failures}
print(json.dumps(report,indent=2))
if failures:sys.exit(1)
