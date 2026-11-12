# Age of the Lost — complete Mastery and art transfer

November 11, 2026. Current source revision: Crownsfall Mastery + Higgsfield Art. 242 unique assertions passed; includes rendered evidence, actual gameplay previews, tuning exports, three validated demo records and retained art provenance. Godot source, not a Windows executable.


---

# Age of the Lost — Crownsfall Mastery + Higgsfield Art

November 11, 2026. Current playable source revision. Read `HANDOFF.md` for implementation boundaries and `docs/MASTERY_SYSTEMS.md` for precise rules. The previous Mage and art builds remain independent rollback copies.

## Play

1. Import `project.godot` in **Godot 4.6.3** and wait for asset imports. This is the tested Linux version; other versions/platforms remain unvalidated. This source package is not a Windows executable.
2. Choose Warrior or Mage and name your Wayfarer. Mage has five starting spells, staff/wand/focus equipment and its own painted directional art. Inventory, stash, vendor, discovery and the Scar remain functional.
3. Recover the plaza stone memory with E. Mage earns a mastery point every five levels from 20 to 60. M opens its Ashen Ward graph. F6 is a development level shortcut; the three validated records under `data/example_builds/` provide faster isolated demonstrations.
4. At level 40, invest Tempered Ward → Ember Aura → **one** of Cinder Bloom / Siphon Embers. The default Ashen Ward slot becomes Ember Aura without changing the saved ability ID. Press 3 to toggle it. It costs 10 mana to start, then pays each pulse; natural regeneration is reduced while active. Equip a burn source for Bloom.
5. At the recovered stone memory, a level-40 Mage can attune Emberwake Circlet once for 250 gold. Equip it in the head slot. It changes real pulse cadence and extends existing burns. Inventory space/currency failure consumes nothing.
6. F7 enters the independent 3D rig lab from town; F7/Escape returns with the same saved build. The lab uses a 58-bone/six-clip geometric proxy and its own training values.

| Input | Action |
|---|---|
| LMB / hold; Shift+LMB | Move or primary action; primary in place |
| RMB / 1; 2; 3; 4 | Four additional equipped slots |
| Q | Health potion |
| I / C; K / B; M | Inventory; Grimoire; Mage mastery graph |
| E; R | Nearby town service; open/close Scar |
| Escape; F11; F3 | Close/pause; fullscreen; navigation overlay |
| F6; F7 | Development level shortcut; independent 3D lab |

The Grimoire's list and long effect/assignment column scroll independently. Audio can be muted from Pause; its preference is separate from progression.

## Included work

Two playable classes, nineteen base/shared ability definitions plus the Ember Aura variant, five mastery nodes, one functional named unique, sixteen item bases and validated inventory/handedness/class restrictions. Mage art has 35 frames across five source facings (eight screen directions with mirroring). Twenty-one painted runtime icons, a bonus source book, 39 original SVGs, blue/gold modal skin, portrait and thirteen procedural sound cues are retained. Original canon boards remain unchanged.

Higgsfield source images, prompts/job configurations and reproducible processing scripts are included. All **51 derived PNG/WAV files** rebuilt byte-for-byte in Higgsfield's sandbox. A rejected combined GIF is clearly marked and excluded from gameplay. The clean front modeling reference is an image for future 3D work, not a mesh/rig. No paid Higgsfield credits were consumed; the requested Tripo mesh still quoted 9 against 1.5 available.

## Saves

Independent namespace: `AgeOfTheLost_Crownsfall_MasterySlice`; file `crownsfall_mastery_v4.json`, **schema 4**. Current resources/cooldowns, mastery ranks, once-only unique attunement, ownership and progression persist. Active aura, patches, casts and arena state do not. F7 cancels transient effects before saving. Offline cooldowns stay frozen.

Manual schema-2/3 import is opt-in: copy a backup into this new namespace with the new filename before launch. Older records gain unspent points, never an automatic transformation, heal or resource reset. Never overwrite the original record to perform migration. Future schemas activate write protection. See the demo-build README for isolated fixture use.

## Verification

Use isolated QA data directories. The suites deliberately create/change test progress.

On Linux the verified helper creates separate disposable user-data directories automatically:

