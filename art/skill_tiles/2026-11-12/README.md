# AOTL full-bleed skill artwork

Twenty close-up action images cover19 implemented base abilities plus Ember Aura. Oversized shields, blades and spell effects extend beyond the square borders, with supporting artwork continuing through the corners. Crisp contours, controlled material shading and distinct physical/fire/frost/arcane silhouettes preserve readability at small sizes. Deep navy, brass and iron retain AOTL's darker identity.

- `generated_sources/skill_tiles_atlas.png`: selected, exact Higgsfield GPT Image 2.6 output, job `88f63d60-3742-48ad-846b-640315582612`.
- `masters/`:20 square 448×448 opaque PNGs.
- `catalog.json`: real ability IDs, exact source rectangles, runtime paths and SHA-256 hashes.
- `index.html`: local32/64/128px readability viewer; click an icon for its master. No server needed.
- `tools/export_tiles.py`: exact crop/downsample exporter; validates40 output hashes.
- `generated_sources/previous_*.png`: superseded source studies, preserved for history and excluded from gameplay.

The selected atlas is 1792×2240 RGB: an exact4×5 grid of 448×448 regions. Runtime images in `game/crownsfall_lootslice/assets/skill_tiles/` are 128×128. Generation used AOTL motifs and the user's reference examples for subject scale and composition. Reference-game assets are not included in runtime textures.

From repository root, run `python3 art/skill_tiles/2026-11-12/tools/export_tiles.py` to rebuild all 20 masters and 20 runtime files. Pillow is required only for rebuilding. Normal play needs Godot 4.6.3 and the self-contained project source. Git clones require Git LFS.

QA:900 headless assertions across 15 suites, including75 skill-art checks; the skill-art suite also passes rendered. The exact source atlas, output hashes and live Mage/Warrior action-bar captures are preserved. No new audio was generated: ElevenLabs speech eligibility is verified under the existing unlimited allowance, with a voice-picker selection required before submission. No money or credits were spent.

## Future spell framework

`framework/STYLE_GUIDE.md` records framing, painted finish, school/material cues and small-size review criteria. `framework/INITIAL_BATCH.json` maps the 19 implemented abilities plus Ember Aura. `framework/make_spell_brief.py --ability-id charge` writes a reproducible single-icon Higgsfield request using this completed production job as reference. For a concept use `--future-id` with `--name`, `--motif`, `--action` and `--family`; it remains explicitly unimplemented. The helper submits no jobs and changes no game data. `higgsfield/` preserves the exact prompt, normalized reference ID, zero-credit request and completed-job metadata. Generation used the existing unlimited allowance; quoted cost 0 credits and the balance remains0.

The user approved the framed batch as the ongoing AOTL action-bar skill-icon standard. Each image has a distinct beveled dark-metal border and restrained school trim. The base painting job is`d42ce8a2-c1cf-4fbf-90f0-ea1097fa78ac`; the selected framing job is`88f63d60-3742-48ad-846b-640315582612`. Both used the existing unlimited allowance with a 0-credit quote. The unframed Higgsfield source and earlier studies remain preserved.
