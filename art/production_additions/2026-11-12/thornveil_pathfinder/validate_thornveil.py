#!/usr/bin/env python3
"""AOTL Thornveil Pathfinder compact equipment art static QA."""
import hashlib,json
from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parent
items=json.loads((root/"SOURCE_MANIFEST.json").read_text())["items"]
assert len(items)==8
checks=0
for item in items:
    path=root/"runtime_items"/item["indexed_name"]
    assert path.is_file(),path
    checks+=1
    assert hashlib.sha256(path.read_bytes()).hexdigest()==item["indexed_sha256"],item["name"]
    checks+=1
    im=Image.open(path).convert("RGBA")
    cols,rows=item["grid_cells"]
    assert im.size==(cols*128,rows*128),(item["name"],im.size)
    checks+=1
    a=im.getchannel("A")
    bb=a.getbbox()
    assert bb and bb[0]>0 and bb[1]>0 and bb[2]<im.width and bb[3]<im.height,(item["name"],bb)
    checks+=1
    assert a.getextrema()[0]==0 and a.getextrema()[1]>100,item["name"]
    checks+=1
    print("PASS",item["name"],im.size)
assert (root/"THORNVEIL_8_ITEM_PREVIEW.jpg").is_file()
checks+=1
print(checks,"static review-file checks passed; human and Godot tests remain pending")