```sh
python3 tools/run_checks.py --report-dir /tmp/aotl-qa-report
```

For manual runs, isolate data first and use:

```sh
godot --headless --path . --editor --quit
godot --headless --path . -- --systems-test
godot --headless --path . -- --mage-test
godot --headless --path . --script res://tests/lab_roundtrip.gd
godot --headless --path . --script res://tests/art_audio_integration.gd
godot --headless --path . --script res://tests/mastery_integration.gd
```

Current total: **242 unique checks** (52 Warrior, 57 Mage, 28 lab, 19 art/audio, 86 mastery), plus rendered engine runs. Exact logs and engine/display modes are under `tests/`. Tuning exports and validated example builds are under `data/`. The source ZIP excludes caches and live user-data directories.

Remaining production work includes an authored encounter, human tuning/audio review, Windows export/target hardware testing, additional character animation, real gear attachment visuals and the production 3D Mage. Current 2D clothing/staff are baked into the sprites. The lab remains an independent proxy testbed.


---

# Crownsfall — current Mastery and art handoff

Revision: November 11, 2026. This independently saved source revision extends the tested Higgsfield Mage art build. Original projects, prior ZIPs and canon references remain preserved. Historical handoffs are under `docs/previous_revision/`; current claims come from this README, `MASTERY_SYSTEMS.md`, runtime definitions and result logs.

## Result

Warrior and Mage remain playable. Mage has five base spells, three specialization/heroic paths, dedicated painted directional art, real projectile/cast/ward behavior and class-specific gear. The new work adds a five-node saved Ashen Ward mastery graph, paid Ember Aura, exclusive Cinder Bloom/Siphon Embers branches, Steady Flame and functional Emberwake Circlet attunement. The graph is an explicit investment, never an automatic class passive.

The source includes UI, inventory/stash/vendor/discovery interactions, spell/gear paintings, actor art, sound feedback, stat curves, tuning exports and validated demo builds. The separate F7 lab remains a 58-bone/six-clip geometric training scene. It is not the Mage combat simulation rendered in 3D.

## Implementation seams

| File | Responsibility |
|---|---|
| scripts/mastery_data.gd | Pure rank/point/prerequisite/exclusion validation, investment/refund planning and derived ability variant |
| scripts/aura_controller.gd | Paid scheduler, immutable pulse packet, bounded patches, actual-damage recovery ledger and unique burn extension |
| scripts/player.gd | Ownership/gear transactions, cast and visual timing, actual damage routing, mastery/attunement commit and cancellation |
| scripts/main.gd | World/services, idempotent kill hook, schema-4 validation/persistence, future-file protection and F7 transition |
| scripts/systems.gd | Inventory geometry, legal equipment, stat derivation, level-capped loot and recognized unique identity |
| scripts/effect_resolver.gd | Shared direct/DOT/ward math and current aura tooltip values |
| scripts/hud.gd / legacy_hud.gd | Graph, actual UI controls, unique inspector, scrollable Grimoire, variant icon and active ON indicator |
| scripts/art_library.gd / sound_bank.gd | Painted/vector routing, panel skin, reusable cue voices, persistent mute and graceful audio shutdown |
| tests/mastery_integration.gd | 86 regression/interaction assertions and actual rendered captures, including a mastery/unique F7 round-trip |

Read `docs/MASTERY_SYSTEMS.md` before modifying resource/proc rules. Aura retains saved ID `ashen_ward`; packets distinguish origin and proc depth. Secondary damage cannot retrigger patches or Siphon. The rolling recovery cap survives toggles/respec within a session. Item/cast snapshots do not read new equipment mid-flight. Aura equipment changes stop that running snapshot.

## Persistence and compatibility

Schema 4 stores ranks and once-only attunements alongside current HP/mana and stable-ID cooldowns. The new custom user directory and filename are in the README. Original namespaces are untouched. Explicit schema-2/3 import starts with unspent mastery and preserves existing current resources where supported; it does not auto-grant Aura. Future save files are write-protected. Invalid points, exclusions, unknown powers, fractional schema/currency and nonfinite numeric fields are rejected.

