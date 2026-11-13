#!/usr/bin/env python3
"""AOTL Phase21: standalone, dependency-free validation of candidate GLB bytes.

Does NOT import art into the active Godot scene. Inspect exported v10 binaries
before placing them in an unused staging folder. Checks actual *post-modifier*
GLB triangle counts, not Blender source mesh polygon counts.

Example:
 python tools/phase21_external_glb_gate.py AOTL_Citadel_Phase21_v10.glb \\
   --mesh-nodes 309 --max-triangles 27000 --min-images 2 --output audit.json
"""
from __future__ import annotations

import argparse
import hashlib
import json
import struct
from pathlib import Path
from typing import Any

MAGIC=b"glTF"
JSON_CHUNK=b"JSON"
BIN_CHUNK=b"BIN\\x00"
GLB_HEADER=12
CHUNK_HEADER=8
FORBIDDEN_NODES=("collisionshape","staticbody","rigidbody","navigationregion",
                 "characterbody","area3d")

class GlbRejected(ValueError):
    pass

def reject(message: str):
    raise GlbRejected(message)

def inspect_glb(path: Path, mesh_nodes: int | None = None,
                max_triangles: int | None = None, min_images: int = 0,
                expected_sha256: str | None = None,
                require_citadel_landmarks: bool = True) -> dict[str, Any]:
    if path.is_symlink() or not path.is_file():
        reject("GLB candidate missing or symlinked")
    payload=path.read_bytes()
    if len(payload)<GLB_HEADER+CHUNK_HEADER:
        reject("GLB too short")
    magic,version,declared_len=struct.unpack_from("<4sII",payload,0)
    if magic!=MAGIC or version!=2 or declared_len!=len(payload):
        reject("Invalid GLB 2.0 header or total byte length")
    if len(payload)%4:
        reject("GLB size is not 4-byte aligned")
    sha256=hashlib.sha256(payload).hexdigest()
    if expected_sha256 and sha256!=expected_sha256.lower():
        reject("SHA-256 of GLB does not match expected binary")
    offset=GLB_HEADER
    chunks=[]
    while offset<len(payload):
        if offset+CHUNK_HEADER>len(payload):
            reject("Truncated GLB chunk header")
        length,ctype=struct.unpack_from("<I4s",payload,offset)
        offset+=CHUNK_HEADER
        if length%4 or offset+length>len(payload):
            reject("Invalid GLB chunk length or alignment")
        chunks.append((ctype,payload[offset:offset+length]))
        offset+=length
    if not chunks or chunks[0][0]!=JSON_CHUNK:
        reject("First GLB chunk must be JSON")
    if len(chunks)>2 or (len(chunks)==2 and chunks[1][0]!=BIN_CHUNK):
        reject("Unexpected GLB chunk ordering")
    try:
        document=json.loads(chunks[0][1].decode("utf-8").rstrip(" \t\r\n\x00"))
    except (UnicodeError,json.JSONDecodeError) as e:
        reject(f"Malformed glTF JSON: {e}")
    if document.get("asset",{}).get("version")!="2.0":
        reject("glTF JSON asset.version is not 2.0")
    buffers=document.get("buffers",[])
    if len(buffers)!=1 or "uri" in buffers[0]:
        reject("Require one embedded BIN buffer, no remote/adjacent buffer URLs")
    binary=chunks[1][1] if len(chunks)==2 else b""
    if int(buffers[0]["byteLength"])>len(binary) or (
            len(binary)-int(buffers[0]["byteLength"])>3):
        reject("Embedded binary buffer does not match glTF declared byteLength")
    views=document.get("bufferViews",[])
    for i,view in enumerate(views):
        start=int(view.get("byteOffset",0))
        length=int(view.get("byteLength",-1))
        if view.get("buffer")!=0 or start<0 or length<0 or start+length>len(binary):
            reject(f"BufferView {i} escapes embedded BIN buffer")
        stride=view.get("byteStride")
        if stride is not None and (int(stride)<4 or int(stride)>252):
            reject(f"Invalid glTF byteStride on bufferView {i}")
    accessors=document.get("accessors",[])
    # Validate reference ranges without reinterpreting individual vertex bytes.
    for i,accessor in enumerate(accessors):
        view=accessor.get("bufferView")
        if view is not None and not (0<=int(view)<len(views)):
            reject(f"Accessor {i} references missing buffer view")
        if int(accessor.get("count",-1))<0:
            reject(f"Accessor {i} has invalid count")
        if accessor.get("sparse"):
            reject("Sparse accessors require separate validation")
    images=document.get("images",[])
    for i,img in enumerate(images):
        if "uri" in img:
            reject(f"Image {i} requires an external URI")
        view=img.get("bufferView")
        if not isinstance(view,int) or not 0<=view<len(views):
            reject(f"Image {i} missing embedded buffer view")
        if img.get("mimeType") not in ("image/png","image/jpeg","image/webp"):
            reject(f"Image {i} unsupported embedded MIME")
    if len(images)<min_images:
        reject(f"Only {len(images)} embedded images; expected at least {min_images}")
    meshes=document.get("meshes",[])
    nodes=document.get("nodes",[])
    materials=document.get("materials",[])
    mesh_name_rows=[]
    for i,node in enumerate(nodes):
        name=str(node.get("name",""))
        normalized=name.lower().replace("_","").replace("-","")
        if any(keyword in normalized for keyword in FORBIDDEN_NODES):
            reject(f"GLB contains gameplay/collision-looking node: {name}")
        if "mesh" in node:
            index=node["mesh"]
            if not isinstance(index,int) or not 0<=index<len(meshes):
                reject(f"Node {i} references absent mesh")
            mesh_name_rows.append(name)
    if len(set(mesh_name_rows))!=len(mesh_name_rows):
        reject("Duplicate mesh node names; cannot reliably audit identity")
    if mesh_nodes is not None and len(mesh_name_rows)!=mesh_nodes:
        reject(f"GLB mesh node count {len(mesh_name_rows)} != {mesh_nodes}")
    if require_citadel_landmarks:
        names=set(mesh_name_rows)
        expected=[f"STAIR_Tread_{i:02d}" for i in range(1,10)]
        expected.extend([f"GATE_Gothic_Voussoir_{i:02d}" for i in range(1,33)])
        missing=[name for name in expected if name not in names]
        if missing:
            reject(f"Missing Citadel source landmarks: {missing[:6]}")
    triangles=0
    primitives=0
    for i,mesh in enumerate(meshes):
        for prim in mesh.get("primitives",[]):
            primitives+=1
            if prim.get("mode",4)!=4:
                reject(f"Non-triangle primitive in mesh {i}")
            material=prim.get("material")
            if material is not None and (
                    not isinstance(material,int) or not 0<=material<len(materials)):
                reject(f"Mesh {i} references invalid material")
            attrs=prim.get("attributes",{})
            if "POSITION" not in attrs:
                reject(f"Mesh {i} missing POSITION vertex attribute")
            position=attrs["POSITION"]
            if not isinstance(position,int) or not 0<=position<len(accessors):
                reject(f"Mesh {i} references absent POSITION accessor")
            index_accessor=prim.get("indices",position)
            if not isinstance(index_accessor,int) or not 0<=index_accessor<len(accessors):
                reject(f"Mesh {i} references absent index accessor")
            count=int(accessors[index_accessor]["count"])
            if count%3:
                reject(f"Mesh {i} triangle index count is not divisible by 3")
            triangles+=count//3
    if max_triangles is not None and triangles>max_triangles:
        reject(f"Actual exported GLB triangles {triangles} exceed {max_triangles}")
    return {
        "schema":"aotl.citadel.phase21.glb_gate.v1",
        "status":"PASS",
        "path":str(path),
        "sha256":sha256,
        "bytes":len(payload),
        "mesh_nodes":len(mesh_name_rows),
        "mesh_definitions":len(meshes),
        "primitives":primitives,
        "actual_exported_triangles":triangles,
        "embedded_images":len(images),
        "materials":len(materials),
        "textures":len(document.get("textures",[])),
        "contains_gameplay_collision":False,
        "real_godot_import_verified":False,
        "user_approved_phase11_integrated":False,
    }

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("glb",type=Path)
    p.add_argument("--mesh-nodes",type=int,default=309)
    p.add_argument("--max-triangles",type=int,default=27000)
    p.add_argument("--min-images",type=int,default=2)
    p.add_argument("--expected-sha256",default=None)
    p.add_argument("--output",type=Path,default=None)
    args=p.parse_args()
    if args.output:
        out=args.output.expanduser().resolve()
        source=args.glb.expanduser().resolve()
        if out==source or out.exists():
            reject("Refuse to overwrite GLB or preexisting audit report")
    result=inspect_glb(args.glb,args.mesh_nodes,args.max_triangles,
                       args.min_images,args.expected_sha256)
    if args.output:
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result,indent=2))

if __name__=="__main__":
    main()
