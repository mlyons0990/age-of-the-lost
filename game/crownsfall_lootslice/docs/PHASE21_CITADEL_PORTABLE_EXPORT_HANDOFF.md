# Phase 21 — Optimized Citadel export, portable backup and independent Godot gate

**Review state: DRAFT and additive.** No edits to the user's local approved Phase11 Godot playable game, character rig, saves, navigation, collisions or painted visual default.

## Optimized material geometry in Higgsfield
Editable scene: https://higgsfield.ai/3d-jutsu/0361ff9b-2829-4595-a64e-564f39e1eeac

Revision9: 309 mesh objects, 8,820 raw Blender mesh triangles, 32,596 **evaluated/placed triangles** from 191 bevel modifiers and two Solidify banner modifiers, 32,324 triangles in the unique glTF mesh definitions. These numbers differ because Blender source geometry is further tessellated by modifiers during GLB export; some mesh definitions are instanced multiple times.

Revision10: applied *selective one-segment bevels* to just 44 narrow ornamental bevel modifiers (width <=0.015m), leaving original source mesh vertices, authoritative stair collisions and nav unchanged. All original nine tread heights, 32 Gothic stones, two embedded textures, 309 mesh names, and 10 exported material definitions were preserved.

| Metric | Provider v9 | Provider v10 | Improvement |
|---|---:|---:|---:|
| Blender source mesh objects | 309 | 309 | same |
| Blender source triangles | 8,820 | 8,820 | same |
| Evaluated/instanced scene triangles | 32,596 | **26,724** | **18.01% less** |
| Unique exported GLB mesh-definition triangles | 32,324 | **26,452** | **18.17% less** |
| Higgsfield provider GLB size | 2,462,652 bytes | **2,218,580 bytes** | **9.91% smaller** |

Match-angle 640×360 Blender A/B: 16/230,400 pixels changed by more than 2% in any RGB channel, 398 changed by >1%, maximum RGB difference 0.039216. This applies to that camera only; it is not a cinematic/canon art signoff.

An **independent temporary Blender GLB export** and import roundtrip restored all 309 mesh names, nine exact tread elevations 0.2m→1.8m, all 32 arch stones, ten materials and two images. The Blender runtime generated and imported the exported GLB; **the v10 GLB has not yet been imported into the actual approved Godot F5 game**.

## Trustworthy binary inspection

Use `tools/phase21_external_glb_gate.py` on the downloaded v10 GLB. Pure Python, no third-party packages, no write to source file. Checks GLB version, chunk bounds, binary typed accessor ranges, embedded PNG/JPEG/WebP signatures, no network-fetched textures, 309 named meshes, 9 stairs and 32 arch voussoirs, no gameplay-collision names/flags, triangle-instance budget at most 27,000. It distinguishes glTF **unique mesh-definition triangles (26,452)** from **placed scene instance-weighted triangles (26,724)**.

From the development project folder:

```powershell
python tools/phase21_external_glb_gate.py "D:/AOTL_Exports/AOTL_Citadel_v10.glb" --mesh-nodes 309 --max-triangles 27000 --min-images 2 --output "D:/AOTL_Backups/phase21_glb_audit.json"
```

After downloading both the v10 GLB and editable .blend from Higgsfield, create a checksum-verified outside-project ZIP:

```powershell
python tools/phase21_bundle_external_art.py --glb "D:/AOTL_Exports/AOTL_Citadel_v10.glb" --blend "D:/AOTL_Exports/AOTL_Citadel_v10.blend" --out "D:/AOTL_Backups/AOTL_Phase21_v10_verified.zip" --approved-project "C:/AOTL/APPROVED_LIVE_CROWNSFALL"
python tools/phase21_bundle_external_art.py --glb "D:/AOTL_Exports/AOTL_Citadel_v10.glb" --blend "D:/AOTL_Exports/AOTL_Citadel_v10.blend" --out "D:/AOTL_Backups/AOTL_Phase21_v10_verified.zip" --verify
```

The ZIP utility refuses to overwrite an existing bundle or write inside approved Godot source. Both files are stored with SHA-256 and independently verified against ZIP member CRC and manifest hashes. A real v10 GLB+Blender *temporary* ZIP was successfully constructed and verified inside the Higgsfield worker; **that temporary ZIP was destroyed on exit, not uploaded to Google Drive or GitHub.** Permanent v10 .blend and GLB remain preserved inside Higgsfield's revision history.

## Optional independent Godot import gate

On an isolated, disposable Godot project copy, after placing the v10 GLB in an inactive staging location (DO NOT replace the approved painted scene):

```powershell
godot --headless --path game/crownsfall_lootslice --script res://tests/citadel_external_glb_import_v21.gd -- --model="D:/AOTL_Exports/AOTL_Citadel_v10.glb" --variant=v10
```

This test uses `GLTFDocument` to import the selected GLB without editing Godot scenes or saves. It checks mesh nodes, arch stones, all treads and collision-free scene nodes. It passed **50/50 assertions against the existing isolated V17 fixture** in GitHub Actions, **NOT** the unrecovered real v10 game scene.

**Do not confuse the portable .glb optimization with already-tested Phase17 procedural 1,197-mesh GLB.** Only the latter is used by the inherited Godot CI environment.

## Executed QA

- 20 hardened GLB-binary tamper cases and 10 ZIP-bundle cases: 30/30 passed in isolated Python worker.
- Real independent v10 GLB passed hardened validator with 309 mesh nodes, 26,724 placed triangles and two embedded images.
- Temporary real v10 GLB plus actual saved .blend ZIP roundtrip: PASS (both member SHA-256 checks), 309 mesh nodes and 26,724 scene triangles.
- Real Blender glTF export then import: all 309 mesh names, 32 arch voussoirs, 9 stepped heights, 2 images and 10 materials unchanged.
- [Phase21 GitHub Actions](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43414420855): Python 20+10, existing v17 Godot import smoke 50/50, Phase19 32/32 nav and 273/273 toggle assertions green. Follow the newer run if further commits follow.

## Storage, safety and next gate

Source code, QA tests, manifest and handoff are committed to the draft [PR #55](https://github.com/mlyons0990/age-of-the-lost/pull/55) and mirrored to [Phase21 Google Drive](https://docs.google.com/document/d/1AF_peGaYG5ubm54cmssDODoPD7bMCC78SOTaHhwECjA/edit).

**The actual optimized binary GLB and .blend have not been copied into GitHub or Drive**; downloads are available from the Higgsfield project. The independent audit/bundle scripts solve this handoff once those files are available on an accessible filesystem.

Do not enable the optimized art by default. Next: recover the authentic locally F5-approved Phase11 game source (Issue #59), immutable backup, import the actual v10 GLB into a copy, confirm visual grade and camera/material fidelity, F4/F8/F10 fallback, knight IK/occlusion and genuine 1080p/1440p frame pacing. Do not claim measured runtime FPS improvement until a game benchmark is executed.