World drops/enemies, open arena state and active effects remain transient. Offline cooldowns do not advance. The loader is a prototype with preserved backups, not a general migration service or production anti-cheat economy.

## Data, sources and examples

- `data/mastery_nodes.json`, `implemented_ability_variants.json` and `runtime_unique_definitions.json` match implemented behavior.
- `data/mastery_balance_snapshot.csv` has 26 analytic checkpoints, including full point investment through level 60. Ratios exclude crit/variance, movement and other casts; they are not measured encounters.
- `data/example_builds/` contains three deliberately authored records that passed the real save validator. Its README describes isolated use. They are not captured user progress.
- Original canon images and GLB hashes are recorded in `CONSOLIDATED_PRESERVATION.json`. The original GLB is unchanged.
- Higgsfield accepted source images, the rejected experiment, prompts, job IDs and portable processors remain. The prior 45 art/audio derivatives plus six new mastery/unique crops reproduced byte-for-byte. The single front modeling reference is source art only; no Tripo/Meshy job completed.

## Verification

242 unique assertions pass: 52 Warrior + 57 Mage + 28 original lab + 19 art/audio + 86 mastery. Rendered tests/captures use actual Godot 4.6.3 Linux/X11/software OpenGL and Dummy audio, not concept mockups. The mastery suite verifies scene transitions with a real level-40 build, a named unique, exact resources/cooldown and art selection before the next physics frame. Review exact logs under `tests/`.

## Limits and next useful increment

The painted Mage is a prototype four-pose walk/two-pose cast set, with mirrored handedness. Hurt/dodge/death, equipment appearance changes, cloth/IK and production 3D remain. The 3D lab uses separate training controls/values. There is no universal resistance/proc engine, multiplayer simulation, production music mix, controller navigation or localization.

Recommended next increment: one authored Mage encounter and readability pass using the included Bloom/Siphon fixtures; measure survival, resource pressure and kill timing before broadening loot/classes. Then complete human/Windows/target-hardware validation and the real 3D Mage pipeline. Do not interpret the 56-bone/17-clip production Wayfarer mentioned in older documents as the included 58-bone/six-clip proxy.


---

# Mage mastery and Emberwake systems

Revision: November 11, 2026. This chapter describes implemented behavior. Earlier proposal chapters remain historical references. Mage/Warrior, inventory, equipment legality, immutable cast snapshots, painted art and the independent rig lab remain in place.

## Points, discovery and transactions

Mage earns one mastery point every five levels from 20 through 60: 1/2/3/4/5/6/7/8/9 at levels 20/25/30/35/40/45/50/55/60. Warrior has no implemented mastery graph. This is one five-node ability graph, not thirteen finished class trees.

| Stable node | Level | Cost per rank | Maximum | Requirements and effect |
|---|---:|---:|---:|---|
| ward_temper | 20 | 1 | 3 | Timed Ward absorbs 10% more per rank. After transforming, ranks 2–3 each add 5% aura pulse damage. |
| ember_aura | 40 | 2 | 1 | Requires Tempered Ward rank 1 and recovered `first_echo` stone memory. Transforms the equipped Ashen Ward into a paid toggle. |
| cinder_bloom | 40 | 2 | 1 | Requires Ember Aura. Radius +25%; qualified burning kills leave secondary cinder patches. |
| siphon_embers | 40 | 2 | 1 | Requires Ember Aura. Recover life from actual aura damage with a rolling cap. Exclusive with Cinder Bloom. |
| steady_flame | 45 | 1 | 2 | Requires Ember Aura. Upkeep −5% per rank; pulse damage/cadence unchanged. |

At level 40, rank-1 Ward + Aura + one branch spends exactly five points. Level 45/50 can add Steady Flame, and 55/60 can add the last Ward ranks. Alternatively, a character can invest in the defensive Ward first. Nothing is granted as an automatic base-class signature passive.

M opens the graph. Investment is computed on a copy and validates points, rank limits, level, discovery, prerequisites and the exclusion group before committing. Refund removes one rank and recursively removes invalid downstream nodes in one transaction; remaining valid prerequisites retain their dependents. Town refunds are free. Changes are rejected during an active Scar or death. Successful changes cancel queued casts, ward, aura and patches, preserve paid resources/cooldowns and save the new ranks.

