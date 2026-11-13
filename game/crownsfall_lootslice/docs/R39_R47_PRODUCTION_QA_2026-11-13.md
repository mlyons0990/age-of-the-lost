# AOTL Warrior — R39 production QA / R47 experimental art handoff
Date: 2026-11-13

## Verified gameplay asset (R39)
The actual file `game/crownsfall_lootslice/models/AOTL_Warrior_R39.glb` is committed via Git LFS, backed up in Google Drive, and **not** overwritten by the art candidate. SHA-256: `6e72468f2bfa6344c66c57cd0157c36949b53d8bb24f8d30c955da5f72e0ba55`. Six independent clips: Idle, Walk, Run, Dodge, Slash, Cast. The GLB has 62 exported skinned joints and 92 skinned meshes; Godot 4.3 imports 69 skeleton bones.

## In-engine and automated acceptance
- Godot 4.6.3 full Crownsfall 17-suite regression: **994/994** checks passing on CI runs [43395624141](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43395624141) and [43396276932](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43396276932). A new run is scheduled whenever terrain changes.
- Real R39 controller in Godot 4.6.3: [runtime CI 43398797740](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43398797740) PASSED, with six actions, weapon/offhand sockets, terrain IK, and no engine ERROR lines in runtime test logs. The math gate passed 18 checks.
- Real floor, 15-cm step, and 12-degree slope collider tests: **17/17** checks passed, including ground raycasts, planted contact offset, reach-limit release, and IK on/off.
- Godot 4.3 automatic mesh LOD import emitted one nonfinite-normal warning; controlled no-LOD import emitted zero. Source glTF vertex positions/normals were all finite. Commit `models/AOTL_Warrior_R39.glb.import` sets `meshes/generate_lods=false` only for R39. It may raise distance-render cost; re-enable when clean LOD geometry is authored.
- Known Godot 4.3 headless dummy-renderer `Parameter "m" is null` teardown diagnostic was not reproduced in the 4.6.3 runtime test.

## Authentic animation preview
`previews/warrior_r39/real_walk_cycle_8frames.gif` is generated from eight real Blender Walk animation frame renders (1, 4, 7, 10, 13, 16, 19, 22), not interpolated or synthesized motion. 480×480, 110ms/frame, eight frames, SHA-256 `5c3674908766a68d0e67005fede086f9a025e48d5a96b185d02a5be0f9d3a962`. PNG frame package and GIF are backed up in Google Drive.

## Experimental R47 visual candidate
Higgsfield Revision 47 adds non-destructive two-segment micro-bevels on seven selected armor, shield and sword meshes, with revision 46 intact as parent and R39 as unchanged gameplay production baseline. Evaluated geometry is finite, preserves the 62-bone rig and six Blender actions. Two tiny boot caps have no evaluated topology change. A Workbench still was rendered; a heavier Eevee 3-frame render exceeded the five-minute remote limit. Therefore **visual approval and playable 6-clip GLB export are NOT complete**. Its archival `.blend` and *one-clip preview* GLB are backed up in GitHub LFS on `art/warrior-r47-visual-candidate` (draft PR #56), and in Google Drive.

## Release and rollback gates
Keep `main`, the previous proxy GLB, R36 authoring baseline and R37 six-clip baseline intact. R39 is on a separate draft asset PR [#53](https://github.com/mlyons0990/age-of-the-lost/pull/53); R47 stays experimental on [#56](https://github.com/mlyons0990/age-of-the-lost/pull/56). Before merging, evaluate visual fidelity against the locked Crownsfall art, inspect contact and weapon deformation during normal Windows gameplay, and reconcile any concurrent main-branch changes. Do not label R47 as the newer production model solely because its revision number is higher.
