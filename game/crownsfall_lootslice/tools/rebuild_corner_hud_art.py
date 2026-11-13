"""Mechanical preparation of reviewed Higgsfield originals; no generated repaint.
Run from the repository checkout. --output can target a disposable verification tree.
"""
from pathlib import Path
import argparse,hashlib,json
from PIL import Image, __version__ as pillow_version
repo=Path(__file__).resolve().parents[3]
source=repo/'art/ui_camera/2026-11-12'
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output',type=Path,default=repo/'game/crownsfall_lootslice/assets')
args=parser.parse_args();out=args.output.resolve();hud=out/'ui/corner_hud';hud.mkdir(parents=True,exist_ok=True)
frames=Image.open(source/'guardian_orb_frames_source.png').convert('RGBA')
assert frames.size==(2688,1520)
for side,box in [('life',(0,0,1344,1520)),('mana',(1344,0,2688,1520))]:
 frames.crop(box).resize((672,760),Image.Resampling.LANCZOS).save(hud/(side+'_frame.png'))
Image.open(source/'health_flask_source.png').convert('RGBA').resize((256,256),Image.Resampling.LANCZOS).save(hud/'health_flask.png')
Image.open(source/'plaza_seam_repaired_source.png').convert('RGB').save(out/'plaza_extension.jpg',quality=94,subsampling=0)
print(json.dumps({'pillow':pillow_version,'output':str(out),'files':{str(p.relative_to(out)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [hud/'life_frame.png',hud/'mana_frame.png',hud/'health_flask.png',out/'plaza_extension.jpg']}},indent=2))
