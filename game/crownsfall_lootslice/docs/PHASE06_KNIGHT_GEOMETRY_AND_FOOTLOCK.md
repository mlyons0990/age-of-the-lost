# AOTL Phase 06 — true-depth painted knight, grounded animation, geometry occlusion

**State:** Tested experimental milestone, **not production-complete**. **Target:** approved Crownsfall screenshot, PoE-scale camera, canonical blue-and-gold Anime Royal Wayfarer sprite. **Date:** 2026-11-12. **Godot:** 4.6.3 stable. **Base:** Phase 05 branch. **Paid Higgsfield credits:** 0.

## Implementation

1. **Official art remains authoritative.** The existing `Player` remains the only actor with input, navigation, combat, stats, save fields and equipment. The class `SpriteFrames` are original PNGs, with 384px walk/idle and 512px Warrior sword attacks. Neither character texture nor UI asset is replaced.
2. **Foot-contact metadata:** `assets/25d/aotl_class_foot_anchors_v06.json` has authoring-space `feet_y` anchors for all 27 existing Warrior/Mage animation strips. `player.gd` applies the frame's source-space contact point to the animated sprite *offset*, not the actual world transform. The metadata was extracted from alpha/source pixels and still needs frame-by-frame animator review, especially slash VFX and a future true dodge roll.
3. **Actual 3D depth, not an always-on overlay:** F8 instantiates the shared world scenery layer, and F10 *optionally* hides the original actor `AnimatedSprite2D` and mirrors the current live frame onto one `Sprite3D` inside that same Godot `SubViewport` and `World3D`. `no_depth_test=false` keeps opaque architecture correctly in front. The scene has no duplicate player or gameplay authority.
4. **Critical rendered-character correction:** a pixel-level comparison revealed that source animation metadata and Sprite3D offsets were using different pivots. The knight has a calibrated 1.90-unit billboard origin, each class uses its original idle-frame offset as the reference, and the 384→512px sword-frame change compensates for the 64px half-canvas difference. `render_priority=12` still handles the transparent painted floor, while opaque mesh depth testing stays enabled. This corrects clipping and keeps the sprite aligned with the original art at the real PoE-scale camera.
5. **Grounding:** a separate horizontal Sprite3D projected at `y=0.07` reuses the original `shadow.texture`, scale and modulation, with `render_priority=8` and opaque depth testing active. A Sprite3D ray-independent shadow is a visual aid, not authored contact IK.
6. **Class compatibility:** the optional depth mirror pulls the actual frame texture from the current actor, and is verified for Warrior walk + both attack directions and Mage two-frame casting. Future humanoid classes can reuse this adapter if they follow the same sprite/art interfaces.

## QA

- `godot --headless --path . --script res://tests/knight_depth_footlock_integration.gd`: **42/42 PASS** (logic and foot metadata) in Godot 4.6.3, including live art identity, 3D transparency sorting, ground shadow, attack transitions, class swaps, F8/F10 reversibility, and exact save snapshot.
- **Rendered visibility guard:** `tests/knight_depth_visual_integration.gd` runs with a real Godot OpenGL/Vulkan renderer and passes **4/4 assertions**. Pixel-comparing F10 knight visible vs hidden yielded **2,380 changed sampled pixels**, catching the previous false-positive where Sprite3D existed but was entirely obscured by the alpha-blended floor. Run with Xvfb on Linux (not `--headless`); PNGs are written to isolated `user://`.
- `python3 tools/run_checks.py --godot <godot-binary> --report-dir /tmp/aotl-phase06-qa`: **954/954 PASS** original assertions (16 suites).
- Xvfb OpenGL screenshots show the real painted actor, realistic gameplay scale, 3D geometry and F10 toggles in actual game. A temporary **opaque green test pillar** in front hides part of the sprite and behind reveals it. That blocker is **not included in the game**.
- Attack and cast previews: [Warrior GIF](https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/d422e7eb-1b51-44af-a1fc-e9b064a6900c.gif) and [Mage GIF](https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/1bcf13b9-ec55-43b3-b460-eee2be8cc028.gif). These are Godot screenshots of **existing** animation frames at isometric scale, not newly illustrated motion.
- [Actual knight frame](https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/8f053a13-853e-44bc-b7b5-ed52100d5647.jpg), [front/behind geometry proof](https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/677e0270-cb41-476f-8d3d-c9c9c9d5e013.jpg).

## Reproducibility and safe operation

