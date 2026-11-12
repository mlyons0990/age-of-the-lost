#!/usr/bin/env python3
"""Static dimension and transparency checks for Chronicle Guard GitHub art previews."""
from pathlib import Path
from PIL import Image
import json, hashlib

ROOT = Path(__file__).resolve().parent
data = json.loads((ROOT / "SOURCE_MANIFEST.json").read_text())
assert len(data["items"]) == 5, len(data["items"])
for item in data["items"]:
    n = item["name"]
    w,h = item["grid_cells"]
    path = ROOT / "runtime_items" / item["compact_file"]
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    assert actual == item["compact_sha256"], (n, "hash", actual)
    im = Image.open(path).convert("RGBA")
    assert im.size == (w*128,h*128), (n, im.size)
    alpha = im.getchannel("A")
    bbox = alpha.getbbox()
    assert bbox and bbox[0] > 0 and bbox[1] > 0 and bbox[2] < im.width and bbox[3] < im.height, (n,bbox)
    lo,hi = alpha.getextrema()
    assert lo == 0 and hi > 50, (n,lo,hi)
    print("PASS",n,im.size,bbox)
print("Static preview checks passed; human and Godot review still required.")
