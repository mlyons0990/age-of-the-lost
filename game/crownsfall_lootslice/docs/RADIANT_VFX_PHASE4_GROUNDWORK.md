# Phase 4 groundwork — "Hollow Sun" radiant spell FX (free, no credits)

Reference: `art/references/2026-11-20/hollow_sun_arbiter_endgame_character_sheet.webp`
("Judgment of the Lost Sun" strip): gold/white compass-star sigils, crescent
light arcs, four-point starbursts, faint violet accents.

## What was built
- `scripts/three_d/radiant_vfx.gd` — procedural, no textures:
  - `sigil()` — ground/halo compass-star circle (8-point star, rings, spinning ticks, counter-spinning rune dashes, diamonds); reveal → spin → fade.
  - `crescent()` — tapered crescent ribbon sweeping right→left round the caster, bright outer edge, violet-tinted tail.
  - `starburst()` — billboard 4-point star with diagonal flare.
  - `judgment()` — signature combo: caster sigil + vertical halo sigil behind the head + two crescents + 5 trailing stars + landing sigil + landing star.
- `rig_lab.gd`: `radiant_spell_fx` export (opt-in); `pilot_mage_combat_lab.tscn` enables it, so Cast → `judgment()`. Knight and other labs are unchanged.

## Evidence (real renders, Godot 4.6.3, opengl3)
- `art/higgsfield_2026-11/vfx_previews/radiant_sheet.jpg` — close 3/4 at 0.12 / 0.30 / 0.50 / 0.85 s.
- `art/higgsfield_2026-11/vfx_previews/radiant_game_crop.jpg` — PoE gameplay camera (FOV 32, pitch 52°, dist 21).
- `tests/verify_radiant_vfx.gd` 17/17; full regression 994/994 unchanged.

## Not yet / next
- Timing is tuned to a generic cast; re-time to the release frame of the paid Mage cast clips once approved (#133 sweep, #136, #132, #125 — awaiting user approval, 32 credits).
- Add bloom/glow to the lab environment; the gold reads best with glow enabled (captures use glow 0.9).
- Per-skill variants (bolt, lance, nova) reuse the same three primitives.
