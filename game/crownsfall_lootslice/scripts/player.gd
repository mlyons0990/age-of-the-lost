extends Node2D
## The knight: movement, combat, skills and progression.
## Left click (or hold) to walk or attack; eight facing directions, the three
## west-facing ones are mirrored from their east-facing sheets.

const Systems := preload("res://scripts/systems.gd")
const Resolver := preload("res://scripts/effect_resolver.gd")
const Projectile := preload("res://scripts/projectile.gd")
const GD := preload("res://scripts/game_data.gd")
const Mastery := preload("res://scripts/mastery_data.gd")
const Aura := preload("res://scripts/aura_controller.gd")
const GROUNDING_METADATA := "res://assets/25d/aotl_class_foot_anchors_v06.json"

const SPEED := 340.0          # pixels per second across the screen
const DEPTH_SQUASH := 0.72    # moving "into" the screen covers less ground
const FRAME := 384            # size of one square frame in the strips
const SPRITE_SCALE := 0.76
const FEET := Vector2(0, 12) # nudges the art so the boots sit on the node origin
const WALK_FPS := 14.0
const ATTACK_FRAME := 512      # attack strips use larger frames so the sword swing fits
const ATTACK_FPS := 28.0
const ATTACK_TIME := 0.5       # how long a swing roots the knight
const HIT_DELAY := 0.2         # the blow lands this long after the swing starts

## Which attack strip to use for each of the 8 facings, and whether to mirror it.
## Only the two diagonal strips exist, so the other facings borrow the nearest one.
const ATTACK_FACINGS := [
	["se", false], ["se", false], ["se", false], ["se", true],
	["se", true], ["ne", true], ["ne", false], ["ne", false],
]

## animation suffix and whether to mirror, for 8 screen directions starting
## at "right" and going clockwise (right, down-right, down, down-left, ...).
const FACINGS := [
	["right", false], ["se", false], ["down", false], ["se", true],
	["right", true], ["ne", true], ["up", false], ["ne", false],
]

var main: Node2D
var sprite: AnimatedSprite2D
## Presentation-only pivot: reactions never displace navigation or interrupt casts.
var visual_root: Node2D
var hurt_visual_left := 0.0
var death_visual_time := -1.0
var visual_class_id := ""
var mage_art_active := false
var visual_cast_time := 0.0
var frame_cache: Dictionary = {}
var foot_anchor_frames: Dictionary = {}
var current_foot_anchor_px := 0.0
var current_sheet_frame_size := FRAME
var shadow: Sprite2D
var path: PackedVector2Array = PackedVector2Array()
var path_index := 0
var facing := 1
var marker: Node2D
var idle_time := 0.0

# ---- progression (saved)
var class_id := "warrior"
var mastery: Dictionary = {}
var crafted_uniques: Array = []
var aura
var combat_epoch := 0
var cast_remaining := 0.0
var cast_definition := {}
var cast_packet := {}
var cast_aim := Vector2.ZERO
var ward_amount := 0.0
var ward_time := 0.0
var last_world_aim := Vector2(1450, 1020)
var hero_name := "Wayfarer"
var level := 1
var xp := 0
var gold := 0
var potions := 3
var kills := 0
var elite_kills := 0
var spec := ""
var adv := ""
var heroic := ""
var gear := {"weapon": null, "offhand": null, "armor": null, "helm": null, "gloves": null, "belt": null, "boots": null, "amulet": null, "ring1": null, "ring2": null}
var inventory: Array = []
var stash: Array = []
var hotbar: Array = ["slash", "cleave", "charge", "rally", ""]
var discoveries: Array = []
var opened_rift := false
var quest := 0

# ---- combat state
var hp := 100.0
var mp := 50.0
var cds := {}       # slot -> seconds left
var cd_full := {}   # slot -> full cooldown, for the HUD sweep
var rally := 0.0
var invuln := 0.0
var attack_anim := 0.0
var lunge := Vector2.ZERO
var last_hurt := -99.0
var clock := 0.0
var dead := false
var target: Node2D = null
var dash := {}
var mouse_held := false
var repath := 0.0
var mana_warn := 0.0
var pending_hit: Callable = Callable()
var pending_t := 0.0
var swinging := 0.0


func _ready() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(GROUNDING_METADATA))
	if parsed is Dictionary: foot_anchor_frames = parsed.get("frames", {})
	aura = Aura.new()
	aura.actor = self
	shadow = Sprite2D.new()
	shadow.texture = _shadow_texture()
	shadow.modulate = Color(0.1, 0.08, 0.2, 0.38)
	shadow.scale = Vector2(1.5, 0.62)
	shadow.z_index = -1
	add_child(shadow)

	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	sprite.offset = Vector2(0, -FRAME / 2.0) + FEET / SPRITE_SCALE
	visual_root = Node2D.new()
	add_child(visual_root)
	visual_root.add_child(sprite)
	refresh_visuals()
	_play("idle")

