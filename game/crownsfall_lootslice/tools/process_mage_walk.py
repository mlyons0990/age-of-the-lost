from PIL import Image
from pathlib import Path
import numpy as np, json, hashlib
ROOT=Path('/home/user/mage_sprite_export')
OUT=ROOT/'assets/mage';OUT.mkdir(parents=True,exist_ok=True)
im=Image.open('/home/user/mage_pose_sheet.png').convert('RGBA')
assert im.size==(1920,2048),im.size
directions=['up','ne','right','se','down']
cells={}
for column,direction in enumerate(directions):
 frames=[]
 for row in range(4):
  cell=im.crop((column*384,row*512,(column+1)*384,(row+1)*512))
  a=np.array(cell)
  a[:,:,3]=np.where(a[:,:,3]<24,0,np.where(a[:,:,3]>220,255,((a[:,:,3].astype(float)-24)/196*255).clip(0,255))).astype('uint8')
  frames.append(Image.fromarray(a))
 cells[direction]=frames
scale=.78
records=[]
for direction,frames in cells.items():
 grounds=[];roots=[]
 for cell in frames:
  a=np.array(cell)[:,:,3]>128
  ys,xs=np.where(a);ground=int(ys.max());grounds.append(ground)
  yy,xx=np.where(a & (np.indices(a.shape)[0]>ground-44))
  roots.append(float(xx.mean()))
 ground=float(np.median(grounds));root=float(np.mean(roots))
 strip=Image.new('RGBA',(384*4,384))
 for i,cell in enumerate(frames):
  out=Image.new('RGBA',(384,384))
  resized=cell.resize((round(384*scale),round(512*scale)),Image.Resampling.LANCZOS)
  out.alpha_composite(resized,(round(192-root*scale),round(368-ground*scale)))
  strip.paste(out,(i*384,0))
 strip.save(OUT/('walk_'+direction+'.png'))
 records.append({'direction':direction,'frame_size':[384,384],'walk_frames':4,'walk_fps':6,'source_root_x':root,'source_ground_y':ground,'scale':scale,'runtime_feet':[192,368]})
(ROOT/'data').mkdir(exist_ok=True)
(ROOT/'data/mage_sprite_manifest.json').write_text(json.dumps({'source_job':'cf22988a-2547-4030-bfe5-95b06b62a022','kind':'Four-pose painted prototype walk cycle, not a skeletal animation','directions':records},indent=2))
print('Prepared five directional four-frame walk strips')

