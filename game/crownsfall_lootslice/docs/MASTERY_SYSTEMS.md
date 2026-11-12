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

The new namespace is `AgeOfTheLost_Crownsfall_EncounterSlice`, filename `crownsfall_encounter_v4.json`. Earlier playable projects and saves remain independent. Manually copying a backup schema-2/3 record into this new path is opt-in. Older records start with unspent mastery points and no consumed new attunements; legacy extra fields cannot silently grant new powers. Current HP/mana/cooldowns remain, with schema-2 defaults as before. No automatic aura activation or reload heal occurs.

Active aura, patches and the short rolling-heal ledger are transient. The F7 route saves after cancellation. A real level-40 Bloom/unique build was taken into the GLB lab and returned with exact mastery, unique UID, consumed attunement, paid HP/mana/cooldown and Mage art selected before its first physics frame.

## Art, examples and tuning

Five mastery paintings and an Emberwake painting came from Higgsfield job `674d526b-92ee-4d37-bb3e-3350d535b437`. The source atlas, prompt/configuration and portable `tools/rebuild_mastery_icons.py` are retained. All six crops reproduced byte-for-byte in Higgsfield's sandbox, in addition to the earlier 45 verified art/audio derivatives. The new single-character front modeling reference is a source image for future mesh work; it is not a generated or rigged 3D Mage.

Three deliberately authored schema-4 demo records in `data/example_builds/` passed the actual save validator. Their README explains isolated use. `tests/export_example_builds.gd` regenerates them. They are examples, not captured user progress.

`data/mastery_balance_snapshot.csv` contains 26 engine-exported checkpoints, including full point investment through level 60. Coefficients omit variance, crit, enemy mitigation, other casts and movement. Level-40 ungeared selected Pyromancer: 378.615 spell power, 227.169 nominal aura damage/s, upkeep 6 mana/s, active natural regen 3.14/s, net −2.86/s. Roughly 0.953 valid Cinder hits/s offset that isolated deficit. These are analytic tuning values, not encounter or hardware benchmarks.

## Verification and next work

The export also has earned/spent point columns. `tools/plot_mastery_balance.py` creates the analytic PNG/PDF under `docs/figures/`; it contrasts gear/full-mastery damage with natural mana pressure. It does not claim measured kill time or native hardware performance.

The current suites cover Warrior, Mage, art/audio, the original lab and the mastery lifecycle, including the full mastery/unique F7 round-trip. Inspect exact result logs rather than treating this chapter as a test runner. Rendered captures show the graph, item inspector, aura and scrollable Grimoire controls. The visible ON state remains tied to the actual aura controller.

Next work: authored encounter and target readability, human tuning/listening review, Windows export/target hardware testing, dedicated hurt/dodge/death animation, gear attachment visuals and integration of the real 3D Mage pipeline once its source/credits are available. The existing 58-bone/six-clip geometric lab remains independent training gameplay; it is not the authoritative Mage simulation rendered in 3D.
