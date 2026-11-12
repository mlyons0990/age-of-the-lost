# Emberlock Arquebus — missing 62nd equipment art candidate

This additive Higgsfield source pass completes **prototype-image coverage** of the original 62-slot AOTL equipment taxonomy, whose only outstanding entry was the optional `aotl_ranged_arquebus_002`. It does **not** mean all 62 entries are production-approved or installed in the game.

**Art and layout:** one original early-fantasy matchlock arquebus, vertical, inventory footprint **2×4 cells**, translucent alpha image exported at 256×512 (128 pixels per cell). Source art is 880×1168 RGB and originally has an opaque charcoal background. A high-quality source WebP is stored here; the bit-identical original RGB PNG remains attached to its Higgsfield generation.

**Higgsfield provenance:** `gpt_image_2`, job `c52aaf3c-bc1c-4f1e-b580-2ee60e966300`, unlimited generation enabled, paid credits spent **0**.

**Files:**
- `aotl_emberlock_arquebus_2x4_RGBA.png` — transparent 2×4 portrait candidate
- `higgsfield_source_q94.webp` — preserved high-quality source proxy
- `ASSET_RECORD.json` — provenance, hashes, alpha bounding box and gameplay status
- `validate_arquebus.py` — standalone Pillow geometry and alpha QA

**Quality caveat:** Automatically cut out from dark-source image using GrabCut, then brightened for inventory visibility. The resulting sprite was visually inspected at preview scale but still needs a human alpha-edge review at 1× and 2× zoom on dark and bright backgrounds. It has not been run through the catalog's export/QA tests or a Godot gameplay playtest.

**Integration:** Do not directly overwrite the established `art/item_taxonomy/2026-11-12/catalog.json` record or any working item definitions. Once visually accepted, use this candidate to replace the optional unproduced arquebus entry in an art-review copy, export it at the catalog's fixed 128 px/cell, update selected source provenance, and re-run the existing visual and geometry checks. Keep `runtime_enabled=false` until the game intentionally implements that future equipment type.

The production-ready Godot baseline remains unchanged. This branch can be reviewed and merged independently of any concurrent gameplay branch.
