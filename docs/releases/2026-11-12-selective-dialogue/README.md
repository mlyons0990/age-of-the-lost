# Selective dialogue delivery

[PR 28](https://github.com/mlyons0990/age-of-the-lost/pull/28) · [Implementation handoff](../../../game/crownsfall_lootslice/docs/SELECTIVE_DIALOGUE_HANDOFF.md) · [Editable Google Doc](https://docs.google.com/document/d/131-JFsR6pRWZPwCLMi75Vi4ldUj6zDSxtOZa2LdvIo8).

- [Current playable source ZIP](https://drive.google.com/file/d/1WNdWgUVhqdtpQ9BGXECR8H5ldQvS5sRh/view): all runtime assets, code, tests, three original recordings, provenance and new native screenshots. Open `game/crownsfall_lootslice/project.godot` in Godot 4.6.3. No Git LFS download is needed for the ZIP.
- [Optional original review images](https://drive.google.com/file/d/1vC108ROuqezrT7s5M2avsKWNCPDHI7U9/view): extract into the same folder for the 68 earlier screenshots. They are documentation, not required runtime assets.
- [Quartermaster greeting](https://drive.google.com/file/d/1I76gMQyRUJgWt99hanNwzHymau-oXhOy/view), [Cantor challenge](https://drive.google.com/file/d/1cQlIvQvgY0Lwix88pvLdw6AYuVp_gDYy/view), [Cantor second verse](https://drive.google.com/file/d/1f5lCGUABG0ykue9iL01fyQ-R7yWzs9o5/view).

Source commit: `5a43d450423a0e9e5f587e495fcbc4b428347176`. Independent GitHub download verified **645 game file hashes**, including the three audio originals. Full QA: **994/994 assertions across 17 headless suites**, plus the same **40/40 dialogue checks rendered**. Native screenshots show the merchant caption, second verse and settings. Original icon art and inventory rules are preserved.

Source ZIP: **95,330,861 bytes**; SHA-256 `841edd20da0dc565471834edf6d074747dd3cc984cdf0676b65bfa99a4f8277c`. CRC and all **588 payload hashes** were verified before upload. Drive metadata confirmed exact size, download access and private sharing for the source ZIP and each recording. The uploaded ZIP's local temporary copy was removed after verification to reclaim disk space; authoritative sources, package recipe and hash manifests remain available.

All three ElevenLabs clips used the preexisting Higgsfield unlimited allowance, explicitly `use_unlim: true`, with zero-credit preflights. No money or credits were spent. Voice scope remains selected NPCs/enemies; human listening, final casting and Windows/target-hardware validation remain pending.

The Google Doc was updated and read back: current pilot behavior, counts, playable source, restore instructions and direct audio links; the existing 43-row art table and illustration were preserved. The first formatting attempt was rejected atomically by Google Docs; the corrected batch succeeded without duplicate content.

See [backup restore instructions](BACKUP_RESTORE.md) for the complete actor-feedback checkpoint saved before this continuation. Earlier art-master packages remain linked in the shared Doc and repository `art/`.
