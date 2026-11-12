# AGE OF THE LOST — COMPLETE AI CONTEXT & CONVERSATION HANDOFF

**Prepared:** November 10, 2026  
**Intended audience:** A different AI assistant or development agent taking over the project.  
**Scope:** A curated, structured reconstruction of the conversation's decisions, dated milestones, known memory, and earlier design documents. **This is not a verbatim export of every message.**  
**Ownership:** Creative direction and approval belong to the user. Do not portray assistant-generated drafts or untested code as confirmed canon or finished game production.

> **High-priority instruction:** Continue *Age of the Lost* faithfully. “REFINE. ADAPT. PROGRESS.” Improve the **actual playable project**, art quality, movement, combat feel, spell VFX, and premium UI/UX in every pass. Aim for a high-end gaming PC first; a later iPhone port must not limit the initial visual target. Preserve user decisions, explicitly distinguish design concepts from implemented gameplay, and never claim background work or tests that did not occur.

## 1. Five-minute briefing for the next AI

*Age of the Lost* (AOTL) is an ambitious original high-fantasy action RPG. Core inspirations: Diablo, Path of Exile, Last Epoch, World of Warcraft, Hades, Ragnarok Online, anime fantasy including Sword Art Online and Granblue Fantasy: Relink, and the production polish of major AAA studios. These are **benchmarks for responsiveness, systems, and production values**, not licenses to copy assets, characters, UI, or proprietary designs.

The playable Godot 4 PC prototype began as 2D/2.5D isometric-style gameplay. Later discussions also progressed a **parallel and preferred higher-fidelity fully skinned 3D Blender/Godot art branch**. Do not assume the latest 2D code ZIP already contains the polished 3D models. Check the source assets, branch and intended integration before changing pipelines. User hardware is Windows; Blender 5.2.2 LTS is an established modeling tool. Godot 4.x is the gameplay engine.

The game features a charming royal city, **Crownsfall**, over lost cathedrals, temporal ruins, and civilizations erased by a malfunctioning **Chronicle Engine**. The central late-story twist is **The Unwritten**: erased timelines were not destroyed; their people and histories exist beyond reality and struggle to return. **Lorecasting** reveals and briefly manifests lost truth and unlocks discoveries, magic, and rare temporary dungeons.

**Current combat/class design direction:** ultimately **13 selectable base classes**, not just four. Mage must begin at level 1, choose **Fire / Frost / Arcane** at level 20, then advance to a corresponding heroic identity at level 40 (Arcane → Chronomancer is strongly favored). Five equipped active ability slots, user-selected talents, and deep per-skill heroic mastery. **No automatic standalone signature class passives**. The runnable prototype currently implements **four starting classes** (Mage, Rogue, Druid, Warrior); 13 is a broader newer design-bible target, not a claim that all classes are playable in the ZIP.

**Ixll** is ONLY an **internal development codename** for the player character; users select their own names at character creation. Every user-facing nameplate, quest, save, and inventory should use the selected name.

**The user's latest explicit request in the provided conversation:** make sword attacks and spells feel **weighty and meaningful**, with appropriate anticipation, visual contact timing, enemy recoil/hitstun, powerful realistic-looking VFX and audio. A new **Combat Impact Pass** ZIP was made on November 10, 2026; static ZIP verification passed but **no Godot runtime test of that new ZIP is confirmed**. The most recent user's directly confirmed working builds were earlier releases (notably Loop 2 Phase 3 and later “it works good” reports). Do not equate package integrity with a passing Godot editor/gameplay test.

### Immediate handoff checklist

1. Get the **latest actual Godot project ZIP** from the sender (see section 12) and extract it. Do not recreate code from memory instead of inspecting files.
2. Confirm Godot version and run `godot --headless --path <project> --editor --quit` or equivalent with an appropriate compatible Godot 4 executable; then launch the game on Windows for real visual QA.
3. Back up saves before importing or resetting character creation. Compare input, animation, combat timings, user names, skill slots, talent investments, inventory, and zone transitions.
4. If the newer **3D Royal Wayfarer / Crownsfall Blender packages** and six approved reference artworks are supplied, inspect those separately and plan carefully for integration. Do not silently discard the approved visual canon or conflate a concept image with a game-ready mesh.
5. **First gameplay improvement:** dedicated, anatomically plausible, fully articulated attack/cast/dodge animation tied to hit frames, including procedural/rigged foot planting where feasible. Add timing tests, before-and-after clips, and performance checks. The current sprite morphs are not yet final-grade animation.
6. Deliver each tangible change with the source project, test instructions, GIF/short visual preview where possible, changelog, and an explicit “tested vs not tested” statement.

## 2. Canon priority and contradictions to resolve

| Priority | Source / status | How to treat it |
|---|---|---|
| 1 | User's latest explicit instructions | Highest priority: AAA visual quality, high-end PC-first, player chosen name, 960 phase-pass target plus 1,000 retrospective refinements, “REFINE. ADAPT. PROGRESS.” |
| 2 | Six approved October 2026 character/city artworks | **Locked visual reference**; future renders and gameplay should match their proportions and painterly royal-fantasy language. Actual image files must be transferred separately. |
| 3 | Class Design Bible V4, newer class-system decisions | **13 base classes**, 3 level-20 paths each, corresponding level-40 heroic identities, 5 equipped active skills, no automatic class-defining passive. V4 names are design proposals until tested. |
| 4 | Godot project source actually supplied | Source of truth for what is **implemented**, whether it runs, and available assets. Older scripts may still contain four-class path names that conflict with V4. |
| 5 | Older 4-class prototype plans and visual concept codices | Historic implementation references only. Do not overwrite newer design-bible decisions with old provisional names. |
| 6 | Proposed story names and speculative twists | Useful ideas; user explicitly loved the Unwritten and cathedral guard reveal, but many proper names and subplots are **not separately approved canon**. |

**Important tension:** The October 13 playable-prototype branch uses four classes and some alternate level-40 names (e.g., Fire Mage → Phoenixbinder/Cinder Sovereign; Frost Mage → Winter Oracle/Glacier Warden; Arcane Mage → Chronomancer/Starweaver). The later V4 13-class design bible simplifies Mage to **Fire → Pyromancer, Frost → Glacial Sovereign, Arcane → Chronomancer** as one heroic identity per path. Preserve the user's **Fire/Frost/Arcane** and **Arcane/Chronomancer** decisions. Treat exact non-Chronomancer heroic names as **version-specific proposals**, not automatically reconcile them or claim both systems are already implemented. The next AI should identify which class spec file is being edited and honor the newer design direction for the long-term architecture.

