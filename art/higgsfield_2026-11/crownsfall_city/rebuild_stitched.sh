#!/bin/sh
# city_stitched.png (114 MB, over GitHub's file limit) is rebuilt from the 9 upscaled sections; run from this folder.
cd "$(dirname "$0")"
S=$(python3 -c "import json;s=json.load(open('sections/sections.json'));print(json.dumps([{'img':'upscaled/'+x['name']+'.png','x0':x['x0'],'y0':x['y0'],'cw':x['cw'],'ch':x['ch']} for x in s]))")
python3 ../../../game/crownsfall_lootslice/tools/stitch_upscaled_sections.py city_stitched.png 3840 1648 "$S"
