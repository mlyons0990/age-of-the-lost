# AOTL Phase A — native Godot 4.6.3 QA result

**Recorded:** 2026-11-12, 20:39 UTC  
**Source:** GitHub Actions completed workflow run **43302181107**, job **131475942976**, on draft PR [#14](https://github.com/mlyons0990/age-of-the-lost/pull/14), head commit `1d2b475049fe83e876bb7ab8abebd5d5769cb15a` at execution time.  
**Outcome:** **SUCCESS**. Runner: Ubuntu Linux / Godot 4.6.3 stable.

## Validated

- Phase A source checks: **112/112** on `--stage` and **112/112** on `--verify` after Git LFS checkout.
- Native Godot art preview toggling: **50/50 assertions**; logs include `PHASE_A_ART_TEST_OK: 50 portrait toggling checks`.
- Existing 16-suite regression runner: **954/954 assertions**, all suites passed. Includes Warrior, Mage, F7 articulated rig lab, art/audio, mastery, encounter, encounter bouts, inventory UI, town UI, reliability, navigation, grid alignment, loot, selected art, skills and actor feedback.
- Original gameplay item definitions, stat curves, save handling, class permissions and selected art profile were not modified. Portrait preview remains **F8 opt-in**.

## Archived evidence

- GitHub Actions artifact ID: `13981283862`, artifact name: `aotl-phase-a-qa`.
- Copy in existing AOTL Google Drive art-production > Phase_A_Playable_Integration_2026-11-12: `AOTL_Phase_A_Godot_4_6_3_Native_QA_2026-11-12.zip`.
- Standalone source release: `AOTL_Phase_A_Art_Preview_Full_Source_v2_Godot_Verified.zip`, with source and QA logs. A smaller v2 patch is also present.
- Native report includes `summary.json` and 17 console logs (16 suites plus import).

## Unresolved production gates

1. **Rendered human UI review** of F8 switching at 32px/64px and light/dark inventory backgrounds.
2. **Windows desktop export and hardware playtest**; GitHub Actions only ran Linux headless.
3. Acceptance of final Phase A art choices and deliberate merge of draft PR. Do not equate successful automated tests with this approval.
4. Continue character modeling/animation separately: the F7 rig is a geometric proxy and is not a production 3D anime character.

This report documents a verified *development milestone*, not a final game release.
