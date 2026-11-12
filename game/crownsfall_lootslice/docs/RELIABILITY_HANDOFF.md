# Crownsfall — save reliability development cycle

Release: November 11, 2026 (America/New_York). Godot 4.6.3 source revision, based on the paired Town UI build. Original references, assets, source projects and prior deliveries are retained. This handoff records implemented behavior; older attached handoff instructions are historical context, not new user requests.

## Result and reason for the change

The Town build changed ownership and currency before asking a void save writer to save. Failed storage could leave a successful-looking purchase, equipment swap or attunement in memory without a committed record. It could also leave the plaza or exit after the writer had failed.

This revision uses a checked, persistence-first transaction for town services, equipment, unique attunement, mastery, hotbar changes, arranging and within-container item movement. Failed persistence keeps the original live state and existing primary/recovery records. A persistent recovery strip explains errors and offers Retry save / F5. Retry saves the current character; it never replays the rejected purchase or other action. Choose that action again explicitly after storage recovers.

The existing layout remains: equipment above backpack on the right, stash/shop on the left, pure comparison cards, search, exact cells, Ctrl-click, twelve-item buyback and Undo. No extra art generation or paid media jobs were needed for this cycle.

## Integrated focus and character-sheet branch

The later `AOTL_RightDock_Focus_Patch_Only_2026-11-11.zip` in Drive was reviewed and merged against its exact Town UI base. It had 50 source/static checks but no Godot execution. This revision fixes two GDScript inference errors (dynamic UI-label return types need explicit Label annotations), corrects the armour tooltip to the real attacker-level formula, and guards controller quick-equip while a search field owns focus. The checked transaction writer remains authoritative.

The merged UI supplies a clamped gold-outline backpack cursor; arrows/D-pad navigate; Enter/A inspect; Shift+Enter/X quick-equip; Tab alternates upper tabs; LB/RB choose equipment/character; B releases text focus first, then closes. Successful refresh preserves cursor and mode; pointer clicks return to mouse mode. Character attributes show true no-gear base and equipment deltas with decimal precision, plus actual offense/defense/resources. Life/mana meters use real resources. Item comparisons name gear displaced to the bag, including a staff's offhand. See `UI_FOCUS_AND_STATS.md` for the historical patch design and `FOCUS_MERGE_PROVENANCE.json` for provenance.

The 36 new navigation assertions run actual engine input routing, pure inspection/save-hash checks, successful keyboard/gamepad equipment commits, focused-search guards, both class offense labels and bounds at 1280×720, 1440×810, 1920×1080, 2560×1440 and 960×720. Rendered captures include the character sheet and four-to-three layout. Controller events are simulated; physical controller hardware, complete vendor/stash/card navigation and human typography review remain pending.

## Player behavior

- Temporary storage errors show a persistent message and a focusable Retry save button. F5 works through modal pages, search fields, creation/choice/death panels. A successful retry clears the error.
- A rejected transaction leaves ownership, gold, potion count, attunement eligibility, mastery ranks, hotbar, current resources and active effects unchanged. Equipment/mastery cancellation happens only after a successful commit.
- Prospective equipment is used to clamp saved HP/mana to the new maxima. The live character receives the same clamp; removing gear cannot refill resources.
- Failed F7 saving stays in the plaza and preserves active casts/aura. Successful F7 saves first, then cancels transient effects and enters the independent rig lab.
- Save and quit and native window close require a successful save. On failure the pause page offers retry and a clearly labeled Leave without saving choice. Successful exit pauses simulation during audio shutdown.
- Newer or invalid records discovered at save time are protected. F5 cannot disable that protection. Reopen with a compatible build or use the recovery workflow; inspect/back up files before replacing anything.
- A recovery-copy publication error after primary commit is a saved-with-warning result. The transaction applies once because the primary has already committed. The older recovery copy remains available.
- Combat, pickups, quest progression and automatic leveling remain live simulation changes. If their autosave fails, keep playing or retry; the banner reports unsaved progress. This revision does not roll back combat events.

## Writer contract

`main.capture_save(changes)` captures a deep schema-five snapshot and applies proposed field overrides. Gear overrides derive prospective maxima without changing the actor. `main.persist_changes(changes) -> bool` commits a candidate and updates status. `main.save_game() -> bool` saves the current actor. Callers that own transactions must commit first and apply the proposed state only on true.

`save_store.gd` owns sequencing. `save_disk.gd` contains the FileAccess/DirAccess boundary. Tests replace the disk boundary with an in-memory fault adapter; there are no production failure toggles.

