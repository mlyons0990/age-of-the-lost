# Unwritten Cantor — implemented encounter handoff

November 11, 2026. New authored prototype content. The uploaded handoff/canon files supplied project context; this encounter was added as an implementation proposal. Its new name, portrait and mechanics are not asserted to be original canon. Prior Mastery/source deliveries are preserved independently.

## Entry and player flow

Press T or use the Cantor Trial menu button. The noticeboard also links the briefing. Enter dismisses the modal, cancels transient casts/aura, clears movement intent and moves the Wayfarer to the plaza start sigil. Health, mana, inventory, equipment, potions and cooldowns carry in; entry grants no heal, refill or new equipment. Warrior and Mage are both accepted at levels 1–60. A living player, no active Reality Scar and a writable valid save are required. A repeated entry cannot duplicate actors. Ordinary gameplay is unchanged outside the trial.

The rooted Cantor uses the inherited painted Revenant body, an antique-gold floor rune and a dedicated boss bar. The new Higgsfield portrait appears in the briefing. No new enemy animation bank, production rig or 3D mesh was created. Two real Unwritten Fragments use inherited Slime bodies and chase/contact mechanics. They appear on entry and once more at half boss health. Every target accepts the shared immutable direct/burn/frost/aura packets. Boss knockback is suppressed; stun delays the next uncommitted cast, while already drawn seals continue. Slows do not move the rooted boss.

## Attack contract

The first warning starts after 2.0 seconds. Rotation repeats Line → Seals → Ring. Phase-one start-to-start spacing is 3.7 seconds, phase two 3.0 seconds, subject to a living, unstunned caster and no existing warning. The phase transition does not erase or replace an existing warning, and it occurs once at 50% health. Each attack reads positions at warning creation; later movement cannot rotate or relocate that warning. Crossbars, circle crosses, a clear ring center, attack name, countdown and fill-progress line supplement red/gold color.

| Attack | Ground-unit geometry | Verse 1 warning | Verse 2 warning | Escape |
|---|---|---:|---:|---|
| Severing Line | Fixed origin/direction, length 7, half-width 0.48 | 1.25s | 1.05s | Move sideways or behind origin |
| Falling Seals | Three radius-1.05 circles at captured player position and ±1.9 on ground X | 1.50s | 1.30s | Leave the circles |
| Unmaking Ring | Captured boss center; annulus inner 1.35, outer 3.30 | 1.65s | 1.45s | Enter center or move outside |

All live hit tests include player ground radius 0.28. The safe inner ring therefore ends at radius 1.07 and the exterior becomes safe above 3.58. The line extends by the actor radius at both ends. The drawing shows the spell footprint; actor overlap is the contact rule. `encounter_rules.gd` supplies the same geometry to the director and integration tests. A circle volley resolves as one union: overlapping circles cannot multiply damage. Each committed warning hits at most once, on expiry. Impact graphics last 0.22s and deal no further damage. Boss hit damage passes through the existing `player.hurt`: armor, ±10% variance, invulnerability and timed Ward absorption remain authoritative.

## Scaling and rewards

Let n = clamp(level, 1, 60) − 1. Tuning is snapshotted at entry, independently of equipment. `tools/export_encounter_data.gd` exports the current engine definitions/checkpoints.

