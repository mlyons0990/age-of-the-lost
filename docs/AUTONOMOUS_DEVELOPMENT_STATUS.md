# November 20 development checkpoint

[Current autonomous development status](checkpoints/2026-11-20-reference-hud/AUTONOMOUS_DEVELOPMENT_STATUS.md)

# AOTL — Autonomous Development Status

**Updated:** 2026-11-20 · **Agent:** Claude Code (cloud container; single agent working sequential workstreams)

## Two live tracks
| Track | Project | Branch / PR | Latest verified |
|---|---|---|---|
| 2D isometric ARPG (playable) | `crownfall/` (Godot 4.3) | `claude/import-crownfall-godot`, mlyons0990/age-of-the-lost#1 | 188/188 autotest checks; Higgsfield bottom HUD frame integrated |
| 3D Warrior rig/combat lab | `game/crownsfall_lootslice/` (Godot 4.6.3 + Blender 5.2) | `dev/r55-clip-safe-elbow-v1` (stack: R52 #67 → R53 #70 → R54 #71 → R55) | R55 clip-safe elbow: 52+10+17 new checks, 994/994 regression |

## Current phase
R55 — clip-safe elbow (see `game/crownsfall_lootslice/docs/R55_CLIP_SAFE_ELBOW_QA_2026-11-20.md`). Note: R54 introduced armor clipping; prefer R55 over R54.

## Environment facts (for resuming)
- Blender: `pip install bpy==5.2.4` in a venv (Python 3.13) works headless. Godot 4.6.3 from GitHub releases.
- No access to the Windows desktop AOTL folder (no machine attached). Google Drive reachable; uploads ≤ ~3 MB per file.
- Higgsfield generation refuses Claude Code sessions; existing Higgsfield art is reused from GitHub/Drive.

## Resume
1. Read this file, `AOTL_DEVELOPMENT_BACKLOG.md`, the latest R5x QA doc.
2. `git worktree add <dir> origin/dev/r55-clip-safe-elbow-v1`, `git lfs pull`.
3. Tools: `tools/r55_clip_safe_elbow.py`, `r55_patch_glb.py`, `tools/r54_elbow_helper.py`, `r54_patch_glb_elbow_helper.py`, `tools/r53_arm_strain.py`, `r53_arm_reweight.py`, `r53_patch_glb_arm_weights.py`, `r53_compose_compare.py`.
