# AOTL — Comprehensive Development Checklist

Version 1.0 • November 21, 2026 • Companion to the Visual Production and Development Handoff.

162 acceptance tasks across 24 workstreams. All boxes are intentionally unchecked pending evidence against the reconciled production baseline. Existing implementation may satisfy an item after verification; an unchecked box does not assert that the feature is absent. Conditional systems require either acceptance evidence or a recorded exclusion from release scope.

Priority: P0 foundation/high-risk proof; P1 slice or launch-critical; P2 later expansion/polish; C conditional. Gate labels G0–G7 and role ownership are defined in the handoff. Section dependencies apply to every item; add precise task IDs when scheduling. Use the CSV to assign people, milestones, status and evidence.

## BASE — Baseline, scope and product definition

Owner roles: Producer + technical lead. Priority: P0. Gate: G0. Depends on: None.

- [ ] **BASE-01 — Recover the exact accepted playable project and make an immutable backup**
  - Why: Branch names and screenshots cannot identify the build the user actually approved.
  - Complete when: Record commit or full file-hash manifest, entry scene, engine version, save sample and matching capture; test restoration.

- [ ] **BASE-02 — Map main, local, Drive and experimental branch ancestry**
  - Why: The Citadel, rig, art and dodge lines contain different features and assumptions.
  - Complete when: Publish a source-of-truth matrix with each branch head, dependency chain, approval status and integration destination.

- [ ] **BASE-03 — Define the launch promise and first vertical slice**
  - Why: PoE-like combat is a design target, not an affordable commitment to PoE's whole content catalog.
  - Complete when: One-page scope names launch features, exclusions, player audience, session loop and G2 slice; expansion ideas remain separate.

- [ ] **BASE-04 — Choose supported platforms, minimum hardware and input devices**
  - Why: Camera readability, renderer choice, texture budgets and UI depend on actual devices.
  - Complete when: Name CPU/GPU/RAM/storage/OS targets, minimum resolution, performance mode and mouse/keyboard/controller scope.

- [ ] **BASE-05 — Choose offline versus online authority before architecture hardens**
  - Why: Multiplayer changes saves, combat authority, economy and operations, not just the connection menu.
  - Complete when: Decision record selects offline single-player or a separately budgeted network scope and defines future migration limits.

- [ ] **BASE-06 — Establish a named decision log and source index**
  - Why: Contradictory hotkeys, camera estimates and duplicate latest documents cause rework.
  - Complete when: Every approved decision links its evidence and owner; estimates and draft art are labeled; repository and Doc versions agree.

## ART — Art direction and visual acceptance

Owner roles: Art director + technical artist. Priority: P0. Gate: G1. Depends on: BASE.

- [ ] **ART-01 — Create a canon board from approved AOTL references**
  - Why: External ARPG references explain readability; they do not replace AOTL's identity.
  - Complete when: Board separates approved hero, city, UI and skill references from unapproved studies and records permitted variation.

- [ ] **ART-02 — Define shape, palette, material and lighting rules per region**
  - Why: A consistent world needs more than a single grading filter.
  - Complete when: Art bible specifies silhouette families, value hierarchy, surface wear, focal contrast and warm hub versus hostile-area treatment.

- [ ] **ART-03 — Build a matched-camera comparison scene**
  - Why: Close-up model renders can hide weak gameplay silhouettes and feet.
  - Complete when: Capture identical actors, arch, stairs and light in candidate pipelines at 1080p/1440p, with movement and combat footage.

- [ ] **ART-04 — Set a visual review rubric and rejection examples**
  - Why: Words such as polished or less AI are too vague for production acceptance.
  - Complete when: Review checks clear edges, coherent anatomy, clean surfaces, intentional detail, distinct skills and no generic haze/grain or distorted ornament.

- [ ] **ART-05 — Approve representative hero, enemy, prop and skill assets before batches**
  - Why: Repeating an unapproved style scales rework.
  - Complete when: Each category has an accepted engine capture, editable master, import preset and documented time-to-acceptance.

- [ ] **ART-06 — Separate technical, visual and integration approval**
  - Why: Import success cannot certify animation quality or a live scene.
  - Complete when: Asset registry records all three statuses independently; unapproved candidates cannot silently become default runtime art.

## CAM — Camera, projection and screen composition

Owner roles: Technical artist + UI/UX owner. Priority: P0. Gate: G1. Depends on: BASE, ART.

- [ ] **CAM-01 — Calibrate projection from the supplied composition**
  - Why: Neither exact pitch nor focal length can be recovered uniquely from the image.
  - Complete when: Save a camera profile with measured actor screen height, pitch/yaw, projection, world scale and matched reference capture.

- [ ] **CAM-02 — Lock zoom, look-ahead, bounds and supported aspect policy**
  - Why: Wider views can expose unpainted edges or change combat visibility.
  - Complete when: Test all allowed zoom/aspect combinations at map edges; no uncovered scenery or inaccessible targets; reset is predictable.

- [ ] **CAM-03 — Make world picking and aiming use the same camera transform**
  - Why: A correct-looking cursor can still target the wrong ground position.
  - Complete when: Click/aim markers coincide with world targets through zoom, resize, elevation and UI scaling; invalid rays fail safely.

- [ ] **CAM-04 — Define occluder fade and camera obstruction rules**
  - Why: Players and warnings must remain visible behind architecture.
  - Complete when: Walk behind arches, trees and walls; fade/outline is stable, restores correctly and does not reveal unexplored gameplay incorrectly.

- [ ] **CAM-05 — Preserve readable actors, warnings and labels at default distance**
  - Why: Fine art details disappear at the chosen wide view.
  - Complete when: Review hero/enemy silhouettes, threat shapes, item labels and overhead bars at actual play size, including low-contrast scenes.

- [ ] **CAM-06 — Keep development overlays separate from shipping HUD**
  - Why: Debug checkboxes and pose strips consume the play field.
  - Complete when: Lab controls are toggleable and absent in release mode; no debug binding conflicts with production controls.

## WORLD — World geometry, navigation and spatial authority

