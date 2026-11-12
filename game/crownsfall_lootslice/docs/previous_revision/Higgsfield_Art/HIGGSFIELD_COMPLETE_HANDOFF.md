# Age of the Lost — Higgsfield Mage Art transfer

Current tested art revision, November 11, 2026. 156 unique checks passed. Source project for Godot 4.6.3, with independent rig lab, canon sources, generated-art provenance and reproducible derivatives.


---

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


---

# Age of the Lost — Mage + 3D Rig Lab handoff

Revision: November 11, 2026. Source baseline: the separately preserved Crownsfall Systems Expansion. Current source lives in this new project copy; it does not overwrite the previous playable package or save namespace.

## Result

Two classes are now selectable at character creation: Warrior and Mage. Mage has five functional starting abilities and three specialization/heroic paths. The existing inventory, stash, services, discovery and arena systems remain. Nineteen distinct abilities are defined across the two classes and four shared recovered techniques; not all nineteen are available to one character simultaneously.

The class roster still contains thirteen planned base classes. Eleven remain design-only. Both playable classes have three level-20 specializations. Mage Fire → Pyromancer, Frost → Glacial Sovereign and Arcane → Chronomancer are preserved. No automatic standalone signature class passive was introduced.

## Actual changes

- Added a class/name creation screen with starting ability icons and visible future paths.
- Added five Mage base actions: traveling generator bolt, piercing frost/slow/freezing projectile, valid-floor blink, timed ward, and delayed area strike.
- Added Solar Writ, Winter Crown and Epoch Lance for the Mage's three level-20 paths.
- Added selected level-40 heroic identities and their explicit training modifiers. Chronomancer cooldown reduction applies consistently in every hotbar slot.
- Added staff/wand/focus/robe/hood/wrap/slipper bases, class-based drop pools, cloth restrictions, two-handed/offhand conflicts and atomic displaced-equipment handling.
- Centralized direct/burn math and tooltips in `effect_resolver.gd`. Casts snapshot power, buffs and modifiers at activation. Crit and variance roll at direct contact; DOT does neither.
- Corrected burn timing so the final full or partial interval is paid, with floating HP damage rather than rounding away the budget.
- Added cast recovery, projectile swept collision and lifetime, and epoch-based cancellation of stale queued attacks.
- Corrected primary-slot range/chase behavior, empty-slot intent and remembered world aim for hotbar clicks.
- Added class identity, current HP/mana, remaining cooldowns and full cooldown durations to schema-3 persistence. Empty merchant stock remains empty after loading.
- Added 15 SVGs, bringing the editable placeholder icon kit to 39.

## Files and seams

| File | Responsibility |
|---|---|
| scripts/game_data.gd | Two playable class definitions, 19 abilities, class/spec filtering, level gates and enemy templates |
| scripts/effect_resolver.gd | Pure snapshot, direct roll, DOT budgets, ward capacity and tooltip summary |
| scripts/projectile.gd | Ground-space travel, swept enemy collision, per-projectile hit IDs, pierce limit and lifetime |
| scripts/player.gd | Input, cast/recovery timeline, active ward, resource payment/reward, targeting and effect application |
| scripts/systems.gd | Inventory geometry, item generation, class/slot/handedness legality and class stat curves |
| scripts/main.gd | World/arena/services, class-aware starter/drop/vendor content and schema-3 save flow |
| scripts/hud.gd | Class creation, class-filtered scrollable Grimoire, equipment comparison and inventory/service modals |
| scripts/legacy_hud.gd | Shared drawing/widgets, progression/death presentation, validated class-specific choices |
| tests/integration.gd | 52 existing Warrior/system regressions |
| tests/mage_integration.gd | 57 new class/cast/gear/save/interaction checks and automated captures |
| tests/export_data.gd | Export runtime definitions, class balance CSV and item-base records |

The architecture remains a pragmatic single-player prototype. Effects now share a calculation seam, but there is no full resistance/condition/proc framework, combat log, replicated simulation or deterministic RNG service. Avoid describing a damage-school metadata field as implemented elemental mitigation.

## Behavior contracts

A cast validates its target, lock state, equipped definition, class/unlock, cooldown and resource before committing payment. Blink/ground targets must land on the navigation floor. Resource and cooldown commit once. A spell with a cast time releases after that timer; recovery prevents another action from overwriting the windup. A newly cast weapon attack preserves its original contact timing.

