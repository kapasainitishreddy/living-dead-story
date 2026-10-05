extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func _initialize(): call_deferred("run")
func run():
	var bindings = load("res://main.gd").new()
	for pair in [["move_left",KEY_A],["move_right",KEY_D],["move_forward",KEY_W],["move_back",KEY_S],["look_left",0],["look_right",0],["look_up",0],["look_down",0],["interact",KEY_E],["reset_camera",KEY_R]]:
		bindings.bind_action(pair[0],[pair[1]] if pair[1] else [])
	bindings.free()
	var state = {"paper_checkpoint":"workshop","paper":{},"settings":{"reduced_motion":true}}
	var world = load("res://world/paper_world.gd").new().build(state)
	root.add_child(world)
	var player = load("res://player/player.gd").new()
	world.add_child(player)
	player.position = world.get_node("Spawn").position
	await physics_frame
	for marker in world.get_node("Interactions").find_children("*","Marker3D",true,false):
		player.position = marker.position+Vector3(0,0.12,0)
		player.velocity = Vector3.ZERO
		for i in range(6): await physics_frame
		check(player.position.y >= -0.06 and player.position.y <= 0.13,"floor safely supports " + str(marker.name))
		check(player.position.distance_to(marker.position) < 0.2,"solid table leaves " + str(marker.name) + " accessible")
		check(player.nearest == marker,"nearest-target controls can individually reach " + str(marker.name))
	player.position = Vector3(-1.7,0.12,1.0)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(55): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z > -0.31,"solid worktable stops player crossing the paper work")
	player.position = Vector3(1.2,0.12,5.8)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(130): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z < -2.3,"wide aisle reaches raise handle from room entrance")
	player.position = Vector3(4.0,0.12,0.7)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in range(110): await physics_frame
	Input.action_release("move_forward")
	check(player.position.z < -5.5,"measured doorway remains a real clear walk-through opening")
	state.paper_checkpoint = "raised"
	world.apply_snapshot(state)
	for marker in world.get_node("Interactions").find_children("*","Marker3D",true,false):
		player.position = marker.position+Vector3(0,0.12,0)
		player.velocity = Vector3.ZERO
		for i in range(6): await physics_frame
		check(player.nearest == marker,"raised nearby control remains reachable " + str(marker.name))
	player.position = Vector3(7.3,0.12,3)
	player.velocity = Vector3.ZERO
	Input.action_press("move_right")
	for i in range(25): await physics_frame
	Input.action_release("move_right")
	check(player.position.x < 7.61,"conservatory boundary keeps walking safe")
	world.free()
	print("Paper physics checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
