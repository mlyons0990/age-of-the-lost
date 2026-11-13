# Phase A — Original Armor Variants (Six)

**Status:** six original Higgsfield PNG illustrations generated, converted to transparent inventory textures, 32/64px readability reviewed, isolated Godot 4.4.1 QA **81/81 passed**. **Review only; not installed in playable Crownsfall.**

## Production archive

[Open full source and verified QA archive (10,071,665 bytes; 39 ZIP entries)](https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/814babe8-cb4b-4ce4-9f57-a578157492d1.zip)

Higgsfield Developer Files media ID: `814babe8-cb4b-4ce4-9f57-a578157492d1`

The archive includes six original 1024×1024 source images, transparent RGBA masters at **128 pixels per grid cell**, runtime-size PNGs at **64 pixels per grid cell**, 32px and 64px light/dark contact sheets, alpha conversion tool, JSON QA manifest, Godot QA script, and captured 81/81 passing headless log.

Runtime-size artwork is also committed under [transparent_inventory](./transparent_inventory), with one named PNG per item.

| Named variant | Current Godot base ID | Footprint | Current class |
|---|---|---:|---|
| Crownwarden Cuirass | armor | 2×3 | Warrior |
| Epochweave Robe | robe | 2×3 | Mage |
| Bastion Sallet | helm | 2×2 | Warrior |
| Veilbound Hood | hood | 2×2 | Mage |
| Dawnsteel Gauntlets | gloves | 2×2 | Warrior |
| Wayfarer's Greaves | boots | 2×2 | Warrior |

All items are original **named variants**, not replacements for standard base gear. They must use the existing base footprints and equipment restrictions in `game/crownsfall_lootslice/scripts/systems.gd`; no change to saved-game schema, loot rules, class restriction, or player stats is authorized by this art review.

## Quality gates

- Source images retained and checksummed: **6/6**.
- RGBA masters and runtime-size PNG dimensions, nonempty alpha, and transparent gutters: **6/6 PASS**.
- Light/dark preview at 32 and 64 pixels per inventory cell: **reviewed, no obvious hard rectangular matte blocks**. Fine-zoom edge inspection and final game UI review remain useful.
- Godot **4.4.1 stable isolated** test using the existing production `systems.gd` and `art_library.gd`: **81/81 PASS**, including class exclusion, legal equip slots, inventory placement, item naming roundtrip and image texture import. Results in the archive.
- Full playable game scene with drag/drop, Quartermaster, stash, disk save/load: **NOT RUN FOR ARMOR VARIANTS**.
- **Paid credits: 0**. All artwork used Higgsfield Ultra unlimited.

## Next integration

Create a separate integration branch from the latest playable branch, add named variant creation and item portrait routing for these six items, verify actual scene and save-state persistence, and only then merge. Keep the game on the original branch untouched until validation.
