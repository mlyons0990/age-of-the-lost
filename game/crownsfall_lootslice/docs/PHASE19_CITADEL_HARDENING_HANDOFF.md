# AOTL Phase 19 — Citadel Sculpture and Navigation Hardening Handoff

**Status:** isolated engineering candidate, **DO NOT MERGE** into the locally approved Phase11 playable game until the authentic project is backed up and verified.

## New sculpt assets (separate Higgsfield source)

Editable 3D Jutsu project: https://higgsfield.ai/3d-jutsu/0361ff9b-2829-4595-a64e-564f39e1eeac

- Revision 5: 481 meshes, 9 original treads, 32 original Gothic arch stones, 18 parapet rosettes.
- Revision 6: +26 art-only twin fountain meshes with concave basins, limestone plinths, blue mosaics, brass spouts and curved water ribbons (507 total).
- Revision 7: +64 art-only Gothic carved lancet relief and shadow cut meshes placed directly in front of the 32 original arch voussoirs (571 total).
- Exact source reconstructibility checked: all 26 fountain and 64 arch meshes have matching vertex geometry fingerprints when rebuilt from the committed scripts inside a temporary Blender query scene.
- Blender v7 safety validator PASS: 9 original 0.2m-rise treads, 7.5m central corridor, 32 arch stones, 18 rosettes, 26 fountain meshes, 64 arch decoration meshes, 2 packed textures, no unpacked external image dependencies; all new meshes visual-only and no game collision owner.

### Reproducible Blender sources

1. `tools/build_citadel_fountains_v19.py`: run on **exact Higgsfield v5** only, yields v6.
2. `tools/build_citadel_arch_relief_v19.py`: run on **exact v6** only, yields v7.
3. `tools/validate_citadel_sculpt_v19_v07.py`: validate v7 from Blender 5.2.
4. `data/citadel_phase19_v07_quality_manifest.json`: provenance and acceptance restrictions.

The binary v7 `.blend` and GLB remain retained **inside Higgsfield**, and are **not copied into GitHub or Google Drive**. The source, QA and manifests are mirrored into GitHub and the Google Drive Phase19 handoff. The already committed 1,197-mesh Phase17 Godot candidate GLB is a *different* portable asset.

### Before/after scene diagnostics

- Fountain addition, fixed 640×360 delivery-camera render: 2,504 of 230,400 pixels changed by more than 4% RGB (1.087%).
- Fine arch relief addition: 134 of 230,400 pixels changed by more than 2.5% RGB (0.0582%).
- These are numeric visibility diagnostics, not aesthetic approval. **The arch details are barely readable at wide gameplay camera distance**, and 64 extra per-mesh objects may add draw calls. Review close-up and implement batching/LOD before promoting to live PC gameplay.
- The visual quality still falls short of the six user-approved Crownsfall painted reference images; do not force-enable this sculpt.

### Citadel navigation and toggle reliability

The optional V17 bridge now verifies the existing (authoritative) indexed `NavigationPolygon` union using:
- adaptive cross-section intervals no greater than 0.15m (minimum 17 sections; reject >512);
- five width lanes, including near both corridor shoulders;
- **exact indexed polygon-edge crossings** with interval membership validation to detect gaps too narrow to appear in sampled points;
- no independently authored 3D navigation, new gameplay actor, save schema or collision authority.

Godot regression `tests/citadel_nav_hardening_v19.gd`: 32/32 assertions passed, including 16 deterministic gaps ranging from 4mm to 140mm and rotated NavigationRegion2D coordinates. [Confirmed CI](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43404986125).

Godot regression `tests/citadel_toggle_stress_v19.gd`: 32 art preview cycles, 64 original colliders, nav immutability and no duplicate meshes; 266/266 assertions passed before the additional F8 reentry cases were appended. Follow the latest CI for F8 reentry tests before claiming the higher count.

Prior Phase17/Phase18 suite: 266 separate isolated Godot assertions and 22 Python backup/staging safety tests. None is a claim of a full F5 traversal in the user's authentically approved Phase11 scene.

### Recovery blocker / next production gate

Actual locally approved Phase11 Godot source is still missing from connected GitHub and Drive. Phase09 and Phase10 branch refs are identical and cannot substitute for it.

1. Obtain the exact locally approved project and establish immutable SHA256 backup with the Phase18 utilities.
2. Validate the source's existing `NavigationRegion2D` and measured stair endpoints.
3. Stage only a verified art candidate in an inactive folder on a copied project, preserving original painted scenery.
4. Port only additive APIs, not the older Phase08 branch wholesale. Test F5 plaza-to-upper-Citadel, F4/F8/F10 fallbacks, knight contact/IK, occlusion, NPCs, inventory, saves at 1080p/1440p.
5. Accept art direction, material fidelity and batching/performance before enabling any new default.
6. Keep the PR in draft until all gates pass.

[Tracking issue #59](https://github.com/mlyons0990/age-of-the-lost/issues/59) · [Draft PR #55](https://github.com/mlyons0990/age-of-the-lost/pull/55) · [Google Drive complete source backup](https://docs.google.com/document/d/1IZ_JGpEfq9kWjb5hcYGPJsKqG73poUFmQVMGmuDD5XU/edit)
