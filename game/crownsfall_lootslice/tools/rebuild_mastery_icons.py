"""Rebuild six mastery/unique crops from the retained Higgsfield source. Requires Pillow."""
from pathlib import Path
import argparse

def build(project):
    from PIL import Image
    from pathlib import Path
    import json,hashlib
    root=project;out=root/'assets/painted_icons';out.mkdir(parents=True,exist_ok=True)
    im=Image.open(project/'assets/higgsfield_sources/mastery_unique_icon_atlas.png').convert('RGB');assert im.size==(1536,1024),im.size
    ids=['ward_temper','ember_aura','cinder_bloom','siphon_embers','steady_flame','emberwake_circlet'];records=[]
    for i,id in enumerate(ids):
        cell=im.crop(((i%3)*512,(i//3)*512,(i%3+1)*512,(i//3+1)*512)).resize((256,256),Image.Resampling.LANCZOS)
        p=out/(id+'.png');cell.save(p)
        records.append({'id':id,'path':'assets/painted_icons/'+p.name,'source_cell':[i%3,i//3],'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
    (root/'data').mkdir(exist_ok=True);(root/'data/mastery_painted_manifest.json').write_text(json.dumps({'job_id':'674d526b-92ee-4d37-bb3e-3350d535b437','source':'assets/higgsfield_sources/mastery_unique_icon_atlas.png','files':records},indent=2))
    print('Prepared six mastery/unique paintings')
    

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project',type=Path,default=Path('.'))
    args=parser.parse_args()
    build(args.project.resolve())

