# Phase 21 — Stride Contact Calibration, diagnostic prototype

This build is derived from your verified Phase 20. It does not replace the production 2D game, save schema, inventory or live 3D rig controller. The optional six-animation master remains a separate Phase 19 GLB.

The master review viewer adds **F9**, which estimates horizontal speed from low-foot-frame bone trajectories. It samples 29 animation frames, finds consecutive near-floor foot segments, and fits a constant character translation that minimizes lateral foot-bone slip **in model-local space**. Reports candidate speed, per-cycle distance, heading alignment and least-squares residual. It does not apply any changes to gameplay automatically, and results must be visually confirmed before movement tuning. Signed heading alignment helps flag backward-facing master assets.

Run standalone test: `godot --headless --path game/crownsfall_lootslice --script res://tests/phase21_stride_fit_test.gd`.

The original 12×5 inventory and all seven-schema saves are untouched. All modifications are confined to the optional review scene, a new pure fit module and tests.

## Save isolation

Phase21 uses `AgeOfTheLost_Crownsfall_Phase21_StrideCalibrationTest` as its own Godot user directory. Earlier Phase20 test saves remain untouched.