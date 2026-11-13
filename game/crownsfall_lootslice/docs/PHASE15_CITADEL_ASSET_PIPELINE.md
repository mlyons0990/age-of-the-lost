# Age of the Lost — Phase 15: Citadel runtime asset bridge

**Status:** standalone 3D import candidate; not yet integrated into the approved live Crownsfall Phase 11 scene. This is a replacement for temporary box-mesh *presentation*, not a replacement for 2D navigation, gameplay collision, quests, saves, player art or the Higgsfield Blender sculpt.

## Production intent

The Citadel quality blocker is no longer an inability to produce real mesh geometry. This package provides a deterministic **art-only**, structurally aligned, editable source generator and a portable Godot-ready `.glb`, with a matching JSON manifest. The actual Higgsfield sculpt remains separately retained in the authenticated 3D Jutsu project at revision 3; this GLB is a **procedural fallback** rebuilt locally because direct transfer of the existing Higgsfield binary was not supported by the two connected services.

**Do not refer to the fallback as an export of the Higgsfield Blender original.** Production UV painting, detailed topology, baked textures and realistic foot IK still require a separate integration/sign-off pass.

## What the GLB contains

- 9 progressively elevated masonry treads (`0.2 m` rise, `1.0 m` run), 7.50 m clear centered passage.
- Raised royal landing (1.8 m) level with the upper courtyard.
- 32 true watertight pointed-Gothic mesh stones with a 8.10 m clear horizontal aperture and minimum 4.14 m of overhead headroom above the upper floor.
- Actual separate side parapets, pier capitals, archivolts, banners with cloth folds, planters, carved decoration, and torch standards.
- Warm limestone, cream sunlight, royal blue and muted gold physically based material slots.
- 220 separate mesh objects with stable semantic names and asset root at the *bottom of the stairs*.

Everything is in **Godot-friendly X lateral, Y up, Z north** physical metre coordinates. Nothing writes player data or performs movement, physics, or navigation. The Godot loader should keep 2D NavigationRegion2D as the only gameplay authority.

## Build locally

From `game/crownsfall_lootslice`:

```sh
python -m pip install -r tools/requirements_citadel_v15.txt
python tools/build_citadel_art_glb_v15.py
python tests/test_citadel_art_glb_v15.py
godot --headless --editor --import --quit
godot --headless --script res://tests/citadel_art_import_v15.gd
```

Generated asset: `assets/25d/citadel/AOTL_Citadel_ArtFallback_v15.glb`
Generated manifest: `assets/25d/citadel/AOTL_Citadel_ArtFallback_v15.json`

## Scene integration

1. **Back up the actual complete playable Phase 11 Citadel project, including art.** The Citadel branch currently in GitHub is descended from earlier Phase 08 code, and must not overwrite the user's more current working scene.
2. In the actual Phase 11 live 2.5D bridge, call the Phase 13 `install_verified_citadel_grade()` with the *real* stair entrance, exit, rise and NavigationRegion2D. Do not guess coordinates from the concept painting.
3. Attach the imported art-only GLB as a child of the same Citadel grade/root transform. The model's origin is the foot of the nine-step staircase: apply no coordinate-altering scale, and match its +Z direction to the 3D route vector.
4. Hide the temporary procedural `MeshInstance3D` furniture/arch/stair visuals **without disabling the physical collision proxies** when the art GLB is visible. Keep collision off entirely when F4 preview is off; keep original F8 painted fallback intact.
5. The F10 rendered Knight depth proxy samples the existing grade Y at each painted 2D location. Validate its contact shadow and front/back depth testing against stair risers, gate piers, NPC mirrors and banners at every grade level.
6. Check camera alignment at 1080p and 1440p under the existing city projection. Do not sign off until the art bridge passes both visual comparison and interactive walking tests.

## QA result and limitations

The standalone Python asset gates passed 8/8 suites on the generated 220-mesh GLB; all nine stair top heights and Gothic voussoir topology were examined as actual binary glTF geometry. The Godot import smoke-test script and CI workflow are included but not yet engine-verified from this execution environment. A true engine result must come from a Godot-equipped Windows development system or a successfully executed GitHub Actions runner.

No paid Higgsfield generation credits were used for this pass. The approved original painterly art remains the final quality reference. There are still no wilderness zones in this branch.
