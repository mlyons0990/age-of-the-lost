"""Apply review-only selections to an isolated fixture, never production."""
from pathlib import Path
import json,shutil,sys,hashlib
p=Path(sys.argv[1]);review=Path(__file__).parent;staff=sys.argv[2]
assert staff in ['mystic_staff','war_staff']
assert (p/'project.godot').read_text().find('AOTL isolated portrait QA')>=0
m=json.loads((review/'manifest.json').read_text());target=p/'assets/gear_review';target.mkdir(parents=True,exist_ok=True)
for name,entry in m['candidates'].items():
 b=(review/(name+'.png')).read_bytes();assert hashlib.sha256(b).hexdigest()==entry['sha256'];(target/(name+'.png')).write_bytes(b)
f=p/'data/selected_art_profile.json';d=json.loads(f.read_text())
for key,name in {'staff':staff,'wraps':'wraps','slippers':'slippers'}.items():d['portraits'][key]='res://assets/gear_review/'+name+'.png'
f.write_text(json.dumps(d,indent=2)+'\n')
(p/'review_overlay.json').write_text(json.dumps({'status':'review_only_not_production_selection','staff_variant':staff,'note':'Gloves and boots are temporarily mapped only to test technical compatibility; not approved semantic replacements','profile_sha256':hashlib.sha256(f.read_bytes()).hexdigest()},indent=2)+'\n')