Owner roles: Technical lead + level designer. Priority: P0. Gate: G1–G2. Depends on: BASE, CAM.

- [ ] **WORLD-01 — Choose and document one authoritative spatial simulation**
  - Why: Duplicate 2D and 3D controllers cause divergence, ghost collision and save defects.
  - Complete when: One owner updates position/hits/nav; any presentation bridge has tested forward/inverse transforms and elevation rules.

- [ ] **WORLD-02 — Build gameplay collision independently from painted detail**
  - Why: Attractive stones or railings do not automatically define traversable space.
  - Complete when: Navigation and collision match visible edges; no invisible walls, walk-through pillars or reachable decorative voids.

- [ ] **WORLD-03 — Specify floors, stairs, slopes, bridges and height-separated routes**
  - Why: A screen-space overlap is not enough to model two traversable elevations.
  - Complete when: Test ascent/descent, edge barriers, path choice, overhead routes, spawn heights and projectile elevation consistently.

- [ ] **WORLD-04 — Implement reliable navigation queries and crowd movement**
  - Why: Dense combat requires routes that remain valid around actors and doors.
  - Complete when: Paths update after obstacles/doors; enemies avoid permanent jams; startup/nav-ready races are covered.

- [ ] **WORLD-05 — Define depth sorting, transparent edges and shadows for mixed assets**
  - Why: Sprites and meshes can disagree about what is in front.
  - Complete when: Actors pass before/behind props at every supported direction; no sorting pops, halos, incorrect shadow planes or double shadows.

- [ ] **WORLD-06 — Define projectile and line-of-sight collision layers**
  - Why: Navigation passability and spell obstruction are different rules.
  - Complete when: Ground, walls, actors, friendly units, triggers and effects have documented masks with tests for each intended interaction.

- [ ] **WORLD-07 — Implement reliable transitions, spawn recovery and streaming seams**
  - Why: Players must not fall out of the world or lose state at a district boundary.
  - Complete when: Cross each exit both ways, reload near transitions and handle invalid saved positions with a safe canonical spawn.

## ENV — Environment asset and level production

Owner roles: Environment artist + level designer. Priority: P1. Gate: G2–G3. Depends on: ART, WORLD.

- [ ] **ENV-01 — Create a reusable modular architecture kit**
  - Why: A full city does not require uniquely sculpting every building.
  - Complete when: Kit includes aligned walls, roofs, arches, stairs, doors, trims and sockets with consistent scale/pivots and assembly examples.

- [ ] **ENV-02 — Model only the geometry needed for silhouettes, depth and interaction**
  - Why: Flat art is efficient at a distance; foreground structure needs convincing volume.
  - Complete when: Each environment asset records mesh/card/painted-layer choice, collision and depth requirements; the choice passes the camera test.

- [ ] **ENV-03 — Author painted surfaces without masking weak geometry**
  - Why: Noisy textures cannot repair blocky proportions or missing architecture.
  - Complete when: Review roofs, arches, door proportions and relief in flat lighting first; then approve texture/material treatment at gameplay scale.

- [ ] **ENV-04 — Split large painted scenery into maintainable regions and occluders**
  - Why: One giant plate is difficult to edit, stream and sort against actors.
  - Complete when: Source layers, seam overlap, tile/region boundaries and foreground masks are retained; movement shows no visible seams.

- [ ] **ENV-05 — Build a prop and dressing library with gameplay hierarchy**
  - Why: Dense detail can obscure paths, loot and attack warnings.
  - Complete when: Reusable lamps, banners, carts, foliage and debris have budgets; combat lanes and interactables remain visibly clear.

- [ ] **ENV-06 — Produce lighting, water, foliage and ambient motion selectively**
  - Why: Subtle motion creates life but excessive animation and particles compete with combat.
  - Complete when: Moving dressing is loop-safe, bounded and quality-scalable; collision/navigation does not drift with visual motion.

- [ ] **ENV-07 — Design levels around encounters, landmarks and return routes**
  - Why: Beautiful scenery alone does not create an engaging ARPG route.
  - Complete when: Blockout tests validate sightlines, chokepoints, retreat space, NPC access, exploration rewards and recognizable exits.

- [ ] **ENV-08 — Validate generated/procedural layouts if included**
  - Why: Random assembly can create unreachable objectives or unreadable scenes.
  - Complete when: Conditional generator tests many recorded seeds for connectivity, safe spawns, encounter spacing and art seams; otherwise mark authored-only.

## CHAR — Characters, enemies and visible equipment

Owner roles: Character artist + technical artist. Priority: P1. Gate: G1–G3. Depends on: ART, CAM, WORLD.

- [ ] **CHAR-01 — Create canonical character sheets and scale references**
  - Why: Identity must survive a new model or render method.
  - Complete when: Warrior/Mage sheets cover proportions, costume, handedness, emblems, face/hair and gameplay silhouette; approved art stays traceable.

- [ ] **CHAR-02 — Choose runtime representation by actor category**
  - Why: One universal method may overbuild NPCs or underbuild a gear-changing hero.
  - Complete when: Actor matrix states sprite, pre-rendered sprite or rigged mesh, with directions, actions, equipment and camera constraints.

- [ ] **CHAR-03 — Build clean topology, UVs and materials for rigged actors**
  - Why: Auto-generated geometry may import while deforming badly or wasting memory.
  - Complete when: Technical review checks joints, normals, UV overlap policy, texture density, materials, hidden surfaces and required LODs.

- [ ] **CHAR-04 — Define skeleton, rest pose, semantic bones and attachment sockets**
  - Why: Existing IK and hit tools cannot depend blindly on a new rig's bone names.
  - Complete when: Versioned mapping includes pelvis/feet/hands, weapon/shield, VFX anchors and optional cape/fingers; import rejects missing required mappings.

- [ ] **CHAR-05 — Design equipment families and body-fit rules**
  - Why: Inventory portraits do not produce wearable gear.
  - Complete when: Each supported body has verified weapon/armor attachments, hide masks, clipping rules and art for equipped/world-drop/UI appearances.

