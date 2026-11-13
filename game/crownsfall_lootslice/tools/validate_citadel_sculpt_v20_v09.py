"""Phase20 v9 Blender sculpt QA — material/UV-safe ornamental consolidation.

Read-only. Run on editable 3D Jutsu v9 or its exact exported .blend.
Does not establish canon art approval, live F5 traversal or runtime FPS.
"""
import bpy
import json
import sys

errors=[]
all_meshes=[o for o in bpy.data.objects if o.type=="MESH"]
v8_batches=[o for o in all_meshes if o.name.startswith("PH20_Batched_")]
v9_batches=[o for o in all_meshes if o.name.startswith("PH20_UVBatch_")]
singletons=[o for o in all_meshes if o.name.startswith("PH17_")]

def verify(condition,description):
    if not condition:errors.append(description)
def ntris(objects):
    return sum(sum(len(poly.vertices)-2 for poly in o.data.polygons) for o in objects)
verify(len(all_meshes)==309,f"expected 309 mesh objects, got {len(all_meshes)}")
verify(ntris(all_meshes)==8820,f"expected 8820 triangles, got {ntris(all_meshes)}")
verify(len(v8_batches)==12,f"expected 12 original v8 ornament batches, got {len(v8_batches)}")
verify(len(v9_batches)==34,f"expected 34 new material-spatial UV batches, got {len(v9_batches)}")
verify(len(singletons)==4,f"expected 4 original PH17 singleton decorative parts, got {len(singletons)}")
verify(len([o for o in all_meshes if o.name.startswith("STAIR_Tread_")])==9,
       "nine stair tread originals unchanged")
verify(len([o for o in all_meshes if o.name.startswith("GATE_Gothic_Voussoir_")])==32,
       "32 Gothic arch source stones unchanged")
verify(len([o for o in all_meshes if o.name.startswith("PH18_Parapet_GothicRosette_")])==18,
       "18 rosettes retained")
total_names=[]
for batch in v9_batches:
    verify(len(batch.data.materials)==1,f"{batch.name}: must have exactly one material")
    verify(len(batch.data.uv_layers)==1,f"{batch.name}: exactly one UV layer")
    verify(batch.get("AOTL_visual_only") is True and batch.get("AOTL_collision") is False,
           f"{batch.name}: missing visual-only/collider-free tag")
    verify(batch.get("AOTL_source_revision")==8,
           f"{batch.name}: provenance revision lost")
    provenance=json.loads(batch.get("AOTL_sources","[]"))
    verify(len(provenance)>=2,f"{batch.name}: batching singleton is wasteful")
    total_names.extend(provenance)
verify(len(total_names)==218,
       f"expected 218 source objects from UV batches; got {len(total_names)}")
verify(len(total_names)==len(set(total_names)),
       "no repeated source object names in batch provenance")
verify(all(name.startswith("PH17_") for name in total_names),
       "batch provenance must be from PH17 ornamental library")
verify(len(set(total_names)|{o.name for o in singletons})==222,
       "all 222 original PH17 objects must be accounted for")
unpacked=[im.name for im in bpy.data.images
          if im.source=="FILE" and not im.packed_file]
verify(not unpacked,f"missing external textures: {unpacked}")
result={"schema":"aotl.citadel.phase20.v9.blender_qa.v1",
        "passed":not errors,"scene_mesh_objects":len(all_meshes),
        "triangles":ntris(all_meshes),"phase19_batches":len(v8_batches),
        "phase17_uv_batches":len(v9_batches),
        "uv_source_objects_merged":len(total_names),
        "remaining_decorative_singletons":len(singletons),
        "total_mesh_objects_saved_from_v7":571-len(all_meshes),
        "packed_images":sum(bool(im.packed_file) for im in bpy.data.images),
        "unpacked_images":unpacked,
        "original_approved_phase11_f5_verified":False,
        "actual_godot_fps_measured":False,
        "errors":errors}
print(json.dumps(result,indent=2))
if errors:sys.exit(1)
