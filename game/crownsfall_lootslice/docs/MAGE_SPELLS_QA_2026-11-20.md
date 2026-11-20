# Mage spell set — QA (2026-11-20)

Four paid Meshy library casts on the Phase 1 Mage (owner approved "Mage spells approved"; 4 × 8 = 32 credits,
each re-quoted at 8 before submit; balance 2,879 → 2,847 verified with `balance` + `transactions`).

| Key | Spell | Source clip | Trim / time | Release phase | Cooldown | FX (`radiant_vfx.gd`) |
|---|---|---|---|---|---|---|
| LMB | Bolt | mage_soell_cast_7 (#136) `Cast_Bolt` | 0.17–2.42 s → 1.25 s | 0.33 | — | feet sigil, star projectile, landing sigil |
| 1 | Lance | mage_soell_cast_3 (#132) `Cast_Lunge` | full → 2.0 s | 0.31 | 3.0 s | ground sigil, upright sigil ahead, star lance, landing sigil |
| 2 | Nova | Charged_Spell_Cast (#125) `Cast_Nova` | full → 1.8 s | 0.69 | 5.0 s | 3 m compass sigil, two ring waves, 8 stars |
| 3 | Judgment (signature) | mage_soell_cast_4 (#133) `Cast_Sweep` | 0.12–2.12 s → 1.5 s | 0.34 | 3.5 s | Hollow Sun "Judgment of the Lost Sun": sigil, halo, crescents, stars |

Release phases are measured from the clips (hand-speed peak / full arm extension), not guessed.

## Staff fix (free)
The library casts are authored for an empty hand: rigidly skinned to `RightHand`, the staff tipped up to
176° (upside down, across the face). New `grip=Action,maxtilt` mode in `tools/attach_props_to_hero.py` adds a
`MAGE_Staff_Grip` bone under `RightHand` at the palm and bakes its rotation in every clip so the shaft stays
within 35° of vertical (Dead exempt: the staff falls with the hand). Measured head-up ≥ 0.77 in every cast.

## Effects on pale stone
Additive FX vanished on the lab's white floor (and would on the Crownsfall limestone plaza), so all three
shaders are alpha-blended with a deep-gold edge; ground sigils sit 0.10 m above the walk surface.

## Evidence
- `art/higgsfield_2026-11/mage/mage_casts_staff_grip_sheet.jpg` — 4 clips × 6 phases, armed.
- `art/higgsfield_2026-11/vfx_previews/mage_spells_ingame.jpg` — live rig lab, 1080p, just after each release.
- `tests/verify_pilot_mage.gd` 83/83 (was 38): grip bone, staff head-up per clip, each spell plays its own clip,
  releases within 0.05 s of its measured phase, hits the dummy, cooldowns block recasts.
- `tests/verify_radiant_vfx.gd` 17/17; full regression 994/994; knight pilot suites unchanged (29, 41, 25, 26).

## Known gaps
- Mid-sweep (Judgment ~0.40) the staff passes in front of the face.
- The tome stays in the left hand; Nova's two-hand raise lifts it overhead.
- Bolt projectile reads small at gameplay distance.
- Combat profile: all four use the generic Cast hit profile (3.3 m, omnidirectional); per-spell ranges/AoE later.
