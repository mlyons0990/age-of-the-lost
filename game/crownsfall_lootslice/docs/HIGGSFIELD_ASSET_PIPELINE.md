> Art-pass provenance: the current Mastery revision adds six painted mastery/unique icons, a front modeling reference and a schema-4 gameplay layer. Current totals and rules are in `MASTERY_SYSTEMS.md` and the root README. The 156-check count below identifies the earlier art milestone.

# Higgsfield art and audio delivery

November 11, 2026. User approved the canon-reference upload and unlimited allowance. Seven image jobs completed: six PNG sources passed visual review and one native GIF was rejected. `data/higgsfield_generation_manifest.json` retains the prompts, configurations, reference identities and job IDs. Paid credit balance stayed at 1.5.

## Integrated assets

Mage has a dedicated painted character bank. Five source facings (up, northeast, right, southeast, down) and mirrored west facings cover eight screen directions. Each has four walking poses, one idle and two casting poses: 35 frames in fifteen PNG textures. Warrior keeps its supplied art. Eight painted spell icons and seven painted gear icons override their vectors; a bonus spellbook is a source painting, not a new item. All 39 editable SVGs remain. A blue/gold nine-slice skin is used by modals, and a portrait derived from the turnaround appears on the Mage class button.

Thirteen short mono PCM WAV cues cover eight Mage abilities, slash, equip, pickup, potion and UI click. These are deterministic procedural sounds authored through Higgsfield's media sandbox, not generated speech/music. Peak is approximately 0.55 before runtime −15 dB gain. Eight playback voices are reused. The pause-menu mute control stops playback and saves a separate audio preference file.

## Runtime contracts

`art_library.gd` chooses paintings by stable gameplay ID, retains vector fallbacks and supplies the panel texture style. Text, numbers, buttons, hit areas and tooltips remain actual Godot controls. Texture/content margins are 64px to preserve corner ornaments.

`player.gd` switches Mage/Warrior frame banks on class changes and load. An incomplete Mage set falls back as a whole. Frames are 384 square with a common feet anchor (192,368). Walk poses run at 6 fps. Mage windup holds pose zero; authoritative gameplay release selects pose one. Combat timers and damage calculations remain authoritative; image playback never applies damage. Cancellation clears the visual timer.

Ability audio starts only after commitment. Rejected cooldown/resource attempts do not emit another ability cue. Equip/unequip, pickups and potions emit cues after success. Audio settings process while paused. Graceful quit stops playback, releases streams and lets the mixer drain before exit.

## Sources and reproducible processing

`assets/higgsfield_sources/` contains the accepted turnaround, two icon atlases and walking/idle-cast pose sheets. Its `.gdignore` avoids importing these large source boards. The original panel source is already its runtime PNG. Canon originals remain under `references/canon_originals/`.

In a project copy with Python, Pillow and numpy:

```sh
python3 tools/rebuild_higgsfield_assets.py --project .
```

This rebuilds icon crops, anchored Mage frames, portrait and synthesized cues. An independent run in Higgsfield's sandbox reproduced all **45 derived PNG/WAV files byte-for-byte**. `data/HIGGSFIELD_REBUILD_VERIFICATION.json` records the result. Asset manifests retain dimensions, cell mappings, synthesis metadata and hashes.

## Review boundaries

The combined native GIF duplicated front-facing figures and changed framing. It is retained under `assets/higgsfield_sources/rejected/` with a rejection note and is never used in gameplay. The accepted PNG sheets replaced it. The source gallery includes this rejected experiment for provenance.

These are four-pose prototype walking cycles and two cast poses, not production skeletal animation. The baked staff/clothing do not change when gear is equipped. Hurt, dodge and death clips, cloth/IK, interpolation and hand attachment points remain future work. Mirroring also mirrors handedness and trim. Technical audio checks do not replace a human listening/mix review.

Tripo quoted 9 credits against 1.5 available; no mesh or rigging job was submitted. The included 3D model remains the preserved 58-bone/six-clip geometric lab proxy. This sound layer does not include music or spatial mixing.

## Verification

52 Warrior + 57 Mage + 28 lab + 19 art/audio checks = **156 unique assertions**, all passing in Godot 4.6.3 Linux. Mage also passed its 57-check suite under rendered X11/software OpenGL. New checks exercise class frame-bank switching, painted/vector routing, cast poses, cue commitment/rejection, importing all cues, mute recreation and pause-control behavior without rewriting progression.

`previews/` contains actual engine screenshots and sampled combat GIFs. Raw source boards and generated concepts are distinct from those captures. Windows, target hardware performance and production audio mixing remain unvalidated.

## Cantor encounter addition

Accepted GPT Image 2.6 unlimited job `ea670ac5-a3fe-42e8-a6c0-5fcf33326583` supplied the new 2048px briefing portrait. `tools/rebuild_cantor_portrait.py` retains it under `assets/higgsfield_sources` and produces a 512px runtime PNG. Full prompt, configuration, source/runtime hashes and purpose are in `data/cantor_art_manifest.json`. This is one additional reproducible derivative beyond the inherited 51 files. Paid balance remained 1.5. The world actor deliberately uses the inherited Revenant body; the portrait is not a new animation bank.
