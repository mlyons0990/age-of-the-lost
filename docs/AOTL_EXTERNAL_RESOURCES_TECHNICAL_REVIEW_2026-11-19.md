# AOTL — Technical review of six owner-supplied development resources

**Review date:** November 19, 2026 (America/New_York)  
**Purpose:** Actionable evaluation for the Codex multi-agent development studio; research only, not integration approval.

## Scope and limitations
All six unique links supplied by the owner were reviewed. For GitHub projects, repository trees, READMEs, licenses, project configuration, selected implementation files and tests were examined. For hosted pages, published product documentation and terms were inspected. The current review environment does not include Godot, Blender, Rust/Cargo, or a mount of the owner's Windows Desktop AOTL folder; **none of these tools has been installed, run in AOTL, rendered there, or performance-benchmarked here**. Do not interpret source inspection as successful compatibility testing.

AOTL acceptance baseline: Godot 4.6.x / Blender 5.2.x, real fully articulated 3D characters with the R50 seven-clip rig candidate as opt-in, approved painterly anime Crownsfall art and ornate HUD, real in-engine GIFs and screenshots. Never swap to low-resolution pixel/chibi sprites merely because a tool is easy to use.

### Executive decision matrix
| Resource | What to use | Direct fit | Main obstacle | Priority |
|---|---|---|---|---|
| Spine Hero Skill | deterministic animation QA and multi-agent orchestration **approach** | methodology: strong; runtime: poor | Spine/PixiJS 2D, missing source license, rig/capture scripts not provided | P0 |
| Patch Assets Toolbox | selected 3D props, PBR materials, environmental sounds and texture sources | useful imports via Godot GLB/materials | individual asset licenses; art-style mismatch; potential service/compute credits | P1 |
| ChatGPT Pixel Effects | authored GIF cleanup/anchoring and composite VFX timing techniques | partial: Godot-based, but 2D | example built for Godot 4.7.2 Compatibility, not AOTL 4.6.x 3D; palette/style differences | P1 |
| SpriteFusion Sprite Normals | automatic 2D sprite normal maps for billboard/impostor/FX assets | narrow | pixel-art height inference can misread painted lighting, not 3D mesh normal-map solution | P2 |
| SpriteCook Sprite Stacking | 2D fake-depth technique for small props | weak | Godot Node2D pixel stacking vs 3D environment / painterly style; draw cost per slice | P3 |
| My Magic Asset Workshop | offline procedural icons/items or disposable prototypes | weak for final game | paid closed standalone; voxel/pixel/chibi; no API/MCP according to author | P3 / optional |

## 1. Spine Hero Skill
**URL:** https://github.com/enoch3712/spine-hero-skill  
**Inspected revision:** main at 2d4f8f41ee257d8559f724799e718856374e3de7 (2026-11-11).

The skill defines *one move per independent author agent*, fixed clip briefs, a serialized capture/build step, a deterministic Node 18+ script gate, a second visual checker and a human-review defect checklist. Gate inputs are JSON metrics with optional per-hero thresholds; the gate checks runtime errors, planted-foot pixel drift, controller ground speed vs stride speed, left/right stance symmetry, leg contacts, rest-pose/loop seams, silhouette holes and bounding-box clipping. It has a test script, but the source project's captured frames and full rig-construction implementation are not part of this repository. Its published examples use 1600x900 30-fps screen pixels; copying its limits into AOTL would be misleading.

**Best application:** build original Godot/Blender R53 motion gates derived from world-space transforms and real rendered frames:
- foot slip during *planted-contact windows* (not simply total range of foot motion), pelvis yaw, knee trajectory, weapon socket/hitbox alignment;
- controller speed vs stride displacement, first/last pose continuity, looping and transition seams, geometry/armor clipping via representative views;
- per-clip reports and multiple isolated author agents with a single integrator.
Use R50's historical 1.8-cm displacement as background, **not as an automatically valid pass threshold**: planted drift and full-clip range are different measurements.

**Reason not to import directly:** This targets Spine 4.2 + PixiJS 2D puppet animations, not skeleton skinning in Blender/Godot 3D. It ships no ready-to-use Godot 3D capture system or Blender rig builder. GitHub metadata showed no project license and root listing contained no LICENSE at review. Public code is not automatically licensed for reuse. Independently implement the ideas unless a license is confirmed.

**Pilot gate:** Verify the exact R50 GLB/Blender source; produce pose metrics JSON from actual game playback, show representative frames, and compare to a stable R39/R50 baseline. Gate failure may not be fixed by suppressing the check. Keep character opt-in.

## 2. Patch Assets Toolbox
**URL:** https://patch.gg/create/toolbox/assets  
**Product terms:** https://patch.gg/terms

