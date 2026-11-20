# AOTL: best use of 3,000 Higgsfield credits (2026-11-19)

**Goal:** make Crownsfall look like a finished, playable ARPG in the approved painted-anime style at the PoE 21 m camera,
with a hero who walks, runs, attacks, dodges, casts, gets hit and dies, plus enemies, spells, city props and the main UI panels.

Prices below are live quotes from Higgsfield on 2026-11-19. The free unlimited allowance ended on 2026-11-13, so everything
here spends credits. 1 credit buys roughly two icons.

| Generation | Model | Credits |
|---|---|---|
| Icon, UI piece, item art | GPT Image 2.6 (1k, medium) | 0.5 |
| Character or concept still (keeps identity best) | Nano Banana Pro (2k) | 2 |
| **Textured + rigged 3D character** | Meshy 7 image-to-3D, rig on | **44** |
| **Each extra animation on that rig** | 3D Rigging + library clip | **8** |
| Rig only (no animation) | 3D Rigging | 5 |
| Static 3D prop | Tripo H3.1 image-to-3D | 9 |
| Static 3D prop, premium | Meshy 7 / Tripo P2 | 34–44 |
| 4 s animation clip, sprite path | Seedance 2.0 480p / 720p | 12 / 18 |
| 4 s clip, budget | Kling 3.0 Turbo | 6 |

## The big change: rigged 3D characters instead of painted video clips

Higgsfield's 3D rigging includes a 678-clip animation library with everything an ARPG hero needs, all on one skeleton:

- **Move:** Casual_Walk (30), Walk_Fight_Forward/Back (21/20), RunFast (16), combat runs (9/10), idle (0), Combat_Stance (89)
- **Melee:** Left_Slash (97), Double_Combo_Attack (92), Triple_Combo_Attack (105), Sword_Judgment (102), Heavy_Hammer_Swing (128), Reaping_Swing (99)
- **Defence:** Roll_Dodge 0–4 (158–163), Stand_Dodge (156), Sword_Parry (147), Block1–10 (138–146)
- **Spells:** Charged_Spell_Cast (125/126), Charged_Ground_Slam (127), mage spell casts 0–8 (129–137)
- **Hit and death:** Hit_Reaction (178/179), BeHit_FlyUp (7), Dead (8), Knock_Down (187/190), dying_backwards (189), Fall_Dead_from_Abdominal_Injury (188)

Why this beats the video-clip sprites we made on Nov 12–13:

1. **All 8 directions for free.** A 3D model rendered at the 21 m camera faces any direction. Video clips needed one paid clip *per direction per move* (5 × 6 moves × 18 credits ≈ 540 credits per character, plus re-rolls).
2. **No identity drift.** Video models change the face, armour and cape between clips. A single mesh can't.
3. **It matches where the coding chats are going.** PRs #43–#71 build a 3D Warrior rig with foot IK, sword collisions and a Godot combat scene. A Higgsfield mesh can feed that pipeline (or replace its hand-built body) instead of competing with it.
4. **Still usable for 2D.** If we keep painted sprites, the same rig can be rendered into 8-direction sprite sheets in Blender/Godot, so nothing is wasted.

**Risks, tested by the pilot before any big spend:**
- **Painted look:** AI meshes can look plastic. Mitigate by generating from clean painted turnaround art, toon/painterly shader in Godot, and the camera distance (knight is ~110 px tall on screen).
- **Cape and long coats:** auto-rigging is humanoid and skins capes to the legs. We may need a cape bone added by the coding chat, or a shorter cape on the 3D version.
- **One clip per call:** each 3D Rigging call returns the rig with one animation. Clips must be merged into one Godot AnimationLibrary. The coding chat's existing Blender export helper already does this.

## Budget (≈ 1,880 planned + ≈ 1,120 reserve)

### Phase 0: Pilot (≈ 80 credits) — go/no-go before anything else
| Item | Credits |
|---|---|
| Knight A-pose turnaround sheet: front, back, side (Nano Banana, ~4 tries) | 8 |
| Meshy 7 textured + rigged knight (one attempt; a second only if the first is close) | 44 |
| 3 test clips: Roll_Dodge, Left_Slash, Dead | 24 |
| **Pilot total** | **≈ 76** |

**Pass criteria:** recognisably the approved knight at gameplay scale, cape doesn't tear badly, the three clips play on one skeleton in Godot.
If it fails, fall back to the sprite plan in the appendix.

### Phase 1: Heroes — Warrior and Mage (≈ 520)
| Item | Count | Credits |
|---|---|---|
| Turnaround sheets (both classes, with re-rolls) | 16 | 32 |
| Textured + rigged models (best of 2 each) | 4 | 176 |
| Warrior clips: idle, combat idle, walk, run, 3 attacks (slash, combo, heavy), roll dodge, parry, hit, knock-down, death, interact | 13 | 104 |
| Mage clips: idle, walk, run, 4 spell casts, ground slam, roll dodge, hit, knock-down, death, channel | 13 | 104 |
| Weapon/offhand props as separate meshes (sword, shield, staff, tome) | 4 | 36 |
| Contingency re-rolls | – | ~70 |

