# AOTL V07 · Phase 1 — Warrior Silhouette Sculpt Worksheet

**Working source:** Higgsfield 3D Jutsu project `088e8199-50e8-4554-b0be-b108a6b2203a` (audited at Blender scene revision **12**); 58-bone `RIG_AOTL_Master_Humanoid_58`, 23 V06 gameplay action sections inside `AOTL_Reel_V06`. 91 visible/candidate mesh objects in inspected scene.  
**Source control:** `dev/humanoid-v07-silhouette-sculpt-2026-11-13`, branched from verified V06.  
**Intent:** A controlled, reversible **silhouette** pass, not a replacement for the canonical approved painterly-anime Warrior images. Real-object names and geometry dimensions below come from the editable scene audit; percentage edits are **proposed targets**, not values taken from the images.

## Locked constraints and model orientation

- **58 original bones remain in place**; preserve `ClavicleL/R`, `UpperArmL/R`, `Chest`, `UpperChest`, `Hips`, `ShinL/R`, `FootL/R`, `ToeL/R` and their animation/IK mappings.
- Keep the **23 V06 action clips**, seven equipment sockets, 2D directional blending, world-space stance IK, and right-mouse combat-facing lock.
- Preserve the **21.0 orthographic vertical world span**, with mouse-wheel range **14–28**, follow offset `(12.8,16.4,12.8)` and look target `(0,1.10,-1.8)`. **21.0 is not physical camera distance.**
- Make symmetric L/R geometry changes together; never scale the armature or overwrite `main` / player saves.
- Preserve the **approved painted Warrior** as the default visual, and keep V06 as an independent, playable rollback. No paid Higgsfield credit use without permission.
- Higgsfield studio lights/camera must remain disabled in Godot's Crownsfall scene (V06 exposure regression check).
- A visible bone-driven mesh must retain its vertex groups, armature modifier, and normalized weights after reshaping.

## Exact object-by-object sculpt queue

Legend: **P0** = highest silhouette impact at the 21.0 camera; **P1** = secondary silhouette; **P2** = reserved for later anatomy/detail passes. Dimensions are native Blender metres, from inspected mesh bounds / objects.

