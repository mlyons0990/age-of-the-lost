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
