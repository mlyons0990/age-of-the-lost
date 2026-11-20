# Autonomous development checkpoint
November 20, 2026. Phase A source reconciliation and a Phase 0 implementation pass are recorded. Character visual acceptance remains open. No Higgsfield credits were spent.

## Runnable packages
1. Extract Crownsfall-HUD-Desktop.zip into a fresh directory. Import project.godot with Godot 4.6.3, then run the main scene. This two-district game includes the reference orbs, XP rail and the camera fix. The package uses a separate save namespace for review.
2. Extract Warrior-Pilot.zip, open game/project.godot in Godot 4.6.3, then press J for Slash, K for Dodge, X for Death and R to reset. Its README covers input, editable Blender source and reproducible tests.
3. For R55, check out dev/r55-reference-globes-xp and pull LFS assets. Run the headless editor import and tests/reference_resources_integration.gd from game/crownsfall_lootslice. Repeat with a graphical renderer at 1280×720, 1672×941 and 1920×1080.

## Current evidence
The R55 HUD commit is 190eaa24aad7d2468897328d74cb3649f9bb11c1, based on c12aae6. It preserves the existing six R55 actions. Testing its pinned scene dependencies and Desktop media passed 29/29 headless and 81/81 per graphical resolution. The Desktop game retains its ten clickable slots; HUD logic passed 43/43 and the 4.7.2 GPU resource suite passed 57/57 at each of three sizes. Camera coverage passed 51,732 invariant checks in each of two Godot 4.6.3 runs, with 24/24 promenade checks. Some existing suites report one resource still in use on process exit.

The eight-clip Warrior pilot adds a timed, directional Slash contact with a practice dummy. Its Godot 4.6.3 end-to-end controller test passed. The additive clip preserves the inherited pose matrices checked in Blender. Art quality, full R55 integration and acceptance of armor, cloth and foot contacts remain outstanding.

## Resume
Start from AOTL_SOURCE_INVENTORY.md and AOTL_DEVELOPMENT_BACKLOG.md. Validate an authenticated full R55 checkout before merging. Use the pilot's motion comparison test when adapting Death to the R55 helper rig. Preserve the original Desktop ZIP and the two-district camera on its own branch. The skill/potion panel styling and the XP rail’s end ornaments remain separate visual work.

## Latest hero development pass
The opt-in hero branch used a hard-coded level and synthetic 42% starting XP in its 3D HUD. The new practice progression uses real defeated-target events in both combat paths and the existing campaign XP curve. The label and overhead badge share level state. The practice session starts at level 25 with zero earned XP and resets when the lab is reopened. Godot 4.6.3 passed 7/7 progression checks and compiled the modified HUD. Full Knight and Mage scene integration checks need their LFS assets. The local Desktop and Warrior ZIPs were backed up to the AOTL Drive project folder. See draft PR #76 for the separate Crownsfall HUD.
