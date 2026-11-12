"""Rebuild the briefing portrait from its retained Higgsfield source (Pillow)."""
from pathlib import Path
import argparse,hashlib,json

def build(root):
 from PIL import Image
 source=root/'assets/higgsfield_sources/cantor_portrait_source.png'
 target=root/'assets/encounter/cantor_portrait.png';target.parent.mkdir(parents=True,exist_ok=True)
 with Image.open(source) as image:
  assert image.size==(2048,2048)
  image.convert('RGB').resize((512,512),Image.Resampling.LANCZOS).save(target)
 record={'job_id':'ea670ac5-a3fe-42e8-a6c0-5fcf33326583','model':'gpt_image_2_6','use_unlim':True,'quality':'medium','resolution':'2k','aspect_ratio':'1:1','source':str(source.relative_to(root)),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'runtime':str(target.relative_to(root)),'runtime_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'runtime_size':[512,512],'purpose':'Accepted Cantor briefing portrait; inherited Revenant body remains the world actor.','prompt':'A single square painted dark fantasy action RPG boss portrait for Age of the Lost, old royal gothic style, grounded and readable at small size. The Unwritten Cantor: a faceless revenant inside a cracked charcoal iron ceremonial helmet, a fractured bronze crown of seven uneven tines, a thick dark crimson and desaturated indigo mantle, pale parchment strips and three suspended stone seals, violet-white light in the empty helmet. Upper body centered fills frame with clear silhouette. Background near-black navy with a faint broken circular rune; restrained antique gold edge glow. Hand-painted rich material texture, dramatic warm side lighting, atmospheric but crisp focal details, no photo realism, no cute styling, no text, no letters, no watermark, no interface, no multiple panels. Square image is a portrait only, not a sprite sheet.'}
 (root/'data/cantor_art_manifest.json').write_text(json.dumps(record,indent=2))
 print('Rebuilt 512px portrait:',record['runtime_sha256'])
if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parent.parent)
 build(parser.parse_args().project.resolve())
