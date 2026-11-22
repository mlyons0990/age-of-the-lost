"""Static reconciliation; never enables candidate artwork or claims engine import success."""
import argparse,hashlib,json,subprocess
from pathlib import Path
GAME='game/crownsfall_lootslice/'
LIB='art/item_taxonomy/2026-11-12/'
CANDIDATE_TYPES={'amulet':['amulet'],'staff':['mystic_staff','war_staff','quarterstaff'],'wraps':['cloth_gloves'],'slippers':['cloth_boots']}
def routes(key,profile):
 return [p for p in [profile.get('portraits',{}).get(key),f'res://assets/item_portraits/{key}.png',profile.get('icons',{}).get(key),f'res://assets/painted_icons/{key}.png',f'res://assets/icons/{key}.svg','res://assets/icons/amulet.svg'] if p]
def reconcile(base,profile,entries,paths):
 rows=[]
 for key,types in CANDIDATE_TYPES.items():
  choices=routes(key,profile);existing=[p for p in choices if GAME+p.removeprefix('res://') in paths]
  candidates=[]
  for e in entries:
   if e.get('type') in types:
    candidates.append({'asset_id':e['asset_id'],'cells':e['cells'],'footprint_matches':e['cells']==base[key]['footprint'],'status':e.get('status'),'runtime_enabled':e.get('runtime_enabled'), 'tracked_texture':LIB+e.get('texture_path','') in paths,'selection':'proposal_only'})
  rows.append({'item':key,'cells':base[key]['footprint'],'route_order':choices,'first_tracked_route':existing[0] if existing else None,'finding':'fallback_tracked_not_missing' if existing else 'no_tracked_fallback','candidates':candidates,'engine_load_verified':False,'equipped_mesh_verified':False})
 return rows
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--repo',type=Path,default=Path('.'));p.add_argument('--ref',default='HEAD');p.add_argument('--out',type=Path,required=True);a=p.parse_args()
 def git(*args):return subprocess.check_output(['git','-C',str(a.repo),*args])
 commit=git('rev-parse',a.ref+'^{commit}').decode().strip();sources={}
 def read(path):
  raw=git('show',commit+':'+path);sources[path]=hashlib.sha256(raw).hexdigest();return raw
 base=json.loads(read(GAME+'data/item_base_definitions.json'));profile=json.loads(read(GAME+'data/selected_art_profile.json'));catalog=json.loads(read(LIB+'catalog.json'))
 route=read(GAME+'scripts/art_library.gd').decode()
 # Fail rather than silently extrapolate when the inspected implementation changes.
 expected=Path(__file__).with_name('routing_source.sha256').read_text().strip()
 if hashlib.sha256(route.encode()).hexdigest()!=expected:raise SystemExit('Art routing changed: review resolver before reconciliation')
 paths=set(git('ls-tree','-r','--name-only',commit).decode().splitlines())
 result={'commit':commit,'source_sha256':sources,'candidate_library_entries':len(catalog['entries']),'rows':reconcile(base,profile,catalog['entries'],paths),'limits':['Tracked route is not a successful Godot ResourceLoader check','Candidates are suggestions, not approved replacements','No textures or gameplay changed']}
 a.out.mkdir(parents=True,exist_ok=True);(a.out/'reconciliation.json').write_text(json.dumps(result,indent=2)+'\n')
 lines=['# Inventory artwork reconciliation','',f'Snapshot: {commit}', '', 'All four previously unresolved selected-profile mappings have tracked item-portrait fallbacks. They are not confirmed missing-art defects. Engine import and pixel validation remain open.','']
 for r in result['rows']:
  lines += ['## '+r['item'], '', 'Fallback: `'+str(r['first_tracked_route'])+'`', '']
  for c in r['candidates']:lines.append('- '+c['asset_id']+': '+str(c['cells'])+'; '+('matching footprint, selection review required' if c['footprint_matches'] else 'REJECT direct substitution: footprint mismatch'))
  lines+=['']
 lines+=['## Next production work','','Validate fallback image bytes and actual engine imports; review matching candidates at gameplay size; retain source provenance and approved status; implement any approved mapping in a separate integration change. Staff quarterstaff art is 1x4 and is not a direct replacement for the current 2x4 staff. Inventory art provides no evidence of a wearable 3D model.']
 (a.out/'RECONCILIATION.md').write_text('\n'.join(lines)+'\n');print(json.dumps({'rows':len(result['rows']),'library_entries':len(catalog['entries']),'tracked_fallbacks':sum(bool(r['first_tracked_route']) for r in result['rows'])}))
