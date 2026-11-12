# Current QA and reproduction

On Linux, `python3 tools/run_checks.py --report-dir /tmp/aotl-qa-report` runs import and all sixteen suites in separate disposable XDG directories, checks full logs and writes a JSON summary. This cycle passes **954 headless assertions**. The new actor-feedback suite also passes its 54 checks rendered; repeated assertions are not added to the total. Six extra native inventory/town/grid mouse checks remain historical and were not rerun in this cycle. The runner is intentionally Linux-only; use an isolated project/user directory on other platforms.

Godot 4.6.3 stable on Linux. Rendered runs use X11/Xvfb, software OpenGL and Dummy audio. Tests operate real scripts, UI signals and scene changes; they are not human usability or native Windows validation.

| Suite | Checks |
|---|---:|
| `-- --systems-test` | 52 |
| `-- --mage-test` | 57 |
| `--script res://tests/lab_roundtrip.gd` | 28 |
| `--script res://tests/art_audio_integration.gd` | 19 |
| `--script res://tests/mastery_integration.gd` | 86 |
| `--script res://tests/encounter_integration.gd` | 60 |
| `--script res://tests/encounter_playthrough.gd` | 15 |
| `--script res://tests/inventory_ui_integration.gd` (headless) | 108 |
| `--script res://tests/town_ui_integration.gd` (headless) | 69 |
| `--script res://tests/reliability_integration.gd` | 77 |
| `--script res://tests/navigation_integration.gd` | 36 |
| `--script res://tests/grid_alignment_integration.gd` (headless) | 64 |
| `--script res://tests/loot_integration.gd` | 78 |
| `--script res://tests/selected_art_integration.gd` | 76 |
| `--script res://tests/skill_tiles_integration.gd` | 75 |
| `--script res://tests/actor_feedback_integration.gd` | 54 |
| Total headless assertions | 954 |

Use a project copy and isolated data directories. On Linux set XDG_DATA_HOME, XDG_CONFIG_HOME and XDG_CACHE_HOME to dedicated QA directories outside the source project. On Windows use a separate Custom User Dir Name. Suites intentionally create/alter their QA saves.

First run `godot --headless --path . --editor --quit`. Then run the listed commands with `godot --headless --path .`. For rendered tests, omit headless and pass `--audio-driver Dummy`. Review the whole result log for script errors, failed assertions and leaked playback resources, as well as the final count.

Mastery assertions cover rank/point gates, exclusion, cascading/partial refunds, immutable pulse power, pre-payment and insufficient mana, quarter/restored regeneration, actual radius/cadence, cancellation/death/slot removal, combat-respec rejection, overkill/immunity/rolling recovery, cap preservation across toggles, secondary recursion/overlap/lifetime/cap, unique sanitation/equip/burn extension, atomic crafting, schema-4 round-trip, older import, fractional/future-file protection, final Grimoire assignment scroll reach, and actual mastery/unique/resources/art preservation through F7.

Rebuild exports with `tests/export_mastery_data.gd`. It writes actual definitions and 26 analytic checkpoints, not timing benchmarks. `tests/export_example_builds.gd` intentionally creates QA progress, validates it and writes three labeled fixtures. Their README explains isolated manual use.

Manual gate: create/name both classes; recover memory; compare staff against wand/focus; force full-bag rollback and crafting failure; invest/refund both exclusive branches; test Aura beside/outside targets; toggle at low mana; move it between slots and remove it; apply burns with Solar Writ/Cinderwake; attune/equip the circlet; verify the displayed and observed cadence; save wounded/low-mana/cooling state; enter/return from lab; review all panels at multiple window sizes; test on Windows and target hardware. Native export, signed executable, broad controller/accessibility and production audio listening are not claimed.

Screenshots in previews are real engine captures of controlled fixtures. Sampled GIFs omit audio. Source boards/experiments are labeled separately. The large rejected native GIF is not used by gameplay.

## Cantor encounter verification

The 60 encounter assertions cover actor-radius shape edges, captured aim, minimum warning times, phase reinforcements, real armor damage, one hit per volley, resource preservation, pause/service/mastery/F7 gates, retreat/death/leash/long-frame cleanup, exact rewards, record validation/reload and actual Bloom/Siphon interactions. The 15 bout checks run all production combat components at fixed 0.05s steps with scripted navigation and casting. Four seeds/conditions/results are exported to `data/encounter_scripted_bouts.json`. They measure simulated combat, not human experience, sound mixing or hardware speed. Cue playback has its own 19-assertion suite; fast manually stepped encounter tests mute sound so the audio mixer is not being treated as the fixed-step simulation clock.