func refresh_visuals() -> void:
	if sprite == null or visual_class_id == class_id: return
	_reset_visual_feedback()
	visual_class_id = class_id
	mage_art_active = class_id == "mage"
	if mage_art_active:
		for d in ["up", "ne", "right", "se", "down"]:
			for kind in ["walk", "idle", "cast"]:
				if not ResourceLoader.exists("res://assets/mage/%s_%s.png" % [kind, d]): mage_art_active = false
	var key := "mage" if mage_art_active else "warrior"
	if not frame_cache.has(key): frame_cache[key] = _build_frames()
	sprite.stop()
	sprite.sprite_frames = frame_cache[key]
	visual_cast_time = 0
	_play("idle")

func _reset_visual_feedback() -> void:
	hurt_visual_left = 0.0
	death_visual_time = -1.0
	if visual_root != null:
		visual_root.transform = Transform2D.IDENTITY
		visual_root.modulate = Color.WHITE
	if shadow != null: shadow.modulate.a = 0.38
	if sprite != null:
		sprite.scale = Vector2.ONE * SPRITE_SCALE
		sprite.modulate = Color.WHITE

func visual_state() -> String:
	if dead: return "dead"
	if hurt_visual_left > 0: return "hurt"
	if not dash.is_empty(): return "charge"
	if cast_remaining > 0 or visual_cast_time > 0: return "cast"
	if swinging > 0: return "attack"
	if path_index < path.size(): return "walk"
	return "idle"

func _process(delta: float) -> void:
	_advance_visual_feedback(delta)
	_apply_visual_footlock()

func _advance_visual_feedback(delta: float) -> void:
	if visual_root == null: return
	if not dead and death_visual_time >= 0: _reset_visual_feedback()
	visual_root.transform = Transform2D.IDENTITY
	visual_root.modulate = Color.WHITE
	var side := -1.0 if sprite.flip_h else 1.0
	if dead:
		if death_visual_time < 0:
			var f: Array = FACINGS[facing]
			sprite.flip_h = f[1]
			side = -1.0 if sprite.flip_h else 1.0
			sprite.play("idle_" + String(f[0]))
			sprite.pause()
			sprite.scale = Vector2.ONE * SPRITE_SCALE
			death_visual_time = 0.0
		death_visual_time += maxf(0, delta)
		var fall := smoothstep(0.0, 0.45, death_visual_time)
		visual_root.rotation = side * 1.32 * fall
		visual_root.position = Vector2(0, 12 * fall)
		visual_root.scale = Vector2(1, 1 - 0.15 * fall)
		visual_root.modulate = Color.WHITE.lerp(Color(0.48, 0.43, 0.46), fall)
		shadow.modulate.a = lerpf(0.38, 0.2, fall)
		return
	hurt_visual_left = maxf(0, hurt_visual_left - maxf(0, delta))
	if hurt_visual_left > 0:
		var recoil := hurt_visual_left / 0.18
		visual_root.rotation = -side * 0.10 * recoil
		visual_root.position.x = -side * 5 * recoil
		visual_root.modulate = Color.WHITE.lerp(Color(1.35, 0.72, 0.68), recoil)
	elif not dash.is_empty():
		visual_root.rotation = side * 0.16
		visual_root.position.x = side * 7

func _show_cast(windup: float) -> void:
	if not mage_art_active: return
	var f: Array = FACINGS[facing]
	sprite.flip_h = f[1]
	sprite.play("cast_" + String(f[0]))
	sprite.pause()
	sprite.frame = 0
	visual_cast_time = windup + 0.2

func _release_cast_art() -> void:
	if not mage_art_active: return
	var f: Array = FACINGS[facing]
	sprite.flip_h = f[1]
	sprite.play("cast_" + String(f[0]))
	sprite.pause()
	sprite.frame = 1
	visual_cast_time = 0.18


func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var folder := "mage" if mage_art_active else "knight"
	for d in ["up", "ne", "right", "se", "down"]:
		var tex: Texture2D = load("res://assets/%s/walk_%s.png" % [folder, d])
		var count := int(tex.get_width() / float(FRAME))
		var walk: String = "walk_" + d
		sf.add_animation(walk)
		sf.set_animation_speed(walk, 6.0 if mage_art_active else WALK_FPS)
		sf.set_animation_loop(walk, true)
		for i in count:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * FRAME, 0, FRAME, FRAME)
			sf.add_frame(walk, at)
		var idle: String = "idle_" + d
		sf.add_animation(idle)
		sf.set_animation_loop(idle, false)
		var itex: Texture2D = load("res://assets/%s/idle_%s.png" % [folder, d])
		sf.add_frame(idle, itex)
		if mage_art_active:
			var cast: String = "cast_" + String(d)
			sf.add_animation(cast)
			sf.set_animation_loop(cast, false)
			var cast_texture: Texture2D = load("res://assets/mage/cast_%s.png" % d)
			for i in 2:
				var cast_frame := AtlasTexture.new()
				cast_frame.atlas = cast_texture
				cast_frame.region = Rect2(i * FRAME, 0, FRAME, FRAME)
				sf.add_frame(cast, cast_frame)
	for d in ["se", "ne"]:
		var apath := "res://assets/%s/attack_%s.png" % [folder, d]
		if not ResourceLoader.exists(apath):
			continue
		var atex: Texture2D = load(apath)
		var attack: String = "attack_" + d
		sf.add_animation(attack)
		sf.set_animation_speed(attack, ATTACK_FPS)
		sf.set_animation_loop(attack, false)
		for i in int(atex.get_width() / float(ATTACK_FRAME)):
			var at2 := AtlasTexture.new()
			at2.atlas = atex
			at2.region = Rect2(i * ATTACK_FRAME, 0, ATTACK_FRAME, ATTACK_FRAME)
			sf.add_frame(attack, at2)
	return sf


