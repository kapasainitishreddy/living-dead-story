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
	check(ResourceLoader.exists("res://world/fair_world.gd"),"fair world exists for accessible-deck physics")
	if failures:
		quit(1)
		return
	var bindings = load("res://main.gd").new()
	for pair in [["move_left",KEY_A],["move_right",KEY_D],["move_forward",KEY_W],["move_back",KEY_S],["look_left",0],["look_right",0],["look_up",0],["look_down",0],["interact",KEY_E],["reset_camera",KEY_R]]:
		bindings.bind_action(pair[0],[pair[1]] if pair[1] else [])
	bindings.free()
	var world = load("res://world/fair_world.gd").new().build({"fair_checkpoint":"workshop","fair":{"levelled":false}})
	root.add_child(world)
	var player = load("res://player/player.gd").new()
	world.add_child(player)
	player.position = Vector3(-2.6,0.1,6.5)
	await physics_frame
	Input.action_press("move_forward")
	for i in range(75): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z < 3.3,"broad ramp permits normal walking onto raised deck")
	check(player.position.y > 0.17 and player.position.y < 0.4,"raised deck supports the production player safely")
	for i in range(40):
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	check(player.position.z > 1.95,"solid pond rim prevents entering shallow decorative water")
	player.position = Vector3(3.4,0.1,6)
	Input.action_press("move_forward")
	for i in range(145): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z < -3.0,"wide courtyard aisle remains traversable beside pond")
	check(player.position.y > -0.1,"courtyard supports safe inspection and doorway routes")
	player.position = Vector3(5.7,0.1,0)
	Input.action_press("move_right")
	for i in range(45): await physics_frame
	Input.action_release("move_right")
	check(player.position.x < 6.4,"solid train hull keeps player out of carriage wall")
	world.free()
	print("Fair physics checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
