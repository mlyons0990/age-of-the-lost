# Autonomous equipment and inventory batch

Source baseline: ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b. Changes stay in standalone tooling/reports; active game code, HUD, rigs, data and saves are untouched. No generation or paid credits used.

## 1. Real inventory-rules verification
Godot 4.6.3 runs the exact baseline systems.gd in an isolated fixture: **1600/1600 checks pass**. An independent cell-occupancy oracle covers all 16 types across coordinates from outside the bag through both edges, with an occupied cell. Other cases cover exported/runtime footprint and destination agreement, ignoring a moving item's own occupancy, full-bag insertion without mutation, failed sorting without mutation, and mixed-item sorting with UID preservation and legal placements.

This tests actual pure game rules, not a copied mock implementation. It does not test pointer events, player equip transactions, persisted saves or live HUD integration. Assertions are scoped evidence, not a statement that the whole game is complete.

## 2. Equipment-art readiness register
**62 unique catalog entries; 61 tracked textures.** The only missing catalog texture is `aotl_ranged_arquebus_002`, explicitly optional and unproduced. This is not treated as a release defect. All 62 entries are marked runtime-disabled in this candidate catalog, which is separate from the selected Expansion02 runtime art.

The CSV tracks inventory-art availability and separately marks ground drops, wearable visuals and character-sheet integration as unverified. It does not claim those assets are missing from other developer branches. A PNG portrait alone is not an equipped model.

## 3. Portrait integration contracts
Five explicit proposals cover four game IDs: amulet, staff (two alternatives), wraps and slippers. All match current footprints. Choose exactly one staff candidate; the 1x4 quarterstaff is excluded for the 2x4 runtime staff. Each contract retains fallback paths, source hashes, slots and provenance requirements. No proposal is automatically enabled. The amulet has prior comparison/engine evidence; remaining candidates still need equivalent visual/import review.

## 4. Current balance measurement
The actual Systems.make_item generator produced **10240 seeded samples**, grouped into 320 item/level/boost scenarios, with min/max/mean damage, armor, HP, crit, spell power and vendor value. JSON and CSV are included. Levels: 1, 10, 20, 40, 60; 32 samples per scenario.

Important: scenarios -2 and +2 force the lowest/highest rarity. +0.56 and +0.84 are mixed-tier boost scenarios because make_item adds a random roll; they are NOT clean rarity-specific balance curves. Do not infer drop rates, combat DPS, player survivability or fairness from this dataset. The sample is finite and summaries are descriptive. Existing formulas and seeds are preserved; no rebalance was applied.

## Reproduce
Open the portable fixture with Godot 4.6.3 or run:

```
XDG_DATA_HOME=/tmp/aotl-engine-data XDG_CONFIG_HOME=/tmp/aotl-engine-config XDG_CACHE_HOME=/tmp/aotl-cache godot --headless --path /path/to/fixture --script batch_checks.gd
python art_readiness.py --repo /path/to/repository --ref ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b --out /tmp/aotl-readiness
```

Create the writable XDG directories before running. The portable fixture includes exact systems.gd and item-base data; manifest.json records their hashes. Avoid using real player save directories. Balance CSV is a flattened representation of balance_baseline.json.

## Next owned work
Review remaining staff/wraps/slippers candidates at real slot sizes, then propose isolated selected-art integration. Add player transaction/save tests only against a clearly selected source baseline. Review rarity-specific balancing with controlled inputs before proposing numeric changes. Keep optional arquebus production out of launch-critical work unless its scope is explicitly selected.
