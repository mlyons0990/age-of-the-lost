# Dodge Roll integrated with the approved corner HUD

November 13, 2026. This cycle merges the existing tested `dev/dodge-roll-2026-11-12` implementation into the reference camera/HUD build, preserving both histories. It does not replace the experimental city or rig branches.

## Behavior

Space or the round winged-boot button beside the left health-flask cluster starts a roll. Mouse clicks on that button use the last world aim; Space uses the current world cursor. The same `hud_layout.gd` geometry positions the painting and click target, including after a resize. Wheel events on the control cannot zoom the world. Menus and inventory block both pointer and Space activation.

Inherited gameplay values are unchanged: 2.6 ground units in 0.28 seconds, 0.32 seconds of invulnerability, 2.5-second cooldown, no mana cost. A wall stops travel. A roll can cancel attack recovery but not a committed swing, cast windup, Shield Charge, death or another roll. Health-potion, skill and inventory controls retain their established bindings. The click control cannot steer the character. The icon retains the exact approved 128px artwork and shows live cooldown state.

Ward and Ember Aura survive the roll. Roll state/cooldown stay transient; the schema-six save format and ownership rules are unchanged. Respawn clears the roll and cooldown. The animation remains the inherited procedural tumble of existing paintings; it is not a newly authored eight-direction sprite animation. The roll sound hook remains silent until an actual sound asset is supplied. No credits were spent in this integration cycle.

## Validation

- **1,126/1,126 headless assertions across 20 suites.** This includes all 1,039 camera/HUD baseline assertions, 71 Dodge Roll checks and 16 new corner-control checks.
- **71/71 native Dodge Roll checks** and **20/20 native corner-control checks**. Four extra corner checks resize the actual window to 1280×960 and 1440×600 and click the moved control.
- The older dodge fixture queried navigation immediately after releasing the paused start menu. Godot had not synchronized the reactivated region, so the closest-point query returned `(0,0)` and subsequent movement assertions were invalid. The fixture now waits for the real physics/process synchronization and checks floor readiness for both classes before stepping the roll. Production movement rules were not changed to accommodate the tests.
- New tests drive actual viewport pointer and Space events, repeated clicks, inventory pause, aura persistence, real resize routing and save validation. Full logs: `tests/dodge_corner_qa/`. Native captures: `previews/dodge_corner/` and `previews/dodge_roll/`.

Godot 4.6.3, Linux X11/Xvfb, software OpenGL and Dummy audio. The 49-check native camera/HUD run belongs to the preceding checkpoint; all 45 of its headless checks passed again here. No Windows hardware benchmark or human combat-feel assessment is claimed.

## Continuation

The main unresolved visual task is dedicated directional roll/hurt/death artwork with grounded foot contacts, using the approved Warrior/Mage identity. Preserve these tested gameplay timings when replacing the procedural pose. A small authored roll sound and human encounter/audio tuning remain separate tasks. The city and master-rig development branches already contain independent prototypes; inspect their current handoffs before integrating them rather than duplicating or overwriting that work.