func _apply_visual_footlock() -> void:
	# Read-only rendering offset: the player transform, collisions, hit timing and
	# world-space navigation all remain untouched.
	if sprite == null or sprite.sprite_frames == null: return
	var id := "mage" if mage_art_active else "knight"
	var path := id + "/" + String(sprite.animation) + ".png"
	var metadata: Dictionary = foot_anchor_frames.get(path, {})
	if metadata.is_empty(): return
	var anchors: Array = metadata.get("feet_y", [])
	if anchors.is_empty(): return
	var sheet_size := int(metadata.get("frame_size", FRAME))
	var f := clampi(sprite.frame, 0, anchors.size() - 1)
	current_foot_anchor_px = float(anchors[f])
	current_sheet_frame_size = sheet_size
	# AnimatedSprite2D is centered. Keep estimated boot contact FEET pixels below
	# the authoritative 2D world position even when switching 384->512px sheets.
	sprite.offset = Vector2(0.0, -current_foot_anchor_px + float(sheet_size) * 0.5 + FEET.y / SPRITE_SCALE)


func _shadow_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


func _play(kind: String) -> void:
	if dead or swinging > 0.0 or visual_cast_time > 0:
		return  # let the attack animation finish
	var f: Array = FACINGS[facing]
	var anim: String = kind + "_" + f[0]
	sprite.flip_h = f[1]
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


## Starts the sword swing animation and schedules the blow to land mid-swing.
func _swing(on_hit: Callable) -> void:
	var f: Array = ATTACK_FACINGS[facing]
	var anim: String = "attack_" + String(f[0])
	if not sprite.sprite_frames.has_animation(anim):
		anim = "attack_se"
	if sprite.sprite_frames.has_animation(anim):
		swinging = 0.0
		sprite.flip_h = f[1]
		sprite.play(anim)
		sprite.frame = 0
		_apply_visual_footlock()
		swinging = ATTACK_TIME
		sprite.scale = Vector2.ONE * SPRITE_SCALE
	pending_hit = on_hit
	pending_t = HIT_DELAY


# ---------------------------------------------------------------- stats
func mods() -> Dictionary:
	var m := {"hp": 0.0, "armor": 0.0, "dmg": 0.0, "crit": 0.0, "cdr": 0.0, "spec_dmg": 0.0, "spec_radius": 0.0,
		"lifesteal_mult": 1.0, "burn_mult": 1.0, "rally_heal": 0.0, "spell_dmg": 0.0}
	var sources: Array = []
	if spec != "" and adv != "":
		for a in GD.SPECS[spec]["advanced"]:
			if a["id"] == adv:
				sources.append(a["mods"])
	if heroic != "":
		for h in GD.HEROIC:
			if h["id"] == heroic:
				sources.append(h["mods"])
	for src in sources:
		for k in src:
			if String(k).ends_with("_mult"):
				m[k] = float(m[k]) * float(src[k])
			else:
				m[k] = float(m[k]) + float(src[k])
	return m


func stats() -> Dictionary:
	return Systems.derive(level, gear, mods(), class_id)

func skill_def(slot: String) -> Dictionary:
	var index := ["basic", "s1", "s2", "s3", "s4"].find(slot)
	if index < 0: return {}
	var id := String(hotbar[index])
	return known_definition(id) if GD.unlocked(self, id) else {}

func has_circlet() -> bool:
	return gear.helm is Dictionary and gear.helm.get("unique_id", "") == Systems.UNIQUE_ID

func known_definition(id: String) -> Dictionary:
	return Mastery.definition(GD.spells().get(id, {}), mastery, has_circlet())

func change_mastery(id: String, refund := false) -> Dictionary:
	if dead or main.combat_active(): return {"ok":false,"reason":"Change mastery in town outside combat."}
	var plan: Dictionary = Mastery.refund(mastery,id) if refund else Mastery.invest(mastery,id,class_id,level,discoveries)
	if not plan.ok: return plan
	var error := Mastery.problem(plan.ranks,class_id,level,discoveries)
	if error != "": return {"ok":false,"reason":error}
	if not main.persist_changes({"mastery":plan.ranks}): return {"ok":false,"reason":main.save_error}
	cancel_casts()
	mastery = plan.ranks
	return {"ok":true,"reason":"Mastery updated. Active casts, aura and patches stopped."}

func craft_circlet() -> Dictionary:
	if dead or main.combat_active() or class_id != "mage" or level < 40 or not discoveries.has("first_echo"):
		return {"ok":false,"reason":"Requires Mage level 40, recovered stone memory and a safe town."}
	if crafted_uniques.has(Systems.UNIQUE_ID): return {"ok":false,"reason":"This memory has already been attuned."}
	if gold < 250: return {"ok":false,"reason":"Requires 250 gold."}
	var trial := inventory.duplicate(true)
	if not Systems.insert(trial,Systems.make_unique()): return {"ok":false,"reason":"Make a 2×2 space in the backpack first."}
	var attuned:=crafted_uniques.duplicate(); attuned.append(Systems.UNIQUE_ID)
	if not main.persist_changes({"inventory":trial,"gold":gold-250,"crafted_uniques":attuned}): return {"ok":false,"reason":main.save_error}
	inventory = trial; gold -= 250; crafted_uniques=attuned
	main.sound.play_cue("equip")
	return {"ok":true,"reason":"Emberwake Circlet attuned. Equip it in the head slot."}

