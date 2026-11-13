# AOTL Phase 18 — Citadel Recovery and Safe Integration

Status: DEVELOPMENT PREVIEW ONLY. DO NOT MERGE the Phase17/18 branch into the locally approved game.

## Known assets
- Phase17 procedural GLB: 1197 meshes; prior isolated Godot checks 266/266.
- Higgsfield revision 5: 481 meshes, 9 stair treads, 32 pointed Gothic voussoirs, 18 outboard decorative rosettes and 2 packed textures. Its editable .blend and .glb remain hosted by Higgsfield rather than copied to GitHub or Drive.
- Two unlimited Higgsfield image references completed and indexed under docs/art_reviews. They are non-canon art studies.
- Actual approved Phase11 F5 project is not recovered; Phase09 and Phase10 GitHub branch refs share the same commit and are not evidence of the later local approved scene.

## Commands to execute only on the actual approved project

Run the scripts from game/crownsfall_lootslice with Python 3.11+. Replace all EXAMPLE paths with real locations. Do not run against a stale Phase08 project.

1. Read-only file/sha inventory:
    python tools/phase18_citadel_recovery_audit.py "C:/EXAMPLE/APPROVED_LIVE_CROWNSFALL" --out "D:/EXAMPLE/phase18_recovery.json"

2. Create an immutable project ZIP outside that folder:
    python tools/phase18_citadel_immutable_backup.py "C:/EXAMPLE/APPROVED_LIVE_CROWNSFALL" --out "D:/EXAMPLE/phase18_approved.zip"

3. Verify the archive independently:
    python tools/phase18_citadel_immutable_backup.py "C:/EXAMPLE/APPROVED_LIVE_CROWNSFALL" --out "D:/EXAMPLE/phase18_approved.zip" --verify

4. Dry-run staged-only Phase17 art candidate:
    python tools/phase18_stage_citadel_candidate.py --approved "C:/EXAMPLE/APPROVED_LIVE_CROWNSFALL" --source "C:/EXAMPLE/PHASE17_PROJECT" --backup "D:/EXAMPLE/phase18_approved.zip"

5. Only after successful dry-run, optional inactive asset copy:
    python tools/phase18_stage_citadel_candidate.py --approved "C:/EXAMPLE/APPROVED_LIVE_CROWNSFALL" --source "C:/EXAMPLE/PHASE17_PROJECT" --backup "D:/EXAMPLE/phase18_approved.zip" --apply

Candidate is copied only to assets/25d/citadel/candidates_phase17_inactive. No scene, scripting, navigation, input, save or inventory files are modified or automatically enabled by this tool. Never use the previous backup as certification that an updated project remains identical once staging has occurred.

## Validation

Run Phase18 unit tests in isolation:
    python -m unittest discover -s tests -p "test_phase18_*.py" -v

Result from exact GitHub code executed in isolated Python runtime: 22/22 passed. No claim of a recent GitHub Actions pass or authenticated Windows production test.

Run Blender sculpt validator after obtaining the actual revision 5 .blend:
    blender --background AOTL_Citadel_Higgsfield_Phase18_v05.blend --python tools/validate_citadel_sculpt_v18.py

The exact committed Blender validation passed against revision 5 inside Higgsfield. Godot F5 path traversal remains unverified.

## Unresolved quality gate

Recover the genuine current approved Phase11 project, backed up verbatim. Inspect true NavRegion and stair endpoints. Port only additive bridge API methods (never older Phase08 game scenes wholesale). Verify F5 plaza-to-Citadel navigation, all nine tread foot contacts, player IK, collision on/off with F4, paint fallback with F8, knight occlusion via F10 and 1080p/1440p matched screenshots. Approve the art against the six locked painterly references before a default visual swap.

GitHub tracked issue: https://github.com/mlyons0990/age-of-the-lost/issues/59
GitHub draft PR: https://github.com/mlyons0990/age-of-the-lost/pull/55
Drive backup handoff: https://docs.google.com/document/d/1oNj6WV02hfsf4CShLCClkTvQ4FOl9p-oXCurf4idaxI/edit
Higgsfield revision: https://higgsfield.ai/3d-jutsu/0361ff9b-2829-4595-a64e-564f39e1eeac
