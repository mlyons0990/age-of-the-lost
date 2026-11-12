# Age of the Lost — expanded development handoff

November 11, 2026. Read this first, then the individual design documents. The complete editable handoff outside the project ZIP combines those chapters for transfer to another developer or AI.

## Five-minute orientation

This is a source-backed expansion of the **supplied Crownfall Art Update**. That ZIP is a 2D Godot action-RPG slice with painted environment, sprite knight/enemies, procedural effects, Reality Scar waves, XP/quests and basic saves. The older Crownfall ZIP is a movement-only baseline. The other handoff files describe larger 2D/3D projects; their named builds and canon image files were not supplied here.

The expansion adds working inventory/equipment, spell assignment, icons, services, stat rules and safer saves. It also supplies a concrete content/engineering plan for the wider game. It is not a completed 13-class ARPG, a recreated 3D branch, a finished campaign or final commercial art.

The current user request is the authority for this work: expand the material so the next person has more to work with, specifically UI, inventory, spells, icons, interactions, gear and scaling. Historical imperatives inside attachments are recorded project intent. Older pending image batches and unlimited “phase passes” are not this turn’s task.

## Status matrix

| Area | Supplied source | This expansion | Still needed |
|---|---|---|---|
| Presentation | 2D plaza, sprites, navigation, occlusion | Retained; in-engine captures added | Supplied 3D art branch, final animation and lighting |
| Combat | Melee/dash/ground/cone/nova, enemy telegraphs | Pending-contact guard, recovered spell power, explicit scaling | Full cast state machine, resistances, animation events, sound |
| Inventory | Four auto-equipped slots; lower-score items auto-sold | 10×6 bag/stash, ten slots, explicit transactions, drag, sort, compare | Two-hand/dual wield, class restrictions, buyback, crafting |
| Abilities | Fixed bar, spec skill, slot cooldowns | Eleven inspectable entries, five assignable slots, ID cooldowns | Other classes, mastery graphs, full effect metadata |
| Icons | Code-drawn glyphs | 24 consistent SVG assets, manifest/atlas | Painted production icon library |
| Interaction | Global Scar shortcut and quests | Four ranged services, merchant, stash, noticeboard, discovery | Authored NPCs, dialogue, quest/world state graph |
| Stats | Four equipment stat fields | Six attributes, derived power, gear budgets, CSV checkpoints | Other class growth, resistance/stamina/attack speed/renown |
| Progression | Knight → three unrelated specs at 10 → advanced 40 → passive 60 | Warrior → Weaponmaster/Bastion Guard/Berserker at 20 → heroic identity 40 | Playable 13-class creation, respec and per-skill heroic trees |
| Saves | One unchecked JSON | Separate schema-2 save, backup, validation, protected future versions | Legacy migration, cooldown/resource rules, persistent drops |
| Content plan | Scattered narrative handoffs | 13-class roster, 65 ability entries, named build proposals, prioritized tickets | Actual implementation, balance and art of proposed content |

## Preserve the long-term identity

Crownsfall is a warm, bright white-stone royal city over grim lost histories. The Unwritten were erased from history without ceasing to exist. They may be hostile, displaced, tragic or innocent; do not flatten them into a generic demon faction. Lorecasting is discovery of historical truth, not a synonym for every spell cast.

Preserve 13 base classes, three level-20 paths each and matching level-40 identities; Mage Fire/Frost/Arcane with Arcane → Chronomancer; five equipped active skills; no automatic standalone signature class passives. Player chooses their name; Ixll remains an internal historical codename. The inventory uses Vitality, two rings, one amulet and actual variable footprints.

The six canon artworks and Royal Wayfarer character sheet remain visual references described by the original handoffs, but their actual files must be transferred. New content names, numerical budgets and the plaza memory vignette in this expansion are proposals, not newly user-approved canon.

## Architecture map

- `main.gd`: navigation, world layers, Scar/waves, services, quests, loot transfer and save orchestration.
- `player.gd`: movement, sprite presentation, equipped ability execution, progression and equipment commands.
- `game_data.gd`: current runtime spells, Warrior choices, enemy templates, rarity and coordinate helpers.
- `systems.gd`: pure item geometry/generation, inventory placement and derived stat calculations.
- `hud.gd`: systems modals, grids, drop targets, services, spellbook and pause.
- `legacy_hud.gd`: inherited drawing/widgets, name entry, progression and death screens; updated for retained SVG textures and ID cooldowns.
- `enemy.gd`, `loot.gd`, `fx.gd`: inherited encounter actors, ground drops and effect layers.
- `tests/integration.gd`: deterministic assertions around real source behavior and automated runtime capture.
- `tests/export_data.gd`: export implemented spell records and calculated balance checkpoints.

Do not hand-copy the controller into another branch before comparing input, camera, collision and navigation conventions. This branch uses painted pixels with 88 pixels per ground unit and 0.72 vertical squash. A 3D branch uses meters and Node3D transforms; only the pure data/model seams transfer directly.

## Source and proposal distinction

`data/implemented_spells.json` is exported from the runtime definitions. `data/class_roster.json` preserves inherited broader class direction with explicit status. `data/class_ability_proposals.json` and CSV contain five entries for each class: five already implemented Warrior entries and sixty new unimplemented base-kit proposals. Additional current runtime techniques bring the implemented spell catalog to eleven. `data/unique_and_set_proposals.json` contains six named build targets; no named unique power runs in the current game.

Data files are not all loaded by the game. The current GDScript definitions remain runtime authority. Future work should establish validated external definitions before treating proposed JSON as executable content.

## Next handoff action

Import the supplied source on Windows, follow the short README walkthrough and preserve the existing save. Obtain the missing production art/builds, select an integration baseline, then finish one Mage encounter with correct animations, tooltips and a transformative mastery choice. The backlog gives independent acceptance evidence for each step.
