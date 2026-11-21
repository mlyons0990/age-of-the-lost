# AOTL production blueprint and team handoff

Version 1.0 — November 21, 2026.

A complete production plan for achieving the approved AOTL camera/art direction with responsive, gear-driven ARPG gameplay. Includes **162 acceptance tasks across 24 workstreams**, each with a reason, completion criteria, owner role, milestone gate and dependencies. Architecture recommendations remain proposals pending a matched-camera comparison; this documentation does not approve candidate art or change the game.

## Read and assign

- [Production handoff](AOTL_Production_Handoff.md): 2D/3D/hybrid options, recommended allocation, current-source audit, art/camera/data contracts, milestones, ownership, risks and immediate next steps.
- [Full checklist](AOTL_Development_Checklist.md): complete development lifecycle, including conditional online systems and release/support.
- [CSV tracker](AOTL_Development_Tracker.csv): add named owners, status, milestones, task dependencies and evidence. All tasks begin unverified against the future reconciled production baseline; existing implementation can satisfy them after verification.
- [Shared native Google Doc](https://docs.google.com/document/d/142jE3zyPWfnX_7UNji4q6qxqwRB8eBqST8R-U-FuaCY/edit): complete handoff and checklist with a navigable heading outline.
- [27-page PDF](https://drive.google.com/file/d/1v_ft8orSeQ1Ex6R6qfT0e6nJXpZnGbt7/view).
- [Editable Word copy](https://drive.google.com/file/d/1SiURcNAlXvlhEwenJ240UbjAp3NHMl-u/view).
- [Drive CSV copy](https://drive.google.com/file/d/1l9Un_5smhiNu-VuDTfJCQZGdc72rvBE6/view).
- [Established AOTL Drive destination](https://drive.google.com/drive/folders/12yXmW4fFu6rsoqxYgfiEYm3_ibgG0Px8).

## Recommendation

Use a fixed-angle hybrid. Prefer rigged heroes and important combat enemies if they match the approved art and motion; use 3D ground/depth where elevation or interactions demand it, and painted scenery/cards/sprites where they remain convincing. Fully 2D characters and worlds are viable when camera, equipment appearances and height interactions are constrained. The whole world does not require unique modeling.

## Source and verification limits

The handoff reviews GitHub main, camera PR 42, draft Citadel PR 55, draft R55 PR 73, draft knight pilot PR 74, connected Drive reports and the user's reference direction. It distinguishes those branches from a single integrated build. The Windows project was not mounted during this pass. No new runtime tests or asset generations were performed, and no credits were spent.

Verified document integrity: 162 unique task IDs, required reason/acceptance fields, CSV agreement, all task IDs in the PDF, all PDF text within page bounds, and complete native Google Doc text readback. Representative PDF pages were visually inspected. Existing game test counts are attributed historical checkpoint evidence, not results of this documentation change.

The portable bundle includes the Markdown/CSV sources, semantic document/checklist JSON, PDF/DOCX builder and validation manifest. PDF/DOCX are generated from the same semantic content as the native Doc. Do not edit exported copies as independent sources of truth; issue a new version and reconcile updates with GitHub and the shared Doc.
