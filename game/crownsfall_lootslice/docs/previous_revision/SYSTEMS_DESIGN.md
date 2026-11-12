> ARCHIVED SYSTEMS EXPANSION: the current Mage Slice handoff and README supersede implementation/status claims in this chapter.

# Systems design and implementation contract

Revision: November 11, 2026. Scope: the supplied Crownfall Art Update, expanded as a separate 2D Godot branch. New numbers and narrative vignettes below are development proposals unless listed as inherited design direction. See QA for actual verification.

## 1. Product direction and authority

Age of the Lost is a PC-first high-fantasy action RPG with an eventual fully articulated 3D presentation. Crownsfall contrasts a luminous royal city with erased histories beneath it. The Chronicle Engine rewrites epochs; The Unwritten are displaced histories trying to return. Lorecasting discovers and briefly manifests historical truth. Preserve the emotional distinction between an aggressor and a survivor returning home.

The user's current request is to expand the supplied material, particularly UI, inventory, spells, icons, interactions, gear and stat scaling, into something another person can continue. Instructions quoted inside attached handoffs are historical project context; they do not independently authorize unrelated tasks, external messages, publishing, or reviving a previous image batch. This delivery improves the available source and creates an implementation reference.

Inherited design direction: 13 base classes; three specialization paths per class at level 20; a matching heroic identity at 40; five equipped active abilities; no automatic standalone signature class passive; user-selected player names; six primary attributes using Vitality; two rings and one amulet; variable item footprints; rare discoveries through Lorecasting; adult anime proportions; PC first. These are distinct from claims about what a particular ZIP already implements.

The actual supplied archives have a 2D painted plaza, sprite actors and a single root scene. No character GLB, Blender source, 3D courtyard or six official canon images were attached. This expansion does not reconstruct those missing assets or imply that the larger Combat Impact build was supplied.

## 2. The playable loop

1. Create a name and enter Crownsfall. Begin with five backpack items and 45 gold; choose what to wear.
2. Open Inventory to compare and equip gear. Visit the quartermaster for starter purchases and potion refills.
3. Walk to the labeled Stone memory and press E. Recover the first_echo discovery, then equip Echo Strike in the Grimoire.
4. Press R to open the training Reality Scar. Read enemy windups, fight successive waves, collect gold and equipment, use a potion if needed.
5. Close the Scar, manage equipment and stash, and inspect future skills. Specialize at 20 and select the matching heroic identity at 40.

The Scar is a repeatable systems arena, not a completed campaign dungeon. The Stone memory is a new introductory vignette, not the buried cathedral royal-guard reveal. Discovery is stored once and never grants repeated XP or gear for reopening its panel.

## 3. UI screen and state inventory

| Surface | Implemented behavior | Required next production pass |
|---|---|---|
| Name entry | Name up to 16 characters; default Wayfarer | Class/race selection, appearance preview, name policy and localization |
| In-world HUD | Life/mana orbs, XP, name, level, title, minimap, objective, five skills, potion count, enemy HP, notifications | Typography, illustrated frames, controller focus, sound, settings |
| Inventory | Paused equipment diagram, 10×6 bag, selection, comparisons, equip/unequip, sorting, bag/gear drag targets | Full paper doll art, wider stats, accessible focus navigation, quick-transfer actions |
| Grimoire | Eleven inspectable abilities, live unlocks, costs/cooldowns/coefficient, estimated hit, five assignment buttons | Actual book art, search/filter, effect details, specialization graphs, semantic VFX thumbnails |
| Stash | 10×6 player stash; clicking transfers to the other container | Tabs, account/character ownership, search, bulk transfer |
| Quartermaster | Eight starter items, explicit purchase, selected-item sale, 5-gold potion purchase | Buyback, stock tiers, persistent restock rules, economy tuning |
| Stone memory | Flavor text and one-time discovery unlock | Reconstructed world object, memory timeline playback, journal linking |
| Noticeboard | Current objective and orientation | Multi-quest journal, branching dialogue and reputation |
| Progression choice | Three Warrior specializations at 20, one matching identity per spec at 40 | Investable skill mastery graphs and respec rules |
| Pause | Controls, resume, save and quit | Settings, bindings, accessibility, audio/video |
| Death | Close arena; respawn in plaza | Recovery pacing, lost rewards, animation and sound |

