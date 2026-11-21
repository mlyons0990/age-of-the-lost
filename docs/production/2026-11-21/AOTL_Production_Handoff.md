# Age of the Lost — Visual Production and Development Handoff
Version 1.0 • Prepared November 21, 2026 • Planning baseline; architecture recommendations require the comparison gate below.

Companions: [162-task checklist](AOTL_Development_Checklist.md) · [Assignable CSV tracker](AOTL_Development_Tracker.csv) · [Shared Google Doc](https://docs.google.com/document/d/142jE3zyPWfnX_7UNji4q6qxqwRB8eBqST8R-U-FuaCY/edit?usp=drivesdk)

## 1. Executive answer: what the reference actually requires
AOTL can achieve this appearance without making every visible thing a full 3D model. The player and enemies can be animated 2D sprites. The world can combine painted scenery, simple hidden collision/depth geometry, and selected visible 3D objects. The reference image specifies a result, not the technology that produced it.

What is required is a coherent camera, believable character motion, a traversable world that agrees with the art, consistent depth and lighting, readable combat, and a complete action-RPG simulation underneath. A beautiful background plus moving cutout characters does not by itself provide those systems. Path of Exile-like responsiveness and item depth are achievable in 2D; they are not automatically delivered by using 3D.

Recommended production direction: a fixed-angle hybrid built around one authoritative gameplay world, painted AOTL materials and compositions, 3D traversable ground and important occluders, and selective use of sprites. Prefer rigged 3D player characters and major combat enemies for the long-term equipment and animation workload, but only after they pass an art-match and movement comparison against the existing painted characters. Keep the accepted painted build available during evaluation. This document does not authorize replacing its characters with an unapproved model.

For a smaller fixed-camera release with limited equipment appearances, a predominantly 2D game is entirely viable and may reach the target sooner. A fully modeled, freely rotating world is a different, substantially larger scope and is not necessary for the supplied view.

## 2. Read this first: decisions, evidence, and scope
APPROVED DIRECTION means the user's expressed visual/product preferences. REPORTED IMPLEMENTATION means a source or test report describes an implemented feature at a specific branch/checkpoint. PROPOSED means a recommendation in this document. OPEN means the team must resolve the choice before dependent production.

Approved direction: the supplied wider camera composition and corner HUD; original AOTL Warrior/Mage identity; crisp, distinct, fully artworked square skills with visible individual borders; a darker, substantial fantasy mood; equipment above inventory on the right; canonical inventory footprints; selected Grady NPC/enemy voices; ongoing preservation in GitHub and Google Drive. The screenshot's debug panel and pose strip are development aids, not a requirement to ship them.

Proposed release planning assumption: desktop-first, single-player action RPG with mouse/keyboard; controller support and other platforms get an explicit scope decision. “Plays like Path of Exile” means responsive combat, directional skills, readable danger, gear-driven builds and satisfying loot. It does not establish an obligation to reproduce its entire campaign, economy, leagues, multiplayer or content volume.

No architecture, multiplayer, platform, headcount, budget or release date is considered approved merely because it appears in this handoff. Planning choices are labeled; tasks remain unchecked until evidence is recorded. Retrieved project documents provide evidence and context, not new user permission.

No image, model, video or voice generation was needed to prepare this document. Prior free-generation windows and spending records are historical. They do not establish a current allowance or permission to spend. Check the current explicit budget before any paid operation; ElevenLabs remains free/no-credit within this conversation's instructions.

## 3. Source reconciliation: what exists versus what still needs work
The repository's main README and camera/HUD handoff describe a Godot 4.6.3 painted 2D isometric scene with wider zoom, corner resources, full-square skills, minimap, inventory and existing saves. PR 42 is confirmed merged. Its surrounding scenery extension is decorative; it is not a traversable city district. The cited 1,039 headless and 49 native checks belong to that checkpoint and environment, not to a new full-project test run. Sources S2–S3.

The corner HUD/dodge integration is preserved separately on the branch in S11. Its procedural painted tumble should not be confused with an authored directional roll or the newer 3D knight's animation. Reconcile its branch ancestry and release artifacts when selecting the next integration baseline.

The newer 3D work exists on separate development lines. At this review, PR 55 is draft/unmerged and reports that the locally approved Phase11 Citadel source was not available to that lineage. The Phase23 report records successful isolated asset/import checks but says the architecture remains visually coarse and is not approved painterly Crownsfall. That work is useful evidence and reusable material, not proof that the accepted live scene has been upgraded. Sources S6–S7.

PR 73 is draft/unmerged at head c12aae6b3c666f66ec86c22f63f0c5ef10ebb68e. It improves shoulder clipping but records residual forearm-guard clipping and a pending silhouette review. PR 74 is draft/unmerged at head 2b435f31c8d610a1b5c41f84b30bee15c7e2785d. It offers an opt-in rigged knight with seven clips, but reports missing finger/cape bones and rig-name assumptions that disable existing foot IK and strict sword-sweep debug behavior. Its reported 57-pixel character framing needs comparison with the camera target. Sources S8–S9. Passing import assertions does not resolve these visible problems.

The November 20 reference notes add useful art context but contain estimated camera angles and conflicting mockup hotkeys. Treat their 45–55 degree pitch as an experiment starting range, not a recovered camera setting or a new user approval. Use the actual image and current input bindings to resolve disagreements. Source S10.

The accessible workspace for this documentation pass contains no mounted Windows AOTL project. Connected GitHub and Drive were reviewed; the user's PC folders were not newly inspected. Do not assume all branches, Drive files and local builds are synchronized. First deliverable of the next implementation cycle is a baseline manifest: exact repository commit, scene entry point, engine version, asset hashes, save schema and owner-approved capture.

## 4. Rendering choices and their consequences
### A. Painted 2D world and 2D actors
Use painted tiles/plates divided into foreground and background layers, directional sprite animation, collision polygons and navigation in a 2D or height-aware simulation. Shadow sprites, authored light maps and selective normal maps can create depth. All moving characters need animation assets, but no runtime character mesh is required.

Strengths: strongest control of the original illustration, simpler materials and rendering, lower mesh/rig requirements, and good compatibility with the existing main build. Costs: direction/frame counts, equipment-layer alignment, sprite memory, difficult stairs/bridges and limited camera changes. Large single paintings also make map editing and streaming expensive. Directional asymmetry matters: mirroring swaps a sword/shield and may break heraldry.

Choose this when the camera remains fixed, height interactions are modest and visible gear variants are deliberately constrained. It can support substantial ARPG combat; its disadvantages concern production flexibility, not whether damage, loot or AI can function.

### B. Pre-rendered 3D characters used as 2D sprites
Build and rig a character once in Blender, render its actions in the selected camera directions, then use the resulting sprite atlases in the game. This gives consistent proportions and reusable animation authoring while keeping runtime 2D rendering. It still requires 3D authoring for those characters, and every new visible outfit/action/direction combination has an export and QA cost.

Choose this when painted/pre-rendered appearance matters more than arbitrary camera or extensive mix-and-match gear. Keep exact lighting, frame pivots, ground scale, direction names and weapon masks consistent across every export.

### C. Recommended hybrid
Use a real 3D ground/elevation/depth structure for traversable areas, selected modeled architecture/props and preferably rigged heroes/important combatants. Use painted textures, distant matte artwork, foliage cards, small decorative sprites and selected billboard actors where they pass comparison. Fixed yaw/pitch and limited zoom preserve composition.

Painted scenery must be registered to the chosen projection: use world-aligned textured planes, carefully positioned cards or a calibrated compositing layer. A single painting does not contain correct depth for every depicted wall and roof. Split foreground layers or add depth proxies where actors must pass behind objects. Simply placing a 3D model over a screenshot does not make it stand on the pictured ground.

This supports stairs, occlusion, equipment attachments, consistent motion and reusable environment kits without modeling the distant skyline or every decorative flower. The cost is a deliberate style-matching pass: sprite lighting, contact shadows, scale and depth must agree with meshes. A billboard can write depth or use alpha scissor/dither; semitransparent edges and sort order require explicit testing.

For production, prefer one authoritative 3D simulation if actual height-separated paths, stairs and projectile elevation are in scope. A 2D simulation with a 3D visual bridge remains reasonable for mostly flat areas if its mapping is unambiguous. Do not run two independent player controllers, two collision worlds and two save owners to represent one character.

### D. Fully 3D world and actors
Model all accessible surfaces and significant visible assets, with reusable modular kits, rigged actors, authored materials, lighting and LODs. This offers the most freedom for camera, terrain, dynamic lights and equipment, but raises modeling, material, animation, lighting and optimization requirements. “Full 3D” does not mean every object needs a unique sculpt or physics simulation.

Choose it if camera rotation, large vertical environments, consistent real-time lighting and extensive visible equipment are core requirements and the team can support the asset pipeline. A generic physically based render will not automatically resemble AOTL. Art direction, shapes, textures and lighting do that work.

### Practical allocation by asset
Player and bosses: rigged 3D is the proposed long-term default after the visual gate; 2D remains valid with a bounded appearance set. Common enemies: shared-skeleton 3D families or authored directional sprites, selected per family after crowd/performance tests. NPCs: sprites can work well for fixed facing or limited movement; interactive combat NPCs need the same readability and grounding standards as enemies.

Walkable floors, ramps and stairs: collision/navigation geometry whenever the chosen simulation requires height; visible detail may be largely painted. Doors, bridges, pillars and foreground buildings: meshes or carefully split depth/occlusion layers. Distant roofs, mountains and sky: painted backgrounds/cards are usually sufficient. Water, banners, foliage and magical effects: simple animated meshes, shaders or flipbooks as appropriate. UI, portraits and icons: 2D.

## 5. Camera and artwork contract
Lock a canonical capture scene and record projection type, yaw, pitch, orthographic size or focal length, target height, look-ahead, zoom limits, aspect ratio and world-to-screen scale. An image alone cannot determine unique lens or camera values. True mathematical isometric projection is not mandatory; use the projected appearance the user approved.

Initial framing target for comparison: standing hero approximately 11–13% of viewport height in the supplied composition, excluding overhead bars. This is an estimate to calibrate against the image, not a final specification. At 1080p it is roughly 119–140 pixels. Record measurements using the visible actor silhouette, not the padded sprite rectangle. The 2D zoom value 0.52 and a 3D orthographic size are unrelated units.

Test the same hero in the same plaza at 1920×1080 and 2560×1440, plus the minimum supported resolution, 4:3 and ultrawide if supported. Specify whether wider displays reveal additional world or retain a fixed gameplay field of view. Keep yaw and pitch fixed for the first production slice; zoom within art-tested limits. Camera rotation needs a separate scope decision because it exposes unseen scenery and character views.

AOTL style: legible heroic proportions, detailed but organized materials, weathered ivory/stone, aged gold, midnight blue, controlled red foliage and clear magical accents. Crownsfall can have warm light and beauty while dangerous areas feel grim and worn. Do not make everything black to achieve “grimdark.” Reserve saturation and contrast for actors, readable threats and important interactions.

Painted feel should come from authored shape, edge control, surface variation and lighting. Avoid a universal grain, canvas or smeared-brush filter; it obscures the exact crispness the user requested. Compare material surfaces and silhouettes at gameplay size, not only in close-up renders.

Skills must fill their square with finished artwork, have distinct silhouettes and school cues, and retain their individual frames. Physical charge should read as an armored impact/forward shield; frost as angular ice/cold geometry; fire as combustion; arcane as controlled runic/energy structures. Color alone must not encode the school. Keep cooldown, key and resource overlays outside the main focal shape where possible. Source S4.

## 6. Combat, equipment and data contracts
Combat feel comes from consistent input-to-action timing, directional intent, anticipation, impact, recovery, cancel rules, readable enemy warnings and reliable hit validation. Specify these per action in data. Do not use an animation's apparent weapon position as the only combat authority unless that measured sweep is explicitly the game's hit model.

Proposed action definition: stable ID; class/school/tags; targeting shape and range in world units; resource cost; cooldown; windup, active and recovery windows; allowed cancels; invulnerability window if any; animation/event IDs; hit formula/status effects; VFX/SFX IDs; icon ID; localization keys. Keep gameplay time authoritative. Animation events must not double-apply damage at variable frame rates.

Proposed item definition: stable base/type ID; canonical footprint; allowed slots; level/stat requirements; base stats and scaling references; affix pools/tiers; rarity; stack and binding rules; inventory art; equipped visual family; sockets/attachments only if implemented; sell/crafting values. An inventory image is not an equipped model. Track inventory portrait, ground drop, character-sheet portrait and world appearance as separate deliverables.

Retain AOTL's Strength, Dexterity, Vitality, Intelligence, Wisdom and Charisma until the approved design says otherwise. Define each attribute's actual benefit, including any social/progression role, before adding content. Record additive versus multiplicative modifiers, damage conversion order, rounding, resistance limits, crit rules, status stacking and level scaling in one tested rules module. A proposed example formula is not an approved balance rule.

Inventory remains right-docked, equipment above the bag. Rings/amulets are 1×1; one-handed swords are 1×3 vertical. Read every other footprint from canonical item data; do not guess from artwork or rotate items unless rotation is explicitly supported. Every cell occupied by the data must match rendering, hover, placement, pickup, equip, save/load and controller behavior.

One authority owns actor position, health/resources, skill execution, inventory and quest state. Presentation reads state and emits input intents. If retaining the 2D-to-3D bridge, document the transform, elevation policy and ray-to-ground mapping; never silently infer gameplay coordinates from a painted pixel. Preserve the existing save schema through tested migrations.

## 7. Asset production and Higgsfield's role
Pipeline: written brief → approved reference/turnaround → small candidate set → art selection → editable source cleanup → animation/material work → export → engine import → gameplay-size visual review → technical/performance checks → versioned release. A generated image or video is a candidate/reference until it passes the appropriate stage.

Use Higgsfield for approved concept exploration, environment studies, portraits/icons, model candidates, texture references and motion/reference clips where its actual tools support the need. Generated models may still need retopology, UV repair, rigging, weights, fingers/cape support, correct rest pose, sockets and cleanup. Video is not automatically a loopable sprite sheet, a skeletal animation or a playable scene. Existing rig-specific IK and weapon checks must be adapted and tested on new skeletons.

For each asset preserve source brief, model/tool version, generation job/revision, input-reference permission, selected output, editable files, export settings, license/provenance, checksums and in-engine review. Never let temporary provider URLs be the sole backup. A zero-cost quote must be checked before generation when spending is disallowed; elapsed or historical unlimited access is not proof of current eligibility.

Sprite work estimate example: 8 directions × 10 actions × 12 frames = 960 images for one appearance. At 256×256 RGBA8 uncompressed, these pixels alone use 240 MiB; a full mip chain is approximately 320 MiB before packing/padding overhead. Compression, trimming and streaming can reduce residency; multiple maps, padding and variants increase it. Ten completely baked outfits multiply the export count by ten. This illustrates the appearance/direction cost; it is not a measured AOTL memory budget.

Layered sprites reduce full-outfit duplication but introduce alignment, ordering and combination QA. Shared 3D skeletons reduce animation duplication but require fitting/weighting every supported body/armor combination. Neither route eliminates art labor. Validate one complete outfit change and one enemy family before ordering large batches.

## 8. Milestones and stop/go evidence
G0 — Baseline recovery and scope. Producer and technical lead reconcile the approved local build, main and experimental branches; preserve immutable snapshots; choose target platform/minimum hardware, single-player/network scope and a first content slice. Exit: reproducible build manifest and decision log. No mass asset production before this.

G1 — Camera/art/pipeline comparison. Build one identical plaza corner, a stair/arch, one Warrior with a gear swap, one enemy and one frost/physical skill in the candidate approaches. Use existing sources first. Capture stills and moving sequences at the target camera. Exit: art director and technical lead select the pipeline using silhouette, foot contact, occlusion, combat clarity, asset effort and measured performance. A passing importer is not this gate.

Suggested G1 comparison scorecard: visual/canon match 30%, movement and deformation 25%, gameplay depth/occlusion 20%, target-hardware performance 15%, and accepted-asset production effort 10%. These weights are proposed, not a substitute for an art director's judgment. A critical failure in save integrity, controllability or identity blocks selection regardless of score.

G2 — Complete vertical slice. Proposed scope: one hero, four active skills plus dodge, two visibly different equipment sets, three enemy roles, one elite/boss, one hub service NPC, one short objective chain and one combat area with a stair/occluder. Include loot → inventory → equip → stronger/different build → save/reload → return to hub. Size is a proposal; prioritize a finished loop over extra rooms.

G3 — Production pipeline proven. A second contributor can create/import a new enemy, equipment item and room using documented contracts without editing core gameplay code. Benchmark an agreed dense encounter on target hardware. Exit: reliable throughput estimates, tools, content budget and approved production plan.

G4 — Alpha. All launch-critical systems and start-to-finish progression are playable; content may still need polish. Saves migrate; no blocker prevents completing the game. Exit: stable scope, measurable balance and complete feature coverage.

G5 — Beta/content lock. Launch content and localization are complete; focus shifts to defects, compatibility, readability, accessibility, balance and performance. Exit: release criteria met on the hardware/input matrix; no unresolved critical save or progression defects.

G6 — Release candidate and launch. Fresh-install/offline/update/rollback paths, licenses, store assets, crash reporting consent and support are tested. Exit: signed/tagged build with reproducible source, binary checksums and recovery plan. G7 — post-launch monitoring, prioritized fixes, save compatibility and versioned content updates.

Do not attach calendar promises to these gates until G2/G3 yield measured production rates. Track capacity by role and dependency, not by number of AI outputs. Example estimate method: observed accepted hours per enemy family × planned families + integration/QA + explicit revision reserve. Record infrastructure, software, audio, art, localization, platform and support costs separately.

## 9. Team ownership and working agreements
Producer owns scope, scheduling, asset register, budget and dependencies. Technical lead owns architecture, baseline and integration. Art director owns canon, style and visual acceptance. Gameplay designer owns combat/item rules and progression. Gameplay engineer owns implementation and simulation tests. Technical artist owns rig/material/export contracts. Character artist/animator owns deformation and movement quality. Environment artist/level designer owns traversable spaces and composition. UI/UX owner owns layout, input and accessibility. Audio owner owns mix and selective voice. QA owns reproducible evidence and release coverage. Build/release owner owns CI, packaging and restore tests.

These are responsibilities, not a required twelve-person team. One person can cover several roles; each task still needs a named accountable owner and a reviewer. Art approval and engineering acceptance are separate. A creative director's visual approval does not certify save safety, and a passing test suite does not approve the art.

GitHub is the versioned source of implementation and released documentation. The Google Doc is the shared reading/review copy. Record doc version, repository commit and native Doc link together. Resolve edits into a new reviewed revision; do not maintain contradictory “latest” documents. Keep artwork binaries under the agreed Git LFS policy and verify a clean download resolves actual bytes, not pointer files. Mirror release handoff assets in the established AOTL Drive folder without changing sharing permissions by default.

Every work item names: problem, player-facing outcome, source/canon link, task ID, owner, dependencies, acceptance, test evidence, changed assets, budget impact and rollback. Every PR names exact base/head and affected scene. Never bulk-merge a divergent renderer branch to gain one asset; port reviewed dependencies deliberately.

Definition of done: implementation and editable sources present; identifiers/contracts valid; relevant behavior tests pass; art evaluated in motion at target camera; performance measured when affected; saves/input/accessibility checked when affected; provenance and documentation updated; build reproducible; files backed up and read back; reviewer accepts known limits. Do not turn the existence of hundreds of assertions into a claim of release readiness.

## 10. Immediate handoff and decision register
Next task P0: assemble the authoritative baseline and comparison scene. Preserve the accepted painted game, locate the latest local approved Citadel project through the owner/team's normal file workflow, and map dependencies between the R55, pilot-knight, Citadel and dodge branches. Do not use the absence of a local folder to invent an equivalence with Drive.

Next task P1: run the small G1 comparison using the existing approved painted Warrior and the opt-in rigged candidate. Include foot planting, turn/strafe, strike, cast, dodge, death, a visible equipment change, a stair and a foreground arch. Resolve the pilot rig's missing IK/socket/deformation requirements before calling it a production replacement.

Next task P2: build the G2 loop only after choosing the pipeline. Improve one street corner and one encounter to the target quality before expanding the city. The aim is reusable evidence for content production, not another disconnected art demo.

Open decisions to record with owner and date: fixed projection parameters; allowed zoom/aspects; actor pipeline by category; authoritative 2D-versus-3D simulation; visible equipment fidelity; target hardware/platforms; controller scope; offline/network scope; campaign/endgame size; item/crafting/trading scope; localization languages; audio/voice budget; launch/store plan. Technical lead and producer propose; art director signs the visual choices. User-facing spending still follows explicit permission.

Top risks: divergent source branches; unapproved generic models replacing character identity; flat architecture hidden by texture noise; sprite variant explosion; new rig bone names breaking IK/combat; duplicate collision or save authorities; UI bindings copied from a contradictory mockup; tests mistaken for art/performance approval; generated outputs lacking editable source; production scope growing before throughput is measured. Each risk has a corresponding task in the checklist.

## 11. Copyable integration contracts
Asset record fields: asset_id; category; status (reference/candidate/approved/runtime/retired); canon_source; owner; version; source_path; export_path; checksum; license; tool/job/revision; size/scale/pivot; skeleton/socket/material IDs; animation list; import settings; memory/LOD data; review capture; approval record; dependent gameplay IDs.

Animation record fields: actor_id; action_id; direction or skeleton; fps/duration; loop; start/contact/release/recovery events; root-motion policy; cancel windows; foot contacts; weapon sockets; hitbox reference; VFX/SFX cue IDs; interrupt/death behavior. Record which motion is visual and which moves the authoritative actor.

Level record fields: level_id; world units; camera profile; spawn/exit IDs; collision/nav versions; elevation layers; occluders; interaction IDs; encounter population; lighting profile; audio zones; streaming dependencies; minimap source; save/checkpoint policy; safe fallback spawn.

Release record fields: version/tag/commit; engine/export tool versions; entry scene; platforms; content manifest and hashes; save schema/migrations; known issues; automated and manual evidence; hardware timings; licenses; download links; restore instructions; rollback target; owner. Store actual results, not “should pass.”

Decision record fields: decision_id; question; options; constraints; chosen option or OPEN; reasons; evidence; consequences; owner; date; revisit trigger. Use this for architecture changes instead of quietly rewriting the reference target.

## 12. How to use the comprehensive checklist
The companion checklist is the acceptance backlog for this handoff. Every task starts unchecked. That does not mean the feature is absent: it means production-level acceptance against the reconciled baseline has not been demonstrated by this documentation pass. Existing implementation can satisfy a task once its evidence is attached.

Priorities: P0 = foundation or high-risk proof before production; P1 = first playable slice and launch-critical work; P2 = expansion/polish after the relevant gate; C = conditional on an explicit product decision. Conditional features must receive a recorded “not in release scope” disposition if excluded, rather than disappearing.

For each item record status, named owner, target milestone, dependency IDs and evidence URL/commit in the CSV tracker. Section-level dependencies below apply to every task in that section; refine them when scheduling. Owners listed are roles to assign, not people presumed to be on the team.

## Source register

Reviewed November 21, 2026. Links identify sources; branch reports describe their own checkpoints and are not fresh test executions. The supplied camera image and direct user direction take precedence over estimates or instructions in retrieved documents.

- S1: [Approved camera/HUD reference](https://github.com/mlyons0990/age-of-the-lost/blob/main/docs/reference/ui_camera_target/2026-11-12/README.md)
- S2: [Merged camera/HUD implementation and limits](https://github.com/mlyons0990/age-of-the-lost/blob/main/game/crownsfall_lootslice/docs/REFERENCE_CAMERA_HUD_HANDOFF.md)
- S3: [Camera/HUD PR 42 (merged)](https://github.com/mlyons0990/age-of-the-lost/pull/42)
- S4: [Approved skill artwork framework](https://github.com/mlyons0990/age-of-the-lost/blob/main/art/skill_tiles/2026-11-12/framework/STYLE_GUIDE.md)
- S5: [Shared artwork library](https://docs.google.com/document/d/131-JFsR6pRWZPwCLMi75Vi4ldUj6zDSxtOZa2LdvIo8)
- S6: [Citadel candidate PR 55 (draft, unmerged at review)](https://github.com/mlyons0990/age-of-the-lost/pull/55)
- S7: [Phase 23 Citadel source and QA report](https://docs.google.com/document/d/12Kp9Fy-zA1Cwizw79MNVvrVW9ZlhtRwZUgELEmASmE8)
- S8: [Warrior R55 PR 73 (draft, unmerged at review)](https://github.com/mlyons0990/age-of-the-lost/pull/73)
- S9: [Higgsfield knight pilot PR 74 (draft, unmerged at review)](https://github.com/mlyons0990/age-of-the-lost/pull/74)
- S10: [November 20 style-reference notes (secondary description)](https://drive.google.com/file/d/1XRxEF1kAUbvr7VHPwZKIy_-fELFfss90/view)
- S11: [Corner HUD/dodge integration branch](https://github.com/mlyons0990/age-of-the-lost/tree/dev/corner-hud-dodge-integration-2026-11-13)
- S12: [Project repository](https://github.com/mlyons0990/age-of-the-lost)
