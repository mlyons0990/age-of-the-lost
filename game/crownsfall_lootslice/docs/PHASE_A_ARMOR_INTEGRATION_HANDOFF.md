# Age of the Lost — Phase A Armor Integration Handoff

**Date:** 2026-11-13 (UTC). **Status:** six new armor item portraits installed on a stacked draft integration branch; current playable `main` unchanged.

## What changed
- Added six 64-pixels-per-inventory-cell transparent PNGs under `res://assets/item_portraits/phase_a_armor/`.
- Extended the existing `scripts/hud.gd` name-and-slot guarded artwork router to cover these named variants without replacing the default base-item portraits.
- Extended `scripts/phase_a_equipment.gd` named-item factory and the class-filtered Quartermaster stock generated **only for new characters**. Existing saved merchant inventories and saved characters remain unchanged.
- Extended `data/phase_a_equipment_catalog.json`. No modifications to `scripts/systems.gd` base item schema, item stats, loot pools, class constraints or save schema.

| Named item | Base | Grid | Allowed class |
|---|---|---|---|
| Crownwarden Cuirass | armor | 2×3 | Warrior |
| Epochweave Robe | robe | 2×3 | Mage |
| Bastion Sallet | helm | 2×2 | Warrior |
| Veilbound Hood | hood | 2×2 | Mage |
| Dawnsteel Gauntlets | gloves | 2×2 | Warrior |
| Wayfarer's Greaves | boots | 2×2 | Warrior |

All six are **original named variants**, not replacements of the gear catalog. New-character Quartermaster preview stock now includes 8 class-compatible Phase A variants for Warrior, 7 for Mage, in addition to ordinary base items; no saved merchant inventories are automatically migrated.

## Tests run
- Isolated Godot 4.4.1 art-only preview tests using copied production systems and art routing: **81/81 PASS**.
- Isolated Godot 4.4.1 integration tests combining all **12 Phase A equipment variants** with production `systems.gd`, `art_library.gd`, `town_actions.gd` and the updated `phase_a_equipment.gd`: **258/258 PASS**.
- Test coverage includes texture resource existence and correct dimensions, legal slots and class filtering, named-item factory, name persistence through clean/sanitize, purchase, inventory ownership, stash deposit/withdraw, sell, buyback, and JSON schema-six in-memory roundtrip.
- Test script committed at `tests/phase_a_all_equipment_integration.gd`.
- To run: `godot --headless --path game/crownsfall_lootslice --script res://tests/phase_a_all_equipment_integration.gd`.
- **Not claimed:** complete live Crownsfall UI session, actual disk-save and recovery regression, controller drag-and-drop or Windows export. These still require validation before merge.

## Art archive and provenance
- [Six original 1024px illustrations, cleaned RGBA masters, runtime PNGs, 32px/64px review sheets, and isolated Godot QA logs](https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/814babe8-cb4b-4ce4-9f57-a578157492d1.zip).
- Art review: [draft PR #34](https://github.com/mlyons0990/age-of-the-lost/pull/34).
- Earlier six equipment item integration: [draft PR #32](https://github.com/mlyons0990/age-of-the-lost/pull/32). This armor branch is stacked on PR #32 and should merge after PR #32, not directly into `main`.
- All images generated with Higgsfield Ultra unlimited; **0 paid credits spent**.

## Next gate
Run a fresh Godot build from the stacked integration branch on Windows to inspect the Warrior/Mage Quartermaster menu, test equipment actions and 1:1 art scale, real stash and merchant UI, and disk save/load. Do not merge until the prior branch and armor integration checks pass.
