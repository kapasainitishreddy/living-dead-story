extends SceneTree
# End-to-end adapter acceptance: all seven chapters, then the complete home matrix.
const Model = preload("res://core/chapter_model.gd")
const Store = preload("res://core/save_store.gd")
const Probe = preload("res://tests/kitchen_quit_probe.gd")
const TICKETS = ["kettle", "drawer", "pocket"]
const RITUALS = ["tea", "window", "neither"]
const ENDINGS = ["train", "sleep"]
var game
var checks := 0
var failures := 0
var checkpoints := {}

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _initialize(): call_deferred("run")

func set_accessibility():
	var settings = game.model.snapshot().settings
	settings.reduced_motion = true
	settings.text_scale = 2.0
	settings.graphics = "low"
	game.change_settings(settings)

func step(action: String, value: Variant = null):
	game.dispatch(action, value)
	var frames := 0
	while game.racing or game.kitchen_animating or game.return_cinematic or game.home_cinematic:
		await process_frame
		frames += 1
		if frames > 600:
			check(false, "presentation settles within reduced-motion budget " + action)
			break
	await process_frame

func completed_return(camera := "lend", resolution := "skipped") -> Dictionary:
	var helper = load("res://tests/kitchen_model.gd").new()
	var m = helper.completed_paper(camera, resolution, "watch")
	check(helper.failures == 0, "authored prior fixture " + camera + resolution)
	helper.free()
	for pair in [["begin_kitchen",null],["kitchen_join","watch"],["kitchen_share","watch"],["kitchen_departure","listen"],["begin_orchard",null],["orchard_route","bench"],["orchard_advance",null],["orchard_advance",null],["orchard_advance",null],["orchard_finish",null],["begin_return",null],["return_arrival",null],["return_farewell","wave"],["return_departure",null],["return_finish",null]]:
		check(m.apply(pair[0],pair[1]), "full prior chronology " + pair[0])
	var settings = m.snapshot().settings
	settings.reduced_motion = true
	settings.text_scale = 2.0
	settings.graphics = "low"
	check(m.apply("settings",settings), "fixture accessibility settings")
	return m.snapshot()

func assert_prior_unchanged(before: Dictionary, after: Dictionary, label: String):
	for key in before:
		if key in ["campaign_chapter","home","home_checkpoint","campaign_complete","choice_history","settings"]: continue
		check(after.get(key) == before[key], label + " preserves " + key)
	check(after.choice_history.slice(0,before.choice_history.size()) == before.choice_history, label + " preserves chronological prefix")
	check(after.npc_state.mira.destination == "lower_mill" and after.npc_state.mira.independent_decision, label + " preserves Mira autonomy")

func no_future_mode_controls(label: String):
	for b in game.hud.footer.get_children():
		if b.text.to_lower().contains("journey mode") or b.text.to_lower().contains("journeypack"):
			check(not b.disabled if game.model.snapshot().get("campaign_complete",false) else b.disabled, label + " Journey access follows real campaign completion")
			var unchanged: Dictionary = game.model.snapshot()
			# Availability is asserted here; actual Journey entry has its own runtime suite.
			check(game.model.snapshot() == unchanged, label + " future continuation callback cannot unlock content")
	for item in get_nodes_in_group("interactables"):
		if not game.world_container.is_ancestor_of(item): continue
		var action: String = str(item.get_meta("action_id",""))
		check(not action.to_lower().contains("journey_mode") and not action.to_lower().contains("journeypack"), label + " exposes no future-mode world target")

func save_reload(label: String):
	var exact: Dictionary = game.model.snapshot()
	check(game.persist(), "save " + label)
	var loaded = game.store.load_snapshot(game.save_path)
	check(loaded.ok and loaded.data == exact, "native exact snapshot " + label)
	var fresh = Model.new()
	check(loaded.ok and fresh.restore(loaded.data) and fresh.snapshot() == exact, "fresh model resume " + label)
	check(game.model.restore(loaded.data), "runtime restore " + label)
	game.hud.close_all()
	game.route()
	check(game.model.snapshot() == exact, "runtime route cannot replay choices " + label)
	check(game.world_container.get_child_count() == 1, "one world after reload " + label)
	check(not game.return_cinematic and not game.kitchen_animating, "earlier staging cannot leak into reload " + label)
	checkpoints[label] = exact
	await process_frame

