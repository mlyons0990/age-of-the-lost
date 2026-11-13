# AOTL Phase 17 — Citadel masonry art / QA handoff

**Date:** 2026-11-13  
**Source branch:** `feature/phase17-citadel-masonry-texture-and-occlusion`  
**GitHub:** https://github.com/mlyons0990/age-of-the-lost/tree/feature/phase17-citadel-masonry-texture-and-occlusion  
**Google Drive backup:** https://drive.google.com/drive/folders/1K9At_fNbkpG-nzCf4I4_aRnnPSIDQQFQ  
**Higgsfield editable Blender scene:** https://higgsfield.ai/3d-jutsu/0361ff9b-2829-4595-a64e-564f39e1eeac (revision **4**)

## Scope and deliverables

This is **not** a replacement for the locally approved full Phase 11 Upper Citadel gameplay project. It is an opt-in, safer art-only replacement of the separate Phase 15/16 engineering preview. Phase 15 is still preserved and working; the canonical painted artwork remains the default.

Produced a new **1,197-mesh** portable GLB (`AOTL_Citadel_MasonryArt_v17.glb`, ~2.3 MB), its JSON geometry manifest, deterministic source generator, four embedded procedural painted limestone diffuse textures with the generating source PNGs, new Godot import tests, and an independent OpenGL capture pipeline. Features include **340 paving stones, 104 carved Gothic detail segments, 328 floral components and 20 water highlights**. All decorative geometry is marked art-only; gameplay collision, authoritative `NavigationRegion2D`, inventory, quests, saves and actual F10 player physics remain unchanged.

The nine physical-scale treads remain 1 metre deep and 20 cm high, for a total 1.8 m rise. Clear route width remains 7.5 m, arch spans 8.1 m with 32 Gothic voussoirs. The new paving and decorations do **not** add collision bodies or modify the authoritative player.

### Bridge API

Phase 17 adds `install_verified_citadel_masonry_v17()` to the existing `live_courtyard_bridge.gd`, while keeping `install_verified_citadel_art()` for the previous 220-mesh Phase 15 candidate. The new function validates its own GLB manifest, reference frame, route dimensions and mesh count before installing any art. It refuses duplicate installation.

This requires that the **actual** Phase 11 stair entrance, exit, width and `NavigationRegion2D` have already been supplied to `install_verified_citadel_grade(...)` by the recovered game scene. The bridge **does not invent coordinates**, so the new variant is not automatically enabled. The existing `set_citadel_art_enabled` and `set_citadel_grade_preview` continue to select exclusively visible visual meshes and disable all 64 physical preview colliders when hidden. F8 painted fallback still wins; F10 height sampling remains visual-only.

### Actual Godot engine checks

Latest successful CI: https://github.com/mlyons0990/age-of-the-lost/actions/runs/43396145667

On GitHub's Linux runner, Godot **4.6.3 stable** imported both the old and new GLBs. Independent Godot checks pass:

| Test suite | Assertions |
|---|---:|
| Phase 15 fallback GLB importer | 35/35 |
| Phase 12 physical geometry | 119/119 |
| Phase 13 depth bridge | 20/20 |
| Phase 16 reversible visual swap and nav | 38/38 |
| Phase 17 enriched masonry art, packed textures and route | 54/54 |
| **Total** | **266/266** |

Additionally, two groups of **8/8 Python static test suites** passed: previous GLB and Phase17 GLB. A real OpenGL/Xvfb 1280×720 screenshot was captured for **each** of the Phase16 and Phase17 assets at exactly the same camera, in separate passes. That proves render output exists, *not* that the user's live F5 city was traversed.

### Visual review

Measured on the identical Godot screenshots, excluding the solid blue background:

| Proxy diagnostic | Phase16 | Phase17 |
|---|---:|---:|
| Foreground pixels | 137,772 | 140,466 |
| Unique foreground RGB colors | 1,555 | 4,873 |
| Significant brightness edges / foreground pixel | 0.269 | 0.539 |

These are reproducible **diagnostic** metrics, not objective art quality scores. The Phase17 screenshot shows warm visibly textured masonry and more architectural/landscape detail; it is nonetheless still far below the official approved Crownsfall look. The canonical reference uses a *different* environment composition and camera, so no pixel-perfect comparison is claimed.

### Higgsfield free allowance and Blender source

The independent Higgsfield **3D Jutsu** project advanced from revision 3 to revision **4**, expanding the existing editable sculpt to **463 mesh objects** while retaining all nine treads and 32 arch stones. Two painted limestone color images were packed into its Blender scene and 222 carved/flower detail objects were added. This scene is a separate art workflow from the 1,197-mesh procedural GLB above. The export and Blender scene remain retained inside Higgsfield; they have **not** been copied to GitHub/Drive, so do not confuse them with the already backed-up procedural GLB.

One separate unlimited-generation material/reference image was made in Higgsfield. No paid credits were used: **paid Higgsfield credits consumed = 0**.

## Do not merge the old phase branch into main yet

Phase16/17 branches inherit an older Phase08 Crownsfall game tree. The complete user-approved Phase11 Citadel playable source, paintings, and newer scene files have not been recovered in that branch. Do not apply the old main/bridge file wholesale over the current user project. To deploy safely: (1) make an immutable backup of the true approved current game, (2) review the original Citadel entrance/exit and NavRegion, (3) port only additive opt-in Phase17 art methods and binary, (4) test F5 Central Plaza → Citadel and F4/F8/F10 transitions in the **actual game**, (5) test knight feet, IK and gateway occlusion from matched 1080p/1440p views, (6) conduct art quality sign-off, then consider merging.

The procedural model is explicitly an **engineering preview**, not final environmental sculpt geometry or signed-off canon art. No wilderness zones were created, no gameplay progress/save modified.
