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

A playable Crownfall plaza with a first combat loop, a sword-swing animation
for the knight and three painted enemy types:

- The knight walks where you click, paths around walls and planters, and props
  draw in front of him when he stands behind them.
- **Combat:** the plaza is safe until the player opens the "Reality Scar"
  (R). Waves of enemies then spawn; every third wave adds an elite. This arena
  is a placeholder so combat has somewhere to happen.
- **Knight skills:** Slash, Cleave, Shield Charge, Rallying Cry, plus one skill
  from the chosen specialization.
- **Progression:** levels 1-60. Specialization at 10 (Paladin, Death Knight,
  Dragon Knight), an advanced path at 40, a Heroic Talent at 60. All class
  data is work in progress and lives in `scripts/game_data.gd`.
- **Loot:** gold, potions and gear in four rarities. Better gear is equipped
  automatically; the rest is sold. No inventory screen yet.
- **HUD:** health and mana orbs, skill bar with cooldowns and tooltips, XP bar,
  minimap, quest tracker, character panel, name entry on first launch.
- **Saving:** `user://aotl_save.json`, written on level-up, wave clear and quit.

Controls: left click (or hold) to move or attack, Shift+click attack in place,
right click or 1 Cleave, 2 Shield Charge, 3 Rallying Cry, 4 spec skill,
Q potion, R Reality Scar, C character, L gain a level (tester shortcut),
F11 fullscreen, F3 walkable outline, Esc save and quit.

## How to run

1. Install Godot 4.3 or newer (standard build, no .NET needed).
2. In the Project Manager choose Import and select `project.godot`.
3. Press F5.

## Files

| Path | Purpose |
| --- | --- |
| `project.godot` | 1920x1080 base size, fullscreen, compatibility renderer |
| `main.tscn` | One root node; everything else is built in code |
| `scripts/main.gd` | Plaza, navigation, prop cut-outs, camera, Reality Scar waves, loot, quests, saving |
| `scripts/player.gd` | Knight: movement, 8 facings, stats, skills, levels |
| `scripts/enemy.gd` | Enemies: one painted sprite each, animated in code; chase, wind-up warning, strike |
| `scripts/game_data.gd` | Class, spec, enemy and item data (edit this to design classes) |
| `scripts/fx.gd` | Slash arcs, rings, blasts, particles, floating numbers |
| `scripts/loot.gd` | Ground drops |
| `scripts/hud.gd` | HUD and panels, drawn in code |
| `scripts/dev_test.gd` | Scripted self-test, only runs with `-- --autotest` |
| `assets/plaza.png` | 2720x1536 painted plaza, used as one background image |
| `assets/knight/walk_<dir>.png` | Walk strips, 12 frames of 384x384, laid out left to right |
| `assets/knight/idle_<dir>.png` | One 384x384 standing frame per direction |
| `assets/knight/attack_<se,ne>.png` | Sword swing strips, 15 frames of 512x512 (the 384 frame sits centred inside) |
| `assets/enemies/<slime,revenant,brute>.png` | Enemy sprites: Hollowling, Veilbound Revenant, Thornhide Brute |

Directions on disk are `up`, `ne`, `right`, `se`, `down`. The three west-facing
directions are the east-facing strips mirrored in code (`FACINGS` in
`player.gd`).

Distances in combat code are "ground units": 88 painting pixels wide, squashed
by 0.72 vertically (`U` and `SQ` in `game_data.gd`).

## Testing

`godot --path . -- --autotest --shots=<folder>` plays a scripted session
(walk, fight a wave, level to 60 making each class choice, save and reload),
prints results and saves screenshots. Last run on Godot 4.3 (Linux, software
renderer): passed with no script errors. Not yet run on Windows.

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

- Enemies are single still sprites moved in code (bob, lean, lunge); they have
  no walk, attack or death animation frames.
- The knight's sword swing exists for the two diagonal facings only (`se`,
  `ne`, mirrored for the west side). Other facings borrow the nearest one.
  No hit or death animation.
- No inventory screen, stash, dual wielding or item sorting yet.
- Only one zone. The Reality Scar arena stands in for real combat zones.
- The stairs are walkable but the knight does not change height on them.
- Prop cut-outs are hand-traced and rough; a few props have none.
- No sound or music.
- Spec level is 10 here; the older Age of the Lost design notes say 20.

## How the new art was made (November 11)

- **Attack strips:** a 4-second Higgsfield clip (`seedance_2_0_mini`, 480p)
  from the facing's green-screen still, used as both start and end frame, with
  a "one sword slash in place, camera locked, flat green background" prompt.
  `tools/make_attack_strip.py` keys the green,
  matches scale and position to the idle frame, and packs the chosen frames.
- **Enemies:** one `nano_banana_2` image each on flat green, keyed with
  `tools/key_sprite.py`.
