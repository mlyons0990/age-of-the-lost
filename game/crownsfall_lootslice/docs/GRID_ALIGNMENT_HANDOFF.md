# Crownsfall — grid-aligned inventory items

Current source revision: November 11, 2026 (America/New_York), Godot 4.6.3. Built on the verified Reliability + Navigation source. This release integrates and tests the Exact Item Footprints patch found in the user's AOTL Drive folder. Earlier projects and source art remain preserved.

## Required cell dimensions

All dimensions are **width × height**. Coordinates start at the upper-left; items do not rotate.

| Item | Cells |
|---|---|
| Ring, amulet | 1×1 |
| One-handed sword (`weapon`) | 1×3, vertical |
| Chest armour, Mage robe | 2×3 |
| Staff | 2×4 |
| Wand, focus | 1×2 |
| Belt | 2×1 |
| Shield, helm, gloves, boots | 2×2 |
| Mage hood, wraps, slippers | 2×2 |
| Emberwake Circlet | 2×2, inherited from hood |

Source reference: [Exact Item Footprints handoff in AOTL Drive](https://drive.google.com/file/d/1cPMVxrwplJm0MB9udLEIPrlavuQk5Svn/view). The dimensions also match the retained original systems design. `Systems.FOOTPRINTS` remains the runtime authority for inventory/stash geometry, item hit testing, overlap, sorting, equipment displacement and save coordinates. No item sizes or existing save coordinates were changed.

## What was wrong and what changed

The latest tested build already reserved the correct rectangles, but its renderer centered a square icon inside each rectangle. Tall items therefore looked detached from their occupied cells. Drag previews were square too.

The AOTL Drive footprint patch supplied 17 transparent item portraits: sixteen base types plus the unique Circlet. They derive from existing original AOTL vectors and Mage paintings, not external game artwork. These exact PNGs are included and cached separately from ability/equipment icons. Each image canvas uses its item's cell aspect ratio. The renderer now fits that portrait, without silhouette stretching, within the item's occupied rectangle. The rarity border encloses exactly that rectangle. Grid interiors covered by a multi-cell item remain occupied even where the portrait itself is transparent.

The drag ghost uses `Systems.footprint` multiplied by the source grid's effective displayed cell size. It retains the picked pixel, including a grab from the bottom of a sword, and works at responsive panel scales. Equipment-to-bag ghosts use the backpack's target scale. The hover placement overlay uses the same existing grabbed-cell offset and authoritative overlap check. Valid/invalid cells remain visible during native dragging. Only the grid under the pointer draws a drop target; inactive grids no longer project an extra red outline over the other pane.

The inspector states the actual width and height. Its new label wraps within the comparison card; an imported version of that label widened the card into the inventory dock and was corrected during regression testing.

No ownership, pricing, stat, item rotation, grid size, save schema or migration rules changed. The Reliability revision's persist-first transactions, guarded saving/exit, F5 retry and keyboard/D-pad controls remain. Stash and backpack use the same drawing and hit-test component. Merchant list and equipment icons remain compact illustrations; they do not represent inventory cell areas.

## Files and provenance

| File | Purpose |
|---|---|
| `scripts/systems.gd` | Existing unchanged cell/ownership/stat authority |
| `scripts/art_library.gd` | Cached portrait route with original-icon fallback |
| `scripts/hud.gd` | Aspect-fitted grid art, scaled/picked-pixel drag ghost, wrapped footprint label |
| `scripts/inventory_panel.gd` | Equipment drag uses the real backpack scale |
| `assets/item_portraits/` | Seventeen included footprint-shaped transparent PNGs |
| `data/item_portrait_catalog.json` | Canvas dimensions and original-art source family |
| `data/GRID_SOURCE_PROVENANCE.json` | Exact Drive patch reference and imported asset hashes |
| `tools/build_inventory_portraits.py` | Optional asset-preparation source; Pillow, numpy, CairoSVG required only to rebuild |
| `tools/verify_footprint_ui.py` | 76 static/asset/geometry checks; distinct from engine tests |
| `tests/inventory_ui_integration.gd` | 108 headless / 110 rendered assertions, including dimensions for every base type |
| `tests/grid_alignment_integration.gd` | 64 headless / 66 rendered focused grid checks and actual captures |

The imported handoff and static composition remain marked historical / non-engine evidence. Current screenshots under `previews/grid/` are actual Godot captures. Original canon/model and inventory-backplate hashes are checked during packaging.

## Verification

All twelve isolated suites pass **671 headless assertions**, including **64 grid-alignment checks** and the expanded **108 inventory UI checks**. Rendered Inventory passes 110, Town 71, and Grid 66, adding six native pointer assertions beyond headless coverage, for **677 distinct assertions overall**. Controller input tests remain simulated; no physical device claim is made.

The grid suite verifies every displayed item's aspect and occupied bounds, lower-cell selection, sword silhouette reaching all three rows, exact one-cell jewellery, unique sizing, overlap/overflow rejection, source-grid drag scale and picked pixel at five resolutions, exact saved anchors, stash transfer, and real save/reload ownership. Display-only checks force a native sword drag from its third row and release it through Godot's real GUI lifecycle. The full suite also retests purchases, buyback, mastery, unique crafting, save failures, F7 round trips, character navigation and combat.

Tested layout bounds: 1280×720, 1440×810, 1920×1080, 2560×1440, and 960×720. Rendered captures include a paired sword/armour/jewellery inventory, four-to-three view, native drag frame, and saved sword in stash. Mixed-class items in the controlled fixture demonstrate footprints; class-specific equipment rules still apply normally.

Run the complete isolated Linux checks:

```sh
python3 tools/run_checks.py --report-dir /tmp/aotl-grid-checks
```

For a rendered run, use a display, a project copy and fresh writable XDG_DATA_HOME / XDG_CONFIG_HOME / XDG_CACHE_HOME:

```sh
godot --path . --audio-driver Dummy --script res://tests/grid_alignment_integration.gd
```

The final delivery manifest records archive hashes and verification from a clean extraction of the exact ZIP. Test scripts intentionally alter their isolated fixture saves; never point them at actual progress.

## Compatibility and remaining work

Schema 5 remains in `AgeOfTheLost_Crownsfall_EncounterSlice`, legacy filename `crownsfall_encounter_v4.json`. The prior schema imports and exact `.pre-v5` snapshot remain. No migration is needed from the Reliability build. Open the extracted `project.godot` in Godot 4.6.3.

This is a source project, not a tested native Windows executable. Physical controller testing, human art/typography review, complete service/card controller routes and actual gear appearance on the actor remain future work. The separate F7 proxy lab and original sources are retained. No new media generation or paid credits were used for this correction.