## Stable skill identity and resource ledger

The saved hotbar ID remains `ashen_ward`. The current definition gains `variant: ember_aura`, its own displayed name/icon, type `aura`, and level-40 presentation. Moving slots preserves the same cooldown. A pre-existing Ward cooldown is not cleared by selecting the transformation.

Activation costs 10 mana and starts a 1-second activation cooldown before chosen cooldown reduction. First pulse occurs after 0.5 seconds. Each pulse pays 3 mana **before** applying its 0.30 spell-power coefficient in radius 2.5 ground units. Empty-space pulses still cost mana. If upkeep is unavailable, the aura stops before that pulse; no partial damage or negative resource balance is allowed.

Natural mana regeneration runs at **25%** while active; it returns to normal when off. Cinder Thread still restores mana on its first actual living-target hit. The quarter-regeneration rule prevents the ungeared level-40 baseline's ordinary regeneration from exceeding upkeep. High-Wisdom builds may still deliberately invest in sustain. Other spells, movement, avoidance and target access affect practical uptime.

Toggle off is free and bypasses the activation cooldown, resource check and ordinary recovery lock. It does not refund activation or erase cooldown. Removing Ashen Ward from all five active slots stops the aura. Death, respec, load, Scar closure and F7 scene entry cancel it and its patches. Successful equipment changes stop it so a cached unique modifier cannot continue after unequipping. World pause freezes the scheduler. A physics interruption above four seconds stops it rather than dumping an unbounded backlog.

Power, chosen damage modifiers and crit chance snapshot on activation. Direct pulses retain normal variance/crit behavior. Tempered Ward's extra pulse damage is also in that snapshot. Damage application reports actual HP removed, bounded by remaining HP; dead, invulnerable and nonpositive hits return zero. This supports recovery calculations without counting overkill. No general resistance/boss-immunity framework is implied by the test fixture's invulnerability flag.

## Cinder Bloom

Radius becomes 3.125 before enemy collision radius. While the aura is active, a primary kill of an already burning enemy, or its final burn tick, can create a patch. The first direct hit that kills an unburned target does not retroactively count as killing a burning target merely because that spell also applies a burn.

Each patch has radius 1, lasts 1 second and pays two half-second damage ticks totaling 0.15 snapshotted spell power before variance. It cannot crit, restore resources, heal through Siphon, extend burns or create another patch. Its packet uses origin `cinder_patch`, proc depth 1. Primary aura uses `ember_aura`, depth 0. These gates are local to this feature, not a finished global proc engine.

Patches whose centers would be less than two ground units apart do not stack or refresh. Eight patches is the hard global cap. Stopping the aura clears remaining patches. The actor's kill gate prevents duplicate reward/patch callbacks.

## Siphon Embers

Each primary aura hit can restore 2% of actual HP removed. An enemy with one remaining HP permits 0.02 life recovery even if the requested hit was enormous. Invulnerable or already dead targets allow none.

Actual restored life is recorded in a rolling one-second ledger. Recovery cannot exceed 3% of current max life in that window. Full-health overheal consumes no recovery budget. The ledger survives toggles, equipment changes and respec within the same actor session, preventing a rapid stop/start from resetting the cap. Secondary patches and other origins cannot feed the trigger.

## Emberwake Circlet

At the recovered stone memory, a living level-40 Mage outside a Scar can attune this item once for 250 gold. A full bag or insufficient gold leaves currency, inventory and attunement state unchanged. The 2×2 cloth item equips in the head destination; a recognized `unique_id` survives sanitation and save/load. It has 60 armor, 12 Intelligence and sells for 125 gold. Selling it does not restore the once-only attunement.

While an invested aura is used, the circlet changes its interval from 0.5 to 0.4 seconds and multiplies per-pulse damage and cost by 0.8. At the same character stats, coefficient/time and mana/time are unchanged. Steady Flame then multiplies upkeep. The unique's Intelligence can separately increase spell power and mana; the cadence claim does not erase those ordinary gear stats.

