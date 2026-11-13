extends SceneTree
## godot --headless --path game/crownsfall_lootslice --script res://tests/phase24_step_safety_test.gd
const POLICY := preload("res://scripts/three_d/phase24_step_safety.gd")

func _initialize() -> void:
    var ok := 0
    var cases := [
        [0.14, Vector3.UP, 4.3, true, true, true, true, true],
        [0.18, Vector3.UP, 4.3, true, true, true, true, true],
        [0.22, Vector3.UP, 4.3, true, true, true, true, false],
        [0.01, Vector3.UP, 4.3, true, true, true, true, false],
        [0.14, Vector3.RIGHT, 4.3, true, true, true, true, false],
        [0.14, Vector3.UP, 0.0, true, true, true, true, false],
        [0.14, Vector3.UP, 4.3, false, true, true, true, false],
        [0.14, Vector3.UP, 4.3, true, false, true, true, false],
        [0.14, Vector3.UP, 4.3, true, true, false, true, false],
        [0.14, Vector3.UP, 4.3, true, true, true, false, false],
        [0.14, Vector3.UP, 10.0, true, true, true, true, false],
        [NAN, Vector3.UP, 4.3, true, true, true, true, false],
    ]
    for test in cases:
        var result: bool = POLICY.accepted(test[0],test[1],test[2],test[3],test[4],test[5],test[6])
        if result != test[7]:
            push_error("Phase24 policy mismatch in case %d" % ok)
            quit(1)
            return
        ok += 1
    print("Phase24 policy: %d/%d assertions passed" % [ok,cases.size()])
    quit(0)
