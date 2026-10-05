extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _initialize(): call_deferred("run")
func run():
	var bindings = load("res://main.gd").new()
	for pair in [["move_left",KEY_A],["move_right",KEY_D],["move_forward",KEY_W],["move_back",KEY_S],["look_left",0],["look_right",0],["look_up",0],["look_down",0],["interact",KEY_E],["reset_camera",KEY_R]]:
		bindings.bind_action(pair[0],[pair[1]] if pair[1] else [])
	bindings.free()
	var value = {"return_checkpoint":"arrival","return_state":{"farewell":"wave"},"camera_choice":"unused","settings":{"reduced_motion":true}}
	var world = load("res://world/return_world.gd").new().build(value)
	root.add_child(world)
	var player = load("res://player/player.gd").new()
	world.add_child(player)
	await physics_frame
	for checkpoint in ["arrival","farewell","departed","complete"]:
		value.return_checkpoint = checkpoint
		world.apply_snapshot(value)
		for target in world.get_node("Interactions").get_children():
			player.position = target.position+Vector3(0,0.12,0)
			player.velocity = Vector3.ZERO
			for i in range(8): await physics_frame
			check(player.position.y > -0.06 and player.position.y < 0.15,"return floor supports " + str(target.name))
			check(player.position.distance_to(target.position) < 0.2,"return standing target is unobstructed " + str(target.name))
			check(player.nearest == target,"return interaction has distinct nearest target " + str(target.name))
	player.position = Vector3(0,0.12,4.5)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(130): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z < -2.3,"broad return path reaches Mira's farewell")
	player.position = Vector3(2.8,0.12,2)
	player.velocity = Vector3.ZERO
	Input.action_press("move_right")
	for i in range(120): await physics_frame
	Input.action_release("move_right")
	check(player.position.x < 4.5 and player.position.y > -0.06,"platform edge safely keeps player away from moving tracks")
	world.free()
	print("Return physics checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