The immutable damage snapshot includes ability ID, power source, direct coefficient, burn DPS/duration, crit chance, chosen modifiers and current Rally multiplier. Equipment changes after activation do not change that cast's impact. Repeated hits from the same generator packet grant mana once. Direct hits roll per-target variance and crit; burns consume their exact stored budget without crit or variance.

A staff displaces both the existing weapon and focus only if both displaced items fit. Equipping a focus while a staff is equipped fails. Replacing a staff with a smaller wand can fail when the bag lacks a suitable staff footprint; that failure preserves all three ownership records. Bags can store other-class items, but equipment validation prevents wearing them.

The primary action uses the actual equipped skill reach. A ranged primary stops at range; an empty primary clears chase intent. Self/area defensive primaries cast locally rather than walking toward an enemy. Hotbar buttons use the last world aim, rather than the pointer's position over the HUD.

## Verification and provenance

The test results are attached under `tests/`, including 52 Warrior regressions, 57 Mage checks, 28 lab round-trip checks and 19 art/audio checks (156 unique assertions). The 3D suite also passed under the rendered X11 display. Rendered Mage captures come from the real Godot project under X11/software OpenGL. The automated combat sequence uses a durable test enemy. It is not a measured balance encounter or a manually approved Windows playtest.

Review the actual final result files before citing a run. A packaged archive should contain the current code, definitions, handoff, QA records and captures, and exclude `.godot`, live saves, raw intermediate frame sequences and unrelated personal-memory material.

## Save compatibility

The new custom user directory and filename are listed in the README. The previous Systems save remains untouched. Schema 2 can be imported by manually copying a backup into the new path; it becomes Warrior, preserves owned items and chooses resource defaults once. Future schema versions are write-protected. Schema-3 resources and cooldowns persist in full; active wards/casts/arena state do not.

Known persistence boundaries: drops/enemies are not saved; offline time does not advance cooldowns; wards are discarded on load while their paid cooldown remains; some UI/presentation state resets. This closes instant resource/cooldown reset behavior without claiming a production exploit-resistant economy.

## Art and production limits

Mage now has a dedicated painted frame bank, idle/cast poses, painted icons, modal skin and thirteen procedural sound cues. Gear appearance is baked into the sprite and does not change when equipping items. The additional consolidated Drive source supplied the six original canon boards, their overview and a 58-bone/six-clip geometric 3D proxy; these are now preserved and tested here. The previously mentioned 56-bone/17-clip production Wayfarer and authored 3D city remain unavailable. The independent 3D lab does not implement the Mage spells, inventory or scaling. Higgsfield generation and integration status is recorded in `docs/HIGGSFIELD_ASSET_PIPELINE.md`; generated proposals do not replace canon originals.

The city is still one painting with hand-traced navigation/occlusion. Enemies are still painted stills with procedural motion. No new production sound system, Windows export, performance benchmark, controller focus, localization or mastery graph is claimed.

## Next work

1. Verify this exact package on Windows with both new characters and a copied schema-2 test save.
2. Add a saved per-ability mastery model with prerequisite and exclusion-group validation.
3. Implement Ashen Ward → Ember Aura as an explicitly selected paid toggle, not a free class passive.
4. Implement mutually exclusive Cinder Bloom / Siphon Embers and one named unique with proc recursion/cap tests.
5. Polish four-pose Mage walking/two-pose casts; add hurt/dodge/death, hand anchors and production animation quality. Gameplay timers remain authoritative.

The prior handoff's narrative pillars, thirteen-class roster, Unwritten reveal, Lorecasting concept and original visual direction remain. New numerical choices and ability variants remain development proposals until user playtesting/design review.

## Consolidated source preservation

The Mage mechanics remain authoritative. Only the independent lab, its geometric GLB and original references were imported from the extra consolidated Drive package. Older progression/inventory scripts were not copied over. `data/CONSOLIDATED_PRESERVATION.json` records the source archive and unchanged reference/model hashes. `docs/3D_LAB.md` explains the F7 save/return contract.

## Higgsfield delivery

Read `docs/HIGGSFIELD_ASSET_PIPELINE.md`. Six accepted generated PNG sources, one rejected GIF and a portable processing helper are retained. All 45 derived PNG/WAV files rebuilt byte-for-byte in Higgsfield’s sandbox. Gameplay/save schema remain compatible with the consolidated namespace.


---

# Higgsfield art and audio delivery

