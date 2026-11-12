> ARCHIVED SYSTEMS EXPANSION: the current Mage Slice handoff and README supersede implementation/status claims in this chapter.

# Content blueprint and schemas

This chapter separates inherited class direction, implemented technique data and new proposals. New base kits and item powers are not approved final canon or implemented mechanics. All IDs are stable semantic keys, suitable for later validated definitions.

## Thirteen classes and thirty-nine paths

| Base class | Armor | Level 20 → Level 40 | Runtime status |
|---|---|---|---|
| Warrior | Plate | Weaponmaster → Bladestorm Paragon; Bastion Guard → Citadel Sentinel; Berserker → Bloodbound Warlord | implemented single class |
| Mage | Cloth | Fire → Pyromancer; Frost → Glacial Sovereign; Arcane → Chronomancer | design only |
| Rogue | Leather | Assassin → Night Reaper; Trickster → Phantom Jester; Duelist → Blade Virtuoso | design only |
| Druid | Leather | Grove Warden → Worldroot Guardian; Shapeshifter → Primal Avatar; Stormspeaker → Tempest Sage | design only |
| Ranger | Mail | Deadeye → Starshot; Beastkeeper → Wildbond Alpha; Trapper → Briar Architect | design only |
| Oathkeeper | Plate | Dawn Vanguard → Sunward Justiciar; Aegis Keeper → Hallowed Bastion; Ashen Inquisitor → Cinder Arbiter | design only |
| Spiritcaller | Mail | Tempest → Storm Herald; Earthkeeper → Worldshaper; Ancestor → Echobound Sage | design only |
| Oracle | Cloth | Luminary → Dawn Saint; Veil Shepherd → Soul Shepherd; Mindweaver → Dream Architect | design only |
| Hexbinder | Cloth | Infernal Binder → Hellchain Sovereign; Plague Hexer → Rot Covenant; Void Scholar → Abyss Archivist | design only |
| Disciple | Leather | Iron Fist → Mountain Hand; Flowkeeper → Everflow Master; Mist Dancer → Veilrunner | design only |
| Graveknight | Plate | Bloodbound → Sanguine Dreadlord; Frost Warden → Winter Revenant; Bonecaller → Ossuary Monarch | design only |
| Riftblade | Leather | Voidblade → Eclipse Harbinger; Riftstalker → Foldwalker; Chaosbreaker → Ruin Sentinel | design only |
| Aethercaller | Mail | Starflare → Astral Herald; Prismcraft → Prism Sovereign; Lifeward → Genesis Keeper | design only |

Race is separate from class. Concept art titles such as Threshold Keykeeper and Hollow Sun Arbiter are not additional base classes. Preserve unusual non-human silhouettes without making all non-human beings antagonists. Appearance, class, race, faction and historical epoch need independent IDs.

## Eleven implemented techniques

| Runtime ID | Display name | Type | Cost | Cooldown | Power coefficient | Unlock |
|---|---|---|---|---|---|---|
| breath | Furnace Sweep | cone | 25.0 mana | 6.0s | 2.4 | Level 20; matching specialization |
| charge | Shield Charge | dash | 15.0 mana | 6.0s | 1.3 | Level 1 |
| cleave | Cleave | arc | 12.0 mana | 2.5s | 1.6 | Level 1 |
| dawnfall | Dawnfall | ground | 30.0 mana | 12.0s | 3.0 | Level 10 |
| echo_strike | Echo Strike | ground | 16.0 mana | 5.0s | 2.1 | Level 1; first_echo |
| ember_cone | Cinderwake | cone | 18.0 mana | 5.0s | 1.8 | Level 6 |
| frost_ring | Winterglass Pulse | nova | 18.0 mana | 8.0s | 1.5 | Level 4 |
| hammer | Sundering Standard | ground | 28.0 mana | 7.0s | 3.2 | Level 20; matching specialization |
| harvest | Citadel Reprisal | nova | 26.0 mana | 8.0s | 2.2 | Level 20; matching specialization |
| rally | Rallying Cry | buff | 20.0 mana | 16.0s | — | Level 1 |
| slash | Slash | melee | -4.0 mana | 0.55s | 1.0 | Level 1 |

