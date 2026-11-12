# Actor feedback and selective voice reference

[Complete playable source](../../../game/crownsfall_lootslice/README.md) · [Implementation handoff](../../../game/crownsfall_lootslice/docs/ACTOR_FEEDBACK_HANDOFF.md) · [PR 9](https://github.com/mlyons0990/age-of-the-lost/pull/9).

- [Review bundle on Drive](https://drive.google.com/file/d/1JTa2yOkxsWT0EBKyOtLoYD5Uib_BxVf9/view): seven native pose captures, full QA logs, handoff and Grady audition. This is a review package, not a standalone game or installation patch.
- [Listen to Grady's audition](https://drive.google.com/file/d/16-cz2Vg_FC00rrcrv-_-PsLkDcGXWbrG/view): unintegrated ElevenLabs tone reference, 4.36 seconds, generated with the existing free allowance at zero credits. Voice scope is selected NPCs and enemies.

Source commit: `364e9c0391c7f3d2cc08a98da1cf077fb40cfae9`. A separate GitHub checkout downloaded this commit and verified **612 game file hashes plus the original Grady audio hash**. Seven new Git LFS images were uploaded, approximately 17 MB.

The code passes **954/954 checks** in 16 headless suites. The actor suite also passes its **54/54 checks rendered**; repeats are not added to the distinct count. See the handoff for screenshot conditions and validation limits.

Review ZIP: 17,080,843 bytes; SHA-256 `1015f72f224df62828dd5519ebf620da08c57d7e488f5da3a3b64c169cef8d02`. CRC and all 33 payload hashes verified before upload. Drive metadata confirmed exact size, download permission and private sharing for both review ZIP and MP3.

Grady MP3: 70,260 bytes; SHA-256 `583f7ed6c40dac72937fe47e204606ab3688a4312d442fc3b2e1b42ad36fa2ad`. Provider completion and request metadata are in `audio/voice_auditions/2026-11-12/` at repository root. No human listening approval is claimed. The existing 13 procedural in-game cues remain selected.

Older Drive game ZIPs remain valid snapshots of their named releases; use the current GitHub source for this code cycle. No new Windows executable is included.
