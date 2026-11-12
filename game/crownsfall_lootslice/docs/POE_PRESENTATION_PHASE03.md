# Age of the Lost — Phase 03: real-game presentation layout

Scope: the **existing saved 2D Crownsfall gameplay scene** (`main.tscn`) and independently testable 2.5D art lab are both retained. This phase only changes visual HUD/camera controls in the playable main game. It does not replace the historical paint-sprite rendering, inventory, loot, abilities, Mage mastery, enemies, combat, save schema 6, or F7 3D rig lab.

## Screenshot-derived presentation goals
- The November 12 user-approved screenshot is a **target image**, not a gameplay screenshot nor a 3D mesh.
- HP globe outside-left, **flasks left**, 5 functioning skill buttons right, MP globe outside-right, XP across the clear middle.
- Five flask slots are drawn; **only the existing Q health potion is playable**. Other four are visibly unassigned and consume no resources/clicks to move the hero. This avoids fabricating mana flask inventory or altering the save format.
- Existing hotkeys **LMB, 1, 2, 3, 4** are preserved; Q still uses a health potion. The screenshot's QWERT illustration is not used as a remapping instruction.
- Main camera zoom 0.84 (wider than 1.0), adjustable with wheel / `+`/`-` between 0.74 and 1.12; Home resets. Zoom is transient presentation only.
- A small **Menu [F9]** toggles the legacy top toolbar; modal buttons remain intact.
- The full original painted town texture and all canon class sprite sheets remain byte-identical. The previous 2.5D environment prototype is unaffected and still accessible as a separate scene.

## Changed source
- `scripts/poe_hud_layout.gd` — responsive geometry, shared by paint and input.
- `scripts/legacy_hud.gd` — draws separate banks, ornamented HP/MP globes, proper full-square ability tiles, flask assigned/unassigned previews and centered XP ledger.
- `scripts/hud.gd` — layout-accurate clickable surfaces and compact menu.
- `scripts/main.gd` — wider actual gameplay camera with safe zoom controls.
- `tests/poe_presentation_integration.gd` — 38+ presentational/functional assertions without save files.

## Verification
Run in Godot 4.6.3 with an **isolated** user data directory:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/poe_presentation_integration.gd
python3 tools/run_checks.py --report-dir /tmp/aotl-phase03-qa
```

Use F5 to launch the real playable town. Use F6 in the editor on `scenes/two_point_five_d/aotl_25d_lab.tscn` to inspect the 2.5D research scene. These are different environments with different gameplay scope: the 3D lab **does not yet carry over** all live inventory/combat/quest systems. A matched integrated 3D town is a future step.

The visual goals are aspirational until real screenshots demonstrate quality. The Nov 12 approved screenshot depicts much more detailed modeled architecture than the existing 2D main map or 3D blockout; this patch cannot be described as a pixel-faithful replica of it.
