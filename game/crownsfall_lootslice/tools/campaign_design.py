"""Per-zone design for the seven-act campaign (docs/AOTL_Seven_Act_Narrative_and_World_Design_Bible.docx).

The bible's register (data/campaign_zones.json: ids, names, quests, looks) is the canon; this file adds what a zone
needs to be built as a playable framework: layout kind, biome, points of interest, the quest mechanic, NPCs, the
local enemy family and bosses. tools/campaign_build.py turns it into zone maps, encounters, quests, NPCs and the
world map. Art is a later pass (owner 11-28): every zone runs greybox on the forest kit with its own biome grade.

kind: fixed (hand-built map) | wild | town | dungeon | between | arena
mech: ("talk", npc) | ("collect", item, [guardian names]) | ("boss", boss name, art) | ("arrive",)
      a mech with turnin=npc is handed in to that NPC; otherwise it completes on the spot ("auto")
foes: three (name, art, tint) families: art = revenant | slime | brute (painted base art until each has its own)
"""

R, S, B = "revenant", "slime", "brute"

# ---------------------------------------------------------------- Act I: The Lost Reach — The Crown That Remembers (levels 1-10)
# Owner 11-28 ("merge both"): the main route is the reconciled Environment Art Bible (Act I, image): the 15 developed
# environments, with the narrative bible's beats folded in (Captain Ralden working with Mira Thorne; courier + archive
# pages; Silverroot Grove as the Lorecasting echo site; Cathedral of the Nameless reached through the Sunken Chapel;
# Caldrin's reveal; the First Anchor Chamber inside the First Rift as the finale). The bible's other Act I zones
# (Production Pack v2) stay as optional side areas with their own bible quests. Main-route entries carry "order";
# zones not in the bible register carry their own name / quest fields ("R" = reconciled).
def RZ(name, qid, qname, qtext, look, reveal, state="PRESENT"):
    return dict(name=name, quest=qid, quest_name=qname, quest_text=qtext, look=look, reveal=reveal, state=state)