Actual aura hits extend an existing burn by 0.15 seconds, capped at four seconds **remaining**. Tick progress is preserved. A pre-existing longer burn is never shortened. The circlet does not start burns, affect secondary patches or supply an automatic aura. Its description, inspector and current Grimoire definition expose these rules.

The underlying rarity color/budget tier remains index 3 for compatibility; the item inspector labels the recognized item Unique. Other named uniques and the Crownless set remain proposals.

## Persistence and compatibility

Schema 4 adds `mastery` ranks by node ID and `crafted_uniques` stable IDs. Class/resources/cooldown state, ownership, stash, merchant stock and progression remain. Numeric ranks normalize to integers after JSON parsing. Invalid prerequisites, exclusions, overspending, unknown nodes/powers, fractional currency/schema and nonfinite data are rejected. A future schema activates write protection.

The new namespace is `AgeOfTheLost_Crownsfall_MasterySlice`, filename `crownsfall_mastery_v4.json`. Earlier playable projects and saves remain independent. Manually copying a backup schema-2/3 record into this new path is opt-in. Older records start with unspent mastery points and no consumed new attunements; legacy extra fields cannot silently grant new powers. Current HP/mana/cooldowns remain, with schema-2 defaults as before. No automatic aura activation or reload heal occurs.

Active aura, patches and the short rolling-heal ledger are transient. The F7 route saves after cancellation. A real level-40 Bloom/unique build was taken into the GLB lab and returned with exact mastery, unique UID, consumed attunement, paid HP/mana/cooldown and Mage art selected before its first physics frame.

## Art, examples and tuning

Five mastery paintings and an Emberwake painting came from Higgsfield job `674d526b-92ee-4d37-bb3e-3350d535b437`. The source atlas, prompt/configuration and portable `tools/rebuild_mastery_icons.py` are retained. All six crops reproduced byte-for-byte in Higgsfield's sandbox, in addition to the earlier 45 verified art/audio derivatives. The new single-character front modeling reference is a source image for future mesh work; it is not a generated or rigged 3D Mage.

Three deliberately authored schema-4 demo records in `data/example_builds/` passed the actual save validator. Their README explains isolated use. `tests/export_example_builds.gd` regenerates them. They are examples, not captured user progress.

`data/mastery_balance_snapshot.csv` contains 26 engine-exported checkpoints, including full point investment through level 60. Coefficients omit variance, crit, enemy mitigation, other casts and movement. Level-40 ungeared selected Pyromancer: 378.615 spell power, 227.169 nominal aura damage/s, upkeep 6 mana/s, active natural regen 3.14/s, net −2.86/s. Roughly 0.953 valid Cinder hits/s offset that isolated deficit. These are analytic tuning values, not encounter or hardware benchmarks.

## Verification and next work

The export also has earned/spent point columns. `tools/plot_mastery_balance.py` creates the analytic PNG/PDF under `docs/figures/`; it contrasts gear/full-mastery damage with natural mana pressure. It does not claim measured kill time or native hardware performance.

The current suites cover Warrior, Mage, art/audio, the original lab and the mastery lifecycle, including the full mastery/unique F7 round-trip. Inspect exact result logs rather than treating this chapter as a test runner. Rendered captures show the graph, item inspector, aura and scrollable Grimoire controls. The visible ON state remains tied to the actual aura controller.

Next work: authored encounter and target readability, human tuning/listening review, Windows export/target hardware testing, dedicated hurt/dodge/death animation, gear attachment visuals and integration of the real 3D Mage pipeline once its source/credits are available. The existing 58-bone/six-clip geometric lab remains independent training gameplay; it is not the authoritative Mage simulation rendered in 3D.


---

> Art-pass provenance: the current Mastery revision adds six painted mastery/unique icons, a front modeling reference and a schema-4 gameplay layer. Current totals and rules are in `MASTERY_SYSTEMS.md` and the root README. The 156-check count below identifies the earlier art milestone.

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

At level 40, chosen Pyromancer training adds 20% to the spell-power multiplier; Glacial Sovereign adds 30% specialization radius; Chronomancer grants 20% cooldown reduction. These are selected progression modifiers, not automatic base-class signature passives. Ashen Ward now has an implemented investable graph and Ember Aura variant; see `MASTERY_SYSTEMS.md` for the selected-node rules.

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

