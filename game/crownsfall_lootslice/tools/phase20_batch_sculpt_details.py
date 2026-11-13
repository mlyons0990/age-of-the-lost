"""Phase20: losslessly consolidate v7 ornamental meshes into material batches.

Exact visual geometry is conserved (vertex positions and polygons), and each
original phase19 mesh can be reconstructed from its preserved generator.
Run on *Higgsfield revision 7* only; revision 7 remains immutable in history.
Does not touch player, character, collision, navigation, saves or core masonry.
"""
from collections import defaultdict, Counter
import hashlib
import json
import bpy

SOURCE_PREFIXES=("PH19_Fountain_","PH19_Arch_")
REQUIRED_OBJECTS=90
EXPECTED_SCENE_MESHES=571

def digest_positions(items):
    rounded=[]
    for obj in items:
        for vert in obj.data.vertices:
            point=obj.matrix_world @ vert.co
            rounded.append(",".join(f"{float(coord):.6f}" for coord in point))
    return hashlib.sha256("\n".join(sorted(rounded)).encode()).hexdigest()

def install_batches():
    scene_meshes=[o for o in bpy.data.objects if o.type=="MESH"]
    if len(scene_meshes)!=EXPECTED_SCENE_MESHES:
        raise RuntimeError(f"Expected v7 571 mesh base; got {len(scene_meshes)}")
    if any(o.name.startswith("PH20_Batched_") for o in scene_meshes):
        raise RuntimeError("Phase20 batches already installed")
    candidates=[o for o in scene_meshes if o.name.startswith(SOURCE_PREFIXES)]
    if len(candidates)!=REQUIRED_OBJECTS:
        raise RuntimeError(f"Expected {REQUIRED_OBJECTS} v7 ornamental meshes")
    groups=defaultdict(list)
    for obj in candidates:
        if obj.get("AOTL_collision") is not False or obj.get("AOTL_visual_only") is not True:
            raise RuntimeError(f"Refusing nonvisual mesh {obj.name}")
        if len(obj.data.materials)!=1:
            raise RuntimeError(f"Expected exactly one material on {obj.name}")
        family="Arch" if obj.name.startswith("PH19_Arch_") else "Fountain"
        # Keep individual fountains separately cullable.
        side="L" if obj.name.startswith("PH19_Fountain_L_") else (
            "R" if obj.name.startswith("PH19_Fountain_R_") else "Whole")
        key=(family,side,obj.data.materials[0].name)
        groups[key].append(obj)
    report={"version":1,"pre_scene_meshes":len(scene_meshes),
            "pre_decorative_meshes":len(candidates),
            "original_groups":{},"batches":[]}
    new_objects=[]
    try:
        for (family,side,material_name),objects in sorted(groups.items()):
            objects=sorted(objects,key=lambda obj:obj.name)
            vertices=[]
            faces=[]
            original_triangles=0
            for obj in objects:
                transform=obj.matrix_world
                offset=len(vertices)
                vertices.extend(tuple(transform @ vertex.co) for vertex in obj.data.vertices)
                for polygon in obj.data.polygons:
                    faces.append(tuple(offset+index for index in polygon.vertices))
                    original_triangles+=len(polygon.vertices)-2
            mesh=bpy.data.meshes.new(f"PH20_{family}_{side}_{material_name}_Geometry")
            mesh.from_pydata(vertices,[],faces)
            mesh.update()
            mesh.materials.append(bpy.data.materials[material_name])
            safe_material=material_name.replace("MAT_","").replace("_","")
            name=f"PH20_Batched_{family}_{side}_{safe_material}"
            batch=bpy.data.objects.new(name,mesh)
            bpy.context.scene.collection.objects.link(batch)
            batch["AOTL_visual_only"]=True
            batch["AOTL_collision"]=False
            batch["AOTL_batch_provenance"]="Phase19 sculpt v7"
            batch["AOTL_source_objects"]=json.dumps([o.name for o in objects])
            new_objects.append(batch)
            before=digest_positions(objects)
            after=digest_positions([batch])
            if before!=after:
                raise RuntimeError(f"World-space vertex hash mismatch for {name}")
            result_triangles=sum(len(p.vertices)-2 for p in batch.data.polygons)
            if result_triangles!=original_triangles:
                raise RuntimeError(f"Triangles changed for {name}")
            report["original_groups"][name]=[o.name for o in objects]
            report["batches"].append({"name":name,"material":material_name,
              "source_meshes":len(objects),"vertices":len(vertices),
              "triangles":result_triangles,"vertex_sha256":after})
        for obj in candidates:
            bpy.data.objects.remove(obj,do_unlink=True)
        final_meshes=len([o for o in bpy.data.objects if o.type=="MESH"])
        report.update({"final_scene_meshes":final_meshes,
          "new_batch_count":len(new_objects),
          "removed_original_objects":len(candidates),
          "reduced_mesh_count":len(scene_meshes)-final_meshes,
          "triangle_count_preserved":True,
          "all_vertex_positions_preserved":True})
        if final_meshes!=len(scene_meshes)-len(candidates)+len(new_objects):
            raise RuntimeError("Unexpected final scene mesh count")
        return report
    except Exception:
        # If error happens before original deletion, remove new artifacts.
        for obj in new_objects:
            if obj.name in bpy.data.objects:
                bpy.data.objects.remove(obj,do_unlink=True)
        raise

if __name__=="__main__":
    print(json.dumps(install_batches(),indent=2))
