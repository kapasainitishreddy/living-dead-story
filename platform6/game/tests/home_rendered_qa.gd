extends SceneTree
# Native Compatibility-renderer evidence, never a headless substitute.
var game
var checks := 0
var failures := 0
var out := "res://../evidence/home/rendered"

func check(ok: bool, label: String):
	checks += 1
	print("QA ","PASS " if ok else "FAIL ",label)
	if not ok: failures += 1

func _initialize(): call_deferred("run")

func settle():
	await create_timer(0.14).timeout
	await process_frame
	await process_frame

func capture(id: String):
	await settle()
	var viewport_image = root.get_texture().get_image()
	check(not viewport_image.is_empty(), "actual rendered viewport " + id)
	check(viewport_image.save_png(out + "/" + id + ".png") == OK, "PNG saved " + id)

func return_seed(camera := "lend", resolution := "skipped") -> Dictionary:
	var helper = load("res://tests/full_campaign.gd").new()
	var value = helper.completed_return(camera,resolution)
	check(helper.failures == 0, "all prior chapters valid for rendered QA")
	helper.free()
	return value

func button(index: int):
	var event = InputEventJoypadButton.new()
	event.device = 0
	event.button_index = index
	event.pressed = true
	game._unhandled_input(event)

func choice_bounds(label: String):
	await settle()
	for b in game.hud.footer.get_children():
		check(root.get_visible_rect().encloses(b.get_global_rect()), label + " 2x visible " + b.text)

func settings(normal_motion := false, text_scale := 2.0):
	var preferences = game.model.snapshot().settings
	preferences.reduced_motion = not normal_motion
	preferences.text_scale = text_scale
	game.change_settings(preferences)

func start_home(source: Dictionary):
	check(game.model.restore(source), "restore exact full journey")
	game.hud.close_all()
	game.route()
	game.dispatch("begin_home")
	await settle()

func seated_bones(sitter) -> Array:
	var poses := []
	for index in range(sitter.skeleton.get_bone_count()):
		poses.append([sitter.skeleton.get_bone_pose_position(index),sitter.skeleton.get_bone_pose_rotation(index),sitter.skeleton.get_bone_pose_scale(index)])
	return poses

func seated_window_proof(ending: String):
	var world = game.world_container.get_child(0)
	var sitter = world.get_node("WindowSitter")
	check(game.home_viewing and sitter.is_visible_in_tree() and not game.player.visual.is_visible_in_tree(), "saved window ritual physically shows one seated protagonist")
	check(sitter.get_meta("character_id","") == "protagonist" and not sitter.animation_tree.active and not sitter.is_processing(), "seated view uses static original articulated rig")
	var hips = sitter.skeleton.global_transform * sitter.skeleton.get_bone_global_pose(sitter._bone_index("Hips")).origin
	var knee = sitter.skeleton.global_transform * sitter.skeleton.get_bone_global_pose(sitter._bone_index("ShinLeft")).origin
	check(hips.y > 0.4 and hips.y < 0.8 and absf(hips.y-knee.y) < 0.22, "actual hips rest at chair height and thighs bend")
	await capture(ending + "-window-seated")
	button(JOY_BUTTON_START)
	check(game.hud.pause_active and world.paused, "Menu pauses rendered seated ritual")
	var frozen = seated_bones(sitter)
	await create_timer(0.25).timeout
	check(seated_bones(sitter) == frozen, "real-time pause freezes every seated bone")
	for reduced in [false,true]:
		var preferences = game.model.snapshot().settings
		preferences.reduced_motion = reduced
		preferences.text_scale = 1.5 if not reduced else 2.0
		game.change_settings(preferences)
		await settle()
		check(game.hud.pause_active and world.paused and sitter.is_visible_in_tree(), "settings preserve open pause and actual seat " + str(reduced))
		check(seated_bones(sitter) == frozen, "settings preserve every seated bone while paused " + str(reduced))
		await capture(ending + "-window-paused-settings-" + str(reduced))
	button(JOY_BUTTON_START)
	await capture(ending + "-window-resumed")
	check(game.home_viewing and sitter.is_visible_in_tree(), "resumed view retains seated ritual")
	button(JOY_BUTTON_B)
	check(not sitter.is_visible_in_tree() and game.player.visual.is_visible_in_tree() and game.player.enabled, "exploration hides seated duplicate and restores walking protagonist")
	await capture(ending + "-window-exploration-one-protagonist")

