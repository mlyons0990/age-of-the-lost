#!/usr/bin/env python3
"""Phase23: upload a QA-verified *binary* GLB as a Git blob, never Git LFS.

For one isolated GitHub Actions branch job ONLY after all Phase23 Blender/Godot
checks passed. Write scope is pinned to the existing draft development branch;
never touches main. Uses base_tree and a non-force fast-forward ref update.

This explicitly bypasses the generic game/**/*.glb Git LFS rule so that the
artifact is a real repository blob, as Phase22's actual GLB was. Avoid invoking
it on new unverified art or private projects without permission.
"""
import base64
import hashlib
import json
import os
from pathlib import Path
import sys
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import Request,urlopen

BRANCH="feature/phase17-citadel-masonry-texture-and-occlusion"
REPO="mlyons0990/age-of-the-lost"
ROOT=Path(__file__).resolve().parents[1]
PATH_IN_REPO="game/crownsfall_lootslice/assets/25d/citadel/AOTL_Citadel_Painterly_v13.glb"
LOCAL=ROOT/"assets/25d/citadel/AOTL_Citadel_Painterly_v13.glb"
QA=LOCAL.with_suffix(".qa.json")

def request(method,endpoint,payload=None,allow_404=False):
    token=os.environ["GITHUB_TOKEN"]
    data=json.dumps(payload).encode() if payload is not None else None
    url="https://api.github.com/repos/"+REPO+"/"+endpoint
    headers={"Authorization":"Bearer "+token,
             "Accept":"application/vnd.github+json",
             "X-GitHub-Api-Version":"2022-11-28",
             "Content-Type":"application/json",
             "User-Agent":"AOTL-phase23-verified-draft"}
    req=Request(url,data=data,headers=headers,method=method)
    try:
        with urlopen(req,timeout=95) as resp:
            return json.loads(resp.read().decode())
    except HTTPError as err:
        if allow_404 and err.code==404:return None
        raise RuntimeError(f"GitHub API {method} {endpoint}: HTTP {err.code}") from err

def main():
    if os.environ.get("GITHUB_REPOSITORY")!=REPO or os.environ.get("GITHUB_REF_NAME")!=BRANCH:
        raise RuntimeError("Refusing any repository or ref other than AOTL draft feature branch")
    if not LOCAL.is_file() or not QA.is_file():
        raise FileNotFoundError("Verified GLB / accompanying Blender QA missing")
    payload=LOCAL.read_bytes()
    actual_hash=hashlib.sha256(payload).hexdigest()
    qc=json.loads(QA.read_text(encoding="utf8"))
    if actual_hash!=qc["output_sha256"]:
        raise RuntimeError("GLB no longer matches its saved Blender verification")
    if int(qc["mesh_count"])!=309 or len(qc["new_textures"])!=3:
        raise RuntimeError("GLB not accepted as Phase23 309-mesh three-atlas candidate")
    if qc.get("original_game_modified") is not False:
        raise RuntimeError("Unsafe source mutation in QA evidence")
    # Never silently replace existing art at this permanent branch path.
    filename=quote(PATH_IN_REPO,safe="/")
    existing=request("GET",f"contents/{filename}?ref={quote(BRANCH,safe='')}",allow_404=True)
    if existing is not None:
        raise FileExistsError("Permanent v13 binary path already exists; manual review required")
    encoded=base64.b64encode(payload).decode("ascii")
    blob=request("POST","git/blobs",{"content":encoded,"encoding":"base64"})
    blob_sha=blob["sha"]
    ref_endpoint="git/ref/heads/"+quote(BRANCH,safe="/")
    update_endpoint="git/refs/heads/"+quote(BRANCH,safe="/")
    for attempt in range(2):
        current=request("GET",ref_endpoint)["object"]["sha"]
        prior=request("GET","git/commits/"+current)
        tree=request("POST","git/trees",{
            "base_tree":prior["tree"]["sha"],
            "tree":[
                {"path":PATH_IN_REPO,"mode":"100644","type":"blob","sha":blob_sha},
                {"path":PATH_IN_REPO[:-4]+".qa.json","mode":"100644","type":"blob",
                 "content":QA.read_text(encoding="utf8")}
            ]})
        commit=request("POST","git/commits",{
            "message":"Phase23: preserve CI-verified real painted Citadel v13 GLB and Blender QA (draft only)",
            "tree":tree["sha"],"parents":[current]})
        try:
            updated=request("PATCH",update_endpoint,{"sha":commit["sha"],"force":False})
            print(json.dumps({"published":True,"commit":commit["sha"],
                "blob_sha":blob_sha,"sha256":actual_hash,"bytes":len(payload),
                "branch":BRANCH,"main_untouched":True},indent=2))
            return
        except RuntimeError:
            if attempt:raise
            # Retry once only if another draft-branch commit raced the ref.
    raise RuntimeError("GitHub branch changed concurrently; no unsafe force update")

if __name__=="__main__":
    main()
