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
