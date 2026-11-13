# AOTL V07 Phase 1A — first sculpt checkpoint

**Date:** November 13, 2026. **Scene:** [Higgsfield 3D Jutsu project](https://higgsfield.ai/3d-jutsu/088e8199-50e8-4554-b0be-b108a6b2203a), model revision **13**. **Git branch:** `dev/humanoid-v07-silhouette-sculpt-2026-11-13`.

The [formal V07 Phase 1 sculpt worksheet](./V07_PHASE1_WARRIOR_SILHOUETTE_SCULPT_WORKSHEET.md) maps 16 sculpting targets to exact mesh names, source bone groups, proposed shape changes and acceptance criteria.

## Implemented in Phase 1A (draft geometry, not yet visually approved)

- Symmetrical pauldron metal `V02_GEAR_ShoulderPlateL/R`: 45 changed vertices **per side**, max vertex delta **1.619 cm**.
- Symmetrical gold shoulder rims `V02_GEAR_ShoulderRimL/R`: 24 changed vertices **per side**, max vertex delta **1.996 cm**.
- `V02_GEAR_LayeredCuirass`: 106 vertices changed, maximum **0.956 cm**, with subtle upper-chest widening and lower-waist narrowing.
- `V02_SKIN_FittedTunic`: 78 vertices changed, maximum **0.368 cm**, for a mild under-armor waist taper.
- **322 vertices** across **six existing objects** altered, without modifying bone transforms, armature vertex groups, material assignments, game data or animation clips.
- Each original mesh datablock is preserved in the Blender file as a fake-user `V06_R12_BACKUP__*` datablock for exact reversal. The project revision history also retains original revision 12.
- Script: `game/crownsfall_lootslice/tools/v07_phase1a_silhouette.py`.
- Before/after **480×560** close comparison and **960×540** exact PoE-wide (orthographic span 21.0) renders were captured in Higgsfield with the same camera and pose.

## What the renders actually show

A modest contour and taper improvement; the model is still rounded, rudimentary and noticeably different from the approved painterly anime Warrior. **This is only the initial P0 geometry trial**, not finished art or a production-quality humanoid. Shoulder armor remains too spherical. Bigger, more purposeful armor topology / sculpt work is required.

## Verified versus pending

- **Verified in Blender:** 58 bones unchanged, `AOTL_Reel_V06` still active, 34 Blender action datablocks preserved, mesh count still 91, original input geometry reversible, no paid Higgsfield credits used.
- **Not yet verified in Godot:** updated V07 GLB import, 23 named clips, 7 mounts, IK performance, character clipping, 21m camera screenshot/exposure and 954 gameplay regressions. Do **not** merge into the saved main game or call Phase 1 accepted.
- **Next batch:** S05–S09 cape/cloth and S10–S11 shaped boot-toe silhouette, then evaluate sculpt quality at 21m and 14m before full V07 export and runtime QA.

## Commands and links

- [Editable Higgsfield scene, current V07 revision](https://higgsfield.ai/3d-jutsu/088e8199-50e8-4554-b0be-b108a6b2203a)
- [V07 worksheet](./V07_PHASE1_WARRIOR_SILHOUETTE_SCULPT_WORKSHEET.md)
- To reproduce in local Blender 5.2 from V06 source: open original blend, run `tools/v07_phase1a_silhouette.py`. It intentionally refuses to run twice.
