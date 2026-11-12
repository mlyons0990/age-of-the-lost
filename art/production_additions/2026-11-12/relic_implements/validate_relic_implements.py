#!/usr/bin/env python3
"""Static integrity checks for AOTL Phase A relic and jewelry art previews."""
from pathlib import Path
from PIL import Image
import hashlib, json
root=Path(__file__).resolve().parent
items=json.loads((root/'SOURCE_MANIFEST.json').read_text())['items']
assert len(items)==8
checks=0
for item in items:
    p=root/'runtime_items'/item['compact_file']
    assert p.is_file(),str(p); checks+=1
    assert hashlib.sha256(p.read_bytes()).hexdigest()==item['compact_sha256'],item['name'];checks+=1
    im=Image.open(p).convert('RGBA')
    w,h=item['grid_cells']
    assert im.size==(w*128,h*128),(item['name'],im.size);checks+=1
    alpha=im.getchannel('A')
    bbox=alpha.getbbox()
    assert bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<im.width and bbox[3]<im.height,item['name'];checks+=1
    assert alpha.getextrema()[0]==0 and alpha.getextrema()[1]>0,item['name'];checks+=1
    print('PASS',item['name'],im.size,bbox)
assert (root/'AOTL_RELIC_8_ITEM_CONTACT_SHEET.jpg').is_file();checks+=1
print(checks,'static review-branch assertions passed. Godot runtime QA still pending.')
