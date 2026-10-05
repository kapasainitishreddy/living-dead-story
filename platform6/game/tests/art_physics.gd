extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: "+message)
func _initialize(): call_deferred("run")
func run():
	var bindings = load("res://main.gd").new()
	for pair in [["move_left",KEY_A],["move_right",KEY_D],["move_forward",KEY_W],["move_back",KEY_S],["look_left",0],["look_right",0],["look_up",0],["look_down",0],["interact",KEY_E],["reset_camera",KEY_R]]:
		bindings.bind_action(pair[0],[pair[1]] if pair[1] else [])
	bindings.free()
	var world = load("res://world/world_factory.gd").new().build("conductor")
	root.add_child(world)
	var player = load("res://player/player.gd").new()
	world.add_child(player)
	player.position = Vector3(0,0.1,5)
	await physics_frame
	Input.action_press("move_forward")
	for i in range(130): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z < -3.0,"station main aisle stays traversable")
	check(player.position.y > -0.2 and player.position.y < 0.3,"tiled platform floor supports player")
	player.position = Vector3(3.2,0.1,-3)
	Input.action_press("move_right")
	for i in range(50): await physics_frame
	Input.action_release("move_right")
	check(player.position.x < 4.8,"cream train solid hull prevents entry through wall")
	player.position = Vector3(-5.8,0.1,1)
	Input.action_press("move_left")
	for i in range(35): await physics_frame
	Input.action_release("move_left")
	check(player.position.x > -6.5,"bench collision prevents walking through seat")
	player.position = Vector3(-8,0.1,0)
	Input.action_press("move_left")
	for i in range(50): await physics_frame
	Input.action_release("move_left")
	check(player.position.x > -8.6,"station wall blocks walking through facade")
	player.position = Vector3(-7.5,0.1,-2.5)
	Input.action_press("move_back")
	for i in range(45): await physics_frame
	Input.action_release("move_back")
	check(player.position.z < -1.3,"reachable canopy columns have solid collision")
	world.free()
	print("Station physics checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
