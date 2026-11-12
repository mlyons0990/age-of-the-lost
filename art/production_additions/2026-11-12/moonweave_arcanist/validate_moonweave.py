#!/usr/bin/env python3
from pathlib import Path
from PIL import Image
import hashlib,json
root=Path(__file__).resolve().parent
items=json.loads((root/'SOURCE_MANIFEST.json').read_text())['items']
assert len(items)==5
checks=0
for it in items:
 p=root/'runtime_items'/it['compact_name']
 assert p.is_file();checks+=1
 assert hashlib.sha256(p.read_bytes()).hexdigest()==it['compact_sha256'];checks+=1
 im=Image.open(p).convert('RGBA')
 w,h=it['grid']
 assert im.size==(w*128,h*128);checks+=1
 a=im.getchannel('A')
 bb=a.getbbox()
 assert bb and bb[0]>0 and bb[1]>0 and bb[2]<im.width and bb[3]<im.height;checks+=1
 assert a.getextrema()[0]==0 and a.getextrema()[1]>0;checks+=1
 print('PASS',it['asset_id'],im.size,bb)
print(checks,'static checks passed; Godot runtime QA pending')
