# Phase 21 — Stride Contact Calibration, diagnostic prototype

This build is derived from your verified Phase 20. It does not replace the production 2D game, save schema, inventory or live 3D rig controller. The optional six-animation master remains a separate Phase 19 GLB.

The master review viewer adds **F9**, which estimates horizontal speed from low-foot-frame bone trajectories. It samples 29 animation frames, finds consecutive near-floor foot segments, and fits a constant character translation that minimizes lateral foot-bone slip **in model-local space**. Reports candidate speed, per-cycle distance, heading alignment and least-squares residual. It does not apply any changes to gameplay automatically, and results must be visually confirmed before movement tuning. Signed heading alignment helps flag backward-facing master assets.

Run standalone test: `godot --headless --path game/crownsfall_lootslice --script res://tests/phase21_stride_fit_test.gd`.

The original 12×5 inventory and all seven-schema saves are untouched. All modifications are confined to the optional review scene, a new pure fit module and tests.

## Save isolation

Phase21 uses `AgeOfTheLost_Crownsfall_Phase21_StrideCalibrationTest` as its own Godot user directory. Earlier Phase20 test saves remain untouched.

## Updated optional Higgsfield model — revision 46

A refreshed six-animation export was created from Higgsfield master revision 46, without modifying the master Blender project. It passed a separate Godot 4.4.1 import and 13 model-integration checks. Download from:

https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/260125af-3418-42ae-858a-354aab7d206a.zip

Extract `AOTL_Master_Rig_R46_Six_Animations.glb`, rename to `AOTL_Master_Rig_R46_AllSix.glb`, and put into `game/crownsfall_lootslice/models/`. The reviewer now prefers R46 when both R46 and R38 are installed; R38 still works as a tested fallback. Neither is substituted for the live player. Model media is hosted separately, not bundled in this full-source ZIP.

## Phase 21 QA limits

Headless Godot 4.4.1 tests passed: 11/11 stride math, 14/14 walk/run/idle/cast/dodge cadence, 13/13 master R38 fitting, 13/13 master R46 fitting, 3/3 optional missing model fallback, and 3/3 R46 priority selection. See `game/crownsfall_lootslice/tests/PHASE21_QA_RESULTS.json`. These tests do not replace a visual quality review in Windows Godot 4.6.3.