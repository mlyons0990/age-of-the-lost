# Crownsfall plaza environment (pilot labs) — QA

## v1 (free, 2026-11-21)
- `crownsfall_plaza` opt-in on both pilot lab scenes (`rig_lab.gd` `_build_plaza`): replaces the white test floor
  visuals (collision unchanged) with a procedural limestone flagstone floor and a gold/blue 16-point compass-rose
  mosaic (`tools/make_plaza_floor.py` -> `assets/env/plaza_floor*.png`), a neutral warm-sun light set, an outer apron,
  and the existing Citadel MasonryArt v17 GLB (reused from PR #55's branch, no new art) as the north backdrop.
- Tests unchanged: arpg_hud 80/80, mage 83/83, knight lab 29/29, regression 994/994.
- Limits: procedural floor reads flat next to the painted HUD; citadel is blocky (Phase 17 procedural). Paid polish
  quoted to the owner (painted floor textures, Tripo props) — not spent.
