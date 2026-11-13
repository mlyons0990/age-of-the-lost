"""Phase20 v8 read-only Blender sculpt and material-batching QA.

Run on Higgsfield editable Citadel revision8, NEVER on approved live Godot scene.
Checks material, location, triangle budget and original stair/arch preservation.
"""
import bpy
import json
import sys
from mathutils import Vector

failures=[]
meshes=[obj for obj in bpy.data.objects if obj.type=="MESH"]
batches=[obj for obj in meshes if obj.name.startswith("PH20_Batched_")]
def check(condition,msg):
    if not condition:failures.append(msg)
def triangles(objects):
    return sum(sum(max(0,len(face.vertices)-2) for face in o.data.polygons) for o in objects)
check(len(meshes)==493,f"expected 493 mesh objects, found {len(meshes)}")
check(triangles(meshes)==8820,f"8820 original triangles expected, found {triangles(meshes)}")
check(len(batches)==12,"twelve material/side batches")
check(not any(obj.name.startswith(("PH19_Fountain_","PH19_Arch_")) for obj in meshes),
      "90 original decorative objects must be represented by batches")
check(len([obj for obj in meshes if obj.name.startswith("PH18_Parapet_GothicRosette_")])==18,
      "all 18 rosettes preserved")
check(len([obj for obj in meshes if obj.name.startswith("GATE_Gothic_Voussoir_")])==32,
      "all 32 original Gothic voussoirs preserved")
check(len([obj for obj in meshes if obj.name.startswith("STAIR_Tread_")])==9,
      "all 9 walkable treads preserved")
source_names=[]
for batch in batches:
    check(batch.get("AOTL_visual_only") is True and batch.get("AOTL_collision") is False,
          f"{batch.name}: must be art-only")
    check(len(batch.data.materials)==1,f"{batch.name}: one unique material")
    check(batch.get("AOTL_batch_provenance")=="Phase19 sculpt v7",
          f"{batch.name}: missing source revision")
    names=json.loads(batch.get("AOTL_source_objects","[]"))
    source_names.extend(names)
    check(len(names)>0,f"{batch.name}: empty source inventory")
    if "_Fountain_" in batch.name:
        positions=[(batch.matrix_world @ Vector(corner)).x for corner in batch.bound_box]
        check(min(positions)>3.75 or max(positions)<-3.75,
              f"{batch.name}: crosses central walking corridor")
    if "_Arch_" in batch.name:
        check(all((batch.matrix_world @ vertex.co).z>5.0
                  for vertex in batch.data.vertices),
              f"{batch.name}: Gothic details must remain far above character grade")
check(len(source_names)==90 and len(set(source_names))==90,
      "exactly 90 unique source ornament objects preserved as provenance")
check(sum(len(bpy.data.objects.get(f"STAIR_Tread_{i:02}").data.vertices)
          for i in range(1,10))>0,"stair geometry still present")
unpacked=[image.name for image in bpy.data.images
          if image.source=="FILE" and image.packed_file is None]
check(not unpacked,f"external texture dependencies: {unpacked}")
result={"schema":"aotl.citadel.phase20.v8.blender_qa.v1",
        "passed":not failures,"scene_meshes":len(meshes),
        "triangles":triangles(meshes),"ornament_source_meshes":len(source_names),
        "art_batches":len(batches),"saved_mesh_objects":78,
        "phase19_originals_remaining":sum(obj.name.startswith(("PH19_Arch_","PH19_Fountain_")) for obj in meshes),
        "packed_images":sum(bool(im.packed_file) for im in bpy.data.images),
        "unpacked_images":unpacked,
        "live_godot_f5_verified":False,"canonical_art_approved":False,
        "failures":failures}
print(json.dumps(result,indent=2))
if failures:sys.exit(1)