- Open `project.godot` in Godot 4.6.3; F5 normal playable game. F8 toggles enhanced 2.5D scenery; F10 toggles true-depth source-painted actor *only when scenery is on*. Both are opt-in, default off.
- Never overwrite or mutate normal `user://` save files while testing; use a new extracted directory and isolated `XDG_DATA_HOME/XDG_CONFIG_HOME/XDG_CACHE_HOME` for Linux tests.
- In pure 2D mode the original player sprite + shadow render unchanged; no new inventory, quest or class balance rules. All 2D NavServer2D routes and world obstacle maps stay authoritative.

## Unfinished gates before final Crownsfall approval

1. **Character art:** authored 3D knight mesh faithful to six locked paintings, UVs, PBR/painterly shaders and high-joint articulated rig. Prior Higgsfield 58-bone free prototype is **not** sufficiently art-faithful. Use user’s future 3,000 credits only after explicit spending approval and reference validation.
2. **Animation quality:** true rolls and eight-direction moves, stable foot plants verified by human animators, multi-hit melee, cast and class-specific animation & synced hit frames. The current GIF is a sampled preview of existing source frames and not a newly rigged mesh.
3. **World art:** final stone, garden, market, Citadel gate and roof/lantern geometry according to the canonical screenshot. Current geometry remains procedural blockout + approved painted cutouts.
4. **Occlusion:** evaluate all animated enemies/NPCs, variable elevation, mesh intersections, cloaks and gear attachments in the same 3D depth pass. Current F10 depth mirror handles the player's painted class art only.
5. **Collision and navigation:** any *new* 3D prop intruding into the existing 2D walk polygon needs matching 2D nav blockers; do not place it without a verified map. Re-audit all town services and scar combat routes.
6. **Windows & perf:** user playtest at 1080p and 1440p with stable framerate/GPU utilization and tested save rollback. City first; **do not build new outside-Crownsfall zones yet**.

## Higgsfield use and billing

Used Higgsfield's free hosted Linux/Godot setup for real rendered tests and animation previews, with free prior Blender/3D-Jutsu prototype as a future retarget reference. Balance checked: **zero paid credits**; trial unlimited not assumed to cover 3D provider models. No paid 3D generations submitted. Remote render previews are artifacts from actual Godot, **not** equivalent to the user's approved screenshot.

## Phase 06.1 — framebuffer-verified character/architecture alignment

The original source art remains the visual authority; the player is not yet a production-quality rigged 3D character. The initial structural pass could not prove pixel visibility and its screenshot was not a reliable comparison. That gap is closed by an additional **25/25 GPU pixel assertions** in `tests/knight_depth_render_validation.gd`, using an actual Godot 4.6.3 OpenGL framebuffer (Xvfb/llvmpipe), not an image mockup. Reproducible Linux command:

```bash
# Run with XDG_* pointed to disposable folders so real saved games are isolated.
xvfb-run -a -s '-screen 0 1920x1080x24' \
  godot --path . --audio-driver Dummy --rendering-driver opengl3 \
  --script res://tests/knight_depth_render_validation.gd
```

The test renders the *same* source Knight/Mage frames through the authoritative 2D actor and the optional 3D Sprite3D mirror; it takes a source-only and mirror-only screenshot for each and measures pixels where the rendered frame actually changes. Measured screen bounds at 1440×810 (left,top,right,bottom):

| Source pose | Original 2D art | Corrected true-depth mirror | Boot difference |
|---|---|---|---|
| Warrior idle SE | (651,319,780,503) | (651,320,780,506) | 3 px |
| Warrior walk SE frame 2 | (655,318,783,503) | (655,322,784,506) | 3 px |
| Warrior sword SE frame 9 | (619,277,812,503) | (619,286,812,506) | 3 px |
| Mage cast SE frame 1 | (673,348,779,503) | (675,343,779,506) | 3 px |

The same test places a large temporary fully opaque mesh between the knight and the camera: unoccluded Knight contributes **20,238 changed pixels**; after the 3D obstacle is placed in front it contributes **0 changed pixels**, demonstrating genuine per-pixel occlusion in the live 3D scene. The obstacle is **test-only and is not exported or spawned in gameplay**. The original 2D presentation remains the F8/F10 fallback.

**Passed:** new 25/25 rendered-pixel checks, 42/42 logic integration checks, original 954/954 gameplay checks across 16 suites. **Not yet passed:** Windows native graphics/performance, completed 3D anime model with facial topology and rig, authored dodge roll, NPC/enemy 3D depth, final Crownsfall architecture or a visually complete first city zone.
