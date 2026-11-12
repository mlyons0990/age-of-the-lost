# Age of the Lost — Item taxonomy artwork

This library expands the 62-slot equipment art taxonomy from the earlier Higgsfield source manifest. It is an independent Godot art-review project, not a gameplay release. Open `project.godot` with Godot 4.6.3 and press F5; use the left/right arrow keys to browse and click an item to inspect it. Click again or press Esc to return. The catalog and export report state each candidate's actual width × height in square inventory cells.

`runtime_items/` contains footprint-normalized transparent PNG candidates at 128 pixels per cell. `generated_sources/` preserves the exact downloaded Higgsfield originals, including superseded takes; inspect `asset_sources.json` to identify the selected source region. `prior_sources/` preserves the five earlier full-size source paintings. `catalog.json` supplies stable IDs, names, art briefs and readiness. `EXPORT_REPORT.json` records source/crop/output geometry. `ART_QA.json` records automated geometry and alpha checks. Native Godot captures live in `previews/`.

The exporter measures the visible silhouette while ignoring alpha below 8/255 for bounds only. It preserves the pixels' original alpha, crops the selected region, scales proportionally and centers it with transparent gutters. It never stretches equipment, paints over a source or removes a background. Alpha failures require an image-generation edit or a replacement source.

The user's uploaded PC snapshot and the Exact Item Footprints handoff were reviewed before production. See `PC_REVIEW.md` for reconciliation. The older uploaded Crownfall project does not replace the validated Loot Recovery baseline. The separate Equipment Art Pass01 image patch is also preserved; this library does not silently overwrite it.

The 62 slots include proposed future equipment categories and two distinct sceptre variants. The optional future arquebus remains unproduced: two mixed-sheet requests returned no usable image. Its brief is retained and it is excluded from selected-art counts. These entries do not unlock classes or items, change combat/stat scaling, or alter saves. `runtime_enabled` remains false until a deliberate gameplay integration. No loose-gem equipment category is added.

For integration, select an approved candidate, copy its PNG to the desired item portrait route, and keep the existing item footprint data authoritative. Review at actual inventory scale in both classes, stash, merchant, drag preview and comparisons before publishing an art swap. A candidate's 128-pixel cell resolution is an image format choice; it does not set gameplay grid-cell size.

Rebuild technical exports with `godot --headless --path . --script tools/export_items.gd`; validate with `python tools/validate_art.py` (Pillow required). Capture the native review with `godot --audio-driver Dummy --path . -- --capture` in a rendered environment. Source files and generation submission logs remain available for another artist to revise each design.

The initial prepare_catalog.py brief builder is historical; do not rerun it over the reviewed registry. Use the selected-source mapping and actual production logs when revising artwork.
