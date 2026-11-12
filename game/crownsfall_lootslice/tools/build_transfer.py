"""Create a complete source ZIP outside the project, excluding caches/live QA data.

Run the isolated checks first. Example:
python3 tools/build_transfer.py --destination /tmp/aotl-release
"""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
import argparse,hashlib,json

EXCLUDED={'.godot','.git','.qa','.venv','__pycache__','.cache'}
def include(file,project):
 if not file.is_file() or any(part in EXCLUDED for part in file.relative_to(project).parts):return False
 if file.suffix in ['.import','.translation','.tmp','.pyc']:return False
 if file.suffix=='.log' and not file.is_relative_to(project/'tests'):return False
 if file.name.startswith(('mage_combat_','combat_','rig_frame_','aura_frame_','trial_frame_','core.')):return False
 return True

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parent.parent)
 parser.add_argument('--destination',type=Path,required=True)
 parser.add_argument('--name',default='Age_of_the_Lost_Full_Skill_Buttons_2026-11-12.zip')
 args=parser.parse_args();project=args.project.resolve();dest=args.destination.resolve()
 if dest==project or project in dest.parents:parser.error('Destination must be outside the project to avoid recursive artifacts.')
 if not (project/'project.godot').is_file():parser.error('No project.godot at the selected path.')
 if Path(args.name).name!=args.name or not args.name.endswith('.zip'):parser.error('Name must be a plain .zip filename.')
 dest.mkdir(parents=True,exist_ok=True)
 manifest=[]
 for file in sorted(project.rglob('*')):
  if include(file,project) and file.name!='release_file_manifest.json':
   manifest.append({'path':str(file.relative_to(project)),'bytes':file.stat().st_size,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})
 (project/'data/release_file_manifest.json').write_text(json.dumps({'project':project.name,'files':manifest},indent=2))
 archive=dest/args.name
 with ZipFile(archive,'w',ZIP_DEFLATED,compresslevel=6) as z:
  for file in sorted(project.rglob('*')):
   if include(file,project):z.write(file,Path(project.name)/file.relative_to(project))
 with ZipFile(archive) as z:
  assert z.testzip() is None
  assert not any('/.godot/' in n or '/.qa/' in n for n in z.namelist())
 summary={'file':archive.name,'bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'source_files':len(manifest)+1}
 (dest/(archive.stem+'_archive_manifest.json')).write_text(json.dumps(summary,indent=2))
 print(json.dumps(summary,indent=2))

if __name__=='__main__':main()
