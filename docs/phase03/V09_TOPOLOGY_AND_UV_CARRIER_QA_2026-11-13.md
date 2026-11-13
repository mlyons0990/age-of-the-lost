# AOTL V09 — Paint-conforming topology and skinned cloth geometry

**Status:** isolated V09 technical art milestone, awaiting Godot QA / artistic acceptance.  
**Higgsfield:** [3D Jutsu project](https://higgsfield.ai/3d-jutsu/088e8199-50e8-4554-b0be-b108a6b2203a), revision **24**.  
**Parent:** V08 58-joint, 22 UV-mapped body/gear paint carrier.  
**Gameplay:** canonical PoE-style orthographic camera **21.0** with zoom **14–28**, original approved painted Warrior remains the default.  
**Credits:** no paid Higgsfield generation credits.

## Actual geometry edits made inside Blender 5.2 (3D Jutsu rev 22–24)

| Mesh | V08 source vertices | V09 vertices | V09 faces | Work done |
|---|---:|---:|---:|---|
| `V02_SKIN_AnatomicalHead` | 722 | 2,882 | 2,880 | Continuously subdivided quad surface, nose bridge/tip, cheek planes, brow/eye recess, lip/chin contour and stylized jaw taper. |
| `V02_HAIR_Crown` | 338 | 1,346 | 1,344 | Denser swept hair surface with modest asymmetrical tufts. |
| `V02_GEAR_LayeredCuirass` | 1,570 | 6,274 | 6,272 | Quad subdivision and physically modeled chest panel relief, sternum ridge, recessed edge seams and waist taper. |
| `V02_GEAR_ShoulderPlateL/R` | 1,010 each | 4,034 each | 4,032 each | Mirrored plate relief, beveled surface ridge and exterior flare; no changes to clavicle joints. |
| `V02_GEAR_RoyalBlueCape` | 1,105 | 8,514 | 8,512 | Fabric folds on tessellated drape, **3.6 mm physical thickness** with back surface and hem walls. |
| `V02_GEAR_RoyalTabard` | 37 | 242 | 240 | Drape refinement and **2.4 mm physical thickness**, preserving Hips attachment. |

Both `V02_GEAR_CapeGoldEdgeL/R` objects follow the altered cape edge contour. Original source mesh datablocks retained as Blender fake-user backups under `V08_BACKUP__*`; historic V08 revision 21 is additionally accessible in Higgsfield for full rollback.

## Structural checks performed in Blender

- **58 bones**, all original action datablocks and active `AOTL_Reel_V06` preserved; character remains compatible with its 23 animation sections.
- For all seven principal affected meshes: **zero unweighted vertices**, **zero non-normalized weight sums** (>0.04 error), **zero missing armature modifiers**, and **zero missing `V08_ART` UV channels**.
- For all seven: **zero non-manifold edges**, **zero open boundary edges**, **zero loose edges**, **zero zero-area faces**. The cape and tabard are physically closed two-sided meshes after Solidify.
- Original atlas rectangles remain unchanged, so the **V08 body and gear 2048×2048 UV overlay kit** still maps to the intended surfaces. UV subdivision interpolated rather than reprojected/overwriting existing coordinates.
- GLB export SHA-256: `9ca742a3e8e91e07165587371723f58f77d47d27408647068eff80f559d83b63` (6,964,528 bytes).
- Gzip SHA-256: `eabe1f376b827ddc762c417987a91b306dc75aedc5f253725c94cd316ae88d21` (4,197,374 bytes). Rebuild from **22 numbered source parts** with `tools/restore_rig_v09.py`.
- Export has the original **58 skin joints**, one packed animation reel containing 23 sections, original 2K `V08_BODY_PaintPlaceholder_2K` and `V08_GEAR_PaintPlaceholder_2K` textures.

## Godot integration and QA acceptance

Use `--aotl-v09` in `scenes/two_point_five_d/aotl_25d_lab.tscn`, then press **V** to compare original painted hero → V09 humanoid → geometric proxy. V09 inherits all V06 controller logic (WASD, right-mouse strafe-facing lock, IK, turning, attacks and equipment sockets), with **no save or stats changes**.

**Automated native Godot 4.6.3 acceptance:** `tests/humanoid_v09_topology_smoke.gd` validates seven refined mesh names, vertex density, UV0 and 2K paint-carrier textures, 58 joints, 23 clips, seven attachment sockets, 21m camera and foot planting. The workflow also runs existing **32 wide-camera checks, 954 gameplay assertions, 21 gameplay-frame captures, walk and strafe GIFs, and world-lighting contamination checks**. Record results only after the workflow finishes; never mistake Blender structural validation for native Godot approval.

## Visual limitations / next sculpt priorities

V09 is an improvement to **mesh topology and how artwork can conform to actual surfaces**. It still does **not** match the locked painterly/anime Warrior character sheets; silhouette is too blocky, the face is still simplistic and armor has insufficient authored panels. Subsequent work should improve detailed face topology and expression/eyelid loops, fitted armor piece layering, proper cloth deformation, new normal/roughness bakes and texture painting against canonical references—not merely duplicate geometry subdivisions. Keep the PR in draft and leave the original painted hero as default until art approval.

**Archive:** editable Blender 5.2 and GLB in Higgsfield Developer Files, with orthographic front/back and 21m renders; source reconstructible in this GitHub branch.
