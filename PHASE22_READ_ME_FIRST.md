# AOTL Crownsfall Phase 22 — Gait Contact Hysteresis

Experimental update based on the user-verified Phase 21 source. F11 activates/deactivates guarded foot IK in the independent 3D rig lab; production Crownsfall is intentionally unchanged.

## Install / test
1. Unzip full source and open `game/crownsfall_lootslice/project.godot` in Godot 4.6.3.
2. Press F5 for the original playable town, or open `scenes/rig_lab_3d.tscn` and F6 to compare 3D movement.
3. In the rig lab, use F11 to toggle experimental IK. Walk, sprint and turn; look for inappropriate ground sticking, leg overextension or swing foot freezing. F8/F9/F10 preserve Phase 21 cadence controls.
4. Run the Godot tests:
   `godot --headless --path game/crownsfall_lootslice --script res://tests/phase22_contact_classifier_test.gd`
   `godot --headless --path game/crownsfall_lootslice --script res://tests/phase22_ik_smoke.gd`
   `godot --headless --path game/crownsfall_lootslice --script res://tests/phase22_walk_ik_integration.gd`

## Scope and caveats
Implemented stance confirmation from backwards moving foot-bone velocities; threshold hysteresis; terrain slope rejection; world-ground anchoring and overstretch release; contact time limit + reacquisition cooldown; owner-collider exclusion and teleport reset. Previous Phase 21 walk/run cadence behavior remains untouched.

Engine validation: Godot 4.4.1 Linux, headless. 66 assertions from new and prior tests, with 2 observed contact acquisitions, 1 contact release and 98 ray hits in the animated-gait integration. These tests do **not** certify final visuals or Windows 4.6.3 performance. This is a development candidate only. See `docs/PHASE22_GROUND_CONTACT.md` and `tests/PHASE22_QA_REPORT.json`.

Backups: previous Phase21 full source remains intact; independent Phase22 user save directory. Code branch is intentionally separate and must not be production-merged before visual QA. No paid generation credits required.