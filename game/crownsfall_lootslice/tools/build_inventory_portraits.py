#!/usr/bin/env python3
"""Produce AOTL-only transparent portraits sized to the *runtime* inventory footprint.

Inputs: existing editable AOTL icon SVGs / accepted AOTL Mage painted icons.
Outputs: assets/item_portraits/<item_slot>.png, plus the unique circlet.

This is a deterministic artwork-preparation step, not a change to inventory geometry.
The GDScript source (Systems.FOOTPRINTS) remains the authority for occupied cells.
"""
from pathlib import Path
from PIL import Image, ImageChops, ImageFilter, ImageOps
import io, re, math, json
import numpy as np
import cairosvg

ROOT = Path(__file__).resolve().parents[1]
ICONS = ROOT/'assets/icons'
PAINTED = ROOT/'assets/painted_icons'
DEST = ROOT/'assets/item_portraits'
DEST.mkdir(parents=True, exist_ok=True)
FOOTPRINTS = {'weapon':(1,3),'offhand':(2,2),'helm':(2,2),'armor':(2,3),'gloves':(2,2),'belt':(2,1),'boots':(2,2),'amulet':(1,1),'ring':(1,1),'staff':(2,4),'wand':(1,2),'focus':(1,2),'robe':(2,3),'hood':(2,2),'wraps':(2,2),'slippers':(2,2),'emberwake_circlet':(2,2)}


def vector_foreground(slot):
    source = (ICONS/(slot+'.svg')).read_text()
    # Preserve only the existing original artwork's <g> silhouettes. The old card
    # background / corner detail is intentionally excluded: the grid is the card.
    defs = re.search(r'<defs>.*?</defs>',source)
    group = re.search(r'<g\b.*?</g>',source)
    if not group: raise RuntimeError('Missing vector glyph '+slot)
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 128 128">'+(defs.group() if defs else '')+group.group()+'</svg>'
    return Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert('RGBA')


def painted_foreground(slot):
    src = np.asarray(Image.open(PAINTED/(slot+'.png')).convert('RGB')).astype(np.float32)
    # The supplied portraits have an AOTL navy studio backdrop. Subtract only that
    # nearly black backdrop; never extract from a third-party screenshot.
    top = np.concatenate((src[:10,:10,:].reshape(-1,3),src[:10,-10:,:].reshape(-1,3),src[-10:,:10,:].reshape(-1,3),src[-10:,-10:,:].reshape(-1,3)))
    bg = np.median(top,axis=0)
    diff = np.linalg.norm((src-bg) * np.array([1.0,0.92,0.9]),axis=2)
    brightness = src.max(axis=2)
    # Remove dark navy while retaining the jeweled/colorful foreground.
    alpha = np.clip((diff-12.0)/45.0,0,1)*np.clip((brightness-24.0)/40.0,0,1)
    array = np.concatenate((np.uint8(np.clip(src,0,255)),np.uint8((alpha*255).round())[:,:,None]),axis=2)
    return Image.fromarray(array,mode='RGBA')


def portrait_image(source, shape, slot):
    width,height=shape
    # AOTL inventory cell sprite 64px, using fully transparent image edges.
    output = Image.new('RGBA',(width*64,height*64),(0,0,0,0))
    if slot in ('staff','wand'):
        # Existing Mage illustrations are diagonally posed; straighten them for
        # vertical 2x4 and 1x2 backpack silhouettes (without stretching a square).
        source = source.rotate(45,resample=Image.Resampling.BICUBIC,expand=True)
    a=source.getchannel('A')
    a=a.point(lambda v:255 if v>=25 else 0)
    bounds=a.getbbox()
    if not bounds: raise RuntimeError('Empty silhouette '+slot)
    source=source.crop(bounds)
    # 4px gutters at each edge; the tall icon really fills its vertical slot.
    inner_w,inner_h=width*64-12,height*64-12
    ratio=min(inner_w/source.width,inner_h/source.height)
    target=(max(1,round(source.width*ratio)),max(1,round(source.height*ratio)))
    source=source.resize(target,Image.Resampling.LANCZOS)
    output.alpha_composite(source,((output.width-target[0])//2,(output.height-target[1])//2))
    return output


def main():
    records={}
    for slot,shape in FOOTPRINTS.items():
        chosen='painted' if (PAINTED/(slot+'.png')).is_file() else 'vector'
        image=painted_foreground(slot) if chosen=='painted' else vector_foreground(slot)
        result=portrait_image(image,shape,slot)
        path=DEST/(slot+'.png')
        result.save(path,optimize=True)
        assert result.size == (shape[0]*64,shape[1]*64)
        records[slot]={'cells':list(shape),'pixels':list(result.size),'source':chosen}
    (ROOT/'data/item_portrait_catalog.json').write_text(json.dumps({'cell_pixels':64,'footprints':records,'note':'Grid dimensions come from scripts/systems.gd, not images.'},indent=2)+'\n')
    print('Created',len(records),'inventory portraits in',DEST)

if __name__=='__main__': main()
