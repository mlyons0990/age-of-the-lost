> ARCHIVED SYSTEMS EXPANSION: the current Mage Slice handoff and README supersede implementation/status claims in this chapter.

# Source ledger and provenance

Audit date: November 11, 2026. Implementation claims are based on files inspected and tests run in this session. Prior user confirmations are historical reports, not repeated validation of their missing packages.

## Supplied files

| File | Bytes | Treatment |
|---|---|---|
| Optional_Personal_Memory_2026-11-10.md | 7,126 | Excluded: optional personal context or combined packet containing personal appendix. |
| Crownfall.zip | 15,984,744 | Inspected project source or game design context. |
| Crownfall-HANDOFF.md | 4,361 | Inspected project source or game design context. |
| Crownfall_Art_Update.zip | 21,441,099 | Inspected project source or game design context. |
| Age_of_the_Lost_Conversation_Handoff.txt | 19,773 | Inspected project source or game design context. |
| Age_of_the_Lost_AI_Handoff_2026-11-10.md | 56,120 | Inspected project source or game design context. |
| Age_of_the_Lost_Full_AI_Transfer_2026-11-10.docx | 70,176 | Excluded: optional personal context or combined packet containing personal appendix. |

Full SHA-256 values are in data/source_manifest.json. Both original project archives were extracted into separate working directories; new work was made in a third directory. Their originals were not changed. Original supplied import caches are excluded from the deliverable so Godot can regenerate them.

## Conflicts resolved for this isolated branch

| Conflict | Evidence | This delivery’s decision |
|---|---|---|
| Crownfall versus Crownsfall | ZIP/project identifiers use Crownfall; broader world notes use Crownsfall | Keep asset paths stable; use Crownsfall in new user-facing labels |
| 2D versus 3D | Both supplied ZIPs use Node2D, Sprite2D/AnimatedSprite2D and painted plaza.png | Improve the actual 2D source; document a 3D adapter path |
| Four versus thirteen starting classes | Larger handoff describes a four-class prototype but later thirteen-class design; current ZIP contains a knight only | Warrior playable, thirteen-class roster documented; no invented claim of four or thirteen working classes |
| 10/40/60 progression versus 20/40 | Art Update game_data defines Knight and automatic spec passives at 10; later handoff supersedes that design | New independent branch uses Warrior spec 20 and matching identity 40; no forced level-60 class passive |
| Fixed versus configurable skill bar | Original definitions assign abilities by slot; current request calls out missing spells/UI | Stable ID assignment and cooldowns in five slots |
| Auto-equip/auto-sell versus real inventory | Original pickup compares an item_score against four gear fields | Preserve all successfully collected items in a real bag; explicit equipment/sale actions |
| Named Legendary versus unique mechanics | Original item tier has names/stat multipliers; no bespoke effect resolver | Keep rarity tier honest; named unique/set effects supplied as future proposals |

## Referenced but not supplied

- Age_of_the_Lost_Combat_Impact_Pass.zip and larger Loop builds.
- Royal Wayfarer V5 motion project and V11 UV-textured/full Blender/GLB packages.
- Crownsfall Courtyard V2 3D rebuild and any actual Blender scenes.
- The six official canon images, best1(1).png and royal_wayfarer_character_sheet.png.
- Class Design Bible V3/V4 and full historical art libraries.

The handoffs describe 56 bones, 17 animation clips and prior user playtests. Those facts remain attributed historical context; none can be reverified from the attached 2D assets. The Art Update’s internal HANDOFF records a prior Linux/Godot 4.3 test; that is an attributed historical claim. The older external handoff’s Godot 4.3 instruction is also historical. The runtime available and used here is 4.6.3.

## Privacy scope

The optional personal-memory file is unrelated to this game-systems expansion and is not copied into the developer archive or expanded handoff. The original combined DOCX includes a personal appendix; it is omitted too. The new DOCX is generated from game-only material. Source manifests list filenames, sizes and hashes without redistributing private text.

## What source material does not establish

Beautiful paintings do not establish a game-ready model. GLB parsing does not establish animation quality. A successful editor import does not establish a playable Windows export. Automated engine captures do not establish manual playtest approval or target-PC performance. Data proposals do not establish playable abilities. Every new assertion should identify its source, test scope and remaining limits.