November 11, 2026. User approved the canon-reference upload and unlimited allowance. Seven image jobs completed: six PNG sources passed visual review and one native GIF was rejected. `data/higgsfield_generation_manifest.json` retains the prompts, configurations, reference identities and job IDs. Paid credit balance stayed at 1.5.

## Integrated assets

Mage has a dedicated painted character bank. Five source facings (up, northeast, right, southeast, down) and mirrored west facings cover eight screen directions. Each has four walking poses, one idle and two casting poses: 35 frames in fifteen PNG textures. Warrior keeps its supplied art. Eight painted spell icons and seven painted gear icons override their vectors; a bonus spellbook is a source painting, not a new item. All 39 editable SVGs remain. A blue/gold nine-slice skin is used by modals, and a portrait derived from the turnaround appears on the Mage class button.

Thirteen short mono PCM WAV cues cover eight Mage abilities, slash, equip, pickup, potion and UI click. These are deterministic procedural sounds authored through Higgsfield's media sandbox, not generated speech/music. Peak is approximately 0.55 before runtime −15 dB gain. Eight playback voices are reused. The pause-menu mute control stops playback and saves a separate audio preference file.

## Runtime contracts

`art_library.gd` chooses paintings by stable gameplay ID, retains vector fallbacks and supplies the panel texture style. Text, numbers, buttons, hit areas and tooltips remain actual Godot controls. Texture/content margins are 64px to preserve corner ornaments.

`player.gd` switches Mage/Warrior frame banks on class changes and load. An incomplete Mage set falls back as a whole. Frames are 384 square with a common feet anchor (192,368). Walk poses run at 6 fps. Mage windup holds pose zero; authoritative gameplay release selects pose one. Combat timers and damage calculations remain authoritative; image playback never applies damage. Cancellation clears the visual timer.

Ability audio starts only after commitment. Rejected cooldown/resource attempts do not emit another ability cue. Equip/unequip, pickups and potions emit cues after success. Audio settings process while paused. Graceful quit stops playback, releases streams and lets the mixer drain before exit.

## Sources and reproducible processing

`assets/higgsfield_sources/` contains the accepted turnaround, two icon atlases and walking/idle-cast pose sheets. Its `.gdignore` avoids importing these large source boards. The original panel source is already its runtime PNG. Canon originals remain under `references/canon_originals/`.

In a project copy with Python, Pillow and numpy:

```sh
python3 tools/rebuild_higgsfield_assets.py --project .
```

This rebuilds icon crops, anchored Mage frames, portrait and synthesized cues. An independent run in Higgsfield's sandbox reproduced all **45 derived PNG/WAV files byte-for-byte**. `data/HIGGSFIELD_REBUILD_VERIFICATION.json` records the result. Asset manifests retain dimensions, cell mappings, synthesis metadata and hashes.

## Review boundaries

The combined native GIF duplicated front-facing figures and changed framing. It is retained under `assets/higgsfield_sources/rejected/` with a rejection note and is never used in gameplay. The accepted PNG sheets replaced it. The source gallery includes this rejected experiment for provenance.

These are four-pose prototype walking cycles and two cast poses, not production skeletal animation. The baked staff/clothing do not change when gear is equipped. Hurt, dodge and death clips, cloth/IK, interpolation and hand attachment points remain future work. Mirroring also mirrors handedness and trim. Technical audio checks do not replace a human listening/mix review.

Tripo quoted 9 credits against 1.5 available; no mesh or rigging job was submitted. The included 3D model remains the preserved 58-bone/six-clip geometric lab proxy. This sound layer does not include music or spatial mixing.

## Verification

52 Warrior + 57 Mage + 28 lab + 19 art/audio checks = **156 unique assertions**, all passing in Godot 4.6.3 Linux. Mage also passed its 57-check suite under rendered X11/software OpenGL. New checks exercise class frame-bank switching, painted/vector routing, cast poses, cue commitment/rejection, importing all cues, mute recreation and pause-control behavior without rewriting progression.

`previews/` contains actual engine screenshots and sampled combat GIFs. Raw source boards and generated concepts are distinct from those captures. Windows, target hardware performance and production audio mixing remain unvalidated.


---

# Mage Slice systems and balance reference

This chapter supersedes the previous revision's implementation claims. Prior detailed design chapters are archived under `previous_revision/`.

## Class/stat curves