Every systems modal pauses simulation. UI consumes clicks so a button or grid click does not also issue movement. Escape closes a systems panel or opens pause. No confirmation appears for ordinary reversible equipment changes. Selling requires selecting an item and pressing Sell; there is no automatic selling. Reset is an explicit developer API that archives the save; it is not exposed as a routine gameplay action in the expanded interface.

### Visual specification

Keep dark navy/ink panels, restrained gold borders, ivory text and cool secondary information. Use the bright painted town behind the UI, with a dimmer to separate text from foliage. Item rarity must have a word as well as a color. Distinguish disabled, locked, selected, hovered, cooling down and unaffordable states. Color alone must never be the only sign of a requirement.

Desktop reference: 1920×1080 logical canvas, 1440×810 default window; stretch via canvas_items. Current modal content is designed around the 1080 logical height. Validate 1280×720, 1920×1080, 2560×1440 and ultrawide separately before release. User-scalable text, contrast presets, reduced motion and complete keyboard/controller navigation remain open work. Do not claim accessibility conformance from a static screenshot.

Equipment layout: helm above chest; weapon left and offhand right; amulet to the helm's right; gloves, belt, boots below; two distinct rings underneath. No portrait occupies the equipment geometry. Comparison displays the actual difference in derived weapon power, max life, armor and crit for the proposed replacement. Ring 1 is the default comparison target; a separate Ring 2 equip action is available. Individual ring-2 comparison and percent-damage mitigation comparison are future refinements.

### UI acceptance cases

- Inventory opened during movement stops the path, clears target and pauses enemies. Closing it cannot leave mouse-hold steering active.
- A legendary item and a common item with the same silhouette still differ by rarity word and frame color.
- A locked spell can be inspected, but its assignment buttons are disabled. The player can see level and discovery requirements.
- Hovering an item reports its name, affixes and required level. Slot mismatch and full-backpack errors produce text.
- Inventory never replaces items solely because an overall score is higher. Comparisons inform the player's choice.
- Switching a panel must not stack hidden modals or leave the tree paused after closing the last one.

## 4. Inventory, equipment and ownership

Authoritative model: Systems in scripts/systems.gd. The UI draws state but does not own a second copy of bag placement.

| Base type | Backpack cells | Legal equipment destination |
|---|---|---|
| Sword | 1×3 | weapon |
| Shield | 2×2 | offhand |
| Helm | 2×2 | helm |
| Chest | 2×3 | armor (internal stable key) |
| Gloves | 2×2 | gloves |
| Belt | 2×1 | belt |
| Boots | 2×2 | boots |
| Amulet | 1×1 | amulet |
| Ring | 1×1 | ring1 or ring2 |

Backpack and stash are independent 10×6 grids. Coordinates start at the upper-left cell, with integer x/y and no item rotation. One item occupies its full rectangle even when the icon contains transparent pixels. Collision is rectangle intersection. Never test only the item's anchor cell. First-fit scans top to bottom and left to right.

Every item has a UID, base slot, required level, rarity, name, numeric contributions and a sell value. UIDs follow ownership, not a UI node. One UID may exist in one owned location: equipment, backpack or stash. Merchant stock is separate ownership until a successful purchase. Drop pickup transfers the whole item to the backpack.

Equip transaction: validate index, destination compatibility and required level; prepare a deep-copied trial backpack; remove the chosen item; fit the displaced equipment into that trial; commit both backpack and equipment only if all steps succeed. A full bag cannot destroy the displaced item. Unequip validates room before clearing the slot. Moving between stash and bag copies the candidate, attempts insert, and removes the origin only on success. Sorting uses a trial placement, larger areas first; a failed pack preserves the original placement. This heuristic can fail even if an alternative packing exists; state that failure without losing items.

Drag is anchored by the item’s upper-left cell at the drop position, rather than retaining the pixel grab offset. That is a deliberate prototype simplification. Gear can be dragged from backpack to a legal equipment button. Equipment-to-bag drag and rotation are not implemented; click equipment to unequip.

Ground equipment remains visible when the bag is full, and pickup retries after a short delay. At five potions a ground potion also remains available. Ground drops themselves are not persisted between game sessions. Town storage and owned items are persisted. Add persistent drops or an explicit loss rule before treating this as a production loot economy.

