# Phase 1 — Heroes (Warrior + Mage) plan, 2026-11-20

Ceiling 600 credits (planning only; every paid job is requested separately with a live quote).

## Warrior = the Phase 0 knight
Already has Idle, jog, sprint, stroll, Slash (Left_Slash), Roll_Dodge, Dead, Cast, sword + shield.
Remaining from the owner's 13: heavy slash, two-hit combo, block, hit reaction, interaction, victory/recovery
(+ a better battle-shout/cast). Candidates (8 each, quote before use): Double_Combo_Attack #92,
Heavy_Hammer_Swing #128 or Sword_Judgment #102, Sword_Parry #147 (block), Hit_Reaction #178, Knock_Down #187,
one interact clip. ≈ 6 × 8 = 48.

## Mage
**Model (needs approval):** `multi_image_to_3d` with the four views cropped from the approved turnaround
(`art/higgsfield_2026-11/mage/*`, uploaded: front 8dfa0e3d…, side 21bc50d2…, back 653115d7…, side 63197d9b…),
textured, rigged, a-pose, 1.75 m, quad 30k. **Live quote 35 credits** (single-image Meshy 7 would be 44).

**Free clips (no credits):** every Meshy auto-rig has the same 24 bone names, and `tools/merge_meshy_clips.py`
transfers clips between rigs with different rest poses (world-space), so the knight's paid clips carry over:
Idle, jog/Run, RunFast, Casual_Walk, Roll_Dodge (dodge), Dead (death), plus our retargeted Cast.

**Paid Mage-specific clips (8 each, quote first):** basic cast, fireball, frost, lightning, channel, staff attack,
hit reaction, interaction → choose from Charged_Spell_Cast #125/#126, mage_soell_cast #129–#137,
Charged_Ground_Slam #127. ≈ 8 × 8 = 64.

**Props (free first):** staff and tome — check existing art/Blender; Tripo H3.1 (≈9) only if needed.

**Estimated Phase 1 total:** Mage 35 + Mage clips ≈64 + Warrior clips ≈48 + props ≤ 36 ≈ **≤ 183**
(well under the 600 ceiling, because clips are reused across rigs instead of bought per character).

## Acceptance (per owner)
Both characters import, play all clips on one skeleton, feet planted / no skating, weapons follow the right bones,
real renders match the approved art, gameplay inputs work in the combat lab.
