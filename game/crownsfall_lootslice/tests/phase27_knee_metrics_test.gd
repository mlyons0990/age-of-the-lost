extends SceneTree
const M := preload("res://scripts/three_d/phase27_knee_metrics.gd")
func _initialize() -> void:
    var cases := [
        [Vector3(0,1,0), Vector3(0,0.5,0), Vector3(0,0,0), 180.0],
        [Vector3(0,1,0), Vector3(0,0.5,0.2), Vector3(0,0,0), 136.39718],
        [Vector3(0,1,0), Vector3(0,0.5,0), Vector3(0,0.5,0), -1.0],
    ]
    var count := 0
    for c in cases:
        var angle := M.knee_angle_deg(c[0],c[1],c[2])
        if absf(angle - c[3]) > 0.03:
            push_error("Knee metric expected %.3f got %.3f" % [c[3],angle])
            quit(1)
            return
        count += 1
    var hip := Vector3(0,1,0)
    var knee := Vector3(0,0.5,0.15)
    var ankle := Vector3(0,0,0)
    var foot := Vector3(0,-0.1,0)
    var a := M.evaluate(hip,knee,ankle,foot,foot,true,Vector3.FORWARD)
    if not bool(a["valid"]) or bool(a["foot_drift"]) or absf(float(a["foot_error_m"])) > 0.0001:
        push_error("Expected valid planted foot at its anchor")
        quit(1)
        return
    count += 1
    a = M.evaluate(hip,knee,ankle,foot,foot+Vector3(0.2,0,0),true,Vector3.FORWARD)
    if not bool(a["foot_drift"]):
        push_error("Expected 20cm anchor drift flag")
        quit(1)
        return
    count += 1
    a = M.evaluate(hip,knee,ankle,foot,foot+Vector3(0.2,0,0),false,Vector3.FORWARD)
    if bool(a["foot_drift"]):
        push_error("Swinging foot must not count as anchor drift")
        quit(1)
        return
    count += 1
    print("Phase27 knee geometry policy: %d/%d checks passed" % [count,count])
    quit(0)