For n = level − 1, Mage starts with Strength 4, Dexterity 8 + 0.5n, Vitality 8 + n, Intelligence 12 + 3n, Wisdom 10 + 2n and Charisma 5 + floor(n/2). Equipment attribute values add after the growth curve.

```
Mage max_hp = round((60 + 8n + 4 × vitality + gear_hp) × (1 + chosen_hp_modifier))
Mage max_mp = round(30 + 3n + 2 × intelligence + wisdom)
Mage spell_power = (10 + 2.5n + gear_spell_power) ×
                   (1 + 0.018 × intelligence + chosen_spell_power_modifier)
mana_regen = 2 + 0.12 × wisdom
crit = clamp(0.03 + 0.0015 × dexterity + gear_crit + chosen_crit, 0, 0.60)
armor = (5 + 2 × level + gear_armor) × (1 + chosen_armor_modifier)
```

Level-1 ungeared Mage: 92 life, 64 mana, 12.16 spell power. Level-10 ungeared Mage: 200 life, 163 mana. Intelligence affects spell power and mana, while Strength does not secretly multiply Mage spell power. Warrior formulas are preserved; its recovered spells retain the Warrior hybrid scaling.

The generated `data/class_balance_snapshot.csv` contains both classes at levels 1, 10, 20, 40 and 60, ungeared and with a midpoint common weapon. Damage ratios exclude variance, crit, animations, resource waits, movement, recovery and buffs. They are analytic checkpoints, not measured time-to-kill.

## Mage active kit

| Ability | Cost | Cooldown | Cast / recovery | Effect |
|---|---|---|---|---|
| Cinder Thread | 0; +3 on first hit | 0.7s | 0.16 / 0.28s | 1.05 spell coefficient, range 8, one target |
| Glacial Stitch | 14 | 5s | 0.25 / 0.38s | 1.3 coefficient, range 7, pierces 3; 30% slow for 2s; second hit in 6s freezes |
| Arcane Fold | 16 | 8s | Instant / 0.12s | Blink up to 4 ground units onto valid floor |
| Ashen Ward | 20 | 12s | Instant / 0.15s | 20% max life + 2× spell power absorbed for 3s |
| Starfall Script | 24 | 7s | 0.3 / 0.45s | 2.4 coefficient, radius 2.3, range 7; another 0.8s telegraph after cast release |

Mage specializations: Solar Writ (Fire) is a cone with direct and burn damage; Winter Crown (Frost) is a freezing nova; Epoch Lance (Arcane) is a precise piercing projectile. The Grimoire lists requirements and evaluates current damage/cooldown numbers using the actual actor modifiers.

The five starting abilities remain available after specialization; the unlocked specialization technique is an additional known ability that can replace any slot. Shared recovered techniques retain their discovery/level requirements. Warrior-only abilities are neither assignable nor listed in the Mage's Grimoire.

At level 40, chosen Pyromancer training adds 20% to the spell-power multiplier; Glacial Sovereign adds 30% specialization radius; Chronomancer grants 20% cooldown reduction. These are selected progression modifiers, not automatic base-class signature passives. Actual branching skill mastery remains future work.

## Direct damage, DOT and timing

Power, Rally and chosen modifiers snapshot at activation. Direct damage at contact = coefficient × snapshotted power × uniform 0.9–1.1 variance, rounded to an integer. A critical direct hit multiplies by 1.75; crit chance is snapshotted but the roll happens per target at contact.

Burn DPS = snapshotted power × burn coefficient × snapshotted burn multiplier × damage multiplier / duration. It ticks every 0.5s, preserves the final full/partial interval, uses floating HP damage and cannot crit. The strongest active burn is retained; applying an equal/stronger burn refreshes its timer. This is a compact single-burn model, not a per-source effect stack.

Cast cancellation uses a monotonically changing combat epoch. Death, respawn, load and Scar closure invalidate previously queued packets. Projectiles also stop on expiry, navigation-boundary collision or pierce exhaustion. No projectile can damage the same actor twice. Enemy health, drops and XP use the existing idempotent kill gate.

Glacial Stitch freezes an ordinary enemy for 0.75s on the second hit within 6s; elites receive 0.35s. General stun options are halved against elites. There are no authored bosses or universal boss-control immunity tags yet.

## Equipment

