# AOTL terrain foot IK — Godot integration V01

Scope: optional Godot 4.3 runtime integration for the existing 3D rig lab. The playable 2D Crownsfall plaza is untouched.

## What is wired
- `rig_controller.gd` instantiates `terrain_foot_ik.gd` after loading its GLB and calls it after `move_and_slide()`.
- The controller now prioritizes `res://models/AOTL_Warrior_R36.glb` if it is installed, with the original `AOTL_Wayfarer_Articulated_Proxy.glb` preserved as a permanent fallback. The IK layer searches for an imported `Skeleton3D` and the `ThighL` → `AnkleL`, `ThighR` → `AnkleR` chains. If the older proxy lacks those exact bones, it exits and the controller remains playable.
- Uses world-space planted targets, downward ground raycasts, slope rejection, smooth IK weight and target interpolation, and movement-phase contact windows.
- IK is automatically inactive during attacks, dodges, falls, or when terrain is unsuitable.
- Default test movement still uses the gameplay controller's velocity. This is **not** clip-extracted root motion.

## Run
1. Open `game/crownsfall_lootslice/project.godot` in Godot 4.3 or newer.
2. Run the project, then open the 3D rig lab using its existing navigation.
3. The lab HUD shows **IK: available** when the imported GLB contains both compatible leg chains; otherwise **IK: proxy fallback**.
4. Test WASD walk, Shift run, Space dodge, and change between flat floors and traversable sloped collision geometry.
5. Run the logic regression check:
   `godot --headless --path game/crownsfall_lootslice --script res://tests/terrain_foot_ik_integration.gd`

## Important current constraints
- The actual R36 binary **has not yet been copied into this Git repository**. The export remains in Higgsfield 3D Jutsu project `088e8199-50e8-4554-b0be-b108a6b2203a`, revision 36. To install, download the exported GLB and place it at `game/crownsfall_lootslice/models/AOTL_Warrior_R36.glb`. Import in Godot, then run `godot --headless --path game/crownsfall_lootslice --script res://tests/verify_warrior_r36_import.gd`. The main branch and original LFS model remain untouched.
- The 62-bone Blender model has additional IK control bones, but runtime Godot uses its own `SkeletonIK3D` modifiers and relies on the deformation chain names.
- `SkeletonIK3D` is deprecated in Godot 4.3; replace with a SkeletonModifier3D-based solver in a future upgrade.
- No Godot runtime or in-engine frame-by-frame visual QA was available in the authoring environment. The regression test was authored but has not been executed here.
- Contact phase centres are tuned to the existing V06 walk/run clip lengths. Retune them after importing V36 and test animation loops before merge.
- To validate actual terrain response, test a **collision-backed** slope or step. Visual-only plaza decorations do not supply raycast hits.

## Acceptance gate before enabling for the main game
- No foot teleportation when contact changes or an action is interrupted.
- No planted-foot sliding while the character translates and turns.
- Feet remain above traversable geometry without knee hyperextension.
- No IK overriding attack/dodge animation; immediate safe fallback if target raycasts fail.
- Original proxy mode and existing gameplay tests continue to pass.

This is an integration scaffold, not a claim of production-perfect foot IK.

## Backup and rollback
- Main branch is the pre-integration baseline.
- Exact original `rig_controller.gd` is copied to `game/crownsfall_lootslice/backups/rig_controller_before_r36_integration.gd.bak` on this branch.
- Original LFS proxy model remains at its existing path; no destructive overwrite.
- Higgsfield revisions 27–36 remain separate, with Revision 36 as the target asset.
- Godot never enables the new IK when the imported skeleton lacks the named leg chains; it uses the older movement intact.
- A production merge requires strict R36 import gate and manual foot motion QA.
