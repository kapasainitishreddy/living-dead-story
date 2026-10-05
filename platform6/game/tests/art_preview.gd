extends SceneTree
var world: Node3D
var player: CharacterBody3D
func _initialize():
	call_deferred("start")
func start():
	var bindings = load("res://main.gd").new()
	for pair in [["move_left",KEY_A],["move_right",KEY_D],["move_forward",KEY_W],["move_back",KEY_S],["look_left",0],["look_right",0],["look_up",0],["look_down",0],["interact",KEY_E],["reset_camera",KEY_R]]:
		bindings.bind_action(pair[0],[pair[1]] if pair[1] else [])
	bindings.free()
	world = load("res://world/world_factory.gd").new().build("conductor")
	root.add_child(world)
	player = load("res://player/player.gd").new()
	world.add_child(player)
	player.position = Vector3(0,0.1,5)
	player.set_preferences({"sensitivity":1.0,"reduced_motion":false})
	await create_timer(3).timeout
	root.get_texture().get_image().save_png("res://../evidence/screenshots/art-station-first.png")
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		root.get_texture().get_image().save_png("res://../evidence/screenshots/art-station-playtest.png")
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE: quit()
