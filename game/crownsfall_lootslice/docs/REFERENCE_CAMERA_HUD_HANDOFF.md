# Reference camera and corner HUD

Reviewed November 13, 2026. The owner's supplied camera/UI reference is the layout baseline. This change applies it to the existing playable Godot 4.6.3 scene, using original AOTL artwork. The source world remains a painted 2D isometric scene; this is not a freely rotating 3D camera or a completed city expansion.

## Playable behavior

- Starts at uniform 0.52 camera zoom. Wheel over the world changes distance; Home restores the starting distance. Bounds adjust to viewport size, preserving scenery coverage. UI hover and paused menus block camera input.
- Life and mana occupy the lower corners inside new Higgsfield stone-guardian/brass frames. Live liquid levels remain engine-driven. The bottom-left five painted health vessels represent the existing shared potion count; Q or clicking the cluster drinks one potion. They are not five independent flask bindings or new mana potions.
- Five approved square ability paintings occupy the lower right, with existing cooldown, insufficient-mana and aura state overlays. Bindings remain LMB and 1–4; RMB also invokes the first equipped skill. Full-square artwork and its individual borders are preserved.
- Thin XP bar and level badge sit along the bottom. Name/level/health/mana follow the actor overhead. The top-right minimap depicts the actual walkable polygon, player and enemies, with the real quest tracker beneath it.
- F2 or the corner button expands menus and control help. The original I/C inventory/character, K spellbook, M mastery, T trial and other working shortcuts remain intact. The right-side equipment/inventory and exact item grid are unchanged.
- Shared `hud_layout.gd` drives both painted geometry and actual input targets. Decorative corner frames, minimap, action-strip gaps and XP region absorb clicks/wheel events. Service markers and combat numbers retain readable screen size at the wider camera distance; service labels appear on approach or hover.

## Art and world integrity

`art/ui_camera/2026-11-12/` at repository root preserves five Higgsfield originals and generation provenance, including rejected scenery iterations. All requests used the authorized unlimited allowance and quoted zero credits; no credit fallback. Initial 429 responses had no job IDs. The mask guide was passed as an image reference because the connector does not expose a canonical hard-mask input.

`tools/rebuild_corner_hud_art.py` crops/downsamples the two frame halves and flask and converts the selected scenery to a runtime JPEG. It does not repaint assets. Reproduction used Pillow 13.0.0. The Cinzel title font is bundled with its SIL Open Font License; source: https://github.com/google/fonts/tree/main/ofl/cinzel .

The surrounding plate spans world rectangle `(-816,-461,4352,2458)`. The exact original plaza remains an overlay at its original coordinates; its decorative edges blend into the new plate, with an extended top blend before the navigable floor begins. Original foreground occluders and navigation remain authoritative. Surrounding artwork is scenery, not a newly traversable district. Original character art, skill tiles, inventory footprints, ownership rules and schema-six saves remain unchanged.

The owner's mockup has inconsistent displayed hotkeys. This build preserves actual established bindings instead of silently remapping movement, inventory and skills. Dodge Roll artwork and its separate implementation branch remain available for the next integration cycle.

## Validation and continuation

The eighteen-suite isolated Linux runner passes **1,039 headless assertions**. The camera/HUD suite passes **49 native checks**, including four additional real-window resize checks (1280×960 and 1440×600) beyond its 45 headless checks. Other checks exercise actual pointer/wheel routing, potion and skill execution, pause, camera limits, every corner of the walking region and save validity. Six native screenshots show Warrior/Mage, inventory, two aspect ratios and combat readability. Reports: `tests/camera_hud_qa/`; captures: `previews/reference_camera/`.

Native environment: X11/Xvfb, software OpenGL, Godot 4.6.3, Dummy audio. No Windows hardware-performance or human difficulty claim. The three previously installed Grady lines remain intact; no new voice generation occurred in this cycle.

Next: integrate the already tested `dev/dodge-roll-2026-11-12` work with this corner layout and rerun both suites. Preserve experimental 2.5D city/rig branches as independent work; do not overwrite their changes or substitute generic characters for the approved art.
