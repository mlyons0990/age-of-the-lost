# Memory Sigil inventory-context review

## Result
Recommend the existing painted Memory Sigil for an isolated integration proposal. The candidate matches the warm metal and ivory materials of neighboring gear and remains identifiable on the actual dark inventory backplate. No source artwork was edited and no production mapping, inventory geometry or other developer's code was changed. No credits spent.

## Evidence and limits
Three Chromium compositions use the actual `assets/ui/inventory_backplate.jpg`, existing selected/fallback gear PNGs, exported equipment-slot coordinates and source-derived fit/scaling rules from baseline ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b. Each shows current and proposed amulet artwork with illustrative neighboring equipment and bag items. These are review compositions, not live Godot screenshots. Full text/buttons, rarity-dependent coloring, vector frame overlays and interaction states are not reproduced.

- 1920x1080: panel scale 1.0, equipment amulet canvas 26px, backpack canvas 40px.
- 1440x900: panel scale approximately 0.859, equipment canvas 22.3px, backpack canvas 34.4px.
- 1280x720: panel scale approximately 0.682, equipment canvas 17.7px, backpack canvas 27.3px.

The equipment slot is 48x56; its art bounds remove 8 horizontal and 24 vertical pixels, followed by the shared 3px inset on each edge. The resulting square canvas is 26px. Backpack cells are 50px, with a 2px item rectangle inset and 3px art inset, producing a 40px square canvas. This is why an isolated 48–64px icon preview overestimates actual equipped-item detail.

Candidate silhouette and gold/ivory contrast survive the smallest tested layout; fine sundial marks do not. The old lavender outline remains recognizable but is less consistent with painted gear. Retain a larger inspect/tooltip portrait for detail. Any enlargement of the equipment slot should be a separately owned UI task, not silently bundled with this art change.

All images loaded in the browser captures. Exact measurements and background hash are in measurements.json. The preceding isolated Godot candidate fixture already passed 67/67 portrait checks; those are historical results for the candidate, not new live-inventory tests in this step.

## Proposed integration contract
Copy the exact existing candidate bytes from `art/item_taxonomy/2026-11-12/runtime_items/aotl_jewelry_amulet_002.png` into a game asset directory and add `portraits.amulet` in selected_art_profile.json. Preserve the current fallback and all stable IDs. Add provenance with asset ID, source path, SHA-256 and 1x1 footprint. Proposed patch is described in integration_proposal.json, not applied.

Before merging a runtime change: rerun import/portrait checks on the integration branch and exercise the real inventory's inspect, equip, unequip, bag placement and save/reload flows. Coordinate ownership of selected_art_profile.json with the other developer. This review does not certify those interactions.

## Reproduction
Self-contained context_*.html files embed the exact image bytes. Open them in a browser without external downloads. PNG captures show the same HTML rendered at device scale 1; viewport labels describe the game's panel scale being modeled, not the browser screenshot dimensions. build_context.py records the source-derived composition and expects the previously prepared local portrait fixtures and Git LFS objects. No runtime game or save files are required to view the saved HTML.
