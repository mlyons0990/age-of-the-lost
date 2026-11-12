#!/usr/bin/env python3
"""Static item-footprint reference sheet; illustrative, not an engine capture."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/figures/item_footprints_STATIC_NOT_ENGINE.png'
OUT.parent.mkdir(parents=True,exist_ok=True)
BASE=Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')
SERIF=Path('/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf')
font=ImageFont.truetype(str(BASE),17)
small=ImageFont.truetype(str(BASE),13)
heading=ImageFont.truetype(str(SERIF),30)
line=ImageFont.truetype(str(SERIF),19)
w,h=1160,690
img=Image.new('RGB',(w,h),(13,18,25));d=ImageDraw.Draw(img)
d.rectangle([22,20,w-24,h-22],fill=(21,25,32),outline=(122,100,67),width=3)
d.text((46,41),'AGE OF THE LOST  /  INVENTORY FOOTPRINT VERIFICATION',font=heading,fill=(219,189,130))
d.text((47,88),'Artwork fitted to the true grid geometry  •  STATIC ASSET REVIEW  •  Not an in-engine screenshot',font=font,fill=(154,165,177))
cell=50;origin=(63,155);cols=10;rows=6
for j in range(rows):
 for i in range(cols):
  x=origin[0]+i*cell;y=origin[1]+j*cell
  d.rectangle((x,y,x+cell-1,y+cell-1),fill=(18,23,31),outline=(67,63,54),width=1)
layout=[('weapon',0,0,1,3,'SWORD'),('armor',1,0,2,3,'ARMOR'),('staff',3,0,2,4,'STAFF'),('ring',5,0,1,1,'RING'),('amulet',6,0,1,1,'AMULET'),('belt',7,0,2,1,'BELT'),('helm',7,1,2,2,'HELM'),('gloves',5,1,2,2,'GLOVES'),('wand',5,3,1,2,'WAND'),('focus',6,3,1,2,'FOCUS'),('boots',7,3,2,2,'BOOTS'),('robe',0,3,2,3,'ROBE'),('ring',9,5,1,1,'RING')]
colors=[(120,177,219),(194,173,112),(176,138,209),(158,178,127)]
for k,(name,x,y,iw,ih,label) in enumerate(layout):
 ax,ay=origin[0]+x*cell,origin[1]+y*cell
 d.rectangle((ax+1,ay+1,ax+iw*cell-2,ay+ih*cell-2),fill=(29,38,50))
 portrait=Image.open(ROOT/'assets/item_portraits'/f'{name}.png').convert('RGBA')
 portrait=portrait.resize((iw*cell-10,ih*cell-10),Image.Resampling.LANCZOS)
 img.paste(portrait,(ax+5,ay+5),portrait)
 color=colors[k%len(colors)]
 d.rectangle((ax+2,ay+2,ax+iw*cell-3,ay+ih*cell-3),outline=color,width=2)
d.text((62,477),'10 columns × 6 rows  •  filled rectangle = occupied cells',font=font,fill=(214,198,166))
d.text((62,508),'Ring / amulet: 1×1   Sword: 1×3   Armor / robe: 2×3',font=small,fill=(176,192,212))
d.text((62,537),'Selection, placement and drag previews use the same dimensions.',font=small,fill=(162,182,173))
# guide on right
d.line([(604,146),(604,559)],fill=(85,73,58),width=2)
x=637
d.text((x,155),'ITEM SIZE RULES',font=line,fill=(229,200,144))
for k,line_text in enumerate(['Ring / Amulet              1 × 1','Sword / Main Hand         1 × 3','Chest Armor / Robe        2 × 3','Staff (two-handed)        2 × 4','Wand / Focus              1 × 2','Belt                      2 × 1','Helmet / Gloves / Boots   2 × 2']):
 d.text((x,207+k*37),line_text,font=font,fill=(197,206,216))
d.text((x,511),'All sizes are width × height.',font=small,fill=(171,180,187))
d.text((46,617),'AOTL originals and model state preserved; no Path of Exile artwork is included.',font=small,fill=(160,160,160))
OUT.parent.mkdir(parents=True,exist_ok=True)
img.save(OUT,optimize=True)
Path('/mnt/data/AOTL_Inventory_Exact_Footprints_Preview_2026-11-11.png').write_bytes(OUT.read_bytes())
print(OUT)
