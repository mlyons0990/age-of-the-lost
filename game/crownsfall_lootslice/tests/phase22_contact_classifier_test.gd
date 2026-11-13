extends SceneTree
const C := preload("res://scripts/three_d/phase22_contact_classifier.gd")
var checks := 0
var failures := 0
func _initialize() -> void:
    call_deferred("run_checks")
func expect(condition: bool, description: String) -> void:
    if not condition:
        failures += 1
        push_error("PHASE22 FAILED: " + description)
    else:
        checks += 1
func tick(state: Dictionary, h: float, vel: Vector3, speed: float = 3.0,
        ground: bool = true, normal: Vector3 = Vector3.UP, moving: bool = true, error: float = 0.02, dt: float = 0.02) -> Dictionary:
    return C.decide(state,dt,h,ground,normal,vel,Vector3.FORWARD,speed,moving,error)
func run_checks() -> void:
    var s := C.fresh()
    expect(not s.planted,"initial swing")
    s = tick(s, 0.04, Vector3(0,0,-0.8))
    expect(s.reason == "forward-or-unclear", "forward-moving foot low is swing")
    expect(not s.planted,"forward swing never locks")
    s = tick(s,0.04,Vector3(0,0,1.3))
    expect(s.reason == "confirming","first reverse sample not enough")
    s = tick(s,0.04,Vector3(0,0,1.3))
    expect(not s.planted,"second sample not enough")
    s = tick(s,0.04,Vector3(0,0,1.3))
    expect(s.planted and s.reason == "contact-acquired","stable backwards stance locks")
    s = tick(s,0.13,Vector3(0,0,1.2))
    expect(s.planted,"stays planted across release-height margin")
    s = tick(s,0.08,Vector3(0,0,-0.8))
    expect(not s.planted and s.reason == "forward-swing","forward swing releases")
    for n in range(3): s = tick(s,0.04,Vector3(0,0,1.2))
    expect(s.planted,"replant")
    s = tick(s,0.03,Vector3(0,0,-1.0),3.0,true,Vector3.UP,true,0.8)
    expect(not s.planted and s.reason == "overstretched","overextended IK target releases")
    for n in range(3): s = tick(s,0.04,Vector3(0,0,1.2))
    expect(s.planted,"replant after stretch")
    s = tick(s,0.04,Vector3(0,0,1.2),3.0,false)
    expect(not s.planted,"lost floor releases")
    for n in range(3): s = tick(s,0.04,Vector3(0,0,1.2))
    s = tick(s,0.04,Vector3(0,0,1.2),3.0,true,Vector3(0.9,0.2,0.0))
    expect(not s.planted and s.reason == "no-ground-or-steep","steep slope rejects")
    for n in range(3): s = tick(s,0.04,Vector3(0,0,1.2))
    s = tick(s,0.04,Vector3(0,0,1.2),0.0)
    expect(not s.planted,"stop locomotion releases")
    for n in range(3): s = tick(s,0.04,Vector3(0,0,1.2))
    for n in range(26): s = tick(s,0.1,Vector3(0,0,1.2))
    expect(not s.planted,"stance timeout prevents permanent glued feet")
    var empty := C.fresh()
    empty = tick(empty,0.15,Vector3(0,0,1.2))
    expect(not empty.planted,"foot above acquisition height not locked")
    empty = tick(empty,0.04,Vector3(0,0,1.2),3.0,true,Vector3.UP,false)
    expect(not empty.planted,"attacks and dodges do not lock")
    print("PHASE22_CONTACT_CLASSIFIER %d passed; %d failed" % [checks,failures])
    quit(0 if failures == 0 else 1)