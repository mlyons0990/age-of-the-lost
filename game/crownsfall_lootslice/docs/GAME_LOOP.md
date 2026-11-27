# Age of the Lost — the playable game (Chapter I: The Whisperwood)

`run/main_scene` is now `scenes/title.tscn`. The labs (`scenes/*_lab.tscn`) and the original 2D build (`main.tscn`)
are unchanged and still open directly.

## Flow

Title → **Continue** (saved character) or **New Game** → choose **Knight** or **Mage** → Crownsfall.

| Step | Where | What happens |
|---|---|---|
| A City Reborn | Crownsfall | Talk to Captain Ralden (click him, `!` over his head). |
| The Lost Tomes | Whisperwood | Three guardian elites (Flower Dell, Fae Ring, Standing Stones) each carry an Archive Page. Walk over a page to collect it; return to Ralden (`?`). |
| The Thornwarden | Whisperwood, Mossy Meadow | Boss (appears only on this quest): telegraphed slams, summons Hollowlings at half life, boss bar. Return to Ralden. |
| Epilogue | Crownsfall | Chapter summary; keep playing (farm, gear up, explore). |

## Systems and how they connect

```
game_state.gd (character record, saved in user://aotl_save.cfg [game])
  ├─ level / XP (game_data.xp_need)  ──> stats (systems.derive: life, mana, damage, spell power, armour, crit)
  ├─ gear + bag (systems.gd item model) ──> stats ──> hero max life/mana, attack damage
  ├─ gold, potions ──> shop, potion belt (counts on the wells)
  ├─ quests, slain guardians/boss ──> NPC marks, tracker, minimap + map markers, which monsters spawn
  └─ zone + position ──> Continue puts you back where you were
game_director.gd (inside the 3D world, rig_lab.gd game_mode)
  ├─ data/encounters.json ──> monster.gd packs (level 1–5 rising west→east), guardians, boss
  ├─ hero attacks ──> rig_lab.attack_damage() = attack base × gear/level scaling × crits
  ├─ monster strikes ──> armour reduction ──> hero; death ──> death screen ──> respawn in Crownsfall
  ├─ kills ──> XP, level-ups (full heal), loot (gold, potions, gear by level and rarity, quest pages)
  ├─ data/quests.json ──> dialogue, rewards (XP, gold, Rare/Legendary item), next quest
  └─ autosave: zone change, level up, quest steps, item pickups, equip, every 30 s, Save & Exit
game_ui.gd: notifications, area banner, boss bar, dialogue, shop, inventory + character (I / C), death, pause (Esc), epilogue
```

## Skills (K) — added 2026-11-27

Six skills per class (`scripts/game/skills.gd`), learned by level, ranked 1–5 with one skill point per level
(+14% damage per rank), one of two upgrades chosen at rank 3. The Quartermaster refunds all points for 25 gold × level.
Skills play the hero's existing animations; the director resolves each skill's own shape and effects.

| Knight | Lv | Shape | Upgrades |
|---|---|---|---|
| Slash (LMB) | 1 | arc | Rending Edge (bleed) / Riposte (+mana) |
| Cleave | 1 | wide arc | Great Arc (all around) / Staggering Blow (knockback + stun) |
| Shield Charge | 3 | dash, stun | Relentless (3.5 s cd) / Shockwave (end burst) |
| Rallying Cry | 5 | heal + 30% damage | Second Wind (40% heal) / Iron Will (−30% damage taken) |
| Sundering Standard | 8 | delayed circle at cursor | Broad Standard / Quake (stun) |
| Citadel Reprisal | 12 | nova, life per hit | Bulwark / Repel |

| Mage | Lv | Shape | Upgrades |
|---|---|---|---|
| Cinder Thread (LMB) | 1 | bolt, +mana | Kindle (burn) / Siphon (+mana) |
| Glacial Stitch | 1 | piercing line, slow | Shatterline (pierce all + freeze) / Deep Cold |
| Arcane Fold | 3 | blink to cursor | Frost Wake / Quickened Fold |
| Ashen Ward | 5 | damage shield | Thick Ash / Ember Burst |
| Starfall Script | 8 | delayed circle at cursor | Wide Sky / Scorching Fall (burn) |
| Winter Crown | 12 | nova stun | Sovereign's Reach / Long Winter |

| Rogue | Lv | Shape | Upgrades |
|---|---|---|---|
| Twin Cut (LMB) | 1 | arc, +mana | Envenomed Edge (poison) / Quick Hands (+mana) |
| Fan of Knives | 1 | wide arc, slow | Whirling Fan (all around) / Barbed Knives (bleed) |
| Shadowstep | 3 | blink to cursor | Ambush (strike where you land) / Fleet (3.5 s cd) |
| Smoke Veil | 5 | heal + −35% damage taken | Deep Smoke (−55%) / Assassin's Focus (+35% damage) |
| Blade Dance | 8 | dash through enemies | Flurry (end spin) / Hamstring (slow) |
| Death Mark | 12 | nova, bleed | Reaper (life per hit) / Wide Storm |

