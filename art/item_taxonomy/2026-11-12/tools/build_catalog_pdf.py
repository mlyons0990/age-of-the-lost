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
output = ROOT/'AOTL_Item_Taxonomy_Art_Catalog_2026-11-12.pdf'
W,H = 1600,1100
c = canvas.Canvas(str(output),pagesize=(W,H))
c.setTitle('Age of the Lost — Item Taxonomy Artwork')
c.setAuthor('AOTL development artwork review')
def text(x,y,s,size=22,color='#c2cad5'):
    c.setFillColor(HexColor(color));c.setFont('Helvetica',size);c.drawString(x,y,s)
def base(title,subtitle):
    c.setFillColor(HexColor('#0c1118'));c.rect(0,0,W,H,fill=1,stroke=0)
    text(46,1044,title,32,'#e8d09b');text(46,1006,subtitle,20)
    text(46,24,'AOTL / Original equipment art / November 12, 2026 / Review candidates',15,'#8e9bad')
base('AGE OF THE LOST','Expanded equipment taxonomy artwork')
text(70,915,f"{len(records)} equipment candidates | 128 pixels per inventory cell | Godot 4.6.3 review project",27,'#e8d09b')
lines=[
    'The uploaded PC AOTL files and exact-footprint handoff were reviewed before production.',
    'Coverage: melee, ranged, caster, off-hand, jewelry, cloth, leather, mail and plate equipment.',
    'Each card shows the PNG at its proposed width x height over square inventory cells.',
    'Swords are 1 x 3 vertical; rings and amulets are 1 x 1; chest pieces are 2 x 3; belts are 2 x 1.',
    'These are art-library candidates. The game still uses its existing implemented item definitions.',
    'No gameplay, stat scaling, classes, saves or item categories are unlocked by this library.',
    f"Technical image checks: {qa['passed']} / {qa['total']}. Native review screenshots are included in the ZIP.",
    'Original Higgsfield sources, selected crop regions, generation logs and file hashes are preserved.',
    'The prior five paintings and Art Pass01 package remain separate references and rollback options.',
    'Optional arquebus remains unproduced after two rejected mixed-sheet jobs. No loose-gem category is added.',
]
for k,line in enumerate(lines):text(70,840-k*48,line,23)
text(70,280,'Use the library',28,'#e8d09b')
for k,line in enumerate(['Open project.godot and press F5; left/right arrows browse the native review.',
                         'runtime_items/ holds the selected textures; catalog.json and EXPORT_REPORT.json map every asset.',
                         'README.md explains export, alpha checks, source reconciliation and gameplay-integration boundaries.']):
    text(70,228-k*42,line,23)
c.showPage()
entries = [e for e in catalog['entries'] if e['index'] in records]
for offset in range(0,len(entries),6):
    page=offset//6+1
    base('EQUIPMENT ART CANDIDATES',f"Art sheet {page} / {(len(entries)+5)//6} | Grid dimensions are width x height")
    for n,e in enumerate(entries[offset:offset+6]):
        col,row=n%3,n//3;x=42+col*520;y=522-row*470
        c.setFillColor(HexColor('#151d27'));c.setStrokeColor(HexColor('#675a43'));c.rect(x,y,500,448,fill=1,stroke=1)
        text(x+18,y+412,e['name'],24,'#e8d09b')
        text(x+18,y+384,e['group'].replace('_',' '),17,'#aab5c5')
        cw,ch=e['cells'];unit=76;gw,gh=cw*unit,ch*unit;gx=x+(500-gw)/2;gy=y+66+(304-gh)/2
        for yy in range(ch):
            for xx in range(cw):
                c.setFillColor(HexColor('#070d13'));c.setStrokeColor(HexColor('#5d5647'));c.rect(gx+xx*unit,gy+yy*unit,unit,unit,fill=1,stroke=1)
        c.drawImage(ImageReader(str(ROOT/records[e['index']]['output'])),gx,gy,width=gw,height=gh,mask='auto')
        text(x+18,y+38,f"{cw} x {ch} cells | {records[e['index']]['review_status'].replace('_',' ')}",17,'#b4c9a7')
        text(x+18,y+16,e['asset_id'],12,'#8f9daf')
    c.showPage()
base('NATIVE GODOT REVIEW','Rendered in Godot 4.6.3 using the supplied project; 49 pixels per cell')
capture=ROOT/'previews/grid_01.png'
if capture.exists():c.drawImage(ImageReader(str(capture)),160,70,width=1280,height=880,mask='auto')
c.showPage();c.save();print(output.name,output.stat().st_size)