func credit_availability(ending: String):
	var durable = game.model.snapshot()
	var entry
	check(durable.campaign_complete and durable.home.ending == ending, "credits keep equal completion and chosen ending " + ending)
	check(game.hud.content.get_children().any(func(label): return label.text.to_lower().contains("credits")), "actual credits are readable " + ending)
	check(game.hud.content.get_children().any(func(label): return label.text.contains("ten authored destinations")), "credits describe implemented bounded continuation " + ending)
	check(not game.journey.active, "completed campaign does not auto-enter Journey " + ending)
	check(not game.world_container.get_child(0).get_node("WindowSitter").visible, "credits hide seated duplicate")
	for b in game.hud.footer.get_children():
		var label = b.text.to_lower()
		check(not label.contains("score") and not label.contains("rank") and not label.contains("bonus"), "credits expose no ranked ending control " + b.text)
		if label.contains("journey mode"):
			entry = b
			check(not b.disabled and not label.contains("unavailable"), "implemented optional Journey entry enabled " + ending)
	check(is_instance_valid(entry), "both equal endings offer explicit continuation " + ending)
	if not is_instance_valid(entry): return
	entry.pressed.emit()
	check(game.journey.active and game.journey.model.snapshot().mode == "train", "actual credits button hands off to Journey carriage " + ending)
	check(game.hud.content.get_children().filter(func(control): return control is Button).size() == 10, "rendered Journey board has ten authored destination controls " + ending)
	check(game.model.snapshot() == durable and game.store.load_snapshot(game.save_path).data == durable, "Journey entry preserves exact campaign and campaign file " + ending)
	check(game.journey.path != game.save_path and game.journey.store.load_snapshot(game.journey.path).data == game.journey.model.snapshot(), "Journey handoff persists separate exact local save " + ending)
	await capture(ending + "-journey-handoff")
	var destinations = game.hud.content.get_children().filter(func(control): return control is Button)
	if not destinations.is_empty():
		destinations[0].grab_focus()
		game.hud.content.get_parent().ensure_control_visible(destinations[0])
		await settle()
		check(root.get_visible_rect().encloses(destinations[0].get_global_rect()), "first authored destination scrolls into visible viewport " + ending)
		await capture(ending + "-journey-first-destination")
	game.dispatch("journey_home")
	check(not game.journey.active and game.journey.model.snapshot().mode == "home", "comfortable Journey return home " + ending)
	check(game.model.snapshot() == durable and game.store.load_snapshot(game.save_path).data == durable, "return home preserves chosen ending and exact campaign save " + ending)
	check(game.world_container.get_child(0).get_node_or_null("WindowSitter") != null and not game.world_container.get_child(0).get_node("WindowSitter").visible, "Journey return restores apartment with seated duplicate hidden " + ending)

