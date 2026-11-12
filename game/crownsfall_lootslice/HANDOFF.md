# Current cycle — Full-square skill artwork

Read `docs/FULL_SKILL_BUTTONS_HANDOFF.md` first. Twenty full-square paintings now appear in the real action bar and Grimoire; earlier transparent symbols remain fallback art. Current QA is900 headless assertions and a75-check rendered skill suite. Six previously verified native drag checks bring distinct coverage to906. Inventory, gameplay and saves retain prior behavior. The following handoff records the preceding integration cycle.

# Crownsfall — current Art Integration handoff

Revision: November 12, 2026. This independently saved source revision extends the tested Higgsfield Mage art build. Original projects, prior ZIPs and canon references remain preserved. Historical handoffs are under `docs/previous_revision/`; current claims come from this README, `MASTERY_SYSTEMS.md`, runtime definitions and result logs.

## Current selected-art cycle

Read `docs/ART_INTEGRATION_HANDOFF.md` first. The 42 accepted Expansion02 designs are now selected for runtime use: 12 equipment portraits, 19 ability icons and 11 UI/service symbols. Original art remains as fallback. Equipped gear now preserves its aspect and shares bag portraits. Existing callbacks, ownership, stat scaling and schema 6 are retained. `data/selected_art_profile.json` records every source ID/path/hash and runtime selection.

## Previous loot recovery cycle

Read `docs/LOOT_RECOVERY_HANDOFF.md` first. Saved floor gold/potions/gear, persist-first pickup, partial piles, separate retry cooldown, nearby comparison/Collect UI and F/N controls are implemented. Schema 6 imports schemas 2–5 and preserves exact pre-v6 bytes. Enemy/arena/cast simulation remains transient.

## Previous item-grid correction

`docs/GRID_ALIGNMENT_HANDOFF.md` records the current correction: footprint-shaped portraits, aspect-preserving grid rendering, responsive drag ghosts with exact picked-pixel offset, wrapped inspector sizing, and complete dimension/hit/overlap/native drag tests. Save reliability and navigation remain integrated.

## Previous reliability cycle

Checked save commits and persist-first transaction application now cover town actions, equipment, unique attunement, mastery, hotbar, arranging and cell movement. Visible storage recovery, F5 non-replay retry, guarded F7/native exit and prospective resource clamping are implemented. Read `docs/RELIABILITY_HANDOFF.md` first for the writer commit point, backup warning semantics, failure tests and limits.

## Result

Warrior and Mage remain playable. Mage has five base spells, three specialization/heroic paths, dedicated painted directional art, real projectile/cast/ward behavior and class-specific gear. The inherited Mastery build supplies a five-node saved Ashen Ward mastery graph, paid Ember Aura, exclusive Cinder Bloom/Siphon Embers branches, Steady Flame and functional Emberwake Circlet attunement. The graph is an explicit investment, never an automatic class passive.

The source includes UI, inventory/stash/vendor/discovery interactions, spell/gear paintings, actor art, sound feedback, stat curves, tuning exports and validated demo builds. The separate F7 lab remains a 58-bone/six-clip geometric training scene. It is not the Mage combat simulation rendered in 3D.

This revision adds the replayable Unwritten Cantor trial: three locked warning shapes, a second verse, real fragments, rewards and persisted victory count. Read `docs/ENCOUNTER_SYSTEMS.md` for implementation, measured scripted bouts, failure handling and tuning limits. The original 242 checks remain; 75 new encounter/bout assertions bring the total to 317.

## Inventory and character revision

`inventory_panel.gd` supplies the new right-docked equipment/character tabs, real inventory grid, comparison card and original Higgsfield stone/bronze frame. `player.plan_equip` is the pure shared planner for preview, drop validation and commit. Exact-cell unequipping and grabbed-cell offsets use the real ownership transaction. The Encounter save namespace and 10×6 bag geometry are retained; schema 6 retains buyback and adds ground ownership with schema-2/3/4/5 imports. Read `docs/INVENTORY_CHARACTER_UI.md` for details.

## Paired town services

The current revision pairs a stash or merchant on the left with the inventory/character pane on the right. `town_actions.gd` supplies pure transfer/purchase/sale/potion/buyback plans; `service_panel.gd` provides live controls. Buyback keeps the newest twelve sold items in schema 6. Main imports schemas 2–5 and preserves exact one-time `.pre-v5` / `.pre-v6` snapshots at their upgrade boundaries. Read `docs/TOWN_UI_HANDOFF.md` for exact behavior, validation and rollback.

## Implementation seams

