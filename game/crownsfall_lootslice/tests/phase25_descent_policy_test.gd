extends SceneTree
const POLICY := preload("res://scripts/three_d/phase25_descent_policy.gd")
func _initialize() -> void:
    var cases := [
        [0.14, Vector3.UP, 4.3, true, true, true, false, false, true],
        [0.03, Vector3.UP, 4.3, true, true, true, false, false, true],
        [0.20, Vector3.UP, 4.3, true, true, true, false, false, false],
        [0.01, Vector3.UP, 4.3, true, true, true, false, false, false],
        [0.14, Vector3.RIGHT, 4.3, true, true, true, false, false, false],
        [0.14, Vector3.UP, 0.0, true, true, true, false, false, false],
        [0.14, Vector3.UP, 8.0, true, true, true, false, false, false],
        [0.14, Vector3.UP, 4.3, false, true, true, false, false, false],
        [0.14, Vector3.UP, 4.3, true, false, true, false, false, false],
        [0.14, Vector3.UP, 4.3, true, true, false, false, false, false],
        [0.14, Vector3.UP, 4.3, true, true, true, true, false, false],
        [0.14, Vector3.UP, 4.3, true, true, true, false, true, false],
        [NAN, Vector3.UP, 4.3, true, true, true, false, false, false],
    ]
    for i in cases.size():
        var c: Array = cases[i]
        var got: bool = POLICY.accepted(c[0],c[1],c[2],c[3],c[4],c[5],c[6],c[7])
        if got != c[8]:
            push_error("Phase25 descent policy failed at case %d" % i)
            quit(1)
            return
    print("Phase25 descent policy: %d/%d passed" % [cases.size(), cases.size()])
    quit(0)