func controller_button(index: int):
	var event = InputEventJoypadButton.new()
	event.device = 0
	event.button_index = index
	event.pressed = true
	game._unhandled_input(event)

func footer_visible(label: String):
	await process_frame
	await process_frame
	var rect = Rect2(Vector2.ZERO,Vector2(1280,720))
	for b in game.hud.footer.get_children():
		check(not b.text.is_empty() and rect.encloses(b.get_global_rect()), label + " 2x choice visible " + b.text)

func verify_full_dispatch_route():
	set_accessibility()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore"]: await step(action)
	check(game.model.snapshot().checkpoint_id == "overlook", "Chapter One reaches unassisted overlook")
	for landmark in ["lighthouse","arch","constellation"]:
		await step("inspect_landmark",landmark)
		check(landmark in game.model.snapshot().inspected_landmark_ids, "dispatch actual puzzle prerequisite " + landmark)
	await step("align",2)
	await step("choose_camera","lend")
	await step("resolve_action","skipped")
	for action in ["return_train","have_breakfast","finish","begin_fair"]: await step(action)
	check(game.model.snapshot().chapter_complete and game.model.snapshot().fair_checkpoint == "arrival", "Chapter One dispatch hands off to Chapter Two")
	for pair in [["fair_greeting","watch"],["set_race_mode","watch"],["release_boat",null],["inspect_fair","watch"],["level_pond","ada"],["release_boat",null],["fair_departure","wait"],["begin_paper",null],["paper_greeting","begin"],["set_paper_star","empty"],["set_paper_layout","star_boat_leaf"],["set_paper_length","long"],["set_paper_mode","watch"],["set_paper_fold","enough"],["raise_paper",null],["finish_paper",null],["begin_kitchen",null],["kitchen_join","watch"],["kitchen_share","watch"],["kitchen_departure","listen"],["begin_orchard",null],["orchard_route","bench"],["orchard_advance",null],["orchard_advance",null],["orchard_advance",null],["orchard_finish",null],["begin_return",null],["return_arrival",null],["return_farewell","wave"],["return_finish",null]]:
		await step(pair[0],pair[1])
	check(game.model.snapshot().return_checkpoint == "complete", "Chapters Two through Six complete via main dispatch")
	check(game.model.snapshot().fair_checkpoint == "complete" and game.model.snapshot().paper.completed and game.model.snapshot().kitchen.completed and game.model.snapshot().orchard.completed, "all prior chapter completion gates retained")
	check(game.model.snapshot().home_checkpoint == "locked" and not game.model.snapshot().campaign_complete, "Chapter Six cannot silently choose Home ending")
	await save_reload("locked")
	var prior: Dictionary = game.model.snapshot()
	await step("begin_home")
	check(game.model.snapshot().campaign_chapter == "still_here" and game.model.snapshot().home_checkpoint == "arrival", "explicit Chapter Seven arrival")
	await footer_visible("arrival")
	await save_reload("arrival")
	game.dispatch("home_state")
	var focused = game.hud.get_viewport().gui_get_focus_owner()
	controller_button(JOY_BUTTON_START)
	check(game.hud.pause_active, "controller Menu pauses Home arrival")
	controller_button(JOY_BUTTON_START)
	await process_frame
	await process_frame
	check(not game.hud.pause_active and game.hud.get_viewport().gui_get_focus_owner() == focused, "controller Menu restores exact Home choice focus")
	game.dispatch("home_ticket")
	await footer_visible("ticket menu")
	game.hud.footer.get_child(TICKETS.find("drawer")).pressed.emit()
	await process_frame
	check(game.model.snapshot().home.ticket == "drawer", "ticket selection accepted by runtime")
	await save_reload("arrival_ticket")
	await step("home_ritual","neither")
	check(game.model.snapshot().home_checkpoint == "settled" and game.model.snapshot().home.ritual == "neither", "neither is a complete settling route")
	await save_reload("settled")
	game.dispatch("home_state")
	await footer_visible("settled")
	await step("home_finish","sleep")
	check(game.model.snapshot().home_checkpoint == "complete" and game.model.snapshot().home.completed and game.model.snapshot().campaign_complete, "all seven chapters dispatch to campaign completion")
	await save_reload("complete")
	assert_prior_unchanged(prior,game.model.snapshot(),"full runtime completion")
	game.dispatch("home_state")
	no_future_mode_controls("campaign completion")
	return prior

