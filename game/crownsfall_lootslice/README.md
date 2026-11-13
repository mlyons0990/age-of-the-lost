# Age of the Lost — Full-Square Skill Artwork

November 12, 2026. All nineteen implemented base abilities plus Ember Aura now use crisp grimdark full-square artwork in the action bar and Grimoire. Each image uses a tightly cropped action composition, with the subject and supporting artwork extending to the edges of the square inside the thin button frame. Clean contours and controlled shading preserve readability. Each icon has its own beveled metal frame, following the user-approved AOTL standard. Hotkeys, cooldown shading/numbers, active-aura ON state and low-mana borders remain live overlays. Earlier approved symbols and equipment artwork remain preserved.

[Latest handoff: Dodge Roll](docs/DODGE_ROLL_HANDOFF.md) adds a Space-bound evasive roll with a HUD button. [Actor-feedback handoff](docs/ACTOR_FEEDBACK_HANDOFF.md) covers damage recoil, charge lean, death/corpse poses and respawn resets. [Skill-art handoff](docs/FULL_SKILL_BUTTONS_HANDOFF.md) explains the approved source atlas, exact IDs and reproduction. The right-docked equipment/character sheet, exact inventory footprints, stat scaling and schema-six saves remain included. The earlier [art integration handoff](docs/ART_INTEGRATION_HANDOFF.md) records the preceding cycle.

## Play

1. Import `project.godot` in **Godot 4.6.3** and wait for asset imports. This is the tested Linux version; other versions/platforms remain unvalidated. This source package is not a Windows executable.
2. Choose Warrior or Mage and name your Wayfarer. Mage has five starting spells, staff/wand/focus equipment and its own painted directional art. Inventory, stash, vendor, discovery and the Scar remain functional.
3. Recover the plaza stone memory with E. Mage earns a mastery point every five levels from 20 to 60. M opens its Ashen Ward graph. F6 is a development level shortcut; the three validated records under `data/example_builds/` provide faster isolated demonstrations.
4. At level 40, invest Tempered Ward → Ember Aura → **one** of Cinder Bloom / Siphon Embers. The default Ashen Ward slot becomes Ember Aura without changing the saved ability ID. Press 3 to toggle it. It costs 10 mana to start, then pays each pulse; natural regeneration is reduced while active. Equip a burn source for Bloom.
5. At the recovered stone memory, a level-40 Mage can attune Emberwake Circlet once for 250 gold. Equip it in the head slot. It changes real pulse cadence and extends existing burns. Inventory space/currency failure consumes nothing.
6. Press **T** for the Unwritten Cantor briefing, then Enter the Cantor trial. Warnings lock at creation; dodge the lane, circles and ring. At half health a second verse begins. R retreats. Each victory grants level-scaled gold, 20% level XP and one gear drop. The current build records victories; see `docs/ENCOUNTER_SYSTEMS.md`.
7. F7 enters the independent 3D rig lab from town; F7/Escape returns with the same saved build. The lab uses a 58-bone/six-clip geometric proxy and its own training values.

| Input | Action |
|---|---|
| LMB / hold; Shift+LMB | Move or primary action; primary in place |
| RMB / 1; 2; 3; 4 | Four additional equipped slots |
| Q | Health potion |
| Space | Dodge Roll toward the cursor |
| I; C; K / B; M | Equipment; character stats; Grimoire; Mage mastery graph |
| F; N | Collect nearest drop; inspect nearby loot beside backpack |
| E; R; T | Nearby service; open/close Scar or retreat from trial; trial briefing |
| Escape; F11; F3 | Close/pause; fullscreen; navigation overlay |
| F5 | Save current state / retry a storage error |
| F6; F7 | Development level shortcut; independent 3D lab |

The Grimoire's list and long effect/assignment column scroll independently. Pause has independent sound-effects and dialogue settings, including voice volume and subtitles; preferences are separate from progression. The Quartermaster greeting and two Cantor lines form the selected [dialogue pilot](docs/SELECTIVE_DIALOGUE_HANDOFF.md).

## Included work