| Cleric | Lv | Shape | Upgrades |
|---|---|---|---|
| Smite (LMB) | 1 | arc, +mana | Searing Light (burn) / Devotion (+mana) |
| Radiant Sweep | 1 | wide arc, life per hit | Dazzle (stun) / Mercy (more life) |
| Sanctuary | 3 | damage shield | Bastion / Breaking Dawn (burst) |
| Prayer of Mending | 5 | heal 35% + −15% damage taken | Miracle (55%) / Zeal (+30% damage) |
| Dawnfall | 8 | delayed pillar at cursor | High Noon / Judged (stun) |
| Consecration | 12 | nova, burn, life per hit | Holy Ground / Absolution |

Monster statuses: slow, stun (cancels wind-ups; bosses resist half), burn (damage over 3 s), knockback (not bosses).
Mana regeneration comes from the character's stats (Wisdom). Tests: `tests/verify_skills.gd` (34 checks) and
`tests/verify_four_classes.gd` (31 checks: every Rogue and Cleric skill on real monsters).

## One hero, four classes — added 2026-11-27

The same hero (face, hair, 24-bone Meshy rig) in four outfits, chosen on the title screen with a hero name:
Knight (`models/higgsfield_pilot/knight_pilot_armed.glb`), Rogue (`models/higgsfield_rogue/rogue_armed.glb`),
Mage (`models/higgsfield_mage/mage_pilot_armed.glb`), Cleric (`models/higgsfield_cleric/cleric_armed.glb`).
Rogue and Cleric come from approved concepts (art/higgsfield_2026-11/classes) via multi-view 3D; the Knight's library
clips move onto their rigs (`tools/build_class_heroes.sh`); their weapons are free Blender props
(`tools/make_class_props.py`: twin daggers, flanged mace, painted sun shield) skinned rigidly to the hands / forearm.
Each class is a ClassData resource (`data/classes/*.tres`, written by `tools/build_class_resources.gd`); the title
offers a class only when its 3D outfit exists. Class portraits are renders of the real 3D heroes
(`tools/render_class_portraits.gd`). The Rogue's loot pool has no shields (the second dagger is its off-hand).

## Painted UI — added 2026-11-27

Every game screen is built from one painted kit that matches the HUD (bronze filigree, slate):
`assets/ui/kit` (cut by `tools/cut_ui_kit.py` from art/higgsfield_2026-11/ui_kit), helpers in `scripts/game/ui_skin.gd`.
- **Inventory — I (right):** a live 3D view of the hero in his gear in a shrine alcove, painted slots with engraved
  emblems, quick stats, bag cells.
- **Character — C (left, its own window; both can be open, as in PoE):** portrait medallion, name, level, experience
  and skill points; six attribute plaques; the skills on the bar with ranks; Offense / Defence / Journey tabs (hit of the
  primary attack, crit, damage reduction from armour at your level, regeneration, totals) from the game's own formulas.
- **Skill tree — K:** tiers by unlock level on a carved slate, socket frames (locked / learned / mastered), rank
  pips, connectors; a detail pane with rank-up and the two upgrade plates.
- **Esc:** pause menu → Options (Game: volume, combine move/attack, auto gold pickup · Display: fullscreen, vsync,
  frame-rate limit · Controls: key bindings · Profile: rename the hero); all saved in the one save file.
- Shop, dialogue, death, epilogue, tooltips, key bindings and the title / class pick use the same frame and buttons.
Visual QA: `tests/capture_ui.gd` screenshots every screen for each class.

## Controls

LMB move / attack / pick up / talk · Shift+LMB attack in place · Q W E R T skills · RMB / MMB skill wells ·
1–5 potions · Space dodge · K skills · I equipment · C character · M map (Tab world) · Esc pause · F1 key bindings (all rebindable).

## Balance (first pass)

- Hollowling dies in ~3 hits at level 1; elites ~3× life, boss 8×. Monster damage reduced by armour/(armour + 10·level + 40).
- A full clear of Whisperwood (92 monsters) takes a Knight from level 1 to about 6–7 with quest rewards.
- Potions scale with level; Crownsfall tops health potions up to 3 and heals you.

## Known limits

- Monsters are the original painted 2D enemy art standing in the 3D world (three types). Dedicated 3D monster models,
  more enemy types and a Hollowmere chapter are content work, not system work.
- NPCs reuse the hero models (no dedicated NPC art yet).
- Rogue and Cleric use the Knight's library clips (sword swing, cast); class-specific attack clips are a possible
  later Higgsfield step (8 credits each, quoted first).
- Skills reuse the heroes' existing animation clips (several skills share one); dedicated clips would come with
  more Higgsfield animation work (quoted first).
