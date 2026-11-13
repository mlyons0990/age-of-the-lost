# Age of the Lost — Phase A: Relics, Consumables and Crafting Materials

**Status: original art complete; non-equipment gameplay NOT integrated.**

Six original illustrations were generated with Higgsfield GPT Image 2.6 Ultra unlimited (**zero paid credits**), processed with separate alpha masters and runtime PNGs, and reviewed at 32px and 64px on both light and dark backgrounds.

[Open complete original + RGBA + QA archive (9,173,268 bytes, 27 files)](https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/dafa0595-0e8d-42ea-8eb7-963139c0ed24.zip). Higgsfield Developer Files media ID: `dafa0595-0e8d-42ea-8eb7-963139c0ed24`.

| ID | Named variant | Proposed type | Footprint | Proposed stack cap |
|---|---|---|---|---:|
| chronicle_heart | Chronicle Heart | relic | 2×2 | 1 |
| unwritten_seal | Unwritten Seal | relic | 1×2 | 1 |
| embermend_phial | Embermend Phial | consumable | 1×1 | 10 |
| moonglass_tonic | Moonglass Tonic | consumable | 1×1 | 10 |
| epoch_iron_ore | Epoch Iron Ore | material | 1×1 | 99 |
| riftglass_shards | Riftglass Shards | material | 1×1 | 99 |

## Validated results

- Original 1024px source artwork retained, conversion script and checksummed files in the archive.
- Transparent 128px-per-cell masters and 64px-per-cell runtime previews: six of each.
- Grid dimensions, alpha gutters, and archive integrity: **6/6 PASS**.
- Visual 32/64px dark/light contact sheets examined. **Unwritten Seal has a visually opaque center** and should receive close-up alpha review before production.
- Isolated Godot **4.4.1 stable** art-import test using actual production `art_library.gd`: **43/43 PASS**.
- New prototype inventory planner using production `systems.gd` as a legacy footprint reference: **61/61 PASS** for proposed non-equipment footprints, stack limits, atomic placement, collision, overflow, and data roundtrips. Source and test in [prototype](./prototype).
- No live Godot UI, use action, crafting station, quest item or persistence deployment test yet.

## Why this branch is art-only

The current `game/crownsfall_lootslice/scripts/systems.gd` only accepts existing equipment slots. `clean_item` rejects any item with `slot` not in `NAMES`. Mapping consumables to rings or amulets would introduce invalid equip behavior and misleading stat bonuses. Therefore **no additions to playable loot, merchant stock, item type catalog or schema-six saved data** have been made.

The stack planner is purely experimental. In a future distinct integration PR, design an item discriminator for equipment vs consumable/material/relic, item-specific metadata, stack count and max, a transactional use/consume action, drop/pickup, vendor/stash UI, crafting inputs and recipe validation, unique relic/quest restrictions, persistence migration and backward compatibility. Review any game balance choices before activation. Run regression tests for legacy saves and equipment to avoid reinterpreting existing `slot` values.

## Integration gate

1. Review the six new art assets in the target inventory UI at 32px and 64px/cell and fix any alpha halos.
2. Implement non-equipment inventory model on a new isolated integration branch; do not mutate schema six in place.
3. Test stacking, split/merge/transfer, transaction rollback, consumption and crafting, vendor pricing, inventory rearrangement and save/reload against legacy saves.
4. Keep draft until an actual playable build is verified. Existing equipment integrations remain in [PR #32](https://github.com/mlyons0990/age-of-the-lost/pull/32) and [PR #35](https://github.com/mlyons0990/age-of-the-lost/pull/35).

**Current working game unchanged. No paid Higgsfield credits used.**
