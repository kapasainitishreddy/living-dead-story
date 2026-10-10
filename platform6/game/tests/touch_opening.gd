extends SceneTree
var game
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool,label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func finger(index: int, position_: Vector2, pressed: bool):
	var event = InputEventScreenTouch.new()
	event.index = index
	event.position = position_
	event.pressed = pressed
	Input.parse_input_event(event)
func drag(index: int,position_: Vector2,relative: Vector2):
	var event = InputEventScreenDrag.new()
	event.index = index
	event.position = position_
	event.relative = relative
	Input.parse_input_event(event)
func tap(button: Control,index: int = 2):
	# Wait until container layout has produced the displayed target bounds.
	await process_frame
	await process_frame
	var point = button.get_global_rect().get_center()
	finger(index,point,true)
	await process_frame
	finger(index,point,false)
	await process_frame
func run():
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://touch_opening_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	check(not game.touch.touch_mode, "desktop retains its original controls before touch input")
	var center = game.touch.stick.position + Vector2(76,76)
	finger(0,center,true)
	await process_frame
	check(game.touch.touch_mode and game.player.touch_mode and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "first touch shows the controls and releases mouse capture")
	check(game.touch.axis == Vector2.ZERO, "center touch has a forgiving movement deadzone")
	var before: Vector3 = game.player.position
	drag(0,center + Vector2(0,-54),Vector2(0,-54))
	for i in 20: await physics_frame
	check(game.player.position.z < before.z - 0.30, "touch stick actually walks the original physics body")
	var yaw: float = game.player.pivot.rotation.y
	finger(1,Vector2(900,330),true)
	await process_frame
	drag(1,Vector2(935,340),Vector2(35,10))
	await process_frame
	check(game.player.pivot.rotation.y < yaw - 0.05 and game.touch.axis.y < -0.9, "second finger looks while the first continues walking")
	finger(0,center,false)
	finger(1,Vector2(935,340),false)
	for i in 22: await physics_frame
	check(game.touch.axis == Vector2.ZERO and Vector2(game.player.velocity.x,game.player.velocity.z).length() < 0.01, "lifting fingers stops movement without a stuck action")
	await tap(game.touch.reset_button)
	check(is_zero_approx(game.player.pivot.rotation.y) and is_equal_approx(game.player.arm.rotation.x,-0.22), "touch reset restores the existing exploration view")
	finger(0,center,true)
	drag(0,center + Vector2(0,-54),Vector2(0,-54))
	await tap(game.touch.pause_button)
	check(game.hud.pause_active and not game.player.enabled and game.touch.axis == Vector2.ZERO, "touch Pause cancels a held movement finger")
	drag(0,center + Vector2(0,-54),Vector2(0,-54))
	check(game.player.touch_move == Vector2.ZERO, "a stale finger cannot resume movement inside pause")
	await tap(game.touch.pause_button)
	check(not game.hud.pause_active and game.player.enabled, "touch Pause also resumes exploration")
	game.player.position = Vector3(0,0.12,-6.85)
	for i in 8: await physics_frame
	check(game.player.nearest != null and game.player.nearest.get_meta("action_id") == "leave_apartment", "touch route reaches the established apartment exit")
	await tap(game.touch.interact_button)
	check(game.hud.modal_visible() and not game.player.enabled and game.model.snapshot().checkpoint_id == "apartment", "touch Interact opens the authored confirmation once")
	check(game.hud.footer.get_children().all(func(b): return b.size.y >= 52), "dialogue choices provide larger touch targets")
	await tap(game.hud.footer.get_child(0),4)
	check(game.model.snapshot().checkpoint_id == "roof" and game.touch.axis == Vector2.ZERO, "chapter transition clears all finger state")
	game.hud.close_all()
	game.resume_controls()
	var prefs = game.model.snapshot().settings
	prefs.reduced_motion = true
	prefs.text_scale = 2.0
	game.change_settings(prefs)
	await process_frame
	for button in [game.touch.pause_button,game.touch.reset_button,game.touch.interact_button]:
		check(button.size.y >= 64 and button.get_global_rect().end.x <= 1280 and button.get_theme_font_size("font_size") == 38, "touch targets remain visible and readable at 2x text: " + button.text)
	check(not game.world_container.get_child(0).get_node("Rain").visible, "touch controls work alongside reduced decorative motion")
	game.dispatch("dialogue","umbrella_question")
	for i in 4: await process_frame
	var prose = game.hud.content.get_parent()
	var reading_point = prose.get_global_rect().get_center()
	finger(5,reading_point,true)
	await process_frame
	drag(5,reading_point - Vector2(0,100),Vector2(0,-100))
	await process_frame
	check(prose.scroll_vertical > 0, "a secondary touch scrolls enlarged authored prose")
	finger(5,reading_point - Vector2(0,100),false)
	await tap(game.hud.footer.get_child(game.hud.footer.get_child_count()-1),6)
	check(game.player.enabled and not game.hud.modal_visible(), "a secondary touch can leave dialogue after reading")
	var position_: Vector3 = game.player.position
	Input.action_press("move_forward")
	for i in 15: await physics_frame
	Input.action_release("move_forward")
	check(game.player.position.distance_to(position_) > 0.3, "desktop movement remains available alongside touch mode")
	game.touch._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.touch.move_finger == -1 and game.touch.look_finger == -1 and game.touch.axis == Vector2.ZERO, "focus loss clears gesture ownership")
	game.audio.shutdown()
	game.queue_free()
	await process_frame
	await process_frame
	print("TOUCH OPENING ",checks," checks; failures: ",failures)
	quit(1 if failures else 0)
