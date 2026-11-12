# Paired town services — current implementation handoff

November 11, 2026 (user-local release date). This revision continues the right-side inventory work with a paired stash or merchant on the left. The prior Inventory source and delivery are preserved separately.

## Visible behavior

Interact with the stash or quartermaster using E nearby. The appropriate service opens on the left; the real equipment/character pane and backpack stay on the right. Item cards sit between the panes. Closing either × or pressing Escape with no text field focused closes both panes and restores the previous pause lifecycle. Equipment/Character tabs remain available during a service. Successful transactions keep the current service, tab and search text open.

The original Higgsfield stone/bronze backplate is reused consistently. No additional generation or paid media job was needed. All labels, rows, filters, item art, stats, prices and buttons are live controls. There is no rendered mock inventory under the interaction layer.

The backpack and stash each retain the existing 10×6/60-cell geometry. Occupied counts include dimmed items. Equipment still has ten actual slots with the inherited class/level/handedness rules. The equipped character and current resources remain visible while shopping. Opening a service follows the existing proximity interaction; combat, death and protected saves reject service transactions.

## Stash controls

- Click a bag or stash item to pin its inspection/comparison card. A stash card offers Withdraw; an owned bag card offers Deposit as well as normal equipment actions.
- Ctrl-click a backpack item to deposit it, or a stash item to withdraw it. Right-clicking a stash item also withdraws it. Right-clicking a backpack item retains quick-equip behavior.
- Drag between grids to choose exact destination cells. The source container and UID are carried with the drag. Full footprints, overlaps, negative coordinates and stale tokens are rejected. Dragging within either grid changes only placement.
- Deposit matching backpack items moves the complete current backpack search selection. The operation is all-or-nothing: if any selected item cannot be placed, nothing moves. Equipped items are not included.
- Search stash supports case-insensitive words across item names/types. Category filters cover weapons/offhands, armour, jewellery/belts, and recognized uniques. All typed words must match. These filters dim non-matching items; they do not repack them or free their cells.

The two searches are independent. The right search selects which backpack items a matching batch deposit uses. The left search/category affects stash visibility. Clear a search to reach dimmed items again. A dimmed item still blocks an overlapping drop, avoiding hidden ownership or unexpected item movement.

## Merchant controls and economy

For Sale lists actual persisted stock. Click an item's name/art to compare it without buying; use its explicit Buy button to purchase. The card also offers a Buy action. Comparison checks the hypothetical equipment layout and current stat modifiers, without changing ownership or claiming that a purchase equips the item. Buying gear above your level or from another class remains possible; the comparison explains equipment restrictions.

A stock purchase costs three times the item's sale value. Sale and buyback value is the item's integer value clamped to 1–100,000. Current gold, stock UID and destination space are checked at commit. Poor funds or a full bag consume neither gold nor stock. Repeating a stale purchase cannot buy or charge the same item twice.

Click a backpack item and use Sell, or Ctrl-click it to sell quickly. The same UID moves into Buyback and its sale value is granted once. A sale that would exceed the existing 999,999,999 gold cap is rejected before removing the item. Equipped gear must first be unequipped into the backpack. Buying, selling and storing items do not refill health/mana or alter equipped gear.

Buyback holds the newest twelve sales in order, with newest shown first. Buying one back charges exactly the gold received and restores the same UID; there is no sell/buyback profit. The oldest recovery record is evicted on a thirteenth sale; the UI explicitly labels this twelve-item capacity. Undo last sale buys back the latest remaining record through the same checks. Insufficient funds or a full bag preserve that record and currency. Buyback survives normal save/load, quitting and the independent F7 lab round-trip.

Buy health potion purchases one potion for five gold, up to the existing five-potion cap. It does not drink it. Full stacks and insufficient gold are not charged. The right-side potion count updates after purchase; Q in the world still consumes a potion through the original combat logic.

## Text, hover and feedback

Ctrl-F focuses backpack search. While a LineEdit has focus, I/C/K/B/M/T and other ordinary typing are left to the text field instead of invoking global shortcuts. The first Escape releases text focus; the next closes the paired service. Search clear buttons remain available.

Hover previews remain separate from click-pinned cards. Service and bag hover cleanup does not change the selected ownership candidate. Failed operations show a reason in the live service notice and right-side status band. Successful operations name the moved/bought/sold item. The status band supports two lines. Background hotbar hover tooltips are suppressed while a modal is open, avoiding unrelated spell tooltips behind the service screen.

## Transaction and code contracts

`town_actions.gd` is the pure planner. It duplicates the supplied state and returns either `{ok:false, reason}` or `{ok:true, reason, state}`. Its state contains inventory, stash, stock, buyback, gold and potions. UID lookup is authoritative; index-only or stale drag data cannot commit an item transfer. Exact cell placement and automatic first-fit placement are distinct, so an explicit negative cell cannot silently become auto-place.

