# Historical imported patch handoff

This source patch is now integrated, corrected and engine-tested in the Grid revision. Read `GRID_ALIGNMENT_HANDOFF.md` for current claims. Statements below about unavailable Godot refer only to its original authoring environment.

---

# AGE OF THE LOST — Exact Inventory Item Footprints

**Revision:** November 11, 2026 (US Eastern). **Source:** `AOTL_Crownsfall_RightDock_Focus_Polish_2026-11-11.zip`. **Godot target:** 4.6.3.

This is the current continuation of the right-side PoE-inspired equipment/character/backpack UI. The user's acceptance rule is that every item must **look and behave** like its real inventory cell size: jewelry is 1×1; a sword is 1×3, vertical; chest armor is 2×3. The newest project includes both the current Town UI systems and the keyboard/controller focus improvements from the preceding phase.

**Get started:** extract the full archive into a new folder, open `project.godot`, allow Godot to import the new `assets/item_portraits/*.png`, then press F5. Press **I** to open equipment/backpack, **C** for character stats, **E** near stash/merchant for paired panels. All existing 10×6 backpack and stash coordinates remain valid.

## Cell dimensions (width × height)

| Item type | Grid footprint |
|---|---|
| Ring; amulet | 1×1 |
| Sword (`weapon`) | **1×3 vertical** |
| Chest armor; Mage robe | **2×3** |
| Staff | 2×4 |
| Wand; focus | 1×2 |
| Belt | 2×1 |
| Shield; helmet; gloves; boots; Mage hood/wraps/slippers | 2×2 |
| Emberwake Circlet (unique hood) | 2×2 |

The authoritative sizes already existed in `scripts/systems.gd`. **That file is intentionally unchanged.** Earlier graphics drew the item icon as a centered *square* even when its occupied item rectangle was tall. This revision creates original, transparent AOTL silhouettes whose image ratios match their actual occupied cells and draws those images across the corresponding item rectangles. Item artwork now communicates the same dimensions the inventory planner, stash, clicks, and drag/drop have always used.

## Code and data changes

- `scripts/art_library.gd`: optional cached `inventory_portrait(id)` art route. The old `_item_icon` route for equipped gear, spells and merchants stays intact.
- `scripts/hud.gd`: bag/stash render from the fitted portrait; the drag preview is a real width×height rectangle, not a 72×72 icon; the inspector explicitly states `Inventory footprint: W × H cells (width × height)`.
- `assets/item_portraits/`: 17 generated AOTL transparent sprites (16 item bases plus the unique Circlet). Vector sprites come from the bundled AOTL SVGs; painted Mage sprites derive solely from already included AOTL source paintings. No Path of Exile assets are copied or included.
- `tools/build_inventory_portraits.py`: optional reproducible original-art processing, needing Pillow, numpy and CairoSVG. It is **not required to run the game** because the generated PNGs are included.
- `tests/inventory_ui_integration.gd`: new Godot assertions for all footprints and portrait dimensions, plus the lower sword cell, ring/amulet exact 1×1 hits, armor 2×3 hit area, overlap rejection and boundary rejection.
- `tools/verify_footprint_ui.py`: 76/76 **static/image/geometry** checks; run with Python and Pillow. `tools/verify_ui_navigation.py` continues to report 50/50 existing static checks.
- `docs/figures/item_footprints_STATIC_NOT_ENGINE.png`: illustrative composition of actual generated portrait assets at their real 10×6 grid footprints. **Not a Godot engine screenshot.**

## Required Godot verification — not yet run here

The environment that built this package does not have Godot installed. Do not claim the new GDScript is engine-tested. Use an isolated test save namespace because test scripts change actor/inventory state; do **not** run them over actual user progress.

```
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/inventory_ui_integration.gd
python3 tools/run_checks.py --report-dir /tmp/aotl-item-footprint-qa
```

Then run a rendered build with an isolated save and capture the right inventory and stash at 1280×720, 1440×810 and 1920×1080. Check that (1) a 1×3 sword visibly spans three rows, (2) armor spans two columns and three rows, (3) single-cell jewelry spans only one cell, (4) item drag ghost matches occupied dimensions, (5) dragging rejects overlaps and overflow, (6) right panels don't obscure the player in ordinary gameplay. Test both classes, two-handed staff/equipped offhand swaps, full stash/bag, transactions, and save/reload.

## Compatibility and limitations

The project save remains schema 5 within `AgeOfTheLost_Crownsfall_EncounterSlice`; `crownsfall_encounter_v4.json` is the legacy filename. The item schema, UID ownership, save importer, equipment planner, grid coordinates, item footprints, player stats, merchant and stash logic were not changed. Previous phase files in Drive remain rollback copies.

The source-only checks verify exact portrait pixel dimensions and code wiring, not the appearance of actual Godot-rendered frames, controller support on hardware, or the absence of parse errors. Windows exports, accessibility review, and human art polish remain ahead. Our objective is a playable, original AOTL interface inspired by PoE's layout — not a direct reproduction of proprietary artwork.
