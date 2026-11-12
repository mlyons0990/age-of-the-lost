# Crownfall — project handoff

This file gives another developer or AI coding model everything needed to keep
building the game without the original chat.

## What the game is

- A 2D isometric action RPG that plays like Diablo 4 / Path of Exile
  (click-to-move, loot, skills, inventory) and looks like the owner's concept
  art: a light, airy, almost elven holy city called Crownfall.
- Desktop game, full screen, built in **Godot 4.3** (GDScript). Not a browser
  game. The long-term goal is a Steam release.
- Art direction: anime-painted characters with **realistic adult proportions**
  (about 7 heads tall, not chibi), ivory-white stone, royal-blue banners with a
  gold filigree crest, glowing brass lamps, waterfalls and spires behind.
  Reference vibe: Ragnarok Online and Octopath Traveler for the look only.
- Planned later, not built yet: combat, enemies, loot drops, inventory, stash
  in town, dual wielding, inventory auto-sort, many spells with combos, named
  legendary items, and extra classes (the concept sheets show a staff mage, a
  "Voidwalker Rift Monk" and a "Crimson Inquisitor").

## What exists now

A playable Crownfall plaza: the knight walks where you click, paths around
walls and planters, the camera follows him, and props draw in front of him
when he stands behind them. There is a placeholder HUD drawn in code.

Controls: left click (or hold) to move, F11 fullscreen, F3 shows the walkable
outline (green) and prop cut-outs (red), Esc quits.

## How to run

1. Install Godot 4.3 or newer (standard build, no .NET needed).
2. In the Project Manager choose Import and select `project.godot`.
3. Press F5.

## Files

| Path | Purpose |
| --- | --- |
| `project.godot` | 1920x1080 base size, fullscreen, compatibility renderer |
| `main.tscn` | One root node; everything else is built in code |
| `scripts/main.gd` | Plaza background, navigation polygon, depth-sorted prop cut-outs, camera |
| `scripts/player.gd` | Knight: pathfinding, movement, 8 facings, animation, click marker |
| `scripts/hud.gd` | Placeholder HUD (orbs and skill slots) drawn with `_draw` |
| `assets/plaza.png` | 2720x1536 painted plaza, used as one background image |
| `assets/knight/walk_<dir>.png` | Walk strips, 12 frames of 384x384, laid out left to right |
| `assets/knight/idle_<dir>.png` | One 384x384 standing frame per direction |

Directions on disk are `up`, `ne`, `right`, `se`, `down`. The three west-facing
directions are the east-facing strips mirrored in code (`FACINGS` in
`player.gd`).

## How the plaza works

- The plaza is a single painting, not a tile map. Coordinates in the code are
  pixels of `assets/plaza.png`.
- `WALKABLE` in `main.gd` is the outline of the floor. It is triangulated at
  start-up into a `NavigationPolygon`; the knight asks `NavigationServer2D`
  for a path.
- `OCCLUDERS` in `main.gd` are polygons traced around props (lamps, planters,
  banners). Each is a `Polygon2D` textured with the same painting and placed in
  a y-sorted node at the prop's ground line, so it covers the knight when he is
  behind it. To add one: trace the prop, set `base` to the y of its foot.
- Movement is slower "into" the screen (`DEPTH_SQUASH`) to match the camera
  angle.

## How the art was made

All art came from Higgsfield (image model `seedream_5_5`, video model
`seedance_2_0`).

- **Plaza:** generated from the owner's two plaza mockups as references, with
  characters and UI removed, then revised to be lighter and more elven.
- **Knight stills:** generated from the owner's turnaround sheet, redrawn from a
  high isometric camera, one still per facing, transparent background.
- **Walk cycles:** Higgsfield's sprite-sheet animator (`autosprite`) failed
  twice, so each facing was animated another way: the still is placed on a flat
  green background, a 4-second "walks in place, camera locked, flat green
  background" video is generated from it, and the frames are keyed and cut
  into a looping 12-frame strip (the script finds two matching frames about
  one stride apart and samples between them).

## Known gaps

- No combat, enemies, loot, inventory or saving yet.
- The stairs are walkable but the knight does not change height on them.
- Prop cut-outs are hand-traced and rough; a few props have none.
- The knight has walk and standing frames only: no attack, hit or death.
- No sound or music.
