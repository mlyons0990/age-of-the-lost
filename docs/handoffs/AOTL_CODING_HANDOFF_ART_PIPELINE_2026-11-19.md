# AOTL handoff: how to spend the 3,000 Higgsfield credits (2026-11-19)

**For:** the coding agent, who will run the Higgsfield generations *and* integrate them in Godot 4.6.3 (`game/crownsfall_lootslice`).
**From:** the art chat. This sheet says **what to spend credits on, in what order, with which models and settings**, plus what worked and what failed in ~150 earlier generations.

**Balance:** ~2,998 credits. 2 were used on 2026-11-19 for a knight A-pose reference image, job `10bf053c-b6e3-4973-bb39-178b2124ff8c`; check it before making a new one. The free unlimited allowance **ended 2026-11-13**, so every generation now costs credits. Never pass `use_unlim: true`; pass `use_unlim: false`.

**Owner rules:** only original Higgsfield art. Log every job. Don't exceed the phase budgets without asking the owner.

**Owner-locked references (read these first):**
- UI and camera: `docs/reference/ui_camera_target/2026-11-19/aotl_ui_target_v2.png` + `README.md`
- Full budget reasoning: `docs/art/HIGGSFIELD_3000_CREDIT_PLAN.md`

Both are on branch `docs/higgsfield-credit-plan-2026-11-19`.

---

## 1. Prices (live quotes, 2026-11-19)

| Use | Model ID | Settings | Credits |
|---|---|---|---|
| Icons, UI pieces, item art | `gpt_image_2_6` | `resolution 1k`, `quality medium` | 0.5 |
| Character/concept stills (best identity match to references) | `nano_banana_pro` | `resolution 2k` | 2 |
| **Textured + rigged 3D character** | `meshy_v7_image_to_3d` | `should_texture true`, `enable_rigging true`, `pose_mode a-pose` | **44** |
| Same, with one animation baked in | `meshy_v7_image_to_3d` | + `enable_animation true`, `animation_action_id N` | 47.5 |
| **Each extra animation on a rigged model** | `3d_rigging` | `model_url <rig GLB URL>`, `enable_animation true`, `animation_action_id N` | **8** |
| Static 3D prop | `tripo_h3_1_image_to_3d` | defaults (`texture`, `pbr` true) | 9 |
| Premium static prop | `tripo_p2_image_to_3d` / Meshy 7 | | 34–44 |
| 4 s animation clip (2D sprites, VFX, globe swirl) | `seedance_2_0` | `mode std`, `resolution 480p`, `aspect 3:4`, `duration 4`, `generate_audio false` | 12 (720p = 18) |
| Budget 4 s clip | `kling3_0_turbo` | 720p | 6 |

Always quote first with `get_cost: true` (or `estimate_image_cost` / `estimate_video_cost`) before using a model or setting for the first time.

## 2. Spend order and budgets

| # | Phase | Budget | Gate before moving on |
|---|---|---|---|
| 0 | **Pilot: 3D knight** | ~76 | Must pass in Godot (below) |
| 1 | Heroes: Warrior + Mage | ~520 | Pilot passed |
| 2 | Enemies | ~560 | Hero pipeline proven |
| 3 | City props (3D) | ~330 | — |
| 4 | Spell/combat VFX | ~220 | — |
| 5 | UI: HUD + panels | ~120 | Can run any time; cheap |
| 6 | Icons + key art | ~80 | — |
| | **Planned** | **~1,910** | |
| | Reserve (re-rolls, optional boss, extra props) | ~1,090 | Ask the owner before dipping in |

### Phase 0: Pilot (~76): do this before anything else
1. **A-pose reference** (`nano_banana_pro`, 2 cr; already made, job `10bf053c…`). Inputs as `image_references`: the approved knight art (front + 3/4).
   Prompt pattern: *"Character model reference for 3D modeling: the exact same young knight as the reference images (…describe outfit…), clean A-pose, facing camera, arms ~45° out, legs slightly apart, cape hanging straight and ending at the back of the knees, no weapon in hand, front orthographic, even soft lighting, hand-painted anime style, plain flat light-grey background, no floor, no shadow, no text."*