## 3. Art direction and technical visual target

**Six locked visual references** from October 2026: Mage concept sheet, Rogue concept sheet, Mail-Wearer concept sheet, plus three Crownsfall environment paintings (market/cathedral plaza, royal square, citadel). The user repeatedly required new class art and the playable environment to match these exact style references in composition, scale, and finish. Reference names known from prior handoff: `01_Mage_Official.png` through `06_Crownsfall_Citadel_Official.png` under `AOTL_Official_Art_Large_View_Oct2026`, or the corresponding six-image ZIPs. Upload the images; **text alone cannot preserve the fidelity of approved art**.

**Rendering:** richly detailed, painterly anime fantasy with adult/anatomically plausible proportions (not chibi), expressive anime-influenced faces, elegant cloth/armor, natural posing, warm environmental light, crisp silhouettes and detailed shading. Crownsfall: bright white stone, blue/gold heraldic banners, flowerbeds, markets, fountains, stairs, royal architecture, lantern glow, greenery. Buried cathedrals, Veyr/Unwritten regions and rare dungeons should contrast sharply with the bright surface. Avoid uniform blue-gold treatment everywhere.

**Diversity:** many enemy/race silhouettes should be genuinely inhuman (spectral, void-faced, root/plant, bone, crystal, living machine, insectoid, aquatic, temporal). Do not make everything a recolored humanoid; avoid anthropomorphic furry/cat-person player races. Avoid mismatched anatomy, clipped hands, floating gear, duplicated poses, unreadable type, AI-looking glitches and lazy hue swaps. Technical model/animation standards: skinned meshes, proper articulation, believable contact/footwork, good UVs/materials, export to Godot as glTF/GLB, and rigged animations that really play in engine. The newer 3D Royal Wayfarer work is an **additional branch**, not proof the latest 2D gameplay ZIP is 3D.

**Gameplay mockups:** high three-quarter/isometric camera, zoomed substantially farther back than early image attempts (at least ~2× farther per user direction), enough world visible to demonstrate scale. True ARPG HUD with HP/mana, five skills, objective, minimap, enemies, and plausible on-screen combat. Clearly call generated composites “concepts,” never captured gameplay.

**UI/UX:** original, consistent premium dark fantasy art language. Ornate black/iron/gold borders, readable contrast, premium type hierarchy, clean interaction, dynamic health/mana orbs, XP/Renown tracking, quest panels, inventory with correct item footprint grids, spellbook with true spell stats and icon art, graphical WoW-like talents, Last Epoch-like *per-active-skill* heroic trees, cinematic character creation, and a title screen. Strong visual hierarchy and accessibility; no static mockup masquerading as implemented UI.

## 4. Story and world canon

**User-approved core:** A lost era's civilization (provisionally Aurelian) built the **Chronicle Engine**, which repeatedly restarts or rewrites epochs in an attempt to avert disaster. Whole histories are erased from current reality but **not annihilated**. Their survivors, eras and futures accumulate outside consensual reality as **The Unwritten** and try to return. Some are dangerous; some are displaced or tragic. The Engine's great evil may be the harm caused by its own resets, rather than an outside demon. This is a carefully paced late-campaign reveal.

**The ruined cathedral encounter** beneath Crownsfall is user-endorsed. The player kills a violet-glowing monstrous figure in damaged royal armor; **unexpected Lorecasting** reveals the being was a royal guard long ago with family, name, home, and a shattered world. The reveal should humanize a supposed monster and shift player understanding of the Unwritten. Names sometimes suggested—Ser Caldrin Vael, Elara, Lys and Elyndor—are **provisional assistant proposals**.

**Crownsfall was itself once part of The Unwritten**, also explicitly liked. The city may be stitched from multiple erased civilizations. Old and new architecture/statues gradually reveal inconsistencies; epochs may overlap during major story beats. The bright, safe city atop terrible history is essential emotional contrast.

**Lorecasting** is a major gameplay progression mechanism: discover lost accounts through people, places, objects, ruins and relics; reveal hidden routes, re-manifest fragments of past worlds, restore transient objects, unlock forgotten spell variants/techniques and unusual rare epoch dungeons. The **rare dungeon's appearance/location is itself the discovery reward**, not just a random rare creature.

**Tentative narrative extensions:** The Aurelian Concord, The Sundering, the First Anchor, The Between, Remnant Court, Hollow Choir, Keepers of Names, Last Curator, multi-act campaign, and an earned third ending are promising design proposals, not locked canon. Keep the player free to choose origin/name; do not impose a compulsory chosen-one identity.

**Enemy factions and locations:** Crownsfall (starter city), Greenwood Marches (wilds), Undercroft (dark dungeon), Reality Scars (rare anomaly dungeons), the Veyr (temporal civilization) with Phasewalkers, Timekeepers, Archivists, Echo Wardens, Riftbinders, Epoch Sentinels and the Meridian boss. Bandits, wolves, and normal regional fauna coexist with temporal threats. Each enemy should ultimately have its own silhouette, animation, spells/attack telegraphs, health bar, behavior and loot, not just recolors.

## 5. Playable systems: mandatory principles

**Stats:** Strength, Dexterity, **Vitality** (not Constitution), Intelligence, Wisdom, Charisma. Derived stats include armor, crit chance/damage, mana/stamina, attack speed, resistances, and Renown. XP, gold, health/resource indicators and achievements/discoveries should be visible in an approachable ARPG HUD.

**Character creation:** Player selects a starting class and chosen name. Previews all base spells, future level-20 paths, level-40 heroic paths, talent and skill trees **at level 1**, but cannot invest in locked paths. Names follow the user-chosen value everywhere; **Ixll** is only internal code/QA shorthand. Class choice should feel as polished as a WoW or PoE character screen but remain original.

**Skillbook / Grimoire:** Open book-style screen with tabs for Spellbook, Talent Tree, Heroic Skills; inspect known/future abilities, custom icons, effects, mana, cooldowns, requirements, mechanics, and evolution. Spellbook may list more spells than active bar. The live prototype previously advertised **124 spell entries** (including advanced *codex previews*, not necessarily playable mechanics). A future spell is not automatically an implemented cast action.

**Five equipped active abilities:** One shared five-slot action bar. Abilities selected from base class, level-20 specialization, and level-40 heroic path. At level 40 a player can “heroic” a chosen active ability and invest in an individual talent graph à la Last Epoch. Build investments should be tied to **stable ability IDs**, not hotbar positions; earlier code needed a migration from slot-based records. Chosen talents, weapons/armor/resources, and active skills define class identity; don't give every class an unexplained automatic “signature passive.”

