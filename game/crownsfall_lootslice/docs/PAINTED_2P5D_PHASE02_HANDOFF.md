# AOTL Painted 2.5D — Phase 02: Wide Isometric Camera & Crownsfall World

**Updated November 12, 2026. This is experimental source; the main Godot game and all save data are unchanged.**

## Camera change (requested PoE-style zoom)

The independent 2.5D art lab now starts at orthographic vertical size **21.0**, up from **14.5**. The original character sprite has a source-image height of about 2.04 world metres, so it occupies **~31% fewer vertical screen pixels** at the same resolution, making the view feel closer to Path of Exile's broad environmental framing. This is a **tunable visual approximation**, not an assertion that Path of Exile uses this exact camera value. Camera look-down angle is preserved; the follow-camera also looks ~1.8m ahead toward the distant gate so the character stays slightly below center and the walkable scene ahead is visible.

Controls: mouse wheel zoom; **-** zoom out; **+ / =** zoom in; **Home** reset to 21m; **P** hide/show reference artwork; **V** original 58-bone 3D proxy vs painted sprite; **Tab** Warrior vs Mage; WASD/click move; Shift sprint; Space dodge; 1/2 attack; 3 cast. Runtime camera range clamps to 14m–28m. Original F5 main game remains unchanged; press F6 *from the experimental scene*.

## Reused original approved AOTL assets

The 27 existing original knight/mage sprite strips remain exact, unchanged PNGs. The 58-bone proxy remains available as a comparison toggle. The original six canon boards and `assets/plaza.png` remain untouched; `P` shows the approved artwork as a comparison panel rather than projecting it incorrectly onto 3D terrain. Original slash/cast particle system and test dummies are reused.

## New environmental prototype

New `scripts/two_point_five_d/crownsfall_courtyard_25d.gd` builds a **60m × 60m** stone courtyard with batched MultiMesh limestone paving, pale ivory stone citadel arch, royal blue banners and simplified gold crest shapes, a raised fountain, market stall, flowers, hedges, trees, gilded lanterns and warm daylight. Decorative objects are original procedural geometry, not paid meshes or altered game art. The world is a **stylized blockout**, not a finished match for the Crownsfall reference painting; no false claim of high-fidelity textured architecture.

Solid stone columns, side walls, planters and fountain support temporary 3D collision. These collision primitives have not been navigation-baked or evaluated as a finished level layout. Painted characters remain Sprite3D billboards in a `CharacterBody3D` with the already-verified five source facings / eight directions. No saved gear appearance or game combat rules are changed.

## Foot-contact and dodge prototypes

New `data/25d_sprite_foot_anchors.json` records first-frame alpha bounds from the existing 27 original painted strips. On each state/sprite change, the visual origin is recalibrated using the actual sheet dimensions, reducing unwanted vertical pops between 384px idle/walk/cast and 512px Warrior attack. The flat rectangular shadow is replaced by a softer vertex-alpha mesh. These improve groundwork for art alignment, not IK or foot planting.

Painted dodge uses a staged **anticipation/lean/compression/recovery proxy**, with consistent contact shadow and readable movement. **It is not a finished painted dodge roll** because no original illustrated eight-direction roll frames exist. The 58-bone proxy remains available for physically articulated motion comparison. Future rollout needs artist-approved directional roll sprites or a convincingly painterly skinned 3D character. Avoid using generic generated knight assets in place of the approved imagery.

## Running and verification

Start the existing project with **Godot 4.6.3**. Open `res://scenes/two_point_five_d/aotl_25d_lab.tscn` and press **F6**. In the project root run:

```bash
godot --headless --path . --script res://tests/two_point_five_d_smoke.gd
python3 tools/run_checks.py --report-dir /tmp/aotl-25d-phase02
```

The 2.5D smoke now also validates camera scale/limits, visibility of reference panel, Courtyard environment objects, 27 sprite feet metadata, shadow mesh and dodge proxy. No automatic edits to player saves or `main.tscn`.

## Known gaps before production integration

- Mesh rooftops, signage, cloth, roads, water and surrounding architecture still need actual 2026-level painterly textures, composition and level design, not just simplified 3D shapes.
- Painted sprite is intentionally billboarded. It cannot dynamically reflect full class equipment. Original `assets/item_portraits` are inventory art, not aligned on-body overlay layers. Equipment appearance needs directional sprite atlases per silhouette/rig for proper occlusion and animation.
- No user-art approved true dodge/landing frames, Warrior casting or shield animations. Prototype movement controllers are isolated from the main save-bearing world.
- Tests here cannot substitute for human review of visual composition, character scale in the 1440×810 live scene, or a Windows hardware run.
- Original GitHub main and prior experimental phase remain untouched until the results are evaluated.