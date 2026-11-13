# AOTL Phase 20 — Citadel Material Batching / UV Integrity

**State:** provider-saved optimized Blender sculpt, not the user-approved playable Godot Citadel. Keep PR #55 **DRAFT**. Do not change main, game saves, authoritative 2D navigation, painted defaults, player IK, quests, or inventory.

## Exactly what changed

Higgsfield 3D Jutsu: https://higgsfield.ai/3d-jutsu/0361ff9b-2829-4595-a64e-564f39e1eeac

* Revision 7: 571 mesh objects, 8,820 triangles, 2 packed image textures.
* Revision 8: optimized the 90 newly authored Phase19 fountain and Gothic relief objects into 12 material/side mesh groups; **493 mesh objects**, all 8,820 triangles and worldspace source vertices preserved by individual SHA-256.
* Revision 9: 222 Phase17 detailed architectural/floral/ivy objects analyzed; joined 218 into **34 UV-preserving, material-and-area groups**, leaving 4 visually separate singletons. **309 mesh objects**, 8,820 triangles, 2 packed textures. 262 fewer objects versus v7 (**45.88% reduction**).

Vertex displacement after Blender join was verified by UV-loop matching against original face UV signatures, not by naive rounded worldspace coordinate equality. Actual maximum displacement in the Blender v8-to-v9 mutation operation was around 0.000001168 metres (about 0.0012 mm), well below the 0.1mm tolerance; UV face winding, UV coordinates, topology, triangle totals and material isolation were checked. Earlier revision snapshots remain retained in Higgsfield and reproducible generators are stored in GitHub and Google Drive.

Artifact sizes retained inside Higgsfield:

| Item | Revision 7 | Revision 9 |
|---|---:|---:|
| Exported GLB | 2,568,576 B | 2,462,652 B (-4.12%) |
| Editable .blend | 5,201,327 B | 3,658,555 B (-29.66%) |

**Object count does not equal GPU draw calls. No actual in-game FPS gain is claimed or measured.** Transparent surfaces, shadow casters, camera culling and material sorting will require production profiling on the user's actual current project.

## Source and executable Blender QA

1. `tools/phase20_batch_sculpt_details.py` installs revision8 from the verified 571-object revision7 sculpt only.
2. `tools/validate_citadel_sculpt_v20_v08.py` validates 493 meshes, 8820 triangles, all original 9 treads and 32 arch stones, 12 separate decor batches, packed images, and provenance.
3. `tools/phase20_uv_preserving_decor_batch.py` installs revision9 from the exact 493-object revision8 sculpt only, using bpy.ops.object.join while checking UV-face equality and 0.1mm worldspace tolerance. It is *not* a shortcut for lossy non-UV-aware mesh concatenation.
4. `tools/validate_citadel_sculpt_v20_v09.py` validates 309 meshes, 8820 triangles, original stairs/arch, both batching stages, the precise 222-object Phase17 ornament inventory and two packed images.
5. `data/citadel_phase20_batch_manifest.json` and `data/citadel_phase20_uv_batch_v09_manifest.json` preserve exact source names, material groups, UV/vertex SHA metadata, counts and QA evidence.
6. `tests/test_phase20_batch_manifest.py` and `tests/test_phase20_uv_batch_manifest.py` are Python 3.11 provenance tests (7+7) run in GitHub Actions.

To inspect the revision9 source in Blender 5.2 after downloading the **actual v9 Blend** from Higgsfield:

```bash
blender --background AOTL_Citadel_Higgsfield_v09.blend --python game/crownsfall_lootslice/tools/validate_citadel_sculpt_v20_v09.py
```

**Do not run the generators on revision9.** Revision7 and revision8 remain available as non-overwritten rollback points.

## Render evidence

* On revision8, a 640x360 matched-camera Blender comparison of original 90 source ornaments versus their 12 merged batches produced 0/230,400 pixels with an RGB-channel difference greater than 2%. Only 198 pixels differed by more than 0.5%; maximum channel difference 0.0157.
* Revision9 produces successful 960x540 and 1280x720 renders from the existing `CAM_Main_Production` camera. The 1280x720 offline Blender still took ~95.82 seconds in the Higgsfield worker. **That is an offline render, not an in-game performance benchmark.**
* Revision9's 218 UV-textured source meshes were checked via identical UV faces and below-tolerance world transforms; an independently rendered revision8-versus-revision9 screenshot A/B and canon art signoff remain open.
* This remains a low-poly art engineering sculpt, not final AAA-quality painterly graphics. Proper materials, atmosphere, scene prop depth and character occlusion need more development.

## Github CI and safety evidence

Verified latest Phase20 CI with 7/7 + 7/7 manifest tests, 22/22 prior Python safety tests, 32/32 isolated Godot Citadel nav checks and 273/273 isolated visual/collision toggle checks:

* [Phase20 / Phase17 GitHub Actions](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43409082194) — SUCCESS.
* [Phase16 renderer](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43409082726) — SUCCESS.
* [Phase15 importer](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43409082184) — SUCCESS.

The existing Godot CI currently tests the **separate Phase17 1,197-mesh procedurally authored GLB**, not the new Higgsfield revision9 binary. Do not confuse their scene mesh counts or declare a v9 Godot import passed. The actual locally approved Phase11 playable Citadel remains missing from connected GitHub/Drive. The recovery blocker is [Issue #59](https://github.com/mlyons0990/age-of-the-lost/issues/59).

## Google, GitHub, Higgsfield storage reality

* Source scripts, manifest QA, CI tests and handoff are committed to the feature branch and mirrored in the [Google Drive Phase20 handoff](https://docs.google.com/document/d/12UFLEL8hEz0FKdCROuM82e3hU_SpKWei5s0rCgF8G88/edit).
* Actual optimized .blend and GLB revision9 binary remain retained under the Higgsfield editable project. The available connected upload interfaces cannot directly transfer those provider binary URLs into Google Drive or GitHub; **no external binary mirror is claimed**.
* No forced paid generation charges, no live-game overwrite, and no canonical artwork replacement.

**Next highest-value production task:** recover the exact current playable Phase11 Godot source; make an independent immutable snapshot; stage the revision9 GLB on a clone, verify actual glTF material import, actor occlusion, F4/F8/F10 and frame pacing at 1080p/1440p before a safe reversible art bridge promotion. Keep previous assets and the painted default.
