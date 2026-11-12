"""Create a portable art-review ZIP and verify every included file hash."""
import hashlib,json,zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT.parent/'art_expansion02_delivery'
OUT.mkdir(exist_ok=True)
files=sorted(p for p in ROOT.rglob('*') if p.is_file() and '.godot' not in p.parts and '__pycache__' not in p.parts and p.name!='FILE_MANIFEST.json')
manifest={str(p.relative_to(ROOT)):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in files}
(ROOT/'FILE_MANIFEST.json').write_text(json.dumps(manifest,indent=2))
files.append(ROOT/'FILE_MANIFEST.json')
output=OUT/'AOTL_Art_Expansion02_Library_2026-11-12.zip'
with zipfile.ZipFile(output,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p in files:z.write(p,'AOTL_Art_Expansion02_2026-11-12/'+str(p.relative_to(ROOT)))
with zipfile.ZipFile(output) as z:
    assert z.testzip() is None
    for path,record in manifest.items():
        data=z.read('AOTL_Art_Expansion02_2026-11-12/'+path)
        assert len(data)==record['bytes'] and hashlib.sha256(data).hexdigest()==record['sha256'],path
delivery={'file':output.name,'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'archive_files':len(files),'verified_manifest_files':len(manifest),'zip_crc_verified':True}
(OUT/'DELIVERY_MANIFEST.json').write_text(json.dumps(delivery,indent=2))
print(json.dumps(delivery))