**Mage:** Level 1 Mage → Level 20 **Fire / Frost / Arcane** → Level 40 heroic progression, with **Arcane → Chronomancer** preserved. **Ashen Ward → Ember Aura** is a major desired transformation: a once-defensive/restorative skill can become a persistent, mana-draining **burning aura**, with mutually exclusive branches **Cinder Bloom** (better burning/radius) and **Siphon Embers** (life gained from burning damage). This should combine with rare loot (Band of Continuance, Crownless set, Emberwake Circlet, Riftglass Focus) to create build-defining synergies. Some old README files describe “Sustaining Aura” as healing; this was **superseded by Ember Aura as passive burn**. Never revert it silently.

**Loot:** Diablo II / PoE style variable-size grid inventory. Important layout: helm 2×2, chest 2×3, tall weapon/offhand slots flanking torso slot, **two ring slots and one amulet**, gloves/belt/boots beneath; item footprints such as 1×1 jewelry, 1×3 sword, 2×3 armor, 2×4 staff. No extra portrait occupying the equipment layout. Items have rarity/affix/stat comparisons, uniques, sets with multi-piece bonuses, boss-specific drops and meaningful visual treatments. Rarity colors should be legible and consistent.

**Movement and combat feel:** The user repeatedly stated sprites “look like the legs aren't moving.” Existing synthesized 8-frame sprites helped but do not meet the desired standard: real leg articulation, grounded foot planting, proper walk/run/idle, natural cloak/weapon motion, 8-way transitions, attack anticipation/contact/follow-through/recovery, dodges, hit reactions and spellcasting synced to projectiles. Movement quality outranks expanding the world prematurely. A high-end PC target means do not compromise visual quality preemptively for iPhone.

**World:** Interconnected continent map, region maps, city layouts and mini-map aligned by common physical landmark IDs. Regions should have grounded navigation, fog/discovery, rich interiors, persistent quests and reputation, rare anomaly dungeons, dynamic NPCs and modern ARPG combat UI. The early 2048×2048 city scene is a **resampled concept painting**, not proof of native-resolution layered production art.

## 6. The 13-class design direction (V4)

*The following is the later design-bible roster. Names and exact ability trees are provisional until tested; the current 4-class prototype does NOT implement all thirteen.*

| Starting class | Armor | Three level-20 paths | Corresponding level-40 heroic identities |
|---|---|---|---|
| Warrior | Plate | Weaponmaster / Bastion Guard / Berserker | Bladestorm Paragon / Citadel Sentinel / Bloodbound Warlord |
| Mage | Cloth | Fire / Frost / Arcane | Pyromancer / Glacial Sovereign / Chronomancer |
| Rogue | Leather | Assassin / Trickster / Duelist | Night Reaper / Phantom Jester / Blade Virtuoso |
| Druid | Leather | Grove Warden / Shapeshifter / Stormspeaker | Worldroot Guardian / Primal Avatar / Tempest Sage |
| Ranger | Mail | Deadeye / Beastkeeper / Trapper | Starshot / Wildbond Alpha / Briar Architect |
| Oathkeeper | Plate | Dawn Vanguard / Aegis Keeper / Ashen Inquisitor | Sunward Justiciar / Hallowed Bastion / Cinder Arbiter |
| Spiritcaller | Mail | Tempest / Earthkeeper / Ancestor | Storm Herald / Worldshaper / Echobound Sage |
| Oracle | Cloth | Luminary / Veil Shepherd / Mindweaver | Dawn Saint / Soul Shepherd / Dream Architect |
| Hexbinder | Cloth | Infernal Binder / Plague Hexer / Void Scholar | Hellchain Sovereign / Rot Covenant / Abyss Archivist |
| Disciple | Leather | Iron Fist / Flowkeeper / Mist Dancer | Mountain Hand / Everflow Master / Veilrunner |
| Graveknight | Plate | Bloodbound / Frost Warden / Bonecaller | Sanguine Dreadlord / Winter Revenant / Ossuary Monarch |
| Riftblade | Leather | Voidblade / Riftstalker / Chaosbreaker | Eclipse Harbinger / Foldwalker / Ruin Sentinel |
| Aethercaller | Mail | Starflare / Prismcraft / Lifeward | Astral Herald / Prism Sovereign / Genesis Keeper |

**V4 details:** 13 base classes × 3 level-20 specialization branches = 39 advanced paths, each with a matching level-40 heroic evolution. In the playable prototype (historically) there were often **two alternative level-40 heroics per discipline**, which is different. Preserve the user's actual current design preference and ask for clarification only if these mechanics cannot be made compatible with the desired build, not as a routine interruption. Starting class is chosen at creation, and future paths can be browsed immediately.

## 7. Implemented prototype and interaction design

**Godot branch:** Godot 4.x, GDScript, main scene `res://scenes/Main.tscn`, data JSON, many UI scenes built programmatically, `Sprite2D`-based actors, Node2D/Camera2D, default 1440×900 desktop viewport, compatibility renderer. Legacy project header still names “Loop 5 Veyr Revision” even inside the latest Combat Impact ZIP; the ZIP's **changelog and actual file contents**, not config title, establish that later update.

**Zones/systems seen in project files:** Crownsfall plaza, Greenwood, Undercroft; continental atlas/minimap; early NPC quests/merchant/chronicle; loot and equipment; four base classes with spell bars; UI for class creation, Grimoire, talent trees and heroic masteries; saved character state; Veyr and other enemies; boss prototype; original audio cues.

**Typical controls** (verify by reading latest input handling): WASD move, mouse click/hold to navigate, Shift run, Space dodge, F attack, 1–5 equipped active skills, Q flask, I inventory, C character, T talents, M world map, K Grimoire, L five-skill loadout, B Explorer’s Chronicle, E interact. Some builds use N for day/night inspection. Don't assume every shortcut works across all snapshots.

**Godot known errors fixed historically:** invalid `class_name` loop variable in `character_creation.gd` prevented Alpha 0.9.6 from loading; renamed in 0.9.6.1. Earlier GDScript inference problems included `next_x`, `next_y`, and `at`; earlier player spawn collided with scenery. Name shadowing / integer division warnings were separate from parser errors. Always use the **first compiler error**, not its cascade, for diagnosis. Check project imports before declaring a ZIP playable.

**Asset truthfulness:** Many class/emblem, UI, scenery and enemy previews were made from procedural art or composites. New image assets do not imply unique rigged animation or full AI. Early enemies were tinted/recolored Hollowling silhouettes; they still require independently authored anatomy and attacks. AI-generated images or static concept comps are **not** screenshots of the playable game. Better preproduction art must translate into actual mesh, shader, sprite, animation and UI systems.