- [ ] **CHAR-06 — Validate armor, hands, cape and weapon deformation across actions**
  - Why: A good idle pose can conceal clipping during cast or roll.
  - Complete when: Inspect extreme frames and full motion; armor stays appropriately rigid, grip reads correctly and residual clipping is explicitly dispositioned.

- [ ] **CHAR-07 — Plan enemy families, silhouettes and shared rigs**
  - Why: Reusing a skeleton can save work without making every enemy visually identical.
  - Complete when: Family matrix separates melee/ranged/caster/boss roles through silhouette, scale, gait and attacks, with measured reuse limits.

- [ ] **CHAR-08 — Define corpse, death and despawn presentation**
  - Why: Death visuals affect readability, performance and loot visibility.
  - Complete when: Corpses settle on the correct surface, stop attacking, release targeting, expose loot and expire under documented limits.

## ANIM — Animation, locomotion and directional sprites

Owner roles: Animator + gameplay engineer. Priority: P0. Gate: G1–G2. Depends on: CHAR, WORLD.

- [ ] **ANIM-01 — Specify a complete action matrix for every playable actor**
  - Why: Missing transitions make otherwise good assets feel unfinished.
  - Complete when: Track idle, start/stop, walk/run, turns/strafe, attack, cast, dodge, hit, death, interaction and weapon variants; unused actions are scoped out.

- [ ] **ANIM-02 — Establish foot contact, stride speed and terrain adaptation**
  - Why: Sliding and floating immediately break the reference's grounded appearance.
  - Complete when: Review slow/fast movement, diagonals, stairs and stops; recorded contacts match travel and acceptable foot/ground error.

- [ ] **ANIM-03 — Choose root motion versus controller motion per action**
  - Why: Applying both can double movement or desynchronize combat.
  - Complete when: Action contract names movement authority; interrupt, low-frame-rate and collision tests show no drift or teleport.

- [ ] **ANIM-04 — Author anticipation, impact and recovery with gameplay events**
  - Why: ARPG weight comes from timing and readable commitment.
  - Complete when: Events align with contact/release, audio and VFX; timing remains correct across supported attack/cast-speed modifiers.

- [ ] **ANIM-05 — Implement animation blending, interrupts and recovery rules**
  - Why: Abrupt transitions or uncancellable states make input feel unreliable.
  - Complete when: State graph covers death, stun, roll, skill cancel, movement restart and pause; no stuck or impossible blended poses.

- [ ] **ANIM-06 — Set directional sprite export standards when sprites are used**
  - Why: Frame padding and inconsistent pivots cause visible popping.
  - Complete when: Define directions, mirroring exceptions, frame order, FPS, per-action bounds, foot pivot, light direction and atlas padding.

- [ ] **ANIM-07 — Validate sprite or retargeted motion frame by frame and in playback**
  - Why: Generated motion can drift in costume, anatomy, weapons or ground contact.
  - Complete when: Review loops, first/last frames, every facing and cross-action transitions; correct defects before runtime approval.

- [ ] **ANIM-08 — Test animation readability at the actual camera distance**
  - Why: A detailed animation may collapse into an unreadable blur at 120 pixels tall.
  - Complete when: Silhouette and attack direction remain recognizable in normal-speed play; add purposeful poses rather than global sharpening.

## COMBAT — Input, combat feel and hit resolution

Owner roles: Gameplay designer + gameplay engineer. Priority: P1. Gate: G2. Depends on: WORLD, ANIM.

- [ ] **COMBAT-01 — Specify input priority, buffering and repeat behavior**
  - Why: Responsive control requires explicit handling of overlapping actions.
  - Complete when: Test held attack, click movement, WASD, queued skills, pause and UI focus; record input-to-action timing at supported frame rates.

- [ ] **COMBAT-02 — Implement movement, collision sliding and targeting consistently**
  - Why: Movement must remain predictable around corners and enemies.
  - Complete when: Click and keyboard movement reach intended locations without oscillation; target lock/aim assists have clear acquisition and release rules.

- [ ] **COMBAT-03 — Define each attack's shape, range and validation time**
  - Why: A visually similar slash can have very different hit behavior.
  - Complete when: Data defines sweep/cone/projectile/AOE, active interval, line-of-sight and per-target repeat policy; debug geometry matches outcomes.

- [ ] **COMBAT-04 — Specify dodge, invulnerability, cooldown and cancel rules**
  - Why: A dodge is a combat mechanic, not only a roll animation.
  - Complete when: Tests cover blocked directions, active swings, resource states, pause/death, repeated input and exact protected/unprotected intervals.

- [ ] **COMBAT-05 — Make damage/status application stable under frame-rate variation**
  - Why: Dropped frames must not miss projectiles or apply a hit twice.
  - Complete when: Fixed simulation or swept queries resolve fast attacks; test low/high FPS, pause/resume and many simultaneous contacts.

- [ ] **COMBAT-06 — Add controlled hit feedback**
  - Why: Impacts need to be felt without obscuring play or causing discomfort.
  - Complete when: Combine reaction, sound, short VFX and optional shake/hit pause; accessibility settings reduce these independently.

- [ ] **COMBAT-07 — Define death, respawn and failure costs**
  - Why: Players need understandable recovery and consistent persistence.
  - Complete when: Death cancels attacks, releases targets, applies only approved penalties, restores a valid state and cannot duplicate items.

## SKILL — Skills, stats and build systems

Owner roles: Gameplay designer + gameplay engineer. Priority: P1. Gate: G2–G3. Depends on: COMBAT, BASE.

- [ ] **SKILL-01 — Create a stable skill registry and authoring schema**
  - Why: Hardcoded one-off spells do not scale or support safe saves.
  - Complete when: Each skill has a validated ID, tags, costs, timing, targeting, animation, effects, icon and localization references.

- [ ] **SKILL-02 — Specify all six AOTL attributes and derived statistics**
  - Why: Familiar names do not establish their actual mathematical effects.
  - Complete when: Document Strength, Dexterity, Vitality, Intelligence, Wisdom and Charisma contributions plus health, mana, armor, resistance and other implemented stats.