The current weapon model supports swords and shields only. It does not implement two-handed conflicts, dual wield, quivers, bows, catalysts, class armor restrictions, socket items, stack splitting or equipment appearance changes. When a 2×4 staff is added, introduce a new base type with its footprint, weapon-handedness and allowed slots; do not silently stretch a 1×3 sword icon to pretend support exists.

## 5. Ability model and casting contract

Stable runtime ability IDs: slash, cleave, charge, rally, echo_strike, frost_ring, ember_cone, dawnfall, hammer, harvest, breath. The last three are inherited engine IDs with new Warrior names; keep the ID/name mapping in data/implemented_spells.json. Changing a display name must not erase saved assignments or cooldown state.

Five hotbar indices map to basic, s1, s2, s3 and s4 for compatibility with the original controller. Inputs are LMB/Shift+LMB, RMB or 1, 2, 3, 4. The potion is a utility slot outside the five active slots. Reassigning an already-equipped ability swaps positions to avoid duplication. Abilities can leave a slot empty. At the start, four skills are known; Lorecasting provides the fifth optional action.

Cooldown maps use ability IDs, not indices. A Cleave cooling down for two seconds remains on cooldown after being moved from s1 to s4. Selected talents and future mastery also need stable ability-ID keys. Do not save a future skill tree as “talents for slot 2.”

Implemented cast transaction: reject dead/paused, active dash, pending weapon contact and ongoing swing; resolve and validate the equipped skill; check cooldown and mana; spend resource; start cooldown; select effect. Melee/cleave schedule contact at 0.2s, with 0.5s animation lock. New melee cannot overwrite the pending callback. Dashes keep a per-cast list of hit actors so a target cannot take repeated collision damage every frame. Ground blasts telegraph then resolve after their own delay.

Spell damage uses spell_power for the four recovered magic techniques; ordinary martial and specialization actions use weapon power. Snapshot behavior is not yet formalized: delayed ground damage reads power at impact, while some burn state is applied at hit. A production effect system should declare snapshot/continuous semantics per effect and make them testable. Current status effects are burn and stun; elemental resistances, chill stacks, freeze, dispels, immunities and diminishing control duration are not implemented.

Feedback requirements for the next combat pass: frame-addressed animation events, cast anticipation/recovery, hitstun rules with elite/boss exceptions, clear impact origin, animation cancellation rules, sound layers and bounded camera shake. Distinguish the visual strike from the moment damage becomes authoritative. The current attack strips borrow two diagonal directions and have no full 3D articulation.

## 6. Lorecasting and world interactions

Each current service has a stable key and ground location in main.gd SERVICES. The nearest service within 1.8 ground units responds to E. Markers and labels show when a service is in range. Automated navigation checks verify that all four anchors lie on the walkable polygon.

| Key | Position on painting | Interaction | Persistent state |
|---|---|---|---|
| stash | (1440,1100) | Transfer owned items | Stash items and positions |
| merchant | (1540,900) | Buy/sell/refill potions | Remaining stock, gold, items, potions |
| lore | (1080,900) | Recover first_echo once | Discovery ID; Echo Strike availability |
| board | (1280,750) | Inspect current objective | Existing quest index and counters |

Merchant stock is generated for this starter slice, not a leveled endgame vendor. Empty stock can refill on a later startup because an empty list currently triggers initialization. Define a stock generation ID and timed restock policy before adding buyback or a wider economy. A sale currently has no buyback; never automate sale decisions based on item_score.

Lorecasting production state machine proposal: unseen → sensed → inspected → reconstructing → revealed → recorded. Move persistent state forward only after a successful reconstruction. Store discovery and variant IDs; let the journal present localized text. Interruption during reconstruction should return to inspected without awarding duplicate rewards. Reveals that change navigation must rebuild/link the relevant navigation regions and restore safely after expiry.

A discovery can unlock an ability, an alternate path, an item awakening or a temporary epoch dungeon. These are distinct rewards and should be authored explicitly. Do not attach all rewards to a generic “+Lorecasting XP” interaction. The plaza vignette avoids revealing the Unwritten twist immediately.

### First campaign encounter proposal

