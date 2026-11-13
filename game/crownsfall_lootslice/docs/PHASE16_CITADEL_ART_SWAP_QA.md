# Age of the Lost — Phase 16 Citadel reversible art swap

**Date:** 2026-11-13  
**Branch:** `feature/phase16-citadel-asset-swap-occlusion`  
**Previous verified basis:** Phase 15 procedural fallback (`220` named GLB meshes; Phase 12 physical grade; Phase 13 depth bridge).  
**Production state:** development integration, **not** a declaration that the missing full approved Phase 11 playable scene has been restored.

## What changed

`live_courtyard_bridge.gd` can now attach the Phase 15 Godot-imported GLB as a child of exactly the same local grade transform used by Phase 12's 64 independent physics proxies. The imported mesh has no duplicate `NavigationRegion2D`, `StaticBody3D`, input handler, 2D player, quest state, skills, inventory or save data. The original procedural meshes are retained and can be restored without rebuilding the world or changing gameplay state.

- `install_verified_citadel_grade(start_px, end_px, navigation_region, 9, 1.8, 7.5)` verifies the **actual** painted route and creates a hidden physical grade. In the fully authored Citadel the ground-route length is **9.0 m**, since the art has nine 1.0 m treads. Do not approximate endpoints from an illustration.
- `install_verified_citadel_art()` validates the supplied GLB manifest (220 meshes; 9 × 1 m run; 1.8 m rise; 7.5 m width; no gameplay colliders), loads the scene, verifies named meshes, and places it in the grade's local zero transform. It defaults **hidden**.
- `set_citadel_art_enabled(true)` hides only Phase 12's procedural `MeshInstance3D` placeholders. It **does not** disable the 64 existing `StaticBody3D` collision proxies. `set_citadel_art_enabled(false)` reverses the swap, restoring the procedural visuals.
- `set_citadel_grade_preview(true)` enables the existing F4-equivalent grade. The selected visual source is the *only* one visible. `set_citadel_grade_preview(false)` hides the entire grade and disables 3D collision, including when the imported GLB was selected.
- `set_active(false)` (F8 painted fallback) also turns the preview off to prevent invisible 3D colliders lingering in the render-only viewport. F10 knight depth/avatar Y sampling still reads the authoritative existing 2D player's position and never changes the real Player2D transform.
- The route verifier now tests each **indexed polygon** in `NavigationPolygon.get_polygon_count()`; the `.vertices` pool is not an ordered boundary and could previously falsely accept disconnected paths. This is a functional safety fix.

## Godot tests

```
godot --headless --path game/crownsfall_lootslice --editor --import --quit
godot --headless --path game/crownsfall_lootslice --script res://tests/citadel_art_import_v15.gd
godot --headless --path game/crownsfall_lootslice --script res://tests/citadel_grade_geometry_v12.gd
godot --headless --path game/crownsfall_lootslice --script res://tests/citadel_depth_bridge_v13.gd
godot --headless --path game/crownsfall_lootslice --script res://tests/citadel_art_swap_v16.gd
```

The Phase 16 test exercises disconnected navigation islands, 9 m route validation, default painterly presentation, imported GLB alignment, exclusively visible procedural / mesh art, reversible preview, precisely 64 collision bodies, unchanged knight height sampler and no duplicated art collision. A separate optional CI capture runs real Godot's OpenGL renderer under Xvfb; it is a **standalone diagnostic** scene, never a substitute for the real F5 gameplay view.

## Test and art-signoff boundaries

**The existing project's complete approved Upper Citadel Phase 11 painting + route is not represented by the Phase 08-based GitHub branch.** This is why the Phase 16 branch is isolated rather than automatically merged into `main`. Merge only after backing up the authentic Phase 11 source, matching its real `NavigationRegion2D` and endpoints, and testing F5 traversal + F4/F8/F10 at 1080p and 1440p.

The new software-projected fallback visual test revealed that the procedural model is **much less detailed than the official Crownsfall reference**: broad flat courts, blocky vertical towers and sparse greenery do not yet show the reference's carved masonry, colorful flowers, multiple aqueducts, Gothic statuary, rich lamps and hand-painted stonework. Consequently leave it as an optional engineering preview, not the approved default. The reference's warm ivory / royal blue / muted gold are the right direction; the future asset pass should sculpt architectural profiles and produce texture/normal atlas rather than just increase primitive count. A separate Higgsfield unlimited concept generated for this pass remains **look-development reference only**, not a hidden production texture.

## Next production gate

1. Recover and commit the **actual** approved playable Phase 11 Upper Citadel game, including image assets, to a separately named backup; preserve separate loot/Lorecasting development line.
2. Load the physical stair route from that game's nav region, not invented image coordinates.
3. Wire F4 quality controls to `install_verified_citadel_art` and `set_citadel_art_enabled`, preserving existing F8 and F10 UX.
4. Check F10 character contact on all nine steps at the real isometric camera angle. Occlusion must work in front of and behind each gate pier; painted fallback must remain unchanged.
5. Only after rendered comparison against `AOTL_Citadel_Official_Canon_Reference.png` is approved, merge the new 3D gateway and refine gait foot IK.

**Paid Higgsfield credits spent:** 0. No wilderness zones. No save-schema or quest/inventory mutations.
