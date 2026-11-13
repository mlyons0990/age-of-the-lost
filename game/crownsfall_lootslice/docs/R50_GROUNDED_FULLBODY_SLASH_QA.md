# Age of the Lost — R50 Grounded Full-Body Slash

**Development:** November 13, 2026  
**Higgsfield project:** `088e8199-50e8-4554-b0be-b108a6b2203a`  
**Godot branch:** `dev/r50-slash-weighttransfer-ik-v1` (draft, stable main untouched)  
**Gameplay fallback:** R39 production six-clip Warrior

## The actual animation defect

The previous source `Slash` action animated the sword arm and upper chest but **never rotated the hips or moved either leg**. The independently measured root, hips, thighs, knees, and feet had zero motion during frames 1–23. This made the attack look stiff despite a functional seven-clip gameplay system.

## Three reversible Blender development candidates

- **R48 / `R48_Slash_FullBody_WeightTransfer_V1`**: adds hip counter-rotation, knee articulation and body recovery, but causes up to **20.77 cm** of left-foot movement. Preserved as an unsuccessful intermediate candidate.
- **R49 / `R49_Slash_PlantConstrained_V2`**: reduces leg motion, but still allows **13.89 cm** left-foot and **13.07 cm** right-foot drift. Preserved as a second candidate, not promoted.
- **R50 / `R50_Slash_Grounded_IKBaked_V3`**: uses Blender's temporary chain-4 leg IK constraints to preserve ankle/foot position, then **visually bakes the complete skeleton action** to actual keyframes and removes the temporary constraints. The previous actions remain in the editable `.blend`.

### Ground-contact metrics

Measured on the original action frames 1–23 (30 FPS), including the exported Godot skeleton:

| Measurement | Original Slash | R50 |
|---|---:|---:|
| Pelvis yaw | 0° | **8.44° in Godot** |
| Left knee world-space travel | 0 cm | **8.39 cm** |
| Right knee world-space travel | 0 cm | **8.19 cm** |
| Left foot travel | 0 cm | **1.77 cm** |
| Right foot travel | 0 cm | **1.86 cm** |
| Source animation duration | 0.73 s | 0.73 s |

These values reflect world-space pose displacement from the beginning of the animation, not an assertion that all bones have natural human biomechanics. Full AAA motion polish and visual consistency remain separate open tasks.

## Real Blender source and seven-clip model

- **Editable Blender source:** `art/character_sources/AOTL_R51_R50_FullBody_Slash_Source.blend` (Higgsfield revision 51)
  - SHA-256: `7e6c43e40fad74f747c0c925e8f23bf7076f976a5bf39b632b90c04f8fb74c01`
  - Size: 24,334,240 bytes
  - Preserves `Slash`, `R48_Slash_FullBody_WeightTransfer_V1`, `R49_Slash_PlantConstrained_V2`, and `R50_Slash_Grounded_IKBaked_V3`.
- **Separate, seven-clip GLB:** `game/crownsfall_lootslice/models/AOTL_Warrior_R50_SevenClip_Candidate.glb`
  - SHA-256: `b1a600ca144ccfc7a868d6e4936964a74c3afe55882c5e8166e3f65a26561a16`
  - Size: 7,080,664 bytes
  - Retains the original six action clips, 62 source skin joints and 92 meshes. Adds `Slash_FullBody_R50` as a seventh, independent clip.
  - Does not overwrite `AOTL_Warrior_R39.glb`.
- **Authentic preview:** `previews/warrior_r50/real_fullbody_slash.gif`, sourced from actual Blender keyframes 1, 5, 9, 12, 15, 19, 23 with no generated in-between motions.

## Opt-in game integration

`rig_controller.gd` exposes `enable_r50_fullbody_slash_candidate`, **false by default**. If enabled, the controller loads the optional R50 GLB first and maps the Slash gameplay key to the new `Slash_FullBody_R50` clip. Earlier model candidates and the original `Slash` remain available as fallback.

The 3D rig lab has a corresponding inspector property `use_r50_fullbody_slash_candidate`, also **false by default**, so developers can test the experimental action without changing production gameplay.

## Godot QA evidence

- [Real R50 glTF animation import](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43410127449) — **18/18 checks passed**. Verified all seven clips, mesh count, pelvis rotation, moving knees, stable feet, and actual weapon motion in Godot 4.6.3.
- [Playable R50 controller](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43410934959) — **16/16 checks passed**. Opt-in selection, original model preservation, foot IK, equipment sockets, authored Slash playback and single impact.
- [Full Crownsfall regression](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43410934976) — **994/994 checks across 17 suites passed**.
- [R50 rig lab baseline plus strict physical sword collision](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43412531968) — **13/13 checks passed**. Confirms real R50 model, terrain IK, equipment sockets, 32-damage Slash, no duplicate hit, opt-in F8 swept blade at 0.65m, and working fallback.
- [Final R50 full Crownsfall regression after relocating source outside Godot](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43412351322) — **994/994 checks across 17 suites passed**.

## Honest visual quality caveat

The current Warrior still uses procedural, relatively blocky geometry and does not faithfully match the locked painterly Crownsfall / anime reference art. Its shoulder, hand grip, cloth dynamics, expression, physical weapon collision alignment and mesh deformation need more work. The new Slash fixes the *specific stationary-lower-body defect* without solving those separate art and rigging shortcomings.

## Safe rollback

- Leave `enable_r50_fullbody_slash_candidate` and `use_r50_fullbody_slash_candidate` unchecked to retain stable R39 gameplay.
- If an R50 visual or collision regression appears, remove the separate R50 GLB or revert the draft branch. The existing R39 model, original six clips, original `Slash`, all prior Higgsfield revisions and playable Godot project remain intact.
- Keep all work in this draft development branch until desktop visual review and full gameplay QA.

## Source-backup import incident and resolution

An initial GitHub source backup mistakenly placed the editable `.blend` inside the Godot game project. Headless Godot attempted to auto-import it without Blender configured, causing an editor import failure. The source was moved to `art/character_sources/`, outside Godot's `res://` tree, **without changing its Git LFS SHA-256**. The original game project and stable asset remained unchanged. Both the complete 17-suite full regression and the live 3D rig-lab strict combat test passed after relocation.

### Final review state

- All earlier character assets and the complete Blender action history are preserved.
- This R50 GLB stays optional. The user-facing default remains the previously verified R39/R40 gameplay path.
- Both the actual `.blend` and the 7-clip `.glb` are backed up in GitHub LFS and Google Drive.
- The R50 GIF and R47-to-R50 comparison GIF were generated from actual keyframed Blender render frames; they are not AI video generations.
- Approved for *developer testing*, not declared a final AAA-quality character asset or merged into stable main.
