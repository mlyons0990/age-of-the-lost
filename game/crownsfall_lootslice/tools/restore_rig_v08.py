#!/usr/bin/env python3
"""Restore V08 geometry/UV QA GLB for Godot from GitHub-stored lossless chunks.

QA GLB has the same V08 geometry, joints, weights, UVs and animation channels,
but miniature neutral placeholder textures instead of the final two 2K PNGs.
Full editable source and artwork atlases live in Higgsfield Jutsu revision 20.
"""
from __future__ import annotations
import base64
import hashlib
import json
import lzma
import pathlib
import struct
import sys

HERE=pathlib.Path(__file__).resolve().parent.parent
PREFIX=HERE/"models/source/AOTL_Humanoid_Master_V08_QA_Lite.glb.xz.b64"
PARTS=[pathlib.Path(str(PREFIX)+f".part{i:02d}") for i in range(7)]
DEST=HERE/"models/AOTL_Humanoid_Master_V08.glb"
GLB_SHA="ec8112d1a24de88ff5782fd388bc728479d71689a9b11ad4534b3847b696f7c4"
XZ_SHA="990f00c381e709d53a9c197ac41465b32cdb914c5ee6b694f3b2c7368c83b67d"
def digest(b: bytes)->str:return hashlib.sha256(b).hexdigest()
def main()->int:
    assert all(p.is_file() for p in PARTS),"One or more V08 QA GLB parts are missing"
    archive=b"".join(base64.b64decode(line,validate=True) for p in PARTS for line in p.read_text(encoding="ascii").splitlines() if line.strip())
    assert len(archive)==741992 and digest(archive)==XZ_SHA, "Corrupt V08 QA model source"
    data=lzma.decompress(archive)
    assert len(data)==3406720 and digest(data)==GLB_SHA and data[:4]==b"glTF", "V08 QA GLB checksum failure"
    count=struct.unpack_from("<I",data,12)[0]
    doc=json.loads(data[20:20+count])
    assert len(doc["skins"][0]["joints"])==58
    assert len(doc.get("animations",[]))==1
    assert sum(1 for m in doc["materials"] if m["name"].startswith("V08_"))>=7
    attrs=[p["attributes"] for m in doc["meshes"] for p in m["primitives"]]
    assert sum("TEXCOORD_1" in a for a in attrs)>=22, "Required overlay UV layer was lost"
    if DEST.is_file():
        if DEST.read_bytes()==data:
            print("V08_QA_ART_CARRIER_RESTORED: already verified")
            return 0
        raise SystemExit("Refusing to overwrite a different V08 model: "+str(DEST))
    DEST.parent.mkdir(parents=True,exist_ok=True)
    temp=DEST.with_suffix(".glb.tmp")
    temp.write_bytes(data)
    temp.replace(DEST)
    print("V08_QA_ART_CARRIER_RESTORED",DEST,len(data),"bytes, 58 bones, overlay UVs")
    return 0
if __name__=="__main__":sys.exit(main())
