"""Build an isolated Godot fixture from a pinned Git snapshot, never edit the game."""
import argparse,subprocess,json,hashlib,shutil
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--repo',type=Path,default=Path('.'));p.add_argument('--ref',default='HEAD');p.add_argument('--out',type=Path,required=True);a=p.parse_args()
if a.out.exists():raise SystemExit('Choose a new output directory; refuse overwrite')
def git(*args):return subprocess.check_output(['git','-C',str(a.repo),*args])
commit=git('rev-parse',a.ref+'^{commit}').decode().strip();common=Path(git('rev-parse','--git-common-dir').decode().strip())
if not common.is_absolute():common=a.repo/common
manifest={}
def raw(path):
 b=git('show',commit+':game/crownsfall_lootslice/'+path)
 if b.startswith(b'version https://git-lfs'):
  oid=next(l.split(':',1)[1] for l in b.decode().splitlines() if l.startswith('oid sha256:'))
  b=(common/'lfs'/'objects'/oid[:2]/oid[2:4]/oid).read_bytes()
  assert hashlib.sha256(b).hexdigest()==oid
 manifest[path]=hashlib.sha256(b).hexdigest();return b
base=json.loads(raw('data/item_base_definitions.json'));profile=json.loads(raw('data/selected_art_profile.json'))
paths=['data/item_base_definitions.json','data/selected_art_profile.json','scripts/art_library.gd']
paths += [profile['portraits'].get(k,'res://assets/item_portraits/'+k+'.png').removeprefix('res://') for k in base]
for path in paths:
 dest=a.out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(raw(path))
(a.out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="AOTL isolated portrait QA"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
shutil.copyfile(Path(__file__).with_name('engine_review.gd'),a.out/'engine_review.gd')
(a.out/'source_manifest.json').write_text(json.dumps({'commit':commit,'sha256':manifest,'note':'Exact runtime resolver and source bytes; no production project mutation'},indent=2)+'\n')
print(a.out)
