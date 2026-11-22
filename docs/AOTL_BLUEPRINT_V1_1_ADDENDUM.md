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
| D1 | **Hero is ~110 px tall at 1080p** (town); per-zone `hero_px_1080` can raise it where the painting's props are larger (Whisperwood 125 px, owner 11-22); the world is scaled to the hero, never the hero to the world. | v1.0 §5 estimate of 11–13 % (119–140 px). | "The character size needed to remain the same … the scene needed to be scaled and not the character" (11-21) | `verify_painted_zone.gd`, zone JSON `hero_px_1080` |
| D2 | **Camera: fixed orthographic, 31° pitch** for painted zones (matches the paintings' ground angle). | v1.0 §5 / S10 45–55° experiment range. | "the 31 degree (B) option is approved" (11-22) | `capture_camera_angle.gd`, zone JSON `pitch: 31` |
| D3 | **2D painted world with selected 3D actors.** Zones are paintings; heroes and enemies are 3D. | Confirms v1.0 §4C hybrid for environments. | "not everything has to be in 3D … each zone can just be a 2d environment" (11-21) | Painted-zone system |
| D4 | **Path of Exile zone model**: one large seamless zone per area; a new area loads only at a zone-exit portal. | Resolves v1.0 open item "transitions / streaming seams". | "let's make the approved style the PoE one" (11-21) | `verify_zone_travel.gd`, `verify_zone_streaming.gd` |
| D5 | **Exit portals** are set INTO a painted threshold (staircase, doorway, cave mouth), never floating on open ground, with a **blue/gold glow** spilling over it and a light veil in the opening. | — | owner, 11-21 / 11-22 ("needs to look organic") | `_build_threshold_portal`, `threshold_glow.gdshader` |
| D6 | **Waypoints**: checkpoints unlocked by reaching them; teleport to town or any unlocked waypoint and back. Undiscovered waypoints are plain world props (no "locked" label). | — | owner, 11-21 / 11-22 | `verify_waypoints.gd` 17/17 |
| D7 | **Waypoint art**: AOTL ivory/gold eight-point platform (WP1 variant A design), glowing version (WP2) once discovered. **Master waypoint = WP3**, the same design painted at the game camera and used unwarped in every zone (owner 11-22). Per-biome material variants (caves, hostile) are generated from WP3 when needed. | — | owner, 11-21 / 11-22 | `assets/props/waypoint_wp3.png`, `tools/build_waypoint_sprite.py` |
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
- Props that sit on the painted ground (waypoints, seals) are **painted at the game camera** and used as-is; never
  re-angle, flatten, rotate or 3D-rebuild a painting made for a different view (all tried and rejected 11-22: tilt,
  lean, lopsided, soft/"crappy 3D"). Earlier experiment kept for reference: symmetric props built as **real 3D geometry** textured with a top-down
  painting made perfectly symmetric (`tools/build_waypoint_topdown.py`: un-tilt the generated art, take one clean
  mirrored wedge, repeat it). A generated oblique painting is never exactly symmetric, and flattening/rotating a
  picture of a raised object makes it lean (both rejected by the owner). Geometry is exact at any camera angle.
- House style: every waypoint's bottom star point tilts slightly right (22.9 deg, as at the Whisperwood shrine).
  `face` (a painted feature) can aim it instead; the test checks both.
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
- `exits`: anchored to a painted threshold. `aura.poly` = exit edge (between the posts / door jambs) + where the glow
  fades out down the steps; trigger `poly` covers the top of the threshold; arrival point off the return exit. When a
  new painting is generated, ask for the exit feature (stairs, gate, cave mouth) at the zone's edge so the portal has
  somewhere real to live.
- `waypoints`: `id`, `name`, `at`, `centre_of` (measured centre of the enclosing ring), `size_px`. The centring test
  must pass before a zone is accepted.

**2.7 Acceptance for a zone** (adds to v1.0 definition of done)
Free in-game render sent to the owner → walk map, occluders, portals, waypoints authored → zone tests green → owner
sign-off → commit + Drive copy.

**2.8 Zone content and world flow (owner, 2026-11-22)**
- Every zone outside towns/cities has **several points of interest**: e.g. a lorecasting unlock, a waypoint, a rare
  boss arena, a secret area, plus its entrance/exit portals on painted thresholds.
- Every zone has its **own feel** and **blends into the previous and next zone** (biome gradient across a chain): e.g.
  lowlands -> foothills with patchy snow -> snowfields -> a mountain zone in full snow and blizzard; or jungle ->
  drier scrub -> desert -> oasis. A zone's near edge looks like the zone before it; its far edge like the next.
- Large zones are built **master-then-tiles**: a free plan sketch (`tools/draw_zone_plan.py`) -> owner approves the
  layout -> one master layout painting of the whole zone -> full-detail tiles painted from it. (Edge outpainting was
  tested with E1 and could not be steered to continue paths; see the credit ledger.)
- **Zone size: at least 3 x 3 tiles** (owner 11-22). 3 x 3 tiles of 21:9 at the 31-degree camera cover nearly square
  ground (~1.2 : 1), so neighbouring zones fit edge to edge.
- **Free movement**: the whole floor is walkable; only trunks, rocks, water, ruins and buildings block (small
  footprints, not whole woods). Paths guide the player, **going off-path is rewarded**: hidden caches, lore, events,
  camps, secret areas, rare spawns.
- Whisperwood plan (v2): 3 x 3 tiles; W1 shrine clearing top-middle; POIs: Fallen Shrine waypoint, Weeping Stele (lore),
  Drowned Altar (lore), Elder Grove (rare boss: the Thornmother), Moonwell Glade (secret, behind a root tunnel);
  exits: Crownsfall stairs (north) and a mossy stone arch to Hollowmere (marsh, south-east). Off-path: Fae Ring
  (mushroom event), Hunter's Camp (journal page), 5 hidden caches. Gradient: tended and
  lantern-lit near Crownsfall -> wild, wet and misty toward Hollowmere.

**2.9 Zones are built from a reusable kit (owner decision, 2026-11-22) - supersedes painted-canvas zones**
- Every zone, Crownsfall and other towns included, is assembled from reusable elements: tileable ground textures
  (grass, moss, dirt, flagstone, cobble, snow...), paths drawn as splines over them, and individual props painted once
  at the game camera on transparent backgrounds (trees, rocks, stones, ruins, buildings, lamps, fences, POI set pieces).
- Each prop carries its own footprint (collision) and occluder outline, so free movement and hide-behind work per object.
- Layout comes from the free plan sketch (`tools/draw_zone_plan.py`), not from a painted master; painted masters are
  mood/colour references at most. Biome blending across zones = shifting ground/prop sets and overlays (e.g. snow).
- Lessons that led here (E1 outpaint, path connector, master paste, master upscale): separate AI images cannot be made
  to continue paths and trees exactly, and one image big enough for a zone cannot hold game-level detail.

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
