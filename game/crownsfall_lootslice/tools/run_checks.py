"""Run the seventeen suites with separate, disposable Linux user-data directories.

Usage: python3 tools/run_checks.py --report-dir /tmp/aotl-reports
The project cache/result text files are updated; actual progress is not used.
"""
from pathlib import Path
import argparse,json,os,re,shutil,subprocess,sys,tempfile,time

SUITES=[
 ('warrior',['--','--systems-test'],'RESULT',52),
 ('mage',['--','--mage-test'],'MAGE RESULT',57),
 ('lab',['--script','res://tests/lab_roundtrip.gd'],'LAB RESULT',28),
 ('art_audio',['--script','res://tests/art_audio_integration.gd'],'ART AUDIO RESULT',19),
 ('mastery',['--script','res://tests/mastery_integration.gd'],'MASTERY RESULT',86),
 ('encounter',['--script','res://tests/encounter_integration.gd'],'ENCOUNTER RESULT',60),
 ('encounter_bouts',['--script','res://tests/encounter_playthrough.gd'],'ENCOUNTER BOUT RESULT',15),
 ('inventory_ui',['--script','res://tests/inventory_ui_integration.gd'],'INVENTORY UI RESULT',108),
 ('town_ui',['--script','res://tests/town_ui_integration.gd'],'TOWN UI RESULT',69),
 ('reliability',['--script','res://tests/reliability_integration.gd'],'RELIABILITY RESULT',77),
 ('navigation',['--script','res://tests/navigation_integration.gd'],'NAVIGATION RESULT',36),
 ('grid_alignment',['--script','res://tests/grid_alignment_integration.gd'],'GRID ALIGNMENT RESULT',64),
 ('loot',['--script','res://tests/loot_integration.gd'],'LOOT RESULT',78),
 ('selected_art',['--script','res://tests/selected_art_integration.gd'],'SELECTED ART RESULT',76),
 ('skill_tiles',['--script','res://tests/skill_tiles_integration.gd'],'SKILL TILES RESULT',75),
 ('actor_feedback',['--script','res://tests/actor_feedback_integration.gd'],'ACTOR FEEDBACK RESULT',54),
 ('dialogue',['--script','res://tests/dialogue_integration.gd'],'DIALOGUE RESULT',40)]

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parent.parent)
 parser.add_argument('--godot',default=shutil.which('godot'))
 parser.add_argument('--report-dir',type=Path,required=True)
 args=parser.parse_args()
 if sys.platform!='linux':parser.error('This runner isolates Linux XDG data. On other platforms follow docs/QA_AND_REPRO.md with a separate Custom User Dir Name.')
 if not args.godot:parser.error('Godot executable not found; supply --godot /path/to/godot.')
 project=args.project.resolve();reports=args.report_dir.resolve();reports.mkdir(parents=True,exist_ok=True)
 if not (project/'project.godot').is_file():parser.error('Project path has no project.godot.')
 summary={'project':str(project),'platform':sys.platform,'suites':[],'unique_assertions':0,'success':False}
 with tempfile.TemporaryDirectory(prefix='aotl-isolated-checks-') as temp:
  base=Path(temp)
  def run(name,flags):
   env=os.environ.copy()
   for var,leaf in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
    directory=base/name/leaf;directory.mkdir(parents=True,exist_ok=True);env[var]=str(directory)
   command=[args.godot,'--headless','--path',str(project),'--audio-driver','Dummy',*flags]
   started=time.monotonic()
   try:
    result=subprocess.run(command,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=120)
    output=result.stdout;exit_code=result.returncode
   except subprocess.TimeoutExpired as error:
    output=error.stdout or '';output=output.decode(errors='replace') if isinstance(output,bytes) else output
    output+='\nRUNNER TIMEOUT\n';exit_code=124
   (reports/(name+'.log')).write_text(output)
   return output,exit_code,round(time.monotonic()-started,3)
  imported,code,duration=run('import',['--editor','--quit'])
  summary['import']={'exit_code':code,'seconds':duration}
  bad=['SCRIPT ERROR','\nERROR:','\nFAIL ','instances leaked','RUNNER TIMEOUT']
  if code or any(token in imported for token in bad):
   print('IMPORT FAILED: inspect',reports/'import.log')
  else:
   for name,flags,label,expected in SUITES:
    output,code,duration=run(name,flags)
    match=re.search(re.escape(label)+r' (\d+) checks; (\d+) failures',output)
    ok=code==0 and match is not None and int(match[1])==expected and int(match[2])==0 and not any(token in output for token in bad)
    summary['suites'].append({'name':name,'success':ok,'expected_checks':expected,'exit_code':code,'seconds':duration})
    if ok:summary['unique_assertions']+=expected
    print(('PASS' if ok else 'FAIL'),name,'—',expected,'checks; log:',reports/(name+'.log'))
   summary['success']=len(summary['suites'])==len(SUITES) and all(item['success'] for item in summary['suites'])
 (reports/'summary.json').write_text(json.dumps(summary,indent=2))
 print('Verified assertions:',summary['unique_assertions'],'/',sum(s[3] for s in SUITES))
 return 0 if summary['success'] else 1

if __name__=='__main__':raise SystemExit(main())
