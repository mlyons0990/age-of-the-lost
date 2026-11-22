# Inventory artwork reconciliation

Snapshot: ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b

All four previously unresolved selected-profile mappings have tracked item-portrait fallbacks. They are not confirmed missing-art defects. Engine import and pixel validation remain open.

## amulet

Fallback: `res://assets/item_portraits/amulet.png`

- aotl_jewelry_amulet_002: [1, 1]; matching footprint, selection review required

## staff

Fallback: `res://assets/item_portraits/staff.png`

- aotl_two_hand_melee_quarterstaff_002: [1, 4]; REJECT direct substitution: footprint mismatch
- aotl_two_hand_melee_war_staff_002: [2, 4]; matching footprint, selection review required
- aotl_caster_mystic_staff_002: [2, 4]; matching footprint, selection review required

## wraps

Fallback: `res://assets/item_portraits/wraps.png`

- aotl_armor_cloth_cloth_gloves_002: [2, 2]; matching footprint, selection review required

## slippers

Fallback: `res://assets/item_portraits/slippers.png`

- aotl_armor_cloth_cloth_boots_002: [2, 2]; matching footprint, selection review required

## Next production work

Validate fallback image bytes and actual engine imports; review matching candidates at gameplay size; retain source provenance and approved status; implement any approved mapping in a separate integration change. Staff quarterstaff art is 1x4 and is not a direct replacement for the current 2x4 staff. Inventory art provides no evidence of a wearable 3D model.

## Subsequent image verification

All 16 runtime portrait images, including all four fallbacks, were fetched, SHA-256 checked against their LFS pointers, fully decoded, and checked against the canonical footprint aspect. All passed. See pixel_verification.json. Engine import and visual approval remain unverified.
