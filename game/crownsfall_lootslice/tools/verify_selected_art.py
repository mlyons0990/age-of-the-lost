"""Verify selected runtime-art hashes; optionally verify Expansion02 source hashes."""
from pathlib import Path
import argparse,hashlib,json

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--library',type=Path,help='Optional Expansion02 library root.')
    args=parser.parse_args();project=args.project.resolve()
    profile=json.loads((project/'data/selected_art_profile.json').read_text())
    failures=[];verified=0
    for selection in profile['selections']:
        pairs=[(project/selection['runtime_path'],selection['runtime_sha256'])]
        if args.library:pairs.append((args.library/selection['source_path'],selection['source_sha256']))
        for path,expected in pairs:
            if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest()!=expected:
                failures.append(str(path))
            else:verified+=1
    for path in failures:print('MISMATCH:',path)
    print(f'Verified {verified} hashes; {len(failures)} failures.')
    return bool(failures)

if __name__=='__main__':raise SystemExit(main())
