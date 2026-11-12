# Age of the Lost — Painted 2.5D Art-Lab / Phase 01

**Experimental, non-destructive.** This is a small playable 2.5D art-direction lab, *not* a conversion of the save-bearing LootSlice into 3D. It answers the visual production question: Can AOTL keep the approved anime-painted character while moving through a genuine 3D world with an isometric camera?

## Source review and reuse

Reviewed: [AOTL GitHub source](https://github.com/mlyons0990/age-of-the-lost), [current Drive folder](https://drive.google.com/drive/folders/12yXmW4fFu6rsoqxYgfiEYm3_ibgG0Px8), *AOTL Artwork Library — Equipment, Abilities and UI — November 12*, 2026, and existing artwork/hand-off material in the user's AOTL Drive folder. Inspected full 2026-11-12 actor-feedback source ZIP and original six canonical images.

| Existing source | Reuse in this phase |
| --- | --- |
| `assets/knight/idle_*.png`, `walk_*.png`, `attack_*.png` | Actual painted Warrior character, 5 source directions, mirrored for 8 screen facings. Walking uses 384×384 frames; attack is 512×512 per frame. |
| `assets/mage/idle_*.png`, `walk_*.png`, `cast_*.png` | Painted Mage; class toggle in 2.5D lab (Tab). |
| `assets/plaza.png` | Original Crownsfall artwork shown as a reference panel, *not* incorrectly used as a 3D ground texture. |
| `references/canon_originals/03_Mail_Wearer_Official(1).png` and the other five | Approved visual standard for proportions, detailed blue/gold armor, royal banners, atmosphere and buildings; these files are not paint-over textures and remain unchanged. |
| `models/AOTL_Wayfarer_Articulated_Proxy.glb` | Existing 58-bone proxy shown when pressing **V**. No new paid mesh or rig was generated. |
| `scripts/three_d/rig_effects.gd` | Existing slash/cast/ring/spark effects (placeholder VFX). |
| `scripts/three_d/training_dummy.gd` | Existing resettable combat targets, 3 instances. |
| `scripts/three_d/rig_controller.gd` | Movement/animation contract consulted, not modified. |
| Main 2D `scripts/player.gd`, `scripts/main.gd`, HUD, inventory, saves and mastery | Preserved, untouched. |

## Run and compare

1. Use Godot **4.6.3** (the version used by the validated LootSlice). Install Git LFS and fetch assets (`git lfs pull`) if cloning from GitHub. The Drive source ZIP already includes game assets.
2. Import `game/crownsfall_lootslice/project.godot`, wait for the editor to import GLB/PNG files.
3. Open `res://scenes/two_point_five_d/aotl_25d_lab.tscn` and press **F6** (Run Current Scene). Do *not* use F5 unless you want the unchanged main 2D game.
4. WASD or left-click to move; Shift to sprint; Space to dodge; 1 slash; 2 heavy; 3 cast; **V** toggles painted sprite versus old 58-bone geometric proxy; **Tab** toggles Warrior and Mage. Click+Shift slashes. Esc quits the lab.
5. Compare painted character proportions and animation clarity at the orthographic 3D camera, especially against the actual `03_Mail_Wearer_Official(1).png` artwork.
6. From the project root, run `godot --headless --path . --script res://tests/two_point_five_d_smoke.gd` for the 15 opt-in smoke checks, then run `python3 tools/run_checks.py --report-dir /tmp/aotl-regression-25d` (Linux, disposable save directories only).

## Engineering choices

- Character is a real `CharacterBody3D` with capsule collision, gravity, orthographic follow camera, click-to-move plane intersection and WASD movement; **painted visual is a camera-facing `Sprite3D`** loaded directly from the original transparent source strips. No AI redraw or lossy re-export.
- Walk/idle/attack/cast animations remain deliberate facings and original sprites. This avoids wasting credits for an inferior generic mesh while preserving the possibility of a genuine 3D pipeline later.
- Using the preexisting 3D proxy is a *visual toggle only* for before/after comparison. Its inherited six animation clips remain subject to their original rig. It does not change the 2D game.
- The **stone 3D floor, columns, lighting and dummies are diagnostic blockouts**. They are not approved Crownsfall level art, collision/navigation meshes, or a claim that the 3D world already matches the painting.
- Color grading, orthographic camera scale, sprite pixel size, original frame orientation and scene lights may need tuning after a real Godot render. No character equipment is attached in the 2.5D experiment.

## Known gaps / not yet delivered

- **No true illustrated dodge roll:** there are no approved roll sprite sheets in the current art set. The painted visual presently uses a short walking/lean placeholder during 3D dodge movement. A future pass must author/test 8-direction illustrated roll frames or use a higher-quality rigged version, then review head and cloak continuity.
- Warrior has no painted spellcasting animation. Until one is authored, the Warrior's 3D cast mechanic displays a borrowed attack sequence. Mage uses the existing cast sprites.
- The torso/armor layering, swept silhouette and painterly highlights are as-good-as-existing painted sprite sources, but we have not matched the published six references pixel-for-pixel at every direction or pose.
- No new gear attachments, proper 3D shadow receiver, depth-masked props, terrain navigation, background-aligned 3D architecture, IK, 3D VFX style pass, full RPG system migration, or release export in this phase.
- **QA status:** source and sprite dimensions audited; new Godot scene and smoke tests authored. This tool session could not execute Godot (no local binary available). Do not claim the smoke tests or frame rendering passed until a real engine execution is recorded.

## Next milestones (before using paid Higgsfield credits)

1. Run the 2.5D lab with Godot and collect screenshots of Warrior/Mage at 8 facings, idle/walk/attack, plus proxy toggle; check clipping, foot placement, feet shadows, texture filter, and camera readability.
2. Confirm whether runtime 3D with Sprite3D painted characters meets visual quality. Compare with a high-quality pre-rendered 3D-to-sprite candidate using the **same camera**, not different backgrounds.
3. If 2D billboard sprites win visually, author the missing 8-way dodge/attack/cast sprite frames for the original hero; implement depth-mask foliage and equipment overlay templates, while reusing current Godot gameplay systems.
4. Only if a true painted 3D model beats sprites **at gameplay size** should the future 3,000 Higgsfield credits go to high-detail geometry, texture painting and retargeted animations. Retain a single shared humanoid skeleton contract, with class-specific variants when appropriate.

**Preservation:** Existing 2D main game, original F7 rig lab, all artwork, 954-assertion legacy baseline, and save schema 6 are unmodified. This test is intentionally not merged into the main scene.