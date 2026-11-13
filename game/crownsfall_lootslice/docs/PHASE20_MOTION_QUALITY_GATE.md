# Phase 20 — Quantitative foot-motion audit (R&D)

This phase advances the isolated master-rig review from verified Phase 19. It is not a release-quality character replacement, and the main Crownsfall player, inventory, saves, and HUD remain untouched.

- Source: `scripts/three_d/phase20_motion_metrics.gd`.
- Viewer: `scenes/phase19_animation_review.tscn`, launched from the existing rig lab with F12.
- Keys: 1–6 choose Idle/Walk/Run/Slash/Dodge/Cast; 7 toggles left/right foot-bone markers; 8 uses 0.35× playback; 9 samples 29 frames of the current clip; 0 resets; F7 returns.
- The output displays per-foot vertical range, total local horizontal travel, near-lowest-foot travel and loop seam.
- Diagnostics do NOT prove world-space ground contact, because the master animations are in-place. Do not claim the foot IK is final.

Test command: `godot --headless --path game/crownsfall_lootslice --script res://tests/phase20_motion_metrics_smoke.gd`.

Godot 4.4.1, isolated import using the separate six-animation master GLB, passed **43** assertions. Static ZIP checks pass. User's Windows Godot 4.6.3 and visual QA are pending.

Measured reference: Idle stationary; Walk ~0.10–0.12m vertical foot range, Run ~0.23–0.24m; measurement tool labels low-foot horizontal path as diagnostic, not sliding in active traversal.

The binary remains an optional download from the Phase19 Higgsfield model artifact: https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/306cda02-51cd-499d-9601-6b87064886f3.zip

The main 12 × 5 backpack, quest and junk overlays, schema-seven saves, and wide PoE-style camera are retained. No paid image/video generation credits were consumed.
