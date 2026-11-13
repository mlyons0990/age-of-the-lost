# Age of the Lost — Phase 20 Movement Quality Gate

**Baseline:** Godot-verified Phase 19; independent master animation viewer only.

## Changes
The isolated animation viewer adds:
- 29-sample numeric left/right foot-bone trajectories for each of six master clips.
- Lowest-foot-height-band horizontal travel and vertical excursion per clip.
- Loop seam distance in metres.
- Visible L/R foot-bone markers (7 toggles).
- Slow-motion playback (8 toggles 0.35×), motion audit (9), reset (0).

The metrics indicate skeletal motion but **do not prove planted contact**; source animations are in-place and their world-space displacement must be interpreted with player movement. No destructive mesh/rig edits; no modification to live Crownsfall, schema-seven saves, 12×5 inventory, items, HUD or camera. The existing Phase 18 foot IK remains independently optional.

## Godot 4.6.3 Runtime Tests
- With master six-animation GLB: **33 checks passed** in an isolated project; verified all six clips, both feet, 29 samples, marker creation and safe scene operation.
- Without optional master GLB: **8 checks passed** in a fresh isolated project; safe fallback preserved.
- Godot 4.4.1 earlier pass: 32 static+engine checks (before adding loop-seam assertion).
- Do not claim final character visual fidelity, contact solve, frame-perfect transitions, or Windows performance.

## Baseline measured in isolated Godot 4.4.1
Foot trajectories (left / right): Idle: vertical 0 / 0 m, lowest-band path 0 / 0 m. Walk: vertical 0.101 / 0.115 m; lowest-band horizontal travel 1.280 / 1.268 m. Run: vertical 0.243 / 0.233 m; lowest-band travel 1.055 / 1.099 m. Dodge: vertical 1.436 / 1.436 m; lowest-band travel 0.637 / 0.637 m. This quantifies the motion, not a visual pass verdict.

## Testing
Use the full build, install the Phase 19 master GLB at `models/AOTL_Master_Rig_R38_AllSix.glb` (distributed separately), open `scenes/phase19_animation_review.tscn` or F12 from the 3D lab. Test clips 1–6, 7/8/9/0 controls. Run `godot --headless --path game/crownsfall_lootslice --script res://tests/phase20_motion_metrics_smoke.gd`.

## Safety and next steps
Visual inspection and proper foot-sole-contact versus collider ground is still required. Next gate: compare animation-derived gait speed with gameplay speeds, design stance timings and IK/FK blending, run video-level visual proof before replacing the production painted character. The standalone six-animation master rig was made in Higgsfield 3D Jutsu; no paid generation credits.