- [ ] **SKILL-03 — Define modifier order and stacking in one rules specification**
  - Why: Tooltip and combat disagreement undermines build decisions.
  - Complete when: Worked examples cover flat/additive/multiplicative terms, conversion, penetration, crit, resistance bounds, rounding and temporary modifiers.

- [ ] **SKILL-04 — Design level and gear scaling with explicit curves**
  - Why: Uncontrolled multipliers cause useless early items or runaway damage.
  - Complete when: Plot player/enemy health, damage, defense and resource costs across intended levels; test low/high gear and edge-case builds.

- [ ] **SKILL-05 — Define status effects, immunities and crowd-control limits**
  - Why: Ambiguous stacking produces stun locks and balance exploits.
  - Complete when: Specify duration, refresh/stack rules, ownership, cleanse, boss exceptions and visual indicators; tests cover overlapping sources.

- [ ] **SKILL-06 — Plan skill acquisition, mastery and respec rules**
  - Why: Progression needs understandable choices and recovery from mistakes.
  - Complete when: Unlocks, prerequisites, costs, reset behavior and saved state are documented and visible in UI.

- [ ] **SKILL-07 — Build a deterministic balance sandbox**
  - Why: Real tuning needs repeatable encounters and calculations.
  - Complete when: Seeded test scenarios compare time-to-kill, survival, resource sustain and build extremes; designer can change data without editing core code.

- [ ] **SKILL-08 — Reconcile displayed descriptions with actual rules**
  - Why: Accurate tooltips are essential in a gear-driven game.
  - Complete when: Tooltip values use the same evaluated stats as combat and identify conditional effects, cooldowns and unsupported calculations.

## AI — Enemy AI, bosses and encounters

Owner roles: Gameplay designer + gameplay engineer. Priority: P1. Gate: G2–G3. Depends on: COMBAT, SKILL, WORLD.

- [ ] **AI-01 — Build distinct enemy roles and readable intentions**
  - Why: Enemy variety comes from behavior, not only recolored models.
  - Complete when: Melee pursuer, ranged attacker and caster demonstrate different positioning, windup and counterplay in the slice.

- [ ] **AI-02 — Specify perception, aggro, leash and reset states**
  - Why: Broken pursuit can trap players or allow trivial exploits.
  - Complete when: Test occlusion, lost targets, unreachable players, returning home, boss reset and player death/teleport.

- [ ] **AI-03 — Implement crowd navigation and attack coordination**
  - Why: Dense packs become unfair when all actors occupy one point or attack simultaneously.
  - Complete when: Spawned groups maintain usable spacing, avoid permanent jams and obey encounter attack-pressure limits.

- [ ] **AI-04 — Author warnings with clear timing and ground placement**
  - Why: Threats must remain readable beneath VFX and on slopes.
  - Complete when: Telegraph geometry matches damage footprint and impact time; distinguish safe/unsafe space beyond color alone.

- [ ] **AI-05 — Build elite and boss state machines with recovery paths**
  - Why: Phase transitions and interrupts are common progression blockers.
  - Complete when: Test threshold crossings, simultaneous effects, death during transitions, arena exits, restart and reward delivery.

- [ ] **AI-06 — Author encounter budgets and escalation**
  - Why: PoE-like density needs pacing and performance discipline.
  - Complete when: Each encounter records actor count/roles, spawn waves, recovery space, reward budget and target difficulty.

- [ ] **AI-07 — Handle population persistence and farming policy**
  - Why: Reloads and respawns affect both challenge and economy.
  - Complete when: Define what resets, when enemies/containers respawn and how boss/quest rewards avoid duplication.

## ITEM — Items, inventory, crafting and economy

Owner roles: Gameplay designer + UI/UX + gameplay engineer. Priority: P1. Gate: G2–G3. Depends on: SKILL, BASE.

- [ ] **ITEM-01 — Reconcile the canonical item taxonomy into validated data**
  - Why: Artwork names and guesses must not define gameplay categories.
  - Complete when: Every base item has a stable type, slots, requirements, footprint, stack rule, rarity and art mapping with no orphan IDs.

- [ ] **ITEM-02 — Make grid occupancy match canonical item dimensions**
  - Why: Incorrect hit rectangles break placement and trust.
  - Complete when: Rings/amulets occupy 1×1; one-handed swords 1×3 vertical; test every type at bag edges, overlapping items and save/load.

- [ ] **ITEM-03 — Implement atomic equip, swap, unequip and transfer**
  - Why: Partial moves can duplicate or destroy valuable items.
  - Complete when: Full bags, incompatible slots, two-handed/offhand conflicts, requirement loss and failed operations leave inventory in a valid state.

- [ ] **ITEM-04 — Plan ground drops, labels, pickup range and loot filtering**
  - Why: Dense loot needs readable, reliable interaction.
  - Complete when: Labels avoid blocking combat unnecessarily; ownership/range rules are enforced; filtering cannot hide required quest items without recovery.

- [ ] **ITEM-05 — Design base stats, affix pools, tiers and rarity rules**
  - Why: Meaningful loot needs controlled combinations and understandable value.
  - Complete when: Seeded generation validates level eligibility, mutually exclusive affixes, roll bounds and representative build usefulness.

- [ ] **ITEM-06 — Implement crafting, upgrading and vendor transactions within scope**
  - Why: Resource sinks need clear outcomes and exploit resistance.
  - Complete when: Preview costs/results; apply atomic transactions; test insufficient currency, full bags, cancellation and repeated input.

- [ ] **ITEM-07 — Define currencies, sinks, drop rates and sell values**
  - Why: An economy can collapse through inflation or an obvious conversion loop.
  - Complete when: Simulate expected income/spend across progression, check circular-profit exploits and tune scarcity using playtest evidence.

- [ ] **ITEM-08 — Connect visual equipment changes to supported item families**
  - Why: Promising every item a unique appearance multiplies production costs.
  - Complete when: Document which items share appearances; supported combinations have fitted assets and correct weapon, shield and clothing visibility.

- [ ] **ITEM-09 — Design stash, sorting, comparison and search behavior**
  - Why: Inventory management can overwhelm the combat loop.
  - Complete when: Within approved scope, test quick transfer, sort stability, tooltip comparison, stack splitting and controller navigation without item loss.

