# Age of the Lost — Crownsfall Art Integration

November 12, 2026. The accepted Expansion02 artwork is now integrated into the playable LootSlice: twelve selected equipment portraits, nineteen ability icons and eleven service symbols. Equipment appears above the exact-cell backpack on the right; the Character tab shares that dock. Selected gear uses matching art in both equipment and inventory, preserves its aspect ratio, and respects the existing footprint rules (including 1×1 jewelry and vertical 1×3 one-handed swords).

Read [the current art integration handoff](docs/ART_INTEGRATION_HANDOFF.md) for the ID map, provenance, reproduction and verification. Original art and fallbacks remain included. Stat curves, combat, transactions and schema-six saves are unchanged. The independent Knight/Godot 4.3 prototype remains a separate branch in the repository.

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
| I; C; K / B; M | Equipment; character stats; Grimoire; Mage mastery graph |
| F; N | Collect nearest drop; inspect nearby loot beside backpack |
| E; R; T | Nearby service; open/close Scar or retreat from trial; trial briefing |
| Escape; F11; F3 | Close/pause; fullscreen; navigation overlay |
| F5 | Save current state / retry a storage error |
| F6; F7 | Development level shortcut; independent 3D lab |

The Grimoire's list and long effect/assignment column scroll independently. Audio can be muted from Pause; its preference is separate from progression.

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

Current total: **825 headless assertions** (52 Warrior, 57 Mage, 28 lab, 19 art/audio, 86 mastery, 60 encounter, 15 scripted-bout, 108 inventory UI, 69 town UI, 77 reliability, 36 navigation, 64 grid alignment, 78 loot, 76 selected art), plus rendered Inventory (110) Town (71), Grid (66), and Loot (78) passes with six extra native mouse-drag checks, plus a 76-check rendered selected-art pass. This is 831 distinct assertions when the six display-only checks are included. Exact logs and engine/display modes are under `tests/`. Tuning exports and validated example builds are under `data/`. The source ZIP excludes caches and live user-data directories.

Remaining production work includes human encounter/economy tuning and audio review, Windows export/target hardware testing, additional character animation, real gear attachment visuals and the production 3D Mage. Current 2D clothing/staff are baked into the sprites. The lab remains an independent proxy testbed.

## Authored encounter and next work

The Cantor is new implemented prototype content, using the inherited Revenant body and a new Higgsfield briefing portrait. It is not a newly animated enemy rig. Four seeded, fixed-step scripted bouts completed: level-one Mage/Warrior and level-forty Bloom/Siphon. These are component-level gameplay measurements, not human difficulty or frame-rate results. Read `docs/ENCOUNTER_SYSTEMS.md` and `data/encounter_scripted_bouts.json` for conditions. Next priorities are human readability/economy tuning, Windows/target-hardware checks, actor hurt/dodge/death and equipment visuals, then a production 3D Mage.

## Save upgrade

This build imports schemas 2–5 and writes schema 6 with persistent ground_loot and buyback_stock. The legacy filename/namespace and 10×6 bag coordinates are retained. Before upgrading, the prior valid primary is copied exactly once to .pre-v6. The older pre-v5 snapshot behavior remains when importing schemas below 5. Earlier builds protect schema six instead of dropping its new ownership data. Read docs/LOOT_RECOVERY_HANDOFF.md before rollback.
