# Mage equipment candidate review and disposition

## Outcome
Retain the current default staff, wraps and slippers. The four candidate assets are useful variant artwork, but matching dimensions alone does not make them correct replacements for existing item identities. No production selection changed and no generation credits were spent.

## Visual comparison
Actual PNG bytes were composed in Chromium with alpha at 24, 34 and 50 pixels per cell. Staff canvases retain 2x4 proportions and cloth pieces retain 2x2. The self-contained HTML has 21 images, all checked loaded; screenshot inspected. This is not a live inventory screenshot or owner art approval.

- Current Aurelian Staff is ornate gold/cobalt. Mystic staff has a clean crescent/crystal silhouette and remains readable at the smaller scale; recommend it for a separately named caster-staff variant.
- War staff is a practical capped shaft with a martial feel. Preserve as martial/quarterstaff-family concept only after a designer chooses its actual type and class role; do not silently remap the 2x4 artwork to the separate 1x4 quarterstaff definition.
- Current wraps depict wrapped forearms. The candidate is a pair of full fingered gloves. Keep current wraps; propose a separate cloth-glove identity.
- Current slippers are low footwear. The candidate is higher ankle-boot footwear. Keep slippers; propose a separate cloth-boot identity.

These conclusions refine the earlier equipment-batch proposals: footprint compatibility is technical eligibility, not semantic or aesthetic approval.

## Actual engine verification
Godot 4.6.3 runs the exact baseline art resolver in a standalone fixture. Mystic-staff/cloth-gloves/cloth-boots profile: 67/67 checks. War-staff/cloth-gloves/cloth-boots profile: 67/67 checks. Six additional result assertions confirm the intended three candidate paths in each run. These are repeated checks across two variants, not 134 distinct gameplay requirements.

The temporary glove-to-wraps and boot-to-slippers mappings exist only to test importer/texture/cache compatibility. They are explicitly not proposed production replacements. The packaged fixture ends on the war-staff test profile; stage_variant.py can select either variant. source_manifest.json describes the original baseline; review_overlay.json records the changed profile. Production game source, stats, saves and other developer branches were untouched.

## Sources and reproduction
Baseline ef263e4aab4e0e1c98e81cdf06ae9e76bc99b60b. manifest.json records exact catalog paths, LFS-verified SHA-256 values, image dimensions and alpha bounds. Every candidate decoded and matched its footprint aspect.

Open index.html for the portable review. The package includes original current/candidate PNGs, scripts, captures, complete fixture and logs. Run stage_variant.py FIXTURE_PATH mystic_staff (or war_staff), import the isolated fixture with Godot 4.6.3 and run engine_review.gd using writable isolated XDG directories. Never apply this fixture profile to the production project.

selection_decisions.json contains an empty production patch by design and explicit future item requirements. Next useful work: define separate variant item identities and validate their interaction with class restrictions, stat generation, inventory and save migration before adding them to loot pools. Amulet integration remains a separate, already-reviewed recommendation.
