# Right-docked inventory and character screen

November 11, 2026. Implemented Godot UI revision, built on the complete Encounter/Mastery source. The prior Encounter source and Drive delivery are preserved. This is a working game screen, with real item ownership and stat calculations.

## Visual comparison and resulting layout

The requested Path of Exile 1/2 comparison was performed using these actual screenshots:

- [Path of Exile 1 equipment screenshot](https://cdn.mmogah.com/Public/news/brutal_exsanguinate_build_elementalist_witch_gear.jpg), from the [Elementalist equipment article](https://www.mmogah.com/news/poe/poe-builds-3-14-brutal-exsanguinate-build-elementalist-witch).
- [Path of Exile 2 character and inventory screenshot](https://staticg.sportskeeda.com/editor/2024/12/6c837-17343630548075-1920.jpg), from the [character movement/stat guide](https://www.sportskeeda.com/mmo/path-exile-2-increase-movement-speed-faster).
- [PoE2 equipment reference page](https://www.poe2wiki.net/wiki/Equipment) supplied an additional inventory-layout reference.

The main visual pattern is now implemented: a narrow right-side slab, equipment arranged around the body slot, weapons flanking it, and a dense inventory grid underneath. Carved charcoal stone, antique bronze edging, a crown relief and two original hooded crow-knight reliefs establish a gothic frame. The world stays visible beside the panel. The new art is an original Higgsfield backplate; no Path of Exile screenshot or game asset is shipped as runtime art.

The combined Inventory/Character interface occupies the right side. Equipment is the default upper tab. Character replaces that upper section with six attributes and supported derived statistics, while the backpack stays below it. The separate character tab follows the user's requested right-side placement. Crownsfall retains its established 10×6/60-cell footprint geometry and save coordinates. This revision is a visual/interaction overhaul with save compatibility, not a new socket/flask/cosmetic system.

## Controls and working interactions

| Input | Result |
|---|---|
| I | Open equipment; return from Character to Equipment; close if already on Equipment |
| C | Open Character; switch Equipment to Character; close if already on Character |
| Escape or × | Close the panel |
| Equipment / Character tabs | Switch the upper section; backpack remains accessible |
| Hover backpack item | Preview an unselected comparison card beside the panel |
| Click backpack item | Pin its comparison and equip actions |
| Right-click / double-click backpack item | Quick-equip into its default legal slot |
| Drag backpack item | Reposition by its true footprint, preserving the grabbed cell |
| Drag backpack item onto equipment | Equip through the shared transaction and hand/class/level rules |
| Click an equipment slot with a selected bag item | Try equipping that selected item into the slot |
| Click equipped item with no bag selection | Inspect its actual equipped card and unequip action |
| Right-click / Ctrl-click equipped item | Unequip if the backpack can hold it |
| Drag equipped item into backpack | Unequip into the exact legal destination cell |
| Arrange bag | Run existing atomic pack/sort; preserve original layout on failure |
| Health-potion strip | Explain that Q in the world consumes the real potion resource |

Click the item first to keep its card open when moving the pointer to its buttons. Hover alone deliberately does not select a candidate for equipping. The card is beside the dock, leaving the grid/equipment visible. Bag hover uses this custom card; other town grids retain their existing tooltip behavior. Stash and merchant now use the paired service-left/inventory-right workflow described in `TOWN_UI_HANDOFF.md`; Grimoire and other full modals retain their layouts.

Opening either tab clears path, target and held attack intent. The existing modal rule pauses the world/encounter. A transparent input shield prevents clicks through to the terrain without darkening the whole screen. Closing releases the same pause state. Town/encounter gates, trial rewards, mastery, sounds, save protection and the independent F7 lab remain operational.

## Live equipment and stats

Ten real slots are displayed: main hand, off hand, head, body, gloves, belt, boots, amulet and two rings. Helmet is above torso; tall hands flank it; jewellery sits beside it; gloves, belt and boots are lower. Original item art supplies filled slots; faint class-appropriate icons mark empty slots. A two-handed staff visibly blocks the offhand. Staff/wand art is rotated and sized only while drawing the hand slot, using the retained original icon.

The bottom grid displays real item footprints, rarity borders, occupied cells and gold. While dragging, the candidate footprint has a green or red placement preview. Negative positions, overflow, overlaps and stale identity tokens are rejected. Incoming drag indices must be integers. Equipment drags carry their source slot and UID; bag drags carry their index, UID and grabbed-cell offset.

The Character tab reads `player.stats()` and shows Strength, Dexterity, Vitality, Intelligence, Wisdom, Charisma, maximum life/mana, natural mana regeneration, class-appropriate power, critical chance, armour and cooldown reduction. No unimplemented resistances/evasion/energy-shield values are invented. Current HP/MP and maxima appear in the common strip. Long content can scroll inside the character section; all six attributes are visible together.

Comparison cards use the full actual equip plan, including staff displacement of an offhand. Power/life/mana/armour/crit changes derive from that candidate gear snapshot and current path modifiers. Ring cards offer both real ring slots. Class, level, handedness or bag-room failures disable the action and explain why. Equipped unique text describes the existing Emberwake effect. The UI does not apply a preview to the actor or refill resources.

## Transaction contracts

`player.plan_equip(index, slot)` is pure: it checks identity/index/slot/class/level, duplicates the bag/gear, inserts displaced items, handles staff offhand removal and validates the final equipment layout. It returns `{ok, reason, inventory, gear}` on success, or `{ok:false, reason}`. Comparison, slot drop validation and `equip_item` use this same plan. This avoids previews promising a swap that actual gear rules reject.

`equip_item` commits the successful plan once, stops the old aura snapshot, clamps existing resources, plays the existing cue and saves. Failure mutates nothing. UID ownership is retained across copies.

`unequip_item(slot, at=Vector2i(-1,-1))` preserves the old auto-place call. The optional explicit cell enables gear-to-bag drag. It plans in a duplicate bag; an occupied/out-of-bounds destination or no room returns false before changing either container. A valid commit stops Aura, transfers the same UID, clamps existing resources, plays the existing cue and saves.

Ordinary bag repositions update the same item coordinates after `Systems.fits` accepts the full footprint. They do not equip, sell or change stats. Quick-equip and card buttons share `equip_item`; right-click and explicit-cell unequip share `unequip_item`. There is no temporary cursor-owned item or hidden overflow container.

## Code and art seams

| File | Responsibility |
|---|---|
| `scripts/inventory_panel.gd` | Dock sizing/anchoring, original frame, equipment controls, character tab, hover/pin lifecycle, item-card placement and native equipment drag |
| `scripts/hud.gd` | I/C/Escape routing, modal lifecycle, custom item details, existing generic bag grid and configurable cell size, quick-equip and bag drop |
| `scripts/player.gd` | Pure equip plan, equip commit, exact-cell/auto-place unequip and inherited resource/cast rules |
| `scripts/systems.gd` | Unchanged logical bag dimensions, footprints, placement, class/hand legality and authoritative derived stats |
| `tools/rebuild_inventory_art.py` | Retained Higgsfield PNG → 680×1020 runtime JPEG, with SHA-256 provenance |
| `data/inventory_art_manifest.json` | Actual prompt, job ID, model, allowance and source/runtime hashes |
| `tests/inventory_ui_integration.gd` | UI/ownership/resize checks and actual rendered captures; native pointer drag when a display is present |

The original 1360×2048 backplate is retained in `assets/higgsfield_sources/inventory_backplate_source.png`; the runtime JPEG is `assets/ui/inventory_backplate.jpg`. Unlimited GPT Image 2.6 job `85ac0717-b195-4cff-be49-f527065e88dd` supplied it. Source and runtime hashes were checked, and rebuilding reproduced the runtime bytes in this environment. Pillow/JPEG encoder differences can affect byte-identical rebuilds elsewhere. The shipped runtime texture is included. A procedural slate/bronze fallback is available if the optional backplate cannot be loaded.

All text, slots, tabs, stats, item cards and inventory cells are live controls/drawing. The generated image contains no baked labels, equipment slots or fake UI. SystemFont prefers Georgia/DejaVu Serif for the title and uses the existing engine font for readable body text; there is no new font-service dependency.

## Compatibility, sizing and validation

The Encounter custom user namespace `AgeOfTheLost_Crownsfall_EncounterSlice`, filename `crownsfall_encounter_v4.json`, 10×6 item positions are deliberately retained. Current saves use schema 5; schemas 2–4 remain importable, and a one-time `.pre-v5` snapshot precedes upgrading. Existing compatible progress loads directly. Testing uses disposable isolated XDG directories, so user progress is not used. No reset is performed. A successful save upgrades older records to schema 5; prior builds protect future schemas. The old Encounter source is a rollback copy.

The logical panel is 680×1020, anchored to the right with a 12-unit edge inset and uniform scale based on available height and width. The item card sits beside it and limits its height with a scroll region. Equipment/character views use the same lower-grid position. Rendered checks cover the normal 16:9 window and a resized 4:3 window. Native Windows, target hardware, controller navigation and human usability remain unvalidated.

The current Linux runner passes 434 assertions across nine suites: inherited 365 plus 69 town UI checks. The rendered UI run passes 50: the same 48 and two additional native pointer-drag assertions. The Town rendered suite passes 71, with two additional native cross-panel drag checks, for 438 distinct assertions overall. Native pointer tests account for viewport stretch through the window's final transform, warp the real mouse and release a native drop. They require a display and are not counted as headless passes.

Run `python3 tools/run_checks.py --report-dir /tmp/aotl-qa`. For actual rendered UI captures, run `godot --path . --audio-driver Dummy --script res://tests/inventory_ui_integration.gd` with a display and isolated user data. Captures are written to `previews/inventory`. `data/.gdignore` retains the existing separation of designer exports/fixtures from resource import. No production scene reads those exported JSON definitions as runtime resources.

## Next useful UI work

1. Human-play the screen at common monitor sizes and with long item names, high attribute values and both classes. Check tooltip/pinned-card discovery and hand-slot art readability.
2. The current Town revision implements paired stash/vendor layouts. Extend the same pattern to additional services after human usability review.
3. Add controller focus/navigation and accessibility scaling using the same authoritative actions.
4. If a future change replaces 10×6 with another grid shape, define an explicit migration and blocked-save/overflow policy first. Do not reinterpret saved coordinates silently.
5. Continue the inherited encounter/economy, additional actor states, target-platform and production 3D backlog independently of this screen.
