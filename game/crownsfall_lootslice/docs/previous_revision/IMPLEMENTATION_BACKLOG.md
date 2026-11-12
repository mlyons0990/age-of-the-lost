> ARCHIVED SYSTEMS EXPANSION: the current Mage Slice handoff and README supersede implementation/status claims in this chapter.

# Implementation backlog and review gates

Each ticket describes a concrete next increment. Priority is about dependencies and player impact, not a claim that the rest of the game exists. Estimates require the next developer's actual art assets, engine version and target hardware.

## P0 — Establish the authoritative production branch

| ID | Work | Dependencies | Acceptance evidence |
|---|---|---|---|
| P0-01 | Obtain actual Combat Impact project, latest 3D courtyard/Warrior sources, class Bible V4 and six canon images | Asset transfer | Archive inventory, hashes, engine version, missing-file list; no reconstruction from filenames |
| P0-02 | Windows import/run/export smoke | This source ZIP; official Godot | Clean import, new character, move/cast/equip/save/reload; capture errors, Windows version and build hash |
| P0-03 | Choose integration baseline after comparing the supplied branches | P0-01 | Written merge map: source of movement, combat, item schema, art, UI and saves; known-good copies retained |
| P0-04 | Legacy save import tool | P0-03 | Read-only original, new output file, mapped/unsupported fields report, tests of old 10/40/60 specialization data |

## P1 — Close correctness gaps before content volume

| ID | Work | Likely seam | Definition of done |
|---|---|---|---|
| P1-01 | Central effect resolver with explicit damage schools and snapshot policy | player.gd, new effect resolver | Direct/delayed/DOT damage use documented power; crit and proc rules tested; no double-kill rewards |
| P1-02 | Fix recovered-magic burn scaling and tooltip parity | damage_enemy, Grimoire | Cinderwake direct and DOT scaling matches tooltip; variance, Rally and modifiers enumerated |
| P1-03 | Save cooldowns/resources or adopt explicit town-session rules | save schema/repository | Reload cannot be an undocumented heal/cooldown exploit; migration from schema 2 tested |
| P1-04 | Equipment legality: dual wield/two-hand/armor class | Systems, item definitions | Two-handed weapon cannot coexist with shield; incompatible swaps roll back whole transaction |
| P1-05 | Complete transactional inventory command API | Systems, player/UI | Equip, move, sort, stash, buy and sell share ownership checks; no duplicated UI business logic |
| P1-06 | UID/content validation and save error UI | save validator | Invalid containers recover backup or remain protected; exact reason visible; no silent item deletion |
| P1-07 | Correct targeting intent when primary slot is a non-melee spell | player/controller | Auto-chase respects actual range, self/ground targets and empty slots; no useless chase loops |
| P1-08 | Merchant buyback and deterministic stock generations | merchant service | A sale can be reversed within defined limits; empty stock does not silently regenerate on load |

## P2 — A complete buildable class slice

| ID | Work | Dependencies | Acceptance evidence |
|---|---|---|---|
| P2-01 | Mage from level 1 with Fire/Frost/Arcane previews | P1-01, class roster | Five active mechanics and correct resource behavior, no free class passive; future paths inspectable |
| P2-02 | Level-20 and level-40 progression service | P2-01 | Gates enforced in model and UI; Arcane → Chronomancer; no accidental Paladin conversion |
| P2-03 | Per-ability mastery graph | P2-02 | Stable node IDs; prerequisites, points, mutual exclusion and respec transaction tested |
| P2-04 | Ashen Ward → Ember Aura transformation | P2-03 | Toggle, paid pulse, insufficient mana stop, death/zone cancellation and branch exclusion tested |
| P2-05 | Cinder Bloom and Siphon Embers | P2-04 | Patch recursion cap, actual-damage lifesteal, recovery cap and boss interaction tested |
| P2-06 | Band of Continuance, Emberwake Circlet, Riftglass Focus, Crownless set | P2-05 | Unique powers work in combat; no recursive loops; duplicates/set count validated |
| P2-07 | Base class restrictions and resources for the remaining roster | P2-01 | One class at a time; five real abilities, distinct silhouettes/animations and a complete tested loop |

## P3 — Visual, input and combat fidelity

| ID | Work | Acceptance evidence |
|---|---|---|
| P3-01 | Art-directed UI frame kit and typography | Same screens in 720p/1080p/1440p/ultrawide; no clipping; consistent hover/disabled/rarity states |
| P3-02 | Painted ability/item icons replacing vectors | Editable source, manifest parity, recognizable at 32px, meaningful shapes, no baked rarity tint |
| P3-03 | Keyboard/controller focus and rebinding | Complete inventory/Grimoire/service flow without mouse; remapped bindings appear in hints |
| P3-04 | Accessibility settings | Text scale, color-independent state markers, contrast and reduced camera shake; user testing |
| P3-05 | Animation contact events and cancellation rules | Captured anticipation/contact/recovery with combat log timestamps; no overwritten pending hit |
| P3-06 | Direction-complete attack/cast/hurt/death animations | Real asset files, atlas/rig checks, looping transitions, foot-contact review at normal speed |
| P3-07 | Original audio and mix | Licensed/original assets, layered impact cues, no clipping, voice/music/effects settings |
| P3-08 | 3D character and environment integration | Actual GLB/Blender import, rig/clip integrity, skinned playback, navigation and lighting verified |

## P4 — Turn the systems arena into an authored world

| ID | Work | Acceptance evidence |
|---|---|---|
| P4-01 | Introductory cathedral encounter | Authored space, guard combat, memory reveal; emotional twist paced and provisional names reviewed |
| P4-02 | Lorecasting state machine and chronicle | Interrupt/retry/one-time rewards, stable discovery IDs, links to item/skill/landmark histories |
| P4-03 | Temporary epoch dungeon | Discovery reveals entrance; expiry safely evacuates or preserves session; rewards cannot duplicate |
| P4-04 | Atlas/region/minimap landmark registry | Identical stable landmark IDs and transforms; navigation and fog ownership defined |
| P4-05 | Enemy families with individual mechanics | Animated silhouettes, combat telegraphs, behaviors and loot tables; no palette-only replacements |
| P4-06 | First authored boss | Multi-phase telegraphs, interrupted state cleanup, one-time rewards, repeat-kill economy checked |
| P4-07 | Performance/export pass | Profiling on declared target PC, median/low frame times and worst VFX scene, clean Windows export |

## A practical next three deliveries

1. **Windows verification + merge decision:** open this exact package, run the short walkthrough, collect missing production assets, identify the authoritative baseline. Deliver a reviewed merge map and any compatibility fixes.
2. **One polished Mage encounter:** five active actions, correct animations/contact events, one elite encounter, spell/equipment tooltips that match actual combat. Deliver source and actual gameplay video.
3. **One transformative build:** implement Ember Aura, one mutually exclusive mastery choice and one named unique. Deliver build fixture, proc-loop tests and tuning measurements before expanding the item pool.

Do not spend hundreds of nominal “passes” adding decorative trim without before/after evidence. The older 960+1,000 plan is historical ambition, not completed work or a required unit of progress. A useful increment has observable player behavior, source, tests and honest limits.