Slash currently restores resource on activation, including a miss. The proposed broader generator model restores resource on a successful hit. This is a known design/implementation distinction to resolve in the combat effect pass.

## Five base-ability entries per class

The following sixty-five entries provide a concrete starting point. Five Warrior entries are already implemented; the remaining sixty are new design proposals. Cooldowns, resource budgets and coefficients for unimplemented classes require testing after resource engines and animations exist. Additional known abilities may be offered beyond the five equipped slots. The current runtime still starts with four abilities and discovers the optional fifth.

### Warrior

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| slash / Slash | generator | -4 mana (prototype); 0.55s | A short weapon arc. Generate 4 mana on activation. |
| cleave / Cleave | area | 12 mana (prototype); 2.5s | Wide frontal sword sweep; delayed contact at 0.2 seconds. |
| charge / Shield Charge | mobility | 15 mana (prototype); 6s | Dash through enemies; one damage event per target per charge. |
| rally / Rallying Cry | recovery | 20 mana (prototype); 16s | Recover 25% maximum life and gain 30% damage for six seconds. |
| echo_strike / Echo Strike | discovery | 16 mana (prototype); 5s | Lorecasting-unlocked delayed area strike; requires first_echo. |

### Mage

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| cinder_thread / Cinder Thread | generator | -3 mana; 0.7s | A narrow fire projectile that restores mana on direct hit. |
| glacial_stitch / Glacial Stitch | control | 14 mana; 5s | A frost line slows for two seconds; second hit briefly roots. |
| arcane_fold / Arcane Fold | mobility | 16 mana; 8s | Blink to a valid ground point; leave a decoy memory for one second. |
| ashen_ward / Ashen Ward | defense | 20 mana; 12s | Absorb damage for three seconds; can later transform into Ember Aura. |
| starfall_script / Starfall Script | area | 24 mana; 7s | Mark a circle and strike after 0.8 seconds; deliberate area denial. |

### Rogue

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| needlecut / Needlecut | generator | -5 energy; 0.45s | A fast dual-blade thrust restores energy when it connects. |
| crossed_wounds / Crossed Wounds | damage | 20 energy; 5s | Two cuts apply separate bleeds that do not snapshot crit. |
| smoke_step / Smoke Step | mobility | 18 energy; 7s | Dash behind a selected target if the destination is walkable. |
| false_opening / False Opening | defense | 15 energy; 10s | A timed evasive stance empowers the next strike after a dodge. |
| silken_snare / Silken Snare | control | 22 energy; 8s | Lay a visible wire trap; first enemy triggers a short root. |

### Druid

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| briar_lash / Briar Lash | generator | -4 spirit; 0.75s | A curving vine strike restores spirit on impact. |
| rootwake / Rootwake | control | 16 spirit; 7s | Roots advance along the ground and pin the first cluster hit. |
| wildbound_leap / Wildbound Leap | mobility | 18 spirit; 8s | Leap along an arc and land with a small shockwave. |
| mending_grove / Mending Grove | recovery | 24 spirit; 12s | Create a small healing field; leaving it ends its benefit. |
| stormseed / Stormseed | area | 20 spirit; 6s | A planted seed bursts into lightning after two seconds. |

### Ranger

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| fletched_shot / Fletched Shot | generator | -4 focus; 0.65s | A deliberate aimed arrow restores focus on a hit. |
| thornfan / Thornfan | area | 18 focus; 5s | Fire a spread; each target takes one full hit and reduced overlaps. |
| trailbreak / Trailbreak | mobility | 14 focus; 7s | Roll away from aim direction and clear minor slows. |
| hawkmark / Hawkmark | setup | 12 focus; 9s | Mark a single target; the next three aimed shots expose its defenses. |
| briar_trap / Briar Trap | control | 22 focus; 8s | A placed trap binds one cluster; bosses receive a slow instead. |

