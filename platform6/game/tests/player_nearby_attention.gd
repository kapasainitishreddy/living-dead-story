extends SceneTree
# Real Godot control/rig contract for discovering quiet ordinary objects.
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func run():
	var player = load("res://player/player.gd").new()
	root.add_child(player)
	await process_frame
	player.set_physics_process(false)
	var first = Node3D.new()
	first.name = "A found postcard"
	first.position = Vector3(2.0,0.0,0.8)
	root.add_child(first)
	var second = Node3D.new()
	second.name = "A waiting cup"
	second.position = Vector3(-1.7,0.0,1.3)
	root.add_child(second)
	player.set_preferences({"sensitivity":1.0,"reduced_motion":false})
	var yaw = player.pivot.rotation.y
	var pitch = player.arm.rotation.x
	player.update_nearby_attention(first,0.0,0.09)
	check(player.visual.gaze_target == null,"no snap to an object on first contact")
	player.update_nearby_attention(first,0.0,0.12)
	check(player.visual.gaze_target == first,"stable idle proximity authorizes first glance")
	player.visual.advance_performance(0.20)
	check(absf(player.visual.gaze_yaw) > 0.01,"production head rig turns toward ordinary object")
	check(is_equal_approx(player.pivot.rotation.y,yaw) and is_equal_approx(player.arm.rotation.x,pitch),"nearby glance does not seize camera orbit")
	player.update_nearby_attention(second,0.0,0.02)
	check(player.visual.gaze_target == null,"new nearest object waits instead of twitching")
	player.update_nearby_attention(second,0.0,0.21)
	check(player.visual.gaze_target == second,"second stable object receives quiet attention")
	player.update_nearby_attention(second,1.6,0.016)
	check(player.visual.gaze_target == null,"walking immediately returns attention to route")
	player.update_nearby_attention(second,0.0,0.24)
	check(player.visual.gaze_target == second,"a pause in walking enables discovery again")
	player.set_controls_enabled(false)
	check(player.visual.gaze_target == null and player.glance_dwell == 0.0,"menus release attention")
	player.set_controls_enabled(true)
	player.update_nearby_attention(first,0.0,0.26)
	check(player.visual.gaze_target == first,"return to exploration restores optional glance")
	player.set_preferences({"sensitivity":1.0,"reduced_motion":true})
	check(player.visual.gaze_target == null,"reduced-motion change immediately clears glance")
	player.update_nearby_attention(first,0.0,3.0)
	check(player.visual.gaze_target == null,"reduced motion suppresses automatic glances")
	player.set_preferences({"sensitivity":1.0,"reduced_motion":false})
	player.update_nearby_attention(first,0.0,0.25)
	check(player.visual.gaze_target == first,"normal motion restores nearby discovery")
	first.queue_free()
	await process_frame
	player.update_nearby_attention(null,0.0,0.016)
	check(player.visual.gaze_target == null,"deleted object cannot leave stale gaze")
	player.queue_free()
	second.queue_free()
	await process_frame
	print("Nearby glance Godot checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