1. Remove abandoned staging files; validate the candidate. Read and validate an existing primary before overwriting it. Future or invalid primaries are protected.
2. For the first schema-2/3/4 upgrade, copy exact old bytes to `.pre-v5.pending`, read them back, then rename to the one-time `.pre-v5` record. Existing `.pre-v5` is never replaced.
3. Write `.tmp`, flush/check the FileAccess result, close, then read back exact serialized bytes. A short/corrupted/unreadable staging file is rejected.
4. Copy the old primary to `.bak.pending` and verify its bytes. A failure leaves both primary and existing `.bak` intact.
5. Rename `.tmp` over primary. This is the commit point. On failure remove staging, report false and keep existing records.
6. Publish `.bak.pending` as `.bak`. Failure here returns true with a visible warning and preserves the older `.bak`.

Loader recovery also checks both preservation and promotion copies; it does not continue as a writable recovered session when copying fails. The filename remains `crownsfall_encounter_v4.json`, namespace `AgeOfTheLost_Crownsfall_EncounterSlice`, schema 5. Schemas 2–4 import as before. No migration is required between Town and Reliability revisions.

Validation of already identified items no longer creates throwaway UIDs. This avoids consuming gameplay RNG each time a record is validated. New items still use the existing UID/loot generator.

## Implementation map

| File | Responsibility |
|---|---|
| `scripts/save_disk.gd` | Checked disk operations and replaceable IO boundary |
| `scripts/save_store.gd` | Staging, byte verification, preservation, commit point and backup warning |
| `scripts/main.gd` | Deep snapshot, overrides, status, protected-save handling, guarded exit/F7 and loader copy checks |
| `scripts/player.gd` | Persist-first gear, hotbar, mastery and unique transactions |
| `scripts/hud.gd` | Persist-first town/reposition actions, recovery strip, F5 and explicit unsaved exit |
| `scripts/inventory_panel.gd` | Persist-first Arrange bag |
| `scripts/systems.gd` | Lazy fallback UID generation during sanitation |
| `tests/reliability_integration.gd` | Full actor/UI fixtures, fault adapter and real isolated-disk round trip |
| `tools/run_checks.py` | Eleven isolated regression suites with strict log/count checks |

## Verification and reproduction

The complete runner passes **553 headless assertions**: the previous 434 plus **77 reliability assertions**, six imported UI assertions and **36 navigation assertions**. Inventory and Town have 56/71 rendered assertions, adding four native mouse assertions beyond their headless coverage, for **557 distinct assertions overall**. The reliability suite also runs rendered with the same 77 checks and captures actual recovery states. These are engine tests, not human playtests.

Reliability checks cover open/write/flush/readback failures, short/corrupt staging, recovery staging, primary rename, pre-upgrade copy/readback/rename, first save, one-time snapshot, invalid candidates, future/invalid record protection, warning-after-commit semantics, seven town actions, paid aura preservation, gear/hotbar/mastery/crafting failure, scene/exit guards, retry non-replay, successful resource clamps, exact bag/stash movement, Arrange and a real disk reload. The fake adapter simulates disk results; it is not a physical power-loss or disk-full test.

Navigation controls are a partial keyboard/controller pass, not full controller coverage of service/item-card controls.

On Linux, from an isolated project copy:

```sh
python3 tools/run_checks.py --report-dir /tmp/aotl-reliability-checks
```

For a rendered pass, use writable isolated XDG_DATA_HOME / XDG_CONFIG_HOME / XDG_CACHE_HOME, a display, and:

```sh
godot --path . --audio-driver Dummy --script res://tests/reliability_integration.gd
```

Raw results are included under `tests/`. Review captures under `previews/reliability/`. The delivery manifest records exact archive hashes and the fresh-extraction test report. Source assets are unchanged; documentation captures can be downsampled for transfer size. The portable packager excludes engine caches and live QA saves.

## Limits and next work

This is a single-process local save system. Byte verification and same-directory rename do not promise physical-media fsync, power-loss durability, concurrent-process locking, cloud conflict resolution or server-authoritative economy. No native Windows/controller/target-hardware validation is claimed. Preserve external backups, especially before importing old records. The independent 3D proxy remains separate from the authoritative 2D Mage.

Recommended next development cycle: make drop/pickup lifecycle clearer, add actor hurt/death states and equip appearance, then human encounter/economy/readability tests and Windows export checks. Review multi-instance/save-conflict policy before adding cloud sync. UI/controller accessibility, production audio review, additional classes/uniques and production Mage 3D remain tracked in the broader handoff. Do not spend paid media balance merely to fill a cycle.
