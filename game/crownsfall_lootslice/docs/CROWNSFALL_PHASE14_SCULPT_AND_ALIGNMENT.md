# AOTL Crownsfall — Phase 14 Citadel Sculpt

## Work completed
A new private **Higgsfield 3D Jutsu project** now contains an editable Blender 5.2 Citadel gateway and staircase sculpt, retained as revision **3**: https://higgsfield.ai/3d-jutsu/0361ff9b-2829-4595-a64e-564f39e1eeac

- Nine hand-built 1.0 m-deep / 0.20 m-rise stair treads, a level upper court at 1.80 m, handcut-edge side parapets outside the central 7.50 m corridor.
- Pointed Gothic arch of 32 **true mesh voussoirs** with 8.10 m span and 4.14 m minimum vertical clearance above the upper court, two heavy piers and decorative rose relief.
- Cloth banners with shaped folds, stone capitals and recesses, landscape planters, a fixed isometric production camera and daylight lights.
- Revision 3's Blender Python audit passed 10/10 independent structural checks (actual riser heights, width, no stair-edge penetration, aligned landings, 32 stones, materials, camera). A 720x405 Blender EEVEE render artifact was generated. **An agent-side pixel inspection was not available**, so visual art approval is pending.
- One Higgsfield unlimited GPT Image 2.6 architecture concept was generated; it is a **reference image**, not automatically a UV texture on the Blender mesh.

## Synchronization to game geometry
Updated Phase 12's fallback procedural Gothic gateway to share the same **4.0 m upper apron**, **8.10 m clear span**, **3.25 m gate offset north of the last tread**, **4.14 m spring**, **6.05 m apex above upper landing**, and **0.77 exponent** with the Blender asset. Old painted mode remains authoritative. The path is still opt-in and requires the REAL Phase 11 Citadel NavigationRegion2D and endpoints, not guessed coordinates.

**Coordinate mapping:** Blender +Y is north and +Z is up. The nine-metre stair extends from Blender Y=-9 to Y=0. Under Godot's route coordinate convention, grade Z = Blender Y + 9 after axis conversion and frame alignment. Do not install the GLB directly with an arbitrary transform; verify actual route orientation and GLB export axis.

## GitHub and Google Drive
GitHub branch: `feature/phase14-citadel-sculpt-source-alignment`, descended safely from Phase 13. Google Drive handoff in the game's existing project folder. The actual Blender .blend and .glb remain safely stored in Higgsfield revision 3; **this handoff records their durable project link, but is not a duplicate binary backup to Google Drive**. A cross-service binary transfer is still needed.

## Verification required before runtime
1. Recover/back up complete Phase 11 Upper Citadel source, including images. Previous GitHub Phase 09/10 branch pointers do not include those assets.
2. Export the art-only GLB from the Higgsfield project's Blender source (disable cameras/lights and unwanted floor stand-ins), keeping metre scale, texture/materials, normals, tangents and distinct structural mesh names.
3. Stage the new GLB inside the actual `res://assets/25d/citadel/`. Compare axis, mesh pivot, gate position and height against `data/citadel_sculpt_v14_manifest.json`.
4. Test `citadel_grade_geometry_v12.gd` and `citadel_depth_bridge_v13.gd` with Godot headless, then capture F5/F4/F8/F10 at identical camera angle; verify all nine foot contacts, 2D navigation, collision and occlusion.
5. Only enable this presentation layer by default after the rendered Godot sign-off.

**Godot test status:** Not run in this turn — Godot executable unavailable in both local execution container and Higgsfield Blender runtime. Do not claim 962/962 or green engine CI for this work without logs.

**Higgsfield paid credits spent: 0**. No wilderness, gameplay, inventory or save changes.
