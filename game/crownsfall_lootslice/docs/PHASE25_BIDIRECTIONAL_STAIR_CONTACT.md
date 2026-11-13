# Phase 25 — Bidirectional stair contact (experimental)

Based on the verified Phase24 stair scene. No production Crownsfall actor, UI or saves changed.

Run `res://scenes/phase25_stair_lab.tscn` using F6. Walk over the six tagged risers and turn around to attempt descent. Press F11 for experimental IK. HUD reports downward contacts and rejection counts.

The descent component requires a tagged test surface, walkable normal, 2.5–18.5 cm drop, recent grounded contact and a non-attack/non-dodge state. Motion uses `move_and_collide`, not an unchecked downward teleport. Phase24 ascent checks remain intact.

Run `godot --headless --path game/crownsfall_lootslice --script res://tests/phase25_descent_policy_test.gd` (13 policy cases). Rerun Phase24 and Phase22 regression tests.

**Not certified:** The grounded grace and probe may fail to acquire descending edges consistently. Real Windows Godot 4.6.3 physics integration and visual camera captures are still required to establish boot contact, pelvis elevation and knee articulation. Experimental, draft only; no production promotion.
