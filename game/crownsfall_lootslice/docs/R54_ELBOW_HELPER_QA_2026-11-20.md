# Age of the Lost — R54 Warrior Elbow Helper

**Branch:** `dev/r54-elbow-helper-v1` (from R53 `dev/r53-warrior-deformation-v1`; opt-in, stable R39/R40 untouched)
**Playable scene:** `res://scenes/r54_elbow_helper_combat_lab.tscn` (Godot 4.6.3, F6)

## Problem
R53 left the elbow crease as the worst region: 63% p95 worst-frame edge strain at 35–40 cm along the arm.
Two-bone linear-blend skinning averages transforms ~65° apart there, which pinches the inner elbow.

## Change
- The never-keyed **Elbow** bone (child of UpperArm, parent of Forearm) becomes a helper: in every clip it is keyed
  to **half of the forearm's swing** about the forearm head; twist about the forearm axis is excluded.
  Forearm is re-keyed with the inverse, so hands, weapon and shield are unchanged.
- Elbow-window skin uses quadratic Bernstein weights UpperArm (1−t)² / Elbow 2t(1−t) / Forearm t²
  over the elbow ± 24 cm (centre +2 cm). Shoulder, twist and wrist blends are R53's.
- Parameters came from grid searches over every second frame of all seven clips (RMS strain + ½·p99 worst-vertex).
  Searches rejected: a full-rotation helper (sheared the forearm through twist) and asymmetric windows (worse overall).
- Blender source: `tools/r54_elbow_helper.py` bakes Elbow/Forearm keys on every frame (Euler-continuous, LINEAR).
  GLB: `tools/r54_patch_glb_elbow_helper.py` applies the same math to glTF local transforms of the verified R53 GLB.

## Results (armature-only LBS, all 7 clips, every 2nd frame; Blender-evaluated after baking)

| Mesh | R53 mean p95 | R54 mean p95 | R53 worst frame | R54 worst frame | worst-vertex p99 |
|---|---:|---:|---:|---:|---:|
| ArmL | 3.18% | 2.37% | 31.37% | 24.29% | 53.2 → 38.6% |
| ArmR | 4.76% | 3.49% | 31.37% | 24.29% | 53.9 → 38.6% |

Right arm worst-frame p95 by band (R53 → R54): crease 25–30 cm 39→20%, 30–35 cm 48→23%, 35–40 cm 63→33%, 40–45 cm 39→25%.
**Trade-off:** the window's ends got worse: 15–20 cm below the shoulder 9→39%, and the wrist side 55–65 cm 11–16→33–39%
(the latter mostly under the rigid forearm guard). A narrower window keeps the edges but loses most of the crease gain.

Hand pose after the Blender bake: max drift 3.7e-7 (armature space) at every 3rd frame of every clip.

## Godot 4.6.3 verification (executed here)
- `tests/verify_r54_elbow_helper_import.gd`: **46/46**: weights normalized, at most 4 influences, Elbow carries crease weight,
  all R52 armor/clip/foot checks, plus hand/weapon/shield/forearm global poses vs R53 at 61 times per clip, including times between keys.
  Max drift: Slash 1.43 mm, Cast 0.20 mm, Idle 0 (Godot interpolates the re-keyed rotations between 30 fps keys). Helper swing 32–34°.
- `tests/verify_r54_scene_entry.gd` **10/10**; `tests/verify_r54_live_rig_lab.gd` **17/17**; R53 suite still 41/41.
- Full regression `tools/run_checks.py`: **994/994 across 17 suites**.
- Real renders (`tests/capture_r54_elbow_compare.gd`): `previews/warrior_r54/r54_vs_r53_*.jpg` (full body),
  `r54_vs_r53_elbow_*.jpg` (right-elbow close-up, `--elbow=R`), `r54_slash_godot.gif`.
  The close-up shows the R53 inner-elbow kink replaced by a smooth curve. At gameplay distance the difference is small.

## Limits / next
- Window-edge strain trade-off above; a twist helper on ArmTwist (now reserved) could recover the wrist side.
- Shoulder/armpit clearance against the rigid shoulder plate is not yet audited.
- The Warrior mesh and materials still don't match the approved painterly references.

## Assets
- `art/character_sources/AOTL_R54_ElbowHelper_Source.blend`, SHA-256 `5de80d771a372c68466ab317d367395354b71537119e85f3d9b20d51939c97b0`
- `models/AOTL_Warrior_R54_ElbowHelper_SevenClip.glb`, SHA-256 `7e7db3781e76c44badbf2b88ad5e06fac87e92c353edb4953583fd1c7b2d908c`
- Rollback: leave `use_r54_elbow_helper_candidate` off. R53/R52/R50/R39 files are untouched.
