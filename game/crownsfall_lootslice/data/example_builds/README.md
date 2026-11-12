# Deliberate demo builds

These three records were created by `tests/export_example_builds.gd` and passed the actual schema-4 save validator. They are authored examples, not a user's captured progress.

- `ward_level20.json`: Mage with Tempered Ward, before the aura transformation.
- `bloom_level40.json`: Pyromancer with Ember Aura, Cinder Bloom and an equipped Emberwake Circlet.
- `siphon_level40.json`: the same gear/path with the exclusive Siphon branch.

Each includes known gear ownership, a starter bag, 500 gold, a small merchant stock, the recovered stone memory and full resources. The level-40 records already consumed the once-only circlet attunement. Aura begins off and still requires activation/upkeep.

To try one, use a **project copy** with Custom User Dir Name changed to a separate demo namespace. Close the running game, locate that copy's user-data folder through Godot's **Project → Open User Data Folder**, and copy one record there as `crownsfall_encounter_v4.json`. Preserve any previous file first. Reopen the game, press M for the graph, K for the current aura tooltip and 3 for the default fourth-slot aura. Use T for the authored Cantor trial or R for the endless Scar. The trial carries in your current resources and gear. Cinder Bloom needs a burning target; equip Solar Writ or Cinderwake to apply a burn. The same JSON ownership rules apply to demo and ordinary saves.

The fixtures are separate alternatives, not automatically imported content. Rebuild only in isolated test data directories; the export script intentionally writes its temporary QA save before producing these records.
