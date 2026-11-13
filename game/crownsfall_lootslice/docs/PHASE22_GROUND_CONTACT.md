# AOTL Phase 22 — Contact hysteresis & guarded foot IK

Prototype isolated to the 3D rig lab. The 2.5D Crownsfall character, exact 12×5 inventory, crafting, HUD and save schema remain unchanged.

## Changes
- Stance classification based on low foot, terrain slope, *relative* foot motion vs actor heading, and 3-frame confirmation. Low forward swing cannot be locked just because it is near ground.
- Plant/release hysteresis, time-limited contact, target overstretch release, steep slope rejection, teleport reset, moving/no-ground release, and optional exclusion of the player's physics collider from raycasts.
- Foot target lock in world space with blended IK interpolation; never change the 3D model or its six animations.
- Press F11 in the existing isolated rig lab to compare default animation to Phase22 foot IK; F8/F9/F10 gait controls from Phase21 are preserved.

## Validation
Run `godot --headless --path game/crownsfall_lootslice --script res://tests/phase22_contact_classifier_test.gd` and `godot --headless --path game/crownsfall_lootslice --script res://tests/phase22_ik_smoke.gd` after importing assets. Regression coverage includes forward foot near floor not locking, confirm frames, movement loss, slope limit, overstretch release, timeout, and disabled IK.

**Critical limitation:** bone joints are not shoe soles and the proxy has no final skinning polish. The sample classifier does not prove finished natural motion; review visible knee hyperextension, foot slide, physics-floor contact and foot target lifetime in Windows Godot 4.6.3 before using it in the production actor. No paid Higgsfield credits required.

## Latest engine evidence (isolated Godot 4.4.1)
- Pure stance/swing and anatomical reach calculations: 22 checks pass.
- IK skeleton binding/disable: 10 checks pass.
- Walk animation with actual physics ground: 11 checks, 2 acquired plants, 1 release, 98 ground-ray hits.
- Run animation with actual physics ground: 11 checks, 2 acquired plants, 2 releases, 122 ground-ray hits.
- Physical 70-degree incline: 9 checks, 2 steep-ground rejects; 20-degree ground accepted; raised step avoids burying feet, no locks.
- Component lifecycle (100 toggles + clean teardown): 9 checks.
- Phase21 gait (14), stride math (11), missing-master fallback (3): 28 regression checks.
Plus 6 actual rig-lab keyboard dispatch checks (F11 on/off, F10 cadence, F8 reset). Total **106 passing assertions**. No Godot 4.6.3 Windows verification was executed in this environment.