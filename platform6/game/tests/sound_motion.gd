extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func run():
	var scene = load("res://main.tscn").instantiate()
	scene.save_path = "user://sound_motion_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(scene)
	await process_frame
	check(scene.audio.has_method("location_profile"),"audio exposes authored location profiles")
	if scene.audio.has_method("location_profile"):
		check(scene.audio.location_profile("apartment").ambience == "rain_window","apartment muffled rain")
		check(scene.audio.location_profile("roof").ambience == "rain_roof","roof open rain")
		check(scene.audio.location_profile("passenger").ambience == "rails","train wheel rhythm")
		check(scene.audio.location_profile("overlook").ambience == "surf","shore rolling surf")
		check(scene.audio.location_profile("apartment").subtitle != scene.audio.location_profile("passenger").subtitle,"subtitle follows actual ambience")
	var prefs = scene.model.snapshot().settings
	check(scene.world_container.get_child(0).has_node("AmbientMotion"),"world owns bounded ambient motion")
	if scene.world_container.get_child(0).has_node("AmbientMotion"):
		var motion = scene.world_container.get_child(0).get_node("AmbientMotion")
		motion.apply_preferences(true)
		check(not scene.world_container.get_child(0).get_node("Rain").visible,"reduced motion hides moving rain")
		motion.apply_preferences(false)
		check(scene.world_container.get_child(0).get_node("Rain").visible,"rain restores on preference toggle")
	prefs.reduced_motion = true
	scene.player.set_preferences(prefs)
	scene.player.pivot.rotation.y = 0.7
	scene.player.arm.rotation.x = 0.3
	scene.player.set_framed_view(true)
	check(is_equal_approx(scene.player.pivot.rotation.y,0.7) and is_equal_approx(scene.player.arm.rotation.x,0.3),"reduced motion framing keeps chosen orbit without snap")
	scene.player.set_framed_view(false)
	check(is_equal_approx(scene.player.pivot.rotation.y,0.7),"reduced motion unframing stays stable")
	check(scene.player.has_method("gait_weight"),"frame independent gait damping helper")
	if scene.player.has_method("gait_weight"):
		var one = scene.player.gait_weight(1.0/30.0)
		var two = 1.0 - pow(1.0 - scene.player.gait_weight(1.0/60.0),2)
		check(is_equal_approx(one,two),"gait easing equivalent across frame rates")
	check(scene.hud.has_method("show_controls"),"pause offers readable control help")
	prefs.master = 0.0
	scene.audio.apply_settings(prefs)
	scene.audio.crossfade_location("overlook")
	await create_timer(0.1).timeout
	check(scene.audio.music.volume_db <= -80 and scene.audio.effects.volume_db <= -80,"zero master stays muted during fade")
	scene.queue_free()
	await process_frame
	print("Sound/motion checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
