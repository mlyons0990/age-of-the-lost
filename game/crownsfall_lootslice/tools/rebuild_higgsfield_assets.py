"""Rebuild delivered runtime derivatives. Requires Pillow and numpy.
Run from a project copy: python3 tools/rebuild_higgsfield_assets.py --project .
Raw generated images remain unchanged. UI panel is already the original source.
"""
from pathlib import Path
import argparse

def build_spells(project):
    from PIL import Image
    from pathlib import Path
    import json,hashlib
    root=project;out=root/'assets/painted_icons';out.mkdir(parents=True,exist_ok=True)
    im=Image.open(project/'assets/higgsfield_sources/mage_spell_icon_atlas.png').convert('RGB');assert im.size==(2048,1024),im.size
    ids=['cinder_thread','glacial_stitch','arcane_fold','ashen_ward','starfall_script','solar_writ','winter_crown','epoch_lance'];records=[]
    for i,id in enumerate(ids):
        cell=im.crop(((i%4)*512,(i//4)*512,(i%4+1)*512,(i//4+1)*512)).resize((256,256),Image.Resampling.LANCZOS)
        p=out/(id+'.png');cell.save(p)
        records.append({'id':id,'runtime_path':'assets/painted_icons/'+p.name,'source_cell':[i%4,i//4],'size':[256,256],'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
    (root/'data').mkdir(exist_ok=True);(root/'data/painted_spell_manifest.json').write_text(json.dumps({'source':'mage_spell_icon_atlas.png','job_id':'441b496a-a6b8-4cc0-952d-5af7aa8171fe','model':'gpt_image_2_6','files':records},indent=2))
    print('Prepared',len(records),'painted spell icons')
    

def build_gear(project):
    from PIL import Image
    from pathlib import Path
    import json,hashlib
    root=project;out=root/'assets/painted_icons';out.mkdir(parents=True,exist_ok=True)
    im=Image.open(project/'assets/higgsfield_sources/mage_gear_icon_atlas.png').convert('RGB');assert im.size==(2048,1024),im.size
    ids=['staff','wand','focus','robe','hood','wraps','slippers','spellbook_source'];records=[]
    for i,id in enumerate(ids):
        cell=im.crop(((i%4)*512,(i//4)*512,(i%4+1)*512,(i//4+1)*512)).resize((256,256),Image.Resampling.LANCZOS)
        p=out/(id+'.png');cell.save(p)
        records.append({'id':id,'runtime_path':'assets/painted_icons/'+p.name,'source_cell':[i%4,i//4],'size':[256,256],'runtime_item':i<7,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
    (root/'data').mkdir(exist_ok=True);(root/'data/painted_gear_manifest.json').write_text(json.dumps({'source':'mage_gear_icon_atlas.png','job_id':'9c2d0436-3313-49fe-a4a3-9a53f1d7a355','model':'gpt_image_2_6','files':records},indent=2))
    print('Prepared 7 runtime gear paintings and 1 bonus source book')
    

def build_walk(project):
    from PIL import Image
    from pathlib import Path
    import numpy as np, json, hashlib
    ROOT=project
    OUT=ROOT/'assets/mage';OUT.mkdir(parents=True,exist_ok=True)
    im=Image.open(project/'assets/higgsfield_sources/mage_directional_pose_sheet.png').convert('RGBA')
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
    

def build_idle_cast(project):
    from PIL import Image
    from pathlib import Path
    import numpy as np,json
    ROOT=project;OUT=ROOT/'assets/mage';OUT.mkdir(parents=True,exist_ok=True)
    im=Image.open(project/'assets/higgsfield_sources/mage_idle_cast_pose_sheet.png').convert('RGBA')
    walk=Image.open(project/'assets/higgsfield_sources/mage_directional_pose_sheet.png').convert('RGBA')
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
    turn=Image.open(project/'assets/higgsfield_sources/mage_turnaround.png').convert('RGB')
    turn.crop((72,0,464,392)).resize((256,256),Image.Resampling.LANCZOS).save(ui/'mage_portrait.png')
    (ROOT/'data').mkdir(exist_ok=True)
    (ROOT/'data/mage_idle_cast_manifest.json').write_text(json.dumps({'source_job':'317b7ac8-94ef-47a4-abf1-aa91fa357d55','portrait_source_job':'27a1c5c2-d5b4-422d-b12c-249b5277732b','directions':records},indent=2))
    print('Prepared five idles, five two-pose cast strips, and one derived portrait')
    

def build_audio(project):
    """Deterministic placeholder cues authored through Higgsfield's media sandbox.
    Not generated voices/music and not a production sound library."""
    import math, random, wave, struct, json, hashlib
    from pathlib import Path
    RATE=22050
    ROOT=project
    OUT=ROOT/'assets/audio'
    OUT.mkdir(parents=True,exist_ok=True)
    CUES={
     'cinder_thread':(.34,340,1250,.22,'fire'),
     'glacial_stitch':(.48,1500,700,.1,'ice'),
     'arcane_fold':(.35,170,1150,.10,'arcane'),
     'ashen_ward':(.65,330,400,.05,'ward'),
     'starfall_script':(.62,900,160,.16,'star'),
     'solar_writ':(.60,280,1000,.33,'fire'),
     'winter_crown':(.72,2000,500,.13,'ice'),
     'epoch_lance':(.48,250,1700,.08,'arcane'),
     'ui_click':(.07,660,880,.01,'ui'),
     'equip':(.18,440,660,.025,'ward'),
     'pickup':(.22,800,1300,.02,'ui'),
     'potion':(.32,400,780,.04,'ward'),
     'slash':(.15,450,200,.40,'fire')
    }
    records=[]
    for name,(duration,start,end,noise,kind) in CUES.items():
     rng=random.Random(3107+sum(map(ord,name)))
     count=round(duration*RATE); samples=[]; phase=0.; low=0.
     for i in range(count):
      t=i/RATE; u=i/max(1,count-1)
      frequency=start*((end/start)**u)
      phase+=2*math.pi*frequency/RATE
      attack=min(1.,t/.012)
      release=min(1.,(duration-t)/.07)
      decay=(1-u)**1.5
      env=attack*release*decay
      white=rng.uniform(-1,1);low=.82*low+.18*white
      tone=math.sin(phase)+.28*math.sin(2*phase)+.12*math.sin(3.01*phase)
      if kind=='fire': tone=.22*tone+noise*4*low
      elif kind=='ice': tone=.43*tone+.35*math.sin(phase*2.76)+noise*white
      elif kind=='arcane':tone=.55*tone*math.sin(2*math.pi*35*t)+noise*white
      elif kind=='star':tone=.33*tone+.3*math.sin(phase*.5)+noise*3*low
      elif kind=='ward':tone=.48*tone+.22*math.sin(phase*1.5)
      else:tone=.5*tone
      samples.append(tone*env)
     peak=max(map(abs,samples)); gain=.55/max(peak,.001)
     values=[round(max(-1,min(1,s*gain))*32767) for s in samples]
     path=OUT/(name+'.wav')
     with wave.open(str(path),'wb') as w:
      w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE)
      w.writeframes(struct.pack('<'+'h'*len(values),*values))
     records.append({'id':name,'path':'assets/audio/'+path.name,'duration_seconds':duration,'sample_rate':RATE,'channels':1,'peak':max(map(abs,values))/32767,'rms':math.sqrt(sum((v/32767)**2 for v in values)/len(values)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    (ROOT/'data').mkdir(exist_ok=True)
    (ROOT/'data/audio_manifest.json').write_text(json.dumps({'provenance':'Procedural deterministic synthesis in Higgsfield sandbox; no speech/music model used','human_listening_review':False,'files':records},indent=2))
    print('Created',len(records),'mono PCM WAV cues')
    print('Largest peak:',max(r['peak'] for r in records))
    

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project',type=Path,default=Path('.'))
    args=parser.parse_args()
    for build in [build_spells,build_gear,build_walk,build_idle_cast,build_audio]: build(args.project.resolve())

