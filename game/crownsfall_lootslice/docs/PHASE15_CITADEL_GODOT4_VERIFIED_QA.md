# Age of the Lost — Phase 15 verified Godot CI record

Date: 2026-11-13
Branch: `feature/phase15-citadel-art-import-pipeline`
Successful workflow run: https://github.com/mlyons0990/age-of-the-lost/actions/runs/43389153600

## Actual execution

On the hosted Linux runner, GitHub Actions installed **Godot 4.6.3-stable** and performed the following successful steps:

1. Checked out Crownsfall source with Git LFS support.
2. Installed the Python asset-building dependencies (NumPy, Trimesh, SciPy).
3. Reconstructed `AOTL_Citadel_ArtFallback_v15.glb` directly from `tools/build_citadel_art_glb_v15.py` and compared geometry against the manifest.
4. Executed all eight Python static mesh test groups (all passed).
5. Imported the generated GLB into the actual Godot 4.6.3 editor in headless mode.
6. Ran `tests/citadel_art_import_v15.gd`: **PASS 35/35**.
7. Ran `tests/citadel_grade_geometry_v12.gd`: **PASS 119/119**.
8. Ran `tests/citadel_depth_bridge_v13.gd`: **PASS 20/20**.
9. Produced the Actions artifact `aotl-citadel-v15-geometry-and-qa.zip`.

**Godot assertions: 174/174.** These are distinct from the eight Python test *groups*.

## Binary reproducibility

The GitHub Actions runner's regenerated GLB and the local build match byte-for-byte:

`8b6e6da69ad357071ae79e1265cae5c8f0976e287344de685d7bed61f4beb6b8`

Asset size: **152,068 bytes**. Actual mesh count: **220**.

The exact binary is committed to GitHub via the Git Blob API, backed up in Google Drive and included in a portable import kit ZIP. The original Higgsfield Blender source remains a *separate* protected 3D Jutsu revision 3 at https://higgsfield.ai/3d-jutsu/0361ff9b-2829-4595-a64e-564f39e1eeac.

## What the passing suite does not establish

- The authentic user-verified Phase 11 playable Upper Citadel tree/art package has not been merged with this branch. F4/F8/F10 runtime rendering on that exact project remains untested here.
- The authoritative 2D navigation is protected by design. Actual lifted character-root physics and authored rig foot IK are not implemented by an art-only GLB.
- Visual appearance matching to the approved canon screenshot, mesh seam quality, occlusion and 1080p/1440p playable camera renders are not approved.
- The GLB is a deterministic **procedural fallback** and must not be mislabeled the Higgsfield Blender sculpt.

Next physical quality gate: recover the complete latest F5 game source and compose the new GLB under its verified Citadel route transform while preserving the painted fallback. Then run a route traversal and screenshot comparison with the real Knight in Godot.

## Costs

Paid Higgsfield credits: **0**. No wilderness zones created and no user save files changed.
