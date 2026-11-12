# AOTL — Humanoid Master V03 in the approved PoE-wide camera

Experimental opt-in playable scene. The main saved game is unchanged. Tested with Godot 4.6.3.

## Windows instructions (standalone ZIP)
1. Extract the full ZIP and open game/crownsfall_lootslice/project.godot in Godot 4.6.3.
2. Allow all 3D model and PNG imports to finish.
3. Run this command from the extracted ZIP root in PowerShell or Command Prompt:

   godot --path game/crownsfall_lootslice res://scenes/two_point_five_d/aotl_25d_lab.tscn -- --aotl-v03

   If Godot is not on PATH, use the full path to your Godot executable.
4. Press V to cycle Painted Warrior -> V03 Humanoid -> Legacy Proxy. Scroll-wheel zoom 14–28m; Home resets 21m.
5. WASD/click move, Shift sprint, Space dodge, 1/2/3 attacks. Tab switches painted Warrior/Mage; V03 remains a Warrior-base visual.
6. F5 without special arguments still opens the original main 2D game. No original saves were modified.

## What is genuinely implemented
- 58-joint GLB with 16 split action clips and 1D Idle/Walk/Run blend tree.
- Seven gear/VFX BoneAttachment3D sockets.
- Left/right live terrain raycast and SkeletonIK3D foot solvers (prototype, not production-quality planted-feet).
- Refined royal sword, shield, cape and matte blue/gold armor meshes in Higgsfield revision 8.
- Source Blender scene: https://higgsfield.ai/3d-jutsu/088e8199-50e8-4554-b0be-b108a6b2203a
- Source archive in Higgsfield Developer Files: AOTL_Humanoid_Master_V03_Higgsfield_Editable_2026-11-12.zip
- V02 GLB retained for rollback, V03 GLB for this independent lab.

## Native verification
- Original Phase02 painted scene: 32/32 checks.
- V03 wide-camera humanoid IK/gear/animation checks: 76/76.
- Legacy project regression: 954/954.
- 14 actual 1440x810 Godot OpenGL screenshots and a 9-frame walk GIF captured.
- No Windows hardware playtest or human visual approval yet.

ART GAP: The 3D model does NOT yet match the six locked painterly-anime character references. Shape, face, detailed painted materials, rig deformation, cloth and foot-contact motion still require substantial polish. Do not replace the canonical painted character based on automated tests alone.

GitHub draft PR #21: https://github.com/mlyons0990/age-of-the-lost/pull/21
Camera reference branch: feature/painted-2p5d-phase02-poe-camera
Paid Higgsfield credits used: 0.
