#!/usr/bin/env python3
"""Staging helper for the additive Phase A runtime art preview.
Run from repository root or game directory:
  python game/crownsfall_lootslice/tools/stage_phase_a_art.py --stage
  python game/crownsfall_lootslice/tools/stage_phase_a_art.py --verify
Requires: Pillow. Does not modify gameplay data, save state or original art.
"""
from pathlib import Path
from PIL import Image
import argparse, json, hashlib, shutil, sys
ROOT=Path(__file__).resolve().parents[3]
GAME=ROOT/'game/crownsfall_lootslice'
TAX=ROOT/'art/item_taxonomy/2026-11-12'

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--stage',action='store_true',help='copy reviewed candidate artwork into optional runtime preview paths')
    p.add_argument('--verify',action='store_true',help='verify staged assets and mappings without changing any files')
    p.add_argument('--taxonomy-dir',type=Path,default=TAX,help='source taxonomy directory; defaults to art/item_taxonomy/2026-11-12 in repo root')
    args=p.parse_args()
    if args.stage == args.verify:p.error('choose exactly one of --stage or --verify')
    catalog=json.loads((args.taxonomy_dir/'catalog.json').read_text())
    source={e['asset_id']:e for e in catalog['entries']}
    mf=json.loads((GAME/'data/phase_a_preview_manifest.json').read_text())
    base_defs=json.loads((GAME/'data/item_base_definitions.json').read_text())
    profile=json.loads((GAME/'data/phase_a_preview_profile.json').read_text())
    expected={m['game_id']:m['staged_path'] for m in mf['items']}
    assert profile['portraits']==expected
    assert set(expected)==set(base_defs), 'not every game base has a preview mapping'
    checks=0
    for item in mf['items']:
        key=item['game_id'];e=source[item['source_asset_id']]
        source_file=args.taxonomy_dir/e['texture_path']
        dest=GAME/('assets/phase_a_preview/portraits/'+key+'.png')
        assert source_file.is_file(),f'Missing original source: {source_file}. Git LFS may need pull.'
        assert sha(source_file)==e['production']['texture_sha256'],f'Unexpected source SHA: {key}'
        assert list(e['cells'])==base_defs[key]['footprint'],f'Game footprint mismatch: {key}'
        assert e['status']=='reviewed_art_candidate' and not e['runtime_enabled']
        with Image.open(source_file) as im:
            assert im.mode=='RGBA' and list(im.size)==[v*128 for v in e['cells']]
            assert im.getchannel('A').getbbox() is not None
        checks+=5
        if args.stage:
            dest.parent.mkdir(parents=True,exist_ok=True)
            if dest.exists() and sha(dest)!=sha(source_file):
                raise RuntimeError(f'Refusing to overwrite an existing, different preview: {dest}')
            if not dest.exists(): shutil.copy2(source_file,dest)
        assert dest.is_file(), f'Not staged: {key}; run --stage'
        assert sha(dest)==sha(source_file)==item['sha256'],f'Corrupt staged file: {key}'
        checks+=2
    print(f'Phase A preview {"staged" if args.stage else "verified"}: {len(mf["items"])} art paths, {checks} checks passed. Source art/default art unchanged.')
    return 0
if __name__=='__main__':sys.exit(main())