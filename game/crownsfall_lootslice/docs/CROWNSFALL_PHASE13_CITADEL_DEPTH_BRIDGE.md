# Crownsfall Phase 13 — Occlusion / grade adapter

Date: 2026-11-13. Branch: `feature/phase13-citadel-depth-bridge`.

## Real changes
- The existing live 2.5D scenery bridge now knows how to install the Phase 12 3D masonry module only when the caller provides **measured Citadel stair endpoints** and its **actual NavigationRegion2D**.
- It rejects blocked / unknown routes using 17 samples of the path center and both shoulders. It does not create or replace a gameplay navigation region.
- Geometry is **disabled by default** and can be enabled and disabled with `set_citadel_grade_preview(true/false)`; call from Phase 11's real F4 handler once its source is restored. Preview off also disables the actual StaticBody3D collision layers, preventing invisible physical blockers.
- F10 knight mirror is offset vertically by the grade sample after its original painted-frame/foot-position calibration. Original 2D player, collision, saves, skills and inventory are untouched.
- Service markers and painted town NPC depth mirrors get matching non-accumulating Y offsets. On toggling off, presentation returns to its original ground plane.
- Any 3D mesh occludes the F10 Sprite3D through its existing depth test. No extra fake sprite actor is created.
- Dedicated adapter test covers missing route, blocked corridor, successful install, default-disabled geometry, toggle, landing height, sentinel outside region, restoration and no duplicate installation.

## Integration gate — do not skip
The referenced *Citadel* Phase 09–11 playable source and art are not committed in the currently accessible GitHub branch. This adapter is added to an isolated development branch descended from Phase 12, which in turn descends from Phase 08. **It is not an assertion that the complete Phase 11 build has been recovered or updated.**

After recovering the current full working Phase 11 source:
1. Commit/upload the original full tree and named image assets as a backup to a clean branch and Drive.
2. Compare `live_courtyard_bridge.gd` with this branch; port only the new adapter methods and the measured Citadel route. Do not overwrite Phase 11's full bridge with this older base.
3. Call `install_verified_citadel_grade(start_px, end_px, steps_region, 9, actual_rise, actual_width)` **after** the Phase 11 bridge has completed `_ready`.
4. Connect `set_citadel_grade_preview` to the real F4 toggle. Respect F8-painted and F10-depth toggles. Existing F5 gameplay and save schema must remain identical.
5. Test 3D contact and actual mesh occlusion across all nine stairs with the animated knight and an NPC. Compare at identical camera angles with the approved painting.

## Headless tests to run on local Godot 4
```bash
godot --headless --path game/crownsfall_lootslice --script res://tests/citadel_grade_geometry_v12.gd
godot --headless --path game/crownsfall_lootslice --script res://tests/citadel_depth_bridge_v13.gd
```

Tests are authored and source-reviewed; they have **not been executed in Godot** in this connector-only environment. Do not report green results until a genuine engine run completes.

No Higgsfield paid credits used, no wilderness zones added.