The generic focus is called Prismatic Focus. The named unique Riftglass Focus remains a distinct proposal. Emberwake Circlet is now implemented separately as a recognized cloth head item; see `MASTERY_SYSTEMS.md`. “Legendary” still describes the prototype's rarity/stat tier, not a bespoke effect framework. Dual wield is not implemented.

Equipment comparisons use the current class curve. Mage comparisons display spell-power differences, not a Warrior damage proxy. Staff comparisons account for losing the focus. Legal gear can still fail a swap when displaced items cannot fit in the bag; failure preserves the original state.

## Saves, economy and migration

Schema 4 retains chosen class/resources/stable-ID cooldowns and adds mastery/attunement state; schema-2/3 import is explicit. It validates field types before model calls, rejects unknown classes/duplicate item IDs/illegal equipped states, recovers backups and protects future schema versions. The new namespace preserves previous playable saves independently. Manual schema-2 import is intentionally opt-in.

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

# Current implementation status

| Area | Implemented | Remaining |
|---|---|---|
| Shared effect calculation | Immutable power/buff packets; direct/DOT/tooltips; exact partial burn ticks | Universal conditions/resistances, deterministic RNG and combat log |
| Class/gear slice | Warrior + Mage, five Mage spells, three paths, cloth/staff/wand/focus and atomic ownership swaps | Eleven planned classes, broader weapon families and authored class encounters |
| Saved mastery | Five-node graph, points, ranks, discovery/prerequisites, exclusions and cascading town refunds | Further ability/class graphs and production respec policy |
| Ember Aura | Explicit paid toggle, paid pulses, quarter natural regen, stable cooldown ID and full cancellation | Human tuning and broader encounter testing |
| Cinder Bloom / Siphon | Non-stacking capped patches, secondary-origin gates, actual-damage recovery and rolling cap | General reusable proc/effect framework |
| Named gear | Emberwake Circlet, once-only paid attunement, recognized unique persistence and actual cadence/burn effect | Other uniques/Crownless sets remain proposals |
| UI/art/audio | 35 Mage frames, 21 painted runtime icons, original 39 vectors, skin/portrait, 13 cues/mute, scrollable spell details | Additional clips, attachment visuals, human mix, controller/localization |
| Persistence | Schema 4, current resources/CDs/ranks/attunements, backups and future write protection; opt-in older import | World/drop persistence and production migration/economy service |
| 3D lab | Preserved actual 58-bone/six-clip proxy, runtime loop resolution, guarded F7 round-trip | Production Mage mesh, shared authoritative Mage simulation in 3D |
| QA | 242 unique checks and rendered engine passes; three validated demo builds | Native Windows, target hardware and human usability/balance review |

Next: one authored encounter with measured tuning and readability. Current gameplay/appearance boundaries are documented in `MASTERY_SYSTEMS.md`; older status chapters are historical.


---

# Current QA and reproduction

On Linux, `python3 tools/run_checks.py --report-dir /tmp/aotl-qa-report` runs import and all five suites in separate disposable XDG directories, checks full logs and writes a JSON summary. This helper itself passed 242 assertions. It is intentionally Linux-only; use an isolated project/user directory on other platforms.

Godot 4.6.3 stable on Linux. Rendered runs use X11/Xvfb, software OpenGL and Dummy audio. Tests operate real scripts, UI signals and scene changes; they are not human usability or native Windows validation.

| Suite | Checks |
|---|---:|
| `-- --systems-test` | 52 |
| `-- --mage-test` | 57 |
| `--script res://tests/lab_roundtrip.gd` | 28 |
| `--script res://tests/art_audio_integration.gd` | 19 |
| `--script res://tests/mastery_integration.gd` | 86 |
| Total distinct assertions | 242 |

Use a project copy and isolated data directories. On Linux set XDG_DATA_HOME, XDG_CONFIG_HOME and XDG_CACHE_HOME to dedicated QA directories outside the source project. On Windows use a separate Custom User Dir Name. Suites intentionally create/alter their QA saves.

