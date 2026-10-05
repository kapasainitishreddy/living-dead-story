extends SceneTree
var game
var checks := 0
var failures := 0
var out := "res://../evidence/orchard/rendered"
func check(ok: bool, label: String):
	checks += 1
	print("QA ","PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func settle():
	await create_timer(0.12).timeout
	await process_frame
func capture(id: String):
	await settle()
	root.get_texture().get_image().save_png(out + "/" + id + ".png")
func make_seed():
	var helper = load("res://tests/orchard_runtime.gd").new()
	var snapshot = helper.kitchen_seed()
	helper.free()
	return snapshot
func run():
	if DisplayServer.get_name() == "headless": quit(2); return
	out = ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://orchard_rendered_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await settle()
	var base = make_seed()
	for route_ in ["cart","walk","bench"]:
		check(game.model.restore(base),"restore "+route_)
		game.route()
		game.dispatch("begin_orchard")
		await settle()
		for scale in [1.0,2.0]:
			var settings = game.model.snapshot().settings
			settings.text_scale = scale
			game.change_settings(settings)
			game.show_orchard_state()
			await settle()
			for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()),"arrival choice visible " +str(scale)+" "+b.text)
			await capture(route_+"-arrival-text-"+str(scale))
			game.show_pause()
			game.hud.resume_pause()
			check(game.hud.content.get_child(0).text == "The Quiet Orchard","pause restores arrival")
		var settings = game.model.snapshot().settings
		settings.text_scale = 1.0
		settings.reduced_motion = false
		game.change_settings(settings)
		game.dispatch("orchard_route",route_)
		await capture(route_+"-wide")
		game.dispatch("orchard_view")
		await capture(route_+"-rest-view")
		game.dispatch("orchard_leave_view")
		for beat in range(1,4):
			game.dispatch("orchard_advance")
			await create_timer(1.0).timeout
			game.dispatch("orchard_view")
			await capture(route_+"-beat-"+str(beat))
			var world = game.world_container.get_child(0)
			game.show_pause()
			var before = world.beat_elapsed
			await create_timer(0.15).timeout
			check(world.beat_elapsed == before,"pause freezes visible beat")
			game.hud.resume_pause()
			game.dispatch("orchard_leave_view")
			await create_timer(1.4).timeout
			settings.text_scale = 2.0
			game.change_settings(settings)
			game.show_orchard_state()
			await settle()
			for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()),"2x rest choice visible")
			await capture(route_+"-rest-text2-beat-"+str(beat))
			settings.text_scale = 1.0
			game.change_settings(settings)
			game.dispatch("dismiss")
		game.dispatch("orchard_finish")
		check(game.model.snapshot().orchard.completed,"equal complete "+route_)
		settings.text_scale = 2.0
		game.change_settings(settings)
		await settle()
		for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()),"2x complete choice visible")
		await capture(route_+"-complete")
		game.dispatch("orchard_view","pear")
		check(game.orchard_observation,"pear view uses optional observation marker")
		await capture(route_+"-pear-observation")
		game.dispatch("orchard_leave_view")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	game = null
	print("ORCHARD GRAPHICS ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
