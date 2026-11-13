extends SceneTree
## Live collider test: actual raycasts on stairs and sloped surfaces.
const TERRAIN := preload("res://scenes/phase23_terrain_lab.tscn")
var pass_count := 0
var failures := 0
func test(ok: bool, description: String) -> void:
    if ok: pass_count += 1
    else:
        failures += 1
        push_error("PHASE23_TERRAIN_PHYSICS: " + description)
func _initialize(): call_deferred("run")
func ground_at(space: PhysicsDirectSpaceState3D, x: float, z: float, exclude: Array[RID]) -> Dictionary:
    var q := PhysicsRayQueryParameters3D.create(Vector3(x,5.0,z),Vector3(x,-2.0,z))
    q.exclude = exclude
    return space.intersect_ray(q)
func run():
    var lab := TERRAIN.instantiate()
    root.add_child(lab)
    await physics_frame
    await physics_frame
    var world: PhysicsDirectSpaceState3D = lab.get_world_3d().direct_space_state
    var excluded: Array[RID] = [lab.player.get_rid()]
    for i in range(7):
        var z := -2.15 - float(i)*0.72
        var ray := ground_at(world,0.0,z,excluded)
        test(not ray.is_empty(),"stair has ground %d"%i)
        if ray.is_empty():continue
        var found_height := float(ray.position.y)
        test(absf(found_height-lab.step_top_heights[i]) < 0.025,"stair step %d height actual %.3f"%[i,found_height])
    var left_ray := ground_at(world,-7.0,-3.5,excluded)
    test(not left_ray.is_empty(),"ramp collision surface detected")
    if not left_ray.is_empty():
        var angle := rad_to_deg(acos(clampf(left_ray.normal.y,-1.0,1.0)))
        print("PHASE23_RAMP_ANGLE: ",angle)
        test(angle>15.0 and angle <23.0,"ramp normal is 18 degrees")
        test(left_ray.position.y>0.5 and left_ray.position.y<1.5,"ramp elevated")
    var steep := ground_at(world,7.0,-8.0,excluded)
    test(not steep.is_empty(),"steep reject wall collision detected")
    if not steep.is_empty():
        var steep_angle := rad_to_deg(acos(clampf(steep.normal.y,-1.0,1.0)))
        print("PHASE23_STEEP_ANGLE: ",steep_angle)
        test(steep_angle>55.0,"reject terrain deliberately steep")
    lab.queue_free()
    await process_frame
    print("PHASE23_TERRAIN_COLLIDERS: ",pass_count," passed; ",failures," failed")
    quit(0 if failures==0 else 1)