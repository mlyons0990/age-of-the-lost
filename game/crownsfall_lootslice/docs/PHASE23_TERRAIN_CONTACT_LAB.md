# Phase23 Terrain Contact — Developer Notes

- Source `scripts/three_d/phase23_terrain_lab.gd`: separate in-engine exercise arena.
- Source `scripts/three_d/phase23_step_assist.gd`: course-only step solver, no live game modification.
- Existing source `scripts/three_d/phase18_foot_ik.gd` and Phase22 classification unchanged.
- Test corpus in `tests/phase23_*.gd` includes scene switch, 7 steps/actual collider normals, real 265-physics-frame traversal per lane, step-smoothing key toggle and actual graphical frame capture.
- `rig_lab.gd` adds F6 shortcut only. Production `scripts/main.gd`, all HUD/inventory/save scripts remain byte-identical.
- Force step release under excessive rise; cap `MAX_STEP_M=0.19`, only `phase23_step` tagged terrain; F11 original IK remains opt-in.
- Auto-rescue on terrain course for y below -4m or beyond course boundary; never applied to town.
- Measured stage: left ramp max actor y=1.349m after 265 frames, middle stairs y=0.377m, right flat lane y≈-0.024m. Visual IK target displacement peak about 0.47m; needs future IK alignment and on-camera deform quality work before production.
- Real Godot captured GIF link: https://d2ol7oe51mr4n9.cloudfront.net/user_3LvftKotfPTUOd7ljqK6GWH6rIX/a95aee52-bb3b-498f-b0e0-6e26dac6770b.gif
- Godot graphical capture uses Xvfb software OpenGL and does not claim Windows rendering equivalence.