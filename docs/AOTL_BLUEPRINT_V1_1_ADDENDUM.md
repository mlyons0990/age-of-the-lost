# AOTL Production Blueprint — v1.1 Addendum

Applies to: *Age of the Lost — Visual Production and Development Handoff / Comprehensive Development Checklist, v1.0
(2026-11-21)*. Prepared 2026-11-22. v1.0 stays the baseline; this addendum records owner decisions made since, adds the
painted-zone rules that are now proven in the lab, and turns the checklist into a tracked backlog. Where this addendum
and v1.0 disagree, this addendum wins (v1.0 §15: direct user direction takes precedence over estimates).

Evidence branch: `art/higgsfield-phase1-heroes-2026-11-20` (lab: `game/crownsfall_lootslice`, Godot 4.6.3).
This is **not yet merged to main**; see open item O1.

---

## 1. Decision log (APPROVED DIRECTION)

| ID | Decision | Replaces / clarifies | Owner words / date | Evidence |
|---|---|---|---|---|
| D1 | **Hero is ~110 px tall at 1080p**; the world is scaled to the hero, never the hero to the world. | v1.0 §5 estimate of 11–13 % (119–140 px). | "The character size needed to remain the same … the scene needed to be scaled and not the character" (11-21) | `verify_painted_zone.gd`, zone JSON `hero_px_1080` |
| D2 | **Camera: fixed orthographic, 31° pitch** for painted zones (matches the paintings' ground angle). | v1.0 §5 / S10 45–55° experiment range. | "the 31 degree (B) option is approved" (11-22) | `capture_camera_angle.gd`, zone JSON `pitch: 31` |
| D3 | **2D painted world with selected 3D actors.** Zones are paintings; heroes and enemies are 3D. | Confirms v1.0 §4C hybrid for environments. | "not everything has to be in 3D … each zone can just be a 2d environment" (11-21) | Painted-zone system |
| D4 | **Path of Exile zone model**: one large seamless zone per area; a new area loads only at a zone-exit portal. | Resolves v1.0 open item "transitions / streaming seams". | "let's make the approved style the PoE one" (11-21) | `verify_zone_travel.gd`, `verify_zone_streaming.gd` |
| D5 | **Exit portals** may be any door / path / stairs but always carry a **blue/gold glowing aura**. | — | owner, 11-21 | `_build_portal`, `portal_aura.gdshader` |
| D6 | **Waypoints**: checkpoints unlocked by reaching them; teleport to town or any unlocked waypoint and back. Undiscovered waypoints are plain world props (no "locked" label). | — | owner, 11-21 / 11-22 | `verify_waypoints.gd` 17/17 |
| D7 | **Waypoint art**: AOTL ivory/gold eight-point platform (WP1 variant A design), glowing version (WP2) once discovered. Built as a **real low 3D dais**, flush with the floor, uniform all the way round (owner 11-22: "needs to look uniform around the entire circumference"). | — | owner, 11-21 / 11-22 | `scripts/three_d/waypoint_mesh.gd`, `assets/props/waypoint_top*.png` |
| D8 | **Waypoint placement**: a waypoint inside a circular space/object is **centred exactly on its centre**, lies flat on the painted ground, a star point aimed at the feature the space faces. | — | "IT SHOULD BE CENTERED IN THE RUINS" (11-22) | tests: centre within 10 px; rendered glow centroid within 8 px |
| D9 | **Controls**: click-to-move (D4/PoE/LE/GD), fully rebindable; skill block LMB/MMB/RMB over Q W E R T; 5 potions. | Resolves v1.0 UI-05 mockup-hotkey conflict. | owner, 11-20 | `keybinds.gd`, `verify_arpg_hud.gd` |
| D10 | **HUD v2 baseline**: edge-to-edge corner HUD, distinct HP (warden) and mana (seer) globes. | — | "Much better, lets use that as our baseline" (11-21) | HUD QA rev 1–19 |
| D11 | **Expansion pacing**: grow zones one approved extension at a time; E2/E3 wait for the G2 slice. | Applies v1.0 §10 P2. | owner, 11-22 | — |
| D12 | **Credits**: no Higgsfield spend without an explicit approval per operation; re-quote before submit; log + verify. | Restates v1.0 PIPE-03. | owner standing rule | credit ledger |

## 2. Painted-zone production rules (new §5A for v1.0)

These are the lessons already paid for. Follow them for every new zone or extension.

**2.1 Scale and camera**
- Set the zone's `pitch` (31) and `hero_px_1080` (110). The painting's `ppm` (painting px per metre) comes from its own
  props: lamp posts ≈ 2 hero heights, planters knee-high. Never resize the hero to fit a painting.
- Generate new paintings at this camera and scale (prompt with an approved zone as the scale reference).

**2.2 Ground angle and props on the ground**
- Symmetric props (waypoints, seals, fountains' bases) are built as **real 3D geometry** textured with a top-down
  painting made perfectly symmetric (`tools/build_waypoint_topdown.py`: un-tilt the generated art, take one clean
  mirrored wedge, repeat it). A generated oblique painting is never exactly symmetric, and flattening/rotating a
  picture of a raised object makes it lean (both rejected by the owner). Geometry is exact at any camera angle.
- Aim a waypoint's bottom star point with `face` (a painted feature) in the zone JSON; the test checks it.
- Measure the painting's ground ratio by fitting an ellipse to a painted circle (height/width): Crownsfall 0.43,
  Whisperwood 0.51. Store it as `ground_ratio`.
- Any prop art laid on the ground (waypoints, decals) is flattened to that ratio — **not** the 3D camera's angle.
  `tools/build_waypoint_art.py <src> <out> <cx> <cy> [rotate_deg] [ground_ratio]`. (Mistake we made: flattening to the
  camera made the waypoint look tilted.)
- Turning ground art (to aim a point) must keep its **height straight up**: the tool removes the raised parts' lift,
  rotates the flat layout, and re-applies the lift vertically. (Mistake we made: a flat image rotation made the raised
  centre lean and left extra stone on one side — lopsided, AI-looking.)
- Place ground art by its **visual centre** (the waypoint's glowing basin), never by the image centre; the render test
  measures the glow centroid against the painted centre.

**2.3 Walk map**
- `walkable` outline + `blocked` cut-outs (water, pillars, statues, fallen columns). Ruins floors stay open; solid
  objects block. Pathfinding (visibility graph + A*) builds itself from these on load — no extra authoring.

**2.4 Hiding behind scenery**
- Long low foreground edges (railings, hedges): `occluders` with a foot `line`.
- Upright props (pillars, arches, statues, trees): `occluders` with a traced `poly`, `holes` for openings, and the foot
  `line` where the prop meets the ground. Bake with `tools/build_zone_tiles.py`.
- The occluded-actor gold silhouette keeps the hero readable behind anything.

**2.5 Large zones**
- A zone is one canvas assembled from several paintings (`sources` with offsets, feathered seams), cut into 2048 px
  tiles that stream around the camera. Extensions are outpaints of the existing painting so paths continue pixel-exact.

**2.6 Portals and waypoints**
- `exits`: polygon at the zone edge, destination, arrival point off the return exit (no bounce).
- `waypoints`: `id`, `name`, `at`, `centre_of` (measured centre of the enclosing ring), `size_px`. The centring test
  must pass before a zone is accepted.

**2.7 Acceptance for a zone** (adds to v1.0 definition of done)
Free in-game render sent to the owner → walk map, occluders, portals, waypoints authored → zone tests green → owner
sign-off → commit + Drive copy.

## 3. Checklist as a tracked backlog

`docs/AOTL_CHECKLIST_TRACKER.csv` (also on Drive as a sheet) lists all 162 v1.0 tasks with: owner roles, **named owner**
and **reviewer** (blank = to assign), milestone (= gate), status, evidence link and notes. Status values:
`Open`, `In progress`, `Partial` (some evidence, not full acceptance), `Evidence (lab)` (meets the criterion on the lab
branch, awaiting owner sign-off and merge), `Accepted`, `Out of scope` (with reason).

Snapshot 2026-11-22: 137 Open · 20 Partial · 3 Evidence (lab): CAM-04, ENV-04, UI-05 · 1 Evidence: PIPE-03 · 1 In progress: QA-01.
Nothing is marked Accepted: per v1.0, passing tests do not approve art and lab evidence is not a merged baseline.

## 4. Open items raised by this addendum
- **O1 (P0, G0):** baseline manifest: which build is approved, and how this branch relates to `main`, PR 76 / PR 77 (other
  developer) and the 2D painted build on main. Blocks merging the painted-zone work.
- **O2:** assign named owners and reviewers in the tracker (one person may hold several roles).
- **O3:** fold waypoint / keybind / loadout settings into the versioned save (SAVE-01/03).
- **O4:** lab debug panel off the play field (CAM-06); painted stairs have no elevation yet (WORLD-03).
