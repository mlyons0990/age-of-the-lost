# AOTL Phase 27 — Anatomical knee/ankle audit (read-only)

**Scope:** preserve the user-verified Phase26 test project and main Crownsfall game. New test only measures actual skeletal hip/knee/ankle/foot joints; it does **not** claim to repair knee skinning or alter mesh assets.

## Evidence
The bundled GLB has 60 nodes, one skin, and six clips: Idle, Walk, Run, Slash, Dodge and Cast. Both legs contain Hip, Knee, Ankle, Foot and Toe bones. The source rest-pose knee chains are nearly straight/collinear, which makes a chosen knee pole axis ambiguous until measured under animation. The JSON audit captures exact GLB SHA-256, bone names and node indices.

## Run
In Godot open `res://scenes/phase27_knee_lab.tscn` and use F6. F11 toggles IK. Walk, sprint, turn, climb and descend, dodge, attack, and capture the camera at in-game isometric scale. Readout displays each knee flexion angle (180° = straight), signed knee pole offset, planted foot vs anchor distance and cumulative anomaly counters. These are *diagnostics*, not proof of deformation quality.

Run `godot --headless --path game/crownsfall_lootslice --script res://tests/phase27_knee_metrics_test.gd`. The deterministic test has six cases; earlier phase regression should also run. Phase27 metrics do not mutate the Skeleton3D.

## Gates for the next work pass
1. Confirm the actual visually correct forward knee bending orientation from side and front camera views.
2. Confirm bone hierarchy and skin weights before modifying joint positions or installing custom pole-target IK.
3. Ensure no recurring extension spikes in walk/run, stair transitions, or combat.
4. With IK active, measure planted foot-to-target drift; do not hide >12 cm errors by increasing whole-body visual offset.
5. Only after Windows Godot 4.6.3 visual comparison, implement a constrained two-bone solver in a *separate* opt-in scene.

**Known limitations:** This phase does not rebind the GLB, create animation GIFs, or fix mesh deformation. Any true knee pose edits require testing mesh skinning and toe/ankle orientation on the master rig. Production remains untouched.