func assign_skill(index: int, id: String) -> bool:
	if index < 0 or index >= 5 or not GD.unlocked(self, id): return false
	var next:=hotbar.duplicate()
	var previous := next.find(id)
	if previous >= 0: next[previous] = next[index]
	next[index] = id
	if not main.persist_changes({"hotbar":next}): return false
	hotbar=next
	if not hotbar.has("ashen_ward"): aura.stop("unequipped")
	return true

func preview_equipment(item: Dictionary, slot: String) -> Dictionary:
	if not gear.has(slot) or not Systems.legal_slot(item,slot): return {"ok":false,"reason":"This item does not fit that slot."}
	if not Systems.class_allows(item,class_id): return {"ok":false,"reason":"This item cannot be worn by your class."}
	if int(item.level)>level: return {"ok":false,"reason":"Requires level %d." % int(item.level)}
	var next_gear:=gear.duplicate(true); next_gear[slot]=item.duplicate(true)
	if slot=="weapon" and item.slot=="staff": next_gear.offhand=null
	if not Systems.gear_valid(next_gear,class_id,level): return {"ok":false,"reason":"A staff occupies both hands. Equip a wand before adding a focus."}
	return {"ok":true,"reason":"","gear":next_gear}

func plan_equip(index: int, slot: String) -> Dictionary:
	if index<0 or index>=inventory.size(): return {"ok":false,"reason":"Select a valid backpack item."}
	var item: Dictionary=inventory[index]; var candidate:=preview_equipment(item,slot)
	if not candidate.ok: return candidate
	var trial:=inventory.duplicate(true); trial.remove_at(index)
	if gear[slot] is Dictionary and not Systems.insert(trial,gear[slot].duplicate(true)): return {"ok":false,"reason":"Make room for the currently equipped item."}
	if slot=="weapon" and item.slot=="staff" and gear.offhand is Dictionary:
		if not Systems.insert(trial,gear.offhand.duplicate(true)): return {"ok":false,"reason":"Make room for the displaced offhand as well."}
	return {"ok":true,"reason":"","inventory":trial,"gear":candidate.gear}

func equip_item(index: int, slot: String) -> bool:
	var plan:=plan_equip(index,slot)
	if not plan.ok: return false
	if not main.persist_changes({"inventory":plan.inventory,"gear":plan.gear}): return false
	aura.stop("equipment change"); inventory=plan.inventory; gear=plan.gear
	clamp_resources(); main.sound.play_cue("equip"); return true

func unequip_item(slot: String, at := Vector2i(-1,-1)) -> bool:
	if not gear.get(slot) is Dictionary: return false
	var trial:=inventory.duplicate(true); var item: Dictionary=gear[slot].duplicate(true)
	if at!=Vector2i(-1,-1):
		if not Systems.fits(trial,item,at): return false
		item.x=at.x; item.y=at.y; trial.append(item)
	elif not Systems.insert(trial,item): return false
	var next:=gear.duplicate(true); next[slot]=null
	if not main.persist_changes({"inventory":trial,"gear":next}): return false
	aura.stop("equipment change"); inventory=trial; gear=next
	clamp_resources(); main.sound.play_cue("equip"); return true

func clamp_resources() -> void:
	var s := stats()
	hp = minf(hp, s.max_hp)
	mp = minf(mp, s.max_mp)

func cooldown(slot: String) -> float:
	var sk := skill_def(slot)
	return float(cds.get(sk.get("id", ""), 0.0))


func fx_colors() -> Array:
	if spec == "":
		return [Color("eee2ff"), Color("ad86ff")] if class_id == "mage" else [Color("e6eeff"), Color("8fb0ff")]
	var f: Array = GD.SPECS[spec]["fx"]
	return [Color(String(f[0])), Color(String(f[1]))]


func title() -> String:
	if spec == "":
		return GD.CLASSES[class_id].name
	var s: Dictionary = GD.SPECS[spec]
	var n: String = s["name"] + (" Mage" if class_id == "mage" else "")
	if adv != "":
		for a in s["advanced"]:
			if a["id"] == adv:
				n = String(a["name"])
	return n


# ---------------------------------------------------------------- combat
func heal(v: float, quiet := false) -> void:
	var before := hp
	hp = minf(float(stats().max_hp), hp + maxf(0, v))
	if not quiet and hp - before >= 1:
		main.fx_text.text(position, "+%d" % int(round(hp - before)), Color("7dff8a"))

