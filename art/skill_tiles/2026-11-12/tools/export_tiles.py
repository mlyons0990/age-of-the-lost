"""Rebuild accepted full-square paintings from their exact source atlas regions."""
from pathlib import Path
from PIL import Image
import argparse,hashlib,json

def main():
 root=Path(__file__).resolve().parents[1]
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--project',type=Path,default=root.parents[2]/'game/crownsfall_lootslice')
 args=parser.parse_args();project=args.project.resolve()
 if not (project/'project.godot').is_file():parser.error('Supply the playable Godot project with --project.')
 profile=json.loads((root/'catalog.json').read_text());source=root/profile['source']
 assert hashlib.sha256(source.read_bytes()).hexdigest()==profile['source_sha256'],'Source atlas changed'
 image=Image.open(source).convert('RGB')
 for entry in profile['selections']:
  x,y,w,h=entry['source_region'];tile=image.crop((x,y,x+w,y+h));master=root/entry['master'];master.parent.mkdir(exist_ok=True);tile.save(master)
  output=project/entry['runtime_path'];output.parent.mkdir(parents=True,exist_ok=True);tile.resize((128,128),Image.Resampling.LANCZOS).save(output)
  assert hashlib.sha256(master.read_bytes()).hexdigest()==entry['master_sha256'],entry['id']
  assert hashlib.sha256(output.read_bytes()).hexdigest()==entry['runtime_sha256'],entry['id']
 print('Rebuilt20 masters +20 runtime paintings; all40 output hashes match.')
if __name__=='__main__':main()
