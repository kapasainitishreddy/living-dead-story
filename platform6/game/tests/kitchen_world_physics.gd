extends SceneTree
# Actual CharacterBody3D tests: dinner props do not become chair/table traps.
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
	var snapshot = {"campaign_chapter":"night_kitchen","kitchen_checkpoint":"arrival","kitchen":{"mode":"unselected","served":false},"paper":{},"settings":{"reduced_motion":true}}
	var world = load("res://world/kitchen_world.gd").new().build(snapshot)
	root.add_child(world)
	var player = load("res://player/player.gd").new()
	world.add_child(player)
	player.position = world.get_node("Spawn").position
	await physics_frame
	for checkpoint in ["arrival","supper","conversation","complete"]:
		snapshot.kitchen_checkpoint = checkpoint
		snapshot.kitchen.mode = "sit"
		snapshot.kitchen.served = checkpoint != "arrival"
		world.apply_snapshot(snapshot)
		for target in world.get_node("Interactions").get_children():
			player.position = target.position+Vector3(0,0.12,0)
			player.velocity = Vector3.ZERO
			for i in range(6): await physics_frame
			check(player.position.y >= -0.06 and player.position.y <= 0.13,"floor supports " + str(target.name) + " at " + checkpoint)
			check(player.position.distance_to(target.position) < 0.2,"target standing spot is unobstructed " + str(target.name))
			check(player.nearest == target,"single nearest-target control reaches " + str(target.name))
	# The player can enter, reach a place, and cross the free-standing chair safely.
	player.position = Vector3(-0.44,0.12,4.2)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(35): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z < 2.62,"broad entrance reaches the dinner place")
	player.position = Vector3(-0.44,0.12,2.2)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(45): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z >= 0.86 and player.position.z < 1.45,"chair permits exit while solid table protects the food")
	player.position = world.get_node("DinnerReturn").position
	player.velocity = Vector3.ZERO
	for i in range(6): await physics_frame
	check(player.position.y > -0.06 and player.position.z > 2.3,"close table view returns to safe walkable space")
	player.position = Vector3(-4.1,0.12,5.4)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(125): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z < -2.5,"wide left aisle reaches sign callback without trapping")
	player.position = Vector3(4.2,0.12,5.4)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(125): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z < -2.5,"wide right aisle reaches tea and camera without trapping")
	player.position = Vector3(7.25,0.12,2.7)
	player.velocity = Vector3.ZERO
	Input.action_press("move_right")
	for i in range(25): await physics_frame
	Input.action_release("move_right")
	check(player.position.x < 7.61,"room boundary keeps dinner walk safe")
	world.free()
	print("Kitchen physics checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
