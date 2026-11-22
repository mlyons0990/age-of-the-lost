"""Read-only catalog and production-contract audit; no runtime selections changed."""
import argparse,csv,hashlib,json,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--repo',type=Path,required=True);p.add_argument('--ref',default='HEAD');p.add_argument('--out',type=Path,required=True);a=p.parse_args()
def git(*args):return subprocess.check_output(['git','-C',str(a.repo),*args])
commit=git('rev-parse',a.ref+'^{commit}').decode().strip();lib='art/item_taxonomy/2026-11-12/';raw=git('show',commit+':'+lib+'catalog.json');catalog=json.loads(raw);paths=set(git('ls-tree','-r','--name-only',commit).decode().splitlines());seen=set();rows=[];issues=[]
for e in catalog['entries']:
 aid=e.get('asset_id');cells=e.get('cells');texture=e.get('texture_path');tracked=bool(texture and lib+texture in paths)
 if aid in seen:issues.append({'asset':aid,'finding':'duplicate ID'})
 seen.add(aid)
 if not isinstance(cells,list) or len(cells)!=2 or any(type(x)!=int or x<1 for x in cells):issues.append({'asset':aid,'finding':'invalid dimensions'})
 status=e.get('status','unknown')
 if not tracked:issues.append({'asset':aid,'finding':'no tracked runtime texture','catalog_status':status})
 rows.append({'asset_id':aid,'name':e.get('name'),'type':e.get('type'),'group':e.get('group'),'cells':str(cells),'status':status,'runtime_enabled':e.get('runtime_enabled',False),'texture_path':lib+texture if texture else '', 'texture_tracked':tracked,'inventory_art':'candidate available' if tracked else 'not available at catalog path','ground_drop':'unverified: separate asset/representation required','equipped_visual':'unverified: separate mesh/layer and attachment required','character_sheet':'unverified: integration and scale review required','source_sha256':e.get('production',{}).get('texture_sha256','')})
a.out.mkdir(parents=True,exist_ok=True)
with (a.out/'equipment_readiness.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
summary={'commit':commit,'catalog_sha256':hashlib.sha256(raw).hexdigest(),'entries':len(rows),'unique_ids':len(seen),'tracked_textures':sum(r['texture_tracked'] for r in rows),'runtime_enabled_in_catalog':sum(bool(r['runtime_enabled']) for r in rows),'issues':issues,'limits':['Catalog availability is not art approval','No inference that ground/equipped assets are absent from other branches','Does not promote candidates or change saves']}
(a.out/'art_readiness.json').write_text(json.dumps(summary,indent=2)+'\n')
# Explicit semantic proposals, not a name-based automatic mapper.
mapping={'amulet':['amulet'],'staff':['mystic_staff','war_staff'],'wraps':['cloth_gloves'],'slippers':['cloth_boots']};bases=json.loads(git('show',commit+':game/crownsfall_lootslice/data/item_base_definitions.json'));proposals=[]
for key,types in mapping.items():
 for e in catalog['entries']:
  if e.get('type') in types:
   assert e['cells']==bases[key]['footprint']
   proposals.append({'game_id':key,'asset_id':e['asset_id'],'cells':e['cells'],'source':lib+e['texture_path'],'source_sha256':e.get('production',{}).get('texture_sha256'),'status':'proposal_not_applied','review_needed':'actual inventory appearance and imported pixel checks; select exactly one staff candidate','equipment_destination':bases[key]['equipment_destination'],'retain_fallback':'res://assets/item_portraits/'+key+'.png','provenance_required':True,'stats_or_save_changes':False})
(a.out/'portrait_integration_contracts.json').write_text(json.dumps({'source_commit':commit,'proposals':proposals,'excluded':'1x4 quarterstaff is incompatible with the 2x4 staff footprint'},indent=2)+'\n')
print(json.dumps(summary,indent=2))