func hurt(amount: float, src_level: int) -> void:
	if invuln > 0 or dead: return
	var s := stats()
	var reduction: float = s.armor / (s.armor + 40.0 + 12.0 * src_level)
	var incoming := maxf(1, round(amount * (1 - reduction) * randf_range(0.9, 1.1)))
	var absorbed := minf(ward_amount, incoming) if ward_time > 0 else 0.0
	ward_amount -= absorbed
	incoming -= absorbed
	last_hurt = clock
	if absorbed > 0: main.fx_text.text(position, "Ward %d" % absorbed, Color("ffc58b"))
	if incoming > 0:
		hp = maxf(0, hp - incoming)
		hurt_visual_left = 0.18
		main.hurt_flash = 0.35
		main.shake = maxf(main.shake, 4)
		main.fx_text.text(position, "-%d" % incoming, Color("ff5a5a"))
	if hp <= 0:
		dead = true
		cancel_casts()
		path = PackedVector2Array(); target = null
		main.on_player_died()

func cancel_casts() -> void:
	combat_epoch += 1
	if aura != null: aura.stop("cancelled")
	visual_cast_time = 0
	pending_t = 0; pending_hit = Callable(); swinging = 0; cast_remaining = 0
	cast_definition.clear(); cast_packet.clear(); dash.clear()
	ward_time = 0; ward_amount = 0

func damage_multiplier(sk: Dictionary) -> float:
	var result := 1.3 if rally > 0 else 1.0
	if spec != "" and GD.SPECS.has(spec) and sk.id == GD.SPECS[spec].skill.id:
		result *= 1 + float(mods().spec_dmg)
	return result

func make_packet(sk: Dictionary) -> Dictionary:
	var packet := Resolver.snapshot(sk, stats(), damage_multiplier(sk))
	packet["epoch"] = combat_epoch
	return packet

func apply_packet(enemy: Node2D, packet: Dictionary, options: Dictionary = {}) -> float:
	if not is_instance_valid(enemy) or enemy.dead_t >= 0 or dead or int(packet.get("epoch", -1)) != combat_epoch: return 0.0
	var was_burning: bool = enemy.burn > 0
	var result := Resolver.resolve(packet, randf_range(0.9, 1.1), randf())
	var opt := {"kb": packet.kb, "stun": packet.stun, "colors": fx_colors()}
	opt.merge(options, true)
	var actual: float = enemy.take_hit(result.damage, result.crit, position, opt)
	if actual <= 0: return 0.0
	aura.on_damage(enemy,actual,packet)
	if packet.mana_gain > 0 and not packet.rewarded:
		packet.rewarded = true
		mp = minf(float(stats().max_mp), mp + float(packet.mana_gain))
	if packet.slow > 0:
		enemy.slow_time = maxf(enemy.slow_time, packet.slow_duration)
		enemy.slow_factor = minf(enemy.slow_factor, 1 - float(packet.slow))
	if packet.is_frost_stitch:
		if clock <= enemy.frost_until:
			enemy.stun = maxf(enemy.stun, 0.35 if enemy.elite else 0.75)
			enemy.frost_until = -1
		else: enemy.frost_until = clock + 6.0
	if result.burn_dps > 0:
		if enemy.burn <= 0 or result.burn_dps >= enemy.burn_dps:
			enemy.burn = packet.burn_duration
			enemy.burn_dps = result.burn_dps
			enemy.burn_tick = 0
	if enemy.hp <= 0: main.kill_enemy(enemy,{"origin":packet.get("origin","primary"),"proc_depth":packet.get("proc_depth",0),"was_burning":was_burning})
	return actual

func damage_enemy(enemy: Node2D, base: float, options: Dictionary = {}) -> void:
	# Compatibility adapter for any inherited debug tools. Normal casts use packets.
	var packet := make_packet({"id": "legacy_hit", "dmg": 1.0})
	packet.direct = base
	apply_packet(enemy, packet, options)

func ability_power(sk: Dictionary) -> float:
	return float(stats().spell_power if sk.get("scaling", "weapon") == "spell" else stats().dmg)

func _hit_packet_arc(origin: Vector2, radius: float, arc: float, angle: float, packet: Dictionary, options: Dictionary = {}) -> int:
	var count := 0
	for enemy in main.enemies.duplicate():
		if not is_instance_valid(enemy) or enemy.dead_t >= 0: continue
		var gv := GD.ground(origin, enemy.position)
		if gv.length() > radius + enemy.rad: continue
		if gv.length() > 0.5 and absf(angle_difference(gv.angle(), angle)) > arc / 2: continue
		apply_packet(enemy, packet, options); count += 1
	return count

func _validated_aim(sk: Dictionary, aim: Vector2) -> Dictionary:
	var gv := GD.ground(position, aim)
	var kind: String = sk.type
	if kind in ["projectile", "dash"] and gv.length() < 0.05: return {}
	if kind in ["ground", "blink"]:
		var reach := minf(gv.length(), float(sk.get("range", 7.0)))
		var at := position + GD.to_px(gv.normalized() * reach)
		var closest := NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, at)
		if closest.distance_to(at) > 7: return {}
		return {"at": closest}
	return {"at": aim}

