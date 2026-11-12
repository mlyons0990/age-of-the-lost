# Age of the Lost — Higgsfield Mage Art + Rig Lab

Revision: November 11, 2026. This is the next playable source revision after the Crownsfall Systems Expansion. Extract it into a **new folder**. The previous Warrior-only project, ZIP and Drive files remain independent rollback copies.

## What is playable

Choose **Warrior or Mage** and your own name at creation. Mage starts with five working actions: Cinder Thread, Glacial Stitch, Arcane Fold, Ashen Ward and Starfall Script. Both classes have three level-20 paths and a matching level-40 heroic identity. Mage follows Fire → Pyromancer, Frost → Glacial Sovereign, Arcane → Chronomancer.

The existing 10×6 inventory/stash, merchant, discovery interaction, Reality Scar arena and five-slot Grimoire remain. New gear includes 2×4 two-handed staffs, wands, focus offhands and cloth equipment. Class restrictions and whole-transaction weapon swaps are enforced. There are 19 distinct implemented ability definitions, 16 item bases and 39 editable vector icons.

**Art status:** Mage now has its own painted frame bank: five source facings (eight screen directions with mirroring), four walking poses, idle and cast poses. Eight spell paintings, seven gear paintings, a nine-slice modal skin and portrait are integrated. Thirteen procedural sound cues and a persistent pause-menu mute control add feedback. Warrior art and vectors remain. The F7 lab retains its 58-bone geometric proxy. Read `docs/HIGGSFIELD_ASSET_PIPELINE.md` for sources, rebuilding and prototype limits.

## Run

1. Import `project.godot` in standard Godot 4.x. This revision is tested in **Godot 4.6.3 on Linux**.
2. Wait for all PNG and SVG imports, then press F5.
3. Choose a class and name. Open Inventory to equip gear. Staff occupies both hands; wand permits a focus.
4. Open the Grimoire to inspect or rearrange abilities. Press R to open the training Scar.

A normal first launch uses a separate save directory, so it displays the new class selector. The source package is not an exported Windows executable.

| Input | Action |
|---|---|
| LMB / hold | Move; click an enemy to use the equipped primary action at its actual range |
| Shift + LMB | Primary action in place |
| RMB or 1 | Second active slot |
| 2 / 3 / 4 | Third / fourth / fifth active slot |
| Q | Health potion |
| I or C / K or B | Inventory / Grimoire |
| E / R | Nearby town service / open-close Scar |
| Escape / F11 / F3 | Close panel-pause / fullscreen / navigation overlay |
| F6 | Gain one level, development shortcut |
| F7 | Enter 3D rig lab from town; return from lab with F7 or Escape |

## Mage actions

| Action | Gameplay |
|---|---|
| Cinder Thread | A traveling fire bolt. No mana cost; restores 3 mana on first valid hit per cast. Missing grants no resource. |
| Glacial Stitch | A frost projectile that pierces three enemies and slows 30% for 2s. A second hit within 6s freezes; elite duration is reduced. |
| Arcane Fold | Blink up to four ground units to valid floor. Invalid destinations spend neither resource nor cooldown. |
| Ashen Ward | Absorbs incoming damage after armor, for up to 3s. Does not heal or stack. |
| Starfall Script | 0.3s cast followed by a 0.8s visible ground telegraph, then area damage. |

Recovery prevents simultaneous spell overwrite. Projectiles use swept collision rather than only checking their final position. Queued casts and projectiles are invalidated on death, respawn, load or Scar closure. Direct hits and burns use a shared immutable power snapshot; tooltip estimates use the same calculation.

## Saves

New namespace: `AgeOfTheLost_Crownsfall_Mage_Consolidated`. Save: `crownsfall_mage_consolidated_v3.json`, schema 3. Class, current HP/mana, remaining cooldowns, cooldown durations, chosen name and existing progression/ownership are saved. Cooldowns freeze while offline; they do not reset on load. Active casts, wards, projectiles, world drops and arena enemies are transient.

The previous Systems save is not modified or automatically imported. To import a **backup copy** manually, copy its schema-2 JSON into this new namespace with the new filename before launch. The loader treats schema 2 as Warrior and adds current resource/cooldown defaults once. Back up both directories first. The original legacy Knight/Paladin 10/40/60 save is not supported by this importer.

## Verification

Run automated tests only with isolated data directories; they intentionally create and alter test saves.

```
godot --headless --path . --editor --quit
godot --headless --path . -- --systems-test
godot --headless --path . -- --mage-test
godot --headless --path . --script res://tests/lab_roundtrip.gd
godot --headless --path . --script res://tests/art_audio_integration.gd
godot --headless --path . --script res://tests/export_data.gd
```

Set `XDG_DATA_HOME`, `XDG_CONFIG_HOME` and `XDG_CACHE_HOME` to an isolated test directory on Linux. On Windows, use a test project copy with a different Custom User Dir Name. Current result files are in `tests/`; `HANDOFF.md` gives the tested scope and remaining work.

## Continue development

Read `HANDOFF.md`, `docs/MAGE_SLICE_SYSTEMS.md`, and `docs/IMPLEMENTATION_STATUS.md`. Generated definitions and balance checkpoints live in `data/`. The previous 12,000-word handoff chapters are retained under `docs/previous_revision/` as historical context; their old implementation-status claims are superseded by this revision.

The next planned increment is per-ability mastery and Ashen Ward → Ember Aura, followed by mutually exclusive Cinder Bloom / Siphon Embers and a named unique. Those mechanics are **not implemented in this slice**.
