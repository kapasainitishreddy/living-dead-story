extends Node
# Real-display settings, fallback, live-camera and keyboard interaction QA.
var game
var checks := 0
var failures := 0
var output_dir := "/workspace/shared/platform6-build/evidence/painterly-paired/desktop-qa"
var orbit_live := false
var orbit_start := 0
var next_orbit_capture := 0.0
var orbit_capture_index := 0
func check(ok: bool, what: String):
	checks += 1
	print("QA ","PASS " if ok else "FAIL ",what)
	if not ok: failures += 1
func _ready():
	if DisplayServer.get_name() == "headless":
		push_error("Station desktop QA requires actual rendered display")
		get_tree().quit(2)
		return
	if DisplayServer.get_name() == "headless":
		push_error("Station desktop QA requires a real rendering display")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	get_tree().root.content_scale_size = Vector2i(1280,720)
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	game = load("res://main.gd").new()
	game.model.data.checkpoint_id = "conductor"
	game.save_path = "user://station_desktop_qa_"+str(Time.get_ticks_usec())+".json"
	add_child(game)
	await get_tree().process_frame
	game.hud.close_all()
	game.resume_controls()
	set_start_pose()
	for quality in ["low","medium","high"]:
		var settings = game.model.snapshot().settings
		settings.graphics = quality
		game.change_settings(settings)
		await get_tree().create_timer(3.0).timeout
		check(get_viewport().msaa_3d == (Viewport.MSAA_DISABLED if quality == "low" else Viewport.MSAA_2X),quality+" MSAA applied")
		check(is_equal_approx(get_viewport().scaling_3d_scale,0.8 if quality == "low" else 1.0),quality+" scale applied")
		var correct_shadows = true
		for light in game.world_container.find_children("*","Light3D",true,false):
			if light.shadow_enabled != (quality == "high"): correct_shadows = false
		check(correct_shadows,quality+" shadow setting applied")
		await capture("settings-"+quality)
	var medium = game.model.snapshot().settings
	medium.graphics = "medium"
	game.change_settings(medium)
	ProjectSettings.set_setting("station/painterly_enabled",false)
	game.route()
	set_start_pose()
	await get_tree().create_timer(3.0).timeout
	check(not game.world_container.get_child(0).has_meta("painterly_station"),"fallback removes painterly layer")
	await capture("fallback-medium")
	var fallback_high = game.model.snapshot().settings
	fallback_high.graphics = "high"
	game.change_settings(fallback_high)
	await get_tree().create_timer(3.0).timeout
	await capture("fallback-high")
	game.change_settings(medium)
	ProjectSettings.set_setting("station/painterly_enabled",true)
	game.route()
	set_start_pose()
	await get_tree().create_timer(3.0).timeout
	check(game.world_container.get_child(0).has_meta("painterly_station"),"painterly enabled again")
	await capture("painterly-medium-restored")
	game.player.enabled = false
	orbit_live = true
	orbit_start = Time.get_ticks_usec()
	print("QA_LIVE_ORBIT_START")
	await get_tree().create_timer(60.0).timeout
	orbit_live = false
	print("QA_LIVE_ORBIT_END")
	game.player.enabled = true
	game.player.position = Vector3(0,0.1,5)
	game.player.pivot.rotation.y = 0
	game.player.arm.rotation.x = -0.22
	key(KEY_W,true)
	for i in range(130): await get_tree().physics_frame
	key(KEY_W,false)
	check(game.player.position.z < -3.0,"actual W-key event moves down station aisle")
	check(game.player.position.y > -0.2 and game.player.position.y < 0.3,"station floor supports keyboard-driven player")
	game.player.position = Vector3(2,0.1,-2.8)
	game.player.velocity = Vector3.ZERO
	for i in range(4): await get_tree().physics_frame
	key(KEY_E,true)
	await get_tree().process_frame
	key(KEY_E,false)
	await get_tree().create_timer(0.7).timeout
	check(game.hud.modal_visible(),"actual E-key event opens conductor dialogue")
	await capture("keyboard-conductor-dialogue")
	var button = null
	for child in game.hud.footer.get_children():
		if child is Button and child.text == "Board the train": button = child
	check(button != null,"boarding choice remains available")
	if button:
		button.grab_focus()
		key(KEY_ENTER,true)
		await get_tree().process_frame
		key(KEY_ENTER,false)
		await get_tree().create_timer(1.2).timeout
		check(game.model.snapshot().checkpoint_id == "passenger","keyboard Enter boards train")
		await capture("keyboard-boarded-train")
	print("Station desktop QA checks: ",checks,"; failures: ",failures)
	get_tree().quit(1 if failures else 0)
func set_start_pose():
	game.player.position = Vector3(-1,0.1,5)
	game.player.velocity = Vector3.ZERO
	game.player.visual.rotation.y = PI
	game.player.pivot.rotation.y = -0.12
	game.player.arm.rotation.x = -0.22
func key(code: int, pressed_: bool):
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed_
	Input.parse_input_event(event)
func _process(_delta):
	if not orbit_live: return
	var elapsed = (Time.get_ticks_usec()-orbit_start)/1000000.0
	game.player.pivot.rotation.y = -0.12+sin(elapsed*0.42)*0.58
	game.player.arm.rotation.x = -0.22+sin(elapsed*0.30)*0.08
	if elapsed >= next_orbit_capture:
		next_orbit_capture += 2.0
		orbit_capture_index += 1
		capture("live-orbit-%02d" % orbit_capture_index)
func capture(name_: String):
	await RenderingServer.frame_post_draw
	var image_ = get_viewport().get_texture().get_image()
	check(image_.get_size() == Vector2i(1280,720),name_+" render size1280x720")
	var err = image_.save_png(output_dir+"/"+name_+".png")
	check(err == OK,name_+" screenshot saved")
