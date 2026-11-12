# AOTL — Master humanoid rig, free development pass (Nov 12, 2026)

## Output locations
- Higgsfield 3D Jutsu scene: https://higgsfield.ai/3d-jutsu/088e8199-50e8-4554-b0be-b108a6b2203a
- GitHub: `game/crownsfall_lootslice/tools/aotl_master_rig_animations_blender52.py` in this branch
- Existing, independent Godot 4.6.3 prototype: `game/crownsfall_lootslice/`
- Original 3D rig lab: `models/AOTL_Wayfarer_Articulated_Proxy.glb`, `data/rig_lab_structure.json`, `scripts/three_d/rig_controller.gd`, and `docs/3D_LAB.md`

## Scope and verification
The new **editable Blender 5.2 scene is committed in Higgsfield** at revision 2:
- 58 named joints matching `data/rig_lab_structure.json`;
- 53 skinned meshes, with procedural materials, first-pass face/hair, plate armor, sword, shield and cloth;
- 10 saved Blender animation actions: `Idle`, `Walk`, `Run`, `Slash`, `HeavySlash`, `Thrust`, `Dodge`, `Cast`, `CastRelease`, `HitReact`;
- free procedural modeling and keyframes, no paid 3D generative credits consumed.

Confirmed from hosted Blender response: all 53 meshes have armature modifiers; all required joint names exist; action datablocks were successfully created with 58 bones intact. **Not yet confirmed:** exported GLB contains all actions, foot contact, roll ground clearance, blend-tree readability, cloth/clipping, eye alignment, screenshot-perfect match to approved AOTL character art, Godot import, or Windows performance. Structural success does not imply visual quality.

Higgsfield's 3D Jutsu editor currently cannot import an arbitrary existing user GLB to its hosted scene; this pass therefore recreates the same 58-joint naming contract procedurally instead of modifying the original LFS GLB. The original rig lab and saved game remain untouched.

## No-cost asset pipeline
1. Reuse existing AOTL proxy's verified skeleton/controller and rig-lab F7 controls. Preserve mechanics/stat/save schema.
2. Use [MPFB (MakeHuman for Blender)](https://extensions.blender.org/add-ons/mpfb/) for a higher-quality, parametric humanoid base. Its Blender 5.2-compatible human generation, clothing and rigging are free; inspect licensing for each optional community asset. `Rigify` is also free in Blender.
3. Use [Quaternius Universal Animation Library (Standard)](https://quaternius.itch.io/universal-animation-library) for free CC0 locomotion/combat prototypes. Use Godot's [SkeletonProfileHumanoid retargeting](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/retargeting_3d_skeletons.html) and verify bone rests before combining clips.
4. Alternative free animation/autorigger: [Adobe Mixamo](https://www.mixamo.com/) (Adobe ID; royalty-free game use per Adobe FAQ). Do not presume Mixamo outputs share the exact 58-bone AOTL hierarchy; retarget deliberately.
5. Match the six locked AOTL canon images before any final skin/gear variants; stylized low-poly free kits are **stand-ins**, not approved visual direction.
6. Only after Godot/Blender prototypes pass the acceptance gates below, use the eventual 3,000 Higgsfield credits for premium textured mesh conversion and rigging. Never spend credits automatically.

## Acceptance gates before merging / production use
- **A — Character proportions:** 1.8–1.9 m, refined painterly anime realism, natural arms/legs, no chibi proportions; verified against the original six images, including three-quarter and side views.
- **B — Skin and topology:** smooth shoulders, elbows, knees and wrists in motion; no collapse under 90-degree bends; correctly weighted gear attachments at `HandL`, `HandR`, `WeaponRoot`, `ShieldRoot`.
- **C — Motion:** walk/run grounded, no foot skating; dodge has anticipation/roll/recovery and does not pass through ground; attack hit frames/events match gameplay timings; spell-cast release matches VFX events.
- **D — Godot integration:** import a *new* `.glb` alongside original, confirm all relevant clips and `Skeleton3D`, run F7 rig lab with updated scene path only on experimental branch; no changed save namespaces or 2D source.
- **E — Performance and regression:** playtest at isometric camera, inspect cloth/collision, run `python3 tools/run_checks.py --report-dir /tmp/aotl-master-rig-QA`, compare against existing 954 suite baseline on supported Linux; Windows testing separate.

## Critical production rule
Reusing a skeleton does **not** mean all classes use identical animations or only shader recolors. Start with a shared humanoid rig and animation interfaces, then create mesh/gear silhouettes and class-specific attacks/spell releases. Orc-sized and creature bodies may need alternate proportions/rig families.

## Host/service limitation
The source lives inside the editable Higgsfield project; GitHub currently stores the procedural motion script and integration plan, **not** a downloaded GLB or BLEND binary. The 3D scene/artifact service has intermittently returned HTTP 503 for retrieval. Do not link to a guessed sandbox file or treat a private signed download URL as a permanent source path. Download and version the actual `.blend` / `.glb` after confirming export contents.