## 8. Latest known builds, chronological summary

**This is a high-level digest of the conversation, NOT a verbatim chat transcript.** Dates are October–November 2026. Earlier prototype builds are superseded in many ways; do not install every ZIP in sequence unless investigating a regression.

| Approx. milestone | Reported change / user response | Validation / caution |
|---|---|---|
| Alpha 0.8–0.8.5 | Godot native PC alpha, movement/spawn parser fixes, inventory/equipment slots and item grid | Iterative user testing; some failures were corrected |
| 0.8.6–0.8.8 | Character walk sprites, less chibi proportions, initial class paths, level-1 browsing of all disciplines/heroes | Animated source often only four poses, synthesized frames; quality below user target |
| 0.8.9–0.9.3 | Character creation, XP/Renown HUD, talent atlas, five heroic trees, Ember Aura, enemies, 124-entry spell codex, three-panel Grimoire | Many advanced spells **preview-only**; testing per build not guaranteed |
| 0.9.4–0.9.7 | Enemy/NPC variants, movement polish, eight-way walk/run, 0.9.6 parser hotfix, stronger leg-stride experiment | User confirmed 0.9.6.1 launched, but still criticized static-looking legs |
| 0.9.8 / first phases 1–7 | Royal UI art foundation, connected talent nodes, city atmosphere, enemy attack windup, five-slot loadout, Ember Aura branches, unique items, Veyr Echo Warden | Snapshots produced; many were static-checked only |
| First phases 8–10 + redux | Explorer Chronicle, NPC quests, cinematic title screen, intro settings, first movement/HUD redux | User explicitly loved the title screen |
| Loop 2 phases 1–3 | Hero animation rebuild, combat polish, Royal HUD with orbs, skillbar, XP / statuses | **User confirmed Loop 2 Phase 3 ran great** |
| Loop 2 phases 4–7 | Spell elemental identity, Crownsfall visual deepening, cinematic class creation, illustrated class path atlas | User later said the project worked well, but every subsequent ZIP needs testing |
| Loop 2 phases 8–15 | Ember Aura art, Veyr Riftbinder, unique loot, slot-independent skill logic, Meridian boss, audio, chronicle, integration | Static test candidates |
| Loops 3–5 | Eight elemental school sigils and aimed attack FX; forty class-path emblems; Veyr Epoch Sentinel and Meridian boss HUD stages | Three cumulative checkpoints, **not** 45 fully executed phases |
| **Nov 10 Combat Impact Pass** | **0.16s melee contact windup**, short casting anticipation, projectile impact timing, enemy recoil/stun, physical sparks, separate steel/magic impact SFX | Latest inspectable Godot ZIP in this conversation; **Godot runtime playtest not confirmed** |

**Latest available package:** `Age_of_the_Lost_Combat_Impact_Pass.zip`, approximately **155.8 MB**, containing `project.godot`, GDScript, game data, scene, art, previews, QA files and README. Its archive was verified readable at preparation time (807 entries; no ZIP corruption). **SHA-256:** `8cded6247f2dbe4dc9e9cd3e42232159eeb8bd8accb037a58ef5c0f68adb1230`.

**Source folder layout (example):** `scripts/game.gd`, `actor.gd`, `enemy.gd`, `progression.gd`, `talent_screen.gd`, `spell_codex.gd`, `character_creation.gd`, `hud.gd`, `loot.gd`, `navigation.gd`, `atlas_screen.gd`; `scenes/Main.tscn`; `data/spell_codex.json` and atlas/world JSON; `assets/actors`, `ui`, `talents`, `spell_icons`, `maps`, `items`; `docs/`; tests/tools. File names can shift by revision—verify the actual ZIP.

**What changed in the latest Combat Impact Pass (verified from its README/changelog):** melee damage resolves after a **0.16-second windup** (can miss as enemy moves), area spells/defense/spells release after a **0.16-second casting gesture**, projectiles deal damage on arrival, enemies recoil directionally and can enter short hitstun, heavy attacks interrupt windups, physical slash sparks are directional, steel and magical impact audio differ. This is genuine code-level timing work but should not yet be described as AAA final animation.

## 9. Known bugs, gaps and major production risks

- **No confirmed headless Godot editor validation in the latest assistant environment** despite earlier intention to use a user-uploaded Linux x86_64 binary. Static JSON/resource/ZIP tests help but cannot prove parser/runtime success. The receiving AI should run an installed compatible Godot 4 editor and a real playtest.
- Movement still relies partly on sprite warps and synthesized in-betweens; legs, arms, cloak, and weight shifts must become fully authored animation or genuinely rigged 3D. Synchronize foot plants and contacts with collision, sound, hit frames and VFX.
- Not all 124 codex spell entries or later class heroics are implemented as unique playable effects. V4 13 classes are broader design targets, not present in the runnable four-class prototype.
- Original 2D/2.5D game and subsequent 3D Blender branch have not been proven integrated into a single production-quality build. Prefer a deliberate technical decision and staged migration, not incompatible asset additions.
- Early Crownsfall image and zone maps were flat/raster/procedural prototypes; layered environments, geometry, occlusion, light, terrain and navigation are not final.
- Some class-path naming differs across versions; V4 is later strategic architecture, but older code has game-specific heroic variants. Audit before changing save schema.
- Mastery-by-ability identity migration has received improvements but must be regression-tested across rearranged hotbars, save/load, transformed spells and unique item effects.
- Enemy families still need truly distinctive animation/rig, movement/AI, telegraphs and loot. Bosses are prototypes, not fully cinematic set pieces.
- Actual performance budgets, 1440×900 scaling, higher resolutions, controller/UI accessibility, export pipelines, audio mixing and iPhone optimization remain production tasks.
- **Avoid making claims of automatic background work.** The user repeatedly asked for hour-long/1,000-cycle autonomous development; actual work occurs in active tool sessions, and ongoing work must be described accurately.

## 10. Planning cadence: 15 phases, 960 + 1,000 passes

The user set a **15-phase quality loop** and repeatedly enlarged the roadmap. The latest long-term target was **960 planned phase passes** (64 cycles × 15 phases) plus **at least 1,000 extra retrospective revisions** revisiting earlier work. These are **aspirational targets and tracking goals**, not thousands of completed autonomous revisions. Only count a pass when there is a concrete change, verification, and recorded outcome. User expects frequent actual playable builds, progress images/GIFs and meaningful before/after improvements.

