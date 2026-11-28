# Project A — Environmental Artwork Library v4

Active zone: Crownsfall. Preserve the gameplay source checkpoint 2da2abaa6da2f79fd43ac9663207b9aedd20c753; this is a review-only art handoff, not a runtime change.

## Shared original binaries and reproducible sources
- [Complete 28-file environmental artwork ZIP](https://drive.google.com/file/d/1JCWIr8Z354VxjDDNMZUO4-K_AMjsHe6T/view)
- [Crownsfall six-prop review](https://drive.google.com/file/d/1OZUsaFy0s6w_0mBOOFWg_BQ-_1XxYh0g/view)
- ZIP size 18,304,385 bytes; SHA256 613d98348d1fe35da09d80760a563bd08f8d1e0820c83cb1f03a1bc42271a23b. ZIP CRC validated before upload.
- Six transparent RGBA props: royal_banner, street_lantern, flower_planter, merchant_stall, noticeboard, cargo_cluster. Source sheet and extraction script, per-file SHA256 manifest, 12 RGB 1024px terrain candidates with procedural generator and checksums, four-biome concept artwork, canonical 105-zone registry, review images.
- Binary assets are hosted on Drive; this repository document indexes the exact package. Not an assertion that the binaries are committed to Git.
- No paid generation credits spent.

## Integration contract
Use approved 31-degree camera, existing plaza painting and depth, unchanged runtime keys and saves. Manual contact anchor, collision footprint, local visual review, separate shadow and occlusion calibration required. The wall-mounted banner must not become a freestanding collider. Check new heraldry against approved original. Ensure NPCs, waypoint and portal remain reachable; avoid duplicate baked props. Terrain tiles are for later zones, not authorization to advance. Do not merge into gameplay without real Godot screenshots and traversal/quest/save regression.

Status: six prop candidates extracted and visually inspected on slate; original sheet preserved; texture hashes validated. Not integrated, not approved, no engine execution. Crownsfall remains the only active zone.