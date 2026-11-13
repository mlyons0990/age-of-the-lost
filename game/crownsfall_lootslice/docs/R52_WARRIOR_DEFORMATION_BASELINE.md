# AOTL Phase R52 — Warrior deformation baseline

This work is **diagnostic**, not an art-model replacement. It starts from the opt-in R50 seven-animation GLB at the unmerged PR #66 head, preserving the production R39 character and all R47–R51 source history.

## What the audit measures
- The R50 GLB's actual skin bindings and the number of weighted vertices per mesh primitive.
- Invalid indices into the skin's ordered joint palette.
- Vertices with zero significant skin influence and normalized skin weights whose total deviates from 1 by more than 0.025.
- Per-mesh, per-joint influence counts, plus joints with no weighted vertices.
- Optional second skinning attribute set (JOINTS_1 / WEIGHTS_1), including buffer-stride and normalized integer handling.

Run:
```bash
python game/crownsfall_lootslice/tools/audit_r52_warrior_skinning.py \
  --glb game/crownsfall_lootslice/models/AOTL_Warrior_R50_SevenClip_Candidate.glb \
  --out r52_warrior_skinning_audit.json --strict
```

The GitHub workflow uploads the full JSON report. `--strict` fails only on structural anomalies; per-joint non-influence is recorded for human review because some socket/helper bones are intentionally unweighted.

## Honest limitations
This is not a visual shoulder-deformation test. It does not measure armor intersections, garment dynamics, normal/tangent quality, or whether the character matches locked painterly concept art. It does not mutate the GLB or Blender file. Sparse accessors and external buffers are explicitly rejected, rather than silently misinterpreted. Current source art must be inspected in Blender before changing topology or vertex groups.

## Next production pass
1. Review JSON for shoulder/clavicle/upper-arm influence gaps and excessively rigid armor plates.
2. Build side-by-side shoulder deformation renders in Blender at rest, mid-swing, contact and recovery.
3. Separate rigid armor elements from deforming underlayers where necessary; adjust vertex group weights without changing 62-joint naming or seven-clip animation layout.
4. Add an opt-in R53 candidate only after Godot import, gameplay regression, visual comparison and authored GIF verification. Keep R39 as default.

## Source pose-review utility added

`tools/r52_blender_pose_review.py` is a Blender-only, read-only source inspection step. It selects the saved `R50_Slash_Grounded_IKBaked_V3` action and samples source frames 1, 5, 9, 12, 15, 19, 23. For each frame it renders front, three-quarter and side PNGs from actual evaluated Blender geometry, and records selected bone world positions plus world-space mesh bounds into `r52_pose_review.json`. This creates **21 actual source images** when successfully executed; it does not substitute generative imagery for deformation evidence.

Example in Blender 5.2:
```bash
blender -b art/character_sources/AOTL_R51_R50_FullBody_Slash_Source.blend \
  --python game/crownsfall_lootslice/tools/r52_blender_pose_review.py -- \
  --output /tmp/aotl_r52_pose_review
```

**Validation caveat:** Blender 5.2 and Godot 4.6.3 were unavailable to this development environment at implementation time. The image outputs do not exist yet and no mesh, vertex-group, armor, or cloth changes are being claimed. GitHub CI syntax-checks the utility but does not execute Blender. Subsequent R53 rigging edits must be based on actual review output rather than assumed topology.
