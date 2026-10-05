extends SceneTree
# Actual CharacterBody3D reachability, including the unchanged opening room.
var checks := 0
var failures := 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _initialize(): call_deferred("run")
func run():
	check(ResourceLoader.exists("res://world/home_world.gd"),"home world exists for real physics checks")
	if failures: quit(1); return
	for pair in [["move_left",KEY_A],["move_right",KEY_D],["move_forward",KEY_W],["move_back",KEY_S],["look_left",0],["look_right",0],["look_up",0],["look_down",0],["interact",KEY_E],["reset_camera",KEY_R]]:
		if not InputMap.has_action(pair[0]): InputMap.add_action(pair[0])
		if pair[1]:
			var key = InputEventKey.new()
			key.physical_keycode = pair[1]
			InputMap.action_add_event(pair[0],key)
	var snapshot = {"campaign_chapter":"still_here","home_checkpoint":"arrival","home":{"ticket":"unselected","ritual":"unselected","ending":"unselected","completed":false},"settings":{"reduced_motion":true}}
	var world = load("res://world/home_world.gd").new().build(snapshot)
	root.add_child(world)
	var player = load("res://player/player.gd").new()
	world.add_child(player)
	player.position = world.get_node("Spawn").position
	await physics_frame
	for checkpoint in ["arrival","settled","complete"]:
		for ticket in ["unselected","kettle","drawer","pocket"]:
			snapshot.home_checkpoint = checkpoint
			snapshot.home.ticket = ticket
			snapshot.home.ritual = "window" if checkpoint != "arrival" else "unselected"
			snapshot.home.ending = "sleep" if checkpoint == "complete" else "unselected"
			snapshot.home.completed = checkpoint == "complete"
			world.apply_state(snapshot)
			for target in world.get_node("Interactions").get_children():
				player.position = target.position+Vector3(0,0.12,0)
				player.velocity = Vector3.ZERO
				for i in range(8): await physics_frame
				check(player.position.y > -0.06 and player.position.y < 0.15,"original floor supports " + str(target.name) + checkpoint + ticket)
				check(player.position.distance_to(target.position) < 0.2,"home standing target clears furniture " + str(target.name) + checkpoint + ticket)
				check(player.nearest == target,"home marker is a distinct nearest target " + str(target.name) + checkpoint + ticket)
	# Original center aisle remains playable from the original Chapter One spawn.
	player.position = world.get_node("Spawn").position
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(125): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z < -3.0 and player.position.x > -0.3 and player.position.x < 0.3,"unchanged broad center aisle reaches home decision markers")
	# Approach the kettle from the front rather than through its solid table.
	player.position = Vector3(4,0.12,4.5)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(110): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z < -1.4 and player.position.z > -1.95,"table-front route reaches ticket without crossing collision")
	# Walk left of the original bed to the original window chair.
	player.position = Vector3(-6.8,0.12,4.5)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(180): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z < -6.3,"original left aisle reaches the window without a bed trap at " + str(player.position))
	player.position = Vector3(8.4,0.12,2)
	player.velocity = Vector3.ZERO
	Input.action_press("move_right")
	for i in range(40): await physics_frame
	Input.action_release("move_right")
	check(player.position.x < 8.65 and player.position.y > -0.06,"opening apartment wall keeps exploration inside the room")
	world.free()
	print("Home world physics checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