ACT1 = {
 # ---- main route
 "ACT01_Z01": dict(key="crownsfall", kind="fixed", order=1, mech=("talk", "mira"),
   npcs=[("mira", "Mira Thorne", "mage", (0.82, 0.84, 1.0), "Archivist of Crownsfall. 'Records do not lie, people do. Lately I am not sure which is which.'", False, 7188, 3272),
         ("ralden", "Captain Ralden", "knight", (0.82, 0.86, 1.0), "Captain of the city watch. 'Mira finds the questions. I keep the people who ask them alive.'", False, 7111, 3140),
         ("quartermaster", "Quartermaster Ysolde", "mage", (1.0, 0.92, 0.85), "Coin for steel, steel for coin.", True, 6198, 3140)],
   also=["Q_A01_09"]),
 "ACT01_Z02": dict(key="kingsroad_fields", kind="wild", biome="farmland", order=2,
   pois=["Old King's Road Milestone", "Weeping Aqueduct", "Dawnwatch Fields", "Roadside Shrine"],
   mech=("collect", "Courier's Waymark", ["Hob Marrow, Bandit Chief", "The Mile-Eater", "Grain-Cart Raider"]),
   foes=[("Kingsroad Raider", R, (0.95, 0.82, 0.66)), ("Displaced Field-Vermin", S, (0.86, 0.8, 0.55)), ("Dawnwatch Scarecrow", B, (0.96, 0.86, 0.6))],
   also=["Q_A01_03", "Q_A01_07"]),
 "ACT01_R03": dict(key="whisperwood_forest", kind="fixed", biome="forest", order=3,
   reg=RZ("Whisperwood", "Q_A01_04", "A Forest Out of Season", "follow impossible winter tracks into the summer wood and stop the out-of-season Thornwarden",
          "Old oaks, standing stones and a fae ring; the Greenwood Marches' oldest wood", "An animal remembers an extinct river; the Thornwarden was a guardian from another season."),
   mech=("boss", "The Thornwarden", B), fixed_boss=[5650, 3000], boss_tint=(0.82, 0.92, 1.0),
   foes=[("Brackenwood Poacher", R, (0.86, 0.9, 0.8)), ("Winter Wisp", S, (0.86, 0.95, 1.0)), ("Out-of-Season Wolf-Beast", B, (0.82, 0.9, 1.0))],
   also=["Q_A01_05"]),
 "ACT01_Z06": dict(key="silverroot_grove", kind="wild", biome="echo_grove", size="S", state="ECHO", order=4,
   pois=["The Old Hunter's Bow", "Suspended Leaves", "Twin Oaks"],
   mech=("boss", "The Echo Stag", B), boss_poi=2,
   lorecast=dict(id="unremembered_hunter", figure="Hennick, the Unremembered Hunter", remains="The Old Hunter's Bow", poi=0,
     skill=dict(id="remembered_volley", name="Remembered Volley", icon="starfall_script", shape="line", anim="Cast", cost=14.0, cd=4.0,
       desc="Lorecast (Hennick, the Unremembered Hunter): loose the arrows of a hunt no one remembers, through every foe in a line.",
       nums={"dmg": 1.9, "pierce": 6, "range": 11.0, "width": 1.0}),
     echo="Echo of Hennick", lore=["A bow hangs in a tree that is two trees at once. The amber leaves around it do not fall.",
       "Hennick's echo nocks an arrow at you. 'This is my hunt. Whose record are you?'",
       "He lowers the bow and fades into the amber. His last hunt stays with you: Remembered Volley."]),
   foes=[("Echo Hound", S, (1.0, 0.84, 0.5)), ("Echo of a Hunter", R, (1.0, 0.86, 0.6)), ("Amber Treant", B, (1.0, 0.8, 0.5))]),
 "ACT01_R05": dict(key="mossbarrow_crypts", kind="dungeon", biome="crypt", order=5,
   reg=RZ("Mossbarrow Crypts", "Q_A01_R05", "The Sealed Barrow", "descend beneath the Standing Stones and put the Barrow-Lord back in his grave",
          "Burial crypt under the Whisperwood's standing stones", "A Concord paladin is buried among the barrow-dead, in armour no smith alive could make."),
   pois=["The Paladin's Tomb", "Hall of Shades", "Barrow-Lord's Vault"], mech=("boss", "Barrow-Lord Ostric", B),
   lorecast=dict(id="exalted_paladin", figure="Aurelian Dace, Exalted Paladin", remains="The Exalted Paladin's Remains", poi=0,
     skill_res="res://data/skills/lore/radiant_spear.tres", echo="Echo of Aurelian Dace",
     lore=["The armour is Concord-forged, untouched by rust after an age in the dark.",
       "As you kneel, light gathers into a man in that armour: Aurelian Dace, Exalted of the Concord's guard. He does not know the Concord has fallen. He knows only that you are not one of his.",
       "He has fallen to you, and in falling he understands. The last of his light is yours: the Radiant Spear."]),
   foes=[("Barrow Shade", R, (0.72, 0.74, 0.86)), ("Crypt Ooze", S, (0.78, 0.86, 0.7)), ("Tomb Warden", B, (0.78, 0.78, 0.82))]),
 "ACT01_R06": dict(key="hollowmere", kind="wild", biome="bog", order=6,
   reg=RZ("Hollowmere", "Q_A01_R06", "The Drowned Matron", "cross the drowned marsh, relight the wardens' lanterns and end the Drowned Matron",
          "Marshlands, drowned lanterns, heavy mist", "The Matron wore a warden's ring older than Crownsfall."),
   pois=["Ferryman's Rest", "Lantern of Reeds", "Lantern of the Willow", "The Matron's Chapel"], mech=("boss", "The Drowned Matron", R), boss_poi=3,
   boss_tint=(0.6, 0.82, 0.98), foes=[("Bog Ghoul", R, (0.62, 0.86, 0.66)), ("Mirelight Wisp", S, (0.74, 1.0, 0.82)), ("Mire Lurker", B, (0.55, 0.76, 0.82))]),
 "ACT01_R07": dict(key="sunken_chapel", kind="dungeon", biome="cistern", order=7,
   reg=RZ("Sunken Chapel", "Q_A01_R07", "The Scorched Altar", "go down beneath the Matron's chapel and silence the Hollow Choir's Choirmaster",
          "Flooded chapel crypt; subsite of the Cathedral of the Nameless", "The altar is burnt in rings from inside time; a buried processional way leads on toward a nameless cathedral.", "ECHO"),
   pois=["Flooded Nave", "Oracle's Pool", "The Scorched Altar"], mech=("boss", "The Choirmaster", R), boss_tint=(0.45, 0.95, 0.9),
   lorecast=dict(id="drowned_oracle", figure="Merrow Ashe, Oracle of the Tides", remains="The Drowned Oracle's Pool", poi=1,
     skill_res="res://data/skills/lore/tidecall.tres", echo="Echo of Merrow Ashe",
     lore=["The pool is perfectly still. Under it lies a woman in a Concord oracle's robes, eyes open, watching a sky that is not there.",
       "Her echo rises dripping. 'The tide of hours is turning. Who let you into the Chapel? The Chancellor forbade it.'",
       "She sinks back into the pool, and the stillness of it stays with you: Tidecall."]),
   foes=[("Drowned Acolyte", R, (0.6, 0.84, 0.82)), ("Chapel Eel", S, (0.62, 0.9, 0.86)), ("Font Horror", B, (0.52, 0.74, 0.76))]),
 "ACT01_Z13": dict(key="cathedral_of_the_nameless", kind="arena", biome="cathedral", state="ECHO", order=8,
   pois=["Processional Aisle", "Sanctuary Door"],
   mech=("boss", "Ser Caldrin Vael", R), boss_tint=(0.72, 0.5, 1.0), boss_height=2.5,
   memory=dict(chapter="THE MAN BEHIND THE MONSTER", title="SER CALDRIN VAEL", lines=[
     "You Lorecast the shield. Warm light: the same shield rests beside a kitchen table. Elara repairs its strap while Caldrin prepares for duty.",
     "Lys sets a folded paper crown on his helmet. 'You promised.' Elara: 'Come home before the bell.'",
     "Then the cathedral doors, civilians behind him, and the silence after the reset.",
     "Caldrin: 'I remember the door. I remember the bell. But I cannot remember who was waiting.'  You give him his name: Caldrin Vael.",
     "Mira, when you return: 'Then he was never the thing we thought he was.'  Captain Ralden says nothing for a long time."]),
   foes=[("Violet Shade", R, (0.72, 0.55, 1.0)), ("Glass Mote", S, (0.78, 0.6, 1.0)), ("Nave Sentinel", B, (0.7, 0.6, 0.95))]),
 "ACT01_R09": dict(key="greyfen_causeway", kind="wild", biome="ash_road", order=9,
   reg=RZ("Greyfen Causeway", "Q_A01_R09", "The Tollkeeper", "break the road cult's hold on the ruined causeway toll and recover the courier's satchel",
          "Ruined causeway over the salt heath, toll encounter", "The courier's seal belongs to the Keepers of Names."),
   pois=["Toll Tower", "Sunken Wagons", "Heron Stones", "Saltpan Shrine"], mech=("boss", "The Tollkeeper", B), boss_poi=0, boss_tint=(1.0, 0.78, 0.42),
   foes=[("Salt Brigand", R, (1.0, 0.86, 0.7)), ("Brine Slime", S, (1.0, 1.0, 0.92)), ("Causeway Brute", B, (0.95, 0.82, 0.62))]),
 "ACT01_R10": dict(key="saltmarrow", kind="town", biome="harbor", order=10,
   reg=RZ("Saltmarrow", "Q_A01_R10", "Safe Harbour", "bring word of the causeway to Saltmarrow's harbourmaster",
          "Coastal sanctuary, trade and respite", "Saltmarrow's ships stopped coming the night the lanterns went dark."),
   pois=["Harbour Square", "Long Pier", "Net Lofts", "Old Lighthouse"], mech=("talk", "harbourmaster"),
   npcs=[("harbourmaster", "Harbourmaster Wenna", "mage", (0.8, 0.9, 1.0), "'The tide still comes in, Wayfarer, even if the ships don't.'", False, 7230, 2540),
         ("chandler", "Chandler Brisk", "knight", (1.0, 0.88, 0.72), "Ship's chandler and general goods.", True, 8300, 3450)],
   foes=[("Salt Brigand", R, (1.0, 0.86, 0.7)), ("Brine Slime", S, (1.0, 1.0, 0.92)), ("Causeway Brute", B, (0.95, 0.82, 0.62))]),
 "ACT01_R11": dict(key="wreckers_strand", kind="wild", biome="coast", order=11,
   reg=RZ("Wrecker's Strand", "Q_A01_R11", "The Dark Lighthouse", "recover the three lighthouse lenses the wreckers took up the Strand",
          "Shipwrecks and shoreline combat", "When the lamp is lit, the beam swings to a crack in the sea cave where the tide runs the wrong way."),
   pois=["Tide Pools", "Wreck of the Gilded Oath", "Driftwood Camp", "Warden's Rock"],
   mech=("collect", "Lighthouse Lens", ["The Pool-Queen", "Captain of the Gilded Oath", "The Strand-Breaker"]), turnin="harbourmaster_s",
   npcs=[("harbourmaster_s", "Harbourmaster Wenna", "mage", (0.8, 0.9, 1.0), "'I came up the Strand myself. Bring me those lenses.'", False)], npc_poi=2,
   foes=[("Drowned Sailor", R, (0.66, 0.8, 0.92)), ("Tide Crawler", S, (1.0, 0.7, 0.62)), ("Wreck Hulk", B, (0.62, 0.84, 0.72))]),
 "ACT01_R12": dict(key="smugglers_grotto", kind="dungeon", biome="cistern", order=12,
   reg=RZ("Smuggler's Grotto", "Q_A01_R12", "The Price of a Name", "find where Corsair Velka gets her relics and free the Keeper she holds",
          "Hidden sea cavern of relic smugglers", "Velka bought Aurelian records that predate the kingdom; her prisoner is Tamsin Reed, a Keeper of Names."),
   pois=["Duelist's Alcove", "Smugglers' Cache", "The Wrong Tide"], mech=("boss", "Corsair Queen Velka", R), turnin="tamsin", boss_tint=(1.0, 0.7, 0.5),
   npcs=[("tamsin", "Tamsin Reed", "mage", (0.86, 0.8, 0.95), "Keeper of Names. 'A name is not a claim to someone else's home.'", False)],
   lorecast=dict(id="corsair_duelist", figure="Serrin Vale, Corsair Duelist", remains="The Duelist's Alcove", poi=0,
     skill_res="res://data/skills/lore/riposte_flurry.tres", echo="Echo of Serrin Vale",
     lore=["A skeleton in a sky-corsair's coat, blade still raised. The smugglers left it alone, which says something.",
       "The echo salutes with the blade. 'Sky-Captain Vale, of the Concord fleet. Draw, whoever you are.'",
       "'Good. They'll need hands like yours when the hours run out.' Riposte Flurry is yours."]),
   foes=[("Grotto Smuggler", R, (1.0, 0.82, 0.66)), ("Cave Crab", S, (1.0, 0.66, 0.55)), ("Grotto Bruiser", B, (0.86, 0.72, 0.6))]),
 "ACT01_R13": dict(key="lanternfall_cliffs", kind="wild", biome="coast", order=13,
   reg=RZ("Lanternfall Cliffs", "Q_A01_R13", "The Keepers' Journal", "recover the lantern-keepers' journal pages from the clifftop ruins",
          "Clifftop ruins and warden lanterns", "Every keeper wrote the same line on the same night: 'The Engine is waking.'"),
   pois=["West Lantern", "High Lantern", "East Lantern", "Keeper's Stair"],
   mech=("collect", "Keeper's Journal Page", ["The West Keeper", "The High Keeper", "The East Keeper"]),
   foes=[("Cliff Ghoul", R, (0.86, 0.9, 0.95)), ("Lantern Wisp", S, (1.0, 0.92, 0.6)), ("Cliff Brute", B, (0.78, 0.8, 0.84))]),
 "ACT01_R14": dict(key="riftscar_moor", kind="wild", biome="quarry", order=14,
   reg=RZ("Riftscar Moor", "Q_A01_R14", "Clockwork on the Moor", "stop the Clockwork Centurion mustering bronze soldiers out of the Riftscar",
          "Fractured terrain around an open rift", "The Centurion's orders are stamped in its chest: 'Hold the line until the Chancellor's word.'"),
   pois=["The Riftscar", "Clockwork Muster", "Moor Cairn", "Shepherds' Fold"], mech=("boss", "The Clockwork Centurion", B), boss_poi=1, boss_tint=(1.0, 0.8, 0.4),
   foes=[("Clockwork Soldier", R, (1.0, 0.78, 0.45)), ("Rift Mite", S, (0.78, 0.55, 1.0)), ("Rift Beast", B, (0.75, 0.55, 0.95))]),
 "ACT01_R15": dict(key="oldwatch", kind="town", biome="refuge", order=15,
   reg=RZ("Oldwatch", "Q_A01_R15", "The Last Dispatch", "reach the frontier fort at Oldwatch and report to scout Rowan Hale",
          "Frontier fort, resupply and allies", "Rowan has tracked the courier's route to the ruins at Brackwater: the road there is older than the kingdom."),
   pois=["Watch Yard", "Old Tower", "Scout's Post"], mech=("talk", "rowan_o"),
   npcs=[("rowan_o", "Rowan Hale", "knight", (0.78, 0.9, 0.7), "Scout of the courier roads. 'Every road out here used to go somewhere.'", False, 11800, 3250),
         ("hode", "Sergeant Hode", "knight", (0.86, 0.9, 0.86), "Quartermaster of the watch.", True, 8700, 2250)],
   foes=[("Clockwork Soldier", R, (1.0, 0.78, 0.45)), ("Rift Mite", S, (0.78, 0.55, 1.0)), ("Rift Beast", B, (0.75, 0.55, 0.95))]),
 "ACT01_R16": dict(key="brackwater_ruins", kind="wild", biome="bastion_ruin", order=16,
   reg=RZ("Brackwater Ruins", "Q_A01_R16", "Stones Beneath Stones", "recover three Concord seals from the flickering Golden Age outpost",
          "Golden Age relics flickering between eras; major Lorecasting site", "The seals bear Chancellor Valen Oris's mark. Crownsfall's foundations are older layers of the same Concord.", "ECHO"),
   pois=["Seal-House West", "Signal Tower", "Seal-House East", "Sentinel's Post"],
   mech=("collect", "Concord Seal", ["The Seal-Warden West", "The Signal-Keeper", "The Seal-Warden East"]),
   lorecast=dict(id="rift_sentinel", figure="Sentinel Oris, of the Brackwater Watch", remains="The Sentinel's Post", poi=3,
     skill_res="res://data/skills/lore/phase_step.tres", echo="Echo of Sentinel Oris",
     lore=["A sentinel stands at his post, flickering. For a heartbeat the forum behind him is whole and full of people.",
       "'Halt. Brackwater is closed by order of the Chancellor. The hours are unsafe.' He raises his spear at you, and at something behind you.",
       "As he fades he steps sideways out of time and back again, and you learn how: Phase Step."]),
   foes=[("Concord Phantom", R, (0.6, 0.92, 1.0)), ("Flicker Ooze", S, (0.6, 0.95, 1.0)), ("Ruin Golem", B, (0.82, 0.86, 0.9))]),
 "ACT01_R17": dict(key="shattered_observatory", kind="dungeon", biome="observatory", order=17,
   reg=RZ("Shattered Observatory", "Q_A01_R17", "The Star Chart", "climb to the Concord observatory and reach the Grand Orrery",
          "Observatory ruins on the mountain behind Oldwatch", "The Orrery shows a golden city under a sky with one more star, and the interval of the scars."),
   pois=["Broken Dome", "Lens Gallery", "The Grand Orrery"], mech=("boss", "The Orrery Golem", B), boss_tint=(1.0, 0.9, 0.55),
   foes=[("Star Wraith", R, (0.66, 0.62, 1.0)), ("Astral Mote", S, (0.95, 0.95, 1.0)), ("Ruin Golem", B, (0.82, 0.86, 0.9))]),
 "ACT01_R18": dict(key="first_rift", kind="arena", biome="sundering", order=18,
   reg=RZ("The First Rift", "Q_A01_R18", "The Riftwarden", "face the Riftwarden, the Concord sentinel that guards the breach",
          "The breach at the moor's eastern end", "The Riftwarden is a conduit: through it the First Anchor answers, and the way opens."),
   pois=["Rift's Edge", "The Breach"], mech=("boss", "The Riftwarden", R), boss_tint=(0.95, 0.75, 1.0), boss_height=2.6,
   foes=[("Clockwork Soldier", R, (1.0, 0.78, 0.45)), ("Rift Mite", S, (0.78, 0.55, 1.0)), ("Rift Beast", B, (0.75, 0.55, 0.95))]),
 "ACT01_Z14": dict(key="first_anchor_chamber", kind="between", biome="anchor", order=19,
   pois=["The Bronze Rings", "Floating Inscriptions", "Joren's Ledge"],
   mech=("boss", "The Anchor Sentinel", B), turnin="joren", boss_poi=0, npc_poi=2, boss_tint=(1.0, 0.82, 0.45),
   npcs=[("joren", "Joren Pike", "knight", (0.92, 0.86, 0.8), "The missing royal courier. 'I was on the road. Then I was nowhere. Then I heard you say my route.'", False)],
   foes=[("Hollow Choir Acolyte", R, (0.4, 0.38, 0.5)), ("Anchor Mote", S, (1.0, 0.86, 0.55)), ("Index Construct", B, (0.95, 0.86, 0.6))],
   also=["Q_A01_15"],
   epilogue=dict(chapter="ACT I COMPLETE", title="THE CROWN THAT REMEMBERS", lines=[
     "Joren Pike steps out of the bronze rings: the missing courier, displaced only days ago, and still coherent enough to bring back.",
     "Mira reads a number from the First Anchor: an interval. It matches the scar on the Riftscar Moor, and the one before it. The Engine beneath the world is alive, and it keeps time.",
     "The First Anchor answered a name, not a royal seal. Captain Ralden carries the proof to the Regent; the outer scars must be investigated.",
     "Act II, Scars of the World, begins in the west at Westgate Refuge."])),
 # ---- side areas (Production Pack v2 / narrative bible zones), each with its bible quest
 "ACT01_Z03": dict(key="bramblewatch", kind="wild", biome="orchard", side=True, levels=[2, 3],
   pois=["Bramblewatch Palisade", "Collapsed Bridge", "Greenmile Orchard", "Watchfire Hill"],
   mech=("boss", "Scavenger Chief Kettle", R), turnin="rowan", boss_poi=1, npc_poi=0,
   npcs=[("rowan", "Rowan Hale", "knight", (0.78, 0.9, 0.7), "Scout of the courier roads. 'Every road out here used to go somewhere.'", False)],
   foes=[("Bridge Scavenger", R, (0.86, 0.76, 0.62)), ("Orchard Swarm", S, (1.0, 0.72, 0.4)), ("Scavenger Bruiser", B, (0.82, 0.7, 0.56))]),
 "ACT01_Z05": dict(key="mossbell_hamlet", kind="wild", biome="hamlet", size="S", side=True, levels=[4, 5],
   pois=["Haunted Mill", "Hollowbrook Millpond", "Lantern Row", "The Three Doors"],
   mech=("boss", "The Millhaunt", R), boss_poi=0,
   npcs=[("widow_ansel", "Widow Ansel", "mage", (0.9, 0.95, 0.82), "'Three doors, three families, one missing girl. Everyone remembers her differently.'", False)], npc_poi=3,
   foes=[("Millhaunt Shade", R, (0.75, 0.85, 0.8)), ("Pond Ooze", S, (0.6, 0.86, 0.7)), ("Hollowed Miller", B, (0.74, 0.82, 0.7))]),
 "ACT01_Z07": dict(key="ashen_tollway", kind="wild", biome="ash_road", side=True, levels=[3, 4],
   pois=["Burnt Caravans", "Cult Camp", "Toll Shrine", "Charred Milestone"],
   mech=("boss", "Cult Captain Varro", R), boss_poi=1, also=["Q_A01_08"],
   foes=[("Tollway Cultist", R, (0.78, 0.7, 0.66)), ("Cinder Mite", S, (1.0, 0.6, 0.4)), ("Cult Enforcer", B, (0.72, 0.64, 0.6))]),
 "ACT01_Z08": dict(key="bellwater_mills", kind="wild", biome="mill_river", side=True, levels=[4, 5],
   pois=["Great Waterwheel", "Cellar Sluices", "Mill Yard", "Grain Canal"],
   mech=("boss", "The Sluice Guardian", B), boss_poi=1,
   npcs=[("bera", "Bera Flint", "knight", (0.9, 0.86, 0.78), "Millwright of Bellwater. 'The water ran uphill for an hour. Then it remembered how not to.'", False)], npc_poi=2,
   foes=[("Sluice Drowned", R, (0.66, 0.82, 0.9)), ("Backwater Ooze", S, (0.55, 0.78, 0.86)), ("Mill Construct", B, (0.8, 0.82, 0.86))]),
 "ACT01_Z09": dict(key="highward_steps", kind="town", biome="city", side=True, levels=[3, 4],
   pois=["Heraldic Gate", "Pilgrim's Rise", "Westgarden Terraces", "Quarantine Post"],
   mech=("collect", "Quarantined Relic", ["Relic Thief Sallow", "The Gatebreaker", "Rift-Touched Smuggler"]), turnin="garran", also=["Q_A01_10"],
   npcs=[("garran", "Marshal Garran Holt", "knight", (0.86, 0.88, 1.0), "'The Regent wants order. I want my people alive. Today those are the same thing.'", False)], npc_poi=0,
   foes=[("Relic Thief", R, (0.9, 0.84, 0.74)), ("Phase Rat", S, (0.8, 0.7, 0.95)), ("Rogue Gate-Construct", B, (0.88, 0.86, 0.8))]),
 "ACT01_Z10": dict(key="sablemarket_vaults", kind="dungeon", biome="merchant_crypt", side=True, levels=[5, 6],
   pois=["Broker's Counting Room", "Bronze Shutters", "Secret Ledgers", "The Cells"],
   mech=("boss", "Relic Broker Quell", R), also=["Q_A01_11"],
   foes=[("Broker's Guard", R, (0.9, 0.8, 0.6)), ("Vault Mimic", S, (0.9, 0.78, 0.5)), ("Vault Hulk", B, (0.82, 0.74, 0.6))]),
 "ACT01_Z11": dict(key="old_crown_cistern", kind="dungeon", biome="cistern", state="ECHO", side=True, levels=[6, 7],
   pois=["Flooded Avenue", "Processional Stair", "Old Street Gate"],
   mech=("collect", "Procession Echo", ["The Drowned Herald", "The Lamp-Bearer", "The Standard-Bearer"]), also=["Q_A01_12"],
   foes=[("Cistern Echo", R, (0.7, 0.86, 0.95)), ("Cistern Eel", S, (0.55, 0.8, 0.86)), ("Masonry Golem", B, (0.8, 0.84, 0.88))]),
 "ACT01_Z12": dict(key="undercroft", kind="dungeon", biome="crypt", side=True, levels=[7, 8],
   pois=["Sunken Archive", "Candle Niches", "Cathedral Underdeep Stair"],
   mech=("boss", "The Crypt Warden", B),
   foes=[("Crypt Ghoul", R, (0.78, 0.74, 0.92)), ("Candle Swarm", S, (1.0, 0.86, 0.6)), ("Crypt Knight", B, (0.72, 0.7, 0.86))]),
 "ACT01_Z15": dict(key="crownsfall_citadel", kind="town", biome="citadel", side=True, levels=[10, 10],
   pois=["Royal Court", "Refugee Hall", "Upper Citadel Approach"],
   mech=("boss", "The Court Tear", R), turnin="maera", boss_poi=0, npc_poi=1, boss_tint=(0.78, 0.5, 1.0),
   npcs=[("maera", "Regent Maera Ashford", "mage", (0.86, 0.86, 1.0), "'I kept this city fed by keeping it calm. I may have kept it ignorant too.'", False)],
   foes=[("Tear Wraith", R, (0.75, 0.55, 1.0)), ("Tear Spawn", S, (0.8, 0.55, 1.0)), ("Unmade Guard", B, (0.75, 0.62, 0.95))]),
}
ACT1_EDGES = [("crownsfall", "kingsroad_fields"), ("crownsfall", "highward_steps"),
  ("kingsroad_fields", "whisperwood_forest"), ("kingsroad_fields", "bramblewatch"), ("bramblewatch", "mossbell_hamlet"),
  ("kingsroad_fields", "ashen_tollway"), ("ashen_tollway", "bellwater_mills"), ("bellwater_mills", "kingsroad_fields"),
  ("whisperwood_forest", "silverroot_grove"), ("whisperwood_forest", "mossbarrow_crypts"), ("whisperwood_forest", "hollowmere"),
  ("hollowmere", "sunken_chapel"), ("sunken_chapel", "cathedral_of_the_nameless"), ("hollowmere", "greyfen_causeway"),
  ("greyfen_causeway", "saltmarrow"), ("saltmarrow", "wreckers_strand"), ("wreckers_strand", "smugglers_grotto"),
  ("wreckers_strand", "lanternfall_cliffs"), ("lanternfall_cliffs", "riftscar_moor"), ("riftscar_moor", "oldwatch"),
  ("riftscar_moor", "brackwater_ruins"), ("oldwatch", "shattered_observatory"), ("riftscar_moor", "first_rift"),
  ("first_rift", "first_anchor_chamber"), ("highward_steps", "sablemarket_vaults"), ("sablemarket_vaults", "old_crown_cistern"),
  ("old_crown_cistern", "undercroft"), ("highward_steps", "crownsfall_citadel")]