| New base | Footprint | Equipment destination | Budget before rarity/quality multiplier |
|---|---|---|---|
| Staff | 2×4 | Weapon, both hands | Spell power = 4 + 1.9L |
| Wand | 1×2 | Weapon | Spell power = 2 + 1.1L |
| Focus | 1×2 | Offhand | Spell power = 1 + 0.6L |
| Robe | 2×3 | Chest | Armor = 4 + 1.4L; implicit Intelligence = max(1, round((1 + 0.2L)q)) |
| Hood | 2×2 | Helm | Armor = 2 + 0.7L |
| Wraps | 2×2 | Gloves | Armor = 2 + 0.7L |
| Slippers | 2×2 | Boots | Armor = 2 + 0.7L |

Multiply primary budgets by q = rarity multiplier × uniform quality 0.85–1.15, then round. Magic and higher add one random primary-attribute affix; affix pools are not yet class-weighted, so undesirable rolls remain possible. Shared rings, amulet and belt retain previous budgets.

The generic focus is called Prismatic Focus. The named unique Riftglass Focus remains a distinct design proposal with no working unique power. “Legendary” still describes the prototype's rarity/stat tier, not a bespoke effect framework. Dual wield is not implemented.

Equipment comparisons use the current class curve. Mage comparisons display spell-power differences, not a Warrior damage proxy. Staff comparisons account for losing the focus. Legal gear can still fail a swap when displaced items cannot fit in the bag; failure preserves the original state.

## Saves, economy and migration

Schema 3 stores chosen class, resources and stable-ID cooldowns. It validates field types before model calls, rejects unknown classes/duplicate item IDs/illegal equipped states, recovers backups and protects future schema versions. The new namespace preserves previous playable saves independently. Manual schema-2 import is intentionally opt-in.

Merchant stock initializes for the selected class and stays empty after it is bought out and saved. There is still no timed restock or buyback. Ground drops, arena enemies and open waves remain transient. Owned inventory, equipment, stash, gold, potions, discoveries and quests persist.

## Art handoff

Thirty-nine original SVG placeholders cover nineteen abilities, sixteen item bases and four utilities. `data/icon_manifest.json` and the local HTML atlas match actual files. Current class-selection, inventory, Grimoire and heroic screenshots are real engine captures. The gameplay GIF is assembled from sampled frames of an automated encounter and contains no audio.

Mage now has a five-facing painted bank (eight mirrored screen directions), four walking poses per facing, idle and two cast poses. Eight spell and seven gear paintings override vectors. The modal skin, portrait and thirteen procedural cues are integrated. Read `HIGGSFIELD_ASSET_PIPELINE.md` for provenance, rebuilding and animation/gear-appearance/3D limits.


---

# Independent 3D rig lab

Press F7 from the town to enter. Entry is refused while dead, paused, in an active Scar or while save writing is protected. Main gameplay cancels transient casts and saves before the scene transition. F7, Escape or the return button reloads the plaza using that saved Mage/Warrior state. Lab training does not grant main-world gold, experience, loot or resource recovery; main cooldowns stay frozen during the visit.

WASD moves, Shift sprints, Space dodges, left click slashes, 1 cleaves, 2 dash-strikes and 3 casts a radial lore burst. These are independent lab actions with training values. They are not aliases for the Mage's five spells. Lab HP starts at 130 and does not replace the saved character's HP.

The GLB contains 58 joints and Idle, Walk, Run, Slash, Dodge and Cast clips. Import may prefix animation names with a library path; the controller resolves the final path component. Idle, Walk and Run explicitly loop. The source GLB remains byte-for-byte unchanged and is a geometric articulated proxy, not the missing production Wayfarer.

`tests/lab_roundtrip.gd` checks 28 conditions through real scene changes: imported skeleton/animations, changing bone poses, movement/sprint, timed slash and cast impacts, invulnerability expiry, duplicate kill prevention, and returning with the same class/name/gear/bag/stash/gold/potions/resources/cooldown state. It passed in Godot 4.6.3 Linux both headless and rendered. Review `tests/LAB_*` logs for exact results.

The floor is a finite blockout. Decorative columns and steps are visual cues rather than a finished collision/navigation level. There is no cloth/IK, production mesh, shared 3D enemy AI, 3D inventory gear visualization or exported Windows build. A future renderer should consume the same mechanics/state as the 2D game rather than evolving these training values into a second balance system.


---

# Mage Slice implementation status

