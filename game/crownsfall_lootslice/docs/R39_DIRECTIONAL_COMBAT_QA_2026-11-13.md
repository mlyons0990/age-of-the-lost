# AOTL Warrior R39 — 3D combat geometry development pass

**Date:** 2026-11-13  
**Git branch:** `dev/r39-3d-combat-geometry-v1`  
**Base:** `assets/warrior-r39-sixclip` (real R39 asset is retained through Git LFS)  
**Production status:** Validated on a development branch, not merged into the stable game.

## Goal

Replace the original 3D rig-lab dummy-hit test (range and a permissive facing check) with reliable directional weapon reach and physics-backed line of sight, keeping the original abilities, effect timing, damage values, character asset, 2D Crownsfall game and save system intact.

## Files changed

- `scripts/three_d/combat_targeting3d.gd`: new reusable `RefCounted` utility implementing cast/cleave/dash/slash targeting profiles, horizontal distance and normalized facing, and `PhysicsDirectSpaceState3D.intersect_ray` for solid cover.
- `scripts/three_d/rig_lab.gd`: routes training dummy impacts through `TARGETING.can_hit` and `TARGETING.damage_for` rather than a simplistic distance/dot-product conditional.
- `tests/combat_targeting3d_integration.gd`: deterministic geometry tests plus real collision-backed physics tests.
- `tests/combat_rig_lab_live_integration.gd`: mounts the full Warrior rig lab and its real R39 asset, evaluates actual training dummy HP changes, cover blocking and removal, and area casting.
- `.github/workflows/r39-combat-targeting-ci.yml`: Godot 4.6.3 test runner for the isolated 3D physics utility.
- `.github/workflows/r39-combat-live-ci.yml`: Godot 4.6.3 full-Crownsfall scene import and real rig-lab combat regression.

## Grounded verification

**Geometry/physics suite:** [GitHub Actions 43400062918](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43400062918) — **16 checks, 0 failures**. Validated attack facing, distance, full-circle cast behavior, finite input handling, cover blocking and clear line of sight.

**Full live rig-lab suite:** [GitHub Actions 43400310844](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43400310844) — **8 checks, 0 failures**. Loaded real R39 Warrior in Godot 4.6.3 with IK and equipment sockets. Slash hit a visible dummy, failed through a physics-blocking wall, hit after cover removal, and refused a rear target. Cast retained its intended area effect and damage. The live test used the real game project in an isolated disposable data directory.

**Parent baseline:** [Full Crownsfall 994-assertion suite](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43398978398) passed before this combat branch. Those 994 assertions have **not** been rerun on this new branch; do not report them as the new branch's regression result.

**Original R39 model:** [Verified six-clip asset PR #53](https://github.com/mlyons0990/age-of-the-lost/pull/53); same existing GLB and SHA-256 `6e72468f2bfa6344c66c57cd0157c36949b53d8bb24f8d30c955da5f72e0ba55`.

## Design and caveats

- Slash and Dash use forward-facing hits; Cleave uses a wider directional arc; Cast uses full-circle area damage. Legacy base damage remains Slash/Dash 32, Cleave 43, Cast 53.
- Hit range is evaluated in the ground plane, and cover is sampled at approximately chest height. This works with the current visual-only `training_dummy.gd`; a future real enemy `CollisionObject3D` will need an intentional target collider exclusion/acceptance policy.
- The raycast uses collision layer 1. Decorative geometry without a collision body does not block attacks. Introduce explicit damageable/cover collision masks and multilayer surfaces before production enemies.
- Attacks are still *single timed impacts* driven by the existing Warrior controller, **not** per-frame weapon trail contact or bone-driven hurtbox overlaps.
- Godot headless smoke checks do not replace visual, audio or difficulty playtesting; use full desktop Crownsfall for those.
- Old model/proxy, earlier Higgsfield revisions and save data were not changed.

## Next responsible production steps

1. Use animated weapon socket and attack event timeline to generate weapon-specific swept hit volumes, retaining target-once semantics per strike.
2. Add enemy faction / shield / destructible-obstacle layers and distinguish intentionally transparent geometry from cover.
3. Align contact timing to the actual weapon's animation frames; benchmark frame-to-hit for Walk/Run/Slash/Cast/Dodge.
4. Re-run all 17 baseline regression suites after any changes to shared game systems, and capture a player-visible 3D combat demonstration.