First run `godot --headless --path . --editor --quit`. Then run the five commands above with `godot --headless --path .`. For rendered tests, omit headless and pass `--audio-driver Dummy`. Review the whole result log for script errors, failed assertions and leaked playback resources, as well as the final count.

Mastery assertions cover rank/point gates, exclusion, cascading/partial refunds, immutable pulse power, pre-payment and insufficient mana, quarter/restored regeneration, actual radius/cadence, cancellation/death/slot removal, combat-respec rejection, overkill/immunity/rolling recovery, cap preservation across toggles, secondary recursion/overlap/lifetime/cap, unique sanitation/equip/burn extension, atomic crafting, schema-4 round-trip, older import, fractional/future-file protection, final Grimoire assignment scroll reach, and actual mastery/unique/resources/art preservation through F7.

Rebuild exports with `tests/export_mastery_data.gd`. It writes actual definitions and 26 analytic checkpoints, not timing benchmarks. `tests/export_example_builds.gd` intentionally creates QA progress, validates it and writes three labeled fixtures. Their README explains isolated manual use.

Manual gate: create/name both classes; recover memory; compare staff against wand/focus; force full-bag rollback and crafting failure; invest/refund both exclusive branches; test Aura beside/outside targets; toggle at low mana; move it between slots and remove it; apply burns with Solar Writ/Cinderwake; attune/equip the circlet; verify the displayed and observed cadence; save wounded/low-mana/cooling state; enter/return from lab; review all panels at multiple window sizes; test on Windows and target hardware. Native export, signed executable, broad controller/accessibility and production audio listening are not claimed.

Screenshots in previews are real engine captures of controlled fixtures. Sampled GIFs omit audio. Source boards/experiments are labeled separately. The large rejected native GIF is not used by gameplay.


---

# Deliberate demo builds

These three records were created by `tests/export_example_builds.gd` and passed the actual schema-4 save validator. They are authored examples, not a user's captured progress.

- `ward_level20.json`: Mage with Tempered Ward, before the aura transformation.
- `bloom_level40.json`: Pyromancer with Ember Aura, Cinder Bloom and an equipped Emberwake Circlet.
- `siphon_level40.json`: the same gear/path with the exclusive Siphon branch.

Each includes known gear ownership, a starter bag, 500 gold, a small merchant stock, the recovered stone memory and full resources. The level-40 records already consumed the once-only circlet attunement. Aura begins off and still requires activation/upkeep.

To try one, use a **project copy** with Custom User Dir Name changed to a separate demo namespace. Close the running game, locate that copy's user-data folder through Godot's **Project → Open User Data Folder**, and copy one record there as `crownsfall_mastery_v4.json`. Preserve any previous file first. Reopen the game, press M for the graph, K for the current aura tooltip and 3 for the default fourth-slot aura. Use R to start the Scar. Cinder Bloom needs a burning target; equip Solar Writ or Cinderwake to apply a burn. The same JSON ownership rules apply to demo and ordinary saves.

The fixtures are separate alternatives, not automatically imported content. Rebuild only in isolated test data directories; the export script intentionally writes its temporary QA save before producing these records.


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

## Mastery and unique revision

- Added five-node paid-investment Mage graph, point/level/discovery/prerequisite gates, exclusion and cascading town refunds. Upper Ward ranks retain a pulse-damage benefit after transformation.
- Added paid Ember Aura, quarter natural regeneration, stable base skill/cooldown identity, actual ON display, slot/equipment/cancel lifecycle and immutable power.
- Added Cinder patch origin/recursion/overlap/lifetime/global caps and actual-damage Siphon with a rolling cap preserved across toggles.
- Added once-only 250-gold Emberwake attunement, real unique cadence/payment/burn extension, known-ID persistence and atomic failure behavior.
- Added schema 4 and separate namespace, older-save opt-in with unspent points, numeric canonicalization and future/fractional save protection.
- Fixed above-cap elite loot generation, immediate class-art selection on create/load, long Grimoire assignment scrolling and overly bright pillar/pulse presentation.
- Added six Higgsfield paintings, a clean front modeling reference, six verified rebuild crops, 26 engine tuning checkpoints and three validated example records.
- Added 86 mastery checks including a real mastery/unique F7 round-trip, for 242 distinct assertions total.