### Oathkeeper

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| oathstrike / Oathstrike | generator | -4 conviction; 0.7s | A measured weapon strike builds conviction on contact. |
| dawnline / Dawnline | area | 18 conviction; 6s | A short radiant line crosses the ground and hits once. |
| aegis_march / Aegis March | defense | 20 conviction; 10s | Advance slowly with frontal protection; cannot cast during the march. |
| witness_vow / Witness Vow | recovery | 24 conviction; 12s | Bind a visible sigil to an ally or self; heal after a short delay. |
| cinder_verdict / Cinder Verdict | damage | 25 conviction; 8s | Spend stored conviction on a single impact, without free class procs. |

### Spiritcaller

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| echo_bolt / Echo Bolt | generator | -4 resonance; 0.75s | Launch an ancestral echo that restores resonance on contact. |
| storm_totem / Storm Totem | area | 22 resonance; 8s | Place a destructible totem that pulses three times. |
| stone_refuge / Stone Refuge | defense | 24 resonance; 12s | Raise a temporary barrier with a clear durability bar. |
| ancestor_step / Ancestor Step | mobility | 16 resonance; 9s | Return to a placed ancestral footprint within three seconds. |
| fault_hymn / Fault Hymn | control | 18 resonance; 6s | Crack the ground in a line; knock back small enemies. |

### Oracle

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| lucent_word / Lucent Word | generator | -4 insight; 0.7s | A clear projectile restores insight on hitting an enemy. |
| mercy_thread / Mercy Thread | recovery | 22 insight; 8s | Link to a target and heal while maintaining line of sight. |
| veilbell / Veilbell | control | 20 insight; 9s | A visible ringing circle briefly disorients normal enemies. |
| dream_passage / Dream Passage | mobility | 16 insight; 8s | Travel to a nearby marked point; cannot cross sealed doors. |
| dawn_sentence / Dawn Sentence | damage | 24 insight; 6s | A slow, powerful radiant bolt that rewards careful aim. |

### Hexbinder

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| inkspike / Inkspike | generator | -4 resolve; 0.7s | An ink projectile restores resolve on enemy contact. |
| hellchain / Hellchain | control | 20 resolve; 8s | Attach a visible tether; breaking its radius triggers one damage event. |
| rot_seal / Rot Seal | damage | 18 resolve; 6s | A placed curse deals damage over four seconds; one stack per caster. |
| borrowed_shade / Borrowed Shade | defense | 22 resolve; 12s | A temporary shade intercepts one hit, then expires. |
| null_door / Null Door | mobility | 16 resolve; 9s | Step through a short-lived ground portal with a visible exit. |

### Disciple

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| foundation_palm / Foundation Palm | generator | -5 flow; 0.5s | A close strike builds flow on contact. |
| mountain_break / Mountain Break | damage | 20 flow; 6s | A committed palm impact with a short stun on normal targets. |
| river_turn / River Turn | mobility | 14 flow; 5s | A curving sidestep repositions around a selected enemy. |
| stillwater_guard / Stillwater Guard | defense | 16 flow; 10s | Time a brief guard; a successful block unlocks an active riposte. |
| mistwheel / Mistwheel | area | 24 flow; 8s | Spin through a short arc with a readable start and finish. |

### Graveknight

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| grave_edge / Grave Edge | generator | -4 grave_reserve; 0.75s | A heavy blade strike builds grave reserve on contact. |
| blood_tithe / Blood Tithe | damage | 18 grave_reserve; 6s | Spend a visible portion of current life for a frontal cleave. |
| winter_bulwark / Winter Bulwark | defense | 22 grave_reserve; 12s | A temporary frost shield slows enemies that strike it. |
| ossuary_call / Ossuary Call | control | 24 grave_reserve; 9s | Raise a brief bone barrier; no permanent minion army at base level. |
| funeral_advance / Funeral Advance | mobility | 20 grave_reserve; 8s | A slow unstoppable march; ends with a short weapon strike. |

