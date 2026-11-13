#!/usr/bin/env python3
"""Losslessly swap two packed PNG textures in exported Higgsfield V08 rigged GLB.

Other mesh/skin/animation data are preserved. Uses standard-library only.
Run: python tools/v08_inject_art_into_glb.py V08.glb --body BODY.png --gear GEAR.png --output V08_Painted.glb
"""
from __future__ import annotations
import argparse, hashlib, json, pathlib, struct
PNG=b"\x89PNG\r\n\x1a\n"
J=0x4E4F534A
B=0x004E4942

def pad(b:bytes,byte:bytes=b"\0")->bytes:
    return b+byte*((-len(b))%4)

def unpack(glb:bytes):
    assert glb[:4]==b"glTF" and struct.unpack_from("<I",glb,4)[0]==2
    assert struct.unpack_from("<I",glb,8)[0]==len(glb)
    chunks=[];p=12
    while p<len(glb):
        n,k=struct.unpack_from("<II",glb,p);p+=8
        chunks.append((k,glb[p:p+n]));p+=n
    assert p==len(glb) and len(chunks)==2 and chunks[0][0]==J and chunks[1][0]==B
    return json.loads(chunks[0][1].rstrip(b" \0")),chunks[1][1]

def replace(glb:bytes,body:bytes,gear:bytes)->bytes:
    d,bin=unpack(glb)
    assert len(d.get("skins",[])) and len(d["skins"][0]["joints"])==58
    assert len(d.get("animations",[]))>=1
    original=bin
    locked={k:json.dumps(d.get(k,[]),sort_keys=True) for k in ("skins","animations","meshes","nodes")}
    for name,png in (("V08_BODY_PaintPlaceholder_2K",body),("V08_GEAR_PaintPlaceholder_2K",gear)):
        assert png.startswith(PNG),name+" is not a PNG"
        matches=[image for image in d["images"] if image.get("name")==name]
        assert len(matches)==1,"Expected one GLB image "+name
        img=matches[0]
        assert img["mimeType"]=="image/png"
        d["bufferViews"].append({"buffer":0,"byteOffset":len(bin),"byteLength":len(png)})
        img["bufferView"]=len(d["bufferViews"])-1
        bin+=pad(png)
    assert bin.startswith(original)
    d["buffers"][0]["byteLength"]=len(bin)
    assert all(json.dumps(d.get(k,[]),sort_keys=True)==v for k,v in locked.items())
    encoded=pad(json.dumps(d,separators=(",",":"),ensure_ascii=False).encode(),b" ")
    size=12+8+len(encoded)+8+len(bin)
    data=struct.pack("<4sII",b"glTF",2,size)+struct.pack("<II",len(encoded),J)+encoded+struct.pack("<II",len(bin),B)+bin
    verify,_=unpack(data)
    assert verify["buffers"][0]["byteLength"]==len(bin)
    return data

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("input_glb",type=pathlib.Path)
    p.add_argument("--body",required=True,type=pathlib.Path)
    p.add_argument("--gear",required=True,type=pathlib.Path)
    p.add_argument("--output",required=True,type=pathlib.Path)
    a=p.parse_args()
    data=replace(a.input_glb.read_bytes(),a.body.read_bytes(),a.gear.read_bytes())
    a.output.write_bytes(data)
    print("AOTL_V08_TEXTURE_SWAP_OK",len(data),"bytes; 58 bones retained; SHA256:",hashlib.sha256(data).hexdigest())

if __name__=="__main__":main()
