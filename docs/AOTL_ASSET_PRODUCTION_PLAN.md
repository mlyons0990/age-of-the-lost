# AOTL Asset Production Plan (2026-11-20)

Follows the owner's execution plan (phases A, 0–6, ceilings totalling 1,650; reserve 1,304 of 2,954).
Ceilings are **not** permission: each paid operation is requested separately with a live quote.
Detailed reasoning and per-phase estimates: `docs/art/HIGGSFIELD_SPEND_PLAN_2026-11-20.md`.

## Pipeline proven by the pilot
1. One A-pose reference image (2) → Meshy 7 rigged model (44).
2. Retarget our own clips in Blender for free (`tools/retarget_r55_to_meshy.py`).
3. Buy library clips (8 each) only for motions our rig lacks; merge with `tools/merge_meshy_clips.py`
   (world-space transfer because each rigging call rebuilds the rest pose slightly differently).
4. Godot gate tests: `tests/verify_higgsfield_pilot_knight_set.gd` (import, clips, ground contact, motion).

## Free/local work queue (no credits)
- Phase 0: sword + shield on the knight via BoneAttachment3D (reuse R52 weapon meshes), knight in the
  combat lab with controller hookup, root-motion handling for Roll_Dodge, gameplay-camera renders.
- Phase 1: author Block, Hit reaction, Combat recovery in Blender on the knight rig where feasible before buying clips.
- Phase 3: Crownsfall props from existing art, Blender modular kit, then patch.gg candidates with per-asset licenses.
- Phase 4: Godot particles/shaders for spells; adapt ChatGPT Pixel Effects principles (MIT) without pixel styling.
