# AOTL Warrior V07 — Sculpt / Packed Materials, Native Godot Handoff
**November 13, 2026 — experimental, unmerged.**

## Windows test
1. Extract `AOTL_V07_Windows_Runtime_2026-11-13.zip` and open `game/crownsfall_lootslice/project.godot` in **Godot 4.6.3**.
2. Let the imported models and textures finish loading.
3. From the extracted ZIP root run (replace `godot` with your Godot exe path if necessary):

   `godot --path game/crownsfall_lootslice res://scenes/two_point_five_d/aotl_25d_lab.tscn -- --aotl-v07`

4. Press **V** to compare original approved painted Warrior → textured 58-bone V07 → original geometric proxy. Mouse wheel 14–28 orthographic span; **Home** restores 21.0. **Hold right mouse** to keep combat facing while strafing/backpedaling.
5. No changes to the original saved main game; its original painted art remains the default.

## Actual Higgsfield work
- 3D Jutsu **revision 17**, an editable Blender 5.2 source and matching portable GLB.
- 58 existing joints and a 23-section exported reel preserved.
- Three sculpt batches: Phase 1A **six** armor/tunic pieces (322 vertex adjustments), Phase 1B **twelve** cape/tabard pieces (141), Phase 1C **six** boot pieces (128); **24 meshes / 591 changed vertex positions** overall. All original meshes retained as fake-user backup datablocks or via Higgsfield historical revisions.
- Phase 2: **12 packed, 128×128 painted-style PNG maps** and duplicated material variants; **60 UV-mapped mesh objects** including steel, gold, worn leather, skin, hair, cape, and shield. Unlike Blender procedural nodes, these are embedded in the portable GLB.
- Higgsfield GPT Image 2.6 free unlimited look-development image job `a0a25c1e-6334-4d33-beff-b6885c9d505e` was used as an **experimental material concept** only, not the actual skinned game model or approved canon art. **Paid credits used: 0**.
- Verified V07 GLB SHA-256: `a3bd395ea0fb01d3465cc18a31ed4c7ee7ce850359d3658ddae74168172a1425`. 12 textures, 58 joints. Restore with `tools/restore_rig_v07.py` from five GitHub-stored base64 parts. Earlier V02–V06 binaries are unchanged.

## Automated evidence — GitHub Actions run 43354708379
- **77/77** V07 mesh/material import, 58 bones, 23 clips, sockets, movement/IK, camera and exposure checks.
- **32/32** original Phase02 painted-world camera checks.
- **954/954** gameplay regression assertions across the original 16 suites.
- Planted-ankle mean horizontal offset **0.0726 m across 38 sampled stance frames**; V06 previous ~0.0738 m under corresponding test.
- Source-screen exposure guard: **0.00/0.00 average/max RGB difference** at static sampled world points; Blender studio lights and camera stay disabled in gameplay.
- **21 real 1440×810 Godot screenshots** plus nine-frame walking and six-frame strafing GIFs. At 21.0 orthographic span V07 is still noticeably less ornate than original painted Warrior; at 14.0 zoom the simplified face/anatomy remain visible.
- Native test host was headless Linux with virtual OpenGL; **Windows GPU gameplay and animator review have not been performed**.

## Production quality gate
This is a **validated textured prototype**, **NOT** an approved final AAA Warrior. It retains low-detail procedural silhouette, simplified hair/face, rounded armor, and largely rigid cape folds. The latest material maps improve color/roughness separation but do not achieve the six canonical painterly-anime character sheets. Do not swap the main default away from painted art or derive 13 classes from this mesh yet.

**Next major art investment:** hand-authored/refined high-resolution basemesh/retopology matching canonical proportions; distinct armor panel topology; facial hair planes; anatomical deformation shape keys; and rigorous PBR-to-painterly texture baking. Free Higgsfield image references can help look-development but don't themselves create an editable skinned replacement mesh.

## Sources and handoff
- [GitHub V07 draft PR #33](https://github.com/mlyons0990/age-of-the-lost/pull/33)
- [Higgsfield V07 editable scene revision 17](https://higgsfield.ai/3d-jutsu/088e8199-50e8-4554-b0be-b108a6b2203a)
- Higgsfield Developer Files archive `AOTL_V07_Higgsfield_r17_Editable_Rig_Materials_2026-11-13.zip` (confirmed media ID `8ce43ad5-8f81-4ada-83d3-f0a18f69724f`).
- Google Drive AOTL / Art_Production_2026-11-12 / Phase03_V07_Sculpt_Materials_2026-11-13 contains the runtime ZIP, QA ZIP, motion GIFs and painted/3D comparison.
