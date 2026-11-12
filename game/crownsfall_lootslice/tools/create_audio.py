"""Deterministic placeholder cues authored through Higgsfield's media sandbox.
Not generated voices/music and not a production sound library."""
import math, random, wave, struct, json, hashlib
from pathlib import Path
RATE=22050
ROOT=Path('/home/user/crownsfall_assets')
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

