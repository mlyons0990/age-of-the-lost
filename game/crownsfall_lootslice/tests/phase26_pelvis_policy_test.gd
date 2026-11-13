extends SceneTree
const P := preload("res://scripts/three_d/phase26_pelvis_policy.gd")
func _initialize() -> void:
    var total := 0
    var cases := [
        [[0.04], true, true, false, false, 0.018],
        [[-0.04], true, true, false, false, -0.018],
        [[0.08, 0.04], true, true, false, false, 0.027],
        [[0.30], true, true, false, false, 0.0],
        [[0.04], false, true, false, false, 0.0],
        [[0.04], true, false, false, false, 0.0],
        [[0.04], true, true, true, false, 0.0],
        [[0.04], true, true, false, true, 0.0],
        [[], true, true, false, false, 0.0],
        [[0.30, 0.04], true, true, false, false, 0.018],
    ]
    for c in cases:
        var got: float = P.target_offset(c[0], c[1], c[2], c[3], c[4])
        if absf(got - c[5]) > 0.0001:
            push_error("Phase26 expected %.4f, got %.4f" % [c[5], got])
            quit(1)
            return
        total += 1
    var x := 0.0
    for i in range(80):
        var old := x
        x = P.update_offset(x, 0.2, 1.0/60.0)
        if x < old or x > P.MAX_OFFSET_M + 0.00001 or x-old > P.MAX_CHANGE_MPS / 60.0 + 0.00001:
            push_error("Phase26 clamping failed at frame %d" % i)
            quit(1)
            return
        total += 1
    for i in range(80):
        var old := x
        x = P.update_offset(x, 0.0, 1.0/60.0)
        if x > old + 0.000001 or x < -0.000001:
            push_error("Phase26 settle failed at frame %d" % i)
            quit(1)
            return
        total += 1
    print("Phase26 pelvis pure-policy assertions: %d/%d" % [total,total])
    quit(0)
