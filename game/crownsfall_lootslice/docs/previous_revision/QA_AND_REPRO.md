> ARCHIVED SYSTEMS EXPANSION: the current Mage Slice handoff and README supersede implementation/status claims in this chapter.

# Verification and reproduction

## Actual scope

This revision was imported and executed in **Godot 4.6.3 stable, Linux**. The final integration harness contains **52 checks**, run in an isolated save directory. A rendered run uses X11/Xvfb with software OpenGL and the Dummy audio driver. Assertions exercise the actual game scripts and UI callbacks; this is not a Windows manual playtest, performance benchmark, human usability review or 3D validation.

Final result files: `tests/HEADLESS_RESULT.txt`, `tests/RENDERED_RESULT.txt` and `tests/LAST_RUN.txt`. A successful run ends with `RESULT 52 checks; 0 failures`. Rendering can emit a V-Sync unsupported warning under the virtual display; no script error is acceptable. The package does not contain a shipped audio system, so Dummy is used deliberately for these captures.

## Tested behaviors

- Item first-fit insertion, full rectangular collision, edge rejection, self-UID movement and no-loss sorting.
- Level-1 formula checkpoints; equipped weapon contribution to actual combat stats.
- Ring 2, slot/level restrictions and rollback when unequipping into a full bag.
- Ability reassignment without duplication, cooldown retained by ID, level/discovery requirements.
- Guard against overwriting a pending melee contact callback.
- I/K/E/Escape input paths, pause/close behavior and bag drag commits.
- Navigation reachability of all service anchors; nearest-service interaction.
- Stash ownership transfer, merchant purchase, potion price and explicit sale.
- Save roundtrip, corrupt-primary backup recovery, future-schema write protection, duplicate UID and malformed field rejection.
- Melee damage waits until contact time; nova applies stun; cone applies burn; ground blast waits for its telegraph.
- Full bag pickup retains the ground item; successful pickup stores gear rather than auto-selling.

The harness injects key events, calls UI signals for transaction tests and drives actor methods for controlled combat. It does not use a human mouse gesture for every drag or sale. Merchant and stash callback tests prove source behavior, while the manual list below covers real gestures and visual interaction.

## Reproduce on Linux

From the project root, with Godot on PATH:

```sh
mkdir -p .qa/data .qa/config .qa/cache
export XDG_DATA_HOME="$PWD/.qa/data"
export XDG_CONFIG_HOME="$PWD/.qa/config"
export XDG_CACHE_HOME="$PWD/.qa/cache"
godot --headless --path . --editor --quit
godot --headless --path . -- --systems-test
godot --headless --path . --script res://tests/export_data.gd
```

Use a fresh `.qa` directory for a new clean-start check. To test repeatability, repeat the harness against the same isolated directory. Never point tests at a directory containing real progress. Import first so PNG/SVG resources have their normal Godot cache. Generated `.godot` and `.qa` folders are not included in this source package.

For actual rendered captures, provide an X11 display and run without `--headless`:

```sh
DISPLAY=:99 godot --audio-driver Dummy --path . -- --systems-test
```

The final session used a local Xvfb runtime; it is not a project dependency. On a normal desktop, just use the available display. Screenshot generation is skipped by the harness when DisplayServer is headless. The standard rendered run saves six UI/world PNGs plus 32 captured combat frames under previews. The delivery keeps the six PNGs, an icon atlas and a GIF assembled from those frames. Raw combat PNG sequences are excluded from the ZIP to keep it compact; rerun the harness to regenerate them. The GIF is not generated artwork.

## Reproduce on Windows

1. Extract to a new folder and import project.godot in standard Godot. Let all texture/icon imports finish.
2. Run a manual new-character session first and note the exact Godot version.
3. For automated tests, make a separate test copy. In Project Settings → Application → Config, change Custom User Dir Name to `AgeOfTheLost_Crownsfall_Systems_QA` before invoking the harness, so normal saves cannot be touched.
4. From PowerShell in that test copy, call your actual Godot console executable:

