# Actor feedback development cycle — November 12, 2026

The approved framed skill icons remain the action-bar standard. This cycle resumes the next code priority: readable character damage, charge and death feedback. Open `project.godot` with Godot 4.6.3 after fetching Git LFS assets.

## Behavior

- Warrior and Mage receive a short recoil and warm hit tint only when health actually decreases. Ward absorption and invulnerability do not create false health-hit reactions.
- A presentation-only parent pivot keeps the existing walk, swing and cast frames intact. Recoil does not change position, navigation, collision, pending attacks, mana or cast timing.
- Shield Charge adds a forward lean during its existing dash. No new dodge ability or invulnerability window is introduced.
- Death takes priority over movement, charge, swing and cast presentation. The actor settles into a dimmed fallen silhouette over 0.45 seconds. The death dialog and respawn action remain available.
- Respawn restores pivot, tint, scale, shadow and idle animation immediately, alongside the existing full resources and two-second grace period.
- Enemies recoil away from actual hits. Slimes flatten; revenants and brutes fall sideways over 0.42 seconds, then finish the existing one-second fade. Death suppresses warning wedges, strike arcs and elite glow; corpses no longer bob or lunge.
- Combat targeting and reward removal still occur immediately at death, with duplicate kill calls unable to duplicate rewards. Save schema remains six; presentation timers are transient.

These are procedural poses of the existing paintings, not newly authored directional hurt/death sprite sheets. Equipment remains baked into character artwork. Dedicated directional animation and equipment-appearance work remain future tasks.

## Verification

`python3 tools/run_checks.py --report-dir /tmp/aotl-feedback-qa` runs sixteen suites using isolated Linux XDG directories. This cycle passed **954/954 assertions**: the previous 900 plus 54 actor-feedback checks. The same 54-check suite also passed in the native renderer. Repeated assertions are not added to the distinct total.

Reports are in `tests/actor_feedback_qa/`. The tests drive actual damage, ward, invulnerability, swing callbacks, mage windup, lethal damage, respawn, pause, enemy windup, kills and corpse cleanup. Existing inventory-grid, equipment, town, loot, mastery, encounters, navigation, artwork and save suites also pass. Earlier extra native inventory-drag checks are historical; they were not rerun in this cycle.

Native review captures live in `previews/actor_feedback/`. For pose inspection only, the test temporarily hides the death modal, floating text and particles while taking a screenshot, then restores them. The production death modal is unchanged. These captures are deterministic fixture scenes, not a claim of human combat playtesting.

Validated on Godot 4.6.3 Linux, X11/Xvfb, software OpenGL and Dummy audio. Windows export, target-hardware performance and human difficulty assessment remain unverified.

## Voice scope and continuation

The user selected **Grady**. Voice work is limited to selected NPCs and enemies; full character voice-over is not needed. A 4.36-second ElevenLabs audition is preserved under repository `audio/voice_auditions/2026-11-12/`, with provider/job/voice metadata and a private Drive copy. It is an unintegrated tone reference, not canonical dialogue. It decoded successfully; listening/performance approval is still outstanding.

No money or credits were spent. Any future generation must remain free: confirm model eligibility and a zero-credit preflight, use the existing unlimited allowance explicitly, and never fall back to credits. The current allowance expires November 13, 2026 at 19:43:34 UTC.

Next useful work: human combat/readability playtest and Windows export validation; then a small selected NPC/enemy dialogue set with subtitles, independent volume, interruption and repeat rules. Dedicated directional actor animation and gear appearance remain subsequent art/animation work. Preserve the approved icon style and existing item footprints.