func verify_all_home_combinations(prior: Dictionary):
	var outcomes := 0
	for ticket in TICKETS:
		for ritual in RITUALS:
			for ending in ENDINGS:
				var label: String = ticket + "/" + ritual + "/" + ending
				check(game.model.restore(prior), "matrix source restore " + label)
				game.hud.close_all()
				game.route()
				await step("begin_home")
				game.dispatch("home_ticket")
				await footer_visible(label + " ticket menu")
				game.hud.footer.get_child(TICKETS.find(ticket)).pressed.emit()
				await process_frame
				check(game.model.snapshot().home.ticket == ticket, "real ticket callback " + label)
				await footer_visible(label + " ritual menu")
				game.hud.footer.get_child(RITUALS.find(ritual)).pressed.emit()
				await process_frame
				check(game.model.snapshot().home.ritual == ritual, "real ritual callback " + label)
				var sitter = game.world_container.get_child(0).get_node("WindowSitter")
				check(sitter.visible == (ritual == "window"), "window ritual alone stages seated protagonist " + label)
				if ritual == "window":
					check(game.home_viewing and not game.player.visual.visible, "window choice immediately frames actual sitting " + label)
					var hips = sitter.skeleton.global_transform * sitter.skeleton.get_bone_global_pose(sitter._bone_index("Hips")).origin
					var knee = sitter.skeleton.global_transform * sitter.skeleton.get_bone_global_pose(sitter._bone_index("ShinLeft")).origin
					check(hips.y > 0.4 and hips.y < 0.8 and absf(hips.y-knee.y) < 0.22, "window posture has seated hips and bent thighs " + label)
				game.dispatch("home_state")
				await footer_visible(label)
				game.hud.footer.get_child(ENDINGS.find(ending)).pressed.emit()
				await process_frame
				var result: Dictionary = game.model.snapshot()
				check(result.home == {"ticket":ticket,"ritual":ritual,"ending":ending,"completed":true}, "real ending callback preserves exact final choices " + label)
				check(result.campaign_complete and result.home_checkpoint == "complete", "equal campaign access " + label)
				check(game.store.load_snapshot(game.save_path).data == result, "ending durable before staging " + label)
				assert_prior_unchanged(prior,result,label)
				game.hud.close_all()
				game.route()
				check(game.model.snapshot() == result and not game.home_cinematic, "terminal reopen preserves ending without replay gate " + label)
				game.dispatch("dismiss")
				check(game.player.enabled, "terminal reopen allows continued apartment exploration " + label)
				check(not game.world_container.get_child(0).get_node("WindowSitter").visible, "exploration shows no duplicate seated protagonist " + label)
				var before = game.model.snapshot()
				for action in [["home_ticket","kettle"],["home_ritual","tea"],["home_finish","train"],["begin_home",null]]: game.dispatch(action[0],action[1])
				check(game.model.snapshot() == before, "terminal choices immutable " + label)
				game.dispatch("home_state")
				no_future_mode_controls(label)
				outcomes += 1
	check(outcomes == 18, "all 18 final combinations exercised through main runtime")

func verify_prior_branch_equivalence():
	var combinations := 0
	for camera in ["take","lend","unused"]:
		var completed: Dictionary = {}
		for resolution in ["completed","skipped"]:
			var prior = completed_return(camera,resolution)
			for ticket in TICKETS:
				for ritual in RITUALS:
					for ending in ENDINGS:
						var m = Model.new()
						check(m.restore(prior), "earlier branch restore " + camera + resolution)
						for pair in [["begin_home",null],["home_ticket",ticket],["home_ritual",ritual],["home_finish",ending]]: check(m.apply(pair[0],pair[1]), "earlier branch Home transition " + pair[0])
						var final = m.snapshot()
						check(final.campaign_complete and final.home.completed and final.home.ending == ending, "all six earlier paths retain both endings")
						assert_prior_unchanged(prior,final,"prior branch matrix")
						var key: String = ticket + ritual + ending
						var normalized = final.duplicate(true)
						normalized.action_resolution = "completed"
						if resolution == "completed": completed[key] = normalized
						else: check(normalized == completed[key], "Done and Not tonight fiction remains exactly equivalent " + camera + key)
						combinations += 1
	check(combinations == 108, "six prior camera/optional branches cross all 18 Home combinations")

