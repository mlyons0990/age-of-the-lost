# Crownsfall plaza environment (pilot labs) — QA

## v1 (free, 2026-11-21)
- `crownsfall_plaza` opt-in on both pilot lab scenes (`rig_lab.gd` `_build_plaza`): replaces the white test floor
  visuals (collision unchanged) with a procedural limestone flagstone floor and a gold/blue 16-point compass-rose
  mosaic (`tools/make_plaza_floor.py` -> `assets/env/plaza_floor*.png`), a neutral warm-sun light set, an outer apron,
  and the existing Citadel MasonryArt v17 GLB (reused from PR #55's branch, no new art) as the north backdrop.
- Tests unchanged: arpg_hud 80/80, mage 83/83, knight lab 29/29, regression 994/994.
- Limits: procedural floor reads flat next to the painted HUD; citadel is blocky (Phase 17 procedural). Paid polish
  quoted to the owner (painted floor textures, Tripo props) — not spent.

## v2 — 2D painted zones (owner direction: "a 2D game with a few 3D elements; each zone is a 2D environment")
- New `painted_zone` lab option (`rig_lab.gd`): the zone painting (`assets/zones/<zone>.png` + `.json`) is laid on the
  ground and seen through an orthographic camera at the painting's own 52-degree pitch, so it shows exactly as painted;
  the 3D heroes walk on it and cast real shadows onto it (shadow-catcher plane). Hero ~100 px at 1080p.
- Zone JSON: painting size, walkable polygons (pixel space), spawn and enemy positions. The hero is clamped to the
  walkable area; the camera follows but never shows past the painting's edges.
- First zone: Crownsfall Central Plaza, using the existing owner-approved painting (`assets/plaza.png`); Whisperwood
  ruins painting copied in for the next zone. No credits spent.
- Both pilot labs now open in the plaza zone. Tests: painted_zone 7/7, arpg_hud 80/80, mage 83/83, knight 29/29,
  regression 994/994.
- Next: foreground occlusion layer (walk behind lamp posts/planters), zone exits/transitions, Whisperwood walk map.

## v3 — true painting scale (owner: planters should reach the hero's knees)
- Per-zone world scale (zone JSON "ppm"), measured from the painting: planter box ~100 px = 0.5 m -> 320 px/m. Painting still drawn 1:1; hero now 345 px at 1080p with correct proportions.
- Consequence: one screen shows ~5.5 m of ground, so the existing plaza painting is only ~1.4 screens of play space. Real zones need paintings authored for the chosen hero size (owner decision pending).

## v4 — Z1 repaint at owner scale (6.5 cr, approval candidate)
- Painting: `assets/zones/crownsfall_plaza_z1.png` (Higgsfield GPT Image 2.6, job 5fdae107, variant B; A kept in `art/higgsfield_2026-11/zones/`).
- Zone JSON sets `"hero_px_1080": 110` → the hero is ~110 px tall at 1080p regardless of painting size; painting ppm 149 (lamp ≈ 2 hero heights, planter knee-high).
- Zones without `hero_px_1080` keep the old 1:1 behaviour, so the default scenes are unchanged until the owner signs off.
- Preview: `tests/capture_arpg_hud.gd -- --zone=crownsfall_plaza_z1`. verify_painted_zone 7/7 on both zones; regression 994/994.