| Phase | Recurring focus |
|---|---|
| 1 | Hero animation: real walk/run/turn/cast/melee/evade, foot planting and equipment motion |
| 2 | Combat feel: anticipation, hit timing, impact, enemy response, telegraphs and audio |
| 3 | HUD and UI: health/mana, five skills, XP/Renown, buffs, minimap, legibility |
| 4 | Spell FX / element identities: fire, frost, arcane, shadow, nature, storm, physical |
| 5 | Crownsfall visual depth, geometry, lighting, interiors, NPC life |
| 6 | Cinematic character creation with class and future-build previews |
| 7 | True illustrated, branching, investable talent trees |
| 8 | Ability-specific heroic trees and transformative alternate skills |
| 9 | Distinct regional enemy silhouettes, animation, AI and loot |
| 10 | Legendary/set item and premium inventory UI art |
| 11 | Distinct class combat resources and animations; correctness of skill swaps |
| 12 | Boss encounters: multi-stage, strong telegraphs, meaningful rewards |
| 13 | Original sound/music, mix, VFX synchronization and UI feedback |
| 14 | Exploration: atlas, landmarks, Lorecasting, chronicle, world cohesion |
| 15 | Full integration, save/load regressions, performance, polish, Windows build |

**Process motto:** **REFINE. ADAPT. PROGRESS.** Maintain quality of **graphics, animation, movement, combat and UI in every loop**; do not use the phase names as an excuse to ignore obvious defects. Design high-end PC assets first and plan iPhone scaling/portability later.

## 11. Specific requests and direct conversation milestones

- **Oct 13, 04:45 UTC:** integrate animated sprites and **make them less chibi**.
- **Oct 13, ~05:00 UTC:** user asked for four starting classes (Mage, Rogue, Druid, Warrior), level-20 Fire/Frost/Arcane Mage, and level-40 Chronomancer path; WoW/PoE-style creation, XP, reputation and resource HUD; view future trees from level 1.
- **Oct 13, ~05:20 UTC:** user requested unique/legendary/set item synergies and transformative skills; renamed defensive “Sustaining Aura” concept to **Ember Aura**, a passive burning aura; temporal ancient Veyr enemies and distinct regional drops/HP/AI.
- **Oct 13, ~05:30 UTC:** user wanted complete spellbook with icons/stats, class-themed backgrounds, linked talent and heroic skill panels à la WoW/Last Epoch.
- **Oct 13, ~06:00 UTC:** user demanded **organic full-body animation** comparable in fluidity to Diablo/Ragnarok Online, not static sprites with sliding feet; prioritize movement/AAA art over world size.
- **Oct 13, ~06:20 UTC:** premium dark-fantasy UI/UX for HUD, character, Grimoire, inventory and creation; “real” branching illustrated trees; class and enemy asset addition every patch.
- **Oct 13, ~06:35–07:20 UTC:** many cumulative prototype phases, title screen, city atmosphere, combat/loot/quests/chronicle; user liked the new cinematic title screen; insisted on high-end PC quality before iPhone port.
- **Oct 13, ~07:25–08:15 UTC:** expanded plan to iterative 15-phase cycles, then 480, then 960 planned passes; strong “REFINE. ADAPT. PROGRESS.” principle and **Ixll is internal-only**.
- **Oct 13, ~08:45–09:45 UTC:** cinematic character creation, improved talent atlas, heroic trees, Loop 2 Phase 15 and Loops 3–5 cumulative builds; user repeatedly approved direction and asked for stronger animation and combat.
- **Nov 10:** explicit request for **weighty swords and spells**, realistic target impacts and properly synced skill animation; latest **Combat Impact Pass** created, code/ZIP checks passed, Windows runtime verification pending.
- **Separate newer class-art conversations (Oct 14–21 and Nov):** six locked visuals, **13 base class V4 design**, large non-human class concept library, and later skinned 3D models. These later decisions supersede older four-only design intent but do not retroactively rewrite the 2D prototype implementation.

## 12. Files and assets that should be handed to the next AI

**Essential:** the latest actual game package `Age_of_the_Lost_Combat_Impact_Pass.zip` (the receiving AI needs the file itself), plus the **six approved original visual canon images**. If continuing model/3D work, include latest **Royal Wayfarer Blender/GLB** and **Crownsfall Courtyard** packages. Older build ZIPs are optional debugging checkpoints.

**Important design sources:** `AOTL_Class_Design_Bible_V4_110_Concepts.docx` (13-class architecture plus archive of 110 art concepts); `AOTL_Conversation_Handoff_Nov2026.md` (archived design/lore handoff); optional V3 quick reference and original full-size art ZIP. A long series of earlier user-facing ZIP links may not work from a different model/session; upload the actual bytes rather than relying on sandbox paths.

**Suggested project transfer order:**

1. This handoff Markdown (for retrieval, search, copy/paste) or combined DOCX.
2. Latest actual Godot project ZIP.
3. Class Bible V4 and approved six-image canonical art.
4. Blender/GLB work and any user-approved 3D screenshots/previews.
5. Optional personal preferences memory appendix only if the user wishes to transfer it.

**Known next step for an engine-focused model:** load actual Combat Impact Pass into Godot, verify all parser/resource issues, capture before/after movement/combat footage, build a rigged animation plan, and deliver a working code + art patch while preserving saves and class names. **Do not claim this was done solely because it is on the roadmap.**

## 13. Communication and delivery preferences

The user prefers **natural, warm, familiar but not overdone** conversation. Some understated sarcasm and early-2000s humor (CKY, Jackass, Viva La Bam vibe) is welcome. Avoid incessant “bro,” “brotha,” “ayyy,” hype clichés or false intimacy. They value energetic collaboration, direct action, high standards, rich artwork, and autonomous completion of ordinary tasks without repeatedly asking permission. User often tests Windows builds and reports exact first parser error; give concrete, reproducible instructions and respect corrections.

Each meaningful build should include: source project (not just screenshots), correct asset/scene integration, specific improvements, install/test steps, actual status of validation, before/after visuals or playable GIF when useful, and a changelog. Do not present aspirational “AAA” quality as accomplished just because a concept image is beautiful. Never claim to run one-hour background work when no tool supports it. Do not assume user wants unapproved features or that large pass targets imply completed work.


---

## Appendix A — Earlier complete AOTL design and art handoff (archived reference)

The following is an archived project handoff prepared for an earlier branch of the design discussion. It contains valuable lore, concept names, and visual requirements. **Its “latest pending request” and code-status claims are historical, and are superseded by the newer November 10 status and the actual files you transfer.**

