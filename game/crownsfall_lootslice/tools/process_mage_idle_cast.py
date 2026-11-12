from PIL import Image
from pathlib import Path
import numpy as np,json
ROOT=Path('/home/user/mage_idle_export');OUT=ROOT/'assets/mage';OUT.mkdir(parents=True,exist_ok=True)
im=Image.open('/home/user/mage_idle_cast.png').convert('RGBA')
walk=Image.open('/home/user/mage_pose_sheet.png').convert('RGBA')
assert im.size==(1920,1536),im.size
directions=['up','ne','right','se','down'];records=[]
def clean(cell):
 a=np.array(cell)
 a[:,:,3]=np.where(a[:,:,3]<24,0,np.where(a[:,:,3]>220,255,((a[:,:,3].astype(float)-24)/196*255).clip(0,255))).astype('uint8')
 return Image.fromarray(a)
def metrics(cell):
 a=np.array(cell)[:,:,3]>128;ys,xs=np.where(a);ground=int(ys.max())
 yy,xx=np.where(a & (np.indices(a.shape)[0]>ground-44));root=float(xx.mean())
 core=a[:,max(0,round(root)-24):min(384,round(root)+24)]
 head=int(np.where(core)[0].min())
 return root,ground,ground-head
for column,direction in enumerate(directions):
 cells=[clean(im.crop((column*384,row*512,(column+1)*384,(row+1)*512))) for row in range(3)]
 roots,grounds,heights=zip(*(metrics(c) for c in cells))
 wh=[metrics(clean(walk.crop((column*384,row*512,(column+1)*384,(row+1)*512))))[2] for row in range(4)]
 root=float(np.mean(roots));ground=float(np.median(grounds))
 scale=.78*float(np.mean(wh))/float(np.mean(heights))
 outputs=[]
 for cell in cells:
  out=Image.new('RGBA',(384,384))
  out.alpha_composite(cell.resize((round(384*scale),round(512*scale)),Image.Resampling.LANCZOS),(round(192-root*scale),round(368-ground*scale)))
  outputs.append(out)
 outputs[0].save(OUT/('idle_'+direction+'.png'))
 cast=Image.new('RGBA',(768,384))
 cast.paste(outputs[1],(0,0));cast.paste(outputs[2],(384,0));cast.save(OUT/('cast_'+direction+'.png'))
 records.append({'direction':direction,'source_root_x':root,'source_ground_y':ground,'scale':scale,'idle_frames':1,'cast_frames':2,'feet':[192,368]})
ui=ROOT/'assets/ui';ui.mkdir(exist_ok=True)
turn=Image.open('/home/user/mage_turnaround.png').convert('RGB')
turn.crop((72,0,464,392)).resize((256,256),Image.Resampling.LANCZOS).save(ui/'mage_portrait.png')
(ROOT/'data').mkdir(exist_ok=True)
(ROOT/'data/mage_idle_cast_manifest.json').write_text(json.dumps({'source_job':'317b7ac8-94ef-47a4-abf1-aa91fa357d55','portrait_source_job':'27a1c5c2-d5b4-422d-b12c-249b5277732b','directions':records},indent=2))
print('Prepared five idles, five two-pose cast strips, and one derived portrait')

