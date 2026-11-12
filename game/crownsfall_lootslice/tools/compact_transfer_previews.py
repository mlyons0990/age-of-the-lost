"""Resize documentation PNG captures for a smaller transfer; preserve a backup.

Runtime assets and art source images are never changed. Rendered suites can
regenerate full-size captures. Example:
python3 tools/compact_transfer_previews.py --backup /tmp/aotl-full-previews
"""
from pathlib import Path
import argparse,json,shutil

def main():
 from PIL import Image
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parent.parent)
 parser.add_argument('--backup',type=Path,required=True)
 parser.add_argument('--colors',type=int,choices=[128,256],default=256,help='Palette size for documentation PNGs only.')
 parser.add_argument('--max-edge',type=int,default=960,help='Maximum documentation capture edge, in pixels.')
 args=parser.parse_args();root=args.project.resolve();backup=args.backup.resolve()
 if not 320<=args.max_edge<=4096:parser.error('Choose a max edge between 320 and 4096 pixels.')
 if backup==root or root in backup.parents:parser.error('Backup must be outside the source project.')
 if backup.exists():parser.error('Choose a new backup directory; existing backups are preserved.')
 shutil.copytree(root/'previews',backup)
 records=[]
 for path in (root/'previews').rglob('*.png'):
  if path.name.startswith(('trial_frame_','aura_frame_','rig_frame_','combat_','mage_combat_')):continue
  with Image.open(path) as image:
   before=list(image.size)
   image=image.convert('RGB')
   image.thumbnail((args.max_edge,args.max_edge),Image.Resampling.LANCZOS)
   image.quantize(colors=args.colors,dither=Image.Dither.NONE).save(path,optimize=True)
   records.append({'path':str(path.relative_to(root)),'original_size':before,'delivery_size':list(image.size),'palette_colors':args.colors})
 (root/'previews/LAST_PREVIEW_COMPACTION.json').write_text(json.dumps({'captures':records,'runtime_or_source_art_changed':False},indent=2))
 print('Resized',len(records),'documentation captures; backup:',backup)
if __name__=='__main__':main()
