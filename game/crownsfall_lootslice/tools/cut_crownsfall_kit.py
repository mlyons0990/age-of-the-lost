from PIL import Image, ImageDraw
import numpy as np, os, json
from scipy import ndimage
R='art/higgsfield_2026-11/crownsfall_kit/raw/'; O='game/crownsfall_lootslice/assets/kit/crownsfall/'
names={
 'props_market':['market_stall_fruit',None,'market_stall_cloth','covered_wagon','crate_stack','barrels_sacks'],
 'props_street':['lamppost_double','lamppost_single','banner_bracket','banner_pole','bench','notice_board'],
 'props_stone':['balustrade_straight','balustrade_corner','pillar_post','stone_urn','flower_planter','flower_pedestal'],
 'props_decor':['wall_banner_wisteria','banner_standard','crates_wisteria','flower_barrel','apple_basket','book_crates'],
 'foliage_trees':['tree_green','tree_blossom','tree_amber','hydrangea_bush','topiary_urn','sapling'],
 'foliage_decor':['hydrangea_blue','flower_white','wisteria_hang','ivy_hang','lavender','flower_basket'],
}
cat=[]
def trim(im,pad=4):
    a=np.array(im)[:,:,3]; ys,xs=np.where(a>8)
    return im.crop((max(xs.min()-pad,0),max(ys.min()-pad,0),min(xs.max()+pad+1,im.width),min(ys.max()+pad+1,im.height)))
for f in sorted(os.listdir(R)):
    k=f[:-4]; im=Image.open(R+f).convert('RGBA')
    if k not in names:
        t=trim(im); t.save(O+k+'.png'); cat.append({'id':k,'kind':{'bld':'building','lm':'landmark'}[k.split('_')[0]],'file':k+'.png','size':list(t.size)}); continue
    a=np.array(im)[:,:,3]>24
    lab,n=ndimage.label(ndimage.binary_dilation(a,iterations=6))
    H,W=a.shape; cells={}
    for i,sl in enumerate(ndimage.find_objects(lab),1):
        ys,xs=sl
        if (lab[sl]==i).sum()<300: continue
        c=int(((ys.start+ys.stop)/2)//(H/2))*3+int(((xs.start+xs.stop)/2)//(W/3))
        cells.setdefault(c,[]).append(i)
    for c,ids in sorted(cells.items()):
        nm=names[k][c]
        if nm is None: print('unnamed',k,c); continue
        m=ndimage.binary_dilation(np.isin(lab,ids)&a,iterations=2)
        arr=np.array(im); arr[:,:,3]=np.where(m,arr[:,:,3],0)
        t=trim(Image.fromarray(arr)); t.save(O+nm+'.png')
        cat.append({'id':nm,'kind':'foliage' if k.startswith('foliage') else 'prop','sheet':k,'file':nm+'.png','size':list(t.size)})
json.dump({'kit':'crownsfall','source':'Higgsfield A1 (2026-11-28), GPT Image 2.6 high, transparent','pieces':cat},open(O+'catalog.json','w'),indent=1)
print(len(cat))
fs=[c['file'] for c in cat]; cell=220; cols=10; rows=(len(fs)+cols-1)//cols
s=Image.new('RGB',(cols*cell,rows*cell),(46,52,60))
for i,f in enumerate(fs):
    p=Image.open(O+f); p.thumbnail((cell-10,cell-28))
    x=(i%cols)*cell+(cell-p.width)//2; y=(i//cols)*cell+4+(cell-28-p.height)//2
    s.paste(p,(x,y),p); ImageDraw.Draw(s).text(((i%cols)*cell+4,(i//cols)*cell+cell-18),f[:-4],fill=(255,230,150))
s.save('/tmp/claude-0/-home-user-age-of-the-lost/7d006b6b-5ba6-59a7-960e-a8220b91ea7c/scratchpad/a1_cut.png')