### Phase 2: Enemies (≈ 560)
Humanoid enemies use the same rig + library (cheap animations). Creatures that won't rig as humanoids stay painted sprites.

| Enemy | Method | Credits |
|---|---|---|
| Revenant spearman | rigged model + walk, attack, hit, death, stagger | 44 + 40 + stills 4 = 88 |
| Skeleton knight | rigged model + 5 clips | 88 |
| Thorn-bark brute (heavy humanoid) | rigged model + 5 clips (Heavy_Hammer_Swing, Charged_Ground_Slam) | 88 |
| Hollowling (hunched humanoid) | rigged model + 5 clips | 88 |
| Training dummy (from the camera target image) | static Tripo mesh + Godot wobble shader | 9 |
| Wraith (floating), corrupted wolf, stag | painted sprites, Seedance 480p: the 5 most-seen clips each (walk ×2 directions, attack, hit, death; others mirrored) | 3 × 5 × 12 ≈ 180 |
| Boss: Cantor/Reality Scar champion (one showpiece) | rigged model + 6 clips | ~100 (optional, from reserve) |

### Phase 3: Crownsfall city props in 3D (≈ 330)
Replaces the procedural blockout meshes that Phases 05–08 say don't yet match the approved painting.
Concept still first (2 cr), then Tripo H3.1 (9 cr) = **11 credits per prop**.

~30 props: tiered elven fountain, blue-canopy market stall (×2 variants), banner pillar with gold crest, stone planter + shrubs,
street lamp, brazier, knight statue, angel/guardian statue, archway gate, stair set, balustrade segment, bench, crates, barrels,
notice board, stash chest, merchant counter, weapon rack, armour stand, anvil, cart, well, potted tree (autumn red, as in the
target image), hedge segment, waterfall lip piece, small shrine, Reality Scar rift frame, training dummy, banner on wall,
cobble border piece.

### Phase 4: Spell and combat VFX (≈ 220)
Seedance 480p on black/green, keyed into sheets + JSON (the structure from chatgpt-pixel-effects, without the pixel steps).
~16 effects × 12 credits + re-rolls: fireball + impact, frost nova, chain lightning, arcane missile, holy smite, ground slam
crack, sword slash arcs (light/heavy), dodge dust puff, level-up burst, potion drink glow, loot beam (by rarity colour),
Reality Scar portal loop, hit sparks, death dissolve, teleport/waypoint swirl.

### Phase 5: UI panels — inventory, character, HUD (≈ 90)
GPT Image 2.6 / Nano Banana at 0.5–2 credits, matched to the approved HUD in `docs/reference/ui_camera_target`:
- Inventory panel frame + grid cell + slot highlight states (common/magic/rare/unique borders)
- Character / equipment panel with the paper-doll silhouette and 11 slot frames
- Skill bar frame, flask slots, life/mana orb frames (stone sentinels as in the target), XP bar
- Tooltip frame (4 rarities), minimap frame, quest tracker panel, name plate, vendor/stash windows, buttons (3 states), close/tab icons
- Class portraits (Warrior, Mage) for the character panel and select screen
≈ 60 pieces with re-rolls.

### Phase 6: Icons and key art (≈ 80)
- Skill icons for the 10 Warrior/Mage skills in the bar (Q–T) + passives: ~30 × 0.5–2
- Remaining item icons for drops and quest items: ~40 × 0.5
- Loading screen / title key art (2–3 Nano Banana 2k): ~10

### Totals
| Phase | Credits |
|---|---|
| 0 Pilot | 76 |
| 1 Heroes | 520 |
| 2 Enemies | 560 |
| 3 City props | 330 |
| 4 VFX | 220 |
| 5 UI panels | 90 |
| 6 Icons + key art | 80 |
| **Planned** | **≈ 1,880** |
| Reserve (re-rolls, boss, extra props) | ≈ 1,120 |

## Rules while spending
- Log every job (model, credits, job ID, accepted/rejected) in `art/higgsfield_ledger.csv`.
- Stop a batch after 2 failed re-rolls of the same item and change approach instead of burning credits.
- Get a quote (`get_cost`) before any new model or setting.
- Pilot first; no Phase 1 spend until the pilot passes in Godot.
- Coordinate with the coding chats: the 3D Warrior rig (PRs #43–#71) owns skinning/IK/collisions; Higgsfield supplies meshes, textures and clips.

## Appendix: sprite fallback if the 3D pilot fails
Keep the Nov 13 high-angle sprite pipeline (Nano Banana stills + Seedance clips, cut to strips). Budget per character:
5 directions × (walk, attack, dodge, hit, death) = 25 clips × 12 (480p) = 300 credits + stills ≈ 320.
Two heroes + four enemies ≈ 1,900. That is why the 3D route is preferred.
