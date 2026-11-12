extends RefCounted
## The places the knight can be. Each zone is one painted background with a walkable
## outline (image pixels), props that draw in front of him, where he arrives, and a
## Waystone that links to another zone.
##
## "wild" zones spawn roaming packs on their own; the town (Crownsfall) is safe until
## the Reality Scar is opened there.

const ZONES := {
	"plaza": {
		"name": "Crownsfall",
		"tex": "res://assets/plaza.png",
		"walk": "main",            # main.gd's WALKABLE and OCCLUDERS (the original plaza)
		"start": Vector2(1350, 1020),
		"portal": Vector2(2060, 1400),
		"arrive": Vector2(1960, 1360),   # where you appear when coming back through the Waystone
		"to": "whisperwood",
		"music": "plaza",
		"wild": false,
	},
	"whisperwood": {
		"name": "Whisperwood Ruins",
		"tex": "res://assets/zones/whisperwood.png",   # Higgsfield GPT Image 2.6, art/higgsfield_trial #39
		"walk": [
			Vector2(700, 1240), Vector2(600, 1120), Vector2(660, 940), Vector2(780, 840), Vector2(790, 740),
			Vector2(860, 660), Vector2(960, 660), Vector2(1080, 600), Vector2(1200, 600), Vector2(1290, 560),
			Vector2(1380, 620), Vector2(1380, 670), Vector2(1680, 665), Vector2(1760, 600), Vector2(1880, 660),
			Vector2(1960, 760), Vector2(1990, 840), Vector2(1960, 900), Vector2(2000, 1000), Vector2(2300, 1000),
			Vector2(2400, 1040), Vector2(2360, 1120), Vector2(2200, 1200), Vector2(1960, 1200), Vector2(1920, 1180),
			Vector2(1700, 1180), Vector2(1600, 1220), Vector2(1520, 1280), Vector2(1440, 1280), Vector2(1280, 1280),
			Vector2(1120, 1320), Vector2(960, 1360), Vector2(840, 1440), Vector2(660, 1520), Vector2(460, 1520),
			Vector2(440, 1400), Vector2(520, 1300), Vector2(660, 1260),
		],
		"occluders": [],
		"start": Vector2(760, 1330),
		"portal": Vector2(560, 1430),
		"arrive": Vector2(760, 1330),
		"to": "plaza",
		"music": "scar",
		"wild": true,
		"pack_cap": 7,          # most enemies alive at once
		"pack_every": 5.0,      # seconds between packs when below the cap
		"level_bonus": 1,       # monsters here are a level above you
	},
}
