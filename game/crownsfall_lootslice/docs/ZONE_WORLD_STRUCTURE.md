# Zone & World Structure — large seamless zones, portals between them

Owner direction (2026-11-21): zones are bigger than one scene. You run around the whole city (or the whole of
Whisperwood) without loading; only a **zone portal** loads the next area. Whisperwood: arrive coming down the top-left
steps, walk out through the top-right and bottom-left paths *within the same zone*.

## How the reference games do it (research summary)
**Path of Exile.** The world is a chain of *areas*; each area is a separately loaded instance (the wiki defines an area
as "any separately loaded zone"). Inside an area there is no loading at all — areas are large and the camera simply
follows the player. Layouts are generated per instance from the area's rules (hand-made set-pieces plus randomised
connecting pieces), so the same area plays differently each visit. Moving to the next area happens only at an *area
transition* (a doorway, cave mouth or road end, marked with the destination's name) or a waypoint.
**Diablo 4.** One contiguous open world per region, streamed seamlessly — Blizzard: "no loading screens in the open
world"; regions are "up to 10× bigger" than Diablo 3's. Dungeons, cellars and key story spaces are separate private
instances entered through an entrance; that transition does load.
Common pattern → **big seamless area + named transition points**. That is what we now build.

## Our implementation (free, in the lab)
- **Zone = one big painted canvas** (`assets/zones/src/<zone>.zone.json`): several paintings placed at pixel offsets.
  Later paintings blend over earlier ones with a feathered seam, so neighbours fuse into one scene (`tools/build_zone_tiles.py`).
- **Tiles + streaming** (D4-style): the canvas is cut into 2048 px tiles. Tiles near the camera load on a worker
  thread; far ones are dropped. Verified on a 15,360 px test zone: tile under the hero always loaded, peak 6 of 8 tiles
  in memory, no zone change (`tests/verify_zone_streaming.gd`).
- **One walk map per zone** across all its paintings: `walkable` outline + `blocked` cut-outs (ruins, water, columns).
- **Foreground depth** baked over the whole canvas so railings, lamps, trees hide actors behind them.
- **Portals** (`exits`) are the only zone loads: fade, swap zone, place the hero at the arrival point. Gold label in
  the world; minimap header follows the zone.

## Current zones
| Zone | Canvas | Paintings | Portals | Open edges to grow |
|---|---|---|---|---|
| Crownsfall | 3840×1648 | Z1 plaza | south road → Whisperwood | north stairs, side streets |
| Whisperwood | 3840×1648 | W1 shrine clearing (stairs top-left) | stairs top → Crownsfall | top-right path, bottom-left path |

## Growing a zone (needs credits, quote per painting)
Each extension is one more painting placed on the canvas next to the existing one. Best route for seamless joins:
Higgsfield **outpaint** of the existing painting toward the open edge (keeps style, scale and the path continuous), or
a new painting with the shared edge given as a reference. ~6.5 cr per 4K 21:9 piece (2 variants) at today's prices.
Suggested next: Whisperwood top-right path (W2) and bottom-left path (W3); Crownsfall market street off the plaza.

## Approved style (owner, 2026-11-21): Path of Exile
- **One large zone** the player moves through; a new zone loads **only** at a zone-end **exit portal**.
- **Exit portals** can be any doorway / path / stairs, but always carry a **blue/gold glowing aura** (light curtain on the
  threshold, gold ground line, rising sparks, blue light, destination name) — `shaders/portal_aura.gdshader`, `_build_portal`.
- **Waypoints** (checkpoints): rune circle on the ground, grey + "(locked)" until the hero first reaches it, then
  blue/gold with a pillar of light. Click a waypoint → walk to it → the **Waypoints** window opens, listing every
  waypoint by zone in world order (locked = "???"). Pick one to teleport — town included — and use the newly unlocked
  waypoint to return after selling/repairing. Unlocks persist (`user://aotl_waypoints.cfg`).
  Files: `scripts/three_d/waypoints.gd`, `scripts/three_d/waypoint_panel.gd`, `assets/zones/world.json` (zone order + town).
- Current waypoints: Crownsfall Plaza (town, compass rose, always open); Whisperwood — Fallen Shrine (shrine ruins, now
  walkable; only the stream is blocked). `tests/verify_waypoints.gd` 14/14.

## Waypoint placement rules (owner, 2026-11-22)
- A waypoint inside a circular space or object (ruin ring, plaza, rose window, ring of pillars) is **centred in that
  space**: the waypoint's centre point (its basin/sigil) lands exactly on the painted centre of the ruins. Measure the
  centre by fitting an ellipse to the painted rings, store it as `centre_of` in the zone JSON, and keep the
  `verify_waypoints.gd` check (< 10 px on screen) passing. Whisperwood: inner shrine ring centre (1995, 851).
- Waypoint art lies **flat on the painted ground**: fit it to the painting's own ground angle (circles in our paintings
  are ~0.51 as tall as wide), not the 3D camera's. `tools/build_waypoint_art.py ... [rotate_deg] [ground_ratio]`.
- Aim a star point toward the feature the space faces (e.g. Whisperwood: down the stream), never straight up/down.
- Undiscovered = carved stone, no label; discovered = WP2 glowing art + "Waypoint" label.

## Pathfinding (2026-11-22)
- Click-to-move in painted zones routes around obstacles: a visibility graph is built on zone load from corner points
  stepped 0.7 m off every walkable-edge and `blocked` corner; each click runs A* from the hero to the target and the hero
  walks the corners. Targets inside an obstacle stop at the nearest walkable point on the way. Clearance 0.45 m.
- Whisperwood: pillars, fallen statue and toppled columns of the shrine are solid footprints; the ruins floor stays open.
- `tests/verify_zone_pathing.gd` 5/5 (routes round the stream; walks round the pillars to the waypoint).

## Behind-scenery and camera angle (2026-11-22)
- Upright props get explicit silhouettes in the zone JSON (`occluders[].poly` + `holes` for arch openings + foot `line`);
  `tools/build_zone_depth.py` bakes them, so the hero is hidden behind Whisperwood's pillars, arches, arcade, statue
  and fallen columns, and still drawn in front when he stands before them.
- Occluded-actor silhouette (blueprint CAM-04): `shaders/occluded_actor.gdshader` as material_overlay draws a soft gold
  silhouette of the hero only where scenery is in front of him. `xray_enabled` toggles it. Occlusion test 5/5.
- Camera angle study (`tests/capture_camera_angle.gd`): 52 deg (current) vs 31 deg (the paintings' ground angle). Owner
  decision pending; zone JSON `"pitch"` switches a zone's camera, everything else (scale, walk map, depth) follows.
