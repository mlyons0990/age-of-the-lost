# Age of the Lost — Phase 05: Crownsfall's first playable area, art/world alignment

**2026-11-12 | Godot 4.6.3 | Draft release gate | No paid Higgsfield credits used**

This work advances the **real playable Crownsfall game** from Phase 04. The original painterly character sprites, inventory, live quests, combat, monsters, player pathfinding, equipment, stash, 5 active skills, and schema-six saves remain authoritative. The user-approved November 12 reference screenshot defines the **visual goal**, not a rendered game frame or texture atlas. The Phase 05 build is **not** yet an art-complete city.

## Usage

- Open `game/crownsfall_lootslice/project.godot` using **Godot 4.6.3**.
- **F5** runs the real playable town, with the original painting as safe default.
- **F8** activates/deactivates the integrated 2.5D city environment. The actor, combat, quests, inventory and saves remain the same.
- **I / C / K**: inventory, character and spellbook. **E**: functional town service. **R**: Reality Scar waves. **Q**: existing health potion. Camera wheel to adjust framing.
- No files in `user://` need migrating. Work from a separate extracted directory to preserve a stable Phase 04 baseline.

## What changed

### 1. Painted floor anchored to the REAL navigation polygon

`Crownsfall_2P5D_Procedural_Courtyard.install_painted_walkway` now constructs an actual 3D triangle mesh from the exact original **`main.WALKABLE`** vertices. UV coordinates derive directly from `assets/plaza.png` (2720 × 1536). The 3D camera uses the existing pixel-to-3D orthographic transform from the Phase 04 `live_courtyard_bridge`. The mesh footprint is exactly the same as the already-tested 2D navigation outline (637,998 canvas pixels²). This avoids misaligned independently authored walking surfaces.

The new `assets/25d/crownsfall_nav_floor_softmask.png` comes **programmatically** from that polygon and fades the original painted stonework into the surrounding 3D tiles over roughly 110 canvas pixels; it is not new AI art or a replacement for the canon painting. The old low-fidelity 3D gold ring is hidden when the authentic, more detailed painted crest is used.

### 2. More painterly surrounding paving

The 60m plaza remains an editable Godot 3D environment, but its floor now has more than 3,600 half-sized instanced stone blocks rather than 961 large flat squares. These receive a repeatable, subtle diffuse-detail texture derived from a clean stone sample of the already-approved `assets/plaza.png`, stored at `assets/25d/crownsfall_ivory_paver_from_approved_art.png`. No paid generation or new licensing is required.

### 3. Foreground architecture and sprite occlusion

The existing **seven approved painting cutouts** (`main.OCCLUDERS`) stay active in the hybrid mode, with original Y-sorting. They now use an alpha-feathered copy of the **same original painting**, created without changing its source pixels: `assets/25d/crownsfall_original_cutouts_feathered.png`. F8 restores the original unmodified `PLAZA` texture for every cutout in painted mode.

This gives characters correct painterly foreground layering for those seven authored pieces. It **does not** mean arbitrary new 3D meshes now support pixel-accurate depth occlusion. That remains a separate acceptance gate.

### 4. Audited physical/nav alignment

The existing 3D props registered through `_solid` (Citadel pillars, side parapets, garden planters, market counter, fountain base) now expose their geometric XZ collision footprint. On hybrid startup the bridge projects those footprints into the original game map and checks for intersections with `main.WALKABLE`. All current blocker footprints fall *outside* the original walking outline; therefore the integrated scene has no **new** walkable-floor obstacles requiring nav holes. The original `NavigationRegion2D` is unchanged and remains authoritative.

A failed overlap is reported as a warning for the art team; it is **not** silently treated as a real nav barrier. Future architectural additions that cross the walkable polygon need exact 2D obstacle polygons and a rerun of all reachability tests before release.

### 5. Gameplay stays genuine, not staged

The actual four town-service locations (`SERVICES`), active quest noticeboard indicator, Reality Scar state, Inventory, Grimoire and Stash continue to come from the real game. The live 2.5D smoke test verifies pathfinding to the four services and their correct 3D screen-space projection. Class visual swapping is unchanged, and none of the graphics alterations touch player hotbars, equipment items, combat calculations or save schema.

## Verification

- New Godot test: `godot --headless --path . --script res://tests/crownsfall_world_alignment_integration.gd` — includes the 72 Phase 04 baseline integration checks, floor/nav source correspondence, texture provenance, projected 3D obstacle exclusions, 7 cutouts, painted mode restore, 4 service path checks and stone art checks.
- Existing core regression: `python3 tools/run_checks.py --godot /path/to/Godot_v4.6.3-stable_linux.x86_64 --report-dir /tmp/aotl-phase05-qa`.
- Actual before/after Godot renders are used for visual inspection, **not** the user-provided concept screenshot.
- Run tests in an **isolated** XDG user-data directory; do not overwrite existing Windows saved characters.

## Completion gate — city first, other zones later

The first playable Crownsfall area will not be called 'complete' until the following pass as a coherent baseline:

1. **World art:** all architectural silhouettes, stairs, walls, market stalls, banners, foliage and lighting genuinely match the November 12 canonical painterly reference in the *runtime view* (not only a concept render).
2. **Movement / navigation:** full walkable area, blockers, collision, pathfinding, service reachability, enemies, projectiles and loot obey the same obstacle layout. This phase currently audits only existing solids that are outside the active walking zone.
3. **Occlusion:** full, dynamic 3D foreground geometry hides player/enemies naturally where appropriate; the current 7 source-image foreground cutouts are only a partial solution.
4. **Characters:** class-specific anime knight geometry/sprites closely follow the six approved official artworks at the actual gameplay scale; convincing walk, run, attack sequences, dodge roll and casting; no placeholders presented as finished. Rig reuse and class gear visual modules validated before cloning other classes.
5. **Gameplay/UI:** real core quests, combat encounter loop, full inventory/equipment interactions, spellbook, five active skills, town services, XP/HP/MP and PoE-edge HUD all integrated and playtested end-to-end (not merely unit-tested).
6. **Stability:** Windows visual playtest at 1080p/1440p, readable UI, performance measurements, regression suite, state migration/rollback safety, and representative GIF/video previews.

**Do not start developing new zones outside Crownsfall as though this work is signed off.** Improve the single first playable city until the acceptance gates are satisfied.

## Known caveats

- The primary 3D courtyard geometry still consists mainly of procedural blockout meshes and cannot honestly be called a finished match to the approved 'Path of Exile-like' game image.
- Art foliage and stone occluders come from the original painted town, not fully sculpted 3D architecture. Their original y-sorting works, but the 3D world and its depth are not yet a unified occlusion system.
- No new 3D humanoid mesh or animation was generated in Phase 05. The existing Warrior/Mage artwork is preserved while the character-art pipeline remains a separate acceptance track.
- No new gameplay abilities, loot tables, quests, flask types, character creation rules or outside-Crownsfall zones were added, to avoid destabilizing the live build.
