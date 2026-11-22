from pathlib import Path
import subprocess,json,hashlib,base64
ROOT=Path('/workspace/aotl-audit');OUT=Path(__file__).parent
REF='ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b'
def raw(path):
 b=subprocess.check_output(['git','-C',str(ROOT),'show',REF+':game/crownsfall_lootslice/'+path])
 if b.startswith(b'version https://git-lfs'):
  oid=next(l.split(':',1)[1] for l in b.decode().splitlines() if l.startswith('oid sha256:'))
  b=(ROOT/'.git/lfs/objects'/oid[:2]/oid[2:4]/oid).read_bytes();assert hashlib.sha256(b).hexdigest()==oid
 return b
def uri(b,mime='image/png'):return 'data:'+mime+';base64,'+base64.b64encode(b).decode()
layout=json.loads(raw('data/inventory_ui_layout.json'));base=json.loads(raw('data/item_base_definitions.json'))
bg=uri(raw('assets/ui/inventory_backplate.jpg'),'image/jpeg')
imgs={k:uri((Path('/workspace/portrait-engine-review')/('assets/item_portraits/'+k+'.png' if k in ['amulet','staff','slippers','wraps'] else 'assets/art_expansion02/portraits/'+k+'.png')).read_bytes()) for k in base}
candidate=uri(Path('/workspace/amulet-review/candidate.png').read_bytes())
slotmap={'ring1':'ring','ring2':'ring'}
def art(k,x,y,w,h,image):
 # Runtime item_art_rect grows the supplied bounds inward by 3px.
 tw,th=base[k]['footprint'];fac=min((w-6)/tw,(h-6)/th);iw,ih=tw*fac,th*fac
 return f'<img src="{image}" style="left:{x+(w-iw)/2}px;top:{y+(h-ih)/2}px;width:{iw}px;height:{ih}px">'
def panel(new):
 s='<div class="panel" style="background-image:url('+bg+')">'
 for slot,r in layout['equipment_slots'].items():
  k=slotmap.get(slot,slot);x,y,w,h=r['x'],r['y']+142,r['width'],r['height'];im=candidate if new and k=='amulet' else imgs[k]
  s+=f'<div class="slot" style="left:{x}px;top:{y}px;width:{w}px;height:{h}px"></div>'
  s+=art(k,x+4,y+4,w-8,h-24,im)
  s+=f'<span style="left:{x}px;top:{y+h-14}px;width:{w}px">{slot.upper()}</span>'
 s+='<div class="bag"></div>'
 placements=[('weapon',0,0),('ring',2,0),('amulet',3,0),('belt',4,0),('armor',7,0),('gloves',2,2),('boots',4,2),('wand',0,4),('ring',2,5)]
 for k,col,row in placements:
  w,h=base[k]['footprint'];x,y=90+col*50,614+row*50
  s+=f'<div class="item" style="left:{x+2}px;top:{y+2}px;width:{w*50-4}px;height:{h*50-4}px"></div>'
  s+=art(k,x+2,y+2,w*50-4,h*50-4,candidate if new and k=='amulet' else imgs[k])
 return s+'</div>'
css='''body{background:#11151c;color:#eee;font:15px system-ui;margin:20px}main{display:flex;gap:24px}.panel{width:680px;height:1020px;background-size:100% 100%;position:absolute;transform-origin:top left}.panel img,.slot,.panel span,.bag,.item{position:absolute}.slot{box-sizing:border-box;background:#171a20;border:2px solid #756046;box-shadow:inset 0 0 0 3px #090c10}.panel span{font:10px sans-serif;color:#928b7e;text-align:center}.bag{left:90px;top:614px;width:500px;height:300px;background:repeating-linear-gradient(0deg,transparent 0 49px,#39332a 49px 50px),repeating-linear-gradient(90deg,#12171e 0 49px,#39332a 49px 50px)}.item{box-sizing:border-box;background:#1b2028;border:1.5px solid #86714f}.wrap{position:relative}h1{font-size:22px}'''
measure=[]
for vw,vh in [(1920,1080),(1440,900),(1280,720)]:
 scale=min(1,(vh-24)/1020,vw*.45/680)
 parts=[]
 for new,label in [(False,'Current fallback'),(True,'Memory Sigil candidate')]:parts.append(f'<section><h2>{label}</h2><div class="wrap" style="width:{680*scale}px;height:{1020*scale}px">'+panel(new).replace('class="panel"','class="panel" style-unused=""').replace('background-image:',f'transform:scale({scale});background-image:')+'</div></section>')
 page=f'<!doctype html><html lang="en"><meta charset="utf-8"><title>AOTL amulet context</title><style>{css}</style><h1>Inventory-context review · {vw}×{vh} viewport scaling</h1><p>Actual background asset and source-derived slot geometry, composed in Chromium. Illustrative equipped/bag items; not a live Godot screenshot.</p><main>'+''.join(parts)+'</main><p>Equipment amulet canvas: '+str(round(26*scale,1))+'px. Bag amulet canvas: '+str(round(40*scale,1))+'px. No production changes.</p></html>'
 (OUT/f'context_{vw}.html').write_text(page)
 measure.append({'viewport':[vw,vh],'panel_scale':scale,'equipment_amulet_canvas_px':26*scale,'bag_amulet_canvas_px':40*scale})
(OUT/'measurements.json').write_text(json.dumps({'source_commit':REF,'measurements':measure,'background_sha256':hashlib.sha256(raw('assets/ui/inventory_backplate.jpg')).hexdigest()},indent=2)+'\n')