| ID | Priority | Exact object(s) | Bone / attachment ownership | V07 Phase 1 proposed edit | Quantitative trial / QA gate |
|---|---|---|---|---|---|
| S01 | P0 | `V02_GEAR_ShoulderPlateL`, `V02_GEAR_ShoulderPlateR` | `ClavicleL/R`, `UpperArmL/R` | Taper the pauldron toward the neck; widen only the outer rim and lift the outer peak slightly. Keep the shoulder socket free. | Current X outer edge ~±0.514m, top Z ~1.578m. **Trial:** outer flare +5–7%, outer peak +1–3cm; compare both arms and inspect at full slash pose. |
| S02 | P0 | `V02_GEAR_ShoulderRimL`, `V02_GEAR_ShoulderRimR` | `ClavicleL/R`, `UpperArmL/R` | Keep gold outline conforming to the new metal pauldron; emphasize the silhouette break without a floating golden halo. | Current outer X ±0.525m. Mirror S01's flare, check no gap greater than ~2cm between plate and rim at rest or raised-arm pose. |
| S03 | P0 | `V02_GEAR_LayeredCuirass` | `SpineB`, `Chest`, `UpperChest` | Strong upper-torso taper with a believable armpit recess; avoid enlarging the waist or shoulders uniformly. | Current mesh width ~0.520m; local Z 1.18–1.49m. **Trial:** upper chest width +1–3%, lower edge width −2–4%; check pelvis/shoulder clipping. |
| S04 | P0 | `V02_SKIN_FittedTunic` | `Hips`, `SpineA`, `SpineB`, `Chest`, `UpperChest` | Shape an under-armor waist and soft lower-torso break; preserve smooth bends under the cuirass. | Mesh width ~0.526m, vertical 0.925–1.52m. Trial waist contour −2–3% near ~1.0m; bend-test `Walk`, `Cleave`, `Dodge`. |
| S05 | P0 | `V02_GEAR_RoyalBlueCape` | `CapeTop`, `CapeL`, `CapeMid`, `CapeR` | Create a purposeful shoulder-to-hem taper, asymmetric broad folds but symmetric overall contour; avoid “paper triangle” look. | Current width ~1.00m, lower edge Z~0.612m. Trial hem flare ~4–7%; shoulder attachment unchanged; check no leg clipping in Run/Dodge. |
| S06 | P0 | `V02_GEAR_CapeGoldEdgeL`, `V02_GEAR_CapeGoldEdgeR` | `CapeTop`, `CapeL/R` | Follow new cape contour with continuous gold piping that reads as stitched edge rather than an exposed wire. | Mirror cape hem flare; preserve current Z 0.64–1.49m; visually confirm gold edge touches actual cloth. |
| S07 | P1 | `V03_GEAR_CapeFold_-2` through `V03_GEAR_CapeFold_2` | `CapeL`, `CapeMid`, `CapeR` | Re-space fold rhythm: 1 central valley, two broad draped planes, two subdued outside folds. No equal-depth rigid ribbons. | 5 pieces × 8 verts; current Z~0.73–1.42m. Keep all 5 parented and retain bone weights; inspect rear 3/4 view. |
| S08 | P0 | `V02_GEAR_RoyalTabard`, `V02_GEAR_TabardPoint` | `Hips` | Reduce broad rectangular panel appearance; narrow near belt, broaden only subtly near hem, make bottom pointed. | Tabard width ~0.43m / hem Z~0.48m. Trial upper width −3%, hem point retained; check knee clearance when sprinting. |
| S09 | P1 | `GEAR_Belt`, `V02_GEAR_TrimLeft`, `V02_GEAR_TrimRight` | `Hips` | Shape a clear waist break, central belt mass and visually coherent trim taper along the tabard. | Belt is 0.408m wide with center Z~1.02m; no belt crossing or skin penetration in dodge compression. |
| S10 | P0 | `V02_GEAR_BootShaftL`, `V02_GEAR_BootShaftR` | `ShinL/R`, `FootL/R` | Stronger calf-to-ankle profile; narrow ankle, add slight shin guard flare without turning boots into oversized blocks. | Current height Z~0.086–0.376m, width ~0.272m. Trial shaft upper opening +2–4%, ankle unchanged. |
| S11 | P0 | `V03_GEAR_AnatomicalBoot_L/R`, `V03_GEAR_BootCap_L/R` | `FootL/R`, `ToeL/R` | Distinct toe-box and instep; keep deformable toe roll visible in stance/swing, preserving 28 V06 toe-reweighted vertices. | Toe region Y from ~−0.30 to −0.015m; trial nose extension ≤2cm and toe cap flush with boot. Validate 23 clips. |
| S12 | P1 | `V02_GEAR_ForearmGuardL`, `V02_GEAR_ForearmGuardR` | `ForearmL/R` | Reduce cylinder-like look; sharpen outer bracer ridge and taper toward the wrist. | Guard current X reaches ±0.736m, vertical Z 0.94–1.204m. Trial silhouette change ≤4%; no shield/sword clipping. |
| S13 | P1 | `V04_SKIN_ArticulatedArmL/R` | `Clavicle`, `UpperArm`, `ArmTwist`, `Elbow`, `Forearm`, `Hand` | Maintain shoulder-to-forearm anatomical progression beneath armor. **Do not** uniformly inflate a weighted mesh. | Each arm 340 vertices. Require normalized ≤4 influences; compare bent-elbow pose and raised arms. |
| S14 | P1 | `V04_SKIN_ArticulatedLegL/R` | `Hip`, `Thigh`, `Knee`, `Shin`, `Ankle`, `Foot` | Subtly reshape thigh, patella and calf contours; avoid sharp knee pinch during 21m stride. | Each leg 380 vertices; preserve 58-joint skinning and measured planted-foot drift benchmark. |
| S15 | P2 (Phase 3) | `V02_SKIN_AnatomicalHead`, `V02_HAIR_Crown`, `V02_HAIR_Front_0…10` | `Head`, `HairFront` | Head/face/hair silhouette reserved for later V07 facial sculpt pass. At Phase 1, only ensure it stays in proportion to new shoulders. | Head width ~0.262m, hair crown ~0.276m; no head scale/position changes until dedicated facial review. |
| S16 | P2 (Phase 4–5) | `SHIELD_Shell`, `SHIELD_Border`, `V03_WEAPON_ForgedSwordBlade` | `ShieldRoot`, `WeaponRoot` | Check equipment doesn't overwhelm the revised character; detailed heraldry/material work occurs later. | Shield width ~0.49m, blade length ~0.697m. Never break socket offsets. |

