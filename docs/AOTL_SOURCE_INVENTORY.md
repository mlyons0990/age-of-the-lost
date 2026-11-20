# AOTL Source Inventory — Phase A (verified 2026-11-20)

| Source | Status | What it holds | Verdict |
|---|---|---|---|
| **Windows desktop `AOTL`** (Mikes-Computer) | Listed in Remote Control, **not offered to cloud sessions** (likely the Claude app there needs updating) | Unknown — not inspectable from this session | **Open task:** update the Claude desktop app or run a session on that PC, then diff against GitHub |
| **GitHub** `mlyons0990/age-of-the-lost` | Inspected | 2D game `crownfall/` (Godot 4.3, PR #1); 3D lab `game/crownsfall_lootslice/` (Godot 4.6.3) with R39→R52 (#57–#68), R53 #70, R54 #71, R55 #73; Higgsfield pilot branch `art/higgsfield-pilot-knight-2026-11-20`; resource register PR #72 | **Authoritative and newest** |
| **Google Drive** folder `10WKq_…` | Inspected (read-only) | R37–R52 handoffs, QA zips, `AOTL_R52_RigidArmor_Source.blend` (24,230,888 B), `AOTL_Warrior_R52_RigidArmor_SevenClip.glb` (7,253,104 B), R50/R39 GLBs, GIF previews | Byte sizes match GitHub R52; **stops at R52** (GitHub is ahead) |
| **Drive** `Claude_Code_Crownfall_Godot43` | Backups from this session | 2D handoffs, R53–R55 summaries, pilot images | Mirror of GitHub summaries |
| **Higgsfield** "AOTL — Master Humanoid Rig V01" | Inspected (read-only) | 11 uploaded files (R39–R52 artifacts; e.g. `ebd7aff9…` is the R52 GLB zip CI downloads) | No generated models to reuse; duplicates of GitHub artifacts |
| **Higgsfield** "AOTL — Crownsfall Citadel Stair & Gateway Sculpt V01" | Inspected (read-only) | No listable assets | Nothing to reuse |
| **Higgsfield** generations | Inspected | Knight A-pose ref `10bf053c…`, Meshy knight `f88409b4…`, Roll_Dodge clip `186cf374…` | All downloaded into GitHub (pilot branch) |

## Latest verified assets
- **Stable gameplay fallback:** R39/R40 Warrior (unchanged; default in every scene).
- **Hand-built rig line:** R55 `models/AOTL_Warrior_R55_ClipSafeElbow_SevenClip.glb` + `art/character_sources/AOTL_R55_ClipSafeElbow_Source.blend` (opt-in; 994/994 regression).
- **Pilot knight (new art):** `models/higgsfield_pilot/knight_pilot.glb` (Meshy mesh + 24-bone rig; Slash/Walk/Run/Idle/Cast retargeted from R55 for free, Roll_Dodge library clip) + `art/higgsfield_2026-11/pilot/knight_pilot_source.blend`.

## Corrections to earlier notes
- "Patch" in the owner's plan is **patch.gg** (asset catalog; per-asset licenses, see PR #72), not a typo.
- PR #72 register: Spine Hero (no license — methods only), Patch (per-asset licenses), SpriteFusion normals (MIT), SpriteCook (article), Magic Asset Workshop (paid — not authorized), ChatGPT Pixel Effects (MIT; principles only, avoid pixel style).

## Baseline decision
GitHub is the development baseline. Work stays on opt-in branches; nothing has been merged into stable.
