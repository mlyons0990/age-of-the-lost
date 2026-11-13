# AOTL Phase 24 — Bounded lab-only stair traversal

**Scope:** opt-in Godot physics scene extending the small Phase 23 GitHub test scene. The fuller Phase 23 source ZIP from the user's library was also inspected for its remaining limits. Neither experiment changes the production Crownsfall character, HUD, inventory or saves.

## Launch
Run `res://scenes/phase24_stair_lab.tscn` with F6 in Godot. Compare the collision-backed blue-gray steps with the green ramp. F11 toggles foot IK; the Phase23 test controls remain available. Phase24 HUD counts successful step assists and rejection categories.

## Guardrails
- Steps only on diagnostic stair colliders explicitly tagged `phase24_steps`; ordinary walls/objects are never step-assisted.
- Per-riser limit 0.025–0.185 m, speed cap 7.1 m/s and 0.07 s cooldown.
- Requires grounded actor, blocked foot-level forward sweep, free overhead ascent and free elevated forward sweep.
- Requires upward-facing surface normal; no stair assist during attacks, dodges or airborne movement.
- Resets experimental IK anchors after discrete capsule correction to reduce foot dragging.
- Enables scene-only floor snapping to assist downhill contact, not moving-platform support.

## Verification
Run `godot --headless --path game/crownsfall_lootslice --script res://tests/phase24_step_safety_test.gd` for 12 deterministic policy cases. Tests have not been executed in this session: ZIP CRC validation is not an engine run.

**Known:** Step traversal is not yet visually approved. Check individual risers, capsule headroom, vertical correction, boot contact and knee animation in Windows Godot 4.6.3. Godot test_move behavior is sensitive to capsule geometry. The test scene is not permission to merge into production. Descending stair edges and moving platforms remain separate gates.