# Archived AOTL handoff (prior snapshot)
**Prepared:** November 10, 2026  
**Purpose:** Paste this into another model to continue game development, art direction, lore, and class design without losing established decisions.  
**Status:** An evolving game-development project. Distinguish user-approved canon, approved visual references, provisional designs, and unfinished work.

## 1. Project overview
*Age of the Lost* is a high-fantasy action RPG intended for PC first, with a potential mobile port later. It uses Godot for gameplay and Blender for models/rigging. Inspirations include the combat readability and progression of Diablo/Path of Exile/Last Epoch, the responsiveness of Hades, and anime-fantasy character styling (e.g. human proportions and expressive faces rather than chibi). It should have substantial character creation, ARPG loot, a configurable five-active-skill bar, equipment, talent trees, advanced class specializations, rare dungeons, and deep exploration-driven storytelling.

The game's artistic contrast is essential: **Crownsfall** is a vibrant, charming, bright white-stone fantasy city with royal-blue/gold banners, flowers, ornate fountains, greenery, grand cathedrals and complex architecture; beneath it lies an increasingly grim, demonic, void-touched, temporally fractured world. Do not homogenize every setting into blue-and-gold Crownsfall. Alternate atmospheres, eras, locations, factions, and palettes.

## 2. Locked visual baseline and presentation rules
The user approved **six canonical reference artworks** in October 2026: three character concept sheets (Mage, Rogue, Mail-Wearer) and three Crownsfall environment paintings (market/cathedral plaza, royal square, citadel). They are the visual north star. Reference files, if available to transfer:
- `AOTL_Official_Art_Large_View_Oct2026/01_Mage_Official.png` through `06_Crownsfall_Citadel_Official.png`
- `AOTL_Six_Official_Canon_Art_Originals.zip` / `AOTL_Official_Six_Full_Size_Images_Fresh_Download.zip`

Character art formula: a **single, individually named polished class concept sheet** per image, not a dense collage or roster poster. Large full-body character portrait on left (fully visible, clear silhouette); ornate dark/black-and-gold panel on right with front/side/back studies, combat poses or spell VFX, face/armor/weapon closeups, palette/insignia, and a small in-world setting study. Include the **class name clearly and legibly within the picture**, with race and correct armor type. Preserve painterly, richly detailed anime fantasy rendering; realistic adult body proportions, elegant armor and textile details, tasteful high fantasy. Avoid clipping, malformed limbs, extra fingers, floaty unconnected gear, gibberish typography, mismatched anatomy, duplicate views, and obviously AI-generated visual artifacts. If a render is flawed, revise it before counting it as a finished class.

The user especially likes **genuinely non-human, radically varied silhouettes**: faceless black void under a hood, ghostly energy with no legs, crystalline beings, skeletal/bone races, plant/root beings, insectoid creatures, living machines, aquatic creatures, demons and temporal anomalies. Do NOT merely change a human face's skin color. Avoid furry/cat-person player-race designs. A key reference was a hooded, black-faced/empty-hood armored angelic entity with pale blue energy wings; adapt the concept into original AOTL art, do not copy its exact design.

**Gameplay mockup requirement:** For every batch of ten artwork deliverables, generate **nine individual named class sheets and a tenth separate gameplay scene** featuring one of the classes. The gameplay image should resemble a plausible *Diablo/Path of Exile* ARPG screenshot: very zoomed out (at least **2× farther away** than earlier attempts), **steep three-quarter/high isometric camera angle**, characters and enemies small relative to substantial visible world, believable spell silhouettes, architecture, readable action and real HUD: health/resource orbs, five skills, enemy health, objective text, minimap, inventory/utility elements. In the last request, user emphasized **even more zoom out**, and **no weird clipping or AI-looking artifacts**. Label images gameplay *concepts*, not actual Godot screenshots unless they truly are playable captures.

## 3. Current player/class system (strong current design direction)
The user explicitly replaced the original four-base-class-only system with **13 selectable base classes**, analogous in breadth to World of Warcraft but with AOTL names and originality. Three specializations at **level 20** per class, evolving into distinct **level-40 heroic identities** = **39 specialization paths and 39 heroic identities**. **Five active skills** define each kit. **No automatic, standalone 'signature class passive'**. Talents and skill enhancements may provide passive effects as selected choices, but class identity must primarily arise from active abilities, weapon/armor gameplay, chosen talents, resources and specialization. Race is distinct from class; don't treat every visual concept as a 14th/100th base class.

**13 classes and progression paths** (copied from existing V3 quick reference):

| Base class | Armor | Level-20 specialization → Level-40 heroic identity |
|---|---|---|
| Warrior | Plate | Weaponmaster → Bladestorm Paragon; Bastion Guard → Citadel Sentinel; Berserker → Bloodbound Warlord |
| Mage | Cloth | Fire → Pyromancer; Frost → Glacial Sovereign; Arcane → Chronomancer |
| Rogue | Leather | Assassin → Night Reaper; Trickster → Phantom Jester; Duelist → Blade Virtuoso |
| Druid | Leather | Grove Warden → Worldroot Guardian; Shapeshifter → Primal Avatar; Stormspeaker → Tempest Sage |
| Ranger | Mail | Deadeye → Starshot; Beastkeeper → Wildbond Alpha; Trapper → Briar Architect |
| Oathkeeper | Plate | Dawn Vanguard → Sunward Justiciar; Aegis Keeper → Hallowed Bastion; Ashen Inquisitor → Cinder Arbiter |
| Spiritcaller | Mail | Tempest → Storm Herald; Earthkeeper → Worldshaper; Ancestor → Echobound Sage |
| Oracle | Cloth | Luminary → Dawn Saint; Veil Shepherd → Soul Shepherd; Mindweaver → Dream Architect |
| Hexbinder | Cloth | Infernal Binder → Hellchain Sovereign; Plague Hexer → Rot Covenant; Void Scholar → Abyss Archivist |
| Disciple | Leather | Iron Fist → Mountain Hand; Flowkeeper → Everflow Master; Mist Dancer → Veilrunner |
| Graveknight | Plate | Bloodbound → Sanguine Dreadlord; Frost Warden → Winter Revenant; Bonecaller → Ossuary Monarch |
| Riftblade | Leather | Voidblade → Eclipse Harbinger; Riftstalker → Foldwalker; Chaosbreaker → Ruin Sentinel |
| Aethercaller | Mail | Starflare → Astral Herald; Prismcraft → Prism Sovereign; Lifeward → Genesis Keeper |