```powershell
& 'C:\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe' --headless --path . --editor --quit
& 'C:\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe' --headless --path . -- --systems-test
```

The path is an example, not an included executable. Record stdout, exit code and tests/LAST_RUN.txt. A Windows export requires the corresponding export templates and an export preset; neither is included or claimed tested here.

## Manual walkthrough and review gates

| Action | Expected outcome | Evidence to retain |
|---|---|---|
| Name a new character | Chosen name in HUD, inventory and save | Screenshot + save header |
| Equip sword/chest; try wrong slot | Legal gear changes stats; wrong slot keeps ownership | Before/after item UID and stats |
| Fill bag, then pick up a drop | Drop remains in world, clear full-bag message | Short gameplay clip |
| Drag a tall item along bag edge | Illegal positions rejected; no overlap or deletion | Mouse-gesture clip |
| Swap rings and compare | Either ring slot works; other ring retained | Equipment/bag UID count |
| Move an equipped item into a full bag | Unequip fails with no deletion | UI message and item still equipped |
| Open UI while moving/holding LMB | World pauses; release/close does not keep steering | Input clip |
| Recover memory twice | First unlock only, later inspection; no duplicate reward | Discovery array |
| Move cooling-down Cleave to another slot | Same remaining cooldown | Hotbar clip |
| Buy/sell/potion refill | Exact gold/item/stock deltas; no free duplicates | Transaction log |
| Transfer to stash and restart | Item stays in stash, does not duplicate in bag | Save before/after |
| Reach 20, select each spec in separate fixture | Matching skill unlock; other spec skills remain locked | Three fixture saves |
| Reach 40 | Matching heroic identity only; no automatic level-60 signature passive | Progression capture |
| Attack during windup/contact | One pending hit, visible contact at expected time | Frame/time annotation |
| Damage an enemy with burn/stun | Documented durations; no duplicate kill reward | Combat log |
| Corrupt test primary, retain backup | Valid backup recovery; corrupt bytes retained | All companion files |
| Put future schema in test save | Writing disabled; original file untouched | Byte/hash comparison |
| Open all screens at different sizes | No clipped text, hidden buttons or unreadable icons | 720p/1080p/1440p/ultrawide set |

## Render provenance and limits

`01_inventory.png`, `02_grimoire.png`, `03_lorecasting.png`, `04_stash.png`, `05_merchant.png` and `06_plaza.png` are captures of the real expanded Godot project, driven by a test fixture around level 10. They are not concept art or proof of manual playtest approval. Combat frames show an automated short sequence against a durable test enemy; it is not a balanced encounter or a boss demonstration. The GIF has no audio and its playback timing is an approximate presentation of sampled frames.

The HTML icon atlas can be opened locally in a browser. The atlas PNG is a separate Godot asset-board capture, not an in-world gameplay screenshot. No new Blender scene, 3D mesh, motion-capture animation, Windows executable or exported build was produced.

## Known limitations to preserve in the next handoff

- Two diagonal attack strips are borrowed for other directions. Enemies remain still sprites with procedural motion.
- Painted backdrop/hand-traced occluders remain; stairs do not change actor height. Some cutouts are rough.
- No production sound/music, controller navigation, rebinding, localization or user text scale.
- Only Warrior is playable; the thirteen-class data does not enable character selection.
- Full per-skill heroic trees, Ember Aura, unique powers, class resources and armor restrictions are design work.
- Current spellbook previews direct hit only; DOT/heal/mitigation and buff-aware detailed calculations need a shared tooltip resolver.
- Burn’s secondary scaling differs from recovered spell direct damage. Legacy CDR special-cases the primary slot.
- Primary-slot non-melee auto-chase targeting needs its own intent logic.
- World drops, active arena, HP/mana and cooldowns are not persisted. Merchant restock behavior is rudimentary.
- No old-save importer, exported Windows build or performance pass on user hardware.
- Opening a full item catalog, a JSON file or a generated table is not evidence those proposed mechanics run.
