# Age of the Lost — R53 Warrior Arm Skinning Pass

**Branch:** `dev/r53-warrior-deformation-v1` (from `dev/r52-armor-rigidity-v1`; opt-in, stable R39/R40 untouched)
**Playable scene:** `res://scenes/r53_arm_skin_combat_lab.tscn` (Godot 4.6.3, F6)
**Tools:** Blender 5.2.4 LTS (`bpy` module), Godot 4.6.3 Linux, software OpenGL under Xvfb

## Defect carried from R52

R52 flagged ~42% p95 edge strain on the right arm in Slash and left arm weighting untouched.
R53 inspection of the actual vertex groups found why:

- Forearm weight reached about 19 cm up the upper arm (34% Forearm at 40% of the arm length).
- The **Elbow** bone (never keyed in any clip, child of UpperArm) and **ArmTwist** were spread over
  the whole limb, so they acted as diluted UpperArm weight and blurred the elbow blend.
- Measurements in R52's report included the arms' `CORRECTIVE_SMOOTH` modifier. glTF/Godot use
  plain linear-blend skinning, so R53 measures with **armature only**, as Godot actually skins.

## Change

`tools/r53_arm_reweight.py` rebuilds only the six arm vertex groups of `V04_SKIN_ArticulatedArmL/R`
from each vertex's position along the shoulder→elbow→wrist chain (smoothstep blends: shoulder cap
Clavicle↔UpperArm, elbow UpperArm↔Forearm, wrist Forearm↔Hand; ArmTwist reserved up to half the
upper-arm share; Elbow gets none; ≤4 influences). Blend widths come from a grid search over every
second frame of all seven clips minimising RMS strain + ½·p99 worst-vertex strain. A pure p95
objective was tried first and rejected: it chose near-rigid segments that crushed the elbow (387% local strain).

`tools/r53_patch_glb_arm_weights.py` writes those weights into a copy of the verified R52 GLB:
only the two arms' JOINTS_0/WEIGHTS_0 bytes change; nodes, 62-joint skin, 92 meshes, materials and
the seven transplanted clips are byte-identical. Vertex order was verified against Blender (median 17 µm;
166 vertices differ ≤6 mm because the R52 export baked corrective smooth).

## Results (armature-only LBS, all 7 clips, every 2nd frame)

| Mesh | R52 mean frame p95 | R53 mean frame p95 | R52 worst frame p95 | R53 worst frame p95 |
|---|---:|---:|---:|---:|
| ArmL | 6.56% | 3.18% | 43.07% (Cast f23) | 31.37% (Cast f23) |
| ArmR | 8.68% | 4.76% | 43.07% (Cast f23) | 31.37% (Cast f23) |

Right arm worst-vertex p99 strain: 77.9% → 53.9%. Upper-arm band (5–35 cm from shoulder) dropped
from 34–81% to 0–48%; the elbow band itself is still the hardest region (63% p95 worst-frame).

## Godot 4.6.3 verification (executed here)

- `tests/verify_r53_arm_skin_import.gd`: **41/41** (all R52 armor/clip/foot checks + 10 new imported-arm-weight checks). The same test on the R52 GLB fails the Elbow check, as expected.
- `tests/verify_r53_scene_entry.gd`: **10/10**; `tests/verify_r53_live_rig_lab.gd`: **17/17** (sword sweep, hurtboxes, one-hit, cover blocking).
- `tools/run_checks.py` full Crownsfall regression: **994/994 across 17 suites**.
- Real renders: `previews/warrior_r53/r53_vs_r52_*.jpg` (same camera, same animation time, R52 left) and `r53_slash_godot.gif` (24 real Godot frames of Slash_FullBody_R50). Captured by `tests/capture_r53_arm_compare.gd`.

## Honest limits

- The visible difference is modest: a fuller upper arm and a cleaner elbow line in Slash f5/f9.
  Elbow pinching under 65°+ bends remains (LBS limit). Next: a helper/corrective elbow joint or
  shape-key-free volume bone, and twist distribution once ArmTwist is keyed.
- The mesh itself is still the low-poly procedural Warrior; it does not yet match the approved painterly
  anime references (proportions, face, materials). That is a model/material task, not skinning.
- Strain metrics are sampled edge-length ratios; they do not prove absence of interpenetration.

## Assets

- `art/character_sources/AOTL_R53_ArmSkin_Source.blend` — SHA-256 `a48d5e5912bdc302413364d3224ddbed191359c3b596799ef3272a3a8942714d` (saved compressed; same 104 objects, 211 meshes, 40 materials, 14 packed images, 9 actions as R52)
- `models/AOTL_Warrior_R53_ArmSkin_SevenClip.glb` — SHA-256 `56fcd8d9ef9524f3b9434b5c8ba459470e5b289acba1dea45a1780332295694e`
- R52/R50/R39 files are unchanged. Rollback: leave `use_r53_arm_skin_candidate` off.
