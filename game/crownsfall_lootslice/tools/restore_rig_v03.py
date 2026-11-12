#!/usr/bin/env python3
"""Restore the exact Higgsfield-exported 58-bone AOTL GLB; safe, checksum-verified."""
from __future__ import annotations
import base64, gzip, hashlib, pathlib, sys
HERE = pathlib.Path(__file__).resolve().parent.parent
SRC = HERE / "models/source/AOTL_Humanoid_Master_V03.glb.gz.b64"
DEST = HERE / "models/AOTL_Humanoid_Master_V03.glb"
GLB_SHA256 = "a03e14a045e53d12bf8434a9cb624fc891cceab33afb55033d3c816101ae3c38"
GZIP_SHA256 = "74123ac9bcb33259737c2b887ae7df66139c813e2889857e7c7d3c2a646d732f"
def sha(blob: bytes) -> str: return hashlib.sha256(blob).hexdigest()
def main() -> int:
    packed = base64.b64decode(SRC.read_text(encoding="ascii").strip(), validate=True)
    assert sha(packed) == GZIP_SHA256, "Corrupted source gzip payload"
    binary = gzip.decompress(packed)
    assert sha(binary) == GLB_SHA256 and binary[:4] == b"glTF", "Invalid master humanoid GLB"
    if DEST.exists() and DEST.read_bytes() == binary:
        print("RIG_V03_RESTORED verified, already matches:", DEST)
        return 0
    if DEST.exists():
        raise SystemExit("Refusing to replace a different local GLB: " + str(DEST))
    DEST.parent.mkdir(exist_ok=True, parents=True)
    temp = DEST.with_suffix(".glb.tmp")
    temp.write_bytes(binary)
    temp.replace(DEST)
    print("RIG_V03_RESTORED:", DEST, len(binary), GLB_SHA256)
    return 0
if __name__ == "__main__": sys.exit(main())
