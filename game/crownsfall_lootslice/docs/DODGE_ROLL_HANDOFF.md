# Dodge Roll development cycle — November 12, 2026

Adds the first evasive move to the playable Crownsfall slice, bound to **Space** as shown in the owner's target UI reference (`docs/reference/ui_camera_target/2026-11-12/` at repository root). Open `project.godot` with Godot 4.6.3 after fetching Git LFS assets.

## Behavior

- **Space**, or the round button to the right of the mana orb, rolls toward the cursor. With the cursor on the character, the roll goes the way the character faces.
- A full roll covers 2.6 ground units in 0.28 seconds. Walls and ledges stop it on the floor; it uses the same navigation test as Shield Charge.
- Damage is ignored for 0.32 seconds from the start of the roll. This reuses the existing `invuln` timer, so enemy attacks and Cantor hazards need no changes.
- No mana cost. 2.5 second cooldown, shown as a clockwise sweep and a number on the button. Cooldown reduction does not apply.
- It is available to Warrior and Mage, is not a hotbar ability, does not appear in the Grimoire and deals no damage.
- A roll may cut short the recovery after an attack. It cannot start during a committed sword swing, a cast windup, Shield Charge, another roll, death or pause; a refused roll changes nothing.
- Abilities cannot be used mid-roll. Rolling clears the current walk path and attack target. Wards and Ember Aura keep running.
- The roll pose is procedural: the existing artwork tumbles once around the body and tucks at the midpoint, on the presentation-only pivot added in the actor-feedback cycle. There is no new painted roll animation.
- Roll state and cooldown are transient. Save schema remains six and saved files contain nothing new. Death ends a roll; respawn clears the cooldown.

All numbers are constants at the top of `scripts/player.gd` (`DODGE_DISTANCE`, `DODGE_TIME`, `DODGE_INVULN`, `DODGE_COOLDOWN`). They are first-pass values and have not been tuned by a human player.

## Files

| Path | Change |
|---|---|
| `scripts/player.gd` | `dodge_ready()`, `dodge_roll(aim)`, roll movement in `_physics_process`, roll pose, Space binding, `visual_state()` returns `dodge` |
| `scripts/legacy_hud.gd` | `dodge_button_rect()`, drawn round button with cooldown sweep, tooltip, start-screen help text |
| `scripts/hud.gd` | transparent click target over the drawn button, help text |
| `assets/ui/dodge_roll.png` | 128px runtime icon, byte-identical to `art/ability_icons/dodge_roll/2026-11-12/dodge_roll_128.png`; stored as a normal Git file, not LFS, via a `.gitattributes` exception |
| `tests/dodge_roll_integration.gd` | 69 assertions |
| `tools/run_checks.py` | seventeenth suite |
| `docs/releases/2026-11-12-dodge-roll/` (repository root) | cropped engine captures; the full-size captures written to `previews/dodge_roll/` are not committed |

## Verification

`python3 tools/run_checks.py --report-dir /tmp/aotl-qa-report` passes **1023 headless assertions across 17 suites**: the previous 954 unchanged plus 69 new. The new suite also passes all 69 rendered under Xvfb with software OpenGL at 1920x1080. Tested on Linux with Godot 4.6.3 only.

The 69 checks cover, for both classes: start conditions, exact distance and duration, ending on walkable floor, the invulnerability window and its end, cooldown, no mana or packet changes, mid-roll ability lock-out, recovery cancel, refusal during a committed swing or cast with that action left intact, self-aimed rolls, wall stops, pause, ward retention, death and respawn, and save validity. Shared checks cover Shield Charge exclusion, the Space key, HUD button placement and non-overlap, icon size and hash, button clicks, and the HUD keeping its own icon reference.

The rendered run found one defect that headless checks could not: the icon was loaded inside the draw call without keeping a reference, so it rendered as a white square. The HUD now caches it and a check guards the cache.

## Not done

- No human playtest; feel, distance and cooldown are untuned. No Windows or target-hardware run.
- No painted roll animation and no roll sound (the `dodge_roll` cue is requested but no audio file exists, so it is silent).
- The HUD still uses the existing centred layout. The owner's target layout (orbs in the corners, flasks 1-5, skills Q W E R T, wider zoomable camera) is not implemented here, and that reference shows flask and skill bindings that conflict with its own controls list; those bindings need the owner's decision first.
- The 2.5D and 3D lab scenes on other branches have their own separate dodge code; nothing here is shared with them.
- This branch and the open dialogue pull request (#28) both add a seventeenth suite to `tools/run_checks.py` and edit the QA totals, so whichever merges second needs a small manual merge there.
