"""Phase20 v9: spatially-aware and UV-preserving reduction of 222 PH17 details.

On *exact* optimized Phase20 v8 only. Original v8 retained in Higgsfield
revision history. PH17 decorative meshes have UV texture coordinates; preserve
those by joining via Blender, NOT by building simple new vertex-only meshes.

Groups by sculptural family, material, side of route, and 4m depth bands to
protect view-frustum culling and material behavior.
"""
import bpy
import hashlib
import json
import math
from collections import defaultdict

SOURCE_PREFIX="PH17_"
BATCH_PREFIX="PH20_UVBatch_"
EXPECTED_SCENE_MESH_COUNT=493
EXPECTED_SOURCE_DETAIL_COUNT=222

def uv_world_records(objects):
    faces=[]
    loops=defaultdict(list)
    for obj in objects:
        if len(obj.data.uv_layers)!=1:
            raise RuntimeError(f"Missing exactly one UV layer: {obj.name}")
        uv=obj.data.uv_layers[0].data
        for polygon in obj.data.polygons:
            face_uv=[]
            for loopid in polygon.loop_indices:
                index=obj.data.loops[loopid].vertex_index
                world=obj.matrix_world @ obj.data.vertices[index].co
                tex=uv[loopid].uv
                key=tuple(round(float(v),6) for v in tex)
                face_uv.append(key)
                loops[key].append((float(world.x),float(world.y),float(world.z)))
            faces.append(tuple(face_uv))
    return {"faces":faces,"loops":loops}

def verify_uv_world_preserved(before,after,tolerance_m=0.0001):
    # Blender's applied world transforms use float32 and can shift values by
    # ~1 micron even when the UV and actual geometry are visually identical.
    # Compare exact per-face UVs and measure numeric spatial displacement,
    # never use fragile rounded coordinate hashes as a substitute.
    if sorted(before["faces"])!=sorted(after["faces"]):
        raise RuntimeError("UV face winding, coordinates or topology changed")
    if set(before["loops"])!=set(after["loops"]):
        raise RuntimeError("UV loop dictionary changed")
    max_error=0.0
    for key,source in before["loops"].items():
        remaining=list(after["loops"][key])
        if len(remaining)!=len(source):
            raise RuntimeError("UV loop multiplicity changed")
        for p in source:
            distances=[math.dist(p,q) for q in remaining]
            index=min(range(len(distances)),key=lambda i:distances[i])
            error=distances[index]
            if error>tolerance_m:
                raise RuntimeError(f"Geometry drift {error}m above {tolerance_m}m")
            max_error=max(max_error,error)
            remaining.pop(index)
    uv_digest=hashlib.sha256(repr(sorted(after["faces"])).encode()).hexdigest()
    return uv_digest,max_error

def mesh_tris(objects):
    return sum(sum(len(p.vertices)-2 for p in obj.data.polygons)
               for obj in objects)

def optimize_uv_details():
    meshes=[o for o in bpy.data.objects if o.type=="MESH"]
    if len(meshes)!=EXPECTED_SCENE_MESH_COUNT:
        raise RuntimeError(f"Expected 493 v8 meshes, got {len(meshes)}")
    if any(o.name.startswith(BATCH_PREFIX) for o in meshes):
        raise RuntimeError("UV detail batching already applied")
    source=[o for o in meshes if o.name.startswith(SOURCE_PREFIX)]
    if len(source)!=EXPECTED_SOURCE_DETAIL_COUNT:
        raise RuntimeError(f"Expected 222 PH17 detail meshes; got {len(source)}")
    buckets=defaultdict(list)
    for obj in source:
        family="_".join(obj.name.split("_")[:2]).replace("PH17_","")
        mat=obj.data.materials
        if len(mat)!=1:raise RuntimeError(f"Expected single material {obj.name}")
        if len(obj.data.uv_layers)!=1:raise RuntimeError(f"Expected UVMap {obj.name}")
        side="L" if obj.location.x < -.25 else ("R" if obj.location.x > .25 else "C")
        band=math.floor(obj.location.y/4)
        buckets[(family,mat[0].name,side,band)].append(obj)
    out={"schema":"aotl.citadel.phase20.v9.uv_batch_report.v1",
         "before_objects":len(meshes),
         "source_objects":len(source),
         "source_triangles":mesh_tris(source),
         "groups":[],"retained_singletons":[]}
    for (family,material,side,band),members in sorted(buckets.items()):
        if len(members)<2:
            out["retained_singletons"].append(members[0].name)
            continue
        members=sorted(members,key=lambda o:o.name)
        before_records=uv_world_records(members)
        before_triangles=mesh_tris(members)
        sample_names=[o.name for o in members]
        bpy.ops.object.select_all(action="DESELECT")
        for obj in members:obj.select_set(True)
        bpy.context.view_layer.objects.active=members[0]
        bpy.ops.object.join()
        batch=members[0]
        batch.name=f"{BATCH_PREFIX}{family}_{side}_B{band:+03d}_{material.replace('MAT_','')}"
        batch["AOTL_visual_only"]=True
        batch["AOTL_collision"]=False
        batch["AOTL_source_revision"]=8
        batch["AOTL_sources"]=json.dumps(sample_names)
        batch.select_set(False)
        if len(batch.data.materials)!=1:
            raise RuntimeError(f"Material slot changed for {batch.name}")
        if batch.data.materials[0].name!=material:
            raise RuntimeError(f"Material changed for {batch.name}")
        after_records=uv_world_records([batch])
        after_hash,max_worldspace_drift=verify_uv_world_preserved(
            before_records,after_records)
        after_triangles=mesh_tris([batch])
        if before_triangles!=after_triangles:
            raise RuntimeError(f"Triangle count mismatch {batch.name}")
        out["groups"].append({"batch":batch.name,"source_count":len(sample_names),
             "source_names":sample_names,"material":material,
             "triangles":before_triangles,"face_uv_sha256":after_hash,
             "maximum_position_error_m":max_worldspace_drift,
             "side":side,"depth_band_4m":band})
    remaining=[o for o in bpy.data.objects if o.type=="MESH"]
    out["optimized_objects"]=len(remaining)
    out["new_batch_count"]=len(out["groups"])
    out["saved_objects"]=len(meshes)-len(remaining)
    out["source_accounted_for"]=sum(g["source_count"] for g in out["groups"])+len(out["retained_singletons"])
    out["total_triangles"]=mesh_tris(remaining)
    if out["source_accounted_for"]!=EXPECTED_SOURCE_DETAIL_COUNT:
        raise RuntimeError("Lost PH17 source detail inventory")
    if out["total_triangles"]!=8820:
        raise RuntimeError("Total scene triangle count was modified")
    return out

if __name__=="__main__":
    print(json.dumps(optimize_uv_details(),indent=2))
