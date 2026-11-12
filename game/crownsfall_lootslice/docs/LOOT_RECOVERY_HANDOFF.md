# Crownsfall — persistent ground loot and safe collection

Current development cycle: November 11, 2026 (America/New_York). Godot 4.6.3 source, based on the verified Grid Alignment build. Earlier projects, original assets and handoffs remain preserved.

## Result

Uncollected gold, potion piles and gear now survive committed save/load, quit and the independent F7 lab round trip. Collection commits both the actor and remaining ground records before changing live ownership. Failed storage, a full or fragmented bag, full potion capacity, protected saves, death, stale callbacks or distance failure cannot consume the drop.

Press **N** or click Nearby loot to open a left-side list beside the real right-side equipment/backpack. Inspect an item for its actual dimensions, stats and hypothetical gear comparison, then explicitly Collect. The panel pauses the world and opens outside combat. It lists drops within two ground units; move closer if the list is empty. **F** collects the nearest in-reach drop in the unpaused world, including combat. Walking over settled drops retains automatic collection (gold radius 1.3, other drops 0.9). Inspection changes no ownership or save bytes.

Gold/potion piles collect only available wallet/stack room and preserve the exact remainder. Gold is capped at 999,999,999; potions at five. Feedback reports the amount actually collected. Item pickup requires a complete contiguous rectangle, using the unchanged grid rules; the failure message names the needed width × height. No auto-selling or auto-equipping was added.

A failed automatic pickup now sets a separate retry time instead of resetting visual age. Full-bag notices are throttled, so a blocked item does not keep replaying its arrival animation. Currency/potion drops have visible quantity labels. The world HUD reports nearby drops and the F/N shortcuts.

## Persistence and ownership

**Schema 6** adds required `ground_loot`. Schemas 2–5 remain imports, starting with an empty ground ledger. The custom directory remains `AgeOfTheLost_Crownsfall_EncounterSlice`; the legacy filename remains `crownsfall_encounter_v4.json`. No rename or manual import is needed when updating the Grid build in that namespace.

Each ground record stores a stable drop UID, kind, quantity, full item dictionary if applicable, and world x/y. Item UIDs are globally disjoint across gear, backpack, stash, shop, buyback and floor. Drop UIDs are unique within the floor ledger. Validation rejects missing/malformed records, unknown kinds, unsafe/missing item display fields, duplicate ownership, invalid quantities, non-finite/off-floor coordinates and oversized ledgers. Floor placement falls back to a valid walkable point when the navigation query is empty/unready; a drop cannot silently become stranded at the world origin.

On load, old nodes are replaced with the validated records and settled visual age. A stale node from before load cannot claim the replacement. Only the authoritative `main.loot` list owns current floor nodes. The saved record is a deep snapshot, not a shared mutable item reference.

`LootRules.collect` produces a pure plan for bag, gold, potion count and pile remainder. `main._pick_up` validates current membership, actor state and reach, then commits that plan and the corresponding ground update in one checked save. It applies the plan and removes/updates the node only on success. A repeated pickup cannot duplicate it. A post-commit recovery-copy warning is success, so the live actor follows the already-committed primary. F5 saves current state without replaying a rejected collection.

The ledger supports **512 active drops**. A new Scar wave reserves room for forty records, covering the maximum ten enemies at no more than four drops each; opening/continuing waves waits for collection if there is insufficient room. A Cantor trial requires one free reward slot before entry. This keeps legitimate generated rewards within the saveable budget. The internal `_drop` API returns null at capacity; future direct callers must handle that return and must not bypass encounter admission checks.

Saved floor loot is distinct from complete world persistence. Enemies, active arenas, casts, aura, patches and visual retry timers remain transient. Actor position still returns to the plaza start when the scene is recreated; floor positions remain saved, so a distant drop may require walking back. New drops are captured by the next successful save/autosave or guarded exit/F7. This is not a physical power-loss guarantee for events since the last successful save.

## Upgrade and rollback