Two playable classes, nineteen base/shared ability definitions plus the Ember Aura variant, five mastery nodes, one functional named unique, sixteen item bases and validated inventory/handedness/class restrictions. Mage art has 35 frames across five source facings (eight screen directions with mirroring). The selected Expansion02 profile adds thirty ability/service icons and twelve equipment portraits. Twenty-one earlier painted runtime icons, a bonus source book, 39 original SVGs, blue/gold modal skin, portrait and thirteen procedural sound cues are retained. Original canon boards remain unchanged.

Higgsfield source images, prompts/job configurations and reproducible processing scripts are included. All **51 inherited derived PNG/WAV files** rebuilt byte-for-byte in Higgsfield's sandbox. A rejected combined GIF is clearly marked and excluded from gameplay. The clean front modeling reference is an image for future 3D work, not a mesh/rig. No paid Higgsfield credits were consumed; the requested Tripo mesh still quoted 9 against 1.5 available.

## Saves

Independent namespace: `AgeOfTheLost_Crownsfall_EncounterSlice`; file `crownsfall_encounter_v4.json`, **schema 6**. Current resources/cooldowns, mastery ranks, once-only unique attunement, ownership and progression persist. The optional validated `encounter_wins` counter persists too; earlier schema-4 records default to zero. Ground gold, potions and items now persist too. Active aura, patches, casts, enemies and trial state do not. F7 saves successfully before cancelling transient effects and changing scenes. Offline cooldowns stay frozen.

Manual schema-2/3 import is opt-in: copy a backup into this new namespace with the new filename before launch. Older records gain unspent points, never an automatic transformation, heal or resource reset. Never overwrite the original record to perform migration. Future schemas activate write protection. See the demo-build README for isolated fixture use.

## Verification

Use isolated QA data directories. The suites deliberately create/change test progress.

On Linux the verified helper creates separate disposable user-data directories automatically:

```sh
python3 tools/run_checks.py --report-dir /tmp/aotl-qa-report
```

For manual runs, isolate data first and use:

```sh
godot --headless --path . --editor --quit
godot --headless --path . -- --systems-test
godot --headless --path . -- --mage-test
godot --headless --path . --script res://tests/lab_roundtrip.gd
godot --headless --path . --script res://tests/art_audio_integration.gd
godot --headless --path . --script res://tests/mastery_integration.gd
```

Current total: **994 headless assertions across 17 suites**, including 40 dialogue checks, 54 actor-feedback checks and 75 skill-art checks. The actor-feedback suite also passes its 54 checks rendered, with seven native review captures. Current complete logs are in `tests/dialogue_qa/`; prior skill-art logs remain in `tests/skill_tiles_qa/`. Earlier native inventory/town/grid tests add six historical pointer assertions; those were not rerun in this cycle. The source ZIP excludes caches and live progress. Tuning exports and validated example builds remain under `data/`.

Remaining production work includes human encounter/economy tuning and audio review, Windows export/target hardware testing, additional character animation, real gear attachment visuals and the production 3D Mage. Current 2D clothing/staff are baked into the sprites. The lab remains an independent proxy testbed.

## Authored encounter and next work

The Cantor is new implemented prototype content, using the inherited Revenant body and a new Higgsfield briefing portrait. It is not a newly animated enemy rig. Four seeded, fixed-step scripted bouts completed: level-one Mage/Warrior and level-forty Bloom/Siphon. These are component-level gameplay measurements, not human difficulty or frame-rate results. Read `docs/ENCOUNTER_SYSTEMS.md` and `data/encounter_scripted_bouts.json` for conditions. Next priorities are human readability/economy tuning, Windows/target-hardware checks, actor hurt/dodge/death and equipment visuals, then a production 3D Mage.

## Save upgrade

This build imports schemas 2–5 and writes schema 6 with persistent ground_loot and buyback_stock. The legacy filename/namespace and 10×6 bag coordinates are retained. Before upgrading, the prior valid primary is copied exactly once to .pre-v6. The older pre-v5 snapshot behavior remains when importing schemas below 5. Earlier builds protect schema six instead of dropping its new ownership data. Read docs/LOOT_RECOVERY_HANDOFF.md before rollback.
