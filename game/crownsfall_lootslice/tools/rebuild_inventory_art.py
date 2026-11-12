"""Rebuild the original Higgsfield stone/bronze inventory backplate (Pillow)."""
from pathlib import Path
import argparse,hashlib,json

def build(root):
 from PIL import Image
 source=root/'assets/higgsfield_sources/inventory_backplate_source.png';target=root/'assets/ui/inventory_backplate.jpg'
 with Image.open(source) as image:
  assert image.size==(1360,2048)
  image.convert('RGB').resize((680,1020),Image.Resampling.LANCZOS).save(target,quality=94,subsampling=0,optimize=True)
 record={'job_id':'85ac0717-b195-4cff-be49-f527065e88dd','model':'gpt_image_2_6','use_unlim':True,'quality':'medium','resolution':'2k','aspect_ratio':'2:3','source':str(source.relative_to(root)),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'runtime':str(target.relative_to(root)),'runtime_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'runtime_size':[680,1020],'purpose':'Original carved slate and bronze UI backplate; all text, equipment slots, grids and interactions are live Godot controls.','prompt':'Original premium dark fantasy action RPG inventory panel BACKPLATE, vertical 2:3 proportion. A flat orthographic carved charcoal slate and blackened bronze architectural frame, antique muted gold trim, tiny cracked stone reliefs of original hooded crow-knights integrated into the far left and far right edges, subtle worn relief crown at the very top border, gothic carved finials in the four corners. The center 80 percent is almost plain VERY DARK charcoal slate, softly textured with fine age marks, perfectly flat and readable for overlaid small text and equipment. All sculptural detail is restricted to the OUTSIDE 8 percent border on each side, no bright central art. Refined, restrained, old royal craftsmanship, rich material definition, sober dark stone like a medieval crypt, faint warm glints. NO TEXT, NO LETTERS, NO NUMBERS, NO ITEMS, NO INVENTORY SLOTS, NO GRID, NO BUTTONS, NO ICONS, NO CHARACTER PORTRAIT, NO COLORFUL MAGIC, no trademark or recognizable existing game artwork. This is a new original UI background texture only, edge-to-edge rectangular composition, no perspective, no surrounding scene.'}
 (root/'data/inventory_art_manifest.json').write_text(json.dumps(record,indent=2));print('Rebuilt original backplate:',record['runtime_sha256'])
if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parent.parent);build(parser.parse_args().project.resolve())
