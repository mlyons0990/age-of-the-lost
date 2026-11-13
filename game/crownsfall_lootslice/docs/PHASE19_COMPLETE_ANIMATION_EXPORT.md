# AOTL Phase 19 — Higgsfield Master Rig Six-Animation Export

The Phase 18 3D lab and production 2D Crownsfall remain untouched. New isolated F12 viewer only; saves, 12×5 backpack, HUD, gameplay cameras remain intact.

## Main milestone
The Higgsfield master humanoid project 088e8199-50e8-4554-b0be-b108a6b2203a, revision 38, has six Blender actions: Idle, Walk, Run, Slash, Dodge, Cast. The normal scene-builder quick GLB bundled these as only one clip. Using the editable .blend with Blender 5.0.1 export_animation_mode=ACTIONS and export_merge_animation=NONE produced an actual six-clip GLB with 62 skin joints, 89 meshes and 26 materials.

Confirmed Higgsfield-hosted artifact:
https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/306cda02-51cd-499d-9601-6b87064886f3.zip

Install: extract AOTL_Master_Rig_R38_Six_Animations.glb from the separate ZIP, rename it AOTL_Master_Rig_R38_AllSix.glb, and place in game/crownsfall_lootslice/models/. Import in Godot. Binary is NOT embedded in the full-source ZIP or GitHub PR.

Use: F5 original game; scene scenes/rig_lab_3d.tscn runs independent lab; F12 opens master rig viewer; keys 1–6 Idle/Walk/Run/Slash/Dodge/Cast; F7 or Esc returns. Missing GLB shows installation guidance.

## Tests
- glTF binary: six distinct named animations, 62 skinned joints.
- Godot 4.4.1 isolated full import: all six clips imported, each with 15 nonzero tracks, bone count 62.
- Phase19 viewer script Godot 4.4.1 isolated runtime: 17/17 assertions with model, 5/5 fallback assertions without optional GLB.
- Visual quality, IK, deformation, Godot 4.6.3 Windows still require approval. Blender 5.0.1 read editable 5.2 file with compatibility warning; the 5.2 project remains source authority.

No character replacement, no save changes, no dropped legacy animations. Paid Higgsfield generation credits spent: zero.