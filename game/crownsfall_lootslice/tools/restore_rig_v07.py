#!/usr/bin/env python3
"""Reconstruct the exact Higgsfield V07 skinned/painted GLB from five lossless source parts."""
from __future__ import annotations
import base64
import gzip
import hashlib
import json
import pathlib
import struct
import sys

HERE = pathlib.Path(__file__).resolve().parent.parent
PREFIX = HERE / "models/source/AOTL_Humanoid_Master_V07.glb.gz.b64"
PARTS = [pathlib.Path(str(PREFIX) + f".part{i:02d}") for i in range(5)]
DEST = HERE / "models/AOTL_Humanoid_Master_V07.glb"
GLB_SHA256 = "a3bd395ea0fb01d3465cc18a31ed4c7ee7ce850359d3658ddae74168172a1425"
GZIP_SHA256 = "31a21c6702b240eca92fc9f6c9891d121b724b00443a768c156d5320e38fc252"

def digest(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()

def main() -> int:
    assert all(p.is_file() for p in PARTS), "Missing V07 source part(s)"
    packed = b"".join(base64.b64decode(p.read_text(encoding="ascii").strip(), validate=True) for p in PARTS)
    assert len(packed) == 441780 and digest(packed) == GZIP_SHA256, "V07 source checksum mismatch"
    binary = gzip.decompress(packed)
    assert binary[:4] == b"glTF" and digest(binary) == GLB_SHA256, "V07 GLB checksum mismatch"
    json_len = struct.unpack_from("<I", binary, 12)[0]
    doc = json.loads(binary[20:20 + json_len])
    assert len(doc.get("skins", [])) >= 1 and len(doc["skins"][0]["joints"]) == 58, "Rig is not 58-joint"
    assert len(doc.get("images", [])) >= 12 and len(doc.get("textures", [])) >= 12, "Missing packed painterly textures"
    assert len([m for m in doc["materials"] if m["name"].startswith("V07_")]) >= 12, "Missing painted variants"
    assert len(doc["animations"]) == 1, "Unexpected reel count"
    if DEST.exists():
        if DEST.read_bytes() == binary:
            print("RIG_V07_RESTORED: already verified", DEST)
            return 0
        raise SystemExit("Refusing to overwrite a different V07 model at " + str(DEST))
    DEST.parent.mkdir(parents=True, exist_ok=True)
    temp = DEST.with_suffix(".glb.tmp")
    temp.write_bytes(binary)
    temp.replace(DEST)
    print("RIG_V07_RESTORED:", DEST, len(binary), "bytes, 58 bones, 12 packed image textures")
    return 0

if __name__ == "__main__":
    sys.exit(main())
