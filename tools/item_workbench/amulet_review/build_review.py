from pathlib import Path
import base64,json,hashlib
from PIL import Image
p=Path(__file__).parent
records=[];cards=[]
for name in ['current','candidate']:
 b=(p/(name+'.png')).read_bytes();im=Image.open(p/(name+'.png')).convert('RGBA');a=im.getchannel('A');values=list(a.getdata());box=a.getbbox();w,h=im.size
 records.append({'name':name,'sha256':hashlib.sha256(b).hexdigest(),'pixels':[w,h],'alpha_bbox':box,'nonzero_alpha_fraction':sum(v>0 for v in values)/len(values),'opaque_fraction':sum(v==255 for v in values)/len(values),'transparent_border':all(a.getpixel((x,y))==0 for x in range(w) for y in [0,h-1]) and all(a.getpixel((x,y))==0 for y in range(h) for x in [0,w-1])})
 uri='data:image/png;base64,'+base64.b64encode(b).decode()
 for bg in ['dark','light','checker']:
  cards.append('<section><h2>'+name+' · '+bg+'</h2><div class="samples">'+''.join('<div><div class="cell '+bg+'" style="width:'+str(s)+'px;height:'+str(s)+'px"><img src="'+uri+'" width="'+str(s)+'" height="'+str(s)+'" alt="'+name+' amulet"></div><p>'+str(s)+' px</p></div>' for s in [32,48,64,96])+'</div></section>')
(p/'metrics.json').write_text(json.dumps(records,indent=2)+'\n')
(p/'index.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><title>AOTL amulet comparison</title><style>body{font:16px system-ui;background:#161b24;color:#eee;margin:30px}main{display:grid;grid-template-columns:1fr 1fr;gap:20px}section{background:#252d3c;padding:20px}.samples{display:flex;gap:22px;align-items:end}.cell{outline:1px solid #8795a8}.dark{background:#17191f}.light{background:#dfd9cb}.checker{background:repeating-conic-gradient(#777 0% 25%,#bbb 0% 50%) 50% / 12px 12px}img{display:block}h2{font-size:18px}</style><h1>AOTL — amulet artwork review</h1><p>Existing runtime fallback versus existing Wayfarer Memory Sigil candidate. Both occupy one inventory cell. Candidate is not enabled.</p><main>'+''.join(cards)+'</main><p>Original PNG bytes preserved. Browser scaling only; no repainting or generation. No live-game UI approval implied.</p></html>')
