# AOTL — Owner-Supplied Development Resource Register

**Created:** 2026-11-19 (America/New_York)  
**Status:** Research and integration candidates, not automatically approved dependencies/assets.  
**Owner's goal:** Reuse appropriate tools and methods for Age of the Lost while preserving **real Godot/Blender 3D characters**, painterly-anime 2.5D Crownsfall art, gameplay, and the approved reference images.

**Agent policy:** Inspect license and compatibility before copying third-party code/assets; test on isolated development branches; document exact upstream URL/commit or asset ID, licensing, provenance, performance, and image comparisons. Do not commit proprietary or paid assets. Do not substitute 2D pixel-art or cutout characters for approved 3D Warrior and class models. Obtain authorization before any paid purchases.

## 1 — Spine Hero Skill

- Link: https://github.com/enoch3712/spine-hero-skill
- Type: Agent workflow for **2D Spine-style skeletal animation from a painting**; orchestrated parallel move authors; deterministic capture gate; independent review/defect checks.
- **AOTL priority:** High for methodology, low for direct asset/runtime reuse.
- **Proposed application:** Adapt motion briefs, foot-drift/ground-contact measurements, gear-swap checks, screenshot sheets, frame close-up reviews, independent failure-checking, and per-animation ownership to **real Blender 3D rigs and Godot 4.6.x**. The R50–R52 Warrior is the first useful pilot.
- Caveat: Original targets Spine 4.2/PixiJS, not Godot skeletal 3D; original rig builder and capture pipeline are not included. Node 18+ for supplied gate. Repository metadata shows no declared license and the inspected root contains no LICENSE file. **Do not copy implementation code unless permission/license is established.** General testing concepts may be reimplemented independently.
- Follow-up: Inspect `skills/spine-hero/SKILL.md` and `references/{gate,orchestration,defects}.md`, define AOTL-specific `metrics.json`, and compare against existing R50 rig-lab tests.

## 2 — Patch Assets Toolbox

- Link: https://patch.gg/create/toolbox/assets
- Type: Hosted game asset catalog with models, materials, HDRIs, sounds, sprites and shaders; site advertises `pch assets search`, `pch assets add`, and Patch MCP `search_assets`.
- **AOTL priority:** High for **selective environmental asset exploration** (Crownsfall stone/cobblestone, moss, foliage, medieval architectural pieces, ambient audio, temporary rig references).
- **Proposed application:** Find quality candidates, preview them in Godot, compare with approved painterly art and FPS/triangle budget, rematerial/rework when permitted, and retain complete provenance.
- Caveat: **Not one open-source license. Every asset has its own source, license and attribution rules.** The displayed `anymove:knight` asset lists CC0, but this is not a blanket license for the catalog. Tools/service may have separate access requirements. Do not bulk-import or silently replace original art.
- Follow-up: Search a small shortlist of scene-relevant assets; record exact item IDs, author/license/credit, output formats and source URL before testing; reject visually inconsistent assets.

## 3 — SpriteFusion Sprite Normals

- Link: https://github.com/Hugo-Dz/spritefusion-sprite-normals
- Type: Rust 1.85+ CLI / WASM tool creating normal maps for sprites, GIF/APNG and sprite sheets.
- **AOTL priority:** Medium for 2D world elements, vegetation impostors, icons, stylized atmospheric elements or 2.5D effects; **not** a replacement for Blender mesh normal maps or physically lit 3D characters.
- **License verified:** MIT (2026 Hugo Duprez) — retain copyright/license notice if including code or substantial portions.
- **Integration:** Build with `cargo build --release --locked`; process controlled input image(s) in a side test; evaluate whether dynamic lighting improves appearance in Godot 4.6.x. For generated normal textures follow correct linear/data texture import; check green channel orientation and blend artifacts.
- Caveat: Designed for pixel-art textures; non-pixel painterly AOTL art may require alternative normal/bump authoring. Visual quality is unverified for AOTL.

## 4 — SpriteCook: Sprite Stacking Technique

