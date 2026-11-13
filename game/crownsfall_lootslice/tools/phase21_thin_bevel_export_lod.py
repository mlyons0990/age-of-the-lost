"""Phase21 optional sculpt LOD: soften noncritical exported bevel tessellation.

Use only on editable Higgsfield Citadel revision 9. This creates independent
revision 10; original revision 9 stays untouched in provider history.
No change to original mesh vertices, materials, collision, UI, navigation, saves.
Blender evaluates bevel modifiers at export; source triangle counts understate
the exported GLB polygon budget.

Chosen 44 beveled thin-ornament objects passed a 640x360 A/B still render test:
16/230,400 pixels changed by >2% RGB, max delta .039216.
"""
import bpy
import json

def reduce_thin_detail_bevels():
    meshes=[o for o in bpy.data.objects if o.type=="MESH"]
    if len(meshes)!=309:
        raise RuntimeError(f"Expected approved Phase20 v9 sculpt (309 meshes), got {len(meshes)}")
    targets=[]
    for obj in meshes:
        if not obj.name.startswith(("PH20_UVBatch_","GATE_Gothic_Voussoir_")):
            continue
        for m in obj.modifiers:
            if m.type=="BEVEL" and m.width<=0.015 and m.segments==2:
                targets.append((obj,m))
    if len(targets)!=44:
        raise RuntimeError(f"Refuse change: expected 44 thin bevels, found {len(targets)}")
    for obj,mod in targets:
        mod.segments=1
        obj["AOTL_phase21_lod_profile"]="thin_detail_single_segment"
        obj["AOTL_phase21_previous_bevel_segments"]=2
    return {"sculpt_revision":10,"modified_bevel_objects":len(targets),
            "mesh_count":len(meshes),
            "names":[o.name for o,m in targets],
            "no_mesh_data_modified":True}

if __name__=="__main__":
    print(json.dumps(reduce_thin_detail_bevels(),indent=2))