- Boss HP = round(360 × (1 + 0.12n)^1.75).
- Fragment HP = round(24 × (1 + 0.12n)^2.15).
- Raw boss hit = 10 + 4 × level. Fragment contact damage = 35% of this, using existing contact cadence and armor handling.
- Victory gold = 120 + 8 × level. Gold clamps to the existing 999,999,999 cap.
- Victory XP = round(20% of the player's current level XP requirement), using normal progression. One class-appropriate item is generated at the entry level with existing quality bias 0.4 and dropped on the plaza floor. This does not promise a particular rarity or item base.

At level 40 the Cantor has 7,523 HP; each fragment has 1,005 HP; a warned hit starts at 170 raw damage; gold is 440. Fragments have sufficient high-level health to survive the initial Solar Writ hit in the tested unequipped build, allowing existing burns and Bloom to matter. Fragment deaths and the boss do not independently grant random gold/items, XP, quest kill counts or elite kills. The single victory transaction supplies the reward budget. The old random-wave kill path remains intact for ordinary enemies.

The director marks the run inactive before resolving rewards, making repeated finish/kill callbacks harmless. Surviving owned enemies are faded/removed from target lists; casts/aura/patches are cancelled. Gold, XP and victory count are committed to the ordinary atomic save. The gear drop remains collectable when the bag is full. Floor loot is transient and will be lost on quitting/reloading; the briefing states this. Replay rewards are intentional prototype behavior, with no fee, lockout or daily claim. The economy still requires human tuning.

## Cancellation and persistence

R during a trial retreats, without opening the Scar. The briefing offers a retreat button. Moving beyond seven ground units of the entry sigil ends the run; this boundary is marked and imposes no invisible wall. Death, a successful save load, or a frame delta above 0.5 seconds ends the trial and clears every warning, impact and owned target. Negative manual deltas clamp to zero. Long-frame suspension gives no reward and does not resolve accumulated hits. No timer/callback owns trial warnings; the director's arrays are the entire hazard lifetime.

Pause, inventory, Grimoire and briefing stop encounter time, enemies and effects. Town vendor/stash/lore actions, mastery investment/refund and F7 are blocked during the trial. Gear changes retain the existing cancellation rule for snapshotted Aura. Opening the mastery view is allowed but transactions remain disabled/rejected. User-facing failure text explains these gates.

The Encounter build has its own custom user namespace `AgeOfTheLost_Crownsfall_EncounterSlice`, filename `crownsfall_encounter_v4.json`. Existing Mastery saves are untouched. Schema 4 adds optional `encounter_wins`; it must be a finite integer 0–999,999 when present. Earlier schema-4 data without it is valid and starts at zero; schema-2/3 imports also start at zero. Counter increments clamp at 999,999. Active run/phase, boss HP, enemies, warnings, patches, metrics and floor loot are not saved. Save load aborts the old run without writing over the file being loaded. Future-schema protection, backups, corrupt preservation and ownership validation remain inherited. To migrate deliberately, close the game and copy a validated older record to this new namespace/filename, preserving both originals. No automatic migration was performed.

Two related shared fixes ship here: a Bloom patch that kills the boss can synchronously cancel/clear its own patch list, so patch iteration now returns immediately after such cancellation; and an immediate scripted kill before navigation synchronization drops at the victim's valid floor point instead of querying an empty map.

## Measured scripted bouts

`tests/encounter_playthrough.gd` advances production player movement/cast roots, navigation, projectiles, enemy contacts/status/burns, effect callbacks and director collision at fixed 0.05s steps. Its scripted agent seeks a nearby safe point, walks with the normal player path/speed, casts unlocked attacks and may use ordinary potions. It does not teleport to dodge, inject damage, waive mana/cooldowns or force boss death. Tests mute cue playback; audio has its own suite. These are repeatable component-level simulations, not human tests, a win-rate sample or hardware/frame-rate benchmarks. RNG remains the shared engine RNG with explicit seeds, not a dedicated deterministic combat stream.

All four bouts use no gear, a fresh 100-gold fixture, three potions and full mana. Level-one classes start at full health. Both level-40 Pyromancer branches start at 280/560 HP to expose sustain; hotbar includes Cinder Thread, Solar Writ, Arcane Fold, Ember Aura and Starfall Script. No named unique is equipped in these measurements. The deliberate demo records in `data/example_builds` are separate, geared alternatives.

| Fixture / seed | Completion | Start → end HP | Warnings resolved / contacts | Aura pulses | Observation |
|---|---:|---:|---:|---:|---|
| Mage 1 / 1001 | 25.40s | 92 → 87.62 | 7 / 1 | 0 | One real warned hit; all four fragments defeated |
| Warrior 1 / 1002 | 28.80s | 100 → 100 | 8 / 0 | 0 | Ordinary melee/cast roots/path movement complete encounter |
| Bloom 40 / 1040 | 13.05s | 280 → 367.70 | 3 / 0 | 26 | A real burning fragment death produces a patch |
| Siphon 40 / 2040 | 13.50s | 280 → 440.40 | 3 / 0 | 27 | Actual aura damage supplements passive regeneration |

All bouts ended alive with all three potions. Minimum mana was 439.69/493 in both level-40 bouts; aura resource pressure is light in these short fixtures. Positive HP changes include normal regeneration; do not label the full increase as Siphon healing. Separate collision tests force damage, invulnerability/resource gates, death and cleanup. Different seeds and scripted action timing mean these four rows cannot establish which branch is strongest. Full-gear/unique builds, long fights, human reaction time, repeated seeds and lower-resource starts remain needed before changing core Mage balance.

## Files and validation

- `scripts/encounter_rules.gd`: pure geometry and level tuning.
- `scripts/encounter_director.gd`: entry, warning scheduler, phases, level snapshot, contacts, terminal transaction and world drawing.
- `scripts/trial_boss.gd`: inherited body with rooted behavior and regular status/DOT processing.
- `scripts/trial_hud.gd`: dedicated health/verse/cast status, positioned above menu controls.
- `scripts/main.gd`, `player.gd`, `hud.gd`, `legacy_hud.gd`: ownership hook, combat gates, optional counter and briefing controls.
- `tests/encounter_integration.gd`: 60 collision, gate, persistence, cleanup and branch assertions, plus rendered captures.
- `tests/encounter_playthrough.gd`: 15 assertions over the four measured production-component bouts.
- `data/encounter_rules.json`, `encounter_scripted_bouts.json`, `cantor_art_manifest.json`: exported definitions, measurements and source provenance.
- `tools/rebuild_cantor_portrait.py`: retained source → 512px runtime portrait, SHA-256 manifest.
- `previews/encounter/`: actual Godot captures, not concept mockups.

The inherited 242 assertions plus 75 new ones total 317. Run `python3 tools/run_checks.py --report-dir /tmp/aotl-qa` on Linux for isolated user data, first import and strict error/leak checks. The source package must also pass after extraction into a clean folder before delivery. No Windows executable/export or target-hardware performance claim is made.

## Concrete next tasks

1. Have a human play both classes at 1, 20, 40 and 60, then the two geared example records. Record missed warning reasons, control reachability, ring-hole clarity, camera/occlusion and subjective pace. The rooted caster plus different briefing portrait is a documented placeholder.
2. Run a matrix of equal seeds, full/half mana, current gear and Emberwake Circlet. Compare survival, cast downtime, resource pressure and fragment patch uptime. Preserve raw JSON alongside conclusions.
3. Tune per-victory gold/XP/drop frequency against vendor prices and once-only attunement. Avoid broad class/stat changes based on four scripted bouts.
4. Add authored body poses/VFX for the boss and actor hurt/dodge/death; then equipment attachment appearance. Keep warnings generated by authoritative ground geometry.
5. Validate target Windows/Godot export and hardware. Continue production 3D Mage generation/rigging only when its actual quoted resource cost is available; the included 3D lab stays an independent proxy scene.