## PROG — Quests, progression, narrative and endgame

Owner roles: Narrative/quest designer + gameplay designer. Priority: P1. Gate: G2–G4. Depends on: AI, ITEM.

- [ ] **PROG-01 — Define the complete player journey and reward cadence**
  - Why: A hub and combat test do not form a finished game.
  - Complete when: Map tutorial, first build choice, milestones, difficulty changes, narrative beats and a reachable ending or declared sandbox loop.

- [ ] **PROG-02 — Implement quest state and objective contracts**
  - Why: Objectives must survive out-of-order actions and reloading.
  - Complete when: Stable IDs and state transitions handle pre-collected items, duplicate events, abandonment, death and loading without blocking completion.

- [ ] **PROG-03 — Build useful NPC services and interaction feedback**
  - Why: Service art needs reliable gameplay functions.
  - Complete when: Approach/hover prompts, dialogue, shops, crafting and quest offers reflect actual availability and cannot activate through blocking UI.

- [ ] **PROG-04 — Connect narrative delivery to play without requiring full voice-over**
  - Why: AOTL needs coherent characters while voice scope stays selective.
  - Complete when: Written dialogue, journal, environmental cues and optional barks work when voice is disabled or unavailable.

- [ ] **PROG-05 — Specify tutorial and onboarding coverage**
  - Why: Experienced ARPG assumptions can conceal basic usability problems.
  - Complete when: First-time players learn movement, skill costs, dodge, loot, equip, healing and return-to-hub through tested prompts.

- [ ] **PROG-06 — Define endgame, replay or campaign-completion scope explicitly**
  - Why: Endless systems can consume a small team's entire schedule.
  - Complete when: Decide launch end state; if endgame is included, specify repeatable activities, modifiers, rewards, difficulty ceilings and retention without content promises.

## UI — HUD, menus, interactions and accessibility

Owner roles: UI/UX owner + gameplay engineer. Priority: P1. Gate: G2–G5. Depends on: CAM, SKILL, ITEM.

- [ ] **UI-01 — Implement the approved corner HUD using live state**
  - Why: A screenshot-like overlay is not a functioning interface.
  - Complete when: HP/MP, XP, level, skills, flasks, minimap and quest tracker update correctly; mock values and debug-only panels are absent in release.

- [ ] **UI-02 — Use shared layout geometry for rendering and input**
  - Why: Buttons that look aligned but click elsewhere cause accidental attacks.
  - Complete when: Clicks and wheel events on frames, gaps, menus and minimap are absorbed correctly across resolution and UI scale.

- [ ] **UI-03 — Keep equipment above the right-side inventory and character stats readable**
  - Why: The approved layout should support actual item decisions.
  - Complete when: Equipment, bag, derived stats and tooltips remain usable at minimum resolution without clipped controls or obscured drop targets.

- [ ] **UI-04 — Produce full-square distinct skill art and state overlays**
  - Why: Small vague symbols are not the approved visual direction.
  - Complete when: Every skill fills its square, has a distinct border/silhouette, and remains identifiable at 32/48/64 pixels with cooldown/resource overlays.

- [ ] **UI-05 — Resolve bindings and provide rebinding/context rules**
  - Why: The reference mockup's keys conflict with existing controls.
  - Complete when: Publish one action map; rebinding detects conflicts and persists; displayed prompts always reflect the current device and binding.

- [ ] **UI-06 — Support chosen controller navigation and input switching**
  - Why: Mouse interfaces do not automatically work on a gamepad.
  - Complete when: If scoped in, test focus order, inventory placement, targeting, prompts and device changes; otherwise document keyboard/mouse-only scope.

- [ ] **UI-07 — Provide accessibility settings and redundant cues**
  - Why: Color, shake and fine text cannot be the only way to read combat.
  - Complete when: Adjustable text/UI scale, subtitles, contrast cues, reduced shake/flashes and clear focus indicators are tested; evaluate other needs with players.

- [ ] **UI-08 — Build complete settings, pause, save feedback and error states**
  - Why: Players need predictable recovery from failed actions.
  - Complete when: Settings apply/persist/revert correctly; menus explain errors; pause follows game mode; loading and save failure remain recoverable.

- [ ] **UI-09 — Implement minimap, quest markers and interaction priority**
  - Why: Decorative maps and overlapping prompts can mislead players.
  - Complete when: Map derives from actual navigable content; markers track valid targets; loot/NPC/door priorities prevent unintended activation.

## VFX — Lighting, shaders, effects and readability

Owner roles: Technical artist + VFX artist. Priority: P1. Gate: G1–G3. Depends on: ART, WORLD, COMBAT.

- [ ] **VFX-01 — Choose a coherent baked versus dynamic lighting policy**
  - Why: Painted shadows can conflict with moving lights and actors.
  - Complete when: Each material category declares lighting treatment; scenes avoid doubled shading, mismatched direction and floating sprites.

- [ ] **VFX-02 — Author contact shadows and grounding cues**
  - Why: Characters must feel attached to the ground in the wide view.
  - Complete when: Shadows follow feet/height correctly on slopes and stairs; sprite and mesh actors have comparable grounding.

- [ ] **VFX-03 — Create a school-specific VFX language**
  - Why: Similar wisps make different spells hard to identify.
  - Complete when: Shape, motion, impact and sound distinguish physical, frost, fire and arcane actions; review at gameplay size in mixed combat.

- [ ] **VFX-04 — Build effect timelines tied to authoritative action events**
  - Why: Visual hits that arrive early or late feel unfair.
  - Complete when: Windup, release, travel, impact and lingering areas match actual mechanics at variable speed and frame rate.

- [ ] **VFX-05 — Budget transparency, particles, lights and decals**
  - Why: ARPG crowds can become GPU-bound through effects alone.
  - Complete when: Worst-case encounters stay within measured frame budgets; pooled effects and quality limits do not remove essential danger information.

- [ ] **VFX-06 — Use restrained grading and post effects**
  - Why: Global blur, grain and bloom can erase crisp AOTL art.
  - Complete when: Compare enabled/disabled settings; UI stays sharp; bloom/exposure preserve warning and actor contrast; reduced-effects mode is legible.

