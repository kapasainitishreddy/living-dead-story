extends SceneTree
var game
var checks := 0
var failures := 0
var out := "res://../evidence/return/rendered"
func check(ok: bool, label: String):
	checks += 1
	print("QA ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func settle():
	await create_timer(0.12).timeout
	await process_frame
func capture(id: String):
	await settle()
	root.get_texture().get_image().save_png(out + "/" + id + ".png")
func make_return_seed(camera := "lend"):
	var helper = load("res://tests/return_runtime.gd").new()
	var snapshot = helper.orchard_seed(camera)
	helper.free()
	return snapshot
func key(action: String):
	var event = InputEventAction.new()
	event.action = action
	event.pressed = true
	game._unhandled_input(event)
func run():
	if DisplayServer.get_name() == "headless": quit(2); return
	out = ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://return_rendered_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await settle()
	check(game.model.restore(make_return_seed()), "restore full journey")
	game.route()
	game.dispatch("begin_return")
	await capture("arrival-text2")
	for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()), "arrival 2x choice visible " + b.text)
	game.dispatch("dismiss")
	await capture("platform-wide")
	var preparation_settings = game.model.snapshot().settings
	preparation_settings.reduced_motion = false
	game.change_settings(preparation_settings)
	game.dispatch("return_arrival")
	var preparation_world = game.world_container.get_child(0)
	var preparation_seen := {}
	while game.return_cinematic:
		var prep_phase: String = preparation_world.cinematic_phase
		if not preparation_seen.has(prep_phase):
			preparation_seen[prep_phase] = true
			await capture("preparation-" + prep_phase)
			game.show_pause()
			var prep_before = preparation_world.preparation_elapsed
			await create_timer(0.2).timeout
			check(preparation_world.preparation_elapsed == prep_before, "pause freezes preparation " + prep_phase)
			game.hud.resume_pause()
		await create_timer(0.08).timeout
	await settle()
	check(game.hud.footer.get_child_count() >= 5, "five equal farewells")
	for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()), "farewell 2x choice visible " + b.text)
	await capture("farewell-text2")
	game.show_pause()
	game.hud.resume_pause()
	await settle()
	for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()), "pause preserves 2x farewell visibility")
	# Normal-motion presentation, not only reduced-motion result.
	var settings = game.model.snapshot().settings
	settings.reduced_motion = false
	settings.text_scale = 1.0
	game.change_settings(settings)
	game.dispatch("return_farewell", "joke")
	var world = game.world_container.get_child(0)
	var seen := {}
	var elapsed := 0.0
	while game.return_cinematic and elapsed < 45.0:
		var phase: String = world.cinematic_phase
		if not seen.has(phase):
			seen[phase] = true
			await capture("departure-" + phase)
			if phase in ["turn_back", "camera_slip", "camera_catch"]:
				await create_timer(0.45 if phase != "turn_back" else 1.0).timeout
				await capture("departure-" + phase + "-gesture")
			if phase not in ["hold", "complete", "idle"]:
				game.show_pause()
				var before = world.cinematic_state()
				await create_timer(0.2).timeout
				check(world.cinematic_state() == before, "pause freezes " + phase)
				game.hud.resume_pause()
				await settle()
		await create_timer(0.08).timeout
		elapsed += 0.08
	check(not game.return_cinematic, "normal-motion train reaches quiet platform")
	check(not game.hud.modal_visible(), "no dialogue automatically covers departure")
	check(game.model.snapshot().return_checkpoint == "departed", "normal passage durable")
	await capture("empty-platform")
	game.dispatch("return_conductor")
	await capture("conductor-optional")
	game.dispatch("dismiss")
	game.dispatch("return_jo")
	await capture("jo-optional")
	game.dispatch("dismiss")
	var jo_camera = Camera3D.new()
	world.add_child(jo_camera)
	jo_camera.global_position = Vector3(-3.6,1.8,7.2)
	jo_camera.look_at(Vector3(-5.7,1.25,10.9),Vector3.UP)
	jo_camera.fov = 48
	jo_camera.current = true
	await capture("jo-umbrella-prop-inspection")
	check(world.get_node("Jo/YellowUmbrella/Canopy").is_visible_in_tree() and world.get_node("Jo/CrookedPaperStar").is_visible_in_tree(), "Jo umbrella and crooked star are physically visible")
	game.player.arm.get_child(0).current = true
	jo_camera.queue_free()
	game.dispatch("return_state")
	await capture("farewell-callback")
	game.dispatch("return_finish")
	await capture("chapter-six-complete")
	check(game.model.snapshot().return_state.completed, "chapter six completes")
	# Native rendered skip path during preparation and departure, all camera ownerships.
	for camera in ["take", "lend", "unused"]:
		game.model.restore(make_return_seed(camera))
		game.route()
		game.dispatch("begin_return")
		settings = game.model.snapshot().settings
		settings.reduced_motion = false
		game.change_settings(settings)
		game.dispatch("return_arrival")
		await settle()
		key("ui_cancel")
		check(not game.return_cinematic and game.hud.modal_visible(), "prep skip preserves five choices " + camera)
		game.dispatch("return_farewell", "wave")
		await settle()
		key("ui_cancel")
		check(not game.return_cinematic and not game.hud.modal_visible(), "departure skip settles without dialogue " + camera)
		check(game.model.snapshot().return_checkpoint == "departed", "skip cannot prevent Mira departure " + camera)
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	game = null
	print("RETURN RENDERED QA ", checks, " checks ", failures, " failures")
	quit(1 if failures else 0)
