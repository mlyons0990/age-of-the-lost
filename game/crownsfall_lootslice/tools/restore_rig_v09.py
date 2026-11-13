#!/usr/bin/env python3
"""Restore exactly the Higgsfield V09 revision-24 GLB from checksum-verified source parts."""
from __future__ import annotations
import base64,gzip,hashlib,json,pathlib,struct
ROOT=pathlib.Path(__file__).resolve().parent.parent
PFX=ROOT/"models/source/AOTL_Humanoid_Master_V09.glb.gz.b64"
PARTS=[pathlib.Path(f"{PFX}.part{i:02d}") for i in range(22)]
OUT=ROOT/"models/AOTL_Humanoid_Master_V09.glb"
COMPRESSED_SHA="eabe1f376b827ddc762c417987a91b306dc75aedc5f253725c94cd316ae88d21"
UNCOMPRESSED_SHA="9ca742a3e8e91e07165587371723f58f77d47d27408647068eff80f559d83b63"
def h(data:bytes)->str:return hashlib.sha256(data).hexdigest()
def main()->None:
    assert all(p.exists() for p in PARTS),"Missing V09 compressed source part"
    packed=b"".join(base64.b64decode(p.read_text(encoding="ascii").strip(),validate=True) for p in PARTS)
    assert len(packed)==4197374 and h(packed)==COMPRESSED_SHA,"Compressed V09 asset checksum mismatch"
    glb=gzip.decompress(packed)
    assert len(glb)==6964528 and h(glb)==UNCOMPRESSED_SHA,"Uncompressed V09 GLB checksum mismatch"
    assert glb[:4]==b"glTF" and struct.unpack_from("<I",glb,8)[0]==len(glb)
    n=struct.unpack_from("<I",glb,12)[0]
    doc=json.loads(glb[20:20+n])
    assert len(doc["skins"][0]["joints"])==58,"58-joint source rig missing"
    assert len(doc["animations"])==1,"Original V06 animation reel missing"
    names={i.get("name") for i in doc.get("images",[])}
    assert {"V08_BODY_PaintPlaceholder_2K","V08_GEAR_PaintPlaceholder_2K"}.issubset(names),"2K art-carrier atlases missing"
    if OUT.exists():
        if h(OUT.read_bytes())==UNCOMPRESSED_SHA:
            print("AOTL_V09_RESTORE_OK: already verified",OUT)
            return
        raise RuntimeError("Refusing to overwrite a different model: "+str(OUT))
    OUT.parent.mkdir(parents=True,exist_ok=True)
    tmp=OUT.with_suffix(".glb.tmp")
    tmp.write_bytes(glb)
    tmp.replace(OUT)
    print("AOTL_V09_RESTORE_OK:",OUT,"58 bones, original reel, both 2K UV paint atlases")
if __name__=="__main__":main()