- Link: https://www.spritecook.ai/blog/sprite-stacking-pixel-art
- Type: **Tutorial/article**, not an open-source repository or downloadable AOTL asset pack. Covers pixel slice stacks, rotation/squash, Godot Node2D rendering, sample Python conversion.
- **AOTL priority:** Low-to-medium, **optional experimental stylized props**, never main 3D characters, environments or player camera replacement.
- **Proposed application:** If a small distant prop/collectible benefits from pseudo-3D pixel stacking, prototype and check camera/lighting/performance. More likely useful as inspiration for efficient 2.5D impostors rather than as a direct integration.
- Caveat: Copyright/license on page code not established here. Do not copy article code verbatim into AOTL without appropriate permission. Its nearest-neighbor pixel-art rendering can clash with Crownsfall's painterly-anime style.

## 5 — My Magic Asset Workshop (Buche de Gato)

- Link: https://buchedegato.itch.io/my-magic-asset-workshop
- Type: **Paid standalone Windows/Linux asset generator**, not verified open-source; produces 1-, 4-, or 8-direction voxel/pixel/chibi units, items, props, icons, terrain and effects. Exports PNG/BMP/TGA sprite sheets, GIF and Godot SpriteFrames.
- **AOTL priority:** Medium for experimental prototyping and item/icon/UI studies, low for final 3D character assets and premium Crownsfall art.
- **License on seller page:** Generated assets permitted inside personal/commercial games; no credit required; cannot resell/share standalone asset packs or redistribute the workshop.
- **Cost/access:** Listed $24 promotional price (normally $30) at review; free browser demo cannot export. Developer states no MCP/API plans at present. **Do not purchase, download a paid copy, or assume automated Codex integration without explicit authorization.**
- Caveat: Style is voxel/pixel/chibi, generally inconsistent with locked painterly character art. Generated items can be useful only after actual visual inspection and consistent styling.

## 6 — ChatGPT Pixel Effects (Kasperzack Games)

- Link: https://github.com/kasperzackgames/chatgpt-pixel-effects
- Type: GIF cleanup / palette, animation sprite sheet, environment relighting workflow; Python scripts plus a **Godot 4 explosion demo**. Includes examples, prompts, assets, camera/screen shake, debris/smoke effect guidance.
- **AOTL priority:** Medium-high for **effects pipeline and VFX timing techniques**, not direct pixel-art replacement of existing painterly particles.
- **License verified:** MIT (2026 Kasperzack Games). Retain notices for copied code or substantial portions; review any generated third-party content separately.
- **Integration:** Isolate Python dependencies (`requirements.txt` pins numpy/Pillow/scipy/sklearn/opencv/unfake). Review `scripts/clean_gif.py` and Godot scene/shaders. Prototype one **painterly, Godot 4.6.x compatible** spell effect (e.g., Ember Aura, fire impact, lightning) in separate branch; assess anchor stability, alpha, frame timing, color grading and performance.
- Caveat: README tested **Godot 4.7.2**, not AOTL 4.6.x; explicit compatibility validation required. Pixel-art style and color quantization may clash with AOTL's style. Prefer adapting principles, do not blindly replace Godot 3D VFX.

## Suggested evaluation order

1. **Spine Hero methodology:** adapt deterministic animation gates to R50/R52 actual skeletal data; no code copy until license clarified.
2. **Patch catalog:** shortlist 3–5 individually licensed props/materials for Crownsfall, preview before integration.
3. **ChatGPT Pixel Effects:** try one opt-in painterly spell-VFX proof of concept with Godot 4.6.x.
4. **SpriteFusion Sprite Normals:** test a 2D environmental impostor under Godot lighting.
5. **SpriteCook technique:** only if a suitable stylized prop genuinely benefits from the illusion.
6. **Magic Asset Workshop:** optional paid investigation; no purchase unless separately authorized.

## Definition of done for any imported or adapted resource

- Record upstream source URL, precise revision/version, license, original author, and attribution requirements.
- Use isolated worktree or draft branch; retain project original and source images.
- Run relevant Godot/Blender validation; never claim runtime results without execution.
- Compare actual screenshot/GIF with approved AOTL references; reject mismatched art styles.
- Note performance impact, reversible rollback, test output and destination asset paths.
- Make integration opt-in until user-approved visual quality and regression checks are satisfied.

**This register is a standing review resource for Codex and the AOTL multi-agent team, not permission to alter production or purchase assets.**
