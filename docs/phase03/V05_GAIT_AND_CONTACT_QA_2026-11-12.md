# AOTL Phase03 V05 — gait synchronization / grounded movement handoff

**Completed:** November 12, 2026 US/Eastern (CI timestamps November 13 UTC)
**Status:** Isolated opt-in technical milestone, not an art-approved replacement.
**Source:** Draft PR [#25](https://github.com/mlyons0990/age-of-the-lost/pull/25)
**Parent:** V04 planted-foot branch and Higgsfield 3D Jutsu revision 10.
**Validated run:** GitHub Actions [43337658195](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43337658195), head commit `7bded13a37ec9dfd1069e541f2cecf1f07682014` at start.

## What changed

- New `--aotl-v05` experimental Warrior comparison in the approved **21.0 orthographic** Crownsfall 2.5D scene, range 14–28 mouse-wheel zoom.
- Reuses the **Higgsfield 58-joint V04 model** with four improved limb skin meshes, 16 original clips, seven semantic equipment/VFX bone mounts. No paid credits were used.
- **Physics-synchronized animation cadence**: uses clip duration, current horizontal velocity and authored stride metres (walk 1.9m cycle; run 2.6m cycle). Important: Godot 4.6.3 lacks `AnimationNodeBlendSpace1D.SYNC_MODE_CYCLIC_MUTABLE` (newer versions); implementation uses the supported `BlendSpace1D.sync = true` feeding an `AnimationNodeTimeScale` in `AnimationNodeBlendTree`. Avoid direct `AnimationTree.speed_scale`: it is unsupported.
- Continuous in-world stance lock and actual IK, with tighter maximum hip-to-plant reach and quicker weight transition.
- Subtle lateral pelvis transfer, vertical settle, forward lean and weighted dodge compression/recovery, **without altering the main game's movement speed, inventory, stats, or saves**.
- Keep original painted Warrior **default**; V key cycles painted → V05 → geometric proxy only in opt-in mode.

## Native measurements and acceptance

| Measured parameter | V04 | V05 |
|---|---:|---:|
| Mean animated ankle-to-world-locked-plant XZ distance | 0.2756 m (50 samples) | **0.0523 m (39 samples)** |
| Native Godot 4.6.3 V05 smoke | N/A | **51/51 passed** |
| Original painted Phase02 wide-camera tests | Preserved | **32/32 passed** |
| Existing gameplay assertions | Preserved | **954/954 passed** |
| Real Godot OpenGL 1440×810 capture | Earlier V04 | **14 screenshots, nine-frame GIF** |

**Interpretation:** The V05 metric is approximately 5.2 cm average on the sampled stance frames, versus 27.6 cm in the earlier V04 test. The test's stance sampling differs between revisions; this is a meaningful regression benchmark, **not proof of zero slide across every speed, direction, terrain and frame**. Human gameplay inspection is still necessary.

All original project source and assets are retained in the separate complete archive. A smaller runtime-only Windows ZIP excludes developer references/previews/tests, retaining actual game content and all three portable 3D GLBs.

## Remaining production gates

1. Inspect body-scale movement during start/stop, turning, diagonal input and varied frame rates; current QA primarily traversed one level courtyard path.
2. Actor has basic physics-based locomotion with foot plants, **not a fully animator-authored 8-direction combat locomotion set**. Test walk/run blend, dodge roll, attack lunges and reaction frames manually.
3. Character geometry still looks significantly simpler and brighter than approved painterly anime reference. Face, fitted armor, normals, roughness and silhouette need focused work at the actual 21m camera.
4. Transition from deprecated `SkeletonIK3D` to a supported IKModifier3D stack once complete foot and pole-vector behavior is authored and validated.
5. Windows GPU rendering / playtest and human art approval are still outstanding.

Do not merge to the stable main game until these acceptance gates are reviewed.