Supported actions are deposit, withdraw, deposit_matching, buy, sell, buyback and potion. The planner never calls save, plays sound or mutates an actor. `hud.town_action` checks the current service context, living actor, combat and write-protection state, commits the successful complete snapshot, invokes the existing sound/save path and refreshes the same UI context. This is atomic logical ownership/currency planning. Disk persistence uses the inherited atomic tmp/bak save writer; it is not a remote transaction/database service.

`player.preview_equipment` supplies a pure hypothetical equipment candidate for unowned stock/stash comparisons. `plan_equip` reuses it and additionally ensures displaced gear can fit the owned backpack. Actual equipment commits retain the existing Aura cancellation and resource-clamp rules. Transferring or buying unequipped items does not cancel a valid equipped Aura snapshot.

| File | Responsibility |
|---|---|
| scripts/town_actions.gd | Pure matching, UID lookup, prices and complete transfer/currency plans |
| scripts/service_panel.gd | Left stash/shop frame, stash grid/search/category, stock/buyback lists and notices |
| scripts/inventory_panel.gd | Right equipment/character/bag, query field, paired-frame layout and shared item card |
| scripts/hud.gd | Context gates, commit/refresh, shortcut focus handling, source-aware bag grid and card actions |
| scripts/player.gd | Pure hypothetical gear candidate and owned equip planning |
| scripts/main.gd | Schema-five serialization, buyback validation/restoration and pre-upgrade snapshot |
| scripts/legacy_hud.gd | Suppress background hotbar hover during modals |
| tests/town_ui_integration.gd | 69 headless / 71 rendered focused checks and real captures |

## Save upgrade and rollback

The established custom user namespace remains `AgeOfTheLost_Crownsfall_EncounterSlice`. The filename remains `crownsfall_encounter_v4.json` for continuity; its name is legacy, and the current record's schema is 5. Current health/mana, cooldowns, gear, bag/stash coordinates, ranks, unique attunement, merchant stock and encounter counter retain their previous meanings. The new field is `buyback_stock`, an array of at most twelve normal validated item records.

The loader accepts schemas 2, 3, 4 and 5. Earlier schemas start with empty buyback; unknown extra legacy fields cannot grant recovery records. Schema-five records require a correctly typed buyback array and reject over-capacity history, malformed items and duplicate UIDs across gear, inventory, stash, merchant stock and buyback. JSON numeric ranks normalize back to integers as before. Future versions above 5 remain write-protected.

Before writing over a valid earlier-schema primary file for the first time, the saver copies its exact bytes once to `crownsfall_encounter_v4.json.pre-v5`. Later saves do not replace this snapshot. The ordinary rolling `.bak` remains independent. If the pre-upgrade copy cannot be made, that upgrade write stops and preserves the primary. Existing schema-four builds see schema 5 as a future version and protect it rather than deleting buyback records on save.

For a rollback, close the game and preserve the current primary, .bak and .pre-v5 files. Use an isolated project/user namespace and copy the desired compatible snapshot there. The pre-v5 file is the first preserved older checkpoint; it does not include later progress. Do not simply run an older writer against newer progress and expect buyback to be preserved. No user progress was used during QA; all tests operate isolated temporary XDG directories.

## Validation and measured limits

The complete Linux runner passes 434 headless assertions across nine suites: the inherited 365 and 69 Town checks. Rendered Inventory passes 50 and rendered Town passes 71. Four native mouse checks are additional to the headless count, making 438 distinct assertions overall. Counts overlap across headless/rendered modes and should not be summed indiscriminately.

Town coverage includes pure planning and UID conservation, exact cross-grid placement, Ctrl-click, full-destination and batch rollback, dim/categorical matching, text-focus shortcuts, merchant comparison/purchase, stale callbacks, poor funds, sale/buyback prices and capacity, gold/potion caps, dead/combat/protected-save gates, saved buyback validation, schema-four import, exact one-time upgrade snapshot, real F7/buyback round-trip, preserved tabs, empty states and resized layouts. Native rendered tests move/release the actual pointer across the paired grids and verify that the successful drop survives rebuilding the UI.

Run `python3 tools/run_checks.py --report-dir /tmp/aotl-qa` on Linux. For actual Town captures, run Godot with a display and isolated user data: `godot --path . --audio-driver Dummy --script res://tests/town_ui_integration.gd`. Captures are written under `previews/town`. The default source ZIP must also pass after fresh extraction before delivery. Original canon/rig hashes remain verified. No Windows executable, controller coverage, target-hardware performance or human-usability claim is made.

Next useful work is human review with long names and full containers, controller/focus navigation, accessibility scaling, and economy tuning against real progression. Broader actor animation, equipment appearance and production 3D remain independent backlog items. The included F7 scene is still the preserved proxy lab.
