#!/usr/bin/env python3
from pathlib import Path
import hashlib,json
from PIL import Image
root=Path(__file__).resolve().parent
it=json.loads((root/'SOURCE_MANIFEST.json').read_text())['items']
assert len(it)==5
asserts=0
for x in it:
 p=root/'runtime_items'/x['compact_name']
 assert p.is_file();asserts+=1
 assert hashlib.sha256(p.read_bytes()).hexdigest()==x['compact_sha256'];asserts+=1
 a=Image.open(p).convert('RGBA')
 w,h=x['grid']
 assert a.size==(w*128,h*128);asserts+=1
 al=a.getchannel('A');b=al.getbbox()
 assert b and b[0]>0 and b[1]>0 and b[2]<a.width and b[3]<a.height;asserts+=1
 assert al.getextrema()[0]==0 and al.getextrema()[1]>0;asserts+=1
 print('PASS',x['asset_id'],a.size)
print('Static checks passed:',asserts,'live Godot and human art review pending')
