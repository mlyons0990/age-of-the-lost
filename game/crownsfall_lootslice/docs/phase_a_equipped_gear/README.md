# Age of the Lost: Phase A live gear appearance prototype

## Scope and limitations
This additive patch includes 27 original Higgsfield-derived item textures at 128 pixels per grid cell, whitelisted cosmetic item IDs, right-hand / off-hand / 2H visual logic, merchant access, and a display-only 2D equipment overlay that changes on equip, unequip, and load.

This is NOT the final 3D skinned equipment system. Current Warrior/Mage 2D sprite sheets already have prepainted armor and weapons; the separate visual layer may double-render accessories or look like floating decals during motion. Real per-item 3D armor requires skinned mesh parts and weapon attachments to the rig.

## Implementation
- systems.gd: approved 27 art variants, optional art_id preserved through clean_item, correct inventory footprint, class checks and 2H occupancy.
- equipment_appearance.gd: deterministic visual loadout from live gear, compatible with future 3D sockets.
- gear_visual_layer.gd: live 2D on-body proof-of-concept (not production sculpt or IK).
- player.gd: updates appearance only after successfully persisted equip / unequip.
- main.gd: additive shop options for current Warrior/Mage classes without schema migration.
- art_library.gd and hud.gd: render specific art via item art_id, fallback to existing legacy assets.

## Installation and QA
Back up full project AND user save. Extract over a copy of the current game/crownsfall_lootslice project; do not overwrite or merge blindly. Open Godot 4.6.3, allow texture import, and test a fresh or disposable save.

Use merchant options to equip a Greyfen Mail Hauberk + Crownspine Halberd (off-hand hidden), swap to Ashensteel Spear + Greyfen Shield, then Moonweave Robe + Staff on Mage. Confirm real in-game appearance, stash and merchant drag/drop, 10x6 inventory footprint, save/reload, and different facings, casts, attack and dodge.

Isolated Godot 4.6.3 headless QA passed:
- GDScript syntax checking for seven updated scripts;
- visual loadout resolver and 2H rules;
- live Node2D appearance overlays and PNG textures;
- Player equip/unequip, rollback on failed save, class restrictions, optional art_id through JSON clean_item.

The whole 89MB game with this patch was not run in Godot. 3D rig/socket meshes are NOT completed. No save schema bump and no damage-stat rebalance. All new art originated from earlier Higgsfield unlimited-entitlement generation; this patch incurred no paid credits.
