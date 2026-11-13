# AOTL Phase 16 — verified Godot engine/render QA

**Final checked source branch:** `feature/phase16-citadel-asset-swap-occlusion`  
**Passing GitHub Actions run:** https://github.com/mlyons0990/age-of-the-lost/actions/runs/43392299001  
**Engine:** Godot 4.6.3 Stable on Ubuntu Linux (GitHub Actions). 

## Engine evidence

| Test | Result |
| --- | ---: |
| Godot GLB import (Phase 15) | 35/35 pass |
| Physical grade and stair height (Phase 12) | 119/119 pass |
| 2D/3D character grade bridge (Phase 13) | 20/20 pass |
| Reversible Phase 16 imported-art swap and real indexed nav polygons | 38/38 pass |
| Static source/GLB tests | 8/8 groups pass |
| Standalone rendered Godot OpenGL screenshot under Xvfb | 1280×720 pass |
| OpenGL render non-flatness check | 40 sampled colors; 0.669 luminance range |

**Total distinct Godot headless assertions: 212/212.** The screenshot test is a separate imaging gate and is not included in the 212 assertions. All verified in the hosted Godot runtime rather than from a screenshot of the script or a simulated check.

## Visual review result

The real rendered Godot diagnostic is now readable and no longer blown out. Its appearance is still **not production-quality Crownsfall**: the broad courts are largely flat ivory surfaces, some large upper structures retain primitive box silhouettes, flora/lights/water are very sparse, and the distinct 2026 painterly, richly carved architecture is absent. The art is therefore opt-in engineering material only; the original approved painterly style remains the presentation target. A side-by-side *look-development* comparison is stored in Drive. The two frames do not share an exact camera, so this is not a pixel-perfect registration test.

The source GLB has 220 semantic meshes, 9 shallow steps with 1.8m total rise, 32 arch stones and a 7.5m walkable central stair; it is the **reproducible Trimesh fallback**, **not** Higgsfield Blender Revision 3.

## Logic changes confirmed

- Real `NavigationPolygon.get_polygon_count()` indexed areas now replace the incorrect use of `.vertices` as a single contour; the test deliberately checks two disconnected valid islands separated by a blocked path.
- The GLB is instantiated in the Phase 12 physical grade assembly with identity local transform, only after strict manifest / route dimension validation.
- Exactly one visible geometry source is selected: imported GLB or procedural placeholder meshes. The 64 existing 3D collider proxies stay active while the grade preview is enabled, and disappear with grade/F8 fallback.
- F10 knight proxy height remains sourced from original player coordinates, not a second physics controller or save data.

## Safety and remaining work

The fully approved Phase 11 Upper Citadel `project.godot`/art package still needs recovery. This Phase 16 branch inherits older Phase 08 code and **must not be blindly merged over a newer locally verified playable build**. Passing CI verifies the isolated graphics swap, not F5 travel from Central Plaza, real character IK/feet, final occlusion in the user's game, or the complete 962-assertion campaign regression suite. Keep the default painted city intact until those gates are passed.

Next priority: backup true current Phase 11, wire its measured 2D nav to the Phase 16 module, perform real F5 traversal, get identical-angle 1080p and 1440p screenshots, and sculpt/texture the upper gate toward the approved image.

## Higgsfield

A new free unlimited look-development reference was generated: ID `4f999634-1bd6-4713-aed3-08a2ea554c6e` (2026-11-13), kept in Higgsfield. Paid credits used: **0**. It is not a runtime texture or merged asset, and the original Blender sculpt remains independently preserved as Revision 3 in the separate Higgsfield 3D Jutsu project.
