"""Read-only, commit-pinned inventory audit. Python standard library only."""
import argparse,base64,csv,hashlib,html,json,struct,subprocess
from pathlib import Path
GAME='game/crownsfall_lootslice/'
def pairs(items):
 d={}
 for k,v in items:
  if k in d: raise ValueError('Duplicate JSON key: '+k)
  d[k]=v
 return d
def footprint(v):
 return isinstance(v,list) and len(v)==2 and all(type(n)==int and 0<n<=10 for n in v) and v[1]<=6
def validate(base,profile):
 issues=[]
 for key,item in base.items():
  cells=item.get('footprint')
  if not footprint(cells):issues.append((key,'error','Invalid footprint'))
  expected={'ring':[1,1],'amulet':[1,1],'weapon':[1,3]}.get(key)
  if expected and cells!=expected:issues.append((key,'error','Owner canonical footprint mismatch'))
  if not item.get('equipment_destination'):issues.append((key,'error','Missing equipment destination'))
 for row in profile.get('selections',[]):
  if row.get('kind')!='equipment':continue
  key=row['game_id']
  if key not in base:issues.append((key,'error','Selection has no base definition'))
  elif row['cells']!=base[key]['footprint']:issues.append((key,'error','Selected artwork cells disagree with base'))
 ids=[r['asset_id'] for r in profile.get('selections',[])]
 if len(ids)!=len(set(ids)):issues.append(('*','error','Duplicate selected asset IDs'))
 return issues

def run(repo,ref,out):
 def git(*args):return subprocess.check_output(['git','-C',str(repo),*args])
 commit=git('rev-parse',ref+'^{commit}').decode().strip()
 def read(path):return git('show',commit+':'+path)
 sources={}
 def data(path):
  raw=read(path);sources[path]=hashlib.sha256(raw).hexdigest()
  return json.loads(raw,object_pairs_hook=pairs)
 base=data(GAME+'data/item_base_definitions.json')
 profile=data(GAME+'data/selected_art_profile.json')
 issues=validate(base,profile);rows=[];cards=[]
 paths=set(git('ls-tree','-r','--name-only',commit).decode().splitlines())
 for key,item in base.items():
  cells=item['footprint'];art=profile.get('portraits',{}).get(key);uri='';pixels=None
  if not art and GAME+'assets/item_portraits/'+key+'.png' in paths:
   art='res://assets/item_portraits/'+key+'.png'
  status='No explicit selected portrait; fallback requires runtime review'
  if art:
   path=GAME+art.removeprefix('res://')
   if path not in paths:
    status='Missing tracked art';issues.append((key,'error',status))
   else:
    blob=read(path)
    if blob.startswith(b'version https://git-lfs.github.com/spec/v1'):
     oid=next((line.split(':',1)[1] for line in blob.decode().splitlines() if line.startswith('oid sha256:')), '')
     common=Path(git('rev-parse','--git-common-dir').decode().strip())
     if not common.is_absolute():common=repo/common
     local=common/'lfs'/'objects'/oid[:2]/oid[2:4]/oid
     if local.is_file():
      candidate=local.read_bytes()
      if hashlib.sha256(candidate).hexdigest()==oid:blob=candidate
    if blob.startswith(b'version https://git-lfs.github.com/spec/v1'):
     status='LFS pointer: pixels not verified'
     issues.append((key,'unverified',status))
    elif blob.startswith(b'\x89PNG\r\n\x1a\n') and len(blob)>=24:
     pixels=list(struct.unpack('>II',blob[16:24]));status='PNG dimensions verified'
     if footprint(cells) and pixels[0]*cells[1]!=pixels[1]*cells[0]:issues.append((key,'error','PNG canvas aspect differs from footprint'))
     uri='data:image/png;base64,'+base64.b64encode(blob).decode()
    else:issues.append((key,'unverified','Unsupported image bytes'))
  else:issues.append((key,'gap',status))
  rows.append(dict(id=key,name=item['name'],cells=cells,slot=item['equipment_destination'],art=art,status=status,pixels=pixels,equipped_visual='Not audited; inventory portrait is not wearable geometry'))
  w,h=cells if footprint(cells) else (1,1)
  content='<img alt="'+html.escape(item['name'],quote=True)+'" src="'+uri+'">' if uri else '<span>Artwork<br>unverified</span>'
  cards.append('<article><h2>'+html.escape(item['name'])+'</h2><p>'+html.escape(key)+' · '+str(w)+'×'+str(h)+' · '+html.escape(item['equipment_destination'])+'</p><div class="grid" style="width:'+str(w*48)+'px;height:'+str(h*48)+'px">'+content+'</div><p>'+html.escape(status)+'</p></article>')
 report=dict(commit=commit,source_sha256=sources,items=rows,issues=[dict(id=i,severity=s,message=m) for i,s,m in issues],limits=['Read-only exported data audit, not live Godot verification','Tracked item-portrait fallback recognized; actual ResourceLoader success not verified','No equipped mesh mappings inferred','LFS pointer files are unverified, not missing artwork','Only main snapshot audited; other developer branches untouched'])
 out.mkdir(parents=True,exist_ok=True)
 (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
 with (out/'exceptions.csv').open('w',newline='') as f:
  writer=csv.writer(f);writer.writerow(['item','classification','finding']);writer.writerows(issues)
 page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>AOTL item workbench</title><style>body{background:#151820;color:#eee;font:16px system-ui;margin:30px}input{padding:12px;width:280px}main{display:flex;flex-wrap:wrap;gap:20px}article{background:#252a34;padding:20px;width:250px}h2{font-size:18px}.grid{position:relative;background:repeating-linear-gradient(0deg,transparent 0 47px,#aaa 47px 48px),repeating-linear-gradient(90deg,transparent 0 47px,#aaa 47px 48px);border:1px solid #aaa}.grid img{width:100%;height:100%;object-fit:contain}.grid span{font-size:11px}p{overflow-wrap:anywhere}</style><h1>AOTL item workbench</h1><p>48 pixels per cell. Shape preview; no drag/drop simulation. Unverified artwork is labeled explicitly.</p>'''
 page+='<p>Source commit: '+commit+'</p><label>Filter items <input id="filter" placeholder="Name, type or slot"></label><main>'+''.join(cards)+'</main><script>document.querySelector("#filter").addEventListener("input",e=>{for(const c of document.querySelectorAll("article"))c.hidden=!c.textContent.toLowerCase().includes(e.target.value.toLowerCase())})</script></html>'
 (out/'index.html').write_text(page)
 print(json.dumps({'commit':commit,'items':len(rows),'errors':sum(s=='error' for _,s,_ in issues),'gaps':sum(s=='gap' for _,s,_ in issues),'unverified':sum(s=='unverified' for _,s,_ in issues)}))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--repo',type=Path,default=Path('.'));p.add_argument('--ref',default='HEAD');p.add_argument('--out',type=Path,required=True);a=p.parse_args();run(a.repo,a.ref,a.out)
