# ARPG HUD (pilot labs) — QA 2026-11-20

Built to the owner's HUD mockup ("AOTL 2.5D LAB v0.2"; spec in `art/references/2026-11-20/README.md`).
Free: all art reused from the 2D Crownfall HUD and the existing painted skill tiles (no generation).

| Mockup element | Implementation (`scripts/three_d/arpg_hud.gd`) |
|---|---|
| Logo + lab panel (top-left) | "AGE of the LOST / CROWNSFALL", status checklist, controls list |
| Minimap "Crownsfall / Central Plaza" (top-right) | SubViewport top-down ortho of the live lab world, gold frame, player + enemy markers |
| Quest tracker | "A City Reborn", "The Lost Tomes — Recover the Archive Pages (n/3)" (n follows kills, max 3) |
| HP globe + "HP x / y" | `orb_life_*` as a bottom-to-top TextureProgressBar on the controller's real HP |
| Potion belt 1–5 + tome | 3 health (+45 HP) and 2 mana (+60 MP) potions, 6 s per-slot cooldown, never wasted at full |
| Skill bar + MP globe | LMB, RMB, Q, E, R, T. Mage: Bolt / — / Lance / Nova / Judgment / —. Warrior: Slash / — / Cleave / Dash / Cast / —. Cooldown shade, purple tint when MP is short |
| XP bar "Lv. 25" | thin purple bar between the belts (cosmetic; advances with kills) |
| Overhead nameplate | "Wayfarer", level badge 25, green HP + blue MP bars |
| Enemy bars | thin red bars over dummies (the 3D text titles are hidden) |
| Camera | unchanged PoE-scale pilot camera (~107 px hero at 1080p) |

Gameplay hooks added: controller `mana` / `max_mana` (120, +6/s), spell costs (Bolt 6, Lance 18, Nova 30,
Judgment 24; Warrior Cast 20), `restore()` for potions.

**Deviation from the mockup:** the mockup shows skills on Q **W** E R T, but W is forward movement (WASD), and
pressing it fired a skill while walking (caught by the regression suite). Skills therefore sit on **Q E R**
(T and RMB shown locked for future skills); 1–5 are potions as in the mockup.

Opt-in: `arpg_hud = true` on `pilot_mage_combat_lab.tscn` and `pilot_knight_combat_lab.tscn`; every other lab keeps
the debug HUD and 1/2/3 skill keys.

Evidence: `art/higgsfield_2026-11/hud_previews/arpg_hud_{mage,knight}_1080p.jpg`.
Tests: `tests/verify_arpg_hud.gd` 35/35; mage 83/83; knight lab 29/29; armed knight 41/41; regression 994/994.

Not yet: the lab is still a white test floor, not the Crownsfall plaza of the mockup; HUD is laid out for
1920×1080 (no resolution scaling yet); XP/level are cosmetic.

## Revision 2 (owner feedback: "no empty space between the left and right screen borders … anchored to the sides")
- Bottom HUD is now one edge-to-edge frame (`hud_frame.png` from the 2D game, slot map `hud_frame.json`), anchored
  left/right/bottom and scaled to the viewport width: life orb flush in the bottom-left corner, 5 potion sockets,
  centre panel with "Lv. 25" + XP bar, 7 skill sockets (Q E R T F | LMB RMB), mana orb flush bottom-right.
- The frame's painted orbs are darkened from the top as HP/MP drop (circular-segment shade + surface line).
- Camera: measured hero height **100 px** at 1080p (knight standing, head_end 1.69 m) with the existing pilot camera.
- Tests: `verify_arpg_hud.gd` 40/40 (adds anchoring, full-width, bottom-edge, corner-orb and socket-count checks).

## Revision 3 (owner: "It needs to look like this, even use these graphics and assets")
- The bottom HUD now uses the owner's mockup artwork itself: `hud_left.png` (seated statue, life orb, potion belt
  with numbered wells and the chest slot) and `hud_right.png` (skill panel, mana orb, statue), cut from the owner's
  close-ups with OpenCV GrabCut (`tools/cut_hud_mockup.py`; sources in `art/references/2026-11-20/hud_mockup/`).
  The baked skill icons and Q W E R T letters were blanked so live icons, cooldowns and key labels draw on top;
  the baked "HP 3,420" / "MP 1,280" text lies outside the cut and is replaced by live values on dark plates.
- Left piece flush to the left and bottom edges, right piece flush to the right and bottom edges, a bronze XP strip
  ("Lv. 25", purple fill) joins them along the bottom: no gap edge to edge. Scales with screen height.
- Skill wells: Q Lance, E Nova, R Judgment, T locked, LMB Bolt (Mage); Q Cleave, E Dash, R Cast, T locked, LMB Slash
  (Warrior). W stays movement.
- Source resolution: the close-ups are phone screenshots (~2.2x the 1080p size), so the pieces are slightly soft;
  a clean high-res redraw of the same design is the upgrade path.
- Tests: `verify_arpg_hud.gd` 40/40 (flush-edge, joined-strip, equal-orb and well-count checks); regression 994/994.

## Revision 4 (owner: globes and surrounding art had rough, unfinished edges)
- Rings re-cut as exact anti-aliased circles fitted to the art (left r 198 px, right r 182 px in source pixels), panel
  edges straight, statue outlines smoothed and stray background leaves removed (`tools/refine_hud_mockup.py`).
- Pieces pre-scaled with Lanczos to their 1080p size (draw 1:1; the runtime 0.47x downscale was causing jaggies).
- Drained orbs: a canvas shader clipped to each glass disc (fitted ellipse) darkens the spent part with a soft
  meniscus, replacing the hard polygon lens. Label plates darkened to match the mockup.
- Tests: arpg_hud 42/42 (adds equal ring size, 1:1 draw and shader-fill checks); regression 994/994.
- Limit: source is phone-screenshot quality; a pixel-sharp 1:1 version needs a high-res redraw of the same art.

## Revision 5 — click-to-move (owner: "this game isn't WASD to move, it's a click to move game like Diablo 4, PoE,
## Last Epoch, Grim Dawn")
- Pilot labs (ARPG HUD) are click-to-move: **LMB on the ground** walks there (hold to keep following the cursor; a
  small gold ring marks the destination); **LMB on an enemy** walks into range and attacks (Warrior Slash at 1.6 m,
  Mage Bolt at 5.4 m; holding LMB keeps attacking); **Shift+LMB** attacks in place toward the cursor;
  **Q W E R T** cast toward the cursor (Q Lance/Cleave, W Nova/Dash, E Judgment/Cast, R and T reserved);
  **Space** dodges toward the cursor; **1–5** potions. WASD is ignored in this mode.
- The skill bar now reads Q W E R T exactly like the mockup (W no longer clashes with movement).
- Bolt and Lance hit at their projectile reach (narrow cone + line of sight) instead of the generic 3.3 m Cast range.
- Legacy debug labs keep WASD so the existing regression suite is unchanged.
- Tests: arpg_hud 52/52 (ground click arrival, WASD ignored, cursor enemy pick, walk-into-range attack for Mage and
  Knight, Shift+LMB in place, W casts); mage 83/83; knight lab 29/29; armed knight 41/41; regression 994/994.
