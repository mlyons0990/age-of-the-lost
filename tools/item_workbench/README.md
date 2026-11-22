# AOTL item workbench — first implementation

Standalone read-only audit of the selected Git commit. No game source, rig, HUD, save or balance edits. Python 3 standard library; Git required.

Run from any checkout:

```
python tools/item_workbench/audit.py --repo . --ref HEAD --out /tmp/aotl-item-review
python -m unittest discover -s tools/item_workbench -v
```

Open the generated `index.html` in a browser. It provides searchable item cards with a 48px cell grid, correctly proportioned canvases, embedded PNG portraits when available, and explicit placeholders otherwise. This is a data/art review tool, not a drag-and-drop inventory simulation.

`report.json` records the exact commit, source hashes, item dimensions, equipment slots and classified findings. `exceptions.csv` is the triage list. JSON duplicate keys are rejected. Checks cover canonical ring/amulet/sword footprints, invalid dimensions, selected-art footprint disagreements, orphan mappings, duplicate selected IDs, missing tracked files and PNG canvas proportions.

Git LFS pointers are not images. Fetch selected portrait assets with `git lfs fetch origin main --include='game/crownsfall_lootslice/assets/art_expansion02/portraits/*'`. The auditor reads checksum-verified local LFS objects when present. It does not download or alter artwork itself.

First snapshot: ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b, 16 base definitions, zero exported-data footprint errors. Four types have no explicit selected portrait: consult the generated report for IDs. These are unresolved selected-profile mappings, not proven missing artwork; runtime fallbacks and the candidate taxonomy library require a subsequent reconciliation pass.

Limits: no live Godot drag/equip/save behavior tested, no alpha/silhouette visual approval, no wearable mesh or ground-drop audit, no other developer branches changed. Five focused validator tests pass. The larger taxonomy, fallback resolver and equipment-production matrix are next; do not interpret this initial snapshot as production signoff.

## Reconciliation update

Run `python tools/item_workbench/reconcile.py --repo . --ref HEAD --out /tmp/aotl-item-review` to trace the four previously unresolved mappings and compare relevant entries in the 62-entry candidate catalog. All four have tracked item-portrait fallbacks. There are five footprint-compatible suggestions; the 1x4 quarterstaff is excluded from direct replacement of the 2x4 runtime staff. Candidate selection is not approval or activation.

`routing_source.sha256` pins the inspected runtime resolver; reconciliation stops for manual review if that implementation changes. Nine focused tests pass. The grid audit now recognizes tracked item-portrait fallbacks. The initial snapshot is retained as history, superseded by the reconciliation report. Runtime import, alpha coverage and gameplay appearance still need engine/visual review.
