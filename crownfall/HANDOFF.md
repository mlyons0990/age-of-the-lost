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
  (R). Waves of enemies then spawn; every third wave adds an elite. From wave 2
  ranged **Hexbound Gravecallers** join: they keep their distance (and back away,
  trying side routes when a wall is behind them), charge a green bolt with an aim
  line on the ground, then fire it. Bolts fly in a straight line and can be
  sidestepped.
- **Elite affixes (Diablo style):** every elite rolls one affix (two from
  character level 15), shown in colour above its name. Swift (moves 45% faster,
  attacks 30% faster), Shielded (a ward blocks all damage for 2.2 s every 7 s),
  Molten (explodes 1.3 s after dying; step out of the orange ring), Summoner
  (calls two Hollowlings at 60% and 25% life). From wave 6 elites can also be
  Gravecallers. Numbers live in `ELITE_AFFIXES` in `game_data.gd`.
- **Boss every fifth wave:** the Unwritten Warden (the Brute art, much larger
  and darkened; replace with real art later). Big health bar at the top of the
  screen. Every 5 s it slams the ground where the knight stands (purple warning
  ring, 1.1 s to step out); it calls Hollowlings at 60% and 25% life; below 35%
  it enrages: red tint, faster, slams twice (the second ring leads the knight).
  It resists knockback and stuns. Defeat drops a guaranteed legendary, a second
  good item and triple gold, and counts on the character panel ("Wardens
  defeated", saved). Closing the Scar clears pending slams and bolts. Tuning:
  `warden` in `ETYPES` and `BOSS_EVERY` in `game_data.gd`.
- **Hovering an enemy** shows its health bar at the top, plus a line for each
  elite affix explaining what it does.
- **Ground loot (Path of Exile style):** every drop gets a name plate in its
  rarity colour; plates stack upward so they never overlap, the best item keeps
  the spot nearest its drop. Magic and better always show; commons, gold and
  potions show while Alt is held or the mouse is near. Click a plate to walk to
  it. Light by rarity: magic a soft glow, rare a beam, legendary a tall pulsing
  pillar with ground rings, its own chime and a "Legendary: ..." message.
- **Death:** the knight topples and darkens, then the death screen names what
  killed him (enemy, bolt or Molten blast), the wave reached and the cost: 10%
  of carried gold (`DEATH_GOLD_LOSS` in `main.gd`); gear is never lost. Enter or
  the button rises again at the plaza with full life, a chime and 2 s of
  invulnerability. Deaths are counted on the character panel and saved. This arena
  is a placeholder so combat has somewhere to happen.
- **Knight skills:** Slash, Cleave, Shield Charge, Rallying Cry, plus one skill
  from the chosen specialization.
- **Progression:** levels 1-60. Specialization at 10 (Paladin, Death Knight,
  Dragon Knight), an advanced path at 40, a Heroic Talent at 60. All class
  data is work in progress and lives in `scripts/game_data.gd`.
- **Loot:** gold, potions and gear in four rarities and nine item types
  (weapon, shield, helm, chest, gloves, belt, boots, ring, amulet). Items go
  into the backpack; if it is full they stay on the ground until there is room.
- **Docked panels (Path of Exile layout, November 12):** panels slide in at the
  screen edges instead of a centred window, and the game keeps running while
  they are open. Left side, one at a time: Character (C), Stash (K), Maren's
  wares (talk to her) and Spellbook (P). Right side: Inventory (I), gear slots
  on top in the PoE arrangement (weapon, helm, amulet, off hand, rings, chest,
  gloves, belt, boots), potion row, backpack grid below, Sort and gold.
  Stash and merchant open both sides. Esc closes everything. Dark textured
  panels with an iron and gold frame and a serif title plate (Liberation Serif,
  OFL licence in `assets/fonts`). Clicking the ground while holding an item
  drops it on the floor; it is not picked back up until you walk away from it.
  HUD parts behind a panel (name block, buttons, minimap, quest) hide.
- **Character panel (C):** portrait, name, level, class, the five attributes
  with + buttons, six stat boxes (Life, Mana, Damage, Armour, Dodge, Critical)
  and a scrolling list: Offence, Defence, Life, Mana, Utility and the class
  path. Hover any stat for an explanation.
- **Spellbook (P):** every skill with its icon, hotkey, mana, cooldown after
  attack speed and cooldown reduction, and damage worked out from your current
  stats; all three specializations, their advanced paths and the Heroic
  Talents, showing which are chosen, available or locked.
- **Item comparison:** hovering an item shows each stat's difference from the
  worn item in green or red, an "If equipped" summary (damage, life, armour,
  mana, crit), and the worn item in a "Currently equipped" box beside it.
- **Inventory (I):** 10x6 backpack with item footprints (sword 1x3, chest 2x3,
  helm 2x2, ring 1x1 and so on), and a paper doll with no portrait: helm,
  amulet, main hand, chest, off hand, belt, gloves, boots and two rings.
  Drag and drop items (press, move, release), or click to lift an item onto
  the cursor and click again to put it down. Dropping onto one item swaps
  them. A drag released where the item can't go snaps it back. Right click
  equips or unequips. The off hand takes a
  shield or a second weapon at half damage. Tooltips show stats, sell price and
  what is currently worn in that slot. Sort button repacks the grid.
- **Merchant:** Maren stands at the top of the market steps (left of the
  plaza). Click her to walk over and trade, or press E next to her. Drag items
  onto her panel, right click or Ctrl+click them to sell. Sold items go to a
  buyback row (last 8, this session only) and can be bought back for what she
  paid. She sells Health Potions (25 gold), six pieces of gear around your
  level at four times their sell value (restocked on level-up and when the
  Scar closes after a cleared wave), and has a "sell all common items" button. Selling only happens at the merchant; she won't trade while the
  Reality Scar is open.
- **Sound:** 26 original sound effects (sword swings, hits, crits, skills,
  enemy deaths, loot, potions, level-up, the Reality Scar, inventory clicks),
  synthesized by `tools/make_sfx.py` into `assets/sfx/`. Played by
  `scripts/audio.gd` with slight pitch variation. M mutes. No music yet.
- **Lorecasting:** faint violet sigils in the plaza hold lost memories (by
  the statue, at the top of the old stairs, near the notice board). Walk up and
  press E or click one to Lorecast: a short memory is shown and added to the
  journal (J), with experience the first time. The first elite you defeat in
  the Reality Scar leaves an "echo" to read. Text lives in `LORE` in
  `game_data.gd`; it follows the canon (Crownsfall stitched from erased eras,
  the statue that doesn't match, the lost royal guard) without the provisional
  character names.
- **Music:** two original loops synthesized by `tools/make_music.py`: a calm
  plaza theme (pad, harp, flute) and a battle loop for the Reality Scar (war
  drums, low strings, choir). They crossfade when the Scar opens and closes.
- **Stash (K):** separate 10x8 grid. Right click moves items between stash and
  backpack. Closed while the Reality Scar is open.
- **Starting kit:** a new character starts with four plain items in the
  backpack. Existing saves are left alone.
- **HUD:** health and mana orbs, skill bar with cooldowns and tooltips, XP bar,
  minimap, quest tracker, character panel, name entry on first launch.
- **Main stats:** Strength, Dexterity, Vitality, Intelligence and Wisdom (no
  Charisma). They grow automatically each level (World of Warcraft style) and
  gear rolls them as bonuses, more on rarer items (Diablo style: magic 1,
  rare 2, legendary 3, from a pool that depends on item type). Each class has a
  main stat that raises all its damage; the Knight's is Strength.
  - Strength: +0.5% damage per point (as main stat) and +0.5 armor
  - Dexterity: +0.06% crit chance and +0.05% dodge chance (dodge capped at 30%)
  - Vitality: +5 maximum life
  - Intelligence: +3 maximum mana and +0.4% damage with specialization skills
  - Wisdom: +0.15 mana per second and +0.5% healing received
  All numbers live in `PER_POINT` and `CLASS_ATTRS` in `game_data.gd`.
- **Stat points (Diablo II style):** 5 points per level to place by hand on the
  character panel (C): click + for one point, Shift+click for five. Automatic
  growth per level was halved to make room for them. "Reset points" returns
  every placed point for 20 gold per character level. Older saves get all
  their earned points back to spend. A glowing reminder under the top buttons
  shows unspent points.
- **Secondary bonuses (Diablo-style):** rare items roll 1 and legendaries 2 of
  critical strike damage, attack speed, life per hit, cooldown reduction and
  movement speed, from a pool per item type (`SECONDARY` and `SECONDARY_POOL`).
  Attack speed speeds up the swing animation and its hit timing; movement speed
  speeds up the walk cycle. Caps: cooldown reduction 50%, attack speed 75%,
  movement speed 40% (`CAP`).
- **Saving:** `user://aotl_save.json` (save_version 2: adds backpack and stash),
  written on level-up, wave clear, closing the inventory and quit. Older saves
  load with an empty backpack and stash; saved grids are re-checked for overlaps.

Controls: left click (or hold) to move or attack, Shift+click attack in place,
right click or 1 Cleave, 2 Shield Charge, 3 Rallying Cry, 4 spec skill,
Q potion, R Reality Scar, C character, I inventory, K stash, E trade or Lorecast, J journal, M mute, L gain a level (tester shortcut),
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
| `scripts/enemy.gd` | Enemies: one painted sprite each, animated in code; melee chase, wind-up warning, strike; ranged casters keep distance and fire bolts |
| `scripts/bolt.gd` | Enemy projectile: straight-line glowing orb that can be dodged |
| `scripts/hazard.gd` | Delayed ground blast with a warning ring (Molten elites; reusable for bosses) |
| `scripts/game_data.gd` | Class, spec, enemy and item data (edit this to design classes) |
| `scripts/fx.gd` | Slash arcs, rings, blasts, particles, floating numbers |
| `scripts/loot.gd` | Ground drops |
| `scripts/inventory_logic.gd` | Pure inventory rules: footprints, grid packing, sorting, slot rules, gear totals |
| `scripts/inventory_window.gd` | Docked panels drawn in code: character, spellbook, stash, merchant, inventory; drag and drop; item comparison |
| `scripts/icons.gd` | Skill and potion icons drawn in code, shared by the HUD and spellbook |
| `assets/portrait.webp`, `assets/fonts/` | Character panel portrait; serif title font (OFL) |
| `scripts/audio.gd` | Sound effect player (pool of players, per-sound volume, mute) |
| `tools/make_sfx.py` | Generates every sound effect from noise and tones; edit and re-run to change them |
| `scripts/memory_point.gd` | A Lorecasting sigil on the ground |
| `tools/make_music.py` | Generates the two music loops (needs ffmpeg) |
| `assets/music/` | `plaza.ogg` and `scar.ogg` |
| `scripts/npc.gd` | Townsperson in the plaza (sprite, name plate, idle sway); used for the merchant |
| `assets/npc/merchant.png` | Maren the merchant |
| `scripts/hud.gd` | HUD and panels, drawn in code |
| `scripts/dev_test.gd` | Scripted self-test, only runs with `-- --autotest` |
| `assets/plaza.png` | 2720x1536 painted plaza, used as one background image |
| `assets/knight/walk_<dir>.png` | Walk strips, 12 frames of 384x384, laid out left to right |
| `assets/knight/idle_<dir>.png` | One 384x384 standing frame per direction |
| `assets/knight/<hit,cast>_<se,ne>.png`, `death_se.png` | Knight flinch (on taking a hit, unless swinging), cast (Rallying Cry and the spec skills) and death fall, cut from the Higgsfield clips with `tools/make_attack_strip.py`; frame rates in `ACTION_FPS` in `player.gd` |
| `assets/knight/attack_<se,ne>.png` | Sword swing strips, 15 frames of 512x512 (the 384 frame sits centred inside) |
| `assets/enemies/<slime,revenant,brute>.png` | Enemy sprites: Hollowling, Veilbound Revenant, Thornhide Brute |
| `assets/items/painted/<art id>.png` | Painted item portraits from `art/item_taxonomy` (Higgsfield). Each item stores its `base` ("Chainmail", "Kite Shield"...) and `ITEM_ART` in `game_data.gd` maps bases to art: plate, mail, leather and cloth armour, three shields, sword/axe/mace. Old saves infer the base from the name |
| `assets/skills/<skill id>.png` | Full-square framed skill tiles (Diablo 4 / Path of Exile style) from `art/skill_tiles` (Higgsfield GPT Image 2.6), 128 px, for all seven Knight skills. They fill the whole action-bar slot; the HUD draws a clockwise cooldown sweep and key plates over them (`icons.gd`) |
| `assets/items/<slot>.png` | Fallback item icons (weapon, offhand, helm, armor, gloves, belt, boots, ring, amulet), sized to each footprint. Made by `tools/make_item_icons.py`; replace any with a painted portrait of the same aspect and the game uses it |
| `tools/make_item_icons.py` | Paints the item icons (gradients, outlines, highlights) in the knight's palette |
| `assets/enemies/anim/<key>_<walk,wind,strike,death>.png` | Enemy animation sheets cut from the Higgsfield clips (`art/higgsfield_trial` branch) by `tools/make_enemy_anim.py`: green keyed, scaled to the still, feet anchored, cells cropped to fit all frames. `tools/collect_enemy_anims.py` writes their layout to `scripts/enemy_anims.gd`. Revenant/Gravecaller (recoloured), Hollowling, Brute (also the Warden), Legionnaire, Stag. Walk loops while moving, wind-up frames follow the warning, strike frames play when the blow lands, death frames play for 1.5 s (Revenant, Gravecaller and Stag still fade) |
| `assets/enemies/<skeleton,stag>.png` | Stills for the Dread Legionnaire (wave 3+) and the Root-bone Stag (wave 4+, fast) |
| `assets/enemies/hexcaller.png` | Placeholder Gravecaller: the Revenant recoloured spectral green. Replace with real art when available |

Directions on disk are `up`, `ne`, `right`, `se`, `down`. The three west-facing
directions are the east-facing strips mirrored in code (`FACINGS` in
`player.gd`).

Distances in combat code are "ground units": 88 painting pixels wide, squashed
by 0.72 vertically (`U` and `SQ` in `game_data.gd`).

## Testing

`godot --path . -- --autotest --shots=<folder>` plays a scripted session
(walk, fight a wave, level to 60 making each class choice, 153 checks covering
inventory, stash, drag and drop, merchant and shop, stats and stat points,
Lorecasting, sound and music driven by simulated mouse clicks, save and reload),
add `--invonly` to run just the inventory checks,
after adding a sound or image run `godot --headless --path . --import` once (a
file Godot hasn't imported is silently skipped; the sound check catches this),
the last check confirms every test section ran to the end (a GDScript error
inside a section stops it without failing a check, so also look for
"SCRIPT ERROR" in the output),
prints results and saves screenshots. Last run on Godot 4.3 (Linux, software
renderer, November 12): passed with no script errors and 153 of 153 checks. Not yet run on Windows.

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
- Inventory and stash are drawn with simple shapes; no painted item icons or
  ornate frames yet. No item comparison beyond the tooltip.
- No stat points to spend by hand; stats come from level and gear only.
- No resistances or secondary affixes yet (attack speed, crit damage, life
  on hit and so on).
- Only one zone. The Reality Scar arena stands in for real combat zones.
- The stairs are walkable but the knight does not change height on them.
- Prop cut-outs are hand-traced and rough; a few props have none.
- Sound effects and music are synthesized placeholders, checked by levels and
  spectrograms only; they were not listened to before delivery.
- Spec level is 10 here; the older Age of the Lost design notes say 20.

## How the new art was made (November 11)

- **Attack strips:** a 4-second Higgsfield clip (`seedance_2_0_mini`, 480p)
  from the facing's green-screen still, used as both start and end frame, with
  a "one sword slash in place, camera locked, flat green background" prompt.
  `tools/make_attack_strip.py` keys the green,
  matches scale and position to the idle frame, and packs the chosen frames.
- **Enemies:** one `nano_banana_2` image each on flat green, keyed with
  `tools/key_sprite.py`.
