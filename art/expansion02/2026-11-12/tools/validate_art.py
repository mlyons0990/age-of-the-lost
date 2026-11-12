"""Check delivery image geometry and alpha; does not modify artwork."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
records = json.loads((ROOT / 'EXPORT_REPORT.json').read_text())
catalog = json.loads((ROOT/'catalog.json').read_text())
checks = []
for row in records:
    im = Image.open(ROOT / row['output'])
    entry=catalog['entries'][int(row['index'])-1]
    expected = tuple(n * entry.get('pixels_per_cell',128) for n in row['cells'])
    checks.append({'asset': row['asset_id'], 'check': 'footprint_pixels', 'pass': im.size == expected})
    checks.append({'asset': row['asset_id'], 'check': 'rgba', 'pass': im.mode == 'RGBA'})
    a = im.getchannel('A')
    solid = a.point(lambda v: 255 if v >= 64 else 0)
    bounds = solid.getbbox()
    checks.append({'asset': row['asset_id'], 'check': 'visible_equipment', 'pass': bool(bounds)})
    margin_ok = bool(bounds) and bounds[0] >= 6 and bounds[1] >= 6 and bounds[2] <= im.width-6 and bounds[3] <= im.height-6
    checks.append({'asset': row['asset_id'], 'check': 'safe_export_margin', 'pass': margin_ok})
    corners = [a.getpixel(xy) for xy in [(0,0),(im.width-1,0),(0,im.height-1),(im.width-1,im.height-1)]]
    checks.append({'asset': row['asset_id'], 'check': 'transparent_canvas_corners', 'pass': max(corners) == 0})
    source = Image.open(ROOT / row['source'])
    x,y,w,h = row['source_region']
    region = source.getchannel('A').crop((x,y,x+w,y+h))
    edge = list(region.crop((0,0,w,1)).get_flattened_data())+list(region.crop((0,h-1,w,h)).get_flattened_data())+list(region.crop((0,0,1,h)).get_flattened_data())+list(region.crop((w-1,0,w,h)).get_flattened_data())
    checks.append({'asset': row['asset_id'], 'check': 'no_solid_source_boundary_contact', 'pass': max(edge) < 64, 'max_alpha': max(edge)})
for row in records:
    entry=catalog['entries'][int(row['index'])-1]
    if entry['kind'] != 'ui_icon': continue
    for edge in [32,64,128]:
        im=Image.open(ROOT/f'runtime_sizes/{edge}'/(row['asset_id']+'.png'))
        a=im.getchannel('A')
        prefix=f'ui_{edge}_'
        checks.append({'asset':row['asset_id'],'check':prefix+'dimensions','pass':im.size==(edge,edge)})
        checks.append({'asset':row['asset_id'],'check':prefix+'visible','pass':bool(a.point(lambda v:255 if v>=64 else 0).getbbox())})
        corners=[a.getpixel(xy) for xy in [(0,0),(edge-1,0),(0,edge-1),(edge-1,edge-1)]]
        checks.append({'asset':row['asset_id'],'check':prefix+'transparent_corners','pass':max(corners)==0})
report = {'image_count': len(records),'derived_icon_count':90, 'passed': sum(c['pass'] for c in checks), 'total': len(checks), 'checks': checks}
(ROOT / 'ART_QA.json').write_text(json.dumps(report, indent=2))
print(json.dumps({k: v for k,v in report.items() if k != 'checks'}))
for c in checks:
    if not c['pass']: print('REVIEW',c)