| File | Responsibility |
|---|---|
| scripts/encounter_rules.gd | Pure warning geometry and bounded level curves shared by rendering and live collision |
| scripts/encounter_director.gd / trial_boss.gd / trial_hud.gd | Authored phases, locked warnings, rewards, cancellation and dedicated status |
| tests/encounter_integration.gd / encounter_playthrough.gd | 60 lifecycle/collision assertions and 15 checks over four scripted production-component bouts |
| scripts/mastery_data.gd | Pure rank/point/prerequisite/exclusion validation, investment/refund planning and derived ability variant |
| scripts/aura_controller.gd | Paid scheduler, immutable pulse packet, bounded patches, actual-damage recovery ledger and unique burn extension |
| scripts/player.gd | Ownership/gear transactions, cast and visual timing, actual damage routing, mastery/attunement commit and cancellation |
| scripts/main.gd | World/services, idempotent kill hook, schema-6 checked validation/persistence, future-file protection and F7 transition |
| scripts/systems.gd | Inventory geometry, legal equipment, stat derivation, level-capped loot and recognized unique identity |
| scripts/effect_resolver.gd | Shared direct/DOT/ward math and current aura tooltip values |
| scripts/hud.gd / legacy_hud.gd | Graph, actual UI controls, unique inspector, scrollable Grimoire, variant icon and active ON indicator |
| scripts/art_library.gd / sound_bank.gd | Painted/vector routing, panel skin, reusable cue voices, persistent mute and graceful audio shutdown |
| tests/mastery_integration.gd | 86 regression/interaction assertions and actual rendered captures, including a mastery/unique F7 round-trip |

Read `docs/MASTERY_SYSTEMS.md` before modifying resource/proc rules. Aura retains saved ID `ashen_ward`; packets distinguish origin and proc depth. Secondary damage cannot retrigger patches or Siphon. The rolling recovery cap survives toggles/respec within a session. Item/cast snapshots do not read new equipment mid-flight. Aura equipment changes stop that running snapshot.

## Persistence and compatibility

Schema 6 adds ground loot to persisted buyback to ranks, once-only attunements, current HP/mana and stable-ID cooldowns. Schemas 2–5 remain importable and a one-time pre-v5 snapshot precedes upgrading. The new custom user directory and filename are in the README. Original namespaces are untouched. Explicit schema-2/3 import starts with unspent mastery and preserves existing current resources where supported; it does not auto-grant Aura. Future save files are write-protected. Invalid points, exclusions, unknown powers, fractional schema/currency and nonfinite numeric fields are rejected.

Enemies, open arena state and active effects remain transient. Offline cooldowns do not advance. The loader is a prototype with preserved backups, not a general migration service or production anti-cheat economy.

## Data, sources and examples

- `data/mastery_nodes.json`, `implemented_ability_variants.json` and `runtime_unique_definitions.json` match implemented behavior.
- `data/mastery_balance_snapshot.csv` has 26 analytic checkpoints, including full point investment through level 60. Ratios exclude crit/variance, movement and other casts; they are not measured encounters.
- `data/example_builds/` contains three deliberately authored records that passed the real save validator. Its README describes isolated use. They are not captured user progress.
- Original canon images and GLB hashes are recorded in `CONSOLIDATED_PRESERVATION.json`. The original GLB is unchanged.
- Higgsfield accepted source images, the rejected experiment, prompts, job IDs and portable processors remain. The prior 45 art/audio derivatives plus six new mastery/unique crops reproduced byte-for-byte. The single front modeling reference is source art only; no Tripo/Meshy job completed.

## Verification

825 headless assertions pass: 52 Warrior + 57 Mage + 28 original lab + 19 art/audio + 86 mastery + 60 encounter + 15 scripted-bout + 108 inventory UI + 69 town UI + 77 reliability + 36 navigation + 64 grid alignment + 78 loot + 76 selected art. Rendered suites pass 110 Inventory, 71 Town, 66 Grid, 78 Loot and 76 Selected Art checks, including six additional native mouse assertions, for 831 distinct assertions overall. Rendered tests/captures use actual Godot 4.6.3 Linux/X11/software OpenGL and Dummy audio, not concept mockups. The mastery suite verifies scene transitions with a real level-40 build, a named unique, exact resources/cooldown and art selection before the next physics frame. Review exact logs under `tests/`.

## Limits and next useful increment

The painted Mage is a prototype four-pose walk/two-pose cast set, with mirrored handedness. Hurt/dodge/death, equipment appearance changes, cloth/IK and production 3D remain. The 3D lab uses separate training controls/values. There is no universal resistance/proc engine, multiplayer simulation, production music mix, controller navigation or localization.

The authored encounter now has automated collision/lifecycle coverage and four scripted measured completions. Next run human readability and economy tuning, compare both branches with equal seeds and geared level-40 demo records, and validate Windows/target hardware. Then add missing actor states/gear visuals and the real 3D Mage pipeline. Do not interpret the 56-bone/17-clip production Wayfarer mentioned in older documents as the included 58-bone/six-clip proxy.
