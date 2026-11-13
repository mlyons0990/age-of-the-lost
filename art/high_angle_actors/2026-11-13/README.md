# High-angle actor art for the PoE-wide (21 m) camera — 2026-11-13

**Why:** the main game's camera was pulled back to a PoE-style 21 m view with a steep downward pitch.
The existing knight/mage/enemy art was painted at roughly eye level, so at the new camera it reads
side-on, as if the figure stands on a wall. These sets are the same designs repainted from a **high camera
looking down at about 50°** (top of the head and shoulders visible, body foreshortened, feet planted),
then animated and cut into the **exact strip format the game already loads**.

All art was made with Higgsfield free/unlimited generations (Nano Banana for stills, Seedance 2.0 for motion).
**0 paid credits.**

## Drop-in format (matches `scripts/player.gd`)

| File | Frame | Notes |
|---|---|---|
| `knight/walk_<dir>.png` | 384×384, horizontal strip | looping, 12 frames, feet on the same baseline as today's strips |
| `knight/idle_<dir>.png` | 384×384 single frame | first frame of the walk loop |
| `knight/attack_<dir>.png` | 512×512 strip | one swing, start→strike→recover |
| `knight/dodge_<dir>.png` | 512×512 strip | **new**: forward roll performed in place; move the node during it |
| `mage/...` | same | |
| `enemies/<name>_<anim>_<dir>.png` | 384×384 strips | **new**: animated enemies (today they're single stills) |

`<dir>` is one of `down, se, right, ne, up`. The west-facing directions are mirrored, exactly as `FACINGS` does now.

Transparent RGBA, keyed from a flat green screen, with a soft 1px edge.
Character height inside the frame is about 360px, like the current strips. At 21 m the coding side may want
to retune `SPRITE_SCALE` so the knight stands about 70–80px tall at 1440p.

## How to try it
Copy the folders over `game/crownsfall_lootslice/assets/` on a scratch branch. Filenames and strip layout are
unchanged, so walk/idle/attack work without code changes. `dodge_*` and enemy strips need small hooks
(new animation names) — not added, to keep the gameplay code with the coding chat.

## Status
See `STATUS.md` in this folder for which directions/animations are done and any known flaws.
