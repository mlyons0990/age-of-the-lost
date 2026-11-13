# AOTL V09 — Anatomical topology / artwork-fit geometry handoff

**Date:** November 13, 2026  
**Source:** [Higgsfield 3D Jutsu, revision 25](https://higgsfield.ai/3d-jutsu/088e8199-50e8-4554-b0be-b108a6b2203a)  
**GitHub branch:** `dev/humanoid-v09-topology-art-fit-2026-11-13`  
**Baseline:** V08 22 independent body/gear paint carriers, `V08_ART` UVs, 2048² packed BODY/GEAR canvases, 58-bone skeleton and V06 23-clip reel.  
**Status:** Real editable geometry improvement; **not yet the visually approved painted-anime hero or Godot-native-verified V09**.

## Actual topology and geometry

The settled Higgsfield revision 24 contained connected quad geometry upgrades for face/hair, cuirass and both pauldrons, and thickness/folds on cape and tabard. Revision **25** adds a further **reversible vertex-level anatomical/armor relief pass** on four existing skinned meshes. Edits preserve vertex counts, quads, weights and UV coordinates.

| Mesh | Blender verts | Quad faces | What is physically shaped |
|---|---:|---:|---|
| `V02_SKIN_AnatomicalHead` | 2,882 | 2,880 | Continuous skinned quad face, cheek/orbital brow and nasal planes; +492 secondary sculpted vertices |
| `V02_HAIR_Crown` | 1,346 | 1,344 | Connected swept hair shape; retains artwork UV |
| `V02_GEAR_LayeredCuirass` | 6,274 | 6,272 | Front armor contours, central recessed seam and symmetric raised panel edges; +1,771 secondary sculpted verts |
| `V02_GEAR_ShoulderPlateL` | 4,034 | 4,032 | Modeled armor crest relief; +1,437 secondary sculpted verts |
| `V02_GEAR_ShoulderPlateR` | 4,034 | 4,032 | Mirrored crest relief; +1,437 secondary sculpted verts |
| `V02_GEAR_RoyalBlueCape` | 8,514 | 8,512 | Thickened closed cloth surface with formed drape folds |
| `V02_GEAR_RoyalTabard` | 242 | 240 | Closed, thickened tabard |

The revision 25 edit affects **5,137 vertices** in total, at no more than **1.081 cm** displacement for a single vertex. Original source mesh datablocks retained under `V08_BACKUP__*` and `V09_R24_BACKUP__*` for exact rollback. Model's source actions remain unaltered.

## Structural acceptance

**Higgsfield/Blender, verified on revision 25:**
- **7/7 target meshes** use closed, predominantly continuous quads; 0 boundary edges and 0 non-manifold edges per target.
- **7/7** have normalized vertex influences (within ±3%), the original armature modifiers, and `V08_ART` UVs.
- **58 joints**, `AOTL_Reel_V06` unchanged, **34 editable source actions** preserved.
- Both atlas images packed: `V08_BODY_PaintPlaceholder_2K` and `V08_GEAR_PaintPlaceholder_2K`, each **2048×2048**.
- Exported V09 R25 GLB: **6,965,104 bytes**; SHA-256 `cdf263322cd86db6d86389904ea851297eb5942cf79134e57dd3a9adb3ab6a5d`.
- Binary GLB has **58 skin joints, 174 animation channels, 16 texture instances**; all seven critical exported parts include skin joints, blend weights, normals and UV coordinates. Exporter correctly uses `TEXCOORD_1` for several V08 surfaces and `TEXCOORD_0` for the separate tunic/leg cloth carriers; material references are aligned to each actual exported channel.
- A read-only GLB validation tool is committed to `game/crownsfall_lootslice/tools/validate_v09_art_fit_glb.py`.

**Visual:** Close, side and 21.0-span camera renders were captured at revision 24; close and 21.0 revision 25 renders captured. Geometry is more consistent, but the Warrior still looks *simpler, rounder and more toy-like* than the approved painterly anime reference, particularly the face and armor. Do not claim AAA-quality modeling complete.

## Editable handoff

The following actual files are archived in Higgsfield Developer Files as  
`AOTL_V09_Topology_Face_Armor_Cape_Editable_2026-11-13.zip` (confirmed media ID `9a10f2b8-2796-4348-9a08-5854554a0bf9`):
- `AOTL_Warrior_V09_Topology.blend` — editable Blender 5.2 scene, weights, UVs, scene and V06 23-section rigged reel.
- `AOTL_Warrior_V09_Topology.glb` — portable 58-joint skinned character with embedded material textures.
- `V09_R25_Close.png` — Blender appearance check.
- `SHA256SUMS.txt` and a readme.

**Reproduce verification:** download the source archive and run  
`python game/crownsfall_lootslice/tools/validate_v09_art_fit_glb.py AOTL_Warrior_V09_Topology.glb`.

## Still necessary before main game replacement

1. Import final V09 GLB into Godot 4.6.3 **as an opt-in** alternate. Run 23 action-section smoke, seven mounts, walk/strafe/dodge/attack tests, planted-foot slip metrics, world-light isolation and original **954 gameplay regressions**.
2. Bake a real AO/normal detail pass and hand-fit the approved painted Warrior assets into `V08_ART` islands. Existing V08 projection is a *starter*, not a 360-degree paint job.
3. Significantly improve bespoke face, hair, shoulder and torso silhouette. The existing sculpt has correct basic surface continuity and weighting, but **does not meet the locked image's fidelity**.
4. Check deformation and clipping through full action cycles, diagonal turning and 14m / 21m camera views, including a human Windows hardware review.

**No paid Higgsfield generation credits used.** Neither stable `main`, original painted default nor existing saves were changed.
