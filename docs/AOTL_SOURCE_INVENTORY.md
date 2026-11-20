# November 20 development checkpoint

[Current aotl source inventory](checkpoints/2026-11-20-reference-hud/AOTL_SOURCE_INVENTORY.md)

# AOTL Source Inventory (2026-11-20)

1. **Windows desktop AOTL folder:** not accessible — this is a cloud container with no attached machine. Reconciliation task: attach the PC via Remote Control and diff it against `main` and the dev branches below.
2. **GitHub** `mlyons0990/age-of-the-lost`: 76 branches. 3D lineage R39 (#57/#60) → R50 (#66) → R52 audit (#68) / R52 rigid armor (#67, most advanced, contains R50) → **R53** (`dev/r53-warrior-deformation-v1`). 2D game on `claude/import-crownfall-godot` (#1).
3. **Google Drive:** AOTL folder and `Claude_Code_Crownfall_Godot43` backup folder; the R50 folder linked in the directive holds R50/R51/R52 binaries per the R52 QA doc.
4. **Latest Godot project:** `game/crownsfall_lootslice` (4.6.3) for 3D; `crownfall/` (4.3) for the playable 2D ARPG.
5. **Latest editable Blender source:** `art/character_sources/AOTL_R53_ArmSkin_Source.blend` (R52 content + arm weights).
6. **Latest model:** `models/AOTL_Warrior_R53_ArmSkin_SevenClip.glb` (opt-in); stable fallback R39/R40 unchanged.
7. **Baseline chosen:** R52 rigid armor (#67) because it contains R50 and passed 994/994 plus its own suites — re-verified here.
8. **Backups:** new-name LFS files only; nothing overwritten. Drive gets docs/previews (binaries over ~3 MB cannot go through the Drive connector).
