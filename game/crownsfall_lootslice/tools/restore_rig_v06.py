#!/usr/bin/env python3
"""Restore the exact Higgsfield-exported 58-bone AOTL GLB; safe, checksum-verified."""
from __future__ import annotations
import base64, gzip, hashlib, pathlib, sys
HERE = pathlib.Path(__file__).resolve().parent.parent
SRC = HERE / "models/source/AOTL_Humanoid_Master_V06.glb.gz.b64"
DEST = HERE / "models/AOTL_Humanoid_Master_V06.glb"
GLB_SHA256 = "ba7725cd0f6a2891f0553e0ba8688b515a19932715cc961872132ff5a75284bb"
GZIP_SHA256 = "ea4124d6c47de246adb3ae0d02e1bf075ffe8e241b5ae9dfc4e5fd90dda75657"
def sha(blob: bytes) -> str: return hashlib.sha256(blob).hexdigest()
def main() -> int:
    packed = base64.b64decode(SRC.read_text(encoding="ascii").strip(), validate=True)
    assert sha(packed) == GZIP_SHA256, "Corrupted source gzip payload"
    binary = gzip.decompress(packed)
    assert sha(binary) == GLB_SHA256 and binary[:4] == b"glTF", "Invalid master humanoid GLB"
    if DEST.exists() and DEST.read_bytes() == binary:
        print("RIG_V06_RESTORED verified, already matches:", DEST)
        return 0
    if DEST.exists():
        raise SystemExit("Refusing to replace a different local GLB: " + str(DEST))
    DEST.parent.mkdir(exist_ok=True, parents=True)
    temp = DEST.with_suffix(".glb.tmp")
    temp.write_bytes(binary)
    temp.replace(DEST)
    print("RIG_V06_RESTORED:", DEST, len(binary), GLB_SHA256)
    return 0
if __name__ == "__main__": sys.exit(main())