# Act map (0..1): Crownsfall in the west heartland, the road out east and south to the coast, the moor and the rift.
ACT1_POS = {"crownsfall": (0.08, 0.42), "highward_steps": (0.1, 0.16), "crownsfall_citadel": (0.2, 0.06), "sablemarket_vaults": (0.03, 0.62),
  "old_crown_cistern": (0.07, 0.82), "undercroft": (0.17, 0.94), "kingsroad_fields": (0.22, 0.46), "bramblewatch": (0.26, 0.24), "mossbell_hamlet": (0.36, 0.1),
  "ashen_tollway": (0.26, 0.7), "bellwater_mills": (0.34, 0.84), "whisperwood_forest": (0.36, 0.42), "silverroot_grove": (0.44, 0.22),
  "mossbarrow_crypts": (0.46, 0.06), "hollowmere": (0.48, 0.56), "sunken_chapel": (0.46, 0.78), "cathedral_of_the_nameless": (0.56, 0.92),
  "greyfen_causeway": (0.6, 0.62), "saltmarrow": (0.7, 0.72), "wreckers_strand": (0.8, 0.82), "smugglers_grotto": (0.9, 0.94),
  "lanternfall_cliffs": (0.82, 0.6), "riftscar_moor": (0.76, 0.42), "oldwatch": (0.72, 0.2), "shattered_observatory": (0.82, 0.08),
  "brackwater_ruins": (0.62, 0.32), "first_rift": (0.9, 0.36), "first_anchor_chamber": (0.96, 0.52)}

