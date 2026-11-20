extends RefCounted
## Rebindable controls for the ARPG labs, modelled on Diablo 4 (Options > Controls > Key Bindings: a primary and a
## secondary bind per action, any skill slot on any key, a "combine move / interact / basic attack" toggle, saved
## layouts) and Path of Exile (Options > Input: LMB/RMB/MMB + Q W E R T skill slots, flasks on 1-5, any key or
## mouse button bindable).
##
## Every action holds up to two binds (keyboard keys, optionally with modifiers, or mouse buttons). Binding a key that
## another action already uses steals it from that action (the other action loses only that bind). Saved to
## user://aotl_keybinds.cfg; `reset_defaults()` restores the defaults below.

const SAVE_PATH := "user://aotl_keybinds.cfg"

## action id -> [label, default primary, default secondary]. Bind spec: "key:Q", "key:Ctrl+Q", "mouse:1" (LMB) ...
const ACTIONS := [
	["move", "Move / Interact / Primary Attack", "mouse:1", ""],
	["force_stand", "Attack in Place (hold)", "key:Shift", ""],
	["skill_1", "Skill Slot 1", "key:Q", ""],
	["skill_2", "Skill Slot 2", "key:W", ""],
	["skill_3", "Skill Slot 3", "key:E", ""],
	["skill_4", "Skill Slot 4", "key:R", ""],
	["skill_5", "Skill Slot 5", "key:T", ""],
	["potion_1", "Potion Slot 1", "key:1", ""],
	["potion_2", "Potion Slot 2", "key:2", ""],
	["potion_3", "Potion Slot 3", "key:3", ""],
	["potion_4", "Potion Slot 4", "key:4", ""],
	["potion_5", "Potion Slot 5", "key:5", ""],
	["dodge", "Dodge Roll", "key:Space", ""],
	["keybinds", "Open Key Bindings", "key:F1", ""],
]

var binds := {}          # action -> [spec0, spec1]
var combine_move_attack := true   # Diablo 4 "Combine Move/Interact/Basic Skill": LMB on an enemy attacks it
var changed_listeners: Array[Callable] = []

func _init() -> void:
	reset_defaults(false)
	load_from_disk()

func reset_defaults(save := true) -> void:
	binds.clear()
	for a in ACTIONS:
		binds[a[0]] = [a[2], a[3]]
	combine_move_attack = true
	if save:
		save_to_disk()
	_notify()

func label_of(action: String) -> String:
	for a in ACTIONS:
		if a[0] == action:
			return a[1]
	return action

# ---------- specs <-> events ----------

static func spec_from_event(e: InputEvent) -> String:
	if e is InputEventKey:
		var k := e as InputEventKey
		var code: Key = k.physical_keycode if k.keycode == KEY_NONE else k.keycode
		if code in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			return "key:" + OS.get_keycode_string(code)
		var mods := ""
		if k.ctrl_pressed: mods += "Ctrl+"
		if k.alt_pressed: mods += "Alt+"
		if k.shift_pressed: mods += "Shift+"
		return "key:" + mods + OS.get_keycode_string(code)
	if e is InputEventMouseButton:
		return "mouse:%d" % (e as InputEventMouseButton).button_index
	return ""

static func _parse_key(spec_body: String) -> Dictionary:
	var parts := spec_body.split("+")
	var d := {"ctrl": false, "alt": false, "shift": false, "code": KEY_NONE}
	for i in parts.size():
		var p := parts[i]
		if i < parts.size() - 1:
			d[p.to_lower()] = true
		else:
			d["code"] = OS.find_keycode_from_string(p)
	return d

## Short label for the HUD key plate (e.g. "Q", "LMB", "C+Q").
static func short_label(spec: String) -> String:
	if spec == "":
		return ""
	if spec.begins_with("mouse:"):
		match int(spec.substr(6)):
			1: return "LMB"
			2: return "RMB"
			3: return "MMB"
			4: return "WhUp"
			5: return "WhDn"
			8: return "M4"
			9: return "M5"
		return "M" + spec.substr(6)
	var body := spec.substr(4)
	body = body.replace("Ctrl+", "C+").replace("Alt+", "A+").replace("Shift+", "S+")
	return body.replace("Space", "Spc")

## Does this input event press the bind `spec`? Modifier binds match the modifier key itself.
static func event_matches(e: InputEvent, spec: String) -> bool:
	if spec == "" or not e.is_pressed() or e.is_echo():
		return false
	if spec.begins_with("mouse:"):
		return e is InputEventMouseButton and (e as InputEventMouseButton).button_index == int(spec.substr(6))
	if not (e is InputEventKey):
		return false
	var k := e as InputEventKey
	var code: Key = k.physical_keycode if k.keycode == KEY_NONE else k.keycode
	var d := _parse_key(spec.substr(4))
	if d["code"] in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
		return code == d["code"]
	return code == d["code"] and k.ctrl_pressed == d["ctrl"] and k.alt_pressed == d["alt"] and (not d["shift"] or k.shift_pressed)

## Is the bind currently held down (for hold actions such as Attack in Place)?
static func spec_held(spec: String) -> bool:
	if spec == "":
		return false
	if spec.begins_with("mouse:"):
		return Input.is_mouse_button_pressed(int(spec.substr(6)) as MouseButton)
	var d := _parse_key(spec.substr(4))
	return Input.is_key_pressed(d["code"])

# ---------- queries ----------

func action_for_event(e: InputEvent) -> String:
	for a in ACTIONS:
		for spec in binds[a[0]]:
			if event_matches(e, spec):
				return a[0]
	return ""

func held(action: String) -> bool:
	for spec in binds.get(action, []):
		if spec_held(spec):
			return true
	return false

func key_label(action: String) -> String:
	var b: Array = binds.get(action, ["", ""])
	return short_label(b[0] if b[0] != "" else b[1])

# ---------- editing ----------

## Bind `spec` to `action` in slot 0 (primary) or 1 (secondary). Returns the action it was stolen from, or "".
func bind(action: String, slot: int, spec: String) -> String:
	var stolen := ""
	if spec != "":
		for a in binds.keys():
			for i in 2:
				if binds[a][i] == spec and not (a == action and i == slot):
					binds[a][i] = ""
					stolen = a
	binds[action][slot] = spec
	save_to_disk()
	_notify()
	return stolen

func clear(action: String, slot: int) -> void:
	binds[action][slot] = ""
	save_to_disk()
	_notify()

func _notify() -> void:
	for c in changed_listeners:
		if c.is_valid():
			c.call()

# ---------- persistence ----------

func save_to_disk() -> void:
	var cf := ConfigFile.new()
	for a in binds.keys():
		cf.set_value("binds", a, binds[a])
	cf.set_value("options", "combine_move_attack", combine_move_attack)
	cf.save(SAVE_PATH)

func load_from_disk() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	for a in binds.keys():
		var v = cf.get_value("binds", a, binds[a])
		if v is Array and v.size() == 2:
			binds[a] = [str(v[0]), str(v[1])]
	combine_move_attack = bool(cf.get_value("options", "combine_move_attack", true))
