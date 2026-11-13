# AOTL Phase 07 — Connected Crownsfall City, first playable expansion

**Status:** experimental, *not* a completed massive city. **Date:** 13 November 2026. Base: Phase 06.1. Godot: 4.6.3. No paid Higgsfield credits.

## What was actually built

- Royal Promenade joins the Central Plaza **inside the original playable Godot scene** rather than in a duplicate level or invented overworld. The entrance is the southern portal at original world pixels `(2070,1536)`. The same `NavigationServer2D` map covers the original walkable polygon and a newly triangulated connected second region.
- `assets/25d/crownsfall_royal_promenade_v07.png` is a preliminary 1500×1410 street-art extension, using palette elements and several crops from the user's actual original approved Crownsfall plaza. It is **not** final-quality hand-painted concept art, and makes no claim to match the provided beautiful screenshot in full.
- A `crownsfall_royal_promenade_3d_v07.gd` procedural rendering layer provides **12 modular Gothic facades**, lanterns, avenue gate arch and 3D street floor. Textures reuse real details from the approved painting. These are visual stand-ins, **not shipping buildings**. Buildings are outside the authoritative walking strip, avoiding unmodeled dynamic 3D/2D navigation collisions.
- `main.gd` remains the saved-game authority. The same Player, inventory, vendors, Reality Scar quests, class/skill systems and schema-six files remain unchanged. The main camera tracks the added ground when the player walks south. `F8` still switches the original painted view to the hybrid 3D view; `F10` opts into painted-knight true-depth occlusion.
- Current game **does not persist exact player coordinates by design**; on reload players return to the original plaza. This is inherited from original schema-six behavior, not newly invented or falsely described as persistence.

## Rig progress and directional dodge

- Higgsfield 3D Jutsu master humanoid, revision 12, contains 58 armature bones and eight separately keyed 24-frame dodge actions: `AOTL_Dodge_N`, `NE`, `E`, `SE`, `S`, `SW`, `W`, `NW`. Later revision 15 adds a small raised gold sun-crown crest on the royal-blue cloak. These are art-direction and animation foundations, **not yet an approved faithful full 3D Royal Wayfarer**.
- The automated 3D Jutsu quick GLB contains only one exported animation named after the rig. We explicitly tested Blender 5.2 export with `export_animation_mode='ACTIONS'`: it produced all 34 actions, including eight dodge clips, in a 1.999 MB GLB *inside the 3D Jutsu sandbox*. This repo includes the tested independent export helper. The editable `.blend` remains available in the user's 3D Jutsu project; do not mistake the quick GLB for the all-clips GLB.
- The main 2D source-painted Warrior **does not yet have newly illustrated directional roll sprite frames**. The eight Dodge actions currently live in the separate 3D Blender rig only; they are not wired as production 2D rolls. No unreviewed AI art substituted for source artwork.

## Test status

- Godot 4.6.3 imported the Phase 07 project with no parse errors.
- Dedicated `tests/crownsfall_royal_promenade_v07_integration.gd` tests **22/22** passed, including exact 2D NavServer path from the original entrance to `(2230,2420)`: `[2070,1440] → [2079.796,1500] → [2082.46,1516.316] → [2085.674,1536] → ... → [2230,2420]`.
- Original game regression `tools/run_checks.py` **954/954** assertions across 16 suites passed, using isolated Linux user folders.
- Real Godot Xvfb/llvmpipe OpenGL rendered full 1440×810 screenshot of both original painted and live 2.5D district. Windows performance still untested.

## Stage gates for the complete Crownsfall city

1. Fix modular architectural silhouette and render quality to be indistinguishable from approved city concept at gameplay scale.
2. Add each city quarter incrementally with a **real connected NavServer2D region**, corresponding 3D terrain polygon, verified collision outside existing walk paths, optional authored occlusion, usable quest/NPC interactions.
3. Bring all NPCs and mobs into the same F10 depth pipeline as the main knight.
4. Create original eight-direction painted roll or a fully art-matched rigged 3D character and retarget its animations. No more generic mannequins substituted for approved Royal Wayfarer.
5. Real Windows and 1080p/1440p performance, frame-time, save validation; only then decide on F8 default and city-complete acceptance.
6. Do not build any new wilderness zones before city acceptance.

**Testing:** unzip full source into a *new folder*, open `game/crownsfall_lootslice/project.godot`, F5, follow the southern main gate, F8 compare city environments, F10 see painted knight in real 3D depth. Avoid overwriting existing working saves.