# ================================================================ Acts II-VII (frameworks; compact form)
# Z(key, kind, biome, pois, mech, foes=family set, npcs, turnin, boss art) — foes come from the act's family sets
# (bible creature progression + Atlas enemy notes): present wildlife and bandits -> phase-altered wildlife and
# constructs -> unstable historical guardians -> organised displaced combatants -> Engine avatars.
def N(nid, name, model, tint, idle, vendor=False): return (nid, name, model, tint, idle, vendor)
def Z(key, kind, biome, pois, mech, fam, npcs=None, turnin=None, size=None, boss_art=None, boss_tint=None, epilogue=None, npc_poi=None, boss_poi=None):
    d = dict(key=key, kind=kind, biome=biome, pois=pois, mech=mech, fam=fam)
    if npcs: d["npcs"] = npcs
    if turnin: d["turnin"] = turnin
    if size: d["size"] = size
    if boss_tint: d["boss_tint"] = boss_tint
    if epilogue: d["epilogue"] = epilogue
    if npc_poi is not None: d["npc_poi"] = npc_poi
    if boss_poi is not None: d["boss_poi"] = boss_poi
    return d
def BO(name, art=B): return ("boss", name, art)
def CO(item, g): return ("collect", item, g)
TALK = lambda n: ("talk", n)
ARR = ("arrive",)

FAMILIES = {
 # Act II: frontier beasts, marsh horrors, phase-altered wildlife, Riftbinder constructs, Choir agents
 "frontier": [("Frontier Raider", R, (0.9, 0.8, 0.7)), ("Scar Mite", S, (0.8, 0.65, 1.0)), ("Phase-Touched Elk", B, (0.82, 0.86, 0.95))],
 "marsh":    [("Fen Lurker", R, (0.62, 0.82, 0.66)), ("Bog Leech-Swarm", S, (0.6, 0.8, 0.6)), ("Drowned Chapel Hulk", B, (0.55, 0.74, 0.7))],
 "highland": [("Pass Brigand", R, (0.86, 0.86, 0.9)), ("Rime Mote", S, (0.9, 0.96, 1.0)), ("Avalanche Brute", B, (0.86, 0.9, 0.96))],
 "riftglass":[("Riftbinder Adept", R, (0.8, 0.6, 1.0)), ("Crystal Mite", S, (0.85, 0.6, 1.0)), ("Conduit Construct", B, (0.8, 0.66, 0.95))],
 "coast":    [("Greywake Wrecker", R, (0.7, 0.82, 0.92)), ("Tide Crawler", S, (1.0, 0.7, 0.62)), ("Salt Hulk", B, (0.66, 0.82, 0.78))],
 "echo_fort":[("Siege Specter", R, (0.7, 0.82, 1.0)), ("Echo Mote", S, (0.8, 0.9, 1.0)), ("Bastion Golem", B, (0.8, 0.84, 0.9))],
 "choir":    [("Hollow Choir Cantor", R, (0.42, 0.38, 0.52)), ("Resonance Wisp", S, (0.6, 0.5, 0.8)), ("Masked Choir Warden", B, (0.45, 0.42, 0.55))],
 # Act III: Golden Age defenders and constructs (unstable historical guardians)
 "concord_guard": [("Concord Sentinel", R, (1.0, 0.92, 0.7)), ("Lumen Mote", S, (1.0, 0.95, 0.75)), ("Civic Automaton", B, (1.0, 0.86, 0.6))],
 "automata":      [("Workshop Automaton", R, (0.95, 0.8, 0.55)), ("Brass Scuttler", S, (1.0, 0.78, 0.45)), ("Foundry Colossus", B, (0.95, 0.72, 0.45))],
 "spectral":      [("Spectral Assailant", R, (0.75, 0.85, 1.0)), ("Memory Wisp", S, (0.85, 0.9, 1.0)), ("Archive Guardian", B, (0.85, 0.85, 0.95))],
 "lab":           [("Unstable Echo", R, (0.85, 0.75, 1.0)), ("Test Remnant", S, (0.9, 0.85, 1.0)), ("Containment Warden", B, (0.92, 0.92, 1.0))],
 # Act IV: the final day: disaster, military patrols, seam-touched, Between factions
 "disaster": [("Panicked Patrol", R, (1.0, 0.75, 0.6)), ("Cinder Spark", S, (1.0, 0.55, 0.35)), ("Ash Elemental", B, (0.9, 0.55, 0.45))],
 "seam":     [("Seam-Touched Guard", R, (0.8, 0.55, 1.0)), ("Violet Rain Mote", S, (0.75, 0.5, 1.0)), ("Fractured Construct", B, (0.75, 0.6, 0.95))],
 "court":    [("Remnant Court Retainer", R, (0.78, 0.82, 0.92)), ("Mirror Shard", S, (0.85, 0.9, 1.0)), ("Glass Knight", B, (0.8, 0.85, 0.95))],
 # Act V: displaced epoch combatants
 "rain":     [("Rain Kingdom Marine", R, (0.6, 0.72, 0.86)), ("Flood Spirit", S, (0.5, 0.7, 0.9)), ("Canal Leviathan", B, (0.5, 0.66, 0.8))],
 "verdant":  [("Verdant Warden", R, (0.6, 0.9, 0.55)), ("Root Swarm", S, (0.55, 0.85, 0.45)), ("Living Vault-Tree", B, (0.5, 0.8, 0.45))],
 "iron":     [("Iron Sabbath Foreman", R, (0.8, 0.55, 0.45)), ("Kiln Spark", S, (1.0, 0.45, 0.3)), ("Furnace Engine", B, (0.75, 0.45, 0.4))],
 "moon":     [("Moonfall Militia", R, (0.82, 0.86, 1.0)), ("Moonlit Glass Mote", S, (0.9, 0.92, 1.0)), ("Assembly Guardian", B, (0.82, 0.85, 0.95))],
 # Act VI: war creatures from the scars, Golden Age war machines, Continuance forces
 "war":      [("Scar-Born Raider", R, (0.85, 0.6, 0.9)), ("Hour Mite", S, (0.9, 0.7, 1.0)), ("War Construct", B, (0.9, 0.8, 0.6))],
 "winter":   [("Frost Revenant", R, (0.8, 0.9, 1.0)), ("Thermal Wisp", S, (1.0, 0.7, 0.5)), ("Winter Elemental", B, (0.85, 0.92, 1.0))],
 "continuance": [("Continuance Index-Knight", R, (1.0, 0.95, 0.8)), ("White-Light Mote", S, (1.0, 1.0, 0.9)), ("Bronze Avatar", B, (1.0, 0.85, 0.55))],
}

