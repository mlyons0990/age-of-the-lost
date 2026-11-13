# Phase 26 — Foot IK-driven visual pelvis stabilization

**User-confirmed source baseline:** Phase25 QA1. **Code status:** standalone R&D, no production merge or certification.

## Purpose
Adds a reversible, bounded *visual-only* pelvis offset (at most 6.5 cm, 32 cm/s max change) to compensate for planted ankle/IK target mismatch and ease abrupt movement transitions. No modifications are made to the CharacterBody3D collision, Godot save schema, 2D Crownsfall actor, animation clips, or the base GLB. Knee and ankle deform weights are **not** changed: those require a proper authored master rig and separate asset review.

## Test
Run `res://scenes/phase26_visual_lab.tscn` via F6. Use F11 to compare foot IK on and off while walking and sprinting on the stairs. The HUD shows visual pelvis offset, target offset, sample count and suspension reason. Compare with Phase25 using the same camera, recorded input and motion. Verify no teleport on attacks, no ground clipping, and no surprising difference in capsule collision. Run pure policy tests with:

`godot --headless --path game/crownsfall_lootslice --script res://tests/phase26_pelvis_policy_test.gd`

## Engineering constraints
- All offsets are bounded and smoothed with frame-rate-aware exponential response; combat, dodge, airborne and IK-disabled force target back to zero.
- Samples use planted-foot target minus observed skeleton foot position. Outliers (>18 cm) excluded. One-foot and two-foot contact supported.
- A separate wrapper pivot keeps Phase25's own `avatar.position` interpolation independent. This is a *visual stabilization experiment* and deliberately **not** proof of anatomically correct deformation.
- The runtime must be reviewed for import differences (SkeletonIK3D behavior), avatar parenting, and ankle bone conventions. On Windows Godot 4.6.3, visually inspect knee bend, boot sole, pelvis and hips across ascent/descent, hard stops, attack interruptions and F11 toggles before approval.

## Remaining concerns
This does not improve bone skin weights or true pole-target knee IK. The visual-only mesh offset may reveal capsule/boot differences; if detected, disable the experiment and refine bone chains and authored animation rather than increasing the pelvis offset limit. Do not merge to production until visually approved and regressions pass.
