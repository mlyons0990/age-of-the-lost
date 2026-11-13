# Phase 18 — Optional Articulated Foot Contact R&D

**Baseline:** user-verified Phase 17 (full source separately backed up on Drive). This GitHub branch is stacked on the separate Crownsfall city-development branch; the complete Phase 17/18 archive is the authoritative integrated playable test candidate, not this GitHub branch alone.

In the independent 3D rig lab (`scenes/rig_lab_3d.tscn`), press **F11** to compare authored movement with experimental two-leg foot IK. **IK is disabled by default.** The script binds `HipL/FootL` and `HipR/FootR` through the imported skeleton, raycasts toward the physics floor, stores stance targets in world space, and blends weights to release planted feet during dodge and attacks. This is a prototype; visual acceptance of knee arcs/foot slide/animation transitions is still pending.

Smoke test: `godot --headless --path game/crownsfall_lootslice --editor --quit`; then `godot --headless --path game/crownsfall_lootslice --script res://tests/phase18_foot_ik_gate.gd`.

A separate Higgsfield master at project `088e8199-50e8-4554-b0be-b108a6b2203a`, revision 36, has **62 skinned joints in its quick GLB** (with IK helper targets). That export contains **one animation**, not the full action library. Do not replace the live six-clip `AOTL_Wayfarer_Articulated_Proxy.glb` with this quick export. A remote Godot 4.4.1 isolated smoke imported the master GLB, found a 69-bone Godot skeleton and initialized both chains. No claim of finished 3D artwork or foot IK.

**Untouched:** production 2D Crownsfall, schema 7, 12-wide × 5-high backpack, quest/junk icons, approved PoE-style HUD and isometric camera. No paid generation credits spent.
