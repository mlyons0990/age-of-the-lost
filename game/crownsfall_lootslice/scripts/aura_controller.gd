extends RefCounted
## Stateful paid aura and bounded secondary effects. Driven by actor physics.
const GD := preload("res://scripts/game_data.gd")
var actor: Node2D
var running := false
var elapsed := 0.0
var skill: Dictionary = {}
var packet: Dictionary = {}
var patches: Array[Dictionary] = []
var healing: Array[Dictionary] = []
var paid_pulses := 0
var last_stop := ""

func start(definition: Dictionary, snapshot: Dictionary) -> void:
	stop("restart")
	skill = definition.duplicate(true)
	packet = snapshot.duplicate(true)
	packet.origin = "ember_aura"; packet.proc_depth = 0
	packet.mana_gain = 0; packet.rewarded = true; packet.burn_dps = 0
	running = true; last_stop = ""; paid_pulses = 0
	actor.queue_redraw()

func stop(reason := "toggle") -> void:
	running = false; elapsed = 0; patches.clear(); last_stop = reason
	if is_instance_valid(actor): actor.queue_redraw()

func advance(delta: float) -> void:
	if not running: return
	if actor.dead: stop("death"); return
	if delta > 4.0: stop("simulation interrupted"); return
	_advance_patches(delta)
	elapsed += maxf(0, delta)
	while running and elapsed >= float(skill.pulse_interval) - 0.000001:
		elapsed = maxf(0, elapsed - float(skill.pulse_interval))
		if actor.mp + 0.000001 < float(skill.pulse_cost): stop("insufficient mana"); break
		actor.mp = maxf(0, actor.mp - float(skill.pulse_cost))
		paid_pulses += 1
		actor.main.fx_ground.ring(actor.position, float(skill.radius) * 0.85, float(skill.radius), 0.25, Color("ffad64"),false,0.035)
		for target in actor.main.enemies.duplicate():
			if not is_instance_valid(target) or target.dead_t >= 0: continue
			if GD.ground(actor.position, target.position).length() <= float(skill.radius) + float(target.rad):
				actor.apply_packet(target, packet)

func on_damage(target: Node2D, actual: float, source: Dictionary) -> void:
	if not running or actual <= 0 or source.get("origin", "") != "ember_aura" or int(source.get("proc_depth", 0)) != 0: return
	if float(skill.get("burn_extension",0)) > 0 and target.hp > 0 and target.burn > 0:
		target.burn = maxf(target.burn,minf(4.0, target.burn + float(skill.burn_extension)))
	if not actor.mastery.has("siphon_embers"): return
	var recent := 0.0
	for i in range(healing.size()-1,-1,-1):
		if actor.clock - float(healing[i].at) >= 1.0: healing.remove_at(i)
		else: recent += float(healing[i].amount)
	var budget := maxf(0, float(actor.stats().max_hp) * 0.03 - recent)
	var before: float = actor.hp
	actor.heal(minf(actual * 0.02, budget))
	var restored: float = actor.hp - before
	if restored > 0: healing.append({"at":actor.clock,"amount":restored})

func on_kill(target: Node2D, context: Dictionary) -> void:
	if not running or not actor.mastery.has("cinder_bloom") or not bool(context.get("was_burning", target.burn > 0)): return
	if int(context.get("proc_depth",0)) != 0 or context.get("origin", "") == "cinder_patch" or patches.size() >= 8: return
	for patch in patches:
		if GD.ground(patch.at, target.position).length() < 2.0: return
	var secondary := packet.duplicate(true)
	var multiplier := float(packet.direct) / maxf(0.00001, float(packet.power) * float(skill.dmg))
	secondary.direct = float(packet.power) * 0.075 * multiplier
	secondary.origin = "cinder_patch"; secondary.proc_depth = 1; secondary.crit_chance = 0.0
	patches.append({"at":target.position,"left":1.0,"tick":0.0,"packet":secondary})
	actor.main.fx_ground.ring(target.position,1.0,1.0,1.0,Color("ff874c"),false,0.04)

func _advance_patches(delta: float) -> void:
	for i in range(patches.size()-1,-1,-1):
		var patch := patches[i]
		var active := minf(delta,float(patch.left))
		patch.left = maxf(0,float(patch.left)-active); patch.tick = float(patch.tick)+active
		while float(patch.tick) >= 0.5 - 0.000001:
			patch.tick = maxf(0,float(patch.tick)-0.5)
			for target in actor.main.enemies.duplicate():
				if is_instance_valid(target) and target.dead_t < 0 and GD.ground(patch.at,target.position).length() <= 1.0 + float(target.rad):
					actor.apply_packet(target,patch.packet)
					# A terminal encounter kill cancels the aura and clears patches.
					if not running: return
		if float(patch.left) <= 0.000001: patches.remove_at(i)
