"""Compose a review PDF from the actual exported transparent PNGs."""
import json
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader

ROOT = Path(__file__).resolve().parents[1]
catalog = json.loads((ROOT/'catalog.json').read_text())
records = {r['index']: r for r in json.loads((ROOT/'EXPORT_REPORT.json').read_text())}
qa = json.loads((ROOT/'ART_QA.json').read_text())
output = ROOT/'AOTL_Art_Expansion02_Catalog_2026-11-12.pdf'
W,H = 1600,1100
c = canvas.Canvas(str(output),pagesize=(W,H))
c.setTitle('Age of the Lost — Art Expansion02')
c.setAuthor('AOTL development artwork review')
def text(x,y,s,size=22,color='#c2cad5'):
    c.setFillColor(HexColor(color));c.setFont('Helvetica',size);c.drawString(x,y,s)
def base(title,subtitle):
    c.setFillColor(HexColor('#0c1118'));c.rect(0,0,W,H,fill=1,stroke=0)
    text(46,1044,title,32,'#e8d09b');text(46,1006,subtitle,20)
    text(46,24,'AOTL / Original equipment and UI art / November 12, 2026 / Review candidates',15,'#8e9bad')
base('AGE OF THE LOST','Artwork Expansion 02 — equipment, abilities and interactions')
text(70,915,f"{len(records)} art candidates | 42 masters + 90 small icons | Godot 4.6.3 review project",27,'#e8d09b')
lines=[
    '42 new art candidates: 12 equipment variants, 19 implemented-ability icons, 11 service/interaction icons.',
    'The preceding 61-item taxonomy library remains available separately: 103 art candidates across both passes.',
    'Equipment keeps its actual inventory footprint. UI symbols use a presentation square, not inventory cells.',
    'Equipment exports use128pixels per cell; UI masters are512pixels with32,64 and128pixel derivatives.',
    'The90 smaller icon files are size variants of30 symbols and are excluded from the42-design count.',
    'All seven new source sheets were generated with OpenAI image_gen; provider/model limits are documented.',
    f"Technical image checks: {qa['passed']} / {qa['total']}. Native Godot and small-icon review captures are included.",
    'Stable IDs, game-ID mappings, source regions, image hashes, briefs and original sheets accompany the PNGs.',
    'No artwork is routed into gameplay yet. Material themes do not add rarity, levels, stats or scaling rules.',
    'The separate PC Knight fork is preserved. The optional arquebus in the earlier taxonomy remains unproduced.',
]
for k,line in enumerate(lines):text(70,840-k*48,line,23)
text(70,280,'Use the library',28,'#e8d09b')
for k,line in enumerate(['Open project.godot and press F5; left/right arrows browse the native review.',
                         'runtime_items/ holds equipment and icon masters; runtime_sizes/ holds small UI textures.',
                         'README.md explains export, alpha checks, source reconciliation and gameplay-integration boundaries.']):
    text(70,228-k*42,line,23)
c.showPage()
entries = [e for e in catalog['entries'] if e['index'] in records]
for offset in range(0,len(entries),6):
    page=offset//6+1
    base('ARTWORK CANDIDATES',f"Art sheet {page} / {(len(entries)+5)//6} | Equipment dimensions are width x height")
    for n,e in enumerate(entries[offset:offset+6]):
        col,row=n%3,n//3;x=42+col*520;y=522-row*470
        c.setFillColor(HexColor('#151d27'));c.setStrokeColor(HexColor('#675a43'));c.rect(x,y,500,448,fill=1,stroke=1)
        text(x+18,y+412,e['name'],24,'#e8d09b')
        text(x+18,y+384,e['group'].replace('_',' '),17,'#aab5c5')
        cw,ch=e['cells'];unit=76 if e['kind']=='equipment' else 256;gw,gh=cw*unit,ch*unit;gx=x+(500-gw)/2;gy=y+66+(304-gh)/2
        for yy in range(ch):
            for xx in range(cw):
                c.setFillColor(HexColor('#070d13'));c.setStrokeColor(HexColor('#5d5647'));c.rect(gx+xx*unit,gy+yy*unit,unit,unit,fill=1,stroke=1)
        c.drawImage(ImageReader(str(ROOT/records[e['index']]['output'])),gx,gy,width=gw,height=gh,mask='auto')
        text(x+18,y+38,(f"{cw} x {ch} inventory cells" if e['kind']=='equipment' else '512px UI master / 32, 64, 128px included'),17,'#b4c9a7')
        text(x+18,y+16,e['asset_id'],12,'#8f9daf')
    c.showPage()
base('NATIVE SMALL-ICON REVIEW','Rendered in Godot 4.6.3 at actual32 /64 /128pixel sizes')
capture=ROOT/'previews/icon_scale.png'
if capture.exists():c.drawImage(ImageReader(str(capture)),160,70,width=1280,height=880,mask='auto')
c.showPage();c.save();print(output.name,output.stat().st_size)
