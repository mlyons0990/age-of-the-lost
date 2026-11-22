from pathlib import Path
import subprocess,json,hashlib,base64,shutil
from PIL import Image
ROOT=Path('/workspace/aotl-audit');OUT=Path(__file__).parent;REF='ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b'
choices={'mystic_staff':'aotl_caster_mystic_staff_002','war_staff':'aotl_two_hand_melee_war_staff_002','wraps':'aotl_armor_cloth_cloth_gloves_002','slippers':'aotl_armor_cloth_cloth_boots_002'}
manifest={};cards=[]
for name,aid in choices.items():
 path='art/item_taxonomy/2026-11-12/runtime_items/'+aid+'.png';b=subprocess.check_output(['git','-C',str(ROOT),'show',REF+':'+path]);oid=next(l.split(':',1)[1] for l in b.decode().splitlines() if l.startswith('oid sha256:'));b=(ROOT/'.git/lfs/objects'/oid[:2]/oid[2:4]/oid).read_bytes();assert hashlib.sha256(b).hexdigest()==oid
 (OUT/(name+'.png')).write_bytes(b);im=Image.open(OUT/(name+'.png'));im.load();cells=[2,4] if 'staff' in name else [2,2];assert im.width*cells[1]==im.height*cells[0]
 manifest[name]={'asset_id':aid,'source':path,'sha256':oid,'pixels':list(im.size),'cells':cells,'alpha_bbox':im.convert('RGBA').getchannel('A').getbbox()}
for item in ['staff','wraps','slippers']:
 source=Path('/workspace/portrait-engine-review/assets/item_portraits')/(item+'.png');shutil.copyfile(source,OUT/('current_'+item+'.png'))
for name in ['current_staff','mystic_staff','war_staff','current_wraps','wraps','current_slippers','slippers']:
 b=(OUT/(name+'.png')).read_bytes();uri='data:image/png;base64,'+base64.b64encode(b).decode();wh=[2,4] if 'staff' in name else [2,2]
 cards.append('<section><h2>'+name.replace('_',' ')+'</h2><div class="samples">'+''.join(f'<div><div class="cell" style="width:{wh[0]*c}px;height:{wh[1]*c}px"><img src="{uri}" alt="{name}"></div><p>{c}px/cell</p></div>' for c in [24,34,50])+'</div></section>')
(OUT/'manifest.json').write_text(json.dumps({'source_commit':REF,'candidates':manifest},indent=2)+'\n')
(OUT/'index.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><title>AOTL Mage gear review</title><style>body{background:#141820;color:#eee;font:15px system-ui;margin:24px}main{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}section{background:#252c38;padding:16px}.samples{display:flex;gap:14px;align-items:end}h2{font-size:17px}.cell{background:#10151c;outline:1px solid #8a7555}img{width:100%;height:100%;object-fit:contain;display:block}p{font-size:12px}</style><h1>AOTL — Mage equipment candidates</h1><p>Original textures, transparent compositing, canonical footprints. Browser review, not a live game screenshot. Current paintings are shown alongside candidates; candidates are not automatically upgrades.</p><main>'+''.join(cards)+'</main></html>')