Mage's Fire/Frost/Arcane path, particularly **Arcane → Chronomancer**, should remain intact. The broader class design includes class-specific spell names, talent-node choices and skill upgrades, not just cosmetic distinctions. Existing full files: `AOTL_13_Base_Classes_Quick_Reference.md`, `AOTL_Class_Design_Bible_V3_13_Base_Classes.docx`, and `AOTL_Class_Design_Bible_V4_110_Concepts.docx`. The V4 codex catalogs 110 character concepts, not 110 playable base classes. Earlier codices (`AOTL_Master_Class_Codex_100_Entries`, `AOTL_Complete_Class_Skills_Talents_Specializations_v2`) included automatic passives; **V3/V4 and the user's later explicit direction take precedence**.

Other established systems: Strength, Dexterity, Vitality, Intelligence, Wisdom, Charisma; derived combat properties such as armor, resistances, crit, stamina/mana. Player-chosen name during character creation; **Ixll** is only an internal protagonist development codename, not required canon. Inventory UI draws from Diablo/PoE with grid equipment, dual rings/amulet and variable-sized items. Skill trees should meaningfully transform abilities with upgraded VFX, mechanics, and rare Lorecasting discoveries, rather than just numerical buffs.

## 4. Narrative — strongly favored user-approved pillars
**Central premise:** Long before current Crownsfall, an Atlantis-like Aurelian civilization reached extraordinary heights in arcane science, temporal manipulation and memory. It made the **Chronicle Engine**, a mechanism intended to avoid catastrophic futures by ending/restarting epochs. It malfunctioned and eventually repeatedly rewrote history. Thousands of years later, ordinary civilization has mostly forgotten the truth, while temporal anomalies leak through the present.

**The Unwritten** is the most important late-game reveal, explicitly and enthusiastically approved by user: erased people, cities, civilizations, futures and whole timelines **were not destroyed**. They accumulated beyond consensual reality and are attempting to return. The Chronicle Engine is not protecting the current world from an unrelated outside evil; it is attempting to contain **the consequences of its own resets**. Unwritten creatures can seem demonic/void-born/monstrous but may be innocent displaced people, desperate survivors, hostile claimants or minds eroded by millennia. Do not make all unfamiliar creatures inherently evil. Preserve the distinction: *The monsters may not be invading our world; they may be trying to return to theirs.*

**Ruined cathedral / guard reveal**, explicitly liked by user: player descends beneath Crownsfall into a forgotten cathedral, fights a deformed violet-glowing monster wearing scraps of ancient royal armor, then unexpectedly triggers Lorecasting after battle. The memory reveals the monster was a royal guard thousands of years before, with family, home and a real name, whose epoch was erased. He waited/fought for thousands of years trying to return. This should initially be a mysterious, emotionally poignant encounter—not an immediate exposition dump. Later story development provisionally called the guard **Ser Caldrin Vael**, his wife **Elara**, daughter **Lys**, and city/kingdom **Elyndor**, approximately 3,700 years before present. Their specific names/timing are **assistant proposals**, not separately confirmed by user. Additional speculative continuation: Lys was reconstructed into a later epoch; her descendants helped found modern Crownsfall, making the guard's tragedy connect to the city above him.

**Crownsfall itself was once part of The Unwritten**, also explicitly liked by user. Present-day Crownsfall may be stitched together from fragments of several erased civilizations. Cathedrals, plazas, roads, statues and perhaps people originate in different epochs. A familiar statue in the buried cathedral might match a modern Crownsfall statue but bear another name; this is a perfect gradual clue. Crownsfall should quietly mutate and 'remember' older architecture, language, inscriptions and residents as the story progresses. Eventually a city-wide temporal anomaly reveals overlapping historical versions of Crownsfall. Its warm sunny beauty intensifies the horror beneath.

**Lorecasting** is not just generic spellcasting. It uncovers and can briefly re-manifest forgotten historical truth from objects, locations, people, battles and equipment. Mechanically: reveal hidden histories/paths, restore objects to former states, unlock unique spells/skill variations and forgotten combat techniques, awaken relic equipment, discover rare epoch dungeons, affect NPC recognition. Discovery-driven magic unlocks are a defining progression loop. Rare dungeons are fragments of lost epochs temporarily surfacing as anomalies: finding the dungeon can be the rare reward, more than a special monster spawn.

## 5. Further narrative development (promising proposals; not all locked canon)
- Ancient supercivilization tentatively named **The Aurelian Concord**, originally 4,000–6,000 years before present; its catastrophic Engine activation called **The Sundering**. Multiple subsequent epochs and partial resets reshaped reality.
- **The First Anchor**, buried beneath Crownsfall, may predate even the Aurelians. Unlike the Engine, it preserves traces of anything supposedly erased. The Aurelians mistook its purpose and wired it into their reset machinery; Crownsfall is a recurring 'temporal anchor' location.
- **The Between** is a shattered nonordinary realm where remnants of erased histories live in discontinuous lands and patchwork civilizations. Identity deteriorates without memory/name anchoring; this partly explains monstrous distortion.
- Possible Unwritten factions: **The Remnant Court** (reclaim their historical world); **The Hollow Choir** (merge identities into collective); **The Keepers of Names** (preserve forgotten individuals, possibly sacrificing their own memories to recover names).
- **The Last Curator**, a surviving Aurelian Engine architect, can be a morally complex antagonist who believes resets are the lesser evil.
- Suggested five campaign acts: **Echoes Beneath Crownsfall → Kingdoms That Never Were → The Sunken Concord → The War of Forgotten Ages → The Last Epoch**. Gradual revelation, not a lore dump.
- Late choice: allow another Engine reset, destroy it and risk chaotic epoch merger, or discover a difficult 'third path' that preserves the present and restores the forgotten through extensive Lorecasting discovery. The third ending should be earned, not automatic.
- Player is NOT necessarily secretly a god or mandatory chosen one; one suggested explanation is survival of a temporal anomaly at the First Anchor. Player origin/race freedom matters. Alternative 'player repeatedly escaped being erased' is purely speculative.
- Theme: **To be forgotten is not to cease existing. It is to exist without a place in the world.** Another strong line: *The lost civilizations were never truly gone.*

## 6. Major character-art libraries and naming history
Over the session many individual artworks were generated (some were visual variants rather than separate game classes). The V4 catalog counted **110 concepts** before the very latest artistic wave. Preserve and audit names so subsequent designs aren't duplicates.

**Early canon / classic archetypes:** Mage, Rogue, royal Mail-Wearer (initial reference sheets); Orc Berserker; Undead Death Knight; Elven Ranger; Dwarven Templar; Gnome Artificer; Ethereal Spellblade; Temporal Chronomancer; Troll Shadow Hunter; Steam-Mech Warden; Alien Void Seer.

