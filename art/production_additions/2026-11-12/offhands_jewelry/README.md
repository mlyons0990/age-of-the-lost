# Age of the Lost — Phase A Magical Offhands and Jewelry

**Status:** six original Higgsfield equipment illustrations generated and converted to inventory review textures. **Art-only draft; not yet gameplay-integrated.**

## Deliverables

- **Full archive (9,318,603 bytes, 36 entries):** [Download from Higgsfield Developer Files](https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/4628d52f-df22-4aec-82cb-91027d0cb048.zip)
- Media ID: `4628d52f-df22-4aec-82cb-91027d0cb048`
- Six untouched 1024×1024 original Higgsfield GPT Image 2.6 PNGs
- Six processed transparent RGBA master PNGs at **128 pixels per grid cell**
- Six smaller review PNGs at **64 pixels per grid cell**
- Dark and light inventory-backdrop previews, full contact sheet, SHA-256 hashes, source job IDs, Python conversion scripts, QA log

| Variant | Slot | Proposed grid | RGBA master | Small preview |
|---|---|---|---|---|
| Crownfall Aegis | Off hand | 2×2 | 256×256 | 128×128 |
| Chronicle Codex | Off hand | 2×2 | 256×256 | 128×128 |
| Emberglass Focus | Off hand | 2×2 | 256×256 | 128×128 |
| Oathkeeper Signet | Ring | 1×1 | 128×128 | 64×64 |
| Veilthorn Band | Ring | 1×1 | 128×128 | 64×64 |
| Wayfarer's Locket | Amulet | 1×1 | 128×128 | 64×64 |

## Validation

- All six image-generation jobs: **completed**, `use_unlim=true`; **0 paid credits**.
- ZIP self-integrity: **PASS**.
- Master source hash tracking: **6/6 PASS**.
- Inventory dimensions/PNG RGBA/7px alpha gutters: **6/6 PASS**.
- **Visual alpha-edge inspection: PENDING**. Current removal uses GrabCut color segmentation, not a reviewed hand mask. These files may retain background, halos, or missing details; inspect at 32px and 64px per cell on light and dark UI backgrounds.
- **Godot import, inventory, tooltip, drag/drop, equip, merchant, stash, and save regression: PENDING**. No game code, loot tables, balance, existing items, or schema-six save data changed.

## Integration plan

1. Open the archived **processed/CONTACT_REVIEW_6.jpg** and inspect each dark/light preview at 32px and 64px per cell.
2. Refine masks in a non-destructive art tool wherever shadows, chains, ring voids, codex corners or shield edge detail were cut incorrectly. Keep the untouched source alongside the corrected RGBA masters.
3. Import the 128-pixels-per-cell RGBA masters to a **separate Godot art test branch** and check filtering, mipmap/shrink, alpha edge bleed, scale and visibility.
4. Verify 1×1 rings/amulet and 2×2 off-hand placeholders against real inventory placement, paper doll restrictions, loot drops, equipment restrictions and schema-six save/load before making any game item definitions.
5. Do not merge this draft until visual approval and runtime verification. The first eight forged weapons are on separate [draft PR #12](https://github.com/mlyons0990/age-of-the-lost/pull/12).

**Next Phase A batch after this gate:** variant armor sets, magical offhands, accessories, then consumables, relics and material loot art. Honor the original AOTL painterly/ornate Crownsfall style. Do not spend paid credits without explicit user approval.
