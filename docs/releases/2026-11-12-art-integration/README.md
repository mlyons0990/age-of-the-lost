# Playable art integration — November 12, 2026

- [Download complete playable Godot source ZIP](https://drive.google.com/file/d/1PiBL4mpatK4GWrtUpGWSMkL-L5d-MSEP/view)
- [Open five-page native-screen review](https://drive.google.com/file/d/1Fh9sNnOgJhov0gg3k5d8LT5QQqI1HSY7/view)
- [Editable artwork and development index](https://docs.google.com/document/d/131-JFsR6pRWZPwCLMi75Vi4ldUj6zDSxtOZa2LdvIo8)
- [Full source in this repository](../../../game/crownsfall_lootslice/README.md)
- [Detailed integration handoff](../../../game/crownsfall_lootslice/docs/ART_INTEGRATION_HANDOFF.md)

Unzip, import `project.godot` in Godot 4.6.3, wait for import and run. The ZIP includes every runtime asset; the separate art libraries are optional for playing. Git clones require Git LFS and `git lfs pull`. This is source, not a Windows executable.

42 accepted designs are selected at runtime. Automated checks pass 825 assertions across fourteen suites, plus six additional native mouse checks (831 distinct overall). The exact ZIP was independently extracted, CRC-checked, verified against 532 file hashes and passed all 825 headless checks again. Full logs from that transfer check are included here. Native rendered logs and captures are in the game project. `delivery_manifest.json` records the archive SHA-256, byte size, source commit, preservation results and Drive IDs.

Only documentation previews in the Drive ZIP are compacted to meet its upload limit. Original/runtime artwork is unchanged; full native captures remain in GitHub and the review PDF. All 147 original media/reference/model files and core gameplay rules are preserved from the verified Loot Recovery source. The Knight-focused Godot 4.3 fork remains independent.

Next priorities: human inventory/encounter playtesting, Windows/target hardware validation, then actor state and equipment-appearance work. Current 2D outfits are baked into sprites.