| Earlier ticket | This revision | Remaining scope |
|---|---|---|
| P1-01 effect resolver | Shared immutable snapshots, direct roll and DOT budgets; cast cancellation and hit ownership | Damage-school mitigation, full effect/proc framework, combat log and deterministic RNG |
| P1-02 burn/tooltip parity | Direct/burn use the same power snapshot; exact final tick/partial interval; tooltip reads shared calculation | Full mitigation/healing tooltips and production effect stacking |
| P1-03 reload resources/cooldowns | Schema 3 stores HP/mana and stable-ID remaining/full cooldowns | World/drop/arena persistence, offline-time policy beyond frozen cooldowns |
| P1-04 equipment legality | Real 2×4 staff, two-handed conflict, wand/focus, class equipment and atomic displaced-item swap | Dual wield, further weapon families and broader class restrictions |
| P1-07 primary intent | Actual spell range, self-defensive casting, empty-slot cancellation and remembered world aim | Target-lock UI, controller targeting and obstruction-aware ranged pursuit |
| P1-08 vendor state | Empty stock survives reload; class-specific starter stock | Buyback and timed restock generations |
| P2-01 Mage slice | Five working base actions, dedicated painted sprites/icons, class creation and sound cues | Additional hurt/dodge/death clips, equipment visualization, production animation polish and authored encounter |
| P2-02 progression | Fire/Frost/Arcane at 20; Pyromancer/Glacial Sovereign/Chronomancer at 40; locked investment enforced | Production respec and complete character path browser |
| P2-03 mastery graph | Not implemented | Stable node IDs, points/prerequisites, exclusivity and respec transaction |
| P2-04/05 Ember Aura branches | Design retained; not implemented | Paid toggle/pulse lifecycle and mutually exclusive Cinder Bloom/Siphon Embers |
| P2-06 named uniques/sets | Design retained; not implemented | Runtime effects, stacking/proc caps and specific tests |
| P3/P4 production/world | Preserved canon boards and 58-bone/six-clip proxy; separate lab verified with 28 checks | Production 3D art, shared Mage simulation in 3D, sound, controller/accessibility, cathedral encounter, Windows/export/performance |

Recommended next pass: implement and test one saved ability mastery graph before adding another class or a large batch of loot. Apply it to Ashen Ward → Ember Aura, then add one exclusive branch and one named unique. Keep existing class and inventory/save tests passing.


---

# Mage Slice QA and reproduction

Environment: Godot 4.6.3 stable, Linux. Rendered captures use X11/Xvfb, Mesa software OpenGL and Dummy audio. No Windows run, signed executable, target-hardware profile is claimed. The independent 3D lab has been validated in headless and rendered runs.

## Test suites

- `-- --systems-test`: 52 existing Warrior/inventory/service/save regressions.
- `-- --mage-test`: 57 Mage creation, class filtering, gear, combat timing, progression and save checks.

- `--script res://tests/lab_roundtrip.gd`: 28 runtime rig, locomotion, timed contact, dodge and save-preserving scene round-trip checks.

- `--script res://tests/art_audio_integration.gd`: 19 sprite/icon/cast/audio/settings integration checks.

Together these cover 156 unique assertions. Result logs in `tests/` identify the exact mode and engine. A passing run ends in zero failures. Inspect logs for script errors as well as the final count. The virtual display may report unsupported V-Sync; that is separate from gameplay script failure.

## Key additions verified

Mage/name selection; all five starting skills; cross-class assignment restrictions; class/level progression gates; real staff footprint; wand/focus support; whole-transaction two-handed swap and rollback; plate/cloth legality; spell-power curve; direct/burn snapshot parity; crit/variance; unchanged packet after gear changes; generator once per cast; projectile windup, flight and swept collision; frost slow/freeze; valid/invalid blink resource behavior; ward absorption/expiry without healing; death cancelling delayed contact; actual ranged-primary reach; empty-primary intent; slot-independent cooldown reduction; persistent class/resources/cooldowns; malformed saves; explicit schema-2 compatibility; bought-out vendor persistence; final full/partial DOT ticks.

These are integration assertions over real scripts and injected key/UI signals. They do not constitute a human mouse/controller usability test. The scripted enemy is a durable fixture, not an authored boss encounter.

## Linux commands

Use an isolated directory. Tests intentionally modify saves.

