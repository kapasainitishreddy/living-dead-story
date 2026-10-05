extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, note: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + note)
func _initialize(): call_deferred("run")
func run():
	var bindings = load("res://main.gd").new()
	for pair in [["move_left",KEY_A],["move_right",KEY_D],["move_forward",KEY_W],["move_back",KEY_S],["look_left",0],["look_right",0],["look_up",0],["look_down",0],["interact",KEY_E],["reset_camera",KEY_R]]:
		bindings.bind_action(pair[0],[pair[1]] if pair[1] else [])
	bindings.free()
	for route in ["unselected","cart","walk","bench"]:
		var state = {"campaign_chapter":"quiet_orchard","orchard_checkpoint":"arrival" if route == "unselected" else "rest","orchard":{"route":route,"beat":0,"completed":false},"settings":{"reduced_motion":true}}
		var world = load("res://world/orchard_world.gd").new().build(state)
		root.add_child(world)
		var player = load("res://player/player.gd").new()
		world.add_child(player)
		await physics_frame
		for beat in range(4):
			state.orchard.beat = beat
			world.apply_state(state)
			for target in world.get_node("Interactions").get_children():
				player.position = target.position + Vector3(0,0.12,0)
				player.velocity = Vector3.ZERO
				for i in range(8): await physics_frame
				check(player.position.y > -0.05 and player.position.y < 0.15,"floor supports " + str(target.name))
				check(player.position.distance_to(target.position) < 0.2,"no collision traps at " + str(target.name))
				check(player.nearest == target,"distinct reachable target " + str(target.name))
		player.position = Vector3(0,0.12,6)
		player.velocity = Vector3.ZERO
		Input.action_press("move_forward")
		for i in range(190): await physics_frame
		Input.action_release("move_forward")
		check(player.position.z < -6,"broad path reaches optional crate observation")
		world.free()
	print("Orchard physics checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
