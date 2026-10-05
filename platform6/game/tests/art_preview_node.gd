extends Node3D
func _ready():
	var bindings = load("res://main.gd").new()
	for pair in [["move_left",KEY_A],["move_right",KEY_D],["move_forward",KEY_W],["move_back",KEY_S],["look_left",0],["look_right",0],["look_up",0],["look_down",0],["interact",KEY_E],["reset_camera",KEY_R]]:
		bindings.bind_action(pair[0],[pair[1]] if pair[1] else [])
	bindings.free()
	var world = load("res://world/world_factory.gd").new().build("conductor")
	add_child(world)
	get_viewport().msaa_3d = Viewport.MSAA_2X
	for light in world.find_children("*","Light3D",true,false): light.shadow_enabled = false
	var player = load("res://player/player.gd").new()
	world.add_child(player)
	player.position = Vector3(-1.0,0.1,5)
	player.visual.rotation.y = PI
	player.pivot.rotation.y = -0.12
	await get_tree().create_timer(3).timeout
	get_viewport().get_texture().get_image().save_png("res://../evidence/screenshots/perf-batched-medium.png")
	await get_tree().create_timer(7).timeout
	var f = FileAccess.open("res://../evidence/perf-batched-medium.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"frame_samples":samples,"elapsed_seconds":elapsed,"average_fps":samples/max(elapsed,0.001),"renderer":"Compatibility OpenGL; cloud Mesa llvmpipe", "scope":"station default medium MSAA2x shadows disabled; not target-device benchmark"},"  "))
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		get_viewport().get_texture().get_image().save_png("res://../evidence/screenshots/art-station-playtest.png")

var elapsed := 0.0
var samples := 0
func _process(delta):
	elapsed += delta
	samples += 1
