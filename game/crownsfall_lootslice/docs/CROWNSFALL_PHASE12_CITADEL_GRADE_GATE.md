# Crownsfall Phase 12 — Citadel masonry / elevation integration gate

Date: 2026-11-13

## What exists here
- `scripts/two_point_five_d/citadel_grade_geometry_v12.gd` authors a configurable nine-tread physical 3D staircase, upper landing, side parapets, two large Gothic gate piers and 32 stone arch voussoirs.
- Each walkable tread, landing and gateway structural component has a real 3D `StaticBody3D/CollisionShape3D`. Every rendered masonry piece casts shadows. The stone palette is warm ivory and the riser edges are intentionally muted.
- The module samples continuous knight/NPC visual elevation over the same route and returns -1 when outside the route, preventing an accidental zero-height override elsewhere.
- No paid Higgsfield generation or paid credits are involved. No new wilderness or save-schema modifications.

## Status and important limitation
This is a **new, independent source module on top of the last verified GitHub Phase 08 base**. The interactive Phase 09–11 Citadel scenes and paintings described in chat were not present on the current GitHub Citadel branches at authoring time. Thus this branch **does not reconstruct the missing Phase 09–11 package** and does **not claim the feature is wired into F4/F8/F10 or the knight**. The present F5 experience remains unchanged. Its 3D colliders are in the 3D visual world, while gameplay/pathing remains under 2D authority.

Never merge the older Phase 08 scene over a newer local Phase 11 playable build. Back up/commit the full local working Phase 11 tree first. Cherry-pick **this added file + test only** after reconciling the current main/bridge source.

## Integrate into the *real* Phase 11 once its source is recovered
1. Copy the new script to `game/crownsfall_lootslice/scripts/two_point_five_d/`.
2. Read the authentic upper-Citadel NavRegion2D and measure the *actual* painted route's lower/upper stair ground points. Do not guess positions from the painting.
3. In the Phase 11 2.5D bridge, preload the new module, instantiate it beneath the 3D scenery root, then `install(actual_entrance_px, actual_exit_px, Callable(self, "to_3d"), 9, actual_rise_m, actual_clear_width_m)`.
4. Keep masonry geometry opt-in under the existing F4 quality toggle; verify painted fallback under F8 and depth mode under F10.
5. When F10 is active, sample `elevation_at(game.player.global_position)`; if it is >= 0, offset only the **rendered** depth avatar's Y, not the authoritative Player/NavigationRegion2D.
6. Apply the same height sampling to NPC depth mirrors and service markers when their world position falls within the Citadel route. Validate the painted knight's feet against the actual treads.
7. Run complete 2D navigation/regression tests and a real rendered Godot screenshot at the same camera angle. Do not sign off the physical-height quality gate until the player actually grounds correctly at every riser and occludes behind the gateway.

## Headless geometry unit test
```bash
godot --headless --path game/crownsfall_lootslice --script res://tests/citadel_grade_geometry_v12.gd
```
Test rejects invalid setup, confirms 9 treads, 32 arch stones and 64 colliders; checks the sampled foot elevation against the physical center of every tread, verifies nondecreasing elevation, landing height and the out-of-region sentinel. Visual railing/route clearance still requires the real Phase 11 scene. A local Godot runtime was **not available** to execute this test when committed.

## Production gate
- [ ] Latest complete Phase 11 playable full-source ZIP/backups synchronized to GitHub/Drive
- [ ] Actual Citadel entrance / exit / width measured from authoritative 2D route
- [ ] Bridge F4/F8/F10 integration preserves painted look and save compatibility
- [ ] Character feet contact + full occlusion tested at every stair
- [ ] Godot headless tests and real gameplay screenshots captured
- [ ] Art reviewed at 1080p and 1440p before switching this on by default
