# Age of the Lost — R55 Clip-Safe Elbow

**Branch:** `dev/r55-clip-safe-elbow-v1` (from R54; opt-in, stable R39/R40 untouched)
**Playable scene:** `res://scenes/r55_clip_safe_elbow_combat_lab.tscn` (Godot 4.6.3, F6)

## R54 regression found in this pass
R54 reduced edge strain, but its wide (±24 cm) linear elbow window **dragged skin out through rigid armor**:
- A new pose-induced poke-through check measures each armor piece's inner-surface profile around its bone axis
  (1 cm × 30° bins) and flags skin pushed beyond both that surface and its own rest radius.
  Results: shoulder plate R53 0 → R54 1,526 vertex-frames; forearm guard R53 877 → R54 3,849.
- Visible in Godot: a large skin wedge through the forearm guard at Cast f23 (`previews/warrior_r54/r54_vs_r53_elbow_Cast_f23.jpg`).
- Root causes:
  1. The forearm guard starts only 3 cm below the elbow joint, and the shoulder plate ends 18 cm above it.
  2. Linear weights change fastest at the window ends, about 20 cm from the pivot, where blended rotations move skin the most.

## Change (R55)
- Keeps R54's half-swing Elbow helper keys unchanged; hands, weapon and shield stay within 1.4 mm of R53.
- Elbow window: **smoothstep-eased**, extending 20 cm above the elbow (stops at the shoulder plate) and 16 cm below; centre +2 cm.
- **Forearm guards scalloped**: the top edge is lowered 2 cm on the inner-elbow side (cos² falloff over ±90°, bottom edge fixed).
  The inner-elbow direction is computed per side from the deepest bend in the clips; the results mirror exactly (L/R).
  Guards remain rigid on Forearm.
- Tried and rejected:
  - Tucking skin hidden under the guard (no measurable effect).
  - Wider eased windows (lower strain, but more armor clipping).
  - Weight-only fixes: no weight setting beats R53 on both strain and clipping while the guard sits 3 cm from the joint.

## Results (search model, all 7 clips, every 2nd frame, right arm)

| | R53 | R54 | **R55** |
|---|---:|---:|---:|
| Shoulder-plate poke-through (vertex-frames) | 0 | 1,526 | **0** |
| Forearm-guard poke-through (vertex-frames) | 877 | 3,849 | **1,471** |
| Worst guard poke depth (mm) | 97 | 68 | **60** |
| RMS edge strain | 2.28% | 1.92% | **1.93%** |
| Worst-frame p95 strain (Blender-evaluated) | 31.4% | 24.3% | **27.1%** |
| Worst-vertex p99 strain | 53.9% | 38.6% | **45.3%** |

R55 gives up some of R54's strain gain to remove the clipping R54 introduced; it remains better than R53 on strain.
Guard poke-through is still above R53. Most of it is skin just inside the guard's top lip (present in R53 too).

## Godot 4.6.3 verification (executed here)
- `tests/verify_r55_clip_safe_elbow_import.gd` **52/52**. All R54 checks, plus:
  - Guards remain rigid on Forearm.
  - The guard top edge is scalloped 1.46 cm. R54 measures 0.6 cm and fails this check, as expected.
- `tests/verify_r55_scene_entry.gd` **10/10**; `tests/verify_r55_live_rig_lab.gd` **17/17**. Full regression **994/994 (17 suites)**.
- Real renders: `previews/warrior_r55/r55_vs_r54_elbow_*.jpg` (right-elbow close-ups), full-body comparisons, `r55_slash_godot.gif`.
  At Cast f23 and f15 the R54 skin wedge through the guard is largely gone; the Slash f5 bend stays smooth.

## Limits / next
- Remaining guard-lip poke-through (inherited from R53). Next step: a slightly flared guard lip or 2–3 mm more guard clearance.
- The scallop changes the guard's silhouette slightly; it should be reviewed against the approved armor art.
- Guard normals were not recomputed after the 2 cm axial reshape (minor shading change near the top edge).

## Assets
- `art/character_sources/AOTL_R55_ClipSafeElbow_Source.blend`, SHA-256 `e43ff7514103da30aa88dcc6218fcbca84340d52b975bd53679cc2f60d3e87b1`
- `models/AOTL_Warrior_R55_ClipSafeElbow_SevenClip.glb`, SHA-256 `10f8ae7805a8a711d6a9bb67cc97b2cb50022ab6ddedcf622d9c8bcc701bb52b`
- Rollback: leave `use_r55_clip_safe_elbow_candidate` off. R54/R53/R52/R50/R39 files are untouched.