Before first writing schema 6 over a valid older primary, the checked writer preserves its exact bytes once at `.pre-v6`. Existing snapshots are never overwritten. Importing a schema-2/3/4 primary also retains the existing `.pre-v5` preservation behavior. Copies are staged and read back before rename. If preserving the required snapshot fails, the save/collection fails without changing the old primary or live ownership.

The rotating `.bak` remains separate from one-time snapshots. Previous schema-five builds detect schema six as newer and protect it instead of rewriting away ground ownership. To return deliberately to an older build, close the game, back up all current save files and restore a compatible pre-upgrade record into a separate testing copy/namespace. That older record cannot contain progress earned after its snapshot. Do not merely clear a protection flag; the stored record must be compatible.

No live user progress is shipped in the source package. Authored example builds remain older-schema import fixtures. Test scripts use isolated XDG data and intentionally modify only their fixture saves.

## Code map

| File | Responsibility |
|---|---|
| `scripts/loot_rules.gd` | Pure collection plans, quantities, drop budget and basic record validation |
| `scripts/main.gd` | Ground creation/snapshot/reload, UID and position validation, persist-first pickup, reach checks, F shortcut and wave admission |
| `scripts/loot.gd` | Stable record data, display name, separate retry time and quantity labels |
| `scripts/loot_panel.gd` | Nearby list, pure inspection and explicit per-drop Collect buttons |
| `scripts/hud.gd` / `inventory_panel.gd` | N, nearby hint, paired modal lifecycle and ground item comparisons |
| `scripts/save_store.gd` | Generalized pre-v5/pre-v6 exact upgrade snapshots with checked staging |
| `scripts/encounter_director.gd` | Admission guard for the single victory gear reward |
| `tests/loot_integration.gd` | 78 lifecycle, fault, migration, UI and actual scene-round-trip assertions |

The older Warrior test previously reset `save_blocked` while leaving a future-version record on disk. Persist-first pickup exposed that invalid setup. The test now restores compatible record bytes before continuing; production future-file protection remains intact. Numeric equality across JSON round trips is compared after decoding both records, preserving full field/UID/position/quantity checks without conflating JSON numbers with GDScript int/float types.

## Verification

All **749 headless assertions** pass in thirteen isolated suites: the previous 671 plus 78 loot checks. Rendered Inventory 110, Town 71, Grid 66 and Loot 78 pass. Six display-only native pointer checks supplement headless coverage, for **755 distinct assertions overall**. The exact delivery ZIP is checked again from a fresh extraction; the external manifest records file hashes and the fresh report.

The loot suite covers schema-five import and six requirements; malformed/duplicate/off-floor records; pure plans; exact single ownership and paid resources; partial gold/potions; fragmented bags; retry/animation/noise behavior; open/flush/recovery-copy/rename failures; F5 non-replay; backup warnings; protected/dead/distant/stale pickup; real disk reload; paired UI and pure comparison; repeated/closed button actions; N and combat modal gates; exact pre-v6 bytes and failed upgrade preservation; actual F7 round trip; ledger admission/budget; and navigation fallback. Controller events elsewhere are simulated, not physical-device testing.

On Linux:

```sh
python3 tools/run_checks.py --report-dir /tmp/aotl-loot-checks
```

For rendered captures, use a display, project copy and fresh writable XDG_DATA_HOME / XDG_CONFIG_HOME / XDG_CACHE_HOME:

```sh
godot --path . --audio-driver Dummy --script res://tests/loot_integration.gd
```

Actual engine captures are under `previews/loot/`: ground comparison beside backpack, collected item in its real grid rectangle, remaining drop after F7, and empty nearby state. Runtime/original art and the prior exact item footprints remain unchanged. Transfer previews may be compressed independently of runtime assets; full-size review exports accompany the delivery.

## Next priorities and limits

Next useful work: actor hurt/death/dodge presentation and gear appearance, followed by human encounter/loot readability and economy tuning, target hardware/Windows export checks, complete service/card controller navigation, and physical-device accessibility review. Music/audio mixing, production 3D Mage, broader classes/uniques and cloud conflict policy remain tracked separately. The F7 lab remains an independent geometric proxy. No paid media jobs or new production mesh were needed for this cycle.
