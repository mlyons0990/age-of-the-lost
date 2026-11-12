#!/usr/bin/env python3
"""AOTL eight forged-weapon review PNG static size, alpha and hash checks."""
from pathlib import Path
from PIL import Image
import json,hashlib

root=Path(__file__).resolve().parent
items=json.loads((root/'SOURCE_MANIFEST.json').read_text())['items']
assert len(items)==8
checks=0
for it in items:
    f=root/'runtime_items'/it['compact_file']
    assert f.is_file(),it['compact_file'];checks+=1
    assert hashlib.sha256(f.read_bytes()).hexdigest()==it['compact_sha256'],it['display_name'];checks+=1
    im=Image.open(f).convert('RGBA')
    w,h=it['grid_cells']
    assert im.size==(w*128,h*128), (it['display_name'],im.size);checks+=1
    alpha=im.getchannel('A');bbox=alpha.getbbox()
    assert bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<im.width and bbox[3]<im.height,it['display_name'];checks+=1
    assert alpha.getextrema()[0]==0 and alpha.getextrema()[1]>0,it['display_name'];checks+=1
    print('PASS',it['display_name'],im.size,bbox)
for n in ['AOTL_FORGED_EIGHT_CONTACT.jpg','AOTL_FORGED_EIGHT_64PX_SCALE.jpg']:
    assert (root/n).exists(),n;checks+=1
print('Checks:',checks,'passed; Godot runtime and 32px visuals still require review')