Rendered encounter capture: `godot --path . --audio-driver Dummy --script res://tests/encounter_integration.gd` with writable isolated XDG directories on Linux and a display. Images under `previews/encounter/` are actual engine captures. The trial title/hit countdown sits above the menu row; the generic hovered-enemy bar is suppressed during a trial.

The inherited cue release-pose assertion now waits for the authoritative physics cast release rather than racing a process timer against a .16s windup. Its assertion count and gameplay timing are unchanged.

## Right-docked UI

`inventory_ui_integration.gd` checks docking/bounds, equipment above bag, every real slot, current resources, hover/pin separation, comparison purity, staff/focus rules, exact-cell bag/gear drops, grabbed offset, stale/invalid payloads, quick-equip, full-bag rollback, character stats, I/C/Escape, resize and compatible saves. Headless runs contain 108 assertions. Rendered runs contain 110: they also force a native drag and move/release the real pointer. Input points are converted through the window final transform before warping, so stretch scaling is accounted for. Native pointer checks require a display and are not counted in the headless runner.

## Paired service verification

The Town suite passes 69 headless and 71 rendered assertions. It covers pure plans, UID conservation, exact cross-grid cells, Ctrl-click, full-destination rollback, batch atomicity, dim filters, text-focus shortcuts, stock comparison/purchase, stale callbacks, buyback pricing/cap/ownership, poor funds/full bags, gold/potion caps, combat/death/protected-save gates, schema-five validation, schema-four import, exact one-time upgrade backup, buyback save/F7 round-trip, preserved tabs, empty states and resize. Two display-only checks use native cross-panel pointer dragging.

## Save reliability

Read `RELIABILITY_HANDOFF.md` for the fault matrix and writer contract. The new suite has 77 assertions in both headless and rendered modes. Its in-memory IO adapter simulates open/write/flush/read/copy/rename and byte corruption; the final round trip uses the real isolated filesystem. Test output distinguishes a failed primary commit from a backup warning after commit. Rejected purchases are never replayed by F5. Active effects and paid resources survive failed equipment/mastery/F7 commits. No physical power-loss or Windows IO claim is made.

## Exact item-grid alignment

Inventory passes 108 headless / 110 rendered; Grid passes 64 headless / 66 rendered. The six additional native mouse checks across Inventory, Town and Grid were verified in the earlier UI cycles. See `GRID_ALIGNMENT_HANDOFF.md` for the complete dimensions, source references, five-resolution drag-scale tests and actual native third-cell sword drag. Current-cycle counts are listed at the top of this document.

## Persistent floor loot

The new 78-assertion headless/rendered suite tests collection plans, failed-write atomicity, remainder piles, separate retry time, exact floor ownership across real save/load/F7, protected/dead/stale/distant guards, nearby UI purity and commit, capacity admission, off-floor navigation fallback and exact schema-six upgrade preservation. Read `LOOT_RECOVERY_HANDOFF.md` for the full contract and limits.

## Selected runtime art

`selected_art_integration.gd` passes 76 checks in both headless and rendered modes. It verifies all 42 selections, real ability IDs, footprint-sized portraits, safe original-art fallback, aspect/caption clearance for both classes, matching bag/equipment art, real tab/action icons, Grimoire routing, the crafting callback, the preserved unique portrait and schema-six save validity. Six rendered captures are in `previews/art_integration/`. Logs from this cycle are in `tests/art_integration_qa/`; inherited previous-cycle logs retain their historical scope.

`python3 tools/verify_selected_art.py` validates the 42 runtime hashes without extra dependencies. Add `--library ../../art/expansion02/2026-11-12` to validate source hashes too when using the repository layout. This is file provenance verification in addition to the 825 gameplay/UI assertions.

## Full-square skill paintings

The skill-tile suite adds 75 headless/rendered assertions covering all twenty IDs, square dimensions, every pixel opaque, accepted hashes, fallback safety, real HUD/Grimoire routing for both classes, actual low-mana/cooldown preservation, active Ember Aura and a valid schema-six save. Six native captures are in `previews/skill_tiles/`; complete current logs are in `tests/skill_tiles_qa/`. Full headless total:900. The six previously verified display-only drag assertions give906 distinct overall; native drag suites were not rerun for this icon-only cycle.
