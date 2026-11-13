# Age of the Lost — Phase A: six magical offhands and jewelry variants

## Current QA state
**VISUAL ART + ISOLATED GODOT IMPORT/INVENTORY CHECKS: PASSED.** **FULL PLAYABLE-GAME REGRESSION: NOT RUN.**

[Get verified production-QA archive (9,656,680 bytes; 56 ZIP entries)](https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/2c767f70-001a-417e-b668-1facb11fa277.zip) — Higgsfield Developer Files media ID `2c767f70-001a-417e-b668-1facb11fa277`.

Includes all six untouched 1024px Higgsfield original PNGs, six transparent RGBA master textures (128px per inventory cell), 64px-per-cell preview PNGs, exact-size **32px** and **64px** two-background contact sheets, manifest and hashes, GrabCut conversion script, source metadata, QA report, the isolated Godot project with the exact production `systems.gd` and `item_base_definitions.json`, runnable `qa_runner.gd`, and captured Godot output.

| Equipment item | Base family | Inventory (W×H) | Classes allowed by current rules |
|---|---|---:|---|
| Crownfall Aegis | offhand (shield) | 2×2 | Warrior |
| Chronicle Codex | focus | 1×2 | Mage |
| Emberglass Focus | focus | 1×2 | Mage |
| Oathkeeper Signet | ring | 1×1 | Warrior, Mage |
| Veilthorn Band | ring | 1×1 | Warrior, Mage |
| Wayfarer's Locket | amulet | 1×1 | Warrior, Mage |

**Important compatibility correction:** Initial preview defined two Mage magical offhands at 2×2. Actual `main` game source `scripts/systems.gd` and `data/item_base_definitions.json` assign Mage focus a **1×2** footprint; both codex and Emberglass Focus masters were remade to 128×256 (64×128 preview). No runtime footprint definitions were altered.

## QA performed (November 13, 2026 UTC)
- Inspected each image against both light and dark UI backgrounds, including **32px and 64px per cell**. Silhouettes remain recognizable and no obvious hard rectangular matte block was observed. The pendant chain and codex should still get final in-game readability review.
- ZIP integrity: PASS. Source checksums captured. All six RGBA8 PNG master dimensions and transparent border gutters: PASS.
- Installed/ran Godot **4.4.1 stable** in an isolated Higgsfield sandbox using **the actual production `scripts/systems.gd`** and **`data/item_base_definitions.json`** copied without gameplay modification.
- **79/79 headless QA checks passed**: PNG loading, RGBA8 formats, GPU ImageTexture creation, cell-sized portrait dimensions, UI drag preview sizes, source footprint agreement, bag insertion, overlap rejection, grid overflow rejection, actual equip-slot destinations, mage/warrior class permissions, bag sort, and in-memory JSON roundtrip.
- No known regression from these isolated tests.

## Outstanding (must run on playable Godot project before release)
1. Load the six validated textures into actual Crownsfall item portrait mapping on a separate integration branch.
2. Test equipment panel at gameplay scale, live drag/drop, merchant transactions, stash, tooltips, equip/unequip interactions and restrictions.
3. Run actual schema-six **disk** save/reload and backups with equipment variants.
4. Validate inventory appearance under the real game's font/UI lighting; refine any apparent alpha halo, missing thin detail, or excessive empty-space silhouettes.
5. Only then approve integration/merge; this PR remains a draft with **no changes** to playable game, loot tables, item stats or save format.

To repeat the isolated test, unpack `godot_qa/project` and execute `godot --headless --path godot_qa/project --script res://qa_runner.gd` using Godot 4.4.1 or a compatible later 4.x build.

Previous eight forged weapons remain on [draft PR #12](https://github.com/mlyons0990/age-of-the-lost/pull/12).
