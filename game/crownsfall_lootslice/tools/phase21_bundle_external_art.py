#!/usr/bin/env python3
"""AOTL Phase21: create a checksummed external portable Citadel art ZIP.

Creates a NEW archive outside the approved game; never imports or writes to
approved Godot project, any .blend, or the source GLB. Uses prevalidated
version10 GLB (309 meshes, <=27000 actual exported triangles, 2 packed images).
No GUI, Godot or Blender install required. Python 3.11+.

python tools/phase21_bundle_external_art.py \\
    --glb C:/Exports/preview_v10.glb --blend C:/Exports/scene_v10.blend \\
    --out D:/AOTL_Backups/AOTL_Citadel_Optimized_v10.zip \\
    --approved-project C:/AOTL/Approved_Original
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile
import zipfile

from phase21_external_glb_gate import inspect_glb

FILES={"AOTL_Citadel_Optimized_v10.glb":"glb",
       "AOTL_Citadel_Editable_v10.blend":"blend"}
MANIFEST_NAME="AOTL_Citadel_v10_Verified_Manifest.json"

def hash_file(path: Path) -> str:
    sha=hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024*1024),b""):
            sha.update(block)
    return sha.hexdigest()

def archive_info(name: str):
    info=zipfile.ZipInfo(name, (2026,1,1,0,0,0))
    info.compress_type=zipfile.ZIP_DEFLATED
    info.external_attr=0o100644<<16
    return info

def verify(archive: Path) -> dict:
    with zipfile.ZipFile(archive) as z:
        if z.testzip() is not None:
            raise ValueError("ZIP CRC failure")
        names=z.namelist()
        if len(names)!=len(set(names)):
            raise ValueError("Duplicate ZIP entries")
        expected=set(FILES)|{MANIFEST_NAME}
        if set(names)!=expected:
            raise ValueError(f"Unexpected or missing ZIP entries: {set(names)^expected}")
        manifest=json.loads(z.read(MANIFEST_NAME))
        if manifest.get("schema")!="aotl.citadel.phase21.portable_bundle.v1":
            raise ValueError("Unknown bundle manifest schema")
        for name,metadata in manifest["files"].items():
            sha=hashlib.sha256()
            nbytes=0
            with z.open(name) as stream:
                for block in iter(lambda:stream.read(1024*1024),b""):
                    sha.update(block)
                    nbytes+=len(block)
            if sha.hexdigest()!=metadata["sha256"] or nbytes!=metadata["bytes"]:
                raise ValueError(f"Member integrity mismatch: {name}")
        return {"verified":True,"files":len(manifest["files"]),
                "model_triangles":manifest["glb_gate"]["actual_exported_triangles"],
                "model_meshes":manifest["glb_gate"]["mesh_nodes"]}

def create(glb: Path, blend: Path, output: Path,
           approved_project: Path|None=None) -> dict:
    if glb.expanduser().is_symlink() or blend.expanduser().is_symlink():
        raise ValueError("Input symlinks are not acceptable")
    if output.expanduser().is_symlink():
        raise FileExistsError("Refusing symlinked output destination")
    glb=glb.expanduser().resolve(strict=True)
    blend=blend.expanduser().resolve(strict=True)
    output=output.expanduser().resolve()
    if glb==blend or glb==output or blend==output:
        raise ValueError("Source and output files must be distinct")
    if output.exists() or output.is_symlink():
        raise FileExistsError("Refusing to overwrite an existing bundle")
    if output.suffix.lower()!=".zip":
        raise ValueError("Output must have .zip suffix")
    if approved_project is not None:
        approved=approved_project.expanduser().resolve(strict=True)
        if not (approved/"project.godot").is_file():
            raise ValueError("Approved project is not a Godot project")
        if approved==output or approved in output.parents:
            raise ValueError("Portable ZIP cannot be written inside approved game")
    if blend.read_bytes()[:7]!=b"BLENDER":
        raise ValueError("Editable .blend file lacks Blender magic signature")
    gate=inspect_glb(glb,mesh_nodes=309,max_triangles=27000,min_images=2)
    input_files={name:glb if kind=="glb" else blend
                 for name,kind in FILES.items()}
    original={name:{"bytes":p.stat().st_size,"mtime_ns":p.stat().st_mtime_ns,
                    "sha256":hash_file(p)} for name,p in input_files.items()}
    manifest={"schema":"aotl.citadel.phase21.portable_bundle.v1",
              "candidate_only":True,"main_game_safe_to_merge":False,
              "source_sculpt_revision":10,
              "export_sha256":gate["sha256"],
              "glb_gate":gate,"files":original,
              "authentic_phase11_f5_verified":False,
              "godot_external_import_verified":False}
    output.parent.mkdir(parents=True,exist_ok=True)
    fd,temp=tempfile.mkstemp(prefix=".aotl_phase21_",suffix=".zip.tmp",
                             dir=output.parent)
    os.close(fd)
    created=False
    try:
        with zipfile.ZipFile(temp,"w",compression=zipfile.ZIP_DEFLATED) as z:
            for name,path in input_files.items():
                with path.open("rb") as src, z.open(archive_info(name),"w") as target:
                    for block in iter(lambda:src.read(1024*1024),b""):
                        target.write(block)
            z.writestr(archive_info(MANIFEST_NAME),
                       json.dumps(manifest,indent=2,sort_keys=True).encode())
        verify(Path(temp))
        for name,path in input_files.items():
            now=(path.stat().st_size,path.stat().st_mtime_ns,hash_file(path))
            old=original[name]
            if now!=(old["bytes"],old["mtime_ns"],old["sha256"]):
                raise RuntimeError("Source changed during bundled snapshot")
        with output.open("xb") as target, open(temp,"rb") as src:
            created=True
            for block in iter(lambda:src.read(1024*1024),b""):
                target.write(block)
        verified=verify(output)
        return {"bundle_path":str(output),"sha256":hash_file(output),
                "bytes":output.stat().st_size,**verified}
    except Exception:
        if created: output.unlink(missing_ok=True)
        raise
    finally:
        Path(temp).unlink(missing_ok=True)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--glb",type=Path,required=True)
    p.add_argument("--blend",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--approved-project",type=Path)
    p.add_argument("--verify",action="store_true")
    args=p.parse_args()
    print(json.dumps(verify(args.out) if args.verify else
                     create(args.glb,args.blend,args.out,args.approved_project),
                     indent=2))

if __name__=="__main__":
    main()
