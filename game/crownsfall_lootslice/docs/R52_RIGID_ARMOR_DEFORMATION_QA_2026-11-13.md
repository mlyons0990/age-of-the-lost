# Age of the Lost — R52 Rigid Armor and Deformation Pass

**Developed:** 2026-11-13  
**Blender/Higgsfield:** [3D Jutsu revision 52](https://higgsfield.ai/3d-jutsu/088e8199-50e8-4554-b0be-b108a6b2203a)  
**GitHub:** `dev/r52-armor-rigidity-v1` (separate from stable and earlier R50 branch)  
**Playable Godot test scene:** `res://scenes/r52_rigid_armor_combat_lab.tscn`

## Purpose and real defect

R50 introduced knee articulation, 8.44° hip turn and planted-foot motion during Slash. A new R51 mesh audit uncovered **hard armor deforming as if it were flexible cloth**: at Slash frame 12, the right shoulder plate had 10.366% p95 sampled edge-length strain and the layered cuirass reached 80.511% p95. A moving metal plate should not stretch or shear that much.

The source contains **62 bones, 92 skinned mesh objects, 61,398 Blender mesh vertices**, and real skin weights. This pass improves the existing production-resolution rig; no simplified character stand-in was substituted.

## Implemented in Blender revision 52

The three originally linked mesh objects remain intact with identical materials and topology; only weight assignments are changed:

| Object | Original weights | R52 rigid follow bone | Original source vertices |
|---|---|---|---:|
| `V02_GEAR_ShoulderPlateL` | 76% UpperArmL / 24% ClavicleL uniformly | UpperArmL (100%) | 4,034 |
| `V02_GEAR_ShoulderPlateR` | 76% UpperArmR / 24% ClavicleR uniformly | UpperArmR (100%) | 4,034 |
| `V02_GEAR_LayeredCuirass` | Variable SpineB / Chest / UpperChest | Chest (100%) | 6,274 |

No animation actions were replaced; the original `Slash`, `R48_Slash_FullBody_WeightTransfer_V1`, `R49_Slash_PlantConstrained_V2` and verified `R50_Slash_Grounded_IKBaked_V3` remain in the editable Blender project.

### Quantified deformation before vs after

The edge-strain values are from sampled edges on the actual Blender evaluated meshes; they are **not** a global proof against all future pose collisions.

| Sample | R51 p95 relative edge strain | R52 p95 relative edge strain |
|---|---:|---:|
| Left shoulder, Slash frame 5 | 0.622% | 0.00011% |
| Right shoulder, Slash frame 12 | 10.366% | 0.00011% |
| Cuirass, Slash frame 12 | 80.511% | 0.00100% |

The full-rig weapon/leg motion remains unchanged: approximately **8.4° of hip rotation, 8.2–8.4 cm of knee motion, and 1.8 cm of planted-foot motion**.

## Delivered assets and safe binary construction

- **Editable source:** `art/character_sources/AOTL_R52_RigidArmor_Source.blend`, 24,230,888 bytes, SHA-256 `09a3a88010fd11988773002144ab168ba934db5ccf97161f6afb3d06ebdda49f`.
- **R52 model:** `game/crownsfall_lootslice/models/AOTL_Warrior_R52_RigidArmor_SevenClip.glb`, 7,253,104 bytes, SHA-256 `0d2812d9ae6d6ab666b237e9e5813cd00d89fb9a070fab74de75df4ccdeea06c`.
- **Animation:** The new model retains all seven named clips: Idle, Walk, Run, Dodge, Slash, Cast, `Slash_FullBody_R50`.
- **Skinning:** Retains the **62 joint mapping** and **92 meshes**. The model merger (`tools/merge_r52_armor_and_animations.py`) keeps the **R52 mesh/weights**, transplants the seven tested R50 animation data tracks and rejects incompatible mesh/skeleton ordering.
- **Real previews:** `previews/warrior_r52/rigid_armor_slash.gif` and `previews/warrior_r52/r52_armor_before_after.jpg`. GIF frames are real Blender Workbench renders at frames 1, 5, 9, 12, 15, 19 and 23, without AI-generated intermediate motion.

The previous R50 GLB (SHA-256 `b1a600ca144ccfc7a868d6e4936964a74c3afe55882c5e8166e3f65a26561a16`) and R39 model remain intact. The previous R51 Blender source is separately preserved in GitHub LFS and Google Drive.

## Godot 4.6.3 automated verification

- [R52 seven-clip imported skin/rig/animation suite](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43416860657): **29/29 passed**, including direct imported bone-weight checks. Godot confirmed **UpperArmL**, **UpperArmR** and **Chest** as the actual weighted skeleton bones; each armor mesh's imported vertex weights have exactly one nonzero influence.
- [R52 live Warrior and training-dummy combat suite](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43417130026): **17/17 passed**. Retains terrain IK, weapon and shield sockets, damageable physics hurtboxes, one-hit-per-swing, obstacle blocking, and F8 strict sword sweep.
- Same run also verifies the editor-openable R52 lab scene with **10/10 passed**.
- [Complete 17-suite Crownsfall regression](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43416671234): **994/994 passed**, including legacy gameplay systems. A follow-up run is configured to rerun after changes to the R52 scene/tests.

## How to try the new version

Open `game/crownsfall_lootslice/project.godot` in Godot 4.6.3. Open `res://scenes/r52_rigid_armor_combat_lab.tscn` and **Run Current Scene (F6)**. It selects R52 by design. The original rig-lab scene remains on the earlier character by default.

Alternatively, set `use_r52_rigid_armor_candidate = true` on the original rig lab, or `enable_r52_rigid_armor_candidate = true` on a Warrior controller. Both defaults are **false**; neither changes the established Crownsfall 2D gameplay.

## Honest outstanding limitations

This pass addresses **rigid armor stretching**, not all character quality. The right arm's underlying skinned mesh still has roughly **41.7% p95 sampled edge strain at Slash frame 5**. Testing stronger corrective smoothing gave only marginal improvement, so the arm skinning was deliberately not blindly changed.

Rigid cuirass weighting also changes its pose from the old stretched version by up to **9.65 cm (p95 sampled vertex displacement at frame 5)**. A side-by-side Workbench comparison was rendered; **desktop visual clipping, chest-to-waist clearance, cloth collisions and painterly material match still require human review**. A passing headless physics test cannot certify those visual qualities.

The current model's procedural surfaces still differ from the approved higher-fidelity anime Crownsfall reference art. Recommended next focus: **elbow/shoulder skin weighting, cloth/plate clearance, mesh proportions and artist-quality material/normal work**, while preserving the verified seven-clip rig.

## Backups and rollback

All new binary files are new-name Git LFS assets; no older GLBs or Blender sources have been overwritten. Google Drive contains the original `.blend`, 7-clip `.glb`, actual GIF, before/after render, source archives, and complete real Godot QA logs. The R52 branch is a **draft development candidate**, not silently merged into stable main.

Rollback: leave the R52 opt-in flags unchecked, run the original rig lab, or revert this development branch; R51 and R50 are preserved independently.
