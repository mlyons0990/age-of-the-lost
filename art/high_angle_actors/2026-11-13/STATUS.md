# Status — high-angle actor set (updated as work lands)

## Knight
| Direction | idle | walk | attack | dodge |
|---|---|---|---|---|
| down | ✅ | ✅ 12f loop | ✅ heavy spin (16f) | ✅ forward roll (14f) |
| se | ✅ | ✅ 12f loop | – | – |
| right | – | – | – | – |
| ne | still ✅ | in progress | – | – |
| up | – | – | – | – |

Known flaws
- `heavy_attack_down`: the model drew a white slash arc in about 3 frames despite the prompt. It reads as built-in swing VFX; regenerate if unwanted.
- `walk_down` turns about 15° toward screen-right, a natural slight angle.
- Nano Banana will not produce a strict side profile for "right"; Seedream with a transparent background is being tried.

## Mage, enemies
Queued after the knight.
