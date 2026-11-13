# AOTL R39 Warrior — Animation-Timed Weapon Contact Pass

Date: 2026-11-13  
Branch: `dev/r39-weapon-sweep-v1`  
Parent: `dev/r39-3d-combat-geometry-v1` (prior 16 geometry + 8 live tests, 994/994 Crownsfall)
Stable `main`: unchanged.

## Implemented

### Imported animation contact events

The R39 Warrior's real imported `Slash` and `Cast` clip playheads now drive the once-per-attack `impact` signal. A preserved missing-animation fallback uses 85% of the attack's requested duration. The old 0.25-second universal sword hit timing has been replaced.

- Slash / Cleave / Dash contact phase: 0.57 of their imported Slash clip
- Cast contact phase: 0.40 of its imported Cast clip
- No impact during initial windup and no second hit through recovery

The Slash timing is grounded in Blender's R47 source `WeaponRoot` motion (frames 1–23 at 30 fps; strike movement around frames 12–17). This is a better fit than the original 0.25-second shortcut, but exact hilt/tip mesh sweep still requires visual calibration.

### Blade-sweep geometry

`scripts/three_d/weapon_sweep3d.gd` provides:
- Point-to-segment projection and squared distance, including degenerate input handling
- Conservative capsule-style overlap with previous/current blade segments, hilt/tip movement, and cross-diagonals, to catch a strike crossing a target between simulation frames
- Contact phase and active contact windows
- Source `BoneAttachment3D` hilt/tip sampled through real imported skeleton transforms
- Multiple-sample moving-blade target overlap

### Playable QA comparison

The R39 3D rig lab now records up to 24 weapon-socket samples during the actual Slash. **F8** enables strict sword-path targeting (experimental) and F8 again returns to the previously validated directional/collision-aware attack. The default stays in baseline mode; all cover and facing protections remain active. The HUD identifies `Sweep: baseline/STRICT`.

The strict feature is a QA mode, **not production-certified**. It uses a provisional local blade direction and target capsule; refine it after seeing the sweep trajectory in Godot. It is intentionally reversible.

## Higgsfield render

The original R47 Blender `Slash` action was rendered in Workbench at real frames 1, 6, 10, 13, 16, 19, 22, 384×384, no generated in-between frames.

- GIF: `previews/warrior_r39/real_slash_contact_7frames.gif`
- Provenance: `previews/warrior_r39/slash_contact_provenance.json`
- SHA-256: `841d0c337314b76a7e05b3ee265b147a8daf85574174dba80ce71f1d8bebd746`
- Preserved as a Higgsfield project asset and in Google Drive.

The R36 full authoring rig, R37 production profile, R39 validated GLB and later action snapshots are not overwritten.

## Validation

- [Actual R39 live weapon animation test](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43403263389): **11/11** checks, including real WeaponRoot socket samples, no early hit, contact hit, unchanged 32 damage, no duplicate follow-through and F8 comparison state.
- [Weapon-sweep geometry test](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43403365347): **23/23** tests including moving-blade intersections and contact timings.
- Full 17-suite Crownsfall regression workflow is configured: `.github/workflows/r39-weapon-full-regression.yml`. Two legacy lab assertions originally assumed the old 0.25s impact and were updated to reflect the now-verified animation timing. The unchanged remaining 16 suites passed on the first attempt; the full suite is being rerun.

## Next technical work

1. Calibrate the true blade orientation and target capsule using the actual Godot R39 asset plus contact GIF; don't enable F8 strict mode as default until reliable.
2. Replace provisional collision volume with socket-driven capsule or swept convex segment broadphase and timed multi-contact resolution that hits each target only once.
3. Use dedicated damageable/cover collision masks for future enemies and destructibles instead of assuming every layer-1 collider is opaque.
4. Add camera-follow combat captures and visual QA in the full 3D Crownsfall scene, then run all 17 suites before merging upstream.

## Later pass: actual bone-axis calibration and continuous collision

The first R39 Godot probe showed that the original provisional local -Z blade tip direction missed the sample training dummy even when the authored animation was playing. [Measured in Godot](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43404167311), the local **negative-Y** direction was closest: at 0.65m directly ahead its blade-to-target distance was about 0.529m (within the 0.57m combined weapon/target collision radius). At 1.35m it remained about 0.928m away (outside physical reach). Other tested axes missed.

The sampler now uses local -Y while **F8 remains opt-in**. Damage in strict mode is resolved over the actual active Slash swing window in `_physics_process` using consecutive weapon-bone transforms, rather than relying on the single animation event to catch a moving blade in one frame.

A serial number is assigned to every accepted Warrior attack. A per-swing target ID ledger is shared between strict and baseline modes so a dummy cannot receive multiple damage applications from one ongoing strike, even when F8 is toggled mid-animation.

### Reusable collision-backed hurtbox

Added `scripts/three_d/hurtbox3d.gd`: a damageable `Area3D` with a 0.45m sphere centered at 1.2m above its owner, on collision layer 4 (world cover remains layer 1). `training_dummy.gd` now exposes `damage_center()` and `damage_radius()` derived from the real attached hurtbox, and strict sword overlap uses these instead of a hardcoded target center.

### Verification

- [Real R39 strict sword collision test](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43404878491): **12/12** checks with the actual imported 62-joint skin, runtime physics backing, hurtbox area query, sword contact at 0.65m, no contact at 1.35m, no hits through a physical wall, and once-per-swing behavior.
- [Full Crownsfall regression](https://github.com/mlyons0990/age-of-the-lost/actions/runs/43404927057): **994/994** across 17 suites, after introducing the collider-backed training target.
- A subsequent F8 mid-swing mode-change regression was added to guard against cross-mode duplicate damage, and a corresponding complete 17-suite regression is queued on the latest branch state. Check those latest workflow results before accepting the branch.

**Important:** A collision-backed target is not the same as a physically exact sword-on-mesh collision. The swept-blade method remains a capsule approximation using bone poses, designed to preserve gameplay responsiveness and support future specialized weapon geometry.
