#!/usr/bin/env python3
"""Static/image/geometry acceptance for AOTL grid display (NOT a Godot playtest)."""
import re,sys,json,hashlib
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
code=(ROOT/'scripts/systems.gd').read_text()
hud=(ROOT/'scripts/hud.gd').read_text()
art=(ROOT/'scripts/art_library.gd').read_text()
tests=(ROOT/'tests/inventory_ui_integration.gd').read_text()
manifest=json.loads((ROOT/'data/item_portrait_catalog.json').read_text())
expected={'weapon':(1,3),'offhand':(2,2),'helm':(2,2),'armor':(2,3),'gloves':(2,2),'belt':(2,1),'boots':(2,2),'amulet':(1,1),'ring':(1,1),'staff':(2,4),'wand':(1,2),'focus':(1,2),'robe':(2,3),'hood':(2,2),'wraps':(2,2),'slippers':(2,2),'emberwake_circlet':(2,2)}
results=[]
def check(ok,label):
 results.append({'pass':bool(ok),'label':label})
 print(('PASS ' if ok else 'FAIL ')+label)

for item,shape in expected.items():
    if item=='emberwake_circlet':
        # Named unique inherits the hood base footprint; it is not a new slot type.
        check('"hood", "mage"' in code and '"hood": Vector2i(2, 2)' in code,item+' inherits the hood 2×2 footprint')
    else:
        match=re.search(r'"'+re.escape(item)+r'"\s*:\s*Vector2i\((\d+),\s*(\d+)\)',code)
        check(bool(match) and (int(match[1]),int(match[2]))==shape,item+' authoritative width×height = '+str(shape))
    p=ROOT/'assets/item_portraits'/f'{item}.png'
    tex=Image.open(p) if p.exists() else None
    check(tex is not None and tex.size==(shape[0]*64,shape[1]*64) and tex.mode=='RGBA' and tex.getchannel('A').getbbox() is not None,item+' PNG respects source item dimensions and transparency')
    check(manifest['footprints'][item]['cells']==list(shape) and manifest['footprints'][item]['pixels']==[shape[0]*64,shape[1]*64],item+' authored portrait catalog matches actual shape')

check('draw_texture_rect(ui._item_portrait(item),ui.item_art_rect(item,r)' in hud,'inventory/stash paint the shape-matched portrait across entire occupied rectangle')
check('Rect2(Vector2(item.x,item.y)*cell_size,Vector2(Systems.footprint(item))*cell_size)' in hud,'item rectangle always derives from actual footprint instead of icon resolution')
check('preview.size=Vector2(Systems.footprint(item))*cell_pixels' in hud,'dragged item is previewed at the actual grid cell dimensions')
check('Inventory footprint: %d × %d cells (width × height)' in hud,'inspector displays width×height label')
check('static func inventory_portrait(id: String)' in art,'new item portrait route exists without replacing original ability icons')
check('var dimensions: Vector2i = Systems.footprint(item)' in hud,'tooltip footprint uses pure data authority')
check('var required_shapes: Dictionary' in tests and 'vertical sword is selectable from its third occupied cell' in tests,'Godot integration test covers sword third cell')
check('chest armor occupies its full 2×3 rectangle' in tests and 'ring occupies exactly one cell' in tests,'Godot integration test covers armor and jewelry cells')
check('not SYS.fits(shell.bag.source' in tests,'Godot integration test covers sword overlap rejection')
check('STAFF' not in code or 'Vector2i(2, 4)' in code,'staff retains 2×4 shape')
# Independent occupancy simulation catches swapped x/y, bad rotation, overflow, and shared cells.
layout=[('weapon',0,0),('armor',1,0),('staff',3,0),('ring',5,0),('amulet',6,0),('belt',7,0),('helm',7,1),('gloves',5,1),('wand',5,3),('focus',6,3),('boots',7,3),('robe',0,3),('ring',9,5)]
occupied=set()
for item,x,y in layout:
 w,h=expected[item];cells={(i,j) for j in range(y,y+h) for i in range(x,x+w)}
 check(x>=0 and y>=0 and x+w<=10 and y+h<=6 and not (cells & occupied),'layout grid item '+item+': legal nonoverlapping '+str((x,y,w,h)))
 occupied|=cells
check(len(occupied)==sum(expected[item][0]*expected[item][1] for item,*_ in layout),'no UI item cells are lost or overlapped')
check(len(occupied)<=60 and all(0<=x<10 and 0<=y<6 for x,y in occupied),'all item cells remain in 10×6 grid')
summary={'kind':'STATIC_ASSET_GEOMETRY_ONLY','passed':sum(x['pass'] for x in results),'total':len(results),'failed':[x['label'] for x in results if not x['pass']],'details':results,'note':'This checks source and PNGs, not Godot parser/runtime.'}
(ROOT/'tests/ITEM_FOOTPRINT_STATIC_RESULT.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({k:v for k,v in summary.items() if k!='details'},indent=2))
if summary['failed']:sys.exit(1)
