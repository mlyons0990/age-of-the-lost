"""Write a credit-free Higgsfield art request; never submit jobs or change gameplay."""
from pathlib import Path
import argparse,json

def main():
 root=Path(__file__).resolve().parents[1]
 p=argparse.ArgumentParser(description=__doc__)
 group=p.add_mutually_exclusive_group(required=True)
 group.add_argument('--ability-id',help='One of the implemented initial-batch IDs.')
 group.add_argument('--future-id',help='A proposed, unimplemented ID; concept artwork only.')
 p.add_argument('--name');p.add_argument('--motif');p.add_argument('--action')
 p.add_argument('--family',choices=['physical','frost','fire','arcane','gold_light'])
 p.add_argument('--output',type=Path)
 args=p.parse_args();rules=json.loads((root/'framework/INITIAL_BATCH.json').read_text())
 if args.ability_id:
  if args.ability_id not in rules['abilities']:p.error('Unknown implemented ability; use --future-id for a concept.')
  entry=dict(rules['abilities'][args.ability_id]);entry['id']=args.ability_id;entry['implemented']=True
 else:
  if args.future_id in rules['abilities']:p.error('That ID already belongs to the implemented batch.')
  if not all([args.name,args.motif,args.action,args.family]):p.error('Future artwork requires --name, --motif, --action and --family.')
  entry={'id':args.future_id,'name':args.name,'motif':args.motif,'action':args.action,'family':args.family,'implemented':False}
 style=(root/'framework/PROMPT_TEMPLATE.txt').read_text()
 prompt=style.format(name=entry['name'],motif=entry['motif'],action=entry['action'],family=entry['family'])
 data={'asset_id':'aotl_skill_'+entry['id'],'status':'implemented_ability_art_request' if entry['implemented'] else 'concept_only_unimplemented','ability':entry,'params':{'model':'gpt_image_2_6','prompt':prompt,'aspect_ratio':'1:1','quality':'medium','resolution':'2k','background':'opaque','output_format':'png','count':1,'use_unlim':True,'medias':[{'role':'image','value':rules['production_framework_job_id']}]},'preflight':'Use estimate_image_cost first; only submit with the existing unlimited allowance. Never switch to credits.','gameplay_changes':False}
 text=json.dumps(data,indent=2)
 if args.output:args.output.write_text(text+'\n')
 else:print(text)
if __name__=='__main__':main()
