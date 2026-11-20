# Higgsfield credit plan, revised after the knight pilot (2026-11-20)

Balance verified 2026-11-20: **2,946** (Roll_Dodge charged; Dead clip held for approval). Every paid job still needs the owner's
OK on the specific operation and its quoted cost. Figures below are live quotes from 2026-11-20 where marked (Q).

## What the pilot proved
- A Meshy 7 rigged model from one A-pose image (44 Q) is a close match to the approved art: face, hair,
  tabard, pauldrons, cape trim. This is far beyond what Blender polish of the procedural R52 mesh can reach.
- Our own clips retarget onto Meshy's 24-bone rig for free (Blender tool `retarget_r55_to_meshy.py`):
  Slash/Walk/Run/Idle/Cast worked. Only motions our rig doesn't have need paid library clips (8 Q each).
- Library clips (`3d_rigging`, 8 Q) arrive on the same skeleton, so they merge with the retargeted set.
- The Meshy rig has no cape/finger/weapon bones: weapons attach in Godot; cape follows legs/spine (acceptable so far).
- **Consequence:** a character costs ~44 + (missing clips × 8), not 44 + 13 × 8. The knight *is* the Warrior,
  so Phase 1's Warrior model is already paid for.

## Recommended allocation (priority order)

| # | What | How | Credits |
|---|---|---|---:|
| 0 | Pilot (done) | ref 2 + model 44 + Roll_Dodge 8 + Dead 8 | **62** |
| 1a | Warrior animation set | ~8 library clips our rig lacks: Combat_Stance, Double_Combo, heavy swing, Sword_Parry, Hit_Reaction, Knock_Down, better Run, interact | 64 |
| 1b | Mage | 2 A-pose refs (nano_banana_pro 2 each), model ×2 tries (44), ~9 clips (casts, channel, roll, hit, death; walk/run retargeted free) | 168 |
| 1c | Hero weapons | sword, shield, staff, tome: concept still 2 + Tripo H3.1 9 each | 44 |
| 2a | First enemy, then decide | revenant spearman: ref 2 + model 44 + 5 clips | 86 |
| 2b | Remaining humanoid enemies | skeleton knight, thorn-bark brute, hollowling (only after 2a passes) | 258 |
| 2c | Non-humanoid enemies | wraith, wolf, stag as painted sprites (stills + Seedance 480p, ~5 clips each) | ~190 |
| 3 | Signature props only | ~12 unique hero props (fountain, Reality Scar frame, knight/angel statues, market stall, noticeboard, stash chest, banner pillar…) at 11 each; generic clutter from existing art/Blender | 132 |
| 4 | VFX source textures | Godot particles/shaders do the work; Seedance sheets for ~6 signature effects | 72 |
| 5 | UI art | statue globe frames (nano_banana_pro), a few panel pieces (gpt_image_2_6 at 0.5) | 40 |
| 6 | Icons + key art | ~30 skill icons + remaining item icons at 0.5, 2–3 key art paintings | 70 |
| | **Planned** | | **~1,186** |
| | **Reserve** | re-rolls, optional boss (~100), Mage/enemy second tries, anything the owner adds | **~1,750** |

Why this order: characters are the hardest thing to make well any other way and the biggest visual gap to the
references; props, VFX and UI can mostly be done in Godot/Blender with generated art only where it is unique.

## Gates (stop and report instead of spending further)
- Each new character: must import, play its clips on one skeleton and read as the reference at the gameplay camera.
- Two failed re-rolls of the same asset → change approach (handoff rule).
- Report spend per phase on completion; ledger in `art/higgsfield_2026-11/LEDGER.csv`.

## Open owner decisions
1. Owner plan now allows appropriately licensed assets incl. patch.gg (per-asset licenses, PR #72) after existing/Blender sources.
2. Camera: the handoff's 26–28 m view gives a 57 px knight, not ~100 px; pick one target.
3. Whether credits renew monthly on the Ultra plan (the 3,000 grant was dated 2026-11-13) — if so, the reserve can be spent more freely.