def _fam(d):
    # zone design "fam" key -> the three foes
    d["foes"] = FAMILIES[d.pop("fam")]
    return d

# ---------------------------------------------------------------- Act II: Scars of the World (levels 11-20)
ACT2 = {k: _fam(v) for k, v in {
 "ACT02_Z01": Z("westgate_refuge", "town", "refuge", ["Ruined Viaduct", "Wagon Circle", "Resource Caches", "Refugee Ledger Tent"],
                CO("Missing Refugee Record", ["Cache-Raider Brask", "The Viaduct Prowler", "Record-Thief Moll"]), "frontier",
                npcs=[N("iri", "Iri", "mage", (0.78, 0.8, 1.0), "Veyr Phasewalker. 'The people the scars take are people. Say it with me.'")], turnin="iri", npc_poi=3),
 "ACT02_Z02": Z("thornfen", "wild", "bog", ["Drowned Chapel", "Reed-Boat Landing", "The Sunk Bell", "Stilt Village"], BO("The Bell-Drowned"), "marsh", boss_poi=2),
 "ACT02_Z03": Z("glassreed_marsh", "wild", "echo_marsh", ["Frozen Ripples", "Surveyor's Stake", "Stable Node", "Translucent Reeds"],
                CO("Surveyor's Map Leaf", ["The Glass Heron", "Reflection of the Surveyor", "The Still Pike"]), "marsh", size="S"),
 "ACT02_Z04": Z("blackpine_reach", "wild", "conifer", ["Charcoal Camp", "Corrupted Logging Camp", "Court Agent's Tent", "Tall Pines Ridge"], BO("The Charcoal Beast"), "frontier", boss_poi=1),
 "ACT02_Z05": Z("hearthstone_crossing", "wild", "mountain", ["Trade Bridge", "Stone Inn", "Toll House of Two Kings", "Widow's Span Lookout"],
                CO("Contradicting Toll Record", ["Toll-Breaker Hask", "The Span Ravager", "Bridge Saboteur"]), "highland"),
 "ACT02_Z06": Z("veyr_meridian_outpost", "town", "veyr", ["Suspended Instruments", "Phase-Safety Trial Ring", "Timekeepers' Hall", "Archivists' Gallery"],
                TALK("meridian"), "frontier",
                npcs=[N("meridian", "Meridian", "mage", (0.74, 0.76, 1.0), "Chief keeper of the Veyr. 'Records and models can be wrong. Mine included.'"),
                      N("sio", "Warden Sio", "knight", (0.8, 0.82, 1.0), "Echo Warden of the Veyr. Supplies for those who cross.", True)], npc_poi=0),
 "ACT02_Z07": Z("windcut_pass", "wild", "snow", ["Avalanche Gallery", "Snow Ridge Camp", "Warning Beacon", "Collapsed Shelter"],
                CO("Warning Dispatch", ["The Rime Courier-Killer", "Ridge Stalker", "Gallery Brute"]), "highland"),
 "ACT02_Z08": Z("riftglass_quarry", "wild", "quarry", ["Purple Cuts", "Abandoned Crane", "Crystal Conduits", "Foreman's Office"], BO("Foreman Draeg"), "riftglass", boss_poi=3),
 "ACT02_Z09": Z("forgotten_bastion", "dungeon", "bastion", ["Stitched Gate", "Two Keeps", "Military Index Vault"], BO("The Siege Specter", R), "echo_fort"),
 "ACT02_Z10": Z("greywake_coast", "wild", "coast", ["Storm Cliffs", "Salt Village", "Watcher's End Beacon", "Wreck Field"], BO("The Tide of Names", R), "coast", boss_poi=2,
                npcs=[N("anwen", "Captain Anwen Sable", "knight", (0.8, 0.9, 0.95), "Greywake pilot. 'The beacons kept ships alive. Now they keep something else away.'")], npc_poi=1),
 "ACT02_Z11": Z("saltmirror_harbor", "town", "harbor_echo", ["Golden Docks", "Cargo Crane", "Modern Fishing Pier", "Smugglers' Berth"], BO("Temporal Smuggler Vane", R), "coast", boss_poi=3),
 "ACT02_Z12": Z("timekeepers_causeway", "between", "causeway", ["First Obelisk", "Shifting Platforms", "The Seventh Interval"], BO("The Interval Guardian"), "riftglass"),
 "ACT02_Z13": Z("scar_of_hollow_rain", "between", "between_rain", ["Broken Town", "Suspended Rain", "Choir Envoy's Rest"], BO("Choir Ambush Leader", R), "choir"),
 "ACT02_Z14": Z("west_meridian_vault", "dungeon", "vault", ["Cracked Rings", "Scar Beam Pylons", "Evacuation Path"], BO("Neral's Lieutenant, Voice of the Choir", R), "choir"),
 "ACT02_Z15": Z("meridian_observatory", "arena", "observatory", ["Calibration Chamber", "Night Dome", "Seven-Record Map"], BO("The Observatory Breaker"), "riftglass",
                npcs=[N("meridian_obs", "Meridian", "mage", (0.74, 0.76, 1.0), "'Seven records, one pattern. The scars are periodic, not natural.'")], turnin="meridian_obs",
                epilogue=dict(chapter="ACT II COMPLETE", title="SCARS OF THE WORLD", lines=[
                    "Meridian lays seven different records on a circular map. The scar points align with a hidden geometric pattern.",
                    "Through the observatory lens a fragment of an old capital becomes visible: the Aurelian Concord, preserved in a stable reconstruction.",
                    "The pattern is periodic, not natural. Act III, The Age of Gold, begins at the Sunward Threshold."])),
}.items()}
ACT2_EDGES = [("kingsroad_fields", "westgate_refuge"), ("westgate_refuge", "thornfen"), ("thornfen", "glassreed_marsh"), ("thornfen", "blackpine_reach"),
  ("blackpine_reach", "hearthstone_crossing"), ("hearthstone_crossing", "veyr_meridian_outpost"), ("veyr_meridian_outpost", "windcut_pass"),
  ("windcut_pass", "riftglass_quarry"), ("riftglass_quarry", "forgotten_bastion"), ("hearthstone_crossing", "greywake_coast"),
  ("greywake_coast", "saltmirror_harbor"), ("greywake_coast", "timekeepers_causeway"), ("timekeepers_causeway", "scar_of_hollow_rain"),
  ("scar_of_hollow_rain", "west_meridian_vault"), ("west_meridian_vault", "meridian_observatory"), ("veyr_meridian_outpost", "meridian_observatory")]