func use_skill(slot: String, aim: Vector2) -> bool:
	refresh_visuals()
	if dead or get_tree().paused: return false
	var sk := skill_def(slot)
	if sk.get("type", "") == "aura" and aura.running: aura.stop("toggle"); return true
	if swinging > 0 or pending_t > 0 or cast_remaining > 0 or attack_anim > 0.05 or not dash.is_empty(): return false
	if sk.is_empty() or not sk.type in ["melee", "arc", "dash", "buff", "nova", "cone", "ground", "projectile", "blink", "ward", "aura"]: return false
	if float(cds.get(sk.id, 0)) > 0: return false
	var validated := _validated_aim(sk, aim)
	if validated.is_empty():
		main.hud.toast("Choose a valid point on the floor.", Color("b3c4dc"), true)
		return false
	var s := stats()
	var cost := maxf(0, float(sk.mana))
	if mp < cost:
		if mana_warn <= 0:
			mana_warn = 1.0; main.hud.toast("Not enough mana", Color("8fb0ff"), true)
		return false
	mp -= cost
	main.sound.play_cue(sk.id)
	var full := float(sk.cd) * (1 - clampf(float(s.m.cdr), 0, 0.6))
	cds[sk.id] = full; cd_full[sk.id] = full
	var packet := make_packet(sk)
	var target_point: Vector2 = validated.at
	_face(target_point - position)
	last_world_aim = target_point
	attack_anim = float(sk.get("recovery", 0.22))
	path = PackedVector2Array()
	var windup := float(sk.get("cast_time", 0))
	_show_cast(windup)
	if windup > 0:
		cast_remaining = windup
		cast_definition = sk.duplicate(true)
		cast_packet = packet
		cast_aim = target_point
		main.fx_ground.ring(position, 0.3, 0.9, windup, Color(String(sk.get("color", "bca2ff"))))
	else: _execute_skill(sk, target_point, packet)
	return true

func _execute_skill(sk: Dictionary, aim: Vector2, packet: Dictionary) -> void:
	if dead or int(packet.epoch) != combat_epoch: return
	_release_cast_art()
	var gv := GD.ground(position, aim)
	var angle := gv.angle()
	var colors := fx_colors()
	var c1: Color = colors[0]; var c2: Color = colors[1]
	if sk.has("color"): c2 = Color(String(sk.color))
	match String(sk.type):
		"aura":
			ward_amount = 0; ward_time = 0
			aura.start(sk,packet)
		"melee", "arc":
			attack_anim = ATTACK_TIME
			_swing(func() -> void:
				main.fx_ground.slash(position, angle, sk.range, sk.arc, 0.25, c2, 0.65 if sk.type == "arc" else 0.35)
				if _hit_packet_arc(position, sk.range, sk.arc, angle, packet, {"kb": 0.3 if sk.type == "arc" else 0.15}) > 0: main.shake = maxf(main.shake, 3))
		"projectile":
			var projectile := Projectile.new()
			projectile.setup(self, sk, packet, aim)
			main.add_child(projectile)
		"blink":
			var before := position
			position = aim
			target = null
			main.fx_ground.ring(before, 0.8, 0.1, 0.35, Color("ad86ff"))
			main.fx_ground.ring(position, 0.1, 1.0, 0.4, Color("e0ceff"))
			main.fx_parts.burst(position, 20, [Color("ad86ff"), Color.WHITE], 3.0, 70.0)
		"ward":
			ward_amount = Resolver.ward_capacity(sk, stats())
			ward_time = float(sk.duration)
			main.fx_ground.ring(position, 0.2, 1.0, 0.45, Color("ffc58b"))
		"dash":
			dash = {"dir": gv.normalized(), "left": clampf(gv.length(), 1.5, sk.range), "hit": [], "packet": packet}
			invuln = 0.35; target = null
		"buff":
			heal(float(stats().max_hp) * (float(sk.heal) + float(stats().m.rally_heal)))
			rally = sk.duration
			main.fx_ground.ring(position, 0.3, 3.2, 0.6, c1)
			main.fx_ground.pillar(position, 0.8, c1)
		"nova":
			var radius := float(sk.radius) * (1 + (float(stats().m.spec_radius) if spec != "" and sk.id == GD.SPECS[spec].skill.id else 0.0))
			main.fx_ground.ring(position, 0.3, radius, 0.45, c2, true)
			var count := _hit_packet_arc(position, radius, TAU + 0.1, angle, packet, {"kb": 0.5})
			if count > 0 and sk.has("heal_per_hit"): heal(float(stats().max_hp) * sk.heal_per_hit * count)
			main.shake = maxf(main.shake, 4)
		"cone":
			for i in 60:
				var a := angle + randf_range(-0.5, 0.5) * float(sk.arc)
				main.fx_parts.spark(position, Vector2(cos(a), sin(a)) * randf_range(4, 11), 85, randf_range(-20, 80), 0, randf_range(0.3, 0.55), Color("ff9d55"), randf_range(5, 12), 1.6)
			_hit_packet_arc(position, sk.range, sk.arc, angle, packet, {"kb": 0.2, "colors": [Color("ffd5a0"), Color("ff8e55")]})
		"ground":
			main.fx_ground.hammer(aim, sk.radius, sk.delay, c1, c2, func() -> void:
				if dead or int(packet.epoch) != combat_epoch: return
				_hit_packet_arc(aim, sk.radius, TAU + 0.1, 0, packet, {"kb": 0.5})
				main.fx_parts.burst(aim, 40, [c1, c2, Color.WHITE], 5.0, 15.0, 8.0)
				main.shake = maxf(main.shake, 6))

