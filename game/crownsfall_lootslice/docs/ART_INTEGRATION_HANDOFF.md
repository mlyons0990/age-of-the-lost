# Selected artwork in the playable LootSlice

November 12, 2026. Current source is the self-contained `game/crownsfall_lootslice/` project on GitHub. This revision builds on the exact verified November 11 Loot Recovery ZIP, not the separate Knight-focused Godot 4.3 fork. That fork retains its own branch, controls and saves.

## What changed

All 42 accepted Expansion02 designs now have deliberate runtime selections: 12 equipment portraits, 19 existing ability icons and 11 UI/service symbols. No new item types or abilities are implied. `data/selected_art_profile.json` maps accepted source IDs, source paths, provider and SHA-256 hashes to actual runtime IDs/files. The complete artwork libraries and source sheets remain in the repository's `art/` folders.

`art_library.gd` reads the profile and falls back to the original painted/portrait/vector art when a selection or resource is absent. Original assets remain byte-for-byte intact. The named unique Emberwake Circlet, unselected jewelry/staff and actor/canon art retain their earlier art. Selection does not add stats or a new variant to saved items.

Equipment and bag views now use the same portrait. The equipment renderer fits that portrait proportionally inside the slot and reserves its caption area; it no longer stretches a tall weapon into a square or rotates a wand diagonally. The real 10×6 bag coordinates remain authoritative. One-handed swords are 1×3 vertical; rings and amulets remain 1×1. Selected runtime portraits retain the established 64 pixels per cell. The review library keeps its higher-resolution 128-pixel-per-cell masters.

Ability paintings appear in the hotbar and Grimoire. The implemented Ember Aura variant keeps its original dedicated art. Interface symbols decorate labeled Equipment/Character tabs, inspection/comparison, equip/unequip, stash/withdraw, buy/sell, pickup, memory recovery and unique crafting controls. Text and existing callbacks remain present. Linear filtering applies to HUD controls; actor texture filtering is unchanged.

## How to play and review

Import this project's `project.godot` in Godot 4.6.3; wait for import, then run. Choose Warrior or Mage. I opens equipment above the backpack on the right; C opens the character sheet in the same dock; K opens the Grimoire. E uses a nearby service, N inspects nearby loot, F collects the nearest drop. Stash/merchant panels pair on the left. Existing mastery, Cantor trial, F7 lab and save recovery are included. Full controls are in the main README.

The source ZIP contains runtime assets and does not need the separate art-library download to play. GitHub users must install Git LFS and run `git lfs pull` before opening the project. This is Godot source, not a Windows executable.

## Verification and preservation

All 14 automated headless suites pass: **825 assertions**. Rendered passes: Inventory 110, Town 71, Grid 66, Loot 78 and Selected Art 76. Inventory/Town/Grid add six real pointer-drag checks beyond the headless set: **831 distinct assertions** overall, not the sum of repeated runs. Runtime art/source file hashes also pass 84 checks; these are counted separately from gameplay assertions.

The new 76-check suite exercises all selections, missing-profile/resource fallback, real ability IDs, footprint dimensions, both classes' equipment fit/caption clearance, shared bag/equipment art, actual controls/Grimoire, a live memory-recovery callback and crafting icon routing and a valid schema-six save. Native screenshots cover Warrior/Mage inventory, comparison and Grimoire. The existing rendered suite captures the right-docked Character view. These are actual Godot captures of controlled QA fixtures.

`tests/art_integration_qa/` contains the complete logs and summary. `data/ART_INTEGRATION_PRESERVATION.json` records byte comparisons against the exact baseline. All original art/reference/model files are preserved; player, main, game-data, mastery, encounter and town transaction scripts are unchanged. Stat scaling, ownership, footprints, cooldowns, gameplay rules and save schema 6 remain established behavior.

The namespace remains `AgeOfTheLost_Crownsfall_EncounterSlice`, filename `crownsfall_encounter_v4.json`. Continue to back up compatible progress before switching source revisions. No real player progress was used in QA. Test runners require disposable data directories because they intentionally create saves.

## Reproduce

On Linux run:

```sh
python3 tools/run_checks.py --report-dir /tmp/aotl-qa
python3 tools/verify_selected_art.py
```

When the full repository is available, also verify accepted sources:

```sh
python3 tools/verify_selected_art.py --library ../../art/expansion02/2026-11-12
```

Equipment portraits are technical downsamplings of accepted transparent library art. `tools/import_selected_portraits.gd` rebuilds the twelve outputs with Godot's Lanczos interpolation and checks both source and output hashes. Run it with isolated writable XDG data/config/cache directories on Linux, and `godot --headless --path . --script res://tools/import_selected_portraits.gd -- --library /absolute/path/to/art/expansion02/2026-11-12`. Ability/UI textures are byte-identical copies of the library's `runtime_sizes/128/` files. No generation, background removal or semantic painting is part of this import.

`tools/build_transfer.py --destination /outside/project` builds the complete source ZIP and hash manifest. Live saves, caches and logs outside the curated QA folder are excluded. Documentation screenshots may be compacted in the Drive ZIP to meet the upload cap; full native captures are preserved in GitHub and the visual review PDF. Runtime and original art are never compacted by that helper.

## Provenance and next development priorities

Expansion02 consists of seven source sheets generated with OpenAI image_gen, with original bytes and source regions retained in its library. Earlier Higgsfield art retains its own provider/provenance. No new generation was needed for this integration cycle.

Next: human playtesting of inventory/full-container and encounter readability, Windows/target-hardware export validation, then a controlled actor hurt/dodge/death and equipment-appearance prototype. A wider item taxonomy needs explicit gameplay definitions and balance before its candidate pictures become new gear types. Current 2D clothing/staff are baked into actor sprites; selected inventory equipment does not yet change the actor's outfit. The independent F7 3D proxy is unchanged.

Godot 4.6.3 Linux/X11 software OpenGL and Dummy audio are the tested environment. Human difficulty/economy tuning, Windows binaries, hardware performance and production audio review remain unvalidated.
