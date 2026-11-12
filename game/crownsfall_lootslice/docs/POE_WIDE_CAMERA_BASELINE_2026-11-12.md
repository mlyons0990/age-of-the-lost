# AOTL — PoE-wide camera baseline (adopted November 12, 2026)

**Status:** Canonical wide gameplay-view baseline, retained as an isolated art-lab configuration until approved for the save-bearing main world. Do not replace approved character artwork or save schema.

## Primary sources

- [GitHub source branch](https://github.com/mlyons0990/age-of-the-lost/tree/feature/painted-2p5d-phase02-poe-camera): \`feature/painted-2p5d-phase02-poe-camera\`
- [Source camera script](https://github.com/mlyons0990/age-of-the-lost/blob/feature/painted-2p5d-phase02-poe-camera/game/crownsfall_lootslice/scripts/two_point_five_d/aotl_25d_lab.gd)
- [Project Google Drive handoff](https://drive.google.com/file/d/18RxVBzh7fMQct8goVFulJRYSf37LfdgG/view)
- [Full Phase02 verified source](https://drive.google.com/file/d/1H9_cMOWH16FI2TG-WR8Fl2YNdHYgpArE/view)

## Locked functional camera contract

| Setting | Canonical value |
| --- | --- |
| Camera node | \`Camera3D\`, \`PROJECTION_ORTHOGONAL\` |
| Default vertical orthographic size | **21.0 world metres** |
| Zoom bounds | **14.0** min (closest) to **28.0** max (farthest) |
| Mouse wheel / keyboard increments | **1.5 m** |
| Wheel up | Decrease orthographic size (zoom in) |
| Wheel down | Increase size (zoom out) |
| Keyboard | Minus / keypad minus = out; Plus / equals / keypad plus = in; Home = 21.0 |
| Follow camera world-space offset | **\`Vector3(12.8, 16.4, 12.8)\`** from player |
| Look-at point | Player global position + **\`Vector3(0.0, 1.10, -1.8)\`** |
| Camera follow interpolation | \`lerp(goal, min(1, delta * 8.0))\` |
| Zoom interpolation | \`lerpf(current, target, min(1, delta * 9.0))\` |
| Previous zoom baseline | 14.5 (superseded) |

Note: \`21.0\` is the **orthographic vertical span**, not a 21 m camera-to-character separation. The look-down pitch derives from the follow offset and look-at target (approximately 38 degrees) and should not be independently changed when copying the look. This is a PoE-*inspired* game feel, not a claim of exact Path of Exile proprietary camera values.

The image character's projected height decreases by \`14.5 / 21 ~= 0.69\` versus the earlier 14.5m view. Preserve the player lower in frame and the 1.8m look-ahead toward the distant gate.

## Applied to Humanoid Master V02

This branch updates \`scripts/three_d/rig_lab.gd\`: the V02 technical rig comparison now starts at 21.0 orthographic with the exact Phase02 follow/look offset, wheel +/- controls, Home reset and smooth zoom. The \`tests/rig_v02_smoke.gd\` tests the camera contract alongside bones, clips and sockets.

The **Phase02 painted 2.5D scene** remains the canonical game art comparison, and its branch is not overwritten or merged by this. This V02 rig lab is simply matched to its camera so model-to-sprite visual comparisons happen at gameplay scale, not at the older 14.0 close-up size.

## Acceptance gates

- Native Godot smoke for camera orientation, 21.0 reset, wheel directions and 14-28 clamps.
- Linux render at 1440x810 plus future Windows graphical comparison of the same hero and plaza at the same view.
- Confirm character, readable combat telegraphs, enemies and effects are visually legible at 21.0.
- Confirm zoom over HUD does not unintentionally scroll or activate world controls.
- Do not merge experimental scene files into \`main\` until comparative human visual approval.

Main gameplay, inventory, saves, original paintings, and Phase02 source stay unchanged until approved.