func full_ending(ending: String, ritual: String, ticket: String):
	await start_home(return_seed("lend" if ending == "train" else "unused"))
	settings(false)
	await capture(ending + "-arrival-text2")
	await choice_bounds(ending + " arrival")
	var focus = game.hud.get_viewport().gui_get_focus_owner()
	button(JOY_BUTTON_START)
	check(game.hud.pause_active, "Menu pauses arrival " + ending)
	await capture(ending + "-arrival-pause")
	button(JOY_BUTTON_START)
	await settle()
	check(game.hud.get_viewport().gui_get_focus_owner() == focus, "Menu restores choice focus " + ending)
	await choice_bounds(ending + " restored arrival")
	game.dispatch("home_ticket")
	await capture(ending + "-ticket-menu-text2")
	await choice_bounds(ending + " ticket menu")
	game.hud.footer.get_child(["kettle","drawer","pocket"].find(ticket)).pressed.emit()
	await capture(ending + "-ticket-choice-text2")
	await choice_bounds(ending + " ritual menu")
	game.hud.footer.get_child(["tea","window","neither"].find(ritual)).pressed.emit()
	if ritual == "window": check(game.home_viewing and game.world_container.get_child(0).get_node("WindowSitter").visible and not game.player.visual.visible, "window choice immediately enters actual seated view")
	await capture(ending + "-settled-text2")
	await choice_bounds(ending + " settled")
	game.dispatch("dismiss")
	if ritual == "window":
		game.dispatch("home_view")
		await seated_window_proof(ending)
	await capture(ending + "-apartment-wide")
	var standing_place = game.player.global_position
	game.dispatch("home_view")
	check(game.home_viewing and not game.player.enabled and not game.player.visual.visible, "optional stable physical close view " + ending)
	check(game.world_container.get_child(0).get_node("WindowSitter").visible == (ritual == "window"), "optional view shows sitter only for saved window ritual " + ending)
	await capture(ending + "-optional-home-view")
	button(JOY_BUTTON_START)
	var world = game.world_container.get_child(0)
	var frozen_view = world.cinematic_state()
	await create_timer(0.25).timeout
	check(world.cinematic_state() == frozen_view, "optional view pause freezes scene " + ending)
	button(JOY_BUTTON_START)
	check(game.home_viewing, "pause restores optional view " + ending)
	button(JOY_BUTTON_B)
	check(game.player.enabled and not game.home_viewing and game.player.global_position.distance_to(standing_place) < 0.06, "B returns to same apartment standing place " + ending)
	check(not world.get_node("WindowSitter").visible and game.player.visual.visible, "optional view exit leaves one walking protagonist " + ending)
	settings(true,1.0)
	game.dispatch("home_finish",ending)
	world = game.world_container.get_child(0)
	check(game.home_cinematic and world.ending_active, "normal ending starts physical hold " + ending)
	var durable = game.model.snapshot()
	check(durable.home.ending == ending and durable.campaign_complete and game.store.load_snapshot(game.save_path).data == durable, "ending saved before staging " + ending)
	await capture(ending + "-ending-start")
	button(JOY_BUTTON_START)
	var frozen = world.cinematic_state()
	await capture(ending + "-ending-pause")
	await create_timer(0.25).timeout
	check(world.cinematic_state() == frozen, "pause freezes ending actor/props/camera/time " + ending)
	button(JOY_BUTTON_START)
	var duration = world.ending_duration
	var next_capture := 0.28
	var elapsed := 0.0
	while game.home_cinematic and elapsed < 45.0:
		var progress: float = world.ending_elapsed / maxf(float(duration),0.01)
		if progress >= next_capture:
			await capture(ending + "-ending-" + str(roundi(next_capture*100)))
			next_capture += 0.25
		await create_timer(0.08).timeout
		elapsed += 0.08
	check(not game.home_cinematic and not world.ending_active, "normal physical ending reaches credits " + ending)
	check(game.hud.modal_visible() and game.model.snapshot() == durable, "quiet hold leads to credits without changing branch " + ending)
	await credit_availability(ending)
	await capture(ending + "-credits")
	settings(false)
	await choice_bounds(ending + " credits")
	await capture(ending + "-credits-text2")
	game.hud.close_all()
	game.route()
	check(not game.home_cinematic and game.model.snapshot().home.ending == ending, "completed reload retains ending and skips replay " + ending)
	await capture(ending + "-completed-reopen")

func skipped_endings():
	for ending in ["train","sleep"]:
		await start_home(return_seed("take","completed"))
		settings(false)
		game.dispatch("home_ticket","pocket")
		game.dispatch("home_ritual","neither")
		settings(true)
		game.dispatch("home_finish",ending)
		await settle()
		var exact = game.model.snapshot()
		button(JOY_BUTTON_B)
		check(not game.home_cinematic and game.hud.modal_visible(), "B skips staging into credits " + ending)
		check(game.model.snapshot() == exact, "B preserves chosen ending " + ending)
		await credit_availability(ending)
		await capture(ending + "-skipped-credits")

func run():
	if DisplayServer.get_name() == "headless":
		printerr("Native renderer required for Home viewport evidence")
		quit(2)
		return
	out = ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://home_rendered_" + str(Time.get_ticks_usec()) + ".json"
	game.journey_save_path = "user://home_rendered_journey_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await settle()
	check(game.has_method("dispatch_home"), "Chapter Seven has actual playable adapter")
	if game.has_method("dispatch_home"):
		await full_ending("train","tea","kettle")
		await full_ending("sleep","window","drawer")
		await skipped_endings()
	game.audio.shutdown()
	await create_timer(0.25).timeout
	game.queue_free()
	await process_frame
	await process_frame
	game = null
	print("HOME RENDERED QA ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
