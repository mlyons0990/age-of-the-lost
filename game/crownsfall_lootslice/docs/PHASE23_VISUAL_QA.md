# Phase 23 — Collision-backed visual QA lab

**Status: R&D scene added; not visually approved.** Based on Phase 22 commit `89decec14ad6ed51ea471c4fe7c7959bd7cb48a3`. The working Crownsfall actor, HUD, inventory and saves are untouched.

## Launch
Open `res://scenes/phase23_terrain_visual_lab.tscn` using **F6** in Godot. F11 enables/disables the experimental foot IK; F9/F10 change stride playback; F8 resets; F7 returns to the existing plaza. Start on the right-hand terrain lane.

## Changes from the Phase 22 rig lab
- A green **12-degree incline** constructed from matching BoxMesh and BoxShape3D, making it possible to compare collider contact to rendered soles.
- Five blue/gray **0.16 m risers**, each backed by a StaticBody3D and a collision box.
- A brown **0.60 m raised platform** backed by collision.
- Live metrics: actor elevation Y, grounded flag, vertical velocity, per-foot plant state, cumulative plant/release events and raycast hits.

## Crucial known limitation
Godot `CharacterBody3D.move_and_slide()` does **not** implement automatic stair step-up. The stair lane is a diagnostic; it may stop at the first riser. Passing Phase 22 IK assertions does not imply stairs are climbable or that the boot sole is correctly grounded. Do not report stairs as passed until locomotion implements a bounded, collision-safe step-up and corresponding step-down plus a visual test confirms it. Likewise, this scene does not prove knee deformation, stable pelvis elevation or moving-platform behavior.

## Review matrix
Capture IK OFF and ON from the isometric camera for:
1. Flat-ground walk, sprint and hard stop.
2. Green 12° ramp ascent and descent (both directions).
3. Blue 16 cm stairs approached head-on (expected step-up limitation).
4. Raised platform edge, when reachable.
5. Abrupt 90° turns while a foot is in stance.
6. Dodge/attack while traversing the incline.

For each capture note **visible sole-to-surface gap**, sole penetration, foot sliding, knee inversion/hyperextension, body/capsule elevation, and animation blending. Do not claim quality pass from plant counters alone.

## Quality gate
- No visible foot penetration or floating boot in representative frames.
- No knee hyperextension or ankle snap, including at the locked-to-swing transition.
- Actor/capsule elevation consistent with collision surface during ascent and descent.
- Foot lock released before the anatomical reach limit and on dodges.
- Existing flat-ground walk/run/attack unaffected.
- Windows Godot 4.6.3 visual review and regression testing still required.

The Phase 23 test scene is intentionally isolated; production promotion and merge are blocked until visual evidence passes.