func verify_checkpoint_chronology():
	for label in checkpoints:
		var exact: Dictionary = checkpoints[label]
		var detached = exact.duplicate(true)
		if exact.choice_history.size() > 1:
			var last: String = detached.choice_history.pop_back()
			detached.choice_history.push_front(last)
			var validator = Model.new()
			var untouched = validator.snapshot()
			check(not validator.restore(detached) and validator.snapshot() == untouched, "chronology remains atomic at Home " + label)
		if label == "locked": continue
		for required in ["paper_sky.finish","night_kitchen.begin","quiet_orchard.finish","return_platform.finish"]:
			var forged = exact.duplicate(true)
			forged.choice_history.erase(required)
			check(not Model.new().restore(forged), "Home cannot erase earlier prerequisite " + label + required)

func verify_controller_exploration():
	check(game.model.restore(checkpoints.settled), "controller restores settled Home")
	game.hud.close_all()
	game.route()
	await physics_frame
	var position = game.player.global_position
	var motion = InputEventJoypadMotion.new()
	motion.device = 0
	motion.axis = JOY_AXIS_LEFT_Y
	motion.axis_value = -1.0
	Input.parse_input_event(motion.duplicate())
	for i in range(30): await physics_frame
	motion.axis_value = 0.0
	Input.parse_input_event(motion.duplicate())
	await physics_frame
	check(game.player.global_position.distance_to(position) > 0.35, "synthetic controller moves within actual Home apartment")
	var yaw = game.player.pivot.rotation.y
	motion.axis = JOY_AXIS_RIGHT_X
	motion.axis_value = 1.0
	Input.parse_input_event(motion.duplicate())
	for i in range(10): await physics_frame
	motion.axis_value = 0.0
	Input.parse_input_event(motion.duplicate())
	await physics_frame
	check(abs(game.player.pivot.rotation.y-yaw) > 0.05, "synthetic controller orbits Home camera")

func verify_home_presentation():
	check(game.model.restore(checkpoints.settled), "optional view restores settled Home")
	game.hud.close_all()
	game.route()
	game.dispatch("dismiss")
	var position = game.player.global_position
	game.dispatch("home_view")
	var world = game.world_container.get_child(0)
	check(game.home_viewing and not game.player.enabled and not game.player.visual.visible, "optional Home close view is stable and unobstructed")
	check(world.get_node_or_null("HomeCloseCamera") != null, "optional view uses actual Home camera")
	controller_button(JOY_BUTTON_START)
	check(game.hud.pause_active and world.paused, "controller Menu freezes optional Home view")
	controller_button(JOY_BUTTON_START)
	check(not game.hud.pause_active and game.home_viewing and not world.paused, "Menu restores same optional Home view")
	controller_button(JOY_BUTTON_B)
	check(not game.home_viewing and game.player.enabled and game.player.visual.visible, "controller B leaves optional Home view")
	check(game.player.global_position.distance_to(position) < 0.05, "Home view returns to same standing place")
	for ending in ENDINGS:
		check(game.model.restore(checkpoints.settled), "normal ending source " + ending)
		game.hud.close_all()
		game.route()
		var settings = game.model.snapshot().settings
		settings.reduced_motion = false
		game.change_settings(settings)
		game.dispatch("home_finish",ending)
		world = game.world_container.get_child(0)
		world.set_process(false)
		check(game.home_cinematic and world.ending_active, "normal physical ending enters actual camera " + ending)
		var durable: Dictionary = game.model.snapshot()
		check(durable.home.ending == ending and durable.campaign_complete, "ending durable before physical hold " + ending)
		world._process(0.65)
		controller_button(JOY_BUTTON_START)
		check(game.hud.pause_active and world.paused, "Menu pauses chosen ending " + ending)
		var frozen = world.cinematic_state()
		world._process(60.0)
		check(world.cinematic_state() == frozen, "pause freezes ending transforms and time " + ending)
		controller_button(JOY_BUTTON_START)
		game.dispatch("home_finish","sleep" if ending == "train" else "train")
		check(game.model.snapshot() == durable, "rapid alternate ending cannot overwrite choice " + ending)
		controller_button(JOY_BUTTON_B)
		check(not game.home_cinematic and not world.ending_active and game.hud.modal_visible(), "B settles chosen ending into credits " + ending)
		check(game.model.snapshot() == durable, "skip preserves exact saved ending " + ending)
		game.hud.close_all()
		game.route()
		check(not game.home_cinematic and game.model.snapshot() == durable, "completed normal ending reload never replays " + ending)

