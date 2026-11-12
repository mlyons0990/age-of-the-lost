# AOTL — INTEGRATION STATUS, GAPS & NEXT DEVELOPER GATES
2026-11-11; this document reflects actual supplied files and static inspection, not new Godot runtime verification.

## Trusted integration decision

**Authoritative gameplay branch = Drive 2D Crownsfall Systems expansion.** It has the strongest evidenced inventory, services, progression, UI and data model. Preserve GDScript source, stable item UIDs, save schema, and original test harness. **3D experiment = isolated rig lab**; do not migrate unvalidated data/UI scripts from the older 3D build into the gameplay branch. The older 3D handoff's inventory implementation differs from the Drive implementation (10×8 stash vs Drive 10×6 stash, separate save files, automatic sales vs explicit merchant). These must NOT be overlaid by blind copy/paste.

### Observed vs. claimed

- Both ZIPs passed Python ZIP CRC integrity checks. The Drive source contains `tests/HEADLESS_RESULT.txt` and `tests/RENDERED_RESULT.txt` reporting 52 passing checks for the original Drive branch, plus true Godot 2D inventory and combat preview images. This is strong upstream evidence but does **not** validate this merged scene.
- `models/AOTL_Wayfarer_Articulated_Proxy.glb` JSON has one skin with 58 joints and six animations with 24 channels each: Idle, Walk, Run, Slash, Dodge, Cast. This proves exported animation curves exist, **not** believable human motion or compatibility with the current 2D player.
- Godot and Blender executables were not available in the consolidation runtime. There is no fresh F5/F7 capture, runtime performance measurement or Blender deform inspection. Current merged scene is **PENDING RUN TEST**.
- World art files are hand-painted concept/sprite images, not 3D geometry. No true 3D Crownsfall town meshes were supplied.

## Status matrix

| System | State in this package | Acceptance gate |
| --- | --- | --- |
| Painted Crownsfall plaza + enemy waves | Upstream tested 2D, retained | Import/F5 + manual encounter |
| 10×6 backpack and ten paper-doll gear slots | Upstream tested game logic, retained | Grid/drag, ownership UID, full bag checks |
| 10×6 stash, merchant and Lorecasting services | Upstream tested 2D branch, retained | No loss/duplication, service range |
| 11 runtime techniques, five assignable actions | Upstream tested 2D, retained | CD identity, unlock and timed hit checks |
| 24 SVG icons and Grimoire UI | Implemented prototype, not approved final art | Polish, scaling and accessible controls |
| Stats, six attributes, L20/L40 progression | Implemented Warrior systems with future proposals | 13-class implementation and balance |
| Rigged 3D model 58 joints/6 animations | Source present; metadata inspected | Godot import and Blender deformation, clip names and visual comparison |
| Independent 3D combat lab | Code and scene present; untested here | F7 scene switch, input, collisions, hit/VFX timing |
| Canon six references | Copied unchanged | Hash match source, side-by-side review |
| Save schema | Drive schema2, preserved | Isolated save-test; F7 save/reload |
| 3D gameplay integration | **Not implemented** | Inventory/spells/AI running on 3D player |
| 3D Crownsfall world | **Not implemented** | 3D traversable town and correct scale |
| Production 3D visuals and animation | **Not implemented** | Approved 3D art and IK, blended combat |

## Priority gates

### P0 — Run and stabilize consolidation (required before art expansion)
- [ ] Import with Godot 4.6.3 on Windows (record exact version, renderer, GPU and import warnings).
- [ ] F5 creates, names, moves and attacks; I opens bag; K opens Grimoire; E/R services.
- [ ] F6 remains level-up (old Drive semantics). **F7** enters the separate rig lab. F7/Escape returns. Try F7 after save, with panels closed.
- [ ] Verify actual GLB import includes Skeleton3D and AnimationPlayer with six clips; if Godot prefixes library paths, adapt `_play()` to actual imported animation names.
- [ ] Walk/run/dodge/cast; 3D hit dummies take damage; scene returns without losing items/gold/player name.
- [ ] Run 52 system checks in an isolated save copy, not user's actual progress; check `tests/` and no new errors.
- [ ] Save a Windows F5/3D GIF or screen capture; don't substitute existing software-preview GIF.

### P1 — Canonical 3D art quality
- [ ] Rebuild facial/hair/armor topology, silhouette, proportions, painterly materials and color blocking against 3 Mage/Rogue/Mail Wearer references.
- [ ] Full armature twist/finger/hands, foot/toe and knee IK, grounded contacts; clean elbow/knee motion; realistic weight shifts and cloth.
- [ ] Clip blending (8-way locomotion, attacks, dodge, cast), proper combat time events and VFX on socket; avoid rigid body-part twisting and sliding feet.
- [ ] Captured footage of each pass alongside original reference; approval required before replacing proxy.

### P2 — Shared mechanics adapter
- [ ] Extract stable item/spell formula interface from `systems.gd` / `game_data.gd` without copying UI code to 3D.
- [ ] Define 2D/3D-neutral event contract for `attack_started`, `contact`, `impact`, `loot_acquired`, `equipped` and `spell_unlocked` (signals with typed IDs).
- [ ] Bind actual inventory item visuals to 3D armor/weapon slots with correct model sockets, gear footprints and legal slot checks.
- [ ] Use same save data and item ownership once tested; **do not** migrate old 3D ZIP's separate inventory/save logic.
- [ ] Implement Mage Fire, Frost and Arcane specialization foundation and five active skills with real effects, then extend other classes incrementally.

### P3 — UI and content polish
- [ ] Replace SVG placeholders with designed vector/painted icons, ornate but legible dark blue-black/gold panels, proper item art, rarity cues and full tooltip comparisons.
- [ ] Keyboard, mouse and controller focus, resolution-scaled UI, options, sound, subtitles and accessibility review.
- [ ] True variable footprint bag drag/drop with tested rotation policy; ring2 comparisons, two-handed/dual-wield, equipment restriction logic, account stash policy.
- [ ] Implement 13 base classes and class resources; three L20 paths per class with matching L40 heroic identities and 5 active slots. No standalone automatically unlocked signature passives.
- [ ] Author actual quests, Lorecasting memories, replayable combat content and 3D Crownsfall with stairs/water/trees/props, depth and lighting. Keep the erased royal guard and Unwritten storyline canon separate from test dummies.

## Locked project direction

- PC-first isometric painterly anime fantasy rendered as **2.5D with fully rigged 3D characters**, not pixel-sprite endgame art and not chibi. Character proportions near realistic anime, Sword Art Online faces, premium ARPG legibility.
- Warm bright Crownsfall surface and mystery/horror beneath. Original six images are locked style baseline; design does not drift to low-poly / 1990s appearance.
- Ixll is developer codename only; players choose names.
- 13 base classes, L20 specialization, L40 heroic identity, five active skills, six attributes: Strength, Dexterity, Vitality, Intelligence, Wisdom, Charisma.
- Inventory layout: helm up top; weapon/offhand flanking chest, gloves/belt/boots lower, two rings and one amulet, no character portrait inside inventory; backpack grid with footprint-specific item sizes.
- Lorecasting unlocks hidden history; Chronicle Engine epoch resets, The Unwritten are erased people/civilizations; story reveal beneath Crownsfall must be handled deliberately.

## Contributor instruction

Work on the **consolidated project**, create a dated new ZIP after each tested milestone, update this checklist and keep the old archives intact. Never claim finished production art or fully playable 13 classes because a preview or JSON registry exists. Provide actual Godot captures for motion, screenshots for UI, a test log and a file hash manifest in each delivered revision.
