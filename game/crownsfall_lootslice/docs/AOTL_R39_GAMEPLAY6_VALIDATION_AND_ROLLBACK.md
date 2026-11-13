# AOTL Warrior R39 — Verified six-clip playable asset

Date: November 13, 2026

## Production outcome

**Asset:** `game/crownsfall_lootslice/models/AOTL_Warrior_R39.glb`

**SHA-256:** `6e72468f2bfa6344c66c57cd0157c36949b53d8bb24f8d30c955da5f72e0ba55`

**Binary:** 7,028,800 bytes; glTF 2.0 GLB; 92 skinned meshes, 62 exported skin joints, one skin, six separate actions. Godot 4.3 reconstructs an imported 69-bone Skeleton3D; this differs from the exported skin-joint count and is not silently conflated.

**Actions:** Idle (1.56667 s), Walk (0.8 s), Run (0.6 s), Dodge (0.76667 s), Slash (0.73333 s), Cast (1.36667 s).

## Authoring and backups

- Higgsfield master: project `088e8199-50e8-4554-b0be-b108a6b2203a`.
- Revision 36: complete experimental IK/animation authoring backup.
- Revision 37: clean production six-action character.
- Revision 39: material response candidate used for this exported asset.
- Individual action snapshots: Walk R41, Run R42, Dodge R43, Slash R44, Cast R45, Idle R46.
- Original playable proxy and older R36/R37 fallback paths remain intact.
- Both the descriptive `AOTL_Warrior_R39_Gameplay6.glb` and controller-compatible `AOTL_Warrior_R39.glb` refer to the same LFS object/hash.

## What was actually tested

1. Deterministic single-action GLB assembler validated static node indices, mesh mappings, skin maps, six animation channel sets, and buffer boundaries.
2. Local GLB parser confirmed the six clip names, 92 skinned meshes and binary checksum.
3. GitHub Actions asset import completed: `43392584336`, including strict binary checks and Git LFS commit.
4. **Godot 4.3 headless asset import PASSED:** `43393154387`. The GLB loads with 69 imported bones, 92 skinned MeshInstance3D nodes, six named animation clips, and nonempty animation durations.
5. **Godot 4.3 playable controller gate PASSED:** `43394082796`. Actual `rig_controller.gd` selects `warrior_r39`, exposes six actions, initializes runtime terrain-foot IK and equipment sockets, plays Walk/Run and toggles IK on/off.

These tests run in isolated minimal Godot 4.3 projects. They are **not** a full Crownsfall game regression suite or a visual gameplay review.

## Known diagnostics

- Godot import prints `WARNING: Ignoring face with non-finite normal in LOD generation.` Raw GLB POSITION/NORMAL arrays are finite, triangle face areas are nonzero, and imported skinned meshes are present. Investigate Godot LOD generation before promotion.
- The Godot 4.3 headless dummy renderer prints `ERROR: Parameter "m" is null` on test shutdown after PASS. The test process still exits successfully. Determine whether this comes from dummy rendering teardown and fix if reproducible in gameplay.
- The final painterly appearance, foot contact behavior on live terrain, and full Crownsfall scene performance still require in-engine visual QA.

## Safe installation

1. From the asset branch, pull both the repository and Git LFS data (e.g. `git lfs pull --include="game/crownsfall_lootslice/models/AOTL_Warrior_R39.glb"`).
2. Open `game/crownsfall_lootslice/project.godot` in Godot 4.3 or newer.
3. Open the 3D rig lab. The HUD should display `warrior_r39` unless a validated newer R40 asset takes priority.
4. Check Idle/Walk/Run/Slash/Dodge/Cast animations. Use F9 to compare runtime terrain IK on/off, F10 to view foot targets, and F11 for equipment-socket QA if enabled by the rig-lab build.
5. If any regression occurs, restore the prior Git branch or remove the R39 asset; the controller automatically falls back through older versions.

## Release status

**Verified import candidate, not merged into main.** Preserving the stable main branch and the other developer branches remains the first requirement.

Google Drive binary backup and CI logs are preserved in the project's R37/R39 production export folder.