# ---------------------------------------------------------------- Act III: The Age of Gold (levels 21-30) - Echo pockets of the Concord
ACT3 = {k: _fam(v) for k, v in {
 "ACT03_Z01": Z("sunward_threshold", "wild", "golden_gate", ["Monumental Transit Gate", "Anchor Plinth", "Echo Travellers' Rest"], BO("Gate Anchor Warden"), "concord_guard", size="S", boss_poi=1),
 "ACT03_Z02": Z("aurelian_forum", "town", "golden_city", ["Marble Arcades", "Civic Amphitheater", "Festival Gardens", "Elyndor's Lectern"], TALK("elyndor"), "concord_guard",
                npcs=[N("elyndor", "Elyndor", "mage", (1.0, 0.94, 0.8), "Aurelian historian. 'Deletion displaces records. It does not destroy them.'")], npc_poi=3),
 "ACT03_Z03": Z("lumen_canal", "wild", "golden_canal", ["Luminous Locks", "Glass Barge Quay", "Aqueduct Span", "Pump House"], BO("The Lock Automaton"), "automata", boss_poi=0),
 "ACT03_Z04": Z("orchard_of_hours", "wild", "golden_orchard", ["Weather Machine", "Terraced Groves", "Harvest Hall", "Season Arena"], BO("The Season Engine"), "automata", boss_poi=3),
 "ACT03_Z05": Z("artificers_ward", "town", "golden_workshop", ["Brass Workshops", "Clockwork Cranes", "Ceramic Roofs", "The First Exception"], BO("Rogue Construct Prime"), "automata", boss_poi=3),
 "ACT03_Z06": Z("sapphire_academy", "dungeon", "golden_academy", ["Observatory Library", "Blue Glass Dome", "Archive Trial Hall"], CO("Continuity Lesson", ["Proctor of Glass", "Archive Trial Echo", "The Index Familiar"]), "spectral"),
 "ACT03_Z07": Z("workers_terrace", "town", "golden_city", ["Public Kitchens", "Laundry Lines", "Union Hall", "Crowded Apartments"], CO("Union Testimony", ["Street Agitator", "Requisition Officer", "Collapsed-Stair Brute"]), "concord_guard",
                npcs=[N("daro", "Daro Fen", "knight", (0.95, 0.86, 0.72), "Guild worker of the labour district. 'Who pays for eternity? Us. Always us.'")], turnin="daro", npc_poi=2),
 "ACT03_Z08": Z("garden_of_civic_memory", "wild", "golden_garden", ["Memorial Trees", "Inscribed Bronze", "Fountain Court", "Ledger of the Living"], BO("The Spectral Assailant", R), "spectral", boss_poi=3),
 "ACT03_Z09": Z("astral_foundry", "dungeon", "golden_foundry", ["Vast Furnace", "Suspended Rings", "Foundry Floor"], BO("The Foundry Automaton"), "automata"),
 "ACT03_Z10": Z("concord_senate", "town", "golden_city", ["Gold Mosaics", "Rival Delegations", "Senate Floor"], CO("Evidence of the Emergency Law", ["Senate Enforcer", "Oris's Clerk", "The Rigged Ballot Guard"]), "concord_guard",
                npcs=[N("oris", "Chancellor Valen Oris", "knight", (1.0, 0.92, 0.76), "'A civilization cannot survive as a collection of exceptions.'")], npc_poi=2),
 "ACT03_Z11": Z("vael_estate", "wild", "golden_garden", ["Garden House", "Sunroom", "Children's Toys", "Duel Lawn"], BO("The Estate Intruder", R), "spectral", size="S", boss_poi=3,
                npcs=[N("caldrin_life", "Ser Caldrin Vael", "knight", (0.86, 0.9, 1.0), "'Stay behind me. The doors must hold. That is the job.'"),
                      N("elara", "Elara Vael", "mage", (1.0, 0.92, 0.86), "Bookbinder and refuge organiser. 'Come home before the bell.'")], npc_poi=0),
 "ACT03_Z12": Z("elyndors_archive", "dungeon", "golden_archive", ["Paper Labyrinth", "Crystal Catalogs", "Unpublished Index"], CO("Index Fragment", ["Archive Saboteur", "Catalog Wraith", "The Burned-Page Golem"]), "spectral"),
 "ACT03_Z13": Z("chronicle_perimeter", "wild", "golden_perimeter", ["Anchor Pylons", "Guarded Plaza", "Checkpoint", "Captain's Post"], BO("Guardian Captain Ilsar", R), "concord_guard", boss_poi=3),
 "ACT03_Z14": Z("preservation_laboratory", "dungeon", "golden_lab", ["Medical Bays", "Sealed Test Chambers", "Sera's Workbench"], CO("Test Record", ["Unstable Echo Subject", "Containment Breach", "The Mercy Construct"]), "lab",
                npcs=[N("sera", "Sera Voss", "mage", (0.95, 0.92, 0.86), "Engine engineer. 'We can save people without saving every street.'"),
                      N("pell", "Pell", "knight", (0.9, 0.9, 0.86), "Sera's technician. Keeps the logs, keeps the lights on.", True)], turnin="sera"),
 "ACT03_Z15": Z("concord_crown_spire", "arena", "golden_spire", ["Ceremonial Overlook", "Engine Balcony", "Collapsing Stair"], BO("The Corrupted Ceremonial Protector"), "concord_guard",
                epilogue=dict(chapter="ACT III COMPLETE", title="THE AGE OF GOLD", lines=[
                    "The Concord built the Chronicle Engine to preserve, to cure shortage and keep records whole.",
                    "Chancellor Oris turned a preservation project into an instrument of control, and buried its test casualties.",
                    "The pocket collapses behind you. Act IV, The Day the World Ended, begins at Last Dawn Station."])),
}.items()}
ACT3_EDGES = [("meridian_observatory", "sunward_threshold"), ("sunward_threshold", "aurelian_forum"), ("aurelian_forum", "lumen_canal"), ("lumen_canal", "orchard_of_hours"),
  ("aurelian_forum", "artificers_ward"), ("artificers_ward", "sapphire_academy"), ("aurelian_forum", "workers_terrace"), ("workers_terrace", "garden_of_civic_memory"),
  ("artificers_ward", "astral_foundry"), ("aurelian_forum", "concord_senate"), ("garden_of_civic_memory", "vael_estate"), ("concord_senate", "elyndors_archive"),
  ("concord_senate", "chronicle_perimeter"), ("chronicle_perimeter", "preservation_laboratory"), ("chronicle_perimeter", "concord_crown_spire")]

# ---------------------------------------------------------------- Act IV: The Day the World Ended (levels 31-40)
ACT4 = {k: _fam(v) for k, v in {
 "ACT04_Z01": Z("last_dawn_station", "town", "golden_dawn", ["Sunrise Rail Terminal", "Evacuation Posters", "Platform Seven", "Alarm Tower"], CO("Rescued Passenger", ["Alarm Anomaly", "Panicked Guard Captain", "Rail Construct"]), "disaster"),
 "ACT04_Z02": Z("cinder_orchard", "wild", "cinder", ["Golden Fields", "Ash Line", "Burning Press", "Hazard Waves"], BO("The Fault Fruit", S), "disaster", boss_poi=2),
 "ACT04_Z03": Z("south_reservoir", "wild", "reservoir", ["Water Towers", "Collapsed Canals", "Technicians' Post", "Sluice Hall"], BO("The Reservoir Breaker"), "disaster", boss_poi=3),
 "ACT04_Z04": Z("labor_quarter_siege", "town", "siege", ["Barricades", "Civilian Shelter", "Military Patrol Gate", "Union Hall"], BO("Emergency Decree Captain", R), "seam", boss_poi=2),
 "ACT04_Z05": Z("hall_of_seven_measures", "dungeon", "golden_hall", ["Seven Control Dials", "Measure Gallery", "Missing Limit"], BO("The Control Guardian"), "seam"),
 "ACT04_Z06": Z("vaels_last_road", "wild", "burning", ["Burning Avenue", "Violet Rain", "Evacuation Column", "The Parting"], BO("Seam-Touched Pursuer", R), "seam", boss_poi=3),
 "ACT04_Z07": Z("cathedral_before_the_fall", "arena", "cathedral_intact", ["Intact Stained Glass", "Crowded Sanctuary", "Sanctuary Door"], CO("Name We Carry", ["Doorbreaker", "Seam Wraith", "Glass-Fall Horror"]), "seam"),
 "ACT04_Z08": Z("senate_of_ash", "town", "ash_senate", ["Shattered Dome", "Emergency Council", "Evidence Strongroom"], CO("Sera's Evidence", ["Senate Guard", "Oris Loyalist", "The Ash Usher"]), "disaster"),
 "ACT04_Z09": Z("chronicle_access_ring", "dungeon", "access", ["Industrial Corridors", "Overloaded Coils", "The Door That Should Stay Shut"], BO("The Security Warden"), "seam"),
 "ACT04_Z10": Z("the_first_sundering", "wild", "sundering", ["Violet Seam", "Falling Architecture", "Escape Bridge", "Fields of Glass"], CO("Coherent Witness", ["Seam Collapse", "Falling-Tower Horror", "The Unmaking"]), "seam"),
 "ACT04_Z11": Z("the_empty_morning", "between", "between_empty", ["Sunless Streets", "Absent Silhouettes", "First Refuge Lamp"], ARR, "court"),
 "ACT04_Z12": Z("remnant_court_refuge", "between", "between_court", ["Floating Palace Fragments", "Formal Halls", "Challenge Floor"], BO("Ysara's Champion", R), "court",
                npcs=[N("ysara", "Queen Ysara", "mage", (0.86, 0.9, 1.0), "Sovereign of the Remnant Court. 'Restoring my people is not a request.'")], turnin="ysara"),
 "ACT04_Z13": Z("hollow_choir_reliquary", "between", "between_choir", ["Resonant Black Arches", "Faceless Masks", "Cantor's Dais"], BO("Cantor Neral", R), "choir"),
 "ACT04_Z14": Z("keepers_lantern", "between", "between_lantern", ["Archive Camp", "Warm Lanterns", "Paper Tags"], CO("Surviving Name", ["Name-Eater", "Choir Raider", "Lantern Thief"]), "court",
                npcs=[N("tamsin_b", "Tamsin Reed", "mage", (0.86, 0.8, 0.95), "'The names that survived. Help me keep them that way.'"),
                      N("lys", "Lys Vael", "mage", (0.92, 0.9, 1.0), "A young adult now, in the Between. 'I still have the paper crown.'")], turnin="tamsin_b"),
 "ACT04_Z15": Z("engine_of_first_night", "arena", "engine", ["Frozen Control Core", "Repeating Arena", "Original Failsafe"], BO("The First Reset"), "continuance",
                epilogue=dict(chapter="ACT IV COMPLETE", title="THE DAY THE WORLD ENDED", lines=[
                    "Oris activated the reset over evacuation, despite Sera's abort. The Concord was erased from the world; its people persist in the Between.",
                    "You hold the original ethical failsafe, and the Engine's emergency directive: every later epoch erased in turn.",
                    "The present age is scheduled for the same. Act V, The Unwritten Kingdoms, begins at Broken Meridian."])),
}.items()}
ACT4_EDGES = [("concord_crown_spire", "last_dawn_station"), ("last_dawn_station", "cinder_orchard"), ("cinder_orchard", "south_reservoir"), ("south_reservoir", "labor_quarter_siege"),
  ("labor_quarter_siege", "hall_of_seven_measures"), ("labor_quarter_siege", "vaels_last_road"), ("vaels_last_road", "cathedral_before_the_fall"), ("vaels_last_road", "senate_of_ash"),
  ("senate_of_ash", "chronicle_access_ring"), ("chronicle_access_ring", "the_first_sundering"), ("the_first_sundering", "the_empty_morning"), ("the_empty_morning", "remnant_court_refuge"),
  ("the_empty_morning", "hollow_choir_reliquary"), ("the_empty_morning", "keepers_lantern"), ("keepers_lantern", "engine_of_first_night")]

