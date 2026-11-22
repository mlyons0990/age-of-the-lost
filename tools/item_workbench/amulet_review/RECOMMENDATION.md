# Amulet artwork comparison and integration recommendation

## Recommendation
Promote the existing Wayfarer Memory Sigil to a reviewed integration candidate for the runtime amulet. Do not generate another amulet before reviewing this one. No production mapping was changed; no credits spent.

Candidate: `aotl_jewelry_amulet_002`, source `art/item_taxonomy/2026-11-12/runtime_items/aotl_jewelry_amulet_002.png`, SHA-256 `09d462713ef24bb949d27f64727c764043cd38c3e2b4e311d1f075b2ca384f5e`. Its catalog status remains reviewed_art_candidate, runtime_enabled false. Source baseline ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b.

## Evidence
- Existing runtime fallback is 64px; candidate is 128px. Both are square, compatible with the unchanged 1x1 amulet footprint.
- Alpha-aware Chromium comparison rendered 24 samples: two images at 32/48/64/96px against dark, light and checker backgrounds. All images loaded. Screenshot inspected.
- Correction to the earlier raw-PNG inspection: the current fallback is a simple lavender outline; it is not a solid lavender pendant. Transparent RGB must not be mistaken for visible background. The candidate composites as a cutout without the apparent rectangle seen in an alpha-unaware preview.
- Candidate has a recognizable chain and warm metal/ivory sundial silhouette. It reads more like the painted equipment at 48–64px. At 32px the small face markings soften but the pendant identity survives. This is a recommendation, not owner art approval.
- Godot 4.6.3 headless candidate fixture passes 67/67 existing portrait checks. An additional report assertion confirms amulet loaded the candidate path at 128x128. All fallback/reset cases still pass. No live inventory interaction or final game-scene visual approval is claimed.

## Integration contract
Use game ID `amulet`, equipment destination `amulet`, footprint `[1,1]`. Add a selected portrait mapping to a dedicated imported texture; preserve original fallback. Do not change item stats, saved IDs, slot rules or geometry. The proposed selected mapping is `portraits.amulet = res://assets/review_candidates/amulet.png` in the fixture; choose the production asset destination during the separate integration change.

Record the candidate asset ID, source library, checksum and approval status in the selected-art provenance before production integration. Keep the exact source bytes; no recoloring or cropping was performed. The inventory picture does not imply an equipped model or ground-drop mesh exists.

## Reproduce and limitations
The portable package includes original PNGs, self-contained HTML, comparison screenshot, metrics, source builder and an isolated Godot fixture. Open `index.html` to inspect the real alpha compositing. `build_review.py` regenerates HTML/metrics using Pillow from unchanged current.png/candidate.png. The fixture's source_manifest records the pre-overlay baseline; candidate_overlay.json records its intentional selected-profile override and exact hashes. Import the fixture with Godot 4.6.3 then run engine_review.gd with isolated writable XDG directories as described in the parent ENGINE_REVIEW.md.

Next integration gate: compare against the actual inventory background and adjacent gear at supported UI scales, then approve or reject the selected-art mapping. Keep the other developer's live scenes and HUD out of this review branch.
