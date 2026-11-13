# Age of the Lost — Phase 08: Merchants' Quarter

Status: verified connected Godot development milestone, NOT final completed Crownsfall. Date: 2026-11-13. Engine: Godot 4.6.3. Paid Higgsfield credits: 0.

## Live gameplay
The F5 scene now contains three contiguous playable city districts, not another stand-alone prototype: Central Plaza, Royal Promenade, and Merchants' Quarter. It retains the original Player, class sprites, save schema 6, navigation, combat, merchants, inventory, skills, quests and loot. No duplicate game simulation or save namespace.

Merchants' Quarter is in scripts/two_point_five_d/crownsfall_merchants_quarter_v08.gd, world origin (2580,1650), canvas 1650x1240. The new NavigationRegion2D exactly shares Royal Promenade's east-edge segment (2690,2111) to (2690,2461), yielding a real Godot path across both city seams. The camera moves east with the same character.

New interactive services using E and the actual existing menus:
- Blue Banner Tailor -> merchant
- Merchant Guild Board -> existing noticeboard/quests
- Market Caravan Chest -> shared stash.
The NPCs are source-art placeholders from existing Warrior/Mage animations, not completed independent character artwork.

## Art and city geometry
Original style reference: user's existing approved Crownsfall painting in assets/plaza.png. Higgsfield GPT Image 2.6, through trial UNLIMITED rather than credits, generated a new original adjacent market environment. Full generation image source:
https://d8j0ntlcm91z4.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/hf_20261113_032843_39efaec9-7d49-4a6a-847d-8a8b40e0a78c.png

Runtime art uses a 1650x1240 quality-90 WebP (assets/25d/crownsfall_merchants_quarter_v08.webp). A second world-aligned WebP (crownsfall_promenade_market_seam_v08.webp) uses smoothstep RGB blending of actual paint overlaps x2580..3000 and y1650..2889. Neither of the old plaza textures is destructively overwritten. The seam is improved, but not handpainted to be perfect across all camera views.

The F8 optional 3D view includes ten limestone shop shells, eight blue-and-gold market-stall canopies, street lamps, the district gate, and a full painted source-image backplate below the nav ground. These geometry shells are still provisional: their silhouette and roof geometry do not match every baked building in the new image and need a final art-authoring pass.

## Collision correctness
The new district originally exposed old Royal Promenade eastern wall shells obstructing new walkable Market paths. Those shells have been moved beyond the outer market boundary; their count is retained for diagnostics. The new cross-district collision audit uncovered an older positive-X Citadel Limestone Parapet intruding on the Royal Promenade entrance; that side alone was shortened to open the actual city gate.

Current invariant: 35 physical 3D footprint records checked against ALL THREE real 2D walkable polygons. Zero intersections after correction. New streets MUST run this combined audit; auditing only their own polygon is insufficient.

## Testing
- Godot 4.6.3 editor import and original F5 scene.
- tests/crownsfall_market_v08_integration.gd covers end-to-end navigation across 3 zones, 3 live E services, 10 marker locations, painting/3D toggles, no save changes, all building colliders and the city-wide collision guard.
- tests/crownsfall_royal_promenade_v07_integration.gd and tests/crownsfall_promenade_services_v071_integration.gd remain maintained.
- tools/run_checks.py runs 16 suites in disposable Linux XDG folders; count expected to increase by three Warrior assertions for valid additional services.
- Godot OpenGL 1440x810 real main-game screenshots, painted mode and F8/F10, are captured from the playable scene.
- Use an independent test folder on Windows; do not overwrite existing saves.

## Outstanding gates
The approved 2026-11-12 blue-gold painterly isometric city screenshot remains the quality bar. Royal, Market and Plaza are playable but city architecture is not final. The six town-service NPC stand-ins now have optional F10 Sprite3D depth mirrors; roaming NPCs/enemies still lack unified true-depth rendering. The source-painted Knight F10 mirror is not a completed true 3D art-matched character mesh/rig. The 58-bone experimental master rig still needs art-faithful geometry, authored dodge animation quality and Godot integration. Windows performance, 1080p/1440p and final art signoff are pending. The other planned city quarters and all wilderness zones have NOT yet been built.

Proceed to Citadel Steps, Archives, Moon Garden, Foundry, Outer Gate only after validating each connected city's physical and artwork rules. No paid model-generation credits were used in Phase 08.


## Phase 08.1 — Actual service-NPC 3D depth

The six Royal Promenade and Merchants Quarter NPC source Sprite2D textures are now
mirrored into the SAME F8 3D SubViewport as the painterly Knight when F10 is active.
The original Node2D NPC is hidden only in F10. F8 or F10 disable restores it,
without second gameplay entities, second pathfinding, new save fields or changed shops.
Textures are still class-derived stand-ins, not approved unique hand-painted NPCs.

- `tests/crownsfall_npc_depth_v081_integration.gd`: 51/51 assertions pass.
- Actual Godot 4.6.3 OpenGL framebuffer test:
  `tests/crownsfall_npc_depth_gpu_validation.gd`: the Market Tailor
  contributes 202 visibly changed pixels at the 1920x1080 runtime viewport when
  its Sprite3D mirror is enabled versus disabled (sampled at stride 2).
  Use an actual OpenGL window (Xvfb on Linux), not --headless for this test.
- The initial GPU probe ran before camera smoothing reached the Market and
  produced an off-screen false negative. Validation now waits for camera sync.
- 44/44 district tests and 35-collider, 3-district collision audit pass.
- 16-suite existing regression expected assertion total: 960.
- F10 NPC depth does NOT establish full production character mesh or rig quality.

The user-approved blue/gold PoE-style Crownsfall screenshot remains the final
quality target. Windows performance and gameplay art signoff still pending.
