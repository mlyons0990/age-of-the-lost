# AOTL Phase 04 — Live Crownsfall gameplay / 2.5D visual integration

**2026-11-12 — development, not canonical-art signoff.** This phase advances the actual game rather than spinning up another independent prototype. The user's Nov 12 screenshot is a visual **target** and has **not** been transformed into a navigable mesh.

## Architecture

The original saved `Node2D` main game and all gameplay objects remain authoritative. `main.tscn`, `player.gd`, `enemy.gd`, `loot.gd`, quest progression, equipment UI, spellbook and schema-6 saves remain unchanged except `scripts/main.gd` gains a safe **F8** presentation toggle. All existing sprites, painted plaza and occluders are preserved.

At first F8 press, `scripts/two_point_five_d/live_courtyard_bridge.gd` is lazily instantiated as a CanvasLayer at -1, drawing a standalone Godot `SubViewport` with the existing `crownsfall_courtyard_25d.gd` architecture behind the *actual real* 2D actors, FX, service labels and Phase 03 PoE HUD. `Camera3D` projects the original `Camera2D` center and its active zoom each frame. World coordinates use the established `GD.U=88` pixels per unit; `to_2d(to_3d(p))` roundtrips for all measured service positions and projected on-screen markers align within 1 pixel. `F8` off restores original plaza/cutouts and disables SubViewport render updates. The main scene starts in the original painted mode to protect tested visuals and performance.

All 4 scene service plinths are placed using the **real** `main.SERVICES` positions. Live `E` interactions open stash, merchant, lore or noticeboard through the exact original HUD. When approaching a service, its 3D marker emits light. The 3D Reality Scar mark responds to the real `game.rift.active` flag, and does not change any quest/combat state. All game input and transaction logic remains with existing 2D player/controller; no second actor exists.

## Verification

- Godot **4.6.3.stable**: asset import passed, no script parse errors on the final integration test package.
- `godot --headless --path . --script res://tests/live_25d_gameplay_integration.gd`: **72/72 checks passed**. Validates shared player/HUD/nav/quest and item ownership, the real stash and spellbook, projection accuracy, visual state, save equality and repeat toggles.
- Existing 16-suite core game regression: **954/954 assertions passed** in isolated XDG user folders. It does **not** include a Windows graphics/performance playthrough.
- Rendered actual main scene at **1440×810** with the hybrid layer enabled through Xvfb/OpenGL software rendering. A screenshot is a diagnostic, not evidence of final artistic fidelity.
- **0 paid Higgsfield credits** consumed. Source assets/canon imagery remained untouched.

## Known limitations and next milestone

1. The current procedural 3D courtyard's geometry, lighting, wall styles and materials are much less detailed than the six locked Crownsfall concept images and user's Nov 12 screenshot. Do not claim a visual match or use the existing illustration as a runtime scene.
2. Actual pathfinding is the original **2D** nav region, not the 3D `StaticBody3D` world: 3D wall/fountain props may not correspond to walkable 2D floor. Author per-prop 2D polygon obstacles, test nav and service reachability before switching to a 3D default.
3. 2D characters and enemies render over the 3D scenery regardless of geometry depth; implement depth-masked props/occlusion before shipping.
4. Sprite sheets are unchanged; actual painted dodge rolls and distinct class-specific equipment visuals remain separate production passes.
5. 3D scene is rendered with a separate SubViewport in the live main game; benchmark at the intended resolution on Windows and ensure compatibility before enabling by default.
6. Final merge requires Windows playthrough, before/after screenshots, combat loot interactions in both visual modes and save rollback test.

## Reproduce

```bash
cd game/crownsfall_lootslice
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/live_25d_gameplay_integration.gd
python3 tools/run_checks.py --report-dir /tmp/aotl-phase04-reports
```

Always run tests using a **disposable XDG user data directory**; normal launches may read and write `user://crownsfall_encounter_v4.json`. Use the isolated full-source ZIP for local testing instead of overwriting an existing project.
