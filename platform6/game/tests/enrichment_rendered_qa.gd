extends SceneTree
var game
var checks := 0
var failures := 0
var out := "/workspace/shared/platform6-build/evidence/chapter-enrichment/rendered"
func check(ok: bool, label: String):
	checks += 1
	print("QA ","PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func settle():
	await create_timer(0.25).timeout
	await process_frame
func capture(id: String):
	await settle()
	root.get_texture().get_image().save_png(out+"/"+id+".png")
func run():
	if DisplayServer.get_name() == "headless":
		printerr("Requires actual graphical renderer")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://rendered_enrichment_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await settle()
	await capture("01-apartment")
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore"]:
		game.hud.close_all()
		game.resume_controls()
		game.dispatch(action)
		game.hud.close_all()
		game.resume_controls()
		if action == "leave_apartment":
			game.dispatch("dialogue","umbrella_question")
			await capture("02-umbrella-reply")
			check(game.hud.content.get_child(1).text.contains("sandwiches"),"roof original reply renders")
			game.dispatch("dismiss")
		if action == "read_board": await capture("03-platform-six")
		if action == "board_train":
			game.hud.show_dialogue("meet_passenger")
			await capture("04-mira-choices")
			for scale in [1.0,2.0]:
				var settings = game.model.snapshot().settings
				settings.text_scale = scale
				game.change_settings(settings)
				game.hud.show_dialogue("meet_passenger")
				await settle()
				for button in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(button.get_global_rect()),"passenger choice visible scale "+str(scale))
				game.show_pause()
				game.hud.show_controls()
				await settle()
				for button in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(button.get_global_rect()),"control help back visible scale "+str(scale))
				game.hud.resume_pause()
				check(game.hud.content.get_child(0).text == "Mira and the unopened camera","pause/help restores authored conversation")
			game.hud.close_all()
			game.dispatch("dialogue","passenger_boats")
			await capture("05-mira-boats")
			game.dispatch("dismiss")
			var settings = game.model.snapshot().settings
			settings.text_scale = 1.0
			game.change_settings(settings)
		if action == "arrive_shore": await capture("06-shore-shared-discovery")
	for landmark in ["lighthouse","arch","constellation"]:
		var target
		for node in game.world_container.get_child(0).get_children():
			if node.get_meta("value","") == landmark: target = node
		game.on_interact(target)
		await settle()
		check(game.hud.modal_visible() and not game.player.enabled,"inspection opens shared discovery "+landmark)
		await capture("07-"+landmark)
		game.dispatch("dismiss")
		check(game.player.enabled,"discovery dismissal restores walking "+landmark)
	game.dispatch("align",2)
	check(game.model.snapshot().checkpoint_id == "camera_choice","unassisted puzzle progresses after shared discoveries")
	game.hud.show_dialogue("camera")
	await capture("08-camera-choices")
	game.dispatch("choose_camera","unused")
	game.hud.show_dialogue("optional")
	await capture("09-equal-optional-choices")
	game.dispatch("resolve_action","skipped")
	game.hud.close_all()
	game.dispatch("return_train")
	game.dispatch("dialogue","breakfast_postcard")
	await capture("10-breakfast-postcard")
	game.dispatch("dismiss")
	var settings = game.model.snapshot().settings
	settings.reduced_motion = true
	game.change_settings(settings)
	game.player.pivot.rotation.y = 0.8
	game.player.arm.rotation.x = 0.25
	game.player.set_framed_view(true)
	await settle()
	check(is_equal_approx(game.player.pivot.rotation.y,0.8),"rendered reduced-motion orbit unchanged")
	check(not game.world_container.get_child(0).get_node("Steam").visible,"rendered steam hidden by reduced motion")
	game.player.set_framed_view(false)
	game.dispatch("have_breakfast")
	game.dispatch("finish")
	await capture("11-chapter-ending")
	check(game.model.snapshot().chapter_complete,"rendered full unused/skipped route completes")
	check(game.store.load_snapshot(game.save_path).data.chapter_complete,"rendered route persisted")
	var report = FileAccess.open(out+"/report.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures,"renderer":RenderingServer.get_video_adapter_name(),"scope":"actual Godot graphical renderer; synthetic menu input; physical controller and human sound listening unverified"},"  "))
	print("Rendered enrichment QA: ",checks," checks; ",failures," failures")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	quit(1 if failures else 0)