## AUDIO — Sound, music and selective voice

Owner roles: Audio owner. Priority: P1. Gate: G2–G5. Depends on: COMBAT, PROG.

- [ ] **AUDIO-01 — Create a prioritized sound-event list**
  - Why: Combat and interaction feedback need broader coverage than spoken dialogue.
  - Complete when: List footsteps by surface, weapon impacts, casts, enemy cues, loot, UI, ambience and music states with asset/event IDs.

- [ ] **AUDIO-02 — Implement audio buses, mixing and voice limits**
  - Why: Dense combat otherwise masks warnings and clips the output.
  - Complete when: Separate master/music/SFX/voice controls; prioritize danger cues, cap simultaneous sounds and validate a dense encounter mix.

- [ ] **AUDIO-03 — Use Grady only for selected NPC/enemy lines within current permission**
  - Why: The user chose a voice and limited scope, not full-character narration.
  - Complete when: Approved line list includes speaker/context, subtitles and playback rules; no paid or credit-consuming ElevenLabs operation is assumed authorized.

- [ ] **AUDIO-04 — Make audio resilient to pause, death, distance and missing files**
  - Why: Orphaned speech and repeated barks undermine polish.
  - Complete when: Dialogue cancels/resumes as designed, subtitles match, cooldowns prevent spam, and the game works with audio disabled.

- [ ] **AUDIO-05 — Produce looping ambience, music transitions and loudness checks**
  - Why: Harsh loops and inconsistent levels are distracting over long sessions.
  - Complete when: Check headphones/speakers, loops, transitions, compression and licensing; record human listening review.

## ARCH — Code architecture, tools and engine configuration

Owner roles: Technical lead + gameplay engineer. Priority: P0. Gate: G0–G3. Depends on: BASE.

- [ ] **ARCH-01 — Pin engine, renderer and dependency versions**
  - Why: A successful import on one tool version may fail elsewhere.
  - Complete when: Document supported Godot version/export templates, Blender/exporter and package versions; fresh setup runs the canonical scene.

- [ ] **ARCH-02 — Separate simulation, content data and presentation**
  - Why: Replacing sprites with meshes should not rewrite inventory or quests.
  - Complete when: Clear APIs cover input intents, actor state, ability events and world queries; presentation can be swapped without duplicating authority.

- [ ] **ARCH-03 — Build validated content registries and stable identifiers**
  - Why: Renamed files must not corrupt saves or silently break references.
  - Complete when: Validation catches missing IDs, invalid stats, absent assets, broken localization keys and unsupported skeleton/material contracts.

- [ ] **ARCH-04 — Create designer-facing debug and authoring tools**
  - Why: Content production becomes expensive if every item requires code changes.
  - Complete when: Tools visualize hit volumes, nav, elevation, pivots, state, stat derivation and encounter seeds; release builds disable developer privileges.

- [ ] **ARCH-05 — Define error reporting, logging and graceful fallbacks**
  - Why: Missing assets and invalid content should be diagnosable without destroying progress.
  - Complete when: Errors include version and asset IDs; safe fallbacks preserve state; logs avoid credentials and unnecessary personal data.

- [ ] **ARCH-06 — Maintain testable boundaries and deterministic fixtures**
  - Why: Large scene-only tests can hide race conditions and state leakage.
  - Complete when: Critical math/transactions have focused tests; integration fixtures wait for real nav/import readiness and use isolated save directories.

## SAVE — Persistence, migrations and data integrity

Owner roles: Gameplay engineer + QA. Priority: P1. Gate: G2–G6. Depends on: ARCH, ITEM, PROG.

- [ ] **SAVE-01 — Define persistent versus transient state**
  - Why: Temporary cooldowns or animation states should not accidentally become permanent.
  - Complete when: Save contract covers character, inventory, quests, world changes and settings; respawn/transient behavior is explicit.

- [ ] **SAVE-02 — Use atomic saves, backup slots and corruption recovery**
  - Why: A crash or disk-full condition must not destroy the only character.
  - Complete when: Fault-injection tests interrupt writing, truncate files and exhaust space; the last valid save or clear recovery path remains available.

- [ ] **SAVE-03 — Version the schema and test real migrations**
  - Why: New content and renamed IDs must preserve existing progress.
  - Complete when: Keep representative old saves; migrate forward with backups, handle missing content, and reject unsupported newer saves safely.

- [ ] **SAVE-04 — Test duplication, loss and transaction interruption**
  - Why: Loot, crafting and shop actions are high-value consistency boundaries.
  - Complete when: Repeated clicks, save/reload and interrupted operations cannot duplicate currency/items or leave equipment ownership inconsistent.

- [ ] **SAVE-05 — Define profiles, reset, import/export and cloud conflict policy**
  - Why: Multiple machines and characters can overwrite progress unexpectedly.
  - Complete when: Implement scoped features with clear identity and conflict handling; destructive reset requires intentional UI confirmation.

## NET — Conditional networking, services and security

Owner roles: Technical lead + online engineer. Priority: C. Gate: Decide G0; implement before G4 if included. Depends on: BASE, ARCH, SAVE.

- [ ] **NET-01 — Choose network topology, session size and authority**
  - Why: Retrofitting online combat can require rewriting the simulation.
  - Complete when: If multiplayer is in scope, specify server authority, client prediction, reconciliation, tick rate, transport and host/disconnect policy.

- [ ] **NET-02 — Design secure accounts, ownership and transactions**
  - Why: Shared economies cannot trust client-authored inventory or damage.
  - Complete when: Validate actions server-side, protect credentials, rate-limit abuse and test replay/duplicate transaction handling; offline scope is recorded otherwise.

- [ ] **NET-03 — Test latency, packet loss, reconnect and synchronization**
  - Why: Local correctness does not imply online playability.
  - Complete when: Simulated network tests cover movement, hits, loot ownership, joins/leaves, boss state and recovery under an agreed latency matrix.