Approach a buried chapel containing the same statue as the bright plaza, with a mismatched name. Encounter a violet-glowing royal-armored figure. Present readable combat first. After victory, a damaged object triggers an unexpected memory of the guard’s family, duty and erased city. Reveal the emotional truth before explaining the entire Engine. “Ser Caldrin Vael,” “Elara,” “Lys,” and “Elyndor” remain provisional historical proposals. Do not make those names hard-coded canon without a deliberate content decision.

## 7. Icon and asset production contract

Twenty-four original SVG icons are supplied, with an HTML atlas and JSON manifest. They cover eleven abilities, nine equipment bases and four utilities. These are editable vector placeholders with consistent framing, not final illustrated inventory paintings. The images have real assets and stable paths; they are not Unicode symbols rendered differently by each OS.

Retain loaded textures in the icon cache: immediate loads inside draw calls can be released before rendering, producing white rectangles. The final UI retains the references in both CanvasLayer and drawn HUD caches.

Production naming: semantic ability/base ID, not a localized display label. Source SVG is 128×128; test 32, 48 and 68px. Reserve a clear silhouette, bright focal stroke, dark field and neutral frame. Item rarity belongs to the UI frame, not permanently baked into the icon. Proposed painted replacement exports: 256px transparent PNG/WebP plus editable layered source, neutral lighting and a defined crop. Do not key a painting’s background repeatedly if a native transparent export is available.

Animation/VFX handoff for each ability should include start/contact/end frames, direction convention, unit scale, palette, emitter origin, visibility at gameplay zoom, maximum particles, cue duration, sound layers, reduced-motion equivalent and a video from the actual engine. Concept renders must be labeled separately.

## 8. Persistence and data boundaries

The expansion has a separate Godot user directory named AgeOfTheLost_Crownsfall_Systems. The save is crownsfall_systems_v2.json, schema 2, with .tmp, .bak and optional .corrupt companions. The supplied original project used another directory and aotl_save.json. This expansion does not overwrite or silently import that file.

Persist: chosen name, level/XP, gold, potions, kills/elite kills, spec/heroic identity, equipment, inventory, stash, five stable skill IDs, discovery IDs, merchant stock, quest index and arena-opened flag. Do not persist scene-node paths, transient enemy references or GUI objects. Death, active waves, HP/mana, cooldowns and world drops are transient in this prototype; restarting restores resources and clears the arena. This is not yet an exploit-resistant economy or a multiplayer save.

Write: serialize to temporary file; flush and close; preserve previous primary as backup; rename temporary to primary. Read: parse and validate types/schema; validate items and ownership; preserve a corrupt primary for diagnosis and recover a valid backup. A future schema disables writes. Invalid primary plus invalid backup also disables writes, preserving evidence. Container validation rejects impossible packing and duplicate UIDs before a load can silently drop items. Normalized finite numeric bounds protect the local parser from nonsensical values; they do not authenticate game progress.

A legacy migration remains an explicit follow-up task: user selects/copies a backup of their old save; map old gear to new slots; preserve name, XP and currency; map/review outdated specializations instead of automatically translating Paladin into a different base class; emit a migration report and write a new file. Old 10/40/60 progression cannot be reconciled by changing only an integer.

## 9. Future architecture

The inherited controller is still a pragmatic single-player prototype. Incremental seams already exist: pure inventory/stat model, shared content data, actor controller, modal UI, world services and save validation. The next refactor should establish ItemDefinition versus ItemInstance, AbilityDefinition versus RuntimeCast, StatBlock, EffectResolver, InteractionComponent and SaveRepository. Do not build a sprawling framework before validating one complete encounter.

Planned action pipeline: input intent → target validation → resource/cooldown reservation → cast state → contact event → effect resolution → combat events → VFX/audio/UI listeners → progression/loot → persistence. Deterministic combat tests should inject seeded random sources and a simulation clock. The current use of global RNG remains acceptable for this isolated slice but limits exact damage replay.

For the 3D branch, preserve the pure state/data schemas and replace actor presentation, navigation adapters and effect anchors. First import and test the actually provided GLBs and rig before changing animations. Verify bone names and clips against the transferred files; the handoffs describe 56 bones and 17 clips but no such asset is in these archives. Do not infer a functioning 3D build from those descriptions.