## Bone-by-bone articulation guards

| Bone(s) | What must remain intact | Visual failure to look for |
|---|---|---|
| `ClavicleL/R`, `UpperArmL/R` | Shoulder plate stays on animated clavicle/upper-arm; no parent or joint origin changes. | Raised arm clips through chest/pauldron; gold trim detaches. |
| `SpineB`, `Chest`, `UpperChest` | Curved cuirass and under-tunic follow separate torso weighting. | Torso looks like one cylindrical block; chest armor twists off tunic. |
| `Hips`, `SpineA` | Belt and tabard may settle but keep root movement and collision unchanged. | Belt floats during dodge; tabard pierces knees. |
| `CapeTop`, `CapeMid`, `CapeL/R` | Keep lower cape sections weighted and movable; no independent object-level scaling. | Cape becomes a broad stiff cone or intersects boots. |
| `ThighL/R`, `KneeL/R`, `ShinL/R` | Keep knee flexion and IK pole behavior. | Knees collapse or invert during strafe/backpedal. |
| `AnkleL/R`, `FootL/R`, `ToeL/R` | Preserve planted-foot IK and V06 toe-roll influences. | Toe cap detaches, foot slides, heel floats or boot pierces floor. |
| `ForearmL/R`, `HandL/R`, `WeaponRoot`, `ShieldRoot` | Preserve seven socket mounts and hand contact. | Weapon handle/shield position breaks during attacks. |

## Suggested execution batches and stop gates

- [ ] **P0 preflight:** Record current armature name, 58-bone count, 23 clip manifest entries, 7 sockets; export V06 baseline and 21m/14m front, side and rear screenshots.
- [ ] **Batch A — major upper-body silhouette:** S01–S04; small reversible vertex-level edits, no bone/weight change. Render 21m and 14m; inspect `Slash`/`Cleave`.
- [ ] **Batch B — cape and tabard:** S05–S09; hem flare, cloth folds and trim fitting. Render rear 3/4 at 21m; inspect Dodge.
- [ ] **Batch C — leg and boot read:** S10–S14; avoid uniformly scaling skin envelopes; inspect Walk, Run, StrafeLeft and StrafeRight and record actual contact drift.
- [ ] **Batch D — consistency:** Evaluate S15/S16 proportions without starting head sculpt/material work; ensure 3/4 silhouette is balanced.
- [ ] **QA and release:** Native Godot 4.6.3 rig import and 23 named clips, 7 sockets, baseline 21m and mouse-wheel 14–28, full 954 game checks, no imported studio-light exposure change, gameplay GIFs and human comparison against the six locked paintings.

## Phase 1 acceptance checklist (must be demonstrated, not assumed)

- [ ] The character is visibly more intentional at the **21.0** gameplay camera; 14.0 is for inspection, not the baseline.
- [ ] Shoulder/torso/cape/boot silhouette improves **without** sacrificing human-like head/body proportions.
- [ ] No missing/skipped meshes, no L/R asymmetry caused by accidental editing.
- [ ] No reduction of 58 joints / 23 clips / 7 attachment mounts.
- [ ] No material/light contamination of Crownsfall; preserve scene exposure.
- [ ] Walking, strafing, attacks and dodge remain functional; actual planted ankle drift is documented with the same test rather than inferred.
- [ ] Approved Warrior artwork stays selectable as the default; existing save-bearing main scene untouched.
- [ ] Updated editable Blender source, GLB, side-by-side renders, GIF and QA results archived with a new V07 handoff.

**Important:** Improving procedural geometry cannot by itself guarantee a faithful match to the six canonical AOTL paintings. If the result still reads as toy-like or generic, do **not** label Phase 1 visually approved; move the biggest mismatch into a real topology/sculpt/material rework, or obtain a hand-authored reference retopology before replacing the main playable hero.
