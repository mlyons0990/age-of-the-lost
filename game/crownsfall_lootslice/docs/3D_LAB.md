# Independent 3D rig lab

Press F7 from the town to enter. Entry is refused while dead, paused, in an active Scar or while save writing is protected. Main gameplay cancels transient casts and saves before the scene transition. F7, Escape or the return button reloads the plaza using that saved Mage/Warrior state. Lab training does not grant main-world gold, experience, loot or resource recovery; main cooldowns stay frozen during the visit.

WASD moves, Shift sprints, Space dodges, left click slashes, 1 cleaves, 2 dash-strikes and 3 casts a radial lore burst. These are independent lab actions with training values. They are not aliases for the Mage's five spells. Lab HP starts at 130 and does not replace the saved character's HP.

The GLB contains 58 joints and Idle, Walk, Run, Slash, Dodge and Cast clips. Import may prefix animation names with a library path; the controller resolves the final path component. Idle, Walk and Run explicitly loop. The source GLB remains byte-for-byte unchanged and is a geometric articulated proxy, not the missing production Wayfarer.

`tests/lab_roundtrip.gd` checks 28 conditions through real scene changes: imported skeleton/animations, changing bone poses, movement/sprint, timed slash and cast impacts, invulnerability expiry, duplicate kill prevention, and returning with the same class/name/gear/bag/stash/gold/potions/resources/cooldown state. It passed in Godot 4.6.3 Linux both headless and rendered. Review `tests/LAB_*` logs for exact results.

The floor is a finite blockout. Decorative columns and steps are visual cues rather than a finished collision/navigation level. There is no cloth/IK, production mesh, shared 3D enemy AI, 3D inventory gear visualization or exported Windows build. A future renderer should consume the same mechanics/state as the 2D game rather than evolving these training values into a second balance system.
