# Isolated runtime portrait review

Baseline: ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b. Godot 4.6.3 stable official, Linux headless.

## Result

67/67 checks pass against the exact, unmodified `art_library.gd` from the baseline. For all 16 items: load a texture through the real inventory_portrait resolver, verify footprint aspect, verify cache identity, and obtain non-empty decoded image data (64 checks). Three additional checks cover a nonexistent selected amulet path, a non-string selected mapping and profile/cache reset followed by reloading the selected weapon.

The isolated fixture contains the exact selected/fallback images, base definitions and selected-art profile, verified against Git/LFS bytes. Its source manifest records SHA-256 hashes. No production project, rig, HUD, saves or gameplay formulas changed. Import completed without script errors or warnings in the final run.

The first attempt failed before testing because the default user-data directory was not writable. The successful run sets XDG_DATA_HOME, XDG_CONFIG_HOME and XDG_CACHE_HOME to isolated temporary directories. This environment correction is not a game fix.

## Visual inspection of the four fallback PNGs

- Amulet: clearly distinguishable pendant silhouette, but flat lavender fill and simple linework are substantially simpler than the other painted gear. Prioritize a reviewed, footprint-compatible amulet candidate for a future integration proposal.
- Staff: ornate gold/cobalt painting, tall vertical silhouette consistent with its 2x4 footprint. Fine ornament is dense at small scale; review in the real inventory before approval.
- Wraps: painted ivory/gold pair with visible cloth structure and a coherent 2x2 composition.
- Slippers: painted navy/gold pair with a clear silhouette and coherent 2x2 composition.

These observations come from direct inspection of the actual PNG files, not a rendered game screenshot. They do not constitute owner/art-director approval. Full inventory interaction, tooltip placement, drag/drop, equipment changes, UI scaling and save behavior remain outside this isolated test.

## Reproduce

Fetch the selected art and fallback images through Git LFS first. In a checkout containing the workbench:

```
python tools/item_workbench/prepare_engine_review.py --repo . --ref ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b --out /tmp/aotl-portrait-fixture
mkdir -p /tmp/aotl-engine-data /tmp/aotl-engine-config /tmp/aotl-cache
XDG_DATA_HOME=/tmp/aotl-engine-data XDG_CONFIG_HOME=/tmp/aotl-engine-config XDG_CACHE_HOME=/tmp/aotl-cache godot --headless --path /tmp/aotl-portrait-fixture --editor --import
XDG_DATA_HOME=/tmp/aotl-engine-data XDG_CONFIG_HOME=/tmp/aotl-engine-config XDG_CACHE_HOME=/tmp/aotl-cache godot --headless --path /tmp/aotl-portrait-fixture --script engine_review.gd
```

The fixture builder refuses an existing output directory. `engine_results.json`, import.log/engine.log (when redirected) and source_manifest.json provide evidence. The generated project is a test fixture, not a playable game.

Next: prepare an amulet candidate comparison at the same footprint and inventory scale; keep selection separate from changing runtime art.