```sh
mkdir -p .qa/data .qa/config .qa/cache
export XDG_DATA_HOME="$PWD/.qa/data"
export XDG_CONFIG_HOME="$PWD/.qa/config"
export XDG_CACHE_HOME="$PWD/.qa/cache"
godot --headless --path . --editor --quit
godot --headless --path . -- --systems-test
godot --headless --path . -- --mage-test
godot --headless --path . --script res://tests/lab_roundtrip.gd
godot --headless --path . --script res://tests/art_audio_integration.gd
godot --headless --path . --script res://tests/export_data.gd
```

On a desktop/X11 display, omit `--headless` and pass `--audio-driver Dummy` for automated capture. The Mage harness writes five UI/world screenshots and a sampled combat frame sequence. Raw frame sequences are intermediate assets and excluded from the compact source ZIP. The delivered GIF is assembled from those actual engine frames, with sampled playback timing and no audio.

The icon atlas helper is `tests/capture_atlas.gd`. The corresponding HTML atlas can be opened locally without an engine. Its asset-board capture is not an in-world screenshot.

## Windows manual gate

Import a fresh extracted source copy in standard Godot. Record exact version and any first parser error. For automated checks, first change Custom User Dir Name to a separate QA namespace in a test copy. Run the console Godot executable with the same flags. Do not run tests against real progress.

Manual acceptance: select and name each class; equip staff then wand/focus; force a full-bag swap failure; move/cast at range; cancel a delayed spell through death; use and expire a ward; choose all three specializations in independent fixtures; reach Chronomancer at 40; inspect/reassign cooling-down skills; save wounded/low-mana state and reload; import a copied schema-2 Warrior save; inspect every screen at 720p/1080p/1440p/ultrawide.

## Capture truth and remaining limits

Current captures are the actual game project. Mage uses dedicated painted sprites with 35 frames across five source facings. Painted icons, panel skin and thirteen procedural cues are integrated. There is no rigged 3D Mage, authored boss, elemental resistance system, mastery graph, Ember Aura, named unique power, controller navigation or localization. Damage ratios in the exported CSV are analytical, not measured encounter timing.


---

# Mage Slice — November 11, 2026

This independent project copy follows the Crownsfall Systems Expansion. The previous package and saves remain available.

- Added selectable Mage with five base spells, level-20 Fire/Frost/Arcane techniques and matching level-40 identities.
- Added class creation previews, name handling, class-filtered/scrollable Grimoire and future choice locks.
- Added immutable shared damage/DOT snapshots, current-stat tooltip evaluation, cast recovery and stale-cast cancellation.
- Added traveling/piercing projectiles, frost slow/freezing, valid-floor blink, active ward and delayed area casting.
- Fixed generator-on-miss behavior; a generator now rewards its first actual hit per cast.
- Fixed spell/weapon burn scaling, final DOT tick/partial interval and slot-dependent cooldown reduction.
- Added class stat growth, spell-power gear, 2×4 two-handed staffs, wand/focus and cloth bases with transaction rollback.
- Fixed ranged/empty/self-defensive primary targeting and remembered world aim for hotbar clicks.
- Added schema-3 class/resources/cooldown persistence; protected previous namespaces and retained opt-in schema-2 import.
- Fixed empty vendor stock regeneration on reload.
- Added 15 editable SVGs, 57 Mage checks, current data exports and revised handoff/status documentation.

Production Mage character art, shared 3D Mage gameplay, full mastery trees, Ember Aura, named unique powers, production sound and Windows export remain future work.

## Consolidated rig lab

- Preserved six canon reference boards, their overview and the original 58-bone GLB with six animation clips.
- Resolved imported animation-library paths and explicitly looped idle/walk/run.
- Added guarded F7 entry, save-before-transition and schema-3 return in an independent namespace.
- Verified 28 additional assertions in headless and rendered engine runs, including real bone motion, contact timing, dodge and ownership/resource preservation.
- Improved lab HUD readability and training-label size.

## Higgsfield art and feedback pass

- Integrated Mage sprites: five source facings, four walking poses, idle and two casting poses each. Warrior keeps its originals.
- Added eight spell paintings, seven gear paintings, a bonus source book, class portrait and blue/gold nine-slice modal skin; retained 39 vector fallbacks.
- Added thirteen procedural sound cues, bounded voice pooling, success-only hooks, persistent mute and graceful audio shutdown.
- Rejected the malformed combined GIF; retained source/reason. Preserved prompts, configurations and a rebuild helper verified against 45 derivative files.
- Added nineteen art/audio checks, bringing the unique total to 156.
