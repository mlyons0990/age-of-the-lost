# Selective dialogue pilot

The user selected Grady and asked for only selected NPCs and enemies to be voiced. This small pilot adds one Quartermaster greeting and two Unwritten Cantor lines. These are newly authored prototype lines, not quotations from established lore or a decision to voice every character. Casting and delivery remain open to human review.

All three use ElevenLabs through Higgsfield: `text2speech_v2`, `variant: elevenlabs`, preset Grady `e2a2d2e6-9ed2-59cd-82af-feaa27f8a678`, `use_unlim: true`. Every preflight quoted **0 credits**; no purchase or paid fallback was used. Original output bytes are installed under `game/crownsfall_lootslice/assets/audio/dialogue/` at repository root. No conversion, pitch filter or effects were applied. Hashes and decode metadata are in `manifest.json`; exact prompts, provider settings and completed jobs are in `provider_results.json`.

| Cue | Line | Completed job |
|---|---|---|
| Quartermaster greeting | Take what you need. The Scar will spare you nothing. | `ef252411-cf39-4e06-81a4-1a452c36eab3` |
| Cantor challenge | The city will forget you. | `e275a359-3617-4ffd-af8b-42bf099a5bb7` |
| Second verse | Another verse. Another name erased. | `a639c1aa-7c36-40ba-93c9-54f7ce3398fc` |

The initial parallel submission accepted only the challenge; the other two definitively failed with provider rate limits and created no jobs. Each was then submitted individually after the preceding job completed. All three completed successfully. Earlier cost checks blocked by the chat usage limit created no jobs either.

FFmpeg successfully decoded all three originals; each is mono MP3 at 44,100 Hz. Durations are approximately 4.44, 2.04 and 3.00 seconds respectively. Engine checks confirm playback, subtitle, pause and lifecycle behavior. Neither human listening approval nor final voice casting is claimed. The earlier standalone Grady audition remains unchanged.

Future generations must still be free: recheck allowance eligibility and quote before submission, retain explicit `use_unlim: true`, and never fall back to credits. The current allowance expires November 13, 2026 at 19:43:34 UTC.
