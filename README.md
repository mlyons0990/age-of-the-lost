# Age of the Lost

A 2D isometric action RPG in the spirit of Diablo and Path of Exile, with painted
anime art inspired by Ragnarok Online and Octopath Traveler. Built in **Godot 4.3**
(GDScript), aimed at PC / Steam.

![Character and inventory panels](screenshots/godot_character_inventory.jpg)

## What's here

| Folder | Contents |
| --- | --- |
| `crownfall/` | The Godot project. Open `crownfall/project.godot` in Godot 4.3. |
| `crownfall/HANDOFF.md` | Full design and code guide: systems, files, testing, how the art was made. Start here. |
| `tools/` | Art pipeline scripts (green-screen keying, attack strip builder). |
| `crownfall/tools/` | Sound effect and music generators. |
| `screenshots/` | Captures from the automated test run. |
| `Higgsfield_Trial_Shot_List.md` | Planned animation shots for the art pipeline. |

## Controls

Click to move and attack · 1–4 skills · Q potion · C character · I inventory ·
K stash · P spellbook · J journal · E talk / Lorecast · R Reality Scar · Esc close.

## Testing

```
godot --path crownfall -- --autotest --shots=<folder>
```

Plays a scripted session and runs 110 checks (inventory, stash, merchant, stats,
Lorecasting, audio, save and load). See `crownfall/HANDOFF.md`.
