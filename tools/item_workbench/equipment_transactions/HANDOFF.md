# Equipment transactions and save-failure verification

## Result
**30/30 checks pass** in Godot 4.6.3 stable on Linux against exact source baseline ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b. No defect was reproduced by this suite, so no production fix was applied.

## What executes
The original Player.plan_equip, equip_item and unequip_item methods, original Systems rules, actual Aura controller and original SaveStore/SaveDisk implementation. Real JSON is written/read under an isolated user-data directory. Player nodes are deliberately not attached to a scene, avoiding unrelated animation/world setup. A minimal Node2D host supplies persistence and a silent cue counter. A disk subclass injects specific write/rename failures while all successful operations use the real disk adapter.

## Verified behavior
- Two-handed staff planning is nonmutating and preserves displaced wand/focus ownership.
- Failed write and failed primary rename reject the transaction and preserve live equipment; primary rename failure also preserves the prior durable save.
- Successful equip survives a JSON disk roundtrip.
- A focus is rejected while a staff occupies both hands.
- Backup publication failure after primary commit remains a successful transaction, with a warning and matching durable/live state.
- Full bag rejects unequip without mutation; full bag also blocks exchanging a 1x2 bag wand for an equipped 2x4 staff when the displaced staff cannot fit.
- Class/level restrictions, invalid inventory indices and unknown equipment slots reject invalid plans.
- A newer-version primary and corrupt primary are protected from overwrite; live state remains unchanged and bytes are retained for recovery.
- A fresh Player instance accepts the persisted gear/inventory dictionaries without duplicate item IDs.

## Boundaries
This does NOT run the real Main.persist_changes host, full production save-schema validator, startup recovery/migration path, UI input, animation or complete game scene. The host's validator checks schema 6 plus inventory/gear container types only. Fresh-actor restoration uses decoded JSON assignments, not the production load entry point. Failure injection tests branches in the actual store; it does not reproduce power loss, hardware corruption or every OS/filesystem failure. No real player saves were read or modified.

## Reproduce
The Drive package contains project.godot, the exact dependency scripts, the harness, logs and source hashes. Use a dedicated writable location:

```
mkdir -p /tmp/aotl-transactions-data /tmp/aotl-transactions-config /tmp/aotl-cache
XDG_DATA_HOME=/tmp/aotl-transactions-data XDG_CONFIG_HOME=/tmp/aotl-transactions-config XDG_CACHE_HOME=/tmp/aotl-cache godot --headless --path /path/to/fixture --script transactions.gd
```

The harness owns `user://equipment_test.json` and its temporary/backup files within that isolated data directory. Do not point these XDG variables at actual game save directories. `prepare.py` reconstructs dependency files from the pinned Git snapshot; its current repository root is /workspace/aotl-audit and can be adjusted to an equivalent checkout. Existing copies and actual fixture files are included for convenient reproduction.

## Next integration gate
Run the complete Main validator/load path and actual inventory input flow against the agreed integration branch. This suite establishes targeted equipment-transaction evidence and is reusable alongside those broader tests. Keep runtime changes separate from the tooling branch to preserve the other developer's active work.

No production code changed; no credits or paid generation used.