# ---------------------------------------------------------------- Act V: The Unwritten Kingdoms (levels 41-50)
ACT5 = {k: _fam(v) for k, v in {
 "ACT05_Z01": Z("broken_meridian", "wild", "broken_observatory", ["Torn Observatory", "Refugee Encampment", "Forecast Engine", "Rowan's Cot"], CO("Forecast Cylinder", ["Scar Breacher", "Forecast Thief", "The Torn-Dome Brute"]), "war",
                npcs=[N("rowan5", "Rowan Hale", "knight", (0.78, 0.9, 0.7), "'Some mornings I'm not sure which road I grew up on.'")], turnin="rowan5", npc_poi=3),
 "ACT05_Z02": Z("throne_of_glass", "between", "between_glass", ["Royal Halls", "Petition Floor", "Duel Dais"], BO("The Glass Champion", R), "court",
                npcs=[N("ysara5", "Queen Ysara", "mage", (0.86, 0.9, 1.0), "'You came to petition a queen without a kingdom. Speak.'")], turnin="ysara5"),
 "ACT05_Z03": Z("rain_kingdom", "wild", "epoch_rain", ["Slate Towers", "Thousand Canals", "Submerged Route", "Flood Gate"], BO("The Rain King's Leviathan"), "rain", boss_poi=3),
 "ACT05_Z04": Z("verdant_empire", "wild", "epoch_verdant", ["Forest-Grown Palace", "Luminous Roots", "Root Bridge", "Living Archive"], BO("The Root That Remembers"), "verdant", boss_poi=3),
 "ACT05_Z05": Z("iron_sabbath", "town", "epoch_iron", ["Red Furnaces", "Smoky Foundry Street", "The Last Factory", "Evacuation Yard"], BO("The Last Factory Engine"), "iron", boss_poi=2),
 "ACT05_Z06": Z("moonfall_republic", "town", "epoch_moon", ["Silver Rooftops", "Assembly Plaza", "Republic Archive", "Civic Defence Line"], CO("Republic Charter Page", ["Assembly Breaker", "Charter Thief", "The Moonglass Guardian"]), "moon"),
 "ACT05_Z07": Z("orchard_of_lost_children", "between", "between_orchard", ["Floating Houses", "Small Lanterns", "Gentle Grass"], ARR, "court",
                npcs=[N("lys5", "Lys Vael", "mage", (0.92, 0.9, 1.0), "'Every lantern is a child someone forgot. We are cataloguing them, one by one.'")]),
 "ACT05_Z08": Z("court_of_borrowed_faces", "between", "between_mirror", ["Mirrored Galleries", "Mask Market", "Mirror Duel Floor"], BO("The Borrowed Face", R), "court"),
 "ACT05_Z09": Z("the_choirs_deep", "between", "between_choir", ["Violet Abyss", "Resonant Platforms", "Lieutenant's Dais"], BO("Choir Lieutenant Aster", R), "choir"),
 "ACT05_Z10": Z("unbound_causeway", "between", "between_bridges", ["Bridge Fragments", "Anchor Node", "Many-Culture Span"], CO("Anchor Key", ["Bridge Severer", "Drift Wraith", "Span Colossus"]), "court"),
 "ACT05_Z11": Z("crownsfall_of_three_ages", "town", "crownsfall_ages", ["Plaza of Three Versions", "Bell Tower", "Founding Stone"], CO("Layer Record", ["Echo of the First Founder", "Plaza Overlap", "The Bell-Shade"]), "spectral"),
 "ACT05_Z12": Z("the_regents_archive", "dungeon", "royal_archive", ["Royal Library", "Concealed Foundation Records", "King Aldren's Notes"], BO("Coup Captain Hollis", R), "war",
                npcs=[N("maera5", "Regent Maera Ashford", "mage", (0.86, 0.86, 1.0), "'A crown of borrowed stone. I suspected. I did not want to know.'"),
                      N("mira5", "Mira Thorne", "mage", (0.82, 0.84, 1.0), "'The city is layered from forgotten lives. That makes it more ours, not less.'")], turnin="maera5"),
 "ACT05_Z13": Z("hearth_of_names", "between", "between_lantern", ["Keeper Sanctuary", "Warm Lights", "Witness Ledger"], CO("Covenant Seal", ["Choir Raider", "Name-Eater", "Court Seizer"]), "choir",
                npcs=[N("tamsin5", "Tamsin Reed", "mage", (0.86, 0.8, 0.95), "'The Covenant of Names: no record taken without consent.'")], turnin="tamsin5"),
 "ACT05_Z14": Z("riven_royal_court", "between", "between_court", ["Breaking Palace", "Present Streets", "Ceasefire Table"], BO("Queen Ysara", R), "court"),
 "ACT05_Z15": Z("the_anchor_of_kinship", "arena", "anchor", ["Rotating Anchor Ring", "Merged Refuge", "Family's Door"], BO("The Overwrite Surge", S), "continuance",
                epilogue=dict(chapter="ACT V COMPLETE", title="THE UNWRITTEN KINGDOMS", lines=[
                    "History was sacrificed again and again: the Rain Kingdom, the Verdant Empire, the Iron Sabbath, the Moonfall Republic. Crownsfall was assembled from the discards.",
                    "Rowan keeps his name. An independently anchored refuge holds a displaced family without erasing anyone already living.",
                    "Coexistence can be built. Act VI, War Against the Hour, begins in Crownsfall Under Siege."])),
}.items()}
ACT5_EDGES = [("engine_of_first_night", "broken_meridian"), ("broken_meridian", "throne_of_glass"), ("throne_of_glass", "rain_kingdom"), ("throne_of_glass", "verdant_empire"),
  ("throne_of_glass", "iron_sabbath"), ("throne_of_glass", "moonfall_republic"), ("throne_of_glass", "orchard_of_lost_children"), ("orchard_of_lost_children", "court_of_borrowed_faces"),
  ("court_of_borrowed_faces", "the_choirs_deep"), ("the_choirs_deep", "unbound_causeway"), ("unbound_causeway", "crownsfall_of_three_ages"), ("crownsfall_of_three_ages", "the_regents_archive"),
  ("unbound_causeway", "hearth_of_names"), ("hearth_of_names", "riven_royal_court"), ("riven_royal_court", "the_anchor_of_kinship")]

