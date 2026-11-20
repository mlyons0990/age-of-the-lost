# Phase 0 — Higgsfield Character Pipeline Pilot: QA Report (2026-11-20)

**Branch / PR:** `art/higgsfield-pilot-knight-2026-11-20`, mlyons0990/age-of-the-lost#74 (opt-in; R39/R40 default untouched)
**Play it:** `res://scenes/pilot_knight_combat_lab.tscn` (Godot 4.6.3, F6)

## Deliverables (owner's Phase 0 list)

| Required | Delivered |
|---|---|
| Editable `.blend` | `art/higgsfield_2026-11/pilot/knight_pilot_armed_source.blend` (+ `knight_pilot_source.blend` without props) |
| Usable `.glb` | `game/crownsfall_lootslice/models/higgsfield_pilot/knight_pilot_armed.glb` |
| Godot test scene | `scenes/pilot_knight_combat_lab.tscn` (rig-lab controller, `use_pilot_knight_candidate`) |
| Controller + animations | Idle, Walk, Run, Slash (library Left_Slash), Roll_Dodge, Dead, Cast |
| Sword and shield | R52 sword in the right hand (re-gripped), R52 shield mirrored onto the left hand |
| Real GIF previews | `previews/higgsfield_pilot/*.gif` (Godot renders) |
| Reference comparison | `previews/higgsfield_pilot/pilot_model_vs_reference.jpg` |
| QA report | this file |

## Tests (executed, Godot 4.6.3)
- `tests/verify_higgsfield_pilot_armed.gd` — 35/35: every clip on one skeleton, feet never below the floor,
  feet planted in Idle/Slash/Cast, sword rigid in hand (0 mm drift), roll tucks to 0.21 m hips, Dead ends lying (hips 0.24 m).
- `tests/verify_pilot_knight_lab.gd` — 23/23: knight selected, faces the controller direction, foot IK on,
  sockets on, real-sword blade segment (0.62 m), ~100 px camera (107 px), no skating in Walk/Run, Slash damages
  the dummy, strict real-sword sweep hits a dummy 0.65 m ahead (nearest 0.14 m), one hit per swing, roll with
  i-frames and controller travel (6.82 m, no root-motion drift).
- Shared-code regressions: R52/R55 live labs 17/17 each; full Crownsfall regression 994/994.

## Owner acceptance checklist
| Check | Result |
|---|---|
| Imports into Godot | Pass |
| All required animations play | Pass (Slash, Roll dodge, Death + locomotion, idle, cast) |
| Feet don't slide excessively | Pass after playback matching; library walk/run (pending) to restore natural cadence |
| Armor doesn't visibly intersect | Pass at gameplay scale (Meshy single mesh; no separate armor pieces) |
| Joints deform naturally | Pass at gameplay scale; close-ups show mild LBS pinching in deep bends |
| Weapon follows the right bones | Pass (rigid skin to RightHand; shield to LeftHand) |
| Dodge/Slash respond to input | Pass (Space, click) |
| Death completes | Pass |
| Matches art direction | Close match to the approved knight art (face, hair, tabard, pauldrons, cape trim) |

## Known issues / remaining work
1. No finger, cape or weapon bones (Meshy 24-bone humanoid): hands stay open around the grip; cape follows legs/spine.
2. Retargeted Walk/Run have short strides → playback ×1.9/×2.3 to avoid skating (hurried cadence). Library walk/run requested.
3. Cast is our R52 clip retargeted; with the right-handed knight its hand roles are mirrored relative to R52 (acceptable; replace with a library cast in Phase 1 if needed).
4. Strict sweep window tuned via clip trimming (shared 57% contact phase); per-model contact windows would be cleaner.
5. Godot normals of re-gripped/mirrored props are recomputed by flip only; fine visually, not audited for seams.

## Credits
70 credits spent through Left_Slash (see `docs/AOTL_HIGGSFIELD_CREDIT_LEDGER.md`); walk/run clips (16) pending.