### Riftblade

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| seamcut / Seamcut | generator | -4 instability; 0.6s | A blade slash builds instability on contact. |
| folded_edge / Folded Edge | damage | 18 instability; 5s | A narrow projected slash crosses a small gap but obeys blockers. |
| riftstep / Riftstep | mobility | 16 instability; 8s | Blink a short distance and leave a clearly marked return seam. |
| eventide_guard / Eventide Guard | defense | 20 instability; 11s | A timed guard stores one absorbed impact for the next active attack. |
| ruin_stitch / Ruin Stitch | area | 24 instability; 7s | Join two ground marks with a delayed damaging line. |

### Aethercaller

| ID / ability | Role | Cost / cooldown | Mechanic |
|---|---|---|---|
| prism_needle / Prism Needle | generator | -4 aether; 0.7s | A narrow light shard restores aether on contact. |
| starflare / Starflare | area | 20 aether; 6s | A bright orb detonates once after a short projectile flight. |
| refraction_step / Refraction Step | mobility | 16 aether; 8s | Slide to a nearby point; the trail is visual and never damages for free. |
| lifeward / Lifeward | recovery | 24 aether; 12s | Place a ward that heals its nearest injured ally once per pulse. |
| spectrum_lattice / Spectrum Lattice | control | 22 aether; 9s | Create three visible prisms that slow enemies inside the triangle. |

## Meaningful mastery node examples — design only

| Ability | Node A | Mutually exclusive node B | Engine requirement |
|---|---|---|---|
| Cleave | Split Standard: the sweep becomes two narrower arcs with a pause; second hit uses a distinct contact event | Steadfast Sweep: remain planted, gain stagger resistance during windup and enlarge the arc | Two-hit cast timeline or explicit guard state; cannot stack both |
| Glacial Stitch | Rime Bridge: the line leaves a brief traversable frost bridge across authorized gaps | Glass Prison: repeated hits create a short cage on normal enemies and a slow field on bosses | Navigation link lifetime and evacuation; boss control tags |
| Arcane Fold | Return Script: one return to origin within 2 seconds; second press consumes the anchor | Forward Only: longer travel; cannot return; arrival empowers the next actively cast spell | Anchor state, legal destination checks, consumed empowerment token |
| Ashen Ward | Ember Aura with Cinder Bloom | Ember Aura with Siphon Embers | Paid pulse scheduler, branch exclusion and proc-depth tags |
| Briar Trap | Briar Architect: two charges, independent placement; shared maximum active traps | Deep Snare: one trap with delayed rearming and stronger control | Charge recovery, trap ownership and elite/boss control rules |

Each mastery record needs node_id, ability_id, rank, max_rank, required_nodes, level_requirement, exclusion_group and effect_definition IDs. Save ranks by node ID. Display node points only after prerequisites are valid; refund invalid downstream ranks during respec in one transaction. The graph should show mechanical transformations, not an expanse of flat +1% nodes.

## ItemDefinition and ItemInstance target schemas

Current items are compact dictionaries generated by systems.gd. The following schema separates immutable content from rolled ownership state. It is a proposal for the next refactor, not a claim these external JSON definitions are loaded today.

```json
{
  "definition": {
    "id": "longsword_royal",
    "base_type": "sword",
    "equipment_slots": [
      "weapon"
    ],
    "handedness": "one_hand",
    "footprint": [
      1,
      3
    ],
    "icon_id": "weapon",
    "damage_school": "physical",
    "affix_pool_ids": [
      "martial_prefix",
      "martial_suffix"
    ]
  },
  "instance": {
    "uid": "unique-instance-id",
    "definition_id": "longsword_royal",
    "generation_version": 1,
    "item_level": 12,
    "required_level": 10,
    "rarity": "rare",
    "rolled_affixes": [
      {
        "id": "strength_tier_2",
        "value": 5
      }
    ],
    "location": {
      "container": "inventory",
      "x": 0,
      "y": 0
    }
  }
}
```

