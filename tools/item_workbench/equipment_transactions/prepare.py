from pathlib import Path
import subprocess,re,json,hashlib
ROOT=Path('/workspace/aotl-audit');OUT=Path(__file__).parent;REF='ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b';seen={}
def copy(path):
 if path in seen:return
 b=subprocess.check_output(['git','-C',str(ROOT),'show',REF+':game/crownsfall_lootslice/'+path]);seen[path]=hashlib.sha256(b).hexdigest();dest=OUT/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(b)
 for dep in re.findall(r'preload\("res://([^\"]+)"\)',b.decode()):copy(dep)
for path in ['scripts/player.gd','scripts/save_store.gd']:copy(path)
(OUT/'source_manifest.json').write_text(json.dumps({'commit':REF,'sha256':seen},indent=2)+'\n')
(OUT/'project.godot').write_text('config_version=5\n[application]\nconfig/name="AOTL isolated equipment transactions"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