- [ ] **NET-04 — Plan backend capacity, deployment, observability and incident response**
  - Why: Online services create recurring cost and operational duties.
  - Complete when: Load tests, region choice, monitoring, backups, rollback and on-call ownership are budgeted before a public online release.

- [ ] **NET-05 — Specify trading, matchmaking and moderation only if included**
  - Why: These features add economy abuse, support and community obligations.
  - Complete when: Scope decision names supported social systems, abuse controls and privacy policy; unbuilt features are not advertised.

## PIPE — Asset pipeline, provenance and repository operations

Owner roles: Technical artist + build/release owner. Priority: P0. Gate: G1–G3. Depends on: BASE, ART, ARCH.

- [ ] **PIPE-01 — Keep editable masters separate from runtime exports**
  - Why: A PNG or GLB alone may not be sufficient to revise the asset.
  - Complete when: Preserve layered art, blend/source rigs, textures and prompts alongside versioned runtime exports and reproducible settings.

- [ ] **PIPE-02 — Automate import validation and predictable derived assets**
  - Why: Manual resizing/exporting leads to inconsistent results.
  - Complete when: Check dimensions, alpha edges, pivots, UVs, bone maps, animation names, codecs and texture color space; deterministic conversions are repeatable.

- [ ] **PIPE-03 — Track Higgsfield jobs, licenses and current cost authorization**
  - Why: Provider output and historic credit plans do not establish present rights or budget.
  - Complete when: Record source permissions, tool/model/job revision, quoted/actual cost and output selection; no unauthorized spend or sole reliance on expiring links.

- [ ] **PIPE-04 — Establish naming, folder, LFS and large-file rules**
  - Why: Unstructured binary history becomes difficult to review and restore.
  - Complete when: IDs and paths follow a documented convention; clean clones resolve real assets; exceptions to LFS are intentional and recorded.

- [ ] **PIPE-05 — Make a per-asset acceptance and replacement workflow**
  - Why: New art must not silently overwrite approved runtime content.
  - Complete when: Candidate, approved, retired and fallback assets have explicit mappings; replacement PR includes before/after in-engine captures and rollback.

- [ ] **PIPE-06 — Mirror accepted releases to GitHub and the AOTL Drive destination**
  - Why: One cloud provider or a local machine is not a reliable handoff.
  - Complete when: Verify file sizes/hashes and archive contents after upload; include a human-readable manifest and check a clean restore.

- [ ] **PIPE-07 — Budget generation batches by accepted deliverables**
  - Why: More generated images do not equal more usable game content.
  - Complete when: Track acceptance rate, cleanup hours and cost per approved asset; stop a failing style/rig batch for review before expanding it.

## PERF — Performance, scalability and hardware budgets

Owner roles: Technical lead + technical artist + QA. Priority: P1. Gate: G1–G6. Depends on: CAM, WORLD, VFX, ARCH.

- [ ] **PERF-01 — Set measured frame, memory and loading budgets**
  - Why: Optimization needs a defined device and workload.
  - Complete when: Record CPU/GPU timings, resident memory, VRAM, load and save durations on chosen minimum hardware, with profiler captures.

- [ ] **PERF-02 — Adopt provisional targets and then validate them**
  - Why: Unsupported performance promises hide unknowns.
  - Complete when: Start with a proposed 60 FPS/16.7 ms frame target at 1080p; allocate subsystem budgets after profiling and explicitly approve any lower target.

- [ ] **PERF-03 — Benchmark a representative worst-case encounter**
  - Why: An empty plaza is not a useful ARPG performance test.
  - Complete when: Stress agreed actor/projectile/particle/loot counts, camera zoom and UI; report percentiles and hitches, not only average FPS.

- [ ] **PERF-04 — Optimize actor updates, pathfinding and physics**
  - Why: Dense crowds can exhaust CPU before rendering becomes expensive.
  - Complete when: Profile tick cost, stagger suitable AI work and use measured broadphase/pooling changes; combat-critical precision is preserved.

- [ ] **PERF-05 — Optimize meshes, textures, transparency and streaming**
  - Why: Both sprites and 3D can exceed memory/bandwidth budgets.
  - Complete when: Measure draw calls, skinning, texture residency, overdraw and load spikes; use batching, LOD/mips/compression as appropriate.

- [ ] **PERF-06 — Create quality settings that preserve essential information**
  - Why: Low settings must not remove danger cues or interactables.
  - Complete when: Compare supported presets in the same combat scene; readability, targeting and collision remain identical.

- [ ] **PERF-07 — Test extended sessions and resource cleanup**
  - Why: Short runs miss leaks and unbounded corpse/effect accumulation.
  - Complete when: Soak tests repeat area transitions, combat, menus and saves; memory stabilizes and no persistent orphan objects accumulate.

## QA — Functional, visual and player testing

Owner roles: QA + discipline owners. Priority: P1. Gate: G1–G6. Depends on: All affected feature sections.

- [ ] **QA-01 — Maintain a requirements-to-evidence matrix**
  - Why: Large assertion counts can still omit a critical player flow.
  - Complete when: Every checklist acceptance links a test, capture or human review at a specific build; known gaps are explicit.

- [ ] **QA-02 — Test the complete core loop manually on native target hardware**
  - Why: Headless logic cannot prove visual clarity or comfortable controls.
  - Complete when: Play fight → loot → equip → skill change → quest → death/recovery → save/reload → return-to-hub on supported platforms.

- [ ] **QA-03 — Capture controlled visual regressions and movement reviews**
  - Why: Static screenshots cannot reveal foot sliding, clipping or bad transitions.
  - Complete when: Use fixed scene/camera/settings plus video of turns, stairs, casts, rolls and crowds; approve meaningful changes rather than blindly matching pixels.

- [ ] **QA-04 — Cover resolution, scaling, localization and device combinations**
  - Why: UI defects often appear outside the developer's default setup.
  - Complete when: Matrix includes supported aspects, minimum resolution, enlarged text, longest language strings and each input device.

- [ ] **QA-05 — Test edge cases, corrupted content and interruptions**
  - Why: Real users pause, alt-tab, disconnect devices and close the game mid-action.
  - Complete when: Exercise focus loss, import failures, missing assets, save interruption, rapid input and invalid state without destructive failure.

