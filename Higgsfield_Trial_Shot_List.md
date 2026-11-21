# Higgsfield shot list — use before the trial ends

**Deadline:** the Ultra trial ends **Nov 13, 19:43 UTC (2:43 PM Eastern)**.

**Where:** your **Claude chat with Higgsfield** (not Claude Code). Higgsfield
only allows free unlimited generations there; from Claude Code every
generation costs credits. At the start, tell that chat:

> Use my unlimited trial generations for everything below (use_unlim true). If a
> generation would cost credits, stop and tell me instead of spending them.

Work top to bottom; the list is in priority order. When done, download every
result (or note the generation IDs) and bring them back to Claude Code, which
will cut them out and put them in the game.

## How every clip must be made (so it can be turned into a sprite)

- Model **Seedance 2.0**, 4 seconds, aspect **3:4**, 720p, **audio off**.
- **Start image and end image = the same still** of the character (listed per
  item), so the clip loops back to the pose it started in.
- Add this to the end of every video prompt:
  > The character stays exactly centred at the same size and does not travel
  > across the frame. The camera is completely locked: no zoom, no pan, no
  > rotation. The background stays a perfectly flat, uniform solid green with no
  > shadows, no floor, no gradients, no slash trails, no glow and no effects. Keep
  > the same anime painted art style, costume and face in every frame.

Images: model **GPT Image 2.6**, on a **flat solid chroma green (#00B140)
background**, no floor, no shadow, no text, whole subject visible with margin.

## 1. Knight — sword swing for the facings that are missing (highest value)

Use the knight's standing still for that facing from the earlier Crownfall
work (front-facing "down", side-facing "right", back-facing "up").

1. Swing, facing **down** (toward the camera): "2D game sprite animation
   reference. The anime knight, standing in place facing toward the camera,
   performs ONE fast, powerful two-handed sword slash: winds the sword back,
   swings it in a wide horizontal arc in front of him with a strong step and
   torso twist, cape whipping, then recovers to exactly the starting pose and
   holds still. Only one swing."
2. Same, facing **right** (side profile).
3. Same, facing **up** (back to the camera).

## 2. Knight — reactions and moves (front diagonal + back diagonal each)

Use the lower-right still (`81db62f3-2f44-407e-a8f9-825fa85039c0`) and the
upper-right still (`510d0f44-c998-4d4c-a940-03cfa8795c66`).

4–5. **Hit reaction:** "staggers backward as if struck in the chest, flinches,
   then recovers to the starting pose."
6–7. **Dodge:** "does a quick sidestep dodge roll in place and comes back up to
   the starting pose."
8–9. **Spell cast:** "raises his free hand and the sword, channels power with a
   short wind-up, thrusts the hand forward, then returns to the starting pose."
10. **Death (lower-right only):** "is struck, drops to one knee, then collapses
    to the ground and lies still." (Use only the start image for this one, not
    an end image.)

## 3. Enemies — walk, attack, death

Start image = the enemy's still (generation IDs below). Facing lower-right.

| # | Enemy | Still (generation ID) |
| --- | --- | --- |
| 11–13 | Veilbound Revenant | `c8e43dfc-7c1e-48fe-9f63-b606080684f1` |
| 14–16 | Hollowling | `c2ea4055-0e71-4fd4-a2a8-692b8bf55827` |
| 17–19 | Thornhide Brute | `dca7d7fc-9c84-4b68-8486-bb15e33c3afc` |

For each enemy make three clips:
- **Walk in place:** "walks in place on the spot with a steady looping
  stride, as if on a treadmill."
- **Attack:** "performs ONE strong attack toward the lower-right (spear thrust /
  lunging claw swipe / two-fisted slam), then recovers to the starting pose."
- **Death:** "is struck, recoils, and collapses, dissolving into violet mist."
  (Start image only, no end image.)

20. **Merchant idle (Maren):** still `a91e0de1-c7a6-4f04-afbd-3b4feb79c36b`,
    "stands in place, gestures warmly with her free hand, glances at her ledger,
    breathes naturally." Start and end image the same.

## 4. Item icons (GPT Image 2.6, square 1:1)

One prompt each, all in the same style:
> "Single fantasy RPG inventory icon of a [ITEM], painted in a rich anime-fantasy
> style matching Ragnarok Online and Octopath Traveler, ivory, steel, royal blue
> and gold palette, centred, three-quarter view, clean silhouette, flat solid
> chroma green background, no text, no border."

21. longsword · 22. greatsword · 23. kite shield · 24. tower shield ·
25. great helm · 26. barbute · 27. plate cuirass · 28. chainmail ·
29. gauntlets · 30. war belt · 31. greaves · 32. ring · 33. amulet ·
34. health potion · 35. gold coins

## 5. If there's time left

36. Ornate black-and-gold UI panel frame with empty dark centre (16:9).
37. Health orb frame and mana orb frame, bronze and gold filigree (1:1 each).
38. Three new enemies for a forest zone, same sprite rules as above
    (non-human: a root-and-bone stag, a void-glass wolf, a lantern-headed
    wraith).
39. A painted forest-ruin zone background in the same isometric camera and
    style as the Crownsfall plaza (16:9), no characters, no UI.

## Bringing it back

Download the files (or copy their generation IDs) and send them in Claude Code.
It will key the green screen, cut animation strips, and wire them into the
Godot project.
