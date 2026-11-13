# AOTL Phase 24 — Bounded lab-only stair traversal

**Scope:** self-contained opt-in Godot stair course that extends the stable rig lab. This is compatible with either Phase23 project variant: the fuller Phase23 ZIP in the user's Library and the experimental Phase23 GitHub branch. It does not alter the production Crownsfall character, HUD, inventory or saves.

## Launch
Open `res://scenes/phase24_stair_lab.tscn` with F6. The scene starts before six real collision-backed 14 cm blue-gray risers. A red *untagged* wall is included to demonstrate assist must not climb arbitrary obstacles. Press F11 to compare the opt-in experimental foot IK. The standard rig-lab movement, attacks and dodge remain available.

## Guardrails
- Only tagged `phase24_steps` colliders may receive assisted stair stepping.
- Per-rise limit 0.025–0.185 m, speed cap 7.1 m/s, 0.07 s cooldown.
- Requires grounded actor, blocked foot-level forward sweep, free overhead ascent, and free elevated forward sweep.
- Requires upward-facing surface normal; disables step assist during attacks, dodges and airborne movement.
- Resets experimental IK anchors after discrete capsule correction to avoid dragging locked feet.
- Uses scene-only floor snapping, not moving-platform support.

## Verification
Run `godot --headless --path game/crownsfall_lootslice --script res://tests/phase24_step_safety_test.gd` for 12 deterministic test cases. In this development session, tests have been authored but NOT run in the Godot engine. The ZIP archive CRC check does not establish engine behavior.

**Review required:** Test every riser, untagged red wall, headroom constraints, foot sliding, capsule height, IK transition snapping and the opposite downhill direction in Windows Godot 4.6.3. The underlying step solver is experimental and should not be merged before passing real physics and visual checks.

**Backup:** the phase24 ZIP patch includes six new source/scene/test/doc files plus SHA-256 manifest; GitHub tracks the source on the isolated Phase24 branch and Google Drive holds the ZIP.