# ---------------------------------------------------------------- Act VI: War Against the Hour (levels 51-60)
ACT6 = {k: _fam(v) for k, v in {
 "ACT06_Z01": Z("crownsfall_under_siege", "town", "siege_city", ["Barricades", "Darkened Fountains", "Civic Shelters", "Garran's Line"], CO("Rescued Family", ["Siege Breacher", "Tear Raider", "The Fountain Horror"]), "war",
                npcs=[N("garran6", "Marshal Garran Holt", "knight", (0.82, 0.86, 1.0), "'Citizens and Unwritten alike. Nobody gets left at the door.'", False)], turnin="garran6", npc_poi=3),
 "ACT06_Z02": Z("greenwood_fracture", "wild", "fracture_forest", ["Summer Side", "Winter Side", "Growth Node", "Root Guardian's Hollow"], BO("The Root Guardian"), "winter", boss_poi=3),
 "ACT06_Z03": Z("bellwater_inundation", "wild", "flood", ["Flooded Mills", "Refugee Rafts", "Valve House", "Returning Tide"], BO("The Returning Tide", S), "rain", boss_poi=3),
 "ACT06_Z04": Z("greywake_armada", "wild", "coast_war", ["Wrecked Harbor", "Ships of Other Epochs", "Beacon Line", "Covenant Port"], BO("Admiral of No Flag", R), "war", boss_poi=1),
 "ACT06_Z05": Z("blackpine_winter", "wild", "winter", ["Summer Camp", "Lethal Frost", "Thermal Node", "Displaced Villagers"], BO("The Winter Elemental"), "winter", boss_poi=2),
 "ACT06_Z06": Z("riftglass_caldera", "wild", "caldera", ["Fractured Quarry", "Molten Violet Crystals", "Conduit Array", "Form Regulator"], BO("The Caldera Construct"), "riftglass", boss_poi=3),
 "ACT06_Z07": Z("veyr_sanctuary", "town", "veyr", ["Phase Shelters", "Shifting Stars", "Observatory Steps"], TALK("meridian6"), "war",
                npcs=[N("meridian6", "Meridian", "mage", (0.74, 0.76, 1.0), "'I concealed the warning. I was wrong. The clock is yours as much as ours.'"),
                      N("iri6", "Iri", "mage", (0.78, 0.8, 1.0), "'Every faction is here. Try to keep them in one room.'", True)]),
 "ACT06_Z08": Z("archive_of_forbidden_futures", "between", "between_futures", ["Unfinished Buildings", "Unrealized Histories", "The Future Never Born"], CO("Forbidden Future Record", ["Variant Horror", "Unborn Sentinel", "Possibility Eater"]), "continuance"),
 "ACT06_Z09": Z("the_sentinels_wall", "wild", "wall", ["Continental Fortification", "Refugee Road", "Repair Pylon", "Boundary Regulator"], BO("The Wall-Breaker"), "war", boss_poi=3),
 "ACT06_Z10": Z("meridians_descent", "dungeon", "vault", ["Silver Machinery", "Dim Lamps", "Meridian's Confession"], BO("The Descent Warden"), "continuance"),
 "ACT06_Z11": Z("the_last_timekeeper", "between", "between_clock", ["Clock Sanctuary", "Fractured Seconds", "Continuity Regulator"], BO("The Last Timekeeper", R), "continuance"),
 "ACT06_Z12": Z("the_choirs_procession", "wild", "choir_march", ["Violet March", "Ruined Town", "Conversion Ring", "Captives' Pen"], BO("Cantor Neral, Ascendant", R), "choir", boss_poi=2),
 "ACT06_Z13": Z("confluence_camp", "town", "camp", ["Allied Encampment", "Banners of Many Epochs", "Council Tent"], TALK("mira6"), "war",
                npcs=[N("mira6", "Mira Thorne", "mage", (0.82, 0.84, 1.0), "'Every faction. One table. Tell them what tomorrow costs.'"),
                      N("bera6", "Bera Flint", "knight", (0.9, 0.86, 0.78), "Quartermaster to the coalition.", True)]),
 "ACT06_Z14": Z("sevenfold_gate", "between", "gate", ["Seven Rotating Bridges", "Measure Plinths", "The Gate Proper"], CO("Regulator Seal", ["Growth Warden", "Flow Warden", "Boundary Warden"]), "continuance"),
 "ACT06_Z15": Z("the_threshold_of_continuance", "arena", "engine_horizon", ["Bronze Horizon", "White Sun", "The Voice"], BO("The Continuance's Herald"), "continuance",
                epilogue=dict(chapter="ACT VI COMPLETE", title="WAR AGAINST THE HOUR", lines=[
                    "The coalition holds. All seven regulator functions answer: Growth, Flow, Passage, Balance, Form, Boundary, Continuity.",
                    "Beyond the bronze horizon, the Continuance speaks: it offers to save the world by ending its history.",
                    "Act VII, Age of the Lost, begins in the First Index."])),
}.items()}
ACT6_EDGES = [("the_anchor_of_kinship", "crownsfall_under_siege"), ("crownsfall_under_siege", "greenwood_fracture"), ("crownsfall_under_siege", "bellwater_inundation"),
  ("bellwater_inundation", "greywake_armada"), ("greenwood_fracture", "blackpine_winter"), ("blackpine_winter", "riftglass_caldera"), ("riftglass_caldera", "veyr_sanctuary"),
  ("veyr_sanctuary", "archive_of_forbidden_futures"), ("veyr_sanctuary", "the_sentinels_wall"), ("veyr_sanctuary", "meridians_descent"), ("meridians_descent", "the_last_timekeeper"),
  ("the_sentinels_wall", "the_choirs_procession"), ("the_choirs_procession", "confluence_camp"), ("confluence_camp", "sevenfold_gate"), ("sevenfold_gate", "the_threshold_of_continuance")]

# ---------------------------------------------------------------- Act VII: Age of the Lost (levels 61-70)
ACT7 = {k: _fam(v) for k, v in {
 "ACT07_Z01": Z("the_first_index", "between", "engine_index", ["Suspended Names", "Index Shelves", "Identity Test"], CO("Recovered Index Entry", ["Index Devourer", "Shelf Warden", "The Name-Collector"]), "continuance"),
 "ACT07_Z02": Z("vault_of_continuity", "between", "engine_rings", ["Interlocking Rings", "White Light", "Makers' Choice"], BO("The Continuity Sentinel"), "continuance"),
 "ACT07_Z03": Z("the_mercy_chamber", "dungeon", "mercy", ["Clinical Halls", "Last Conversation", "Farewell Room"], CO("Memory of Mercy", ["Repeating Orderly", "Mercy Echo", "The Last Patient's Warden"]), "lab"),
 "ACT07_Z04": Z("the_kings_unmaking", "wild", "oris_ruin", ["Oris's Chambers", "Crumbling Capital", "Promise Balcony"], BO("The Memory of Oris", R), "concord_guard", size="S", boss_poi=0),
 "ACT07_Z05": Z("the_remnant_siege", "between", "between_court", ["Central Gate", "Royal Forces", "Ceasefire Line"], BO("The Remnant Vanguard", R), "court"),
 "ACT07_Z06": Z("the_choirs_last_hymn", "between", "between_choir", ["Vibrating Black Glass", "Silence Chamber", "Last Voice"], BO("The Last Voice", R), "choir"),
 "ACT07_Z07": Z("caldrins_vigil", "arena", "cathedral_restored", ["Restored Threshold", "Sanctuary Door", "Vigil Step"], CO("Vigil Watch", ["Erasure Tide", "Door-Breaker Avatar", "The Last Assault"]), "continuance",
                npcs=[N("caldrin7", "Ser Caldrin Vael", "knight", (0.86, 0.9, 1.0), "'I have stood at this door long enough. Let someone open it.'")], turnin="caldrin7"),
 "ACT07_Z08": Z("the_seven_chambers", "dungeon", "engine_rings", ["Growth Cell", "Flow Cell", "Continuity Cell"], CO("Chamber Key", ["Regulator Guardian", "Cell Avatar", "The Seventh Warden"]), "continuance"),
 "ACT07_Z09": Z("the_crown_of_empty_histories", "between", "between_glass", ["Kingdom Models", "Mirrored Champions", "Empty Crown"], BO("The Mirrored Champion", R), "court"),
 "ACT07_Z10": Z("the_unwritten_shore", "between", "shore", ["Sea of Lights", "Refugee Bridges", "Readiness Beacon"], CO("Refugee Escort", ["Shore Devourer", "Light-Eater", "The Tide of Erasure"]), "continuance"),
 "ACT07_Z11": Z("chronicle_heart", "arena", "engine_core", ["Rotating Core", "Reality Seams", "Reset Ring"], BO("The Continuance"), "continuance", boss_tint=(1.0, 0.95, 0.8)),
 "ACT07_Z12": Z("the_last_decision", "arena", "decision", ["Still Chamber", "Three Control Paths"], ARR, "continuance",
                npcs=[N("tamsin7", "Tamsin Reed", "mage", (0.86, 0.8, 0.95), "'A name is not a claim to someone else's home.'"),
                      N("mira7", "Mira Thorne", "mage", (0.82, 0.84, 1.0), "'We can remember what was lost without becoming it.'")]),
 "ACT07_Z13": Z("crownsfall_reborn", "town", "crownsfall_reborn", ["Bluebanner Square Reborn", "New Banners", "Bell Tower"], TALK("mira_r"), "war",
                npcs=[N("mira_r", "Mira Thorne", "mage", (0.82, 0.84, 1.0), "'After the bell. Let's see what kind of city we chose.'"),
                      N("garran_r", "Marshal Garran Holt", "knight", (0.82, 0.86, 1.0), "Keeping order in a changed city.", True)]),
 "ACT07_Z14": Z("the_open_meridian", "wild", "frontier_new", ["Stabilized Crossing", "Expedition Camp", "Bounded Pocket"], ARR, "war"),
 "ACT07_Z15": Z("the_lantern_beyond", "wild", "memorial", ["Memorial Garden", "Caldrin's Ledger", "Distant Horizon"], ARR, "war", size="S",
                epilogue=dict(chapter="AGE OF THE LOST", title="A REMEMBERED NAME", lines=[
                    "Caldrin's ledger rests in a public memorial. The bell rings in Crownsfall.",
                    "The final image is a remembered name, not a reset."])),
}.items()}
ACT7_EDGES = [("the_threshold_of_continuance", "the_first_index"), ("the_first_index", "vault_of_continuity"), ("vault_of_continuity", "the_mercy_chamber"),
  ("vault_of_continuity", "the_kings_unmaking"), ("vault_of_continuity", "the_remnant_siege"), ("the_remnant_siege", "the_choirs_last_hymn"),
  ("the_choirs_last_hymn", "caldrins_vigil"), ("caldrins_vigil", "the_seven_chambers"), ("the_seven_chambers", "the_crown_of_empty_histories"),
  ("the_crown_of_empty_histories", "the_unwritten_shore"), ("the_unwritten_shore", "chronicle_heart"), ("chronicle_heart", "the_last_decision"),
  ("the_last_decision", "crownsfall_reborn"), ("crownsfall_reborn", "the_open_meridian"), ("crownsfall_reborn", "the_lantern_beyond")]
