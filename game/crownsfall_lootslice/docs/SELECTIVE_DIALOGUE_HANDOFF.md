# Selective NPC/enemy dialogue

The pilot voices the Quartermaster's first shop greeting and the Unwritten Cantor's entry and second-verse transitions. Grady is the user-selected voice. The three newly authored prototype lines are defined in `data/dialogue_lines.json`; the original ElevenLabs MP3 bytes are under `assets/audio/dialogue/`. They are not a commitment to full character voice-over. Human performance/casting review is still needed.

## Runtime behavior

`scripts/dialogue_controller.gd` owns a single speech channel and a click-through, speaker-attributed subtitle panel. It does not schedule damage, movement, encounter attacks, rewards or transactions.

- Opening the Quartermaster starts a greeting, with a 30-second repeat cooldown. The line can play while the service modal pauses the world. Closing or switching the service stops it; shop refreshes do not repeat it during cooldown.
- Entering the Cantor encounter starts its challenge. Crossing half health starts the higher-priority second verse. Each has a 20-second repeat cooldown. Lower/equal-priority lines cannot interrupt; obsolete lines are never queued.
- Pausing suspends encounter audio and subtitle time together. Resuming continues that line. Retreat, victory, player death and scene teardown cancel the relevant playback.
- Missing audio falls back to the same subtitle. Unknown IDs are safely rejected. Subtitle display time covers both the spoken clip and a bounded reading interval.
- Pause offers separate dialogue voice on/off, voice volume and subtitle on/off controls. These persist in `user://dialogue_preferences.cfg`, independently of SFX settings and schema-six character saves. Muting stops the active voice; enabling it applies to the next line rather than replaying a partial line.
- The approved skill-icon artwork, actor feedback, inventory dimensions and combat timing remain intact. All 13 procedural SFX are unchanged.

## Validation and continuation

The full headless runner passes 994 assertions across 17 suites, including 40 dialogue checks. The new suite exercises real shop opening/closing, a real Cantor start/phase transition, pause/resume, retreat, lethal damage, missing audio, the actual settings controls, preference reload and save preservation. See `tests/dialogue_qa/` for logs and `previews/dialogue/` for native captures when present. Counts for repeated rendered checks are not added to the headless total.

Audio decode and engine playback checks do not substitute for listening review. Linux/Godot 4.6.3 is the tested platform; Windows export and target-hardware testing remain pending. No money or credits were spent. Provider requests, completed job IDs and file hashes are saved at repository `audio/dialogue_pilot/2026-11-12/`.

Next: review the three actual performances in context, then tune dialogue mix and readability during a human encounter playtest. Expand only selected NPC/enemy lines. Dedicated directional hurt/death frames and equipment appearance remain separate animation work.
