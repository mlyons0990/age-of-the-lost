# Current implementation status

| Area | Implemented | Remaining |
|---|---|---|
| Shared effect calculation | Immutable power/buff packets; direct/DOT/tooltips; exact partial burn ticks | Universal conditions/resistances, deterministic RNG and combat log |
| Class/gear slice | Warrior + Mage, five Mage spells, three paths, cloth/staff/wand/focus and atomic ownership swaps | Eleven planned classes, broader weapon families and further class encounters |
| Authored trial | Three captured attack shapes, second phase/fragments, arena boundary, safe retreat/death/load cancellation, rewards and victory record | Human difficulty/readability, drop economy and broader seed/gear coverage |
| Saved mastery | Five-node graph, points, ranks, discovery/prerequisites, exclusions and cascading town refunds | Further ability/class graphs and production respec policy |
| Ember Aura | Explicit paid toggle, paid pulses, quarter natural regen, stable cooldown ID and full cancellation | Human tuning and broader encounter testing |
| Cinder Bloom / Siphon | Non-stacking capped patches, secondary-origin gates, actual-damage recovery and rolling cap | General reusable proc/effect framework |
| Named gear | Emberwake Circlet, once-only paid attunement, recognized unique persistence and actual cadence/burn effect | Other uniques/Crownless sets remain proposals |
| Inventory & character | Right-docked equipment above the real 10×6 bag; right-side character tab, original gothic backplate, hover/pinned comparison, quick-equip and bidirectional drag/drop | Additional service types, controller navigation and human usability review |
| Paired town services | Stash/shop left, equipment/bag right; exact drag, Ctrl-click, search/dim categories, atomic matching deposit, persisted twelve-item buyback/undo | Human usability, service accessibility/controller work and economy tuning |
| UI/art/audio | 35 Mage frames, 21 painted runtime icons, original 39 vectors, skin/portrait, 13 cues/mute, scrollable spell details | Additional clips, attachment visuals, human mix, controller/localization |
| Persistence | Checked persist-first transactions, visible retry/non-replay and guarded exit; schema 6, ground loot, buyback, prior-schema imports and one-time pre-v5/pre-v6 backups; current resources/CDs/ranks/attunements, backups and future write protection; opt-in older import | Complete world persistence and production migration/economy service |
| Ground loot | Saved gear/gold/potions, partial piles, checked pickup, N comparison/Collect UI, F/manual/automatic collection, wave reward budget | Human drop economy/readability, richer labels and full controller routes |
| 3D lab | Preserved actual 58-bone/six-clip proxy, runtime loop resolution, guarded F7 round-trip | Production Mage mesh, shared authoritative Mage simulation in 3D |
| QA | 749 headless checks, 110 Inventory/71 Town/66 Grid/78 Loot rendered UI checks (755 distinct), four seeded scripted completions and rendered engine passes; three validated demo builds | Native Windows, target hardware and human usability/balance review |

Next: human encounter/readability and economy tuning, Windows/target hardware, actor state/gear visuals and production 3D. Current gameplay/appearance boundaries are documented in `MASTERY_SYSTEMS.md`; older status chapters are historical.
