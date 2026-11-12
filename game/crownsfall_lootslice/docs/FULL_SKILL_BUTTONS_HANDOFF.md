# Full-bleed action artwork — November 12, 2026

The user requested skill artwork filling the entire square action button, following the subject scale of their WoW, Path of Exile and Diablo references while retaining AOTL's darker identity. The current selection uses tightly cropped action compositions: actual blades, shields, spell forms and cloth extend beyond the square borders, and supporting artwork continues through the corners. Earlier centered symbols and plain-color backgrounds are superseded.

## Runtime behavior

Twenty images cover all 19 implemented base abilities plus the transformed Ember Aura. Physical skills read through iron/leather, frost through sharp pale ice, fire through directional orange forms and arcane through violet geometry. Clean contours and controlled shading keep them distinct at small sizes. Deep navy/brass preserves AOTL's palette. No global texture/filter is applied after generation.

`ArtLibrary.action_icon()` selects the new artwork and falls back to the preserved `ArtLibrary.icon()` when a selection is absent, malformed or unavailable. The action renderer fills the square inside its existing two-pixel frame; the Grimoire uses matching images. Existing hotkeys, cooldown shading/numbers, low-mana borders, tooltips and active-aura ON overlay remain live. Transparent service icons, equipment portraits, inventory footprints and actor sprites are unchanged.

`data/skill_tile_profile.json` records exact IDs, source regions and source/runtime hashes independently of the preceding Expansion02 profile. No ability, stat, resource cost, save schema, ownership or combat rule changes. The original player/main/game-data/mastery/town/encounter core files remain byte-identical to the preceding published project.

## Source and reproduction

`art/skill_tiles/2026-11-12/` in GitHub contains the exact selected Higgsfield GPT Image 2.6 atlas,20 square 448px masters, catalog, local readability viewer and portable exporter. Earlier source studies are labeled superseded and excluded from runtime selection. The selected source is 1792×2240 with 20 exact448×448 regions. Runtime PNGs are 128×128 Lanczos downsamplings; no painting, background editing or compositing occurs after generation.

From repository root, `python3 art/skill_tiles/2026-11-12/tools/export_tiles.py` rebuilds 20 masters and 20 runtime files and verifies all 40 output hashes. Pillow is needed only for that exporter. The full project ZIP includes every runtime asset and does not require a separate art download to play. Git clones require Git LFS and `git lfs pull`.

## Verification

Godot 4.6.3 Linux/X11/software OpenGL/Dummy audio is tested. `python3 tools/run_checks.py --report-dir /tmp/aotl-qa` passes 900 assertions across 15 headless suites. The new75-check suite also passes rendered, checking all 20 IDs, every pixel opaque, exact dimensions/hashes, safe fallback, both classes' real HUD/Grimoire, low-mana/cooldown preservation, active Ember Aura and schema-six save validity. Six native captures are in `previews/skill_tiles/`; current complete logs are in `tests/skill_tiles_qa/`. Earlier native drag coverage remains separately archived and is not claimed as rerun for this artwork cycle.

The existing schema6 save namespace/filename, equipment/stat rules and exact grid dimensions remain compatible. QA uses disposable XDG data directories and never real player progress. Windows export, hardware performance and human gameplay tuning remain pending.

## ElevenLabs with no money or credits

Read-only model/balance checks confirm that the existing Higgsfield unlimited allowance covers `text2speech_v2` with `variant: elevenlabs`, through November 13, 2026 at 2:43p.m. America/New_York. Credits are0. Use `use_unlim:true`; never fall back to credits, a paid engine, a purchase or a new subscription.

The tool requires an exact `voice_id` and `voice_type` from its voice picker. That selection is still required before generation. A read-only cost estimate rejected the missing pair and created no job. Proposed standalone audition: “The lost are not forgotten. Their echoes endure.” It is a voice/style review line, not new canon or integrated dialogue. Existing13 procedural sound effects remain active. After selection, recheck eligibility, quote with `get_cost:true`, and submit only under the unlimited allowance. Preserve actual audio/provider/job metadata and derived-format hashes before integration. No new audio job, money or credits were spent during this art cycle.

## Framework for future spells

The production batch was generated in Higgsfield with GPT Image 2.6, job `88f63d60-3742-48ad-846b-640315582612`, using the earlier AOTL sheet as reference and the mage/Cinder Thread as style anchors. Quoted cost 0 credits, `use_unlim:true`, balance0 afterward. Exact request, source hash and completed metadata are in the artwork library's `higgsfield/` folder. Earlier OpenAI image_gen studies retain their original attribution.

The library's `framework/STYLE_GUIDE.md`, `INITIAL_BATCH.json`, `PROMPT_TEMPLATE.txt` and `make_spell_brief.py` define the reusable approach. The helper writes existing-skill or future-concept single-square Higgsfield requests with a completed production-job reference, fixed credit-free settings and no automatic submission. A future image never silently creates a gameplay ability or stat. Visual families guide composition; the real registry continues to define mechanics.

The user approved the framed batch as the ongoing AOTL action-bar skill-icon standard. Each image has a distinct beveled dark-metal border and restrained school trim. The base painting job is`d42ce8a2-c1cf-4fbf-90f0-ea1097fa78ac`; the selected framing job is`88f63d60-3742-48ad-846b-640315582612`. Both used the existing unlimited allowance with a 0-credit quote. The unframed Higgsfield source and earlier studies remain preserved.
