extends SceneTree
var failures := 0
var checks := 0
func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)
func _initialize(): call_deferred("run")
func run():
	root.size = Vector2i(1280,720)
	var scene = load("res://main.tscn").instantiate()
	scene.save_path = "user://integration_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(scene)
	await process_frame
	check(scene.world_container.get_child_count() == 1,"one world")
	var initial = scene.model.snapshot().checkpoint_id
	scene.dispatch("unknown")
	check(scene.model.snapshot().checkpoint_id == initial,"invalid transition safe")
	check(abs(scene.player.visual.rotation.y - PI) < 0.01,"player initially faces forward away from rear camera")
	check(scene.player.arm.spring_length > 2,"third-person spring arm")
	for action in ["move_left","move_right","move_forward","move_back","interact","look_left","look_right","pause"]:
		var mapped = false
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion: mapped = true
		check(mapped,"controller binding " + action)
	scene.hud.show_dialogue("optional")
	check(scene.hud.modal_visible(),"optional visible")
	var scrolling_choices = false
	for child in scene.hud.content.get_children():
		if child is Button: scrolling_choices = true
	check(not scrolling_choices,"optional choices stay equally visible outside text scroll")
	scene.hud.close_modal()
	check(not scene.hud.modal_visible(),"back cancels")
	var preferences = scene.model.snapshot().settings
	preferences.text_scale = 2.0
	preferences.reduced_motion = true
	preferences.graphics = "low"
	scene.change_settings(preferences)
	check(scene.player.preferences.reduced_motion,"reduced motion applied")
	check(scene.hud.prompt.get_theme_font_size("font_size") == 46,"large text")
	check(scene.audio.has_method("crossfade_location"),"location crossfade")
	check(scene.hud.has_method("show_arrival"),"framed arrival")
	check(scene.has_method("apply_graphics"),"graphics setting changes renderer")
	check(scene.has_method("capture_frame"),"local QA frame capture")
	check(scene.hud.has_method("set_subtitle"),"ambient subtitles respect preference")
	check(scene.player.has_method("set_framed_view"),"reversible cinematic framing")
	check(scene.hud.content.get_parent() is ScrollContainer,"large text scroll-safe")
	scene.hud.close_modal()
	scene.resume_controls()
	var start_position = scene.player.global_position
	var motion = InputEventJoypadMotion.new()
	motion.device = 0
	motion.axis = JOY_AXIS_LEFT_Y
	motion.axis_value = -1.0
	Input.parse_input_event(motion.duplicate())
	for i in range(20): await physics_frame
	motion.axis_value = 0.0
	Input.parse_input_event(motion.duplicate())
	check(scene.player.global_position.distance_to(start_position) > 0.4,"synthetic controller movement")
	var before_yaw = scene.player.pivot.rotation.y
	motion.axis = JOY_AXIS_RIGHT_X
	motion.axis_value = 1.0
	Input.parse_input_event(motion.duplicate())
	for i in range(10): await physics_frame
	motion.axis_value = 0.0
	Input.parse_input_event(motion.duplicate())
	check(abs(scene.player.pivot.rotation.y-before_yaw) > 0.05,"synthetic controller orbit")
	scene.player.arm.rotation.x = 0.0
	scene.player.preferences.sensitivity = 0.5
	motion.axis = JOY_AXIS_RIGHT_Y
	motion.axis_value = 0.5
	Input.parse_input_event(motion.duplicate())
	for i in range(10): await physics_frame
	var slow_pitch = scene.player.arm.rotation.x
	scene.player.arm.rotation.x = 0.0
	scene.player.preferences.sensitivity = 1.0
	for i in range(10): await physics_frame
	var fast_pitch = scene.player.arm.rotation.x
	motion.axis_value = 0.0
	Input.parse_input_event(motion.duplicate())
	check(abs(fast_pitch-slow_pitch*2.0) < 0.015 and fast_pitch > slow_pitch,"right-stick pitch respects sensitivity multiplier")
	scene.player.pivot.rotation.y = 0
	var obstruction = load("res://world/world_factory.gd").new().box(scene.world_container.get_child(0),"Camera test wall",scene.player.position + Vector3(0,2,2.5),Vector3(4,4,0.3),Color.WHITE)
	for i in range(5): await physics_frame
	check(scene.player.arm.get_hit_length() < scene.player.arm.spring_length,"camera collision avoidance")
	obstruction.queue_free()
	scene.dispatch("leave_apartment")
	scene.dispatch("leave_apartment")
	check(scene.model.snapshot().checkpoint_id == "roof" and scene.world_container.get_child_count() == 1,"repeated transition one world")
	scene.hud.apply_settings(preferences)
	scene.hud.show_puzzle(scene.model.snapshot())
	await process_frame
	await process_frame
	print("LAYOUT:",scene.hud.get_viewport().get_visible_rect(),scene.hud.modal.get_global_rect())
	for b in scene.hud.footer.get_children(): print(b.text,b.get_global_rect())
	var viewport_rect = Rect2(Vector2.ZERO,Vector2(1280,720))
	for control in scene.hud.footer.get_children():
		check(viewport_rect.encloses(control.get_global_rect()),"large-text puzzle button inside viewport: " + control.text)
	scene.hud.show_dialogue("camera")
	scene.player.set_controls_enabled(false)
	scene.player.set_framed_view(true)
	await process_frame
	var focused_before = scene.hud.get_viewport().gui_get_focus_owner()
	var yaw_before_pause = scene.player.pivot.rotation.y
	var menu_event = InputEventJoypadButton.new()
	menu_event.button_index = JOY_BUTTON_START
	menu_event.pressed = true
	scene._unhandled_input(menu_event)
	check(scene.hud.content.get_child(0).text == "Take your time","Menu pauses an active conversation")
	scene._unhandled_input(menu_event.duplicate())
	await process_frame
	await process_frame
	check(scene.hud.get_viewport().gui_get_focus_owner() == focused_before,"pause restores original focused choice")
	check(scene.hud.modal_visible() and not scene.player.enabled,"pause restores dialogue movement gating")
	check(is_equal_approx(scene.player.pivot.rotation.y,yaw_before_pause),"pause preserves framed camera")
	scene.hud.close_modal()
	scene.resume_controls()
	check(scene.player.enabled,"back restores walking")
	scene.hud.show_puzzle(scene.model.snapshot())
	await process_frame
	var scroll = scene.hud.content.get_parent()
	scroll.scroll_vertical = 0
	var focus_before_scroll = scene.hud.get_viewport().gui_get_focus_owner()
	var text_motion = InputEventJoypadMotion.new()
	text_motion.axis = JOY_AXIS_RIGHT_Y
	text_motion.axis_value = 1.0
	Input.parse_input_event(text_motion)
	for i in range(12): await physics_frame
	check(scroll.scroll_vertical > 0,"controller right stick reads enlarged prose")
	check(scene.hud.get_viewport().gui_get_focus_owner() == focus_before_scroll,"text scroll preserves choice focus")
	text_motion.axis_value = 0.0
	Input.parse_input_event(text_motion.duplicate())
	scroll.scroll_vertical = 0
	var page = InputEventKey.new()
	page.keycode = KEY_PAGEDOWN
	page.physical_keycode = KEY_PAGEDOWN
	page.pressed = true
	Input.parse_input_event(page)
	print("PAGEACTION:",page.is_action_pressed("ui_page_down"),InputMap.action_get_events("ui_page_down"))
	await process_frame
	await process_frame
	check(scroll.scroll_vertical > 0,"PageDown reads enlarged prose")
	scene.hud.show_dialogue("camera")
	await process_frame
	check(scroll.scroll_vertical == 0,"new dialogue starts at beginning")
	scene.hud.close_modal()
	scene.hud.show_notice("Recovered backup; damaged primary retained. You can continue; damaged data is retained.")
	await process_frame
	await process_frame
	check(viewport_rect.encloses(scene.hud.notice.get_global_rect()),"large recovery notice inside viewport")
	scene.hud.close_all()
	for action in ["meet_stranger","read_board","board_train","meet_passenger","arrive_shore"]:
		scene.dispatch(action)
		scene.hud.close_all()
	for landmark in ["lighthouse","arch","constellation"]:
		var marker = null
		for node in scene.world_container.get_child(0).get_children():
			if node.has_meta("value") and node.get_meta("value") == landmark: marker = node
		scene.on_interact(marker)
		check(scene.hud.modal_visible(),"landmark discovery is playable authored scene")
		scene.dispatch("dismiss")
	scene.dispatch("align",0)
	check(scene.hud.notice.text.begins_with("That framing"),"wrong alignment shows retry notice")
	scene.dispatch("align",2)
	check(scene.model.snapshot().checkpoint_id == "camera_choice" and scene.hud.notice.text == "","successful framing clears stale retry notice")
	scene.dispatch("choose_camera","lend")
	scene.dispatch("resolve_action","skipped")
	scene.dispatch("return_train")
	scene.dispatch("have_breakfast")
	scene.dispatch("finish")
	check(scene.model.snapshot().chapter_complete and scene.model.snapshot().souvenir_ids == ["platform_six_journey"],"actual runtime dispatch completes unassisted lend skipped route")
	var saved_ending = scene.store.load_snapshot(scene.save_path)
	check(saved_ending.ok and saved_ending.data.chapter_complete,"actual runtime completion persists and reloads")
	check(scene.hud.modal_visible() and scene.hud.content.get_child(1).text.contains("Chapter one complete"),"actual runtime ending UI shows completion")
	print("Integration checks: %d; failures: %d" % [checks,failures])
	scene.audio.music.stop()
	scene.audio.effects.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
