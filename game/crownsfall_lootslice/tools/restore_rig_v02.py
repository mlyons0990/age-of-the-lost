#!/usr/bin/env python3
"""Restore the exact Higgsfield-exported 58-bone AOTL GLB; safe, checksum-verified."""
from __future__ import annotations
import base64, gzip, hashlib, pathlib, sys
HERE = pathlib.Path(__file__).resolve().parent.parent
SRC = HERE / "models/source/AOTL_Humanoid_Master_V02.glb.gz.b64"
DEST = HERE / "models/AOTL_Humanoid_Master_V02.glb"
GLB_SHA256 = "ef8b288351d749e7e46fa0347c2ba658d773680735ced8d5377b93e672dcc455"
GZIP_SHA256 = "0638de285cf12a4561b1eff1e9709c32b07c92363644c1e669479770aa151596"
def sha(blob: bytes) -> str: return hashlib.sha256(blob).hexdigest()
def main() -> int:
    packed = base64.b64decode(SRC.read_text(encoding="ascii"), validate=True)
    assert sha(packed) == GZIP_SHA256, "Corrupted source gzip payload"
    binary = gzip.decompress(packed)
    assert sha(binary) == GLB_SHA256 and binary[:4] == b"glTF", "Invalid master humanoid GLB"
    if DEST.exists() and DEST.read_bytes() == binary:
        print("RIG_V02_RESTORED verified, already matches:", DEST)
        return 0
    if DEST.exists():
        raise SystemExit("Refusing to replace a different local GLB: " + str(DEST))
    DEST.parent.mkdir(exist_ok=True, parents=True)
    temp = DEST.with_suffix(".glb.tmp")
    temp.write_bytes(binary)
    temp.replace(DEST)
    print("RIG_V02_RESTORED:", DEST, len(binary), GLB_SHA256)
    return 0
if __name__ == "__main__": sys.exit(main())
