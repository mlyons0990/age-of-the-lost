# AGE OF THE LOST — Phase 23 Terrain Traversal & Foot Contact Lab

**Derived from the user-verified Phase 22 source; safe independent experiment.**

## Open and test
1. Extract the FULLSOURCE ZIP to a folder. Import `game/crownsfall_lootslice/project.godot` in Godot 4.6.3.
2. F5 loads the unchanged approved 2.5D Crownsfall town. To test 3D, open `scenes/rig_lab_3d.tscn`, press F6 to run it, then press F6 inside that scene to launch the **Phase 23 terrain course**. Or run `scenes/phase23_terrain_lab.tscn` directly (F6 in editor).
3. Choose lanes **1 = 18° blue ramp, 2 = seven 14cm stone steps, 3 = flat stone path leading to steep 65° red obstacle**.
4. WASD move, Shift sprint, **F11** optional foot IK on/off (default OFF), **7** target+animated-bone markers, **8** follow camera on/off, **9** visual step smoothing on/off. **F7/Esc** returns to original rig lab.
5. Onscreen diagnostics measure actual player world elevation, on-floor state, foot planting/release, terrain ray hits and source foot-bone→target divergence. Out-of-bounds actors are returned to the middle lane.

## Engineering additions
- Physically collidable seven-step staircase and ramps with real surface normals, colored visual labels and an orthographic inspection camera.
- **Phase23 step assist**, only on course-tagged steps and ramp seam. It requires a physically detected obstruction, checks the next surface is 2.5–19cm higher, verifies traversability of the elevated body, and rejects untagged/too-high obstacles. A separate additive render-model counter-offset gently blends step corrections; the original main player is untouched.
- Diagnostic difference between planted target and actual imported foot bone for left/right IK.
- Captured genuine Godot 4.4.1 OpenGL scene frames (8) into an animated GIF, separately hosted on Higgsfield; not an AI-rendered character screenshot.

## Engine QA
Godot 4.4.1 Linux: 177/177 checks across Phase 23 + earlier Phase 21/22 test suites, including 265-frame traversal in all three lanes. Eight real graphical Godot frames captured with software OpenGL/Xvfb. 18° and 65° collision normals verified. Both source archives integrity-checked.

**Quality caveats**: Stair ascent is not yet full-course; in the test run the actor climbed multiple steps to ~0.38m while the ramp reached ~1.35m. The gap between the model's animated foot bone and its planted IK target can peak near 0.47m; this is diagnostic evidence of unfinished visual contact, not a final-quality result. Do not promote this model or gait to production. Godot 4.6.3 Windows visual QA still needed.

Previously verified Phase22 project preserved separately, this project uses `AgeOfTheLost_Crownsfall_Phase23_TerrainTest` save namespace. No production gameplay scripts, character, inventory, quest progression, or HUD were changed. All edits reversible. No paid Higgsfield credits spent.