2. **Rigged model** (`meshy_v7_image_to_3d`, 44 cr), from that image, with `pose_mode: a-pose`, `rigging_height_meters: 1.75`.
3. **3 test clips** (`3d_rigging`, 8 each, `model_url` = the pilot GLB's URL): Roll_Dodge (158), Left_Slash (97), Dead (8).

**Pass:** loads in Godot; all three clips play on one skeleton. At the new camera (~100 px tall) it reads as the approved blue/gold knight. The cape doesn't badly tear.
**Fail:** stop and use the sprite fallback (§8).

### Phase 1: Heroes (~520)
- Turnaround/A-pose sheets for Warrior and Mage, best of several (~32).
- Rigged models, best of 2 each (~176).
- **Warrior clips** (13 × 8):
  - Idle (0), Combat_Stance (89), Casual_Walk (30), RunFast (16)
  - Left_Slash (97), Double_Combo_Attack (92), Sword_Judgment (102) or Heavy_Hammer_Swing (128)
  - Roll_Dodge (158–163, pick by preview), Sword_Parry (147)
  - Hit_Reaction (178), Knock_Down (187), Dead (8), one interact clip
- **Mage clips** (13 × 8):
  - Idle, walk, run
  - 4 casts from Charged_Spell_Cast (125/126) and mage spell casts (129–137)
  - Charged_Ground_Slam (127), Roll_Dodge, Hit_Reaction, Knock_Down, Dead, a channel loop
- Weapons as separate GLBs: sword, shield, staff, tome (Tripo, ~36).
- Re-rolls ~70.
- Browse clips with the `animation_actions` tool. Every clip has a preview GIF.

### Phase 2: Enemies (~560)
- **Humanoids** via the same rig pipeline, ~88 each (44 model + 5 clips × 8 + stills):
  - revenant spearman
  - skeleton knight
  - thorn-bark brute (Heavy_Hammer_Swing, Charged_Ground_Slam)
  - hollowling
- **Non-humanoids** as painted sprites with Seedance 480p, 5 clips each (≈180 total): wraith (floats), corrupted wolf, stag.
  - Use the start=end-frame method in §7. The auto-rig is humanoid-only; don't try to rig these.
- Training dummy: static Tripo mesh (9).
- Optional boss from reserve (~100, ask first).

### Phase 3: City props (~330)
**11 credits per prop:** concept still (`nano_banana_pro` 2) → Tripo H3.1 (9).

~30 props:
- **Plaza features:** tiered elven fountain, banner pillar with gold crest, knight statue, angel statue, archway gate, stair set, balustrade, waterfall lip, cobble border.
- **Market and services:** market stall ×2 variants, merchant counter, noticeboard, stash chest, weapon rack, armour stand, anvil, cart, well, crates, barrels.
- **Greenery and decoration:** planter, autumn-red tree, hedge, lamp, brazier, bench, shrine, wall banner, Reality Scar rift frame.

Concept prompt tip: one object, 3/4 view from slightly above, plain light-grey background, even lighting, matching the Crownsfall palette (ivory stone, royal blue, gold trim, autumn red foliage).

### Phase 4: VFX (~220)
~16 effects × 12 cr (Seedance 480p) + re-rolls:
- **Spells:** fireball + impact, frost nova, chain lightning, arcane missile, holy smite.
- **Combat:** ground-slam crack, light/heavy slash arcs, dodge dust, hit sparks, death dissolve.
- **World and feedback:** level-up burst, potion glow, rarity loot beams, Reality Scar portal loop, waypoint swirl.

Generate on **pure black** (additive glows) or **flat green #00B140** (solid effects; never green for green/violet effects). Then key them and cut into a sheet + JSON (anchor, `impact_frame`, `loop`, `blend`). The structure from the reviewed `chatgpt-pixel-effects` repo is fine, but **skip its pixel-grid and palette-reduction steps**: they destroy painted art.

### Phase 5: UI (~120): must match UI target v2
HUD pieces (~71):
- **Globes:**
  - life globe frame with a **seated stone maiden statue on the outer left** and mana globe frame with the **statue mirrored on the right**; make each as its own image, not a runtime flip (~16)
  - red/blue liquid fills + glass highlight (~4)
  - looping liquid swirl for each globe, 2 Seedance clips (24)
- **Bars and slots:**
  - flask bar and skill bar panels with key plates (~6)
  - flask icons red/blue/green, full/empty, plus the utility map icon (~5)
  - XP bar frame, purple fill and ticks (~3)
- **Top of screen:** minimap frame + `+` button, quest tracker backing, gold diamond bullet (~4); logo (~4).
- **In-world labels:** 6 service badges (~3); nameplate + level badge (~2).

Panels in the same frame style (~50): inventory, character/equipment paper doll, rarity tooltip frames, vendor/stash windows, buttons, class portraits.

Use `gpt_image_2_6` for flat pieces, `nano_banana_pro` for the statue frames, and ask for **flat key-colour backgrounds**.

### Phase 6: Icons + key art (~80)
~30 skill icons, ~40 remaining item icons, 2–3 loading/title key-art paintings.

## 3. Camera (do before judging any art in-engine)

The owner wants it **farther out than the UI mock-up, like Path of Exile**. PoE uses a perspective camera, steeper than Diablo 2/3.

| Setting | Target |
|---|---|
| Player height on screen | ~9–10% of screen height (~100 px at 1080p) |
| Visible ground | ~26–28 m vertical |
| Pitch | 50–55° down |
| Projection | perspective `Camera3D`, vertical FOV ~30–35° |
| Zoom | mouse wheel ~0.7–1.3×, Home/R reset |

These are starting values to tune by eye. At ~100 px, prioritise bold silhouettes and colour blocks over fine detail.

## 4. HUD layout (owner-locked, UI target v2)

| Area | Contents |
|---|---|
| Bottom-left | Life globe + statue; `HP x / y` above a flask bar: slots 1–5 (red, red, red, blue, green) + utility slot |
| Bottom-centre | Purple XP bar, `Lv. 25 (current / next)` centred |
| Bottom-right | Skill bar Q W E R T; `MP x / y` above; mana globe + mirrored statue |
| Top-left | AOTL / CROWNSFALL logo |
| Top-right | Minimap + quest tracker |
| In world | Nameplate with level badge; service badges (quest `!`, merchant, Reality Scar, lore, noticeboard, stash) |

Confirm key bindings with the owner: the mock-up uses 1–5 for flasks and Q–T for skills, but the current build uses Q for the potion and RMB/1–4 for skills.

## 5. Godot integration notes

- **Clips:** each `3d_rigging` call returns the rig with **one** animation. Merge them all into one `AnimationLibrary` (a Godot import script, or the Phase 07 Blender helper with `export_animation_mode='ACTIONS'`).
- **Root motion:** strip root translation on walk/run loops and drive movement from code; keep it optional for dodge/attack.
- **Directions:** rotate the node; no per-direction art is needed.
- **Look:** use a toon/painterly shader (stepped light, rim, outline) so meshes sit with the painted city.
- **Weapons:** attach via `BoneAttachment3D`.
- **Cape:** auto-rig is humanoid and may skin the cape to the legs. Add 2–3 spring cape bones, or regenerate the reference with a shorter cape.
- **Existing rig:** the hand-built Warrior rig (PRs #43–#71: foot IK, sword collisions, hurtboxes) stays the gameplay foundation. Keep visuals swappable.
- **Props:** rescale to real metres, origin at the base, and add `NavigationRegion2D` obstacle polygons for anything on the walkable area. Decimate heavy meshes.
- **Git:** LFS uploads failed from the art sandbox (S3 auth). If that happens to you, commit art as normal files.

## 6. Lessons from ~150 earlier generations (avoid wasting credits)

- **Rate limits:** effectively **one image job and one video job at a time** account-wide. On HTTP 429, wait 1–2 minutes and resubmit; don't hammer.
- **"Bad Gateway" can still create the job.** Check `transactions` or generation history before resubmitting, or you pay twice. Image jobs from Nano Banana/Seedream may not appear in `show_generations`.
- **Black-background failures:** `gpt_image_2_6` often returns **black with a glow halo** for glowing, golden or dark subjects.
  - Add *"background stays pure flat bright green (#00B140) to the edges, no glow halo"*.
  - Or use a model with real transparency. Seedream with `background: transparent` worked well, but `seedream_5_5` is no longer listed, so check `models_explore` for its successor.
- **Nano Banana Pro** keeps identity best from reference images, but **refuses strict side profiles**: it turns them into 3/4 front. It occasionally adds a duplicate floating arm or gauntlet; add *"one single character, exactly two arms, no floating armor pieces"*.
- **Seedance clips:**
  - Set the still as **both `start_image` and `end_image`** to get clean loops.
  - Add *"camera completely locked, no zoom, flat uniform green background, no shadow, no effects"*.
  - For deaths add *"wide shot, whole body stays in frame, no push in"*.
  - For back views add *"back to camera the whole time, face never visible"*.
  - For attacks, *"big, exaggerated"* gives readable motion.
  - It adds white slash arcs even when told not to.
- **Camera angle for stills:** *"camera high above looking down at about 50 degrees, top of head and shoulders visible, body foreshortened, feet on the ground plane"* matched the PoE look on Nov 13.
- QA every result at gameplay scale (~100 px tall) before accepting it.

## 7. 2D sprite method (non-humanoid enemies, globe swirl)

1. Make a still on flat green at the high camera angle (`nano_banana_pro`, 2 cr).
2. Generate a Seedance 480p 4 s clip with start = end = that still (12 cr).
3. Key the green and cut it into 384×384 strips (512×512 for attacks) on a fixed foot baseline, with a JSON sidecar (frames, fps, loop, hit frame).

Tools that do this are in the art chat's history; the Nov 13 strips are on branch `art/high-angle-actors-21m`.
Directions `down, se, right, ne, up`; mirror for west.

## 8. Sprite fallback (if the 3D pilot fails)

Same as §7 for the heroes too. Each character needs 5 directions × (walk, attack, dodge, hit, death) = 25 clips × 12 = 300 credits + stills ≈ 320. Two heroes + four enemies ≈ 1,900 credits, which is why the 3D route comes first.

## 9. Logging (required)

Keep `art/higgsfield_2026-11/LEDGER.csv` with: date, phase, asset, model, credits, job ID, accepted/rejected, note.
Stop after **2 failed re-rolls** of the same asset and change approach. Report spend per phase to the owner when each phase ends.