func primary_reach() -> float:
	var sk := skill_def("basic")
	if sk.is_empty() or sk.type in ["buff", "ward", "nova", "aura"]: return 0.0
	return float(sk.get("range", 1.5))

func _draw() -> void:
	if aura != null and aura.running:
		var radius := float(aura.skill.radius) * GD.U
		draw_set_transform(Vector2.ZERO,0,Vector2(1,0.72))
		draw_arc(Vector2.ZERO,radius,0,TAU,64,Color(1,0.48,0.2,0.65),3,true)
		draw_circle(Vector2.ZERO,radius,Color(1,0.3,0.1,0.04))
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if ward_time > 0 and ward_amount > 0:
		draw_arc(Vector2(0, -100), 62, 0, TAU, 48, Color("ffc58b"), 3, true)
		draw_circle(Vector2(0, -100), 61, Color(1, 0.65, 0.3, 0.08))
	if cast_remaining > 0:
		draw_set_transform(Vector2.ZERO, clock * 2, Vector2(1, 0.72))
		draw_arc(Vector2.ZERO, 42, 0, TAU, 40, Color("c8a8ff"), 3, true)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func drink_potion() -> void:
	if dead:
		return
	if potions <= 0:
		main.hud.toast("No potions", Color.WHITE, true)
		return
	var max_hp: float = stats()["max_hp"]
	if hp >= max_hp:
		return
	potions -= 1
	main.sound.play_cue("potion")
	heal(max_hp * 0.45)
	main.fx_parts.burst(position, 14, [Color("ff8a8a"), Color.WHITE], 2.0, 80.0)


func gain_xp(v: int) -> void:
	if level >= GD.MAX_LEVEL:
		return
	xp += v
	while level < GD.MAX_LEVEL and xp >= GD.xp_need(level):
		xp -= GD.xp_need(level)
		level_up()
	if level >= GD.MAX_LEVEL:
		xp = 0


func level_up() -> void:
	if level >= GD.MAX_LEVEL:
		return
	level += 1
	var s := stats()
	hp = s["max_hp"]
	mp = s["max_mp"]
	main.on_level_up()


func respawn(at: Vector2) -> void:
	cancel_casts()
	dead = false
	_reset_visual_feedback()
	_play("idle")
	pending_t = 0.0
	pending_hit = Callable()
	dash = {}
	swinging = 0.0
	var s := stats()
	hp = s["max_hp"]
	mp = s["max_mp"]
	position = at
	path = PackedVector2Array()
	target = null
	invuln = 2.0


# ---------------------------------------------------------------- input and movement
func _unhandled_input(event: InputEvent) -> void:
	if dead or get_tree().paused:
		return
	if event is InputEventMouseMotion and get_viewport().gui_get_hovered_control() == null:
		last_world_aim = get_global_mouse_position()
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			mouse_held = mb.pressed
			if mb.pressed:
				var at := get_global_mouse_position()
				var e: Node2D = main.pick_enemy(at)
				if e != null:
					target = e
					path = PackedVector2Array()
				elif mb.shift_pressed:
					use_skill("basic", at)
				else:
					target = null
					_walk_to(at, true)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			use_skill("s1", get_global_mouse_position())
	elif event is InputEventKey and event.pressed and not event.echo:
		var at2 := get_global_mouse_position()
		match (event as InputEventKey).keycode:
			KEY_1:
				use_skill("s1", at2)
			KEY_2:
				use_skill("s2", at2)
			KEY_3:
				use_skill("s3", at2)
			KEY_4:
				use_skill("s4", at2)
			KEY_Q:
				drink_potion()


func _walk_to(goal_px: Vector2, show_marker: bool) -> void:
	var map := get_world_2d().navigation_map
	var goal := NavigationServer2D.map_get_closest_point(map, goal_px)
	var start := NavigationServer2D.map_get_closest_point(map, global_position)
	var p := NavigationServer2D.map_get_path(map, start, goal, true)
	if p.size() < 2:
		return
	path = p
	path_index = 1
	if show_marker:
		_show_marker(goal)