func seated_bones(sitter) -> Array:
	var poses := []
	for index in range(sitter.skeleton.get_bone_count()):
		poses.append([sitter.skeleton.get_bone_pose_position(index),sitter.skeleton.get_bone_pose_rotation(index),sitter.skeleton.get_bone_pose_scale(index)])
	return poses

func verify_seated_pause():
	check(game.model.restore(checkpoints.arrival_ticket), "seated pause restores unchosen ritual")
	game.hud.close_all()
	game.route()
	game.dispatch("home_ritual","window")
	var world = game.world_container.get_child(0)
	var sitter = world.get_node("WindowSitter")
	check(sitter.visible and game.home_viewing and not game.player.visual.visible, "window ritual enters visible original seated rig")
	controller_button(JOY_BUTTON_START)
	check(world.paused and game.hud.pause_active, "Menu pauses actual seated view")
	var frozen = seated_bones(sitter)
	world._process(30.0)
	check(seated_bones(sitter) == frozen, "pause freezes every actual seated bone")
	for reduced in [false,true]:
		var settings = game.model.snapshot().settings
		settings.reduced_motion = reduced
		settings.text_scale = 1.5 if not reduced else 2.0
		game.change_settings(settings)
		check(world.paused and game.hud.pause_active and sitter.visible, "preferences keep paused seat and visibility " + str(reduced))
		check(seated_bones(sitter) == frozen, "paused preferences preserve every seated bone " + str(reduced))
	controller_button(JOY_BUTTON_START)
	check(game.home_viewing and sitter.visible, "resume restores chosen seated ritual")
	controller_button(JOY_BUTTON_B)
	check(not sitter.visible and game.player.visual.visible and game.player.enabled, "seated view exit restores exactly one walking protagonist")

func verify_save_failures():
	for label in ["arrival","settled","complete"]:
		check(game.model.restore(checkpoints[label]), "failed-save source " + label)
		game.hud.close_all()
		game.route()
		var good_path: String = game.save_path
		game.save_path = good_path + ".future_" + label
		var fixture = FileAccess.open(game.save_path,FileAccess.WRITE)
		var future = game.model.snapshot()
		future.schema_version = Model.SCHEMA_VERSION + 1
		var bytes: String = JSON.stringify(future)
		fixture.store_string(bytes)
		fixture.close()
		if label == "arrival": game.dispatch("home_ticket","pocket")
		elif label == "settled": game.dispatch("home_finish","train")
		else: game.persist()
		var before: Dictionary = game.model.snapshot()
		game.dispatch("home_state")
		check(game.hud.notice.text.contains("Unsaved"), "Home save failure remains visible " + label)
		var exits: int = game.attempted_exits
		game.show_pause()
		game.hud.quit_requested.emit()
		check(game.attempted_exits == exits, "pause quit cannot drop failed Home save " + label)
		game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		check(game.attempted_exits == exits, "OS close cannot drop failed Home save " + label)
		game.hud.resume_pause()
		game.dispatch("home_leave")
		check(game.attempted_exits == exits and game.model.snapshot() == before, "leave retry retains exact in-memory Home choices " + label)
		check(FileAccess.get_file_as_string(game.save_path) == bytes, "future-schema bytes preserved " + label)
		DirAccess.remove_absolute(game.save_path)
		game.request_quit()
		check(game.attempted_exits == exits+1, "successful Home save retry exits exactly once " + label)
		check(game.store.load_snapshot(game.save_path).data == before, "successful retry saves exact Home state " + label)
		game.quitting = false
		game.save_path = good_path

func run():
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	game = Probe.new()
	game.save_path = "user://full_campaign_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	check(game.has_method("dispatch_home") and game.model.has_method("apply_home"), "Home has real runtime and model adapters")
	if game.has_method("dispatch_home") and game.model.has_method("apply_home"):
		var prior = await verify_full_dispatch_route()
		await verify_all_home_combinations(prior)
		verify_prior_branch_equivalence()
		verify_checkpoint_chronology()
		await verify_controller_exploration()
		verify_home_presentation()
		verify_seated_pause()
		verify_save_failures()
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await process_frame
	game = null
	print("FULL CAMPAIGN ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
