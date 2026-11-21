# Production Blueprint v1.0 vs this branch — comparison (2026-11-21)

Source: `AOTL_Production_Blueprint_and_Checklist.pdf` (Drive, 27 pp, read in full). Branch:
`art/higgsfield-phase1-heroes-2026-11-20` @ 90b18ab (painted zones, HUD v2, portals, waypoints).

## Where we already agree
| Blueprint | This branch | Evidence |
|---|---|---|
| §4C hybrid: painted world + depth proxies + 3D heroes | Painted zone canvas on a ground plane, depth-map occluders, 3D heroes | `rig_lab.gd`, `zone_painting.gdshader` |
| ENV-04 split big paintings into regions, seam overlap, foreground masks | 2048 px tiles with gutters, feathered multi-source canvas, baked depth | `build_zone_tiles.py`, `verify_zone_streaming.gd` 7/7 |
| WORLD-07 transitions both ways, streaming seams | Portals both ways, no-bounce arrival, tile streaming | `verify_zone_travel.gd` 13/13 |
| WORLD-02 collision independent of painting | Walkable + blocked polygons per zone | zone JSON |
| UI-05 one action map, rebinding, conflict steal, persisted | `keybinds.gd`, F1 menu | `verify_arpg_hud.gd` 80/80 |
| UI-01 corner HUD on live state | HUD v2 globes/XP/skills/flasks from actor state | same |
| PIPE-03 Higgsfield job/cost tracking, quote before spend | Ledger md + CSV, every spend verified against balance | `AOTL_HIGGSFIELD_CREDIT_LEDGER.md` |
| PIPE-06 mirror to GitHub + Drive | Every milestone pushed + Drive copies | Drive folder |
| CAM-01 camera profile, pitch in 45–55° range | Ortho, 52° pitch, hero px fixed per zone | `HERO_PX_1080` |

## Conflicts to resolve (owner decision)
1. **Hero screen size.** Blueprint proposes 11–13 % of viewport (~119–140 px at 1080p) as an *estimate*. Owner's direct
   instruction + reference image set **~110 px**, which we implemented. Blueprint itself says direct user direction wins;
   recommend recording 110 px in the decision log (BASE-06).
2. **Expansion before the slice.** Blueprint P2: "improve one street corner and one encounter to target quality before
   expanding the city"; G0/G1 before mass asset production. The E1–E3 extension quotes (42.18 cr) expand ahead of G2.
   Recommend at most E1 now (proves seamless outpaint joins), hold E2/E3 until the G2 slice.
3. **Two game lines.** Main holds the accepted painted 2D build (PR 42); this branch is a 3D-lab line. Blueprint's top
   risk is divergent branches / duplicate authority. Needs BASE-01/02 baseline manifest before more features land here.

## Gaps the blueprint exposes in our work (free to fix)
| ID | Gap | Proposed fix |
|---|---|---|
| CAM-04 | Hero is fully hidden behind railings/lamps/trees | Occluded-actor silhouette/outline (draw hero again with depth-test inverted, tinted) |
| CAM-06 | "AOTL 3D LAB" panel + controls list sit on the play field | Toggle (F10) and off in a release flag |
| WORLD-03 | Painted stairs are flat ground — no ascent/elevation | Height polygons in zone JSON → hero y offset + depth agrees |
| SAVE-01/03 | Waypoints, keybinds, loadout each in their own `user://*.cfg` | Fold into the main save schema with a version + migration |
| UI-09 | Minimap shows black margins, not derived from walkable data | Draw from zone overview + walkable outline, waypoint/portal markers |
| PERF-01/03 | Streaming tested for correctness only | Frame/VRAM capture on a dense encounter in a tiled zone |
| QA-01 | Many tests, no requirement→evidence matrix | CSV tracker mapping checklist IDs to tests/captures |
| LOC-02 | HUD began from PoE-style mockups | Provenance note: shipped HUD art is Higgsfield-generated, list jobs |

## Not in scope of this branch (owner/other dev)
G1 rig comparison (PR 73/74 clipping, missing finger/cape bones), item/affix rules, AI, audio, localization, release
pipeline — owned elsewhere; avoid duplicating PR 76/77 work.
