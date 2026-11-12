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