The site is an asset catalog exposing categories including 3D models, materials, HDRIs, shaders, sounds, music, sprites and splats; it advertises agent asset queries ('pch assets search' or MCP 'search_assets') and importing ('pch assets add', MCP 'assets_add'). The catalog shows examples directly relevant to Crownsfall: **Cobblestone Floor 09, Moss 002, Gothic Statue, Treasure Chest, Large Castle Door, Building castle**. These are *search candidates*, not independently verified or imported assets.

The catalog's rigged knight example ('anymove:knight') is a 1.85-m, 59k-triangle, 22-bone GLB with seven clips and a 4096-px texture; this demonstrates what the library carries but is **not** a substitute for AOTL's established 62-joint R50 Warrior or approved appearance.

**License detail:** The knight listing is CC0; individual catalog assets carry separate provenance/license/credit requirements. The site's terms explicitly require following other asset licenses. Most Patch services are free, but cloud Blender/compute use credits; **do not spend credits automatically**. Also avoid publishing private AOTL assets or granting third-party access to them during searches/imports.

**Best application:** isolate 3–5 relevant CC0 or permissively licensed environment props/materials, document exact identifiers and licenses, import into an opt-in Crownsfall scene, apply painterly materials/LOD, inspect from the game's isometric camera and benchmark memory/triangles. Prioritize generic architecture and terrain; avoid visually inconsistent character models.

**Pilot gate:** prove format/import compatibility, collision/LOD, texture/UV behavior, alpha settings, licensing, and scene render at target frame rate. Never overwrite unique Crownsfall geometry.

## 3. ChatGPT Pixel Effects
**URL:** https://github.com/kasperzackgames/chatgpt-pixel-effects  
**Inspected revision:** main at 7d1bbcf121c44ba17a997f344278e0677e9d50d2 (2026-11-16).  
**License:** MIT, Copyright 2026 Kasperzack Games; preserve license and attribution when copying relevant source.

The repository includes Python GIF cleanup/normalization (fixed grid, shared palette, chroma removal, anchoring, frame timing and JSON spritesheet metadata), source VFX examples, deterministic Godot explosion mechanics, debris arcs, blast flashes, Camera2D shake, scorch, light blending, and dissolving smoke. Its Python dependencies include Pillow, NumPy, SciPy, scikit-learn, OpenCV and unfake (review their downstream licenses before copying requirements). The shipped Godot demo is a **320x180 Node2D scene configured for Godot 4.7, Compatibility renderer**; README states it was tested in Godot 4.7.2.

**Best application:** original painterly 3D spell/attack VFX: reuse the *event model* (anticipation -> contact frame -> flash/impact -> debris/embers -> smoke decay), alpha/anchor validation and cleanup checklist, with Godot GPUParticles3D, Sprite3D or camera-facing quads and actual environment lighting. An Ember Aura or fire-impact prototype is appropriate. Timing and anchoring transfer; pixel-grid quantization and 2D painted lighting do not automatically transfer to 3D.

**Pilot gate:** one opt-in effect launched by a real warrior swing or Mage cast; proper world-space impact point, no billboard/sorting errors, approved color/brush aesthetic, stable framerate, no accidental 4.7-only API use, and reproducible actual Godot screenshots/GIF.

## 4. SpriteFusion Sprite Normals
**URL:** https://github.com/Hugo-Dz/spritefusion-sprite-normals  
**Inspected revision:** main at d14b06726cabab09c68a403ce2e684a52efbfe4c (2026-10-20).  
**License:** MIT, Copyright 2026 Hugo Duprez; preserve notice if source is included.

Rust 1.85+ command-line and WASM tool for generating normals from a sprite's alpha silhouette and painted shading. Supports PNG, GIF/APNG, per-cell sprite sheets, normal-strength and relief controls, OpenGL/DirectX Y-channel convention, animated color + normal atlases and frame timing metadata. Source implementation uses alpha masks, connected components, distance fields, blurred painted-lightness relief and image gradients. Tests in the repository cover normal-vector direction, alpha preservation, cell isolation, timing/CLI output and overwrite safeguards. The README warns that inferred normals may interpret intentional painted highlights as relief. Source image processing limits are 64 MiB/4,194,304 pixels (including padding), and 256 frames for animated sources.

**Best application:** normal-map 2D decorative sprites, plant billboards, select foliage impostors, UI particles or stylized magical decals that need to respond to changing lights. It is **not** a tool for creating normals for skinned 3D warrior meshes or 3D armor. Source code is Rust (not GDScript); prefer offline build-time conversion over runtime dependency.

**Pilot gate:** compare unlit vs normal-mapped sprites under multiple moving lights in Godot 4.6.x, with correct linear texture import, channel orientation, edges and alpha blend. Reject if painterly painted-light shapes become artificial bumps or shimmer.

## 5. SpriteCook — Sprite Stacking
**URL:** https://www.spritecook.ai/blog/sprite-stacking-pixel-art  
**Article date:** 2026-11-14.