**Second early named wave:** Human Crimson Inquisitor; Moon Elf Bladedancer; Goblin Saboteur; Revenant Plague Alchemist; Crystalborn Geomancer; Dune Troll Spiritcaller; Deep Dwarf Forgecaller; Aetherborn Sky Corsair; Astral Gravity Lancer; Voidwalker Rift Monk.

**Other non-human concepts already depicted:** Mycelian Rotweaver, Glassbone Lichblade, Primborn Halo Sage, Deep Orc Mirecaller, Aether Wisp Oracle, Tideborn Abyss Lancer, Obsidian Scarab Juggernaut, Moonshade Moth Dancer, Clockwork Thunder Bastion, Stonewing Gargoyle Vindicator, plus ethereal Lightborn, Void/astral beings, trolls and bog shamans. Several visual and name variants appear elsewhere in the 100-entry codex.

**Darker class/image waves** (selected examples): Umbral Fen Ravager; Solaris Myrmidon; Grimcoil Ossuary Weaver; Verdant Hollow Warden; Cinder Djinn Reaver; Moonglass Harrier; Obsidian Beetle Colossus; Prism Tide Cantor; Rift Howler; Gothic Death Knight; Infernal Warlord; Ash Orc Doomblade; Infernal Cathedral Demoness; Moonlit Naga Assassin; Gargoyle Knight; Astral Void Seer; Fallen Angel; Infernal Djinn. The images include experimental HUD scenes, but earlier gameplay images were repeatedly judged **too close to the action**.

**Ten new concepts cataloged in V4 (numbers 101–110):**
1. Tallowgrave Wickwarden — candle-and-bone sentinel.
2. Threshold Keykeeper — sentient boundary / key-and-portal guardian, faceless hood.
3. Hollowvein Burrower — armored subterranean stone beast.
4. Vesperglass Mourner — shattered stained-glass entity.
5. Cairnwake Stagstrider — spectral stag-themed archer.
6. Eclipse Spindle Harrower — sinister thread/spindle manipulator.
7. Salt-Bloom Monolith — sea-salt/coral armored monolith.
8. Tidemarked Compass Phantom — drowned wayfinding spirit.
9. Aurelian Scrap Oracle — scavenged ancient-divination apparatus.
10. Cenotaph Kitewarden — memorial airborne/kite figure.

Originally V4 had silhouette placeholders and a Threshold Keykeeper distant-isometric gameplay study. User rejected placeholder quality as unlike six approved artworks; these ten were subsequently **re-rendered as richer AOTL concept sheets**. File names include `tallowgrave_wickwarden_concept_sheet.png`, `threshold_keykeeper_veilbound_guardian.png`, etc. NOTE: Images with the same name may have multiple revisions; always prioritize painterly re-renderings over placeholders.

**Nine subsequent named class art images + a tenth gameplay illustration:** Stormscale Dragoon; Moonreef Mistblade; Hollow Sun Arbiter; Briarthorn Fen Oracle; Glassbone Cataphract; Brasswing Bombardier; Thornveil Leshy Stalker; Star-Silk Chrysomancer; Riftmaw Harrowbeast. The tenth image portrayed **Hollow Sun Arbiter** in a high-isometric Crownsfall cathedral combat mockup with health/mana HUD, five skill icons, minimap and quest objectives. Some of these names or archetypes overlap earlier works (e.g. Moonreef / Thornveil); **deduplicate before declaring them brand-new**.

A separate ten-archetype *Forgotten Realms* design pitch included Hollow Halo Justiciar, Censerbound Requiem, Nullscript Hexscribe, Bloodglass Sanguinist, Dreadroot Mawkeeper, Lamentloom Marionettist, Gloamfin Harpooner, Chitin Blight Reaper, Knellforge Tollbringer, Mirrorfall Shardrunner. Detailed appearances, lore and five abilities were drafted in chat. These are proposals to map onto 13 base classes/specs, not automatically extra base classes.

## 7. Current pending request and quality bar
The **latest outstanding user request** (October 21, 2026) was: *'great work, do it again with new images and classes. Make sure there is no weird clipping or ai looking bits. Also make the gameplay image more zoomed out this time.'* A new batch after this message was **not yet delivered** in the transcript before the request for this handoff.

**What the next model should do next when asked to continue:** Produce another batch of **10 outputs**: nine *truly novel* race/class concept sheets (individual images, each legibly titled), plus one gameplay scene showing a chosen new class with the camera substantially farther back than all prior examples (steeper high-isometric 3/4 angle), and a convincing ARPG UI. Do not recycle prior character names or slightly recolor humans. Vary locales beyond Crownsfall into dark realms, ancient ruins, void fractured regions, swamps and forgotten epochs. Critically check framing, body proportions, hands/feet, armor intersections, accessories, VFX clipping, and legibility. Maintain the established AOTL painterly art identity, not glossy unrelated generic fantasy. Add vetted concepts with abilities, armor, race, level-20 spec and level-40 heroic path to the existing Bible **without changing the 13-base-class structure**. Only claim deliverables that were actually produced.

## 8. Tool, file, workflow preferences
The user is on Windows, uses **Godot and Blender**, and has tested playable builds; they want a production-quality 3D model of the AOTL visual canon, realistic articulated movement and Hades-like combat, not low-poly/1990s-looking prototypes. Fully articulated rigs, strong proportions, skinned animation, playable test builds and GIF movement/combat previews are valued when doing engine work. The user wants iterative autonomous execution without routine approval requests, but do not claim work continues in the background. If files are available, inspect the actual latest V4 class Bible and the original six canon art files before extending them. Do not mistake concept art for playable engine work or visual drafts for approved canon.

**Useful established file names:**
- `AOTL_Six_Official_Canon_Art_Originals.zip`
- `AOTL_Official_Art_Large_View_Oct2026/` (six original art pieces)
- `AOTL_13_Base_Classes_Quick_Reference.md`
- `AOTL_Class_Design_Bible_V3_13_Base_Classes.docx`
- `AOTL_Class_Design_Bible_V4_110_Concepts.docx`
- `AOTL_Complete_Class_Skills_Talents_Specializations_v2.md` (older; passive content superseded)
- Prior class and gameplay images under /mnt/data (transfer separately if the new environment has no access).

**Priority hierarchy:** (1) user-approved narrative twist and Crownsfall cathedral/stitched city; (2) six locked visual references; (3) latest 13-base-class/no-auto-passive five-skill system; (4) accurate nonduplicate class concept library; (5) newest art refinement requests; (6) optional speculative story twists and provisional names.