The current schema uses `slot` as a base type and keeps ring1/ring2 as equipment destinations; preserve that distinction in migration. Current `level` is required level and generation budget together. Separate those meanings before creating high-item-power low-level uniques.

## AbilityDefinition and RuntimeCast target schemas

```json
{
  "definition": {
    "id": "echo_strike",
    "display_name_key": "ability.echo_strike.name",
    "class_tags": [
      "lorecasting"
    ],
    "target_mode": "ground_point",
    "range_ground_units": 7,
    "radius_ground_units": 1.8,
    "power_source": "spell",
    "coefficient": 2.1,
    "resource_cost": 16,
    "cooldown_seconds": 5,
    "cast_seconds": 0.6,
    "effects": [
      "echo_impact"
    ],
    "unlock": {
      "discovery_id": "first_echo"
    }
  },
  "runtime_cast": {
    "cast_id": "unique-cast-id",
    "ability_id": "echo_strike",
    "source_actor_id": "player",
    "started_at_tick": 100,
    "contact_at_tick": 136,
    "aim": [
      2,
      1
    ],
    "snapshot_policy": "explicit_choice_required",
    "already_hit_ids": []
  }
}
```

Origin IDs and explicit timing make combat logs, saves and proc-loop prevention reviewable. Treat tooltips as formatted views of definitions plus evaluated actor modifiers; do not maintain a separate hand-written damage number in the UI.

## Interaction authoring record proposal

```json
{
  "id": "crownsfall.stone_memory.01",
  "kind": "lorecasting",
  "landmark_id": "crownsfall.plaza.memory_stone",
  "range_ground_units": 1.8,
  "requirements": [],
  "rewards": [
    {
      "kind": "discovery",
      "id": "first_echo"
    }
  ],
  "repeat_policy": "inspect_only_after_claim",
  "state_keys": [
    "sensed",
    "revealed",
    "recorded"
  ],
  "spoiler_tier": "early_hint"
}
```

The eventual journal should reference spoiler tier and discovery state so a UI tooltip cannot reveal a late-game identity early. Player-facing text should name the chosen character when needed and should not use the internal Ixll codename.

## Data validation requirements

- Unique IDs across each definition namespace; no UI labels as keys.
- Class paths reference valid base classes and preserve all thirty-nine mappings.
- Ability icons exist or explicitly use a reviewed placeholder; proposed entries with null icon_id are asset requests.
- Footprints are positive integer cells and fit at least one supported container.
- Affix values are finite and conform to authored ranges; no duplicate exclusive groups.
- Every transformation has base/variant IDs, unlock condition, cancellation behavior and a tested tooltip.
- Every named unique/set effect declares trigger scope, per-source cooldown, cap, proc recursion policy and interaction with immunity/overkill.

## Missing asset briefs

| Asset group | Required source and export | Review test |
|---|---|---|
| Royal Wayfarer | Actual editable Blender scene, skinned GLB, textures and clip manifest | Import, named bones/clips, deformation, foot contact and original concept comparison |
| Crownsfall 3D | Actual courtyard/environment package, materials, light/navigation notes | Ground collision, stairs, occlusion, camera reference and engine render |
| Twelve additional classes | Rig or atlases, silhouette sheet, five active animation/VFX sets | Adult proportions, readable class identity, no texture-only “new class” |
| Inventory illustrations | Nine base-type icons plus future weapon families; transparent source | 32px silhouette, consistent lighting/crop, no accidental rarity paint |
| Skill illustrations | Eleven current plus proposed class abilities, semantic ID manifest | Match mechanic; distinguish similar schools without relying only on color |
| Audio | Original/licensed hit, cast, world, UI, ambience and music source | Contact sync, mix headroom, volume controls and ownership metadata |

No new concept artwork or 3D assets were generated in this expansion. The vector icons and engine screenshots are real delivered assets; prose asset briefs are requests for future production.