func _physics_process(delta: float) -> void:
	refresh_visuals()
	visual_cast_time = maxf(0, visual_cast_time - delta)
	clock += delta
	queue_redraw()
	ward_time = maxf(0, ward_time - delta)
	if ward_time <= 0: ward_amount = 0
	if cast_remaining > 0:
		cast_remaining -= delta
		if cast_remaining <= 0:
			var release := cast_definition.duplicate(true)
			var packet := cast_packet
			cast_definition = {}; cast_packet = {}
			_execute_skill(release, cast_aim, packet)
	for k in cds.keys():
		cds[k] = maxf(0.0, float(cds[k]) - delta)
	rally = maxf(0.0, rally - delta)
	invuln = maxf(0.0, invuln - delta)
	attack_anim = maxf(0.0, attack_anim - delta)
	mana_warn = maxf(0.0, mana_warn - delta)
	swinging = maxf(0.0, swinging - delta)
	if pending_t > 0.0:
		pending_t -= delta
		if pending_t <= 0.0 and pending_hit.is_valid() and not dead:
			pending_hit.call()
			pending_hit = Callable()
	sprite.modulate.a = 0.6 if (invuln > 0.0 and dash.is_empty() and int(clock * 20.0) % 2 == 1) else 1.0
	if dead:
		swinging = 0.0
		pending_t = 0.0
		_play("idle")
		return
	var s := stats()
	var regen_multiplier: float = float(aura.skill.get("regen_multiplier",1)) if aura.running else 1.0
	mp = minf(float(s["max_mp"]), mp + float(s["mana_regen"]) * regen_multiplier * delta)
	aura.advance(delta)
	hp = minf(float(s["max_hp"]), hp + float(s["max_hp"]) * (0.012 if clock - last_hurt > 4.0 else 0.002) * delta)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or get_viewport().gui_get_hovered_control() != null:
		mouse_held = false

	# Shield Charge
	if not dash.is_empty():
		var step: float = minf(float(dash["left"]), 16.0 * delta)
		var dir: Vector2 = dash["dir"]
		var np := position + GD.to_px(dir * step)
		var cp := NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, np)
		if cp.distance_to(np) < 6.0:
			position = np
			dash["left"] = float(dash["left"]) - step
		else:
			dash["left"] = 0.0
		main.fx_parts.spark(position, Vector2.ZERO, randf_range(20, 120), 0.0, 0.0, 0.3, fx_colors()[1], 9.0)
		var hit: Array = dash["hit"]
		for e in main.enemies.duplicate():
			if e.dead_t < 0.0 and not hit.has(e) and GD.gdist(position, e.position) < 1.1 + e.rad:
				hit.append(e)
				apply_packet(e, dash["packet"], {"kb": 0.8, "stun": 1.0, "colors": fx_colors()})
		if float(dash["left"]) <= 0.0:
			dash = {}
			main.shake = maxf(main.shake, 5.0)
			main.fx_ground.ring(position, 0.2, 1.8, 0.3, fx_colors()[0])
		_play("walk")
		return

	# Chasing and attacking a clicked enemy
	if target != null:
		if not is_instance_valid(target) or target.dead_t >= 0.0:
			target = null
			if mouse_held:
				target = main.pick_enemy(get_global_mouse_position())
		else:
			var primary := skill_def("basic")
			if primary.is_empty():
				target = null
				return
			if primary.type in ["ward", "buff", "nova", "aura"]:
				use_skill("basic", position)
				target = null
				return
			var reach: float = primary_reach() + target.rad - 0.15
			if GD.gdist(position, target.position) <= reach:
				path = PackedVector2Array()
				if cooldown("basic") <= 0.0:
					use_skill("basic", target.position)
				else:
					_face(target.position - position)
				if not mouse_held and attack_anim <= 0.0 and cooldown("basic") > 0.0:
					pass  # keep the target until it dies or the player clicks elsewhere
			else:
				repath -= delta
				if repath <= 0.0 or path_index >= path.size():
					repath = 0.25
					_walk_to(target.position, false)
	elif mouse_held:
		# Holding the button keeps steering toward the cursor, as in other ARPGs.
		if Input.is_key_pressed(KEY_SHIFT):
			use_skill("basic", get_global_mouse_position())
			path = PackedVector2Array()
		elif Engine.get_physics_frames() % 6 == 0:
			_walk_to(get_global_mouse_position(), false)

	if path_index >= path.size() or attack_anim > 0.05 or cast_remaining > 0:
		_play("idle")
		idle_time += delta
		if swinging <= 0.0:
			sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE * (1.0 + 0.008 * sin(idle_time * 2.2)))
		return

	idle_time = 0.0
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	var remaining := SPEED * delta
	while remaining > 0.0 and path_index < path.size():
		var to: Vector2 = path[path_index] - global_position
		# Convert the on-screen offset into "ground" distance.
		var ground := Vector2(to.x, to.y / DEPTH_SQUASH)
		var dist := ground.length()
		if dist < 0.5:
			path_index += 1
			continue
		_face(to)
		if dist <= remaining:
			global_position = path[path_index]
			path_index += 1
			remaining -= dist
		else:
			var step2 := ground / dist * remaining
			global_position += Vector2(step2.x, step2.y * DEPTH_SQUASH)
			remaining = 0.0
	_play("walk" if path_index < path.size() else "idle")


func _face(dir: Vector2) -> void:
	if dir.length() < 1.0:
		return
	var a := Vector2(dir.x, dir.y / DEPTH_SQUASH).angle()
	facing = posmod(int(round(a / (PI / 4.0))), 8)


func _show_marker(at: Vector2) -> void:
	if marker and is_instance_valid(marker):
		marker.queue_free()
	marker = ClickMarker.new()
	marker.global_position = at
	get_parent().get_parent().add_child(marker)


class ClickMarker extends Node2D:
	var t := 0.0
	func _ready() -> void:
		z_index = -5
	func _process(delta: float) -> void:
		t += delta
		if t > 0.6:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var k := t / 0.6
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		draw_arc(Vector2.ZERO, 14.0 + 26.0 * k, 0.0, TAU, 40, Color(1.0, 0.86, 0.4, 1.0 - k), 4.0, true)
		draw_arc(Vector2.ZERO, 6.0 + 10.0 * k, 0.0, TAU, 24, Color(1, 1, 1, 0.8 * (1.0 - k)), 2.0, true)