Article and example Python/Godot code, not a complete open-source AOTL plugin. Uses one image slice per height layer and Godot Node2D drawing, with 1-pixel lift, 0.75 squash, nearest filtering, ground-point whole-stack sorting and rotation. It reports Godot 4.6 testing and warns about per-slice draw overhead, soft/painted texture smearing, holes/overhangs, and rotation jitter.

**Best application:** optional experiments for ultra-small secondary props or UI showcases if they genuinely benefit from pseudo-3D. AOTL already has real 3D world assets, so native meshes/impactors will usually be better quality, depth ordering and lighting. Do not use this for the playable Warrior, mobs, buildings or core terrain.

**License:** Online tutorial code is not automatically open-source; no general code-reuse license verified. Prefer implementing technique independently rather than copying unlicensed scripts.

**Pilot gate:** compare a stacked small prop against a native low-poly model at real Crownsfall camera distances. If shading, perspective, depth, overlap, performance or visual style are inferior, **stop**.

## 6. My Magic Asset Workshop
**URL:** https://buchedegato.itch.io/my-magic-asset-workshop  
**Product page checked:** November 19–20 UTC, 2026.

Closed standalone offline tool for Windows/Linux generating voxel/pixel/chibi art, items, icons, 1/4/8-direction sprites and animations; exports PNG/BMP/TGA, sprite sheets/GIF and Godot SpriteFrames. The free browser demo cannot export. Seller page lists a **$24 promotional minimum** (regular $30) as of review and the developer explicitly says there are **no MCP/API plans at present**.

**License:** Seller grants use of produced assets in commercial and personal games without credit, while forbidding standalone resale/share of generated packs and redistribution of the workshop. This does *not* mean the generator's code is open-source.

**Best application:** only optional quick prototype placeholders or item/icon silhouette brainstorming. The rendered voxel/pixel/chibi style is inappropriate as final AOTL Warrior, Crownsfall characters or main high-quality visual assets. Autonomous Codex agent cannot be assumed to control the UI or export directly without a supported local UI automation tool.

**Decision:** defer purchase. High risk of time spent converting style, low impact on R52/R53 priorities. Do not spend money without user authorization.

## Related discovery during Patch research — Pencil and Wash for Blender
**URL:** https://patch.gg/chris/pencil-and-wash-blender  
**Note:** This was *not* supplied directly by the owner; it is an optional follow-up surfaced from the Patch ecosystem.

This MIT-labelled Blender 5.0+ EEVEE/Freestyle/compositor extension adds watercolor wash, stylized stone/wood/foliage materials, clumped painted trees and pencil outlines. Its visual vocabulary is arguably **closer to painterly Crownsfall than pixel-art tools**. It has a 'steady' animation option, but the effect relies on Blender render/compositor passes and does **not** ship as real-time Godot 4.6 shaders merely by exporting GLB. The author's example reports 11–17 sec per 1080p render frame on an L40S and CPU Freestyle/memory caveats.

**Recommended limited proof-of-concept:** in a separate Blender scene, render one Crownsfall-like stone courtyard still and a short camera pan with/without the look, compare to approved images; only if it is directionally useful, investigate baking textures or reimplementing selected stylization in Godot realtime materials. Never promise in-engine parity from offline Blender looks.

## Codex task queue (recommended)

1. **P0 / Animation QA:** adapt Spine Hero methodology into an original AOTL rig-lab testing extension. Inputs: actual R50/R52 GLB and Blender source; outputs: planted-frame foot slip, contact alignment, per-frame skeleton metrics, shoulder/armor screenshot crops, independent visual checklist. No copied unlicensed code. Preserve all original actions.
2. **P1 / Crownsfall assets:** investigate Patch 3–5 candidate stone/foliage/props; document asset IDs/licenses before download. Test individual assets with reversible opt-in staging scene, painterly materials and performance counters.
3. **P1 / Spell VFX:** isolate ChatGPT Pixel Effects techniques; build one native Godot 4.6.x 3D impact with layered flash, particles, decals and smoke timed from authored contact. Verify visuals and frame budget.
4. **P2 / 2D lighting:** run SpriteFusion on one sprite effect or foliage billboard and compare different lights, import channels and visuals. Revert if painterly lighting degrades.
5. **P2 / optional look-development:** test Patch's Pencil and Wash only for Blender lookdev/offline comparison; not a drop-in game shader.
6. **P3 / deprioritize:** SpriteCook sprite stacking and paid Magic Asset Workshop unless a concrete AOTL asset need emerges.

### Required evidence per pilot
- File/branch/revision/author/license; full license notices when needed.
- Actual rendered outputs from **Godot 4.6.x or Blender 5.2.x**, not generated approximations.
- Before/after references at the intended isometric camera and game resolution.
- Scripted test outcomes, regression results and performance measured on the actual target environment.
- No main-branch merge until compatibility and visual acceptance pass.
- Explicitly state which tools were merely read, built, executed, imported, visually inspected or merged; do not conflate these milestones.

**Current status:** Source/code and terms review completed. No imported assets, runtime integrations, purchases or Godot/Blender QA were performed in this review.
