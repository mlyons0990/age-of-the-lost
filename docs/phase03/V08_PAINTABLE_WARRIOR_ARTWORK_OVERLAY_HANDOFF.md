# AOTL V08 — Paintable Humanoid / UV Artwork Overlay Handoff

**Status:** V08 art-carrier proof of concept, not approved replacement for the 2.5D painted hero. **Built November 13, 2026.**

## Exact model inspected in Higgsfield 3D Jutsu

- Project `088e8199-50e8-4554-b0be-b108a6b2203a`, **revision 21**. [Open editable V08 project](https://higgsfield.ai/3d-jutsu/088e8199-50e8-4554-b0be-b108a6b2203a).
- Rig is `RIG_AOTL_Master_Humanoid_58`, retaining **58 bones**, named arm/leg skin weights, equipment mounts, and the `AOTL_Reel_V06` **23-section** animation reel.
- The independently UV-mapped skinned surface contains **22 paint-carrier meshes**:
  - **BODY:** 7 meshes (head, hair crown, fitted tunic, left/right arms, left/right legs).
  - **GEAR:** 15 meshes (cuirass, cape, tabard, two pauldrons, two forearm guards, two boot shafts, two anatomical boots, two toe caps, two knee guards).
- Each carrier has a **`V08_ART`** UV layer and assigned category material `V08_BODY_*` or `V08_GEAR_*`. Their respective packed 2048×2048 PNGs are `V08_BODY_PaintPlaceholder_2K` and `V08_GEAR_PaintPlaceholder_2K`.
- Blender carrier mesh resolution is far denser than V07 on weighted limbs: **5,282 verts per arm, 5,922 per leg, 1,570 cuirass, 1,105 cape**, etc. The textured GLB includes 58 skin joints and the original animation channel layout.
- Existing approved 21.0 orthographic gameplay camera, scroll range 14–28 and original painted 2D display remain the baseline. No production art approval implied.

## Real original AOTL sprite projection proof

**Reference:** existing game art files `assets/knight/idle_down.png`, `assets/knight/idle_se.png`, `assets/knight/idle_ne.png` (384×384 RGBA). No invented external knight design is substituted.

The separate V08 artwork overlay kit includes:
- `V08_BODY_ART_PROJECTED_2K.png`, `V08_GEAR_ART_PROJECTED_2K.png`: 2048² starter albedo layers, with selected parts projected from the original painted sprites.
- `V08_BODY_UV_GUIDE_TRANSPARENT_2K.png` and `V08_GEAR_UV_GUIDE_TRANSPARENT_2K.png`: labelled UV region guides grounded in Blender bounds, plus mask/preview PNGs.
- `v08_art_atlas_manifest.json`: exact 22 mesh names, UV bounds, destination pixels, source sprite and crop.
- `v08_inject_art_into_glb.py`: external, pure Python tool to replace just the embedded body/gear PNG images in an exported GLB; it asserts original skins, meshes, animation JSON and BIN prefix unchanged. A synthetic GLB binary-injection test passed.
- Original reference images and `SHA256SUMS.txt`.
- Kit is also saved in AOTL Google Drive / `Art_Production_2026-11-12/Phase03_V08_Artwork_Projection_2026-11-13`.

**Model usage:** Export V08 revision21 GLB from Higgsfield. Unzip the overlay kit and run:

```shell
python v08_inject_art_into_glb.py AOTL_Humanoid_Master_V08.glb --body V08_BODY_ART_PROJECTED_2K.png --gear V08_GEAR_ART_PROJECTED_2K.png --output AOTL_Humanoid_Master_V08_Painted.glb
```

The resulting **new GLB** references the painted atlas images, without altering the original 58 bone joints, 23 animation sections, geometry or material bindings. Blender users can instead load the two PNGs directly as Albedo for the `V08_BODY_*` and `V08_GEAR_*` materials while retaining `V08_ART` as UV layer.

## Important limitations / QA gates

- Original painted sprites are **not UV-wrapped 360° source textures**. Their crop projection creates a useful first texture transfer, but will stretch at curved anatomy and back-facing faces; fine facial features and ornate armor motifs require manual painting, texture baking and additional camera angles.
- The UV guides show **exact region rectangles**, not pixel-perfect wireframe rasterization. Actual model UV islands are the authoritative positions for a production paint pass.
- The GLB injector was successfully smoke-tested on a synthetic GLB binary; **an actual V08-Godot end-to-end painted-GLB regression is pending**. Do not assert it passed until importing the modified V08 GLB into Godot 4.6.3.
- Higgsfield V08 carrier render still has simplified geometry and does not yet resemble the locked painterly-anime Warrior closely enough for production approval. It is an editable, skinned high-density *texture carrier*, not finished character art.
- V07 rollback, original game saves, class selection, equipment stats, and main remain untouched; **no paid Higgsfield credits spent**.

## Next production steps

1. Paint face/hair and detailed chest armor onto the precise UV islands using the locked AOTL image references; use source images as reference, not one flattened sprite.
2. Retopologize distinct armor panels and cloth hems to match the approved silhouette; bake normal/ambient occlusion maps.
3. Export V08 GLB plus both painted atlases, import to Godot, run native 58-joint/23-clip/954-regression suite and 21.0/14.0 comparison captures.
4. Only then promote to the new recommended class base (never override the approved painted mode prematurely).