- [ ] **QA-06 — Run structured combat and usability playtests**
  - Why: Automated checks cannot measure fairness, confusion or fun.
  - Complete when: Observe new and experienced players; record task completion, unclear deaths, inventory friction and build choices; prioritize recurring evidence.

- [ ] **QA-07 — Define severity, triage, regression and release-blocking rules**
  - Why: Teams need agreement on which defects can ship.
  - Complete when: No unresolved critical crash, progression blocker or item/save-loss defect; exceptions require a named owner and explicit release disposition.

## LOC — Localization, legal and data/privacy obligations

Owner roles: Producer + localization/QA owners. Priority: P1 / C. Gate: G3–G6. Depends on: UI, AUDIO, PROG.

- [ ] **LOC-01 — Externalize player-facing text and support formatting**
  - Why: Late localization is expensive when strings are embedded in art/code.
  - Complete when: Stable keys, plural/number formatting, font glyph coverage and text expansion work; right-to-left support follows chosen languages.

- [ ] **LOC-02 — Maintain licenses and attribution for all shipped assets and tools**
  - Why: Reference art, fonts, voice and generated material have distinct rights.
  - Complete when: Asset provenance includes usage/redistribution terms; no copied WoW/Diablo/PoE assets ship; required notices accompany builds.

- [ ] **LOC-03 — Review voice consent, provider terms and generated-asset provenance**
  - Why: Availability of a voice or model does not imply unrestricted use.
  - Complete when: Confirm permitted commercial/game use, speaker restrictions and retention rules for selected services before release.

- [ ] **LOC-04 — Define analytics and crash-reporting data collection**
  - Why: Diagnostic data can include identifiers or user content.
  - Complete when: Collect only needed data, document retention/consent where required, avoid secrets in logs and provide applicable privacy information.

- [ ] **LOC-05 — Plan age ratings, accessibility/store declarations and regional requirements**
  - Why: Distribution obligations can delay a completed game.
  - Complete when: Producer checks target stores/regions, content rating questionnaires, refund/support terms and required disclosures before submission.

## RELEASE — Builds, distribution, launch and maintenance

Owner roles: Build/release owner + QA + producer. Priority: P1. Gate: G3–G7. Depends on: QA, PERF, SAVE, LOC.

- [ ] **RELEASE-01 — Create reproducible automated builds from a clean checkout**
  - Why: A working editor scene is not a distributable game.
  - Complete when: CI pins tools, resolves LFS and exports target packages with version, content manifest, licenses and checksums.

- [ ] **RELEASE-02 — Test actual exported binaries and fresh installation**
  - Why: Editor-only dependencies and missing resources often appear after export.
  - Complete when: On a clean supported machine, install/run/play/save/relaunch without developer tools or network unless explicitly required.

- [ ] **RELEASE-03 — Validate updates, save compatibility and rollback**
  - Why: Patches can break previously working characters or installations.
  - Complete when: Upgrade representative old versions, verify migrations and restore prior builds/backups according to documented limits.

- [ ] **RELEASE-04 — Prepare store/demo/support materials from real gameplay**
  - Why: Marketing should represent the shipped experience.
  - Complete when: Screenshots/trailers show accepted runtime footage; feature claims, controls, system requirements, known limits and support links are accurate.

- [ ] **RELEASE-05 — Run a release-candidate checklist and preserve the exact build**
  - Why: Rebuilding later may produce a different result.
  - Complete when: Tag source, archive binaries/source manifests, verify hashes and backups, sign/notarize where needed and record release approval.

- [ ] **RELEASE-06 — Plan launch monitoring, hotfixes and player support**
  - Why: Development continues after the first download.
  - Complete when: Assign crash/feedback triage, save-loss response, patch cadence, rollback authority and issue communication channels.

- [ ] **RELEASE-07 — Maintain content compatibility and documentation after launch**
  - Why: New items, areas and balance patches can invalidate old data.
  - Complete when: Version content IDs, migration tests, changelogs and handoff updates with each release; retire assets only after dependencies are addressed.

## PROD — Staffing, estimates, budget and completion control

Owner roles: Producer + discipline leads. Priority: P0. Gate: G0–G7. Depends on: BASE; refine after G2–G3.

- [ ] **PROD-01 — Assign accountable owners and reviewers to each workstream**
  - Why: Unowned work remains unfinished even when tools can generate assets.
  - Complete when: Every active task has a named owner, reviewer, milestone and capacity allocation; one person may hold several roles.

- [ ] **PROD-02 — Estimate from a completed representative asset and encounter**
  - Why: Counting prompts or mesh objects is not a production estimate.
  - Complete when: Track accepted production, cleanup, integration and QA hours; estimate remaining content using measured throughput and explicit revision reserve.

- [ ] **PROD-03 — Build a dependency-based milestone schedule**
  - Why: Parallel art output cannot bypass unresolved camera or rig decisions.
  - Complete when: Schedule G0–G7 with exit evidence, critical path, staffing capacity and risks; dates remain provisional until throughput is known.

- [ ] **PROD-04 — Maintain a complete operating and production budget**
  - Why: Software, asset cleanup, storage, localization and support all cost time or money.
  - Complete when: Record recurring and one-time costs, current authorized limits, actual spend and stop conditions; service credits are not assumed free.

- [ ] **PROD-05 — Control changes and optional systems**
  - Why: An ARPG can expand indefinitely through crafting, trading or endgame ideas.
  - Complete when: Changes state player benefit, asset/system/test cost and displaced work; launch scope is versioned and conditional tasks get a decision.

- [ ] **PROD-06 — Keep risk, debt and unresolved-decision registers current**
  - Why: Hidden technical debt becomes a release blocker.
  - Complete when: Each risk has likelihood/impact, owner, mitigation and trigger; unresolved source, rig and art-quality issues stay visible.

- [ ] **PROD-07 — Verify the final handoff by an independent clean-start walkthrough**
  - Why: A document is useful only if another developer can continue from it.
  - Complete when: A teammate restores the build, finds sources, imports an asset, runs checks and identifies the next task using the handoff alone.
