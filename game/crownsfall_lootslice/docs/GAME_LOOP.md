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

## Controls

LMB move / attack / pick up / talk · Shift+LMB attack in place · Q W E R T skills · RMB / MMB skill wells ·
1–5 potions · Space dodge · I or C inventory · M map (Tab world) · Esc pause · F1 key bindings (all rebindable).

## Balance (first pass)

- Hollowling dies in ~3 hits at level 1; elites ~3× life, boss 8×. Monster damage reduced by armour/(armour + 10·level + 40).
- A full clear of Whisperwood (92 monsters) takes a Knight from level 1 to about 6–7 with quest rewards.
- Potions scale with level; Crownsfall tops health potions up to 3 and heals you.

## Known limits

- Monsters are the original painted 2D enemy art standing in the 3D world (three types). Dedicated 3D monster models,
  more enemy types and a Hollowmere chapter are content work, not system work.
- NPCs reuse the hero models (no dedicated NPC art yet).
- No skill tree in this mode yet (the 2D build's mastery graph is not wired in); skills are the hero's four.
