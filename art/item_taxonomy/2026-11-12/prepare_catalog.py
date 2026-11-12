from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parent;prior=json.loads((root/'PRIOR_SOURCE_MANIFEST.json').read_text())
briefs={
'sword':('Crownguard Sword','Upright straight silver longsword with an elegant antique-brass winged crossguard and a midnight leather grip; practical long narrow blade, ivory pommel.'),
'axe':('Wayfarer Axe','Single-headed forged steel hand axe with a crescent cutting edge, compact bronze socket, straight ashwood haft and worn brown leather grip; blade at top.'),
'mace':('Dawnkeeper Mace','Upright six-flanged blunt silver mace with bronze bindings, dark wine leather grip and ivory sunburst pommel. Read clearly as a functional mace.'),
'dagger':('Veilrunner Dagger','Point-up slim single-edged steel dagger with an engraved fuller, short curved brass crossguard and short charcoal-brown wrapped grip.'),
'fist_weapon':('Ironbriar Knuckle Guard','One empty wearable knuckle gauntlet: four spaced iron knuckle caps, a short crescent guard and dark oxblood leather wrist straps. No human hand.'),
'flail':('Bellward Flail','One oak-handled flail: a single continuous short iron chain joins the handle to exactly one heavy fluted iron ball. Arrange connected parts into a tall narrow silhouette.'),
'sceptre':('Votive Sceptre','Upright silver ceremonial cudgel with a solid ivory lantern-shaped flanged head, brass arches, red enamel center and dark leather grip; a sacred melee sceptre, not a long staff.'),
'short_spear':('Borderwatch Short Spear','Straight ashwood short spear, a leaf-shaped forged steel point at top, small tied moss-green pennant, worn brown grip and brass butt cap.'),
'greatsword':('Oathkeeper Greatsword','Large upright two-handed silver greatsword with a broad tapered blade, long dark leather two-hand grip, swept bronze crossguard and a restrained ivory crest.'),
'greataxe':('Deepforge Greataxe','Large upright two-handed greataxe with one broad asymmetrical iron head, a hooked balancing spine, heavy dark ash haft and reddish leather bindings.'),
'greatmace':('Citadel Maul','Large upright two-handed maul, blocky forged iron striking head with beveled faces and small brass corner braces, long ashwood haft and double wrapped grip.'),
'polearm':('Gatewarden Halberd','Long upright halberd with one leaf point, a crescent axe blade and a short opposing hook, all joined to one straight wooden shaft by a sturdy socket.'),
'quarterstaff':('Waywood Quarterstaff','Straight narrow hardwood quarterstaff, no spell orb and no blade; visible wood grain, two dark leather hand grips and simple iron ferrules at both ends.'),
'war_staff':('Sunforge War Staff','Heavy upright combat staff with bronze-capped striking ends, a segmented black iron collar and two brown leather grips; martial blunt weapon, no floating crystal.'),
'bow':('Ranger Ash Bow','Complete medium-height curved ashwood bow, intact taut bowstring joining both tips, leather central grip and small bronze nock fittings; upright slender profile.'),
'longbow':('Farwatch Longbow','Very tall slender yew longbow, nearly straight elegant limbs, continuous taut bowstring, dark wrapped grip, understated moss-green cloth tie and ivory nocks.'),
'recurve_bow':('Moonwillow Recurve','Strong readable recurved bow with ivory horn limb tips, warm laminated wood, a continuous taut bowstring and compact dark leather grip; clearly different from longbow.'),
'crossbow':('Caravan Crossbow','Compact medieval crossbow seen from above at a slight three-quarter angle, upright wooden stock, horizontal steel prod and continuous string, working lever and brass trigger housing.'),
'heavy_crossbow':('Bastion Arbalest','Heavy two-handed medieval arbalest with a long oak stock, thick steel bow assembly, taut string, cranking gear and a sturdy metal stirrup. Tall heavy silhouette.'),
'hand_crossbow':('Veilmark Hand Crossbow','Small single-hand crossbow with short walnut pistol-shaped grip, small paired steel limbs, taut string and a compact mechanical trigger; no modern rails or firearm magazine.'),
'arquebus':('Emberlock Arquebus','Optional future item: original early matchlock arquebus, upright long walnut stock and aged iron barrel, brass matchlock mechanism and wooden butt. No modern rifle features or bullets outside the gun.'),
'wand':('Cinderweave Wand','Upright slender short caster wand with warm dark wood, copper spiral bindings and an integrated amber flame-shaped finial, tiny controlled ember light rather than large effects.'),
'runic_wand':('Chronicle Rune Wand','Short upright pale ash wand capped with three joined brushed-silver geometric rings, a violet enamel inset and discrete abstract non-letter engravings. No readable writing.'),
'channeling_rod':('Aurelian Channeling Rod','Long narrow brass-and-ivory channeling rod with three connected architectural rings and a small contained blue magical light at the top; visibly longer than a wand.'),
'mystic_staff':('Epoch Staff','Tall upright midnight-and-gold Mage staff with a slim dark shaft and a circular astronomical brass crown around a contained sapphire-blue light; all parts physically connected.'),
'shield':('Frontier Round Shield','Weathered round iron-rimmed timber shield with a plain central bronze boss, deep burgundy painted wood and a few honest scratches; no giant gems or symbols from existing games.'),
'buckler':('Duelist Buckler','Small compact convex steel buckler with a raised central boss and narrow brass rim, rivets and worn steel; strongly distinguishable from large shields.'),
'tower_shield':('Gatehouse Tower Shield','Tall rectangular tower shield, rounded upper corners, aged silver iron rim and ivory painted wooden face with one original simple dark-blue branching arch motif. No words.'),
'kite_shield':('Royal Kite Shield','Point-down silver-and-ivory royal kite shield, antique brass edging, restrained dark royal-blue enamel heraldic arch and clear tapered medieval silhouette.'),
'spell_focus':('Riftglass Focus','Narrow upright handheld caster focus: a small brass astrolabe frame enclosing violet-blue light over a short wrapped handle; connected structure, readable compact silhouette.'),
'orb':('Aether Vessel','A complete small spherical spell vessel held within three connected brass meridian bands, contained pearl-blue glow and a sturdy base; a usable offhand artifact, not a loose gemstone or socket gem.'),
'tome':('Wayfarer Field Tome','Closed thick travel tome, aged brown leather, cream page block, iron corner guards and a practical brass clasp, slight three-quarter view; no legible writing or magical aura.'),
'grimoire':('Chronicle Grimoire','Closed ornate dark violet spellbook with ivory page edges, antique-gold hinged clasp and an original circular clockwork cover ornament. No legible text, no floating loose pages.'),
'catalyst':('Leyglass Catalyst','A narrow handheld silver cage with a contained aquamarine alchemical light, polished ivory handle and connected gold braces; a constructed magical instrument, not a loose gem.'),
'quiver':('Greenmarch Quiver','One compact warm brown leather quiver with a folded moss-green flap, brass strap buckles and exactly a small bundle of three feather-fletched arrows partly inside. No bow or body.'),
'totem':('Oldroot Totem','Tall narrow carved weathered dark-wood ritual staff fragment with one abstract tree-face relief, bound bronze rings and small hanging pale fabric strips. No person or creature body.'),
'idol':('Remembrance Idol','Small upright carved ivory-and-bronze abstract ceremonial figure, geometric faceless robed silhouette mounted on a solid oval base, fine age cracks and restrained turquoise enamel.'),
'fetish':('Reedbound Fetish','Small narrow ritual bundle of carved driftwood, braided cord, two clean pale bone charms and a few muted rust-colored feathers; all pieces tied together, not a floating collage.'),
'ring':('Sapphire Signet Ring','One complete three-quarter-view antique-gold signet ring with a deep royal-blue enamel face and a tiny incorporated sapphire inset, open ring hole clearly visible, restrained original arch crest.'),
'amulet':('Wayfarer Memory Sigil','One complete warm silver and brass amulet with a small ivory sundial pendant and a short joined chain loop, restrained original arch engraving, no readable writing or loose gem.'),
'belt':('Wayfarer Utility Belt','One horizontal broad worn brown leather belt arranged as a compact gentle arc, brass buckle centered, clearly joined ends, two small attached practical pouches; no waist or mannequin.'),
}
armor={
'cloth':('Aurelian','Cream linen and deep royal-blue woven fabric with restrained antique-gold embroidery, delicate silver fasteners, natural fabric folds and clearly stitched seams.'),
'leather':('Greenmarch','Supple warm chestnut and dark walnut leather with moss-green textile insets, practical brass rivets, reinforced stitching and natural leather grain.'),
'mail':('Watchguard','Fine interlocking steel chainmail with warm bronze edge fittings, a small muted burgundy textile lining and carefully joined metal links. Clearly mail, not plate or leather.'),
'plate':('Citadel','Articulated brushed silver plate with ivory enamel panels, restrained antique brass trim and dark leather joints; clear forged planes and practical overlapping plates.')}
parts={
'head':('Headguard','One empty wearable headpiece. Cloth uses a soft hood, leather a fitted hood and half-mask, mail a flexible chain coif, plate a closed sallet with a narrow visor. No head, hair, skin or mannequin.'),
'chest':('Vestments','One complete empty torso garment with shoulders, collar and waist visible. Cloth is an elegant long robe, leather a reinforced fitted jerkin, mail a chain hauberk, plate a fitted cuirass. No body, limbs or mannequin.'),
'gloves':('Handwraps','A neatly arranged pair of empty wearable hand coverings, one slightly overlapping the other, with all fingers coherent. Cloth wraps, reinforced leather gloves, chain-backed gloves or articulated plate gauntlets as appropriate. No hands or skin.'),
'boots':('Footguards','A neatly arranged pair of empty wearable boots, one slightly behind the other, toes and soles clearly defined. Soft cloth shoes, high leather boots, chain-topped boots or articulated plate sabatons as appropriate. No feet or legs.'),
'belt':('Girdle','One complete horizontal wearable belt with a centered functional buckle. Match the material family: woven cloth sash, leather straps, linked mail over a strap, or an articulated plate girdle. No body or mannequin.')}
base='Original Age of the Lost premium ARPG inventory artwork. Rich hand-painted anime-realistic high fantasy craftsmanship; believable material wear, warm directional highlights and crisp purposeful outer contours. A single equipment design, no extra variants. '
end=' Isolated on a genuinely transparent alpha background. Entire object visible, centered with generous padding. No floor or scene, no cast shadow, no background card or rectangle, no UI, no border, no labels or text, no watermark, no human or mannequin. Preserve instantly readable silhouette at small inventory size; avoid excessive micro-filigree and avoid turning every object blue and gold.'
records=[]
for i,row in enumerate(prior['planned'],1):
 group,kind=row['group'],row['type'];w,h=row['proposed_grid']
 if group.startswith('armor_'):
  mat=group[6:];part=kind.split('_',1)[1];prefix,material=armor[mat];suffix,description=parts[part];name=f'{prefix} {suffix}';description=description+' '+material
 else:
  name,description=briefs[kind]
  if kind=='sceptre' and group=='caster':name='Dawnscript Arcane Sceptre';description='Upright ivory-and-brass arcane sceptre with an open astronomical crown and a contained soft-violet light, slim dark wooden stem and short wrapped grip; caster instrument rather than melee mace.'
 orient='Horizontal broad silhouette.' if w>h else ('Upright vertical silhouette, top at image top and grip/bottom below.' if h>w else 'Compact balanced square silhouette, slight three-quarter view.')
 prompt=base+name.upper()+'. '+description+' '+orient+f' Compose specifically for {w} columns by {h} rows of square inventory cells, width by height; the object should use about 85 percent of the canvas in its long axis.'+end
 records.append({'index':i,'asset_id':f'aotl_{group}_{kind}_002','group':group,'type':kind,'name':name,'cells':[w,h],'prompt':prompt,'status':'planned','model':'gpt_image_2_6','params':{'quality':'medium','resolution':'1k','background':'transparent','output_format':'png','aspect_ratio':'3:2' if w>h else ('2:3' if h>w else '1:1')},'runtime_enabled':False})
(root/'catalog.json').write_text(json.dumps({'date':'2026-11-12','base_project':'Crownsfall_LootSlice schema6','source_manifest_count':62,'paid_credits_authorized':False,'allowance':'use_unlim=true','entries':records},indent=2))
(root/'PC_REVIEW.md').write_text('PC AOTL folder: 1idwSs7k1HUOgagQUgg-K7jjy9hMW1UU3. Inspected uploaded crownfall project tree, three original scripts, original HANDOFF, developer handoff and canonical class/world files. This is an earlier project baseline, not a replacement for the 749-check LootSlice. Reviewed source AI handoff art direction: painterly adult anime realism, original varied material silhouettes, sunny Crownsfall, correct variable inventory footprints, no extra character portrait, no loose gem item category. Excluded optional personal-memory file as irrelevant. Taxonomy source is the 62-slot prior art manifest; future types remain art-library entries, not gameplay unlocks. Duplicate sceptre families receive separate art IDs.\n')
print('Prepared',len(records),'distinct taxonomy art slots')
