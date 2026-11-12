# age-of-the-lost
AOTL Files

## Full-square skill artwork and future spell framework

[View approved icons](https://drive.google.com/file/d/1at2mBYThoYL3p335qc68jVpvdBXdxWJ0/view) · [Latest downloads and verification](docs/releases/2026-11-12-approved-skill-icons/README.md).

[Play the updated source](game/crownsfall_lootslice/README.md) · [Browse20 full-bleed skill images](art/skill_tiles/2026-11-12/README.md) · [Future-spell style guide](art/skill_tiles/2026-11-12/framework/STYLE_GUIDE.md).

Higgsfield GPT Image2.6 produced the selected20-image batch using the existing unlimited allowance at0 credits. The user-approved ongoing style includes distinct beveled metal frames. Oversized painted skill subjects reach those frames, with distinct physical/fire/frost/arcane forms and live hotkey/cooldown overlays. The library includes448px masters, exact source/prompts/settings, a32/64/128px viewer and a reusable brief generator for future spells. Full QA:900 headless assertions, including75 new skill-art checks; the new suite also passes rendered. Earlier equipment, stat and save behavior remains intact.

## Playable artwork integration

[Open the complete Crownsfall LootSlice project](game/crownsfall_lootslice/README.md) in **Godot 4.6.3** after `git lfs pull`. The accepted Expansion02 designs now appear in gameplay: 12 equipment portraits, 19 ability icons and 11 service symbols. Equipment and inventory share matching, proportional art; the right-docked Character sheet and exact item-grid footprints remain intact.

[Download playable source ZIP](https://drive.google.com/file/d/1PiBL4mpatK4GWrtUpGWSMkL-L5d-MSEP/view) · [Release files and verification](docs/releases/2026-11-12-art-integration/README.md).

[Current development handoff](game/crownsfall_lootslice/docs/ART_INTEGRATION_HANDOFF.md) · [Five-page native-screen review](docs/reviews/AOTL_Playable_Art_Integration_Review_2026-11-12.pdf) · [QA logs and summaries](game/crownsfall_lootslice/tests/art_integration_qa/).

Verified: 825 headless assertions plus six additional native mouse checks, **831 distinct assertions**. Existing gameplay, stat scaling, schema-six saves, original art and fallbacks are preserved. The Knight-focused Godot 4.3 import remains on its independent branch. This project is playable source; Windows export and human playtesting remain pending.

## Item taxonomy artwork

[Open the equipment art library](art/item_taxonomy/2026-11-12/README.md): 61 reviewed equipment-art candidates, footprint-normalized transparent PNGs, original Higgsfield sources, an interactive Godot 4.6.3 review project, and a 13-page PDF catalog. Image/geometry checks: 366/366. The optional future arquebus remains unproduced. These are artwork candidates; no gameplay definitions or saves are changed.

Large PNG/PDF files use Git LFS. Install Git LFS, clone this repository, then run `git lfs pull` to obtain their full bytes. Open `art/item_taxonomy/2026-11-12/project.godot` in Godot to inspect the library.

Browser copies: [PDF catalog](https://drive.google.com/file/d/1I5bkj1iWO-0gS0JaL8PgqjYnxIL2YeCe/view) and [complete ZIP](https://drive.google.com/file/d/151THqMOpRRYznfoSqywVf2Mym-at-fO0/view).

## Artwork Expansion02

[Open Expansion02](art/expansion02/2026-11-12/README.md): 42 additional designs — 12 equipment variants, 19 implemented-ability icons and 11 service/interaction symbols. Includes512px UI masters and90 derived32/64/128px textures, a Godot readability viewer, CSV/JSON ID mapping, source provenance and a9-page visual catalog. Image checks:522/522. Seven new source sheets were generated with OpenAI image_gen; the preceding library retains its Higgsfield provenance.

Together the two libraries provide 103 designs. Derived sizes are excluded from that count. The playable project above deliberately selects all 42 Expansion02 designs; the preceding 61-item taxonomy remains a separate candidate library.

[Editable Google Doc index](https://docs.google.com/document/d/131-JFsR6pRWZPwCLMi75Vi4ldUj6zDSxtOZa2LdvIo8) · [Expansion02 PDF](https://drive.google.com/file/d/1mc3FYLM_USKS2MwqEKsYn18zj6H-IRdF/view).
