"""Build a source-linked registry from selected exports and terminal job records."""
import json,hashlib
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
catalog=json.loads((ROOT/'catalog.json').read_text())
records=json.loads((ROOT/'EXPORT_REPORT.json').read_text())
for row in records:
    row['index']=int(row['index'])
    for key in ['cells','pixels','source_region','used_region']:row[key]=[int(n) for n in row[key]]
(ROOT/'EXPORT_REPORT.json').write_text(json.dumps(records,indent=2))
jobs=[]
for f in sorted(ROOT.glob('jobs_terminal_*.json')):jobs.extend(json.loads(f.read_text())['jobs'])
by_index={j['index']:j for j in jobs}
source_indices=json.loads((ROOT/'SOURCE_INDEX.json').read_text())
selected={}
for r in records:
    source=ROOT/r['source'];image=Image.open(source)
    e=catalog['entries'][r['index']-1]
    job=by_index[source_indices[source.name]]
    e['status']='reviewed_art_candidate'
    e['source_path']=r['source'];e['texture_path']=r['output']
    e['individual_asset_brief']=e.pop('prompt',e.get('individual_asset_brief',''))
    if 'params' in e:e['individual_brief_params']=e.pop('params')
    e['production']={'job_id':job['job_id'],'generation_index':job['index'],'model':job['model'],'source_pixels':list(image.size),'source_region':r['source_region'],'texture_pixels':r['pixels'],'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'texture_sha256':hashlib.sha256((ROOT/r['output']).read_bytes()).hexdigest()}
    selected.setdefault(source.name,[]).append(e['index'])
catalog.update({'selected_art_count':len(records),'runtime_enabled_count':0,'generation_jobs_completed':sum(j['status']=='completed' for j in jobs),'generation_jobs_without_image':sum(j['status']!='completed' for j in jobs),'review_engine':'Godot 4.6.3','billing':'Every production request used the explicitly authorized unlimited allowance; no paid fallback.'})
(ROOT/'catalog.json').write_text(json.dumps(catalog,indent=2))
sources=[]
for filename,index in source_indices.items():
    path=ROOT/'generated_sources'/filename
    if not path.exists():continue
    sources.append({'file':str(path.relative_to(ROOT)),'generation_index':index,'job':by_index[index],'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'selected_entries':selected.get(filename,[]),'status':'selected' if filename in selected else 'superseded_transparency_cleanup'})
(ROOT/'SOURCE_PROVENANCE.json').write_text(json.dumps(sources,indent=2))
print('Registry:',len(records),'candidates;',len(selected),'selected original images;',len(sources),'downloaded current sources')
