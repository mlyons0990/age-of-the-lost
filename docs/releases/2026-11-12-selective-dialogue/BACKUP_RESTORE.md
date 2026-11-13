# Complete project backups

All completed source is preserved in GitHub. Google Drive also holds actual asset bytes; restoring these archives does not require Git LFS.

The actor-feedback baseline is preserved in two archives. Extract both into the same directory to recover the complete original project, including review images:

- [Actor-feedback source and assets](https://drive.google.com/file/d/1Bc_SudGkdC5xmJWzEc2tdDOf0SlE4TgW/view): 89,925,389 bytes, 550 payload files. SHA-256 `ab97f2641d8f5cca6874e3c08e3430b6cae152d64572927c922cd38eb31ff14e`.
- [Original preview images](https://drive.google.com/file/d/1vC108ROuqezrT7s5M2avsKWNCPDHI7U9/view): 74,740,345 bytes, 68 payload files. SHA-256 `4b3b673cf5961f9a4f84049e6416bd915eaec07b2f1254426922b572fe1f790d`.

Every archive passed CRC and payload hash checks before upload. Drive metadata confirmed the exact byte counts, download access and private sharing. The second archive's earlier interrupted upload had no stored file; the resumed upload above completed and was verified. Its temporary local ZIP was removed only after verification to reclaim disk space; source files and hash manifests remain intact.

Open `game/crownsfall_lootslice/project.godot` in Godot 4.6.3. These are source projects, not Windows executables. Current selective-dialogue source and review links are listed in this release's README. The original preview archive can be reused with the newer source; the newer source contains its own additional dialogue screenshots.

The larger artwork libraries and approved skill framework remain in the AOTL Drive folder and repository `art/`. The shared editable index is [the AOTL Google Doc](https://docs.google.com/document/d/131-JFsR6pRWZPwCLMi75Vi4ldUj6zDSxtOZa2LdvIo8).
