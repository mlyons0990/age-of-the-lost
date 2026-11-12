# Current integration notice

This historical focus patch is now merged and tested in the Reliability revision. Two GDScript inference errors were fixed, the armour tooltip corrected, and search focus guarded against controller equip. Eleven headless suites pass 553 assertions; rendered Inventory/Town add four native pointer checks (557 distinct). Navigation adds 36 engine assertions. Read `RELIABILITY_HANDOFF.md` and current result logs for release claims. Statements below about unavailable Godot describe the original authoring environment, not this tested release.

---

# Right-dock focus, comparison and statistics polish

## Source of truth

This revision is made from the **Town UI** release, which already includes the Cantor encounter, real right-docked inventory, left-side stash and merchant, saved twelve-item buyback, schema-5 save compatibility, original AOTL stone/bronze artwork, and independent F7 rig lab. The previous Reference Alignment and F8 Bridge variants are **separate branches** and have not been silently merged. This prevents reverting a tested save schema or losing buyback ownership state.

The user's five Path of Exile reference images inform overall hierarchy: symmetric paper-doll slots on top, real Tetris-like item grid beneath, readable character stat grouping and inspector positioned to the side. AOTL art remains original.

## Implementation changes

### Navigation

`scripts/inventory_panel.gd` now holds ephemeral `keyboard_mode` and `focus_cell` state. The cursor clamps to the authoritative `Systems.WIDTH` and `Systems.HEIGHT` constants. It never changes inventory ownership, bag coordinates or a save field. Moving a cursor clears stale pinned item details. Inspect uses the same `BagGrid.index_at` hit test as clicking the real item. Quick-equip calls the existing `HUD._equip` transaction path, not a second state writer.

`scripts/hud.gd` routes arrow/Enter/Tab while a paired inventory UI is active. D-pad/A/X/B/LB/RB are handled through the same focus methods, and modal inputs are consumed. In search-field focus, keyboard arrows/text do **not** control the bag and Escape releases focus before closing. A pointer click on the bag returns to mouse mode. On successful transactions, the UI refresh preserves the cursor coordinate and focus state.

This is a **first controller pass**, not comprehensive controller UX: left-side service tabs, merchant stock, buyback, pinned-card action buttons, stash selection and tooltip scrolling still need full controller focus paths and visual affordances. Thumbstick navigation, remapping and platform-specific button glyphs are not implemented.

### Character tab

`InventoryPanel.build_stats()` calls the existing `SYS.derive(level, {}, modifiers, class_id)` with no equipment to obtain the player's genuine base attributes. It compares that output with `player.stats()` for equipped totals, showing decimal precision (necessary for Mage Dexterity growth), gear deltas, offense, critical chance, cooldown reduction, armor, HP/MP maxima and mana regeneration. Resistances, evasion and Energy Shield are **not yet implemented** and are labeled accordingly. No mock values or new stat formulas are introduced.

The new `ResourceMeter` draws directly from actual player current HP/MP and derived maxima, clamped to nonnegative available amounts. Bars are visual only. Existing health potions are a real resource, not decorative faux flasks.

### Item inspection

For a legal equip plan, the inspector enumerates the current gear slots that would change when `plan.gear` becomes active. If a staff displaces a focus, the item name appears in a clearly labeled `Moves to backpack` line. The preview is still pure; only the existing explicit equip action can mutate ownership and gameplay stats. Both rings and the backpack-fit rejection remain authoritative in the baseline.

### Art/identity

The original Higgsfield stone/bronze panel remains. Custom typography is restrained: narrow gold headings, high-contrast readable cream body text and distinct amber gear displacement warnings. The six canonical concept images are preserved, unaltered. The screenshot references are not packaged as game assets.

## Changed files

- `scripts/inventory_panel.gd`: focus methods, real resource bars, stat groups and base/equipment deltas
- `scripts/hud.gd`: keyboard/controller routing, comparison displaced-item labels, focus persistence and pointer-mode release
- `tests/inventory_ui_integration.gd`: pending runtime assertions for real input focus and stat labels
- `tools/verify_ui_navigation.py`: **source-only** and geometry checks, 50/50 passing
- `tests/UI_NAVIGATION_STATIC_RESULT.json`: machine-readable static report
- This document and `00_START_HERE_RightDock_Focus_Polish.md`

## Run acceptance / blockers

The patched source was not run inside Godot: its binary was absent from the environment and network access to the official distribution was unavailable. All new Godot tests and rendered verification remain pending. The baseline's 438 assertions do not certify this new branch. Do not call this production-ready or Windows-validated.

Manual acceptance steps:

1. Godot 4.6.3 import with no GDScript parser errors and no missing resources.
2. Test I/C/Escape, Tab, arrow navigation, Enter and Shift+Enter, LB/RB/D-pad/A/X/B, text search focus, clicking and dragging.
3. Test Mage + Warrior; check 10 equipment slots, 10x6 bag, staff/offhand displacement, both rings, full backpack rollbacks, inventory/stash/merchant/buyback, and character stat deltas.
4. Run the full isolated baseline test runner. In a rendered display, rerun the inventory and town UI integration tests and capture new screenshots; compare against existing `previews/inventory/` and `previews/town/` baseline captures.
5. Perform a human typography/legibility pass at 960x720, 1280x720, 1440x810, 1920x1080 and ultrawide with long names and full inventories.
6. After those gates pass, add full focus navigation for service panels, gear slots and item-card buttons, plus accessibility scaling, user-customizable bindings, and controlled runtime performance tests.

## Old and new claims

Historical Town UI release evidence: 434 unique headless checks plus four additional native mouse checks, full rendered screenshots. **Current candidate evidence:** 50 static/geometry checks, no new engine execution.
