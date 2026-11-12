# AOTL Phase A — Equipment Art Production Closeout Candidate
**Date:** 2026-11-12  
**Status:** static-art-production checkpoint with review records. **NOT a tested or approved gameplay release.**  
**Playable baseline:** main commit `d37fa731b1913bdfc327be2c4631a217a9e0910e`. No gameplay code, item IDs, 10×6 inventory, save schema, class restrictions, loot or stat rules were modified.

## Source and review ledger

| Collection | Distinct visual records | QA/readiness |
| --- | ---: | --- |
| Original equipment taxonomy | 61 | Newly audited **856/856** static file/alpha/footprint/hash tests. Original taxonomy ZIP contains one separate unproduced optional record. |
| Emberlock Arquebus, [PR #4](https://github.com/mlyons0990/age-of-the-lost/pull/4) | 1 | Separate source candidate |
| Expansion02 art library | 42 | 12 equipment + 19 abilities + 11 services; prior 522/522 static checks |
| Chronicle Guard Plate, [PR #6](https://github.com/mlyons0990/age-of-the-lost/pull/6) | 5 | Prior 25/25 static checks |
| Thornveil Leather + weapons, [PR #7](https://github.com/mlyons0990/age-of-the-lost/pull/7) | 8 | Prior 48/48 static checks |
| Moonweave/Greyfen + gear, [PR #10](https://github.com/mlyons0990/age-of-the-lost/pull/10) | 12 | Prior 62/62 static checks |
| Relic Implements, [PR #11](https://github.com/mlyons0990/age-of-the-lost/pull/11) | 8 | Prior 56/56 static checks |
| Forged Weapons, [PR #12](https://github.com/mlyons0990/age-of-the-lost/pull/12) | 8 | Prior 56/56 static checks |
| **New Eclipse Oathband and Emberwake Signet** | **2** | Original Higgsfield GPT Image 2.6, unlimited generation, **0 paid credits**; 14/14 asset processing checks; source/true-alpha master/32/64px previews archived |

Additive ledger: **148 visual designs** = **118 equipment-variant art records + 30 ability/service graphics**. This is not 147 gameplay item definitions; variants can represent an existing type. Existing gameplay art selections are unchanged.

## New Higgsfield art provenance

Original images: 
- **Eclipse Oathband**, `aotl_eclipse_oathband_v1`, ring 1×1, job `72f7d40f-5048-4182-93c0-ff86f028f61a`, [original PNG](https://d8j0ntlcm91z4.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/hf_20261112_195956_72f7d40f-5048-4182-93c0-ff86f028f61a.png)
- **Emberwake Signet**, `aotl_emberwake_signet_v1`, ring 1×1, job `4ac74e50-5f86-408d-876d-a215eb042dbe`, [original PNG](https://d8j0ntlcm91z4.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/hf_20261112_200408_4ac74e50-5f86-408d-876d-a215eb042dbe.png)

Originals and processed true RGBA 128×128 and 32/64 previews in confirmed Higgsfield Developer Files archive `AOTL_PhaseA_Jewelry_Eclipse_Emberwake_Source_RGBA_2026-11-12.zip`, media ID `eff632ef-d082-4ac6-b144-a47a6fa1d2c9`, size 3,561,542 bytes (11 archive entries). Original source and file hashes, clipping/alpha diagnostics in its `SOURCE_MANIFEST.json`. New jewelry remains **candidate art only**.

## Validated locally

Downloaded and inspected the original AOTL taxonomy library and current playable Godot source independently. New portable QA script checked 61 assets: unique IDs, source file presence and SHA-256, PNG SHA-256, 128px/cell footprints, genuine RGBA alpha, corner/perimeter gutters, reduced 32px readability presence, all art disabled in runtime. **856 of 856 assertions passed**. This is not an art-style approval. Game portrait slot grid is 64px/cell, independent of texture source density.

The full new audit report, reproducible Python scripts, and **bright/dark 32px/64px contact sheets** were saved in the already-established [AOTL Google Drive Art Production folder](https://drive.google.com/drive/folders/1eeXR6zZ_m7C-G8qZLf-9uYUdWt86LdPI) as:
- `AOTL_Phase_A_Release_Review_2026-11-12.zip`
- `AOTL_Phase_A_Final_Handoff_2026-11-12.md`

## Native acceptance still required (no false completion claim)

- Human visual approval across light/dark backgrounds and native 32px/64px sizes; especially slender weapon handles, Greyfen shield alpha matte and new ring silhouette bounds.
- Isolated art-only Godot integration branch with mapping to existing authoritative item definitions, no automatic item/stat/save changes.
- Godot 4.6.3 native/regression suite with isolated test saves; verify inventory drag/drop, stash, merchant, tooltip, Warrior/Mage slots, schema-six save/load and F7 lab return.
- Windows export + rendered human playtest + original/current regression screenshots. Existing 954 headless assertions in main are historical, **not rerun for Phase A art**.

**Leave the prior draft PRs unmerged until reviewed and proven in game.** This closeout PR is documentation only and safe to merge separately once verified. Phase B (consumables, quest drops, crafting/reagents) should begin only after the art acceptance gate.

## Addendum — Chronicle Hourglass Pendant

Another Higgsfield unlimited image finished after the initial two-ring archive: **Chronicle Hourglass Pendant** (`aotl_chronicle_hourglass_pendant_v1`, 1×1 amulet), job `8805f295-9d60-489e-91ff-d0366ff938a5`, [original image](https://d8j0ntlcm91z4.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/hf_20261112_201621_8805f295-9d60-489e-91ff-d0366ff938a5.png). Its independent source ZIP (1,064,087 bytes, 8/8 static checks) is in Higgsfield Developer Files media ID `9ad6cf0c-5843-42a8-aa53-fab8ea8deb07`. This asset is **not installed in gameplay**. Release package **v2** and supplemental handoff are in the same Google Drive Art Production folder. Totals above supersede the initial two-ring checkpoint.
