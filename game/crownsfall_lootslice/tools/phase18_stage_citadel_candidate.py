#!/usr/bin/env python3
"""Safely stage the vetted Phase17 Citadel GLB for later *manual* Phase11 integration.

Requires a verified, immutable backup of the actual approved project made with
phase18_citadel_immutable_backup.py. Adds only the GLB and manifest to a new,
inactive candidate folder. It never touches scenes, scripts, saves, gameplay,
navigation, project.godot or the active art paths. Dry-run by default.

Usage:
 python tools/phase18_stage_citadel_candidate.py --approved "C:/AOTL/Approved" --source "C:/AOTL/Phase17" --backup "D:/Backups/Approved.zip"
 python tools/phase18_stage_citadel_candidate.py --approved "C:/AOTL/Approved" --source "C:/AOTL/Phase17" --backup "D:/Backups/Approved.zip" --apply
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys
import zipfile
from phase18_citadel_immutable_backup import verify_snapshot, MANIFEST_NAME

GLB_NAME = "AOTL_Citadel_MasonryArt_v17.glb"
MANIFEST_FILE = "AOTL_Citadel_MasonryArt_v17.json"
# Verified exact binary from Phase17 CI and PR #55.
EXPECTED_GLB_SHA256 = "84989a6e572dde75f406c2ce2c8cb435015c55ea0bb79571061930e0c2119ca2"
CANDIDATE_SUBDIR = Path("assets/25d/citadel/candidates_phase17_inactive")
SOURCE_SUBDIR = Path("assets/25d/citadel")

def digest(path: Path) -> str:
    h=hashlib.sha256()
    with path.open("rb") as inp:
        for block in iter(lambda: inp.read(1024*1024), b""):
            h.update(block)
    return h.hexdigest()

def plan(approved: Path, source: Path, backup: Path, expected_sha=EXPECTED_GLB_SHA256) -> dict:
    approved=approved.expanduser().resolve(strict=True)
    source=source.expanduser().resolve(strict=True)
    backup=backup.expanduser().resolve(strict=True)
    if not (approved/"project.godot").is_file():
        raise ValueError("Approved project missing project.godot")
    if approved==source or approved in source.parents or source in approved.parents:
        raise ValueError("Approved project and candidate source must be separate")
    target=approved/CANDIDATE_SUBDIR
    files=[target/name for name in (GLB_NAME,MANIFEST_FILE)]
    if target.is_symlink() or not target.resolve().is_relative_to(approved):
        raise ValueError("Candidate staging directory escapes approved project")
    if any(p.exists() or p.is_symlink() for p in files):
        raise FileExistsError("Inactive candidate already present: refuse overwrite")
    verified=verify_snapshot(backup)
    if not verified.get("verified"):
        raise ValueError("Backup archive was not verified")
    with zipfile.ZipFile(backup) as archive:
        manifest=json.loads(archive.read(MANIFEST_NAME))
    backed={entry["path"]:entry for entry in manifest["files"]}
    if "project.godot" not in backed:
        raise ValueError("Backup does not include project.godot")
    for relative, entry in backed.items():
        live=approved/relative
        if not live.is_file() or live.is_symlink() or digest(live)!=entry["sha256"]:
            raise ValueError(f"Original project changed since backup: {relative}")
    # Also reject any added regular file not in the backup snapshot. Cache dirs excluded.
    from phase18_citadel_immutable_backup import source_files
    current={name for name,_ in source_files(approved)}
    if current!=set(backed):
        raise ValueError("Approved project inventory differs from backup")
    candidates=[source/SOURCE_SUBDIR/name for name in (GLB_NAME,MANIFEST_FILE)]
    for p in candidates:
        if p.is_symlink() or not p.is_file():
            raise ValueError(f"Missing candidate: {p.name}")
    glb_sha=digest(candidates[0])
    if glb_sha != expected_sha:
        raise ValueError(f"GLB checksum mismatch: {glb_sha}")
    data=json.loads(candidates[1].read_text(encoding="utf-8"))
    if int(data.get("nodes",-1))!=1197 or data.get("has_gameplay_colliders") is not False:
        raise ValueError("Manifest is not verified 1197-mesh art-only Phase17 geometry")
    if data.get("status")!="art_candidate_not_canon_not_higgsfield_export":
        raise ValueError("Candidate manifest must disclose non-canon status")
    target=approved/CANDIDATE_SUBDIR
    files=[target/p.name for p in candidates]
    if target.is_symlink() or any(p.exists() or p.is_symlink() for p in files):
        raise FileExistsError("Inactive candidate already present: refuse overwrite")
    return {"status":"STAGING_ONLY_NOT_ENABLED", "files":2,
            "candidate_sha256":glb_sha, "approved_project":str(approved),
            "target":str(target), "sources":[str(p) for p in candidates],
            "destination_files":[str(p) for p in files], "backup_files_verified":len(backed)}

def stage(approved: Path, source: Path, backup: Path, apply: bool=False,
          expected_sha=EXPECTED_GLB_SHA256) -> dict:
    result=plan(approved,source,backup,expected_sha)
    if not apply:
        result["applied"]=False
        return result
    target=Path(result["target"])
    target.mkdir(parents=True,exist_ok=False)
    copied=[]
    try:
        for src,dest in zip(result["sources"], result["destination_files"]):
            with open(src,"rb") as a, open(dest,"xb") as b:
                shutil.copyfileobj(a,b,length=1024*1024)
            copied.append(Path(dest))
            if digest(Path(src))!=digest(Path(dest)):
                raise ValueError("Copy integrity check failed")
        result["applied"]=True
    except Exception:
        for path in copied:
            path.unlink(missing_ok=True)
        target.rmdir()
        raise
    return result

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--approved",type=Path,required=True)
    p.add_argument("--source",type=Path,required=True)
    p.add_argument("--backup",type=Path,required=True)
    p.add_argument("--apply",action="store_true",help="Stage only the verified art candidate")
    args=p.parse_args()
    result=stage(args.approved,args.source,args.backup,args.apply)
    print(json.dumps(result,indent=2))

if __name__=="__main__":
    main()
