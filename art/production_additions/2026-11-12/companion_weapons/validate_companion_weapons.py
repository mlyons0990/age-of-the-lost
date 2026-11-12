#!/usr/bin/env python3
from pathlib import Path
from PIL import Image
import hashlib,json
root=Path(__file__).resolve().parent
items=json.loads((root/'SOURCE_MANIFEST.json').read_text())['items']
assert len(items)==2
checks=0
for it in items:
 p=root/'runtime_items'/it['compact']
 assert p.is_file();checks+=1
 assert hashlib.sha256(p.read_bytes()).hexdigest()==it['compact_sha256'];checks+=1
 a=Image.open(p).convert('RGBA')
 w,h=it['grid']
 assert a.size==(w*128,h*128);checks+=1
 alpha=a.getchannel('A');bb=alpha.getbbox()
 assert bb and bb[0]>0 and bb[1]>0 and bb[2]<a.width and bb[3]<a.height;checks+=1
 assert alpha.getextrema()[0]==0 and alpha.getextrema()[1]>0;checks+=1
 print('PASS',it['name'],a.size,bb)
print(checks,'static compact checks passed; original-source QA and human/Godot review still pending')
