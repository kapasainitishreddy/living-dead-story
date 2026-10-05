extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://home_runtime_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	check(game.has_method("dispatch_home"), "home has a playable runtime adapter")
	check(game.hud.has_method("show_home_dialogue"), "home choices and credits have accessible authored controls")
	if game.has_method("dispatch_home") and game.model.has_method("apply_home"):
		check(game.hud.home_authored.dialogues.home_ritual.choices[1].label == "Sit by the window", "window ritual offers requested sitting")
		check(game.hud.home_authored.ritual_callbacks.window.contains("sit") and not game.hud.home_authored.ritual_callbacks.window.contains("stand"), "window prose matches seated ritual")
		check(game.hud.home_authored.ticket_callbacks.drawer.contains("open"), "drawer prose matches visible saved ticket")
		await verify_routes(game)
		await verify_seated_pause(game)
		await verify_interruptions(game)
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("HOME RUNTIME ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
func completed_return(camera_choice := "take") -> Dictionary:
	var helper = load("res://tests/return_runtime.gd").new()
	var m = load("res://core/chapter_model.gd").new()
	m.restore(helper.orchard_seed(camera_choice))
	helper.free()
	for step in [["begin_return",null],["return_arrival",null],["return_farewell","thanks"],["return_departure",null],["return_finish",null]]: m.apply(step[0],step[1])
	return m.snapshot()
func verify_routes(game):
	var seed = completed_return("unused")
	for ticket in ["kettle","drawer","pocket"]:
		for ritual in ["tea","window","neither"]:
			for ending in ["train","sleep"]:
				var branch = ticket + "/" + ritual + "/" + ending
				check(game.model.restore(seed), "restore six chapters " + branch)
				game.route()
				game.show_return_state()
				check(game.hud.footer.get_children().any(func(b): return b.text.contains("Continue home")), "Chapter Six offers explicit home handoff " + branch)
				game.dispatch("begin_home")
				check(game.model.snapshot().home_checkpoint == "arrival", "home begins explicitly " + branch)
				check(game.hud.content.get_child(0).text == "Still Here", "home arrival panel " + branch)
				game.show_pause()
				game.hud.resume_pause()
				await process_frame
				check(game.hud.content.get_child(0).text == "Still Here", "pause restores arrival " + branch)
				game.dispatch("home_ticket")
				game.hud.footer.get_child(["kettle","drawer","pocket"].find(ticket)).pressed.emit()
				check(game.model.snapshot().home.ticket == ticket, "real ticket control " + branch)
				check(game.store.load_snapshot(game.save_path).data == game.model.snapshot(), "ticket durable before room update " + branch)
				game.dispatch("home_ritual")
				game.hud.footer.get_child(["tea","window","neither"].find(ritual)).pressed.emit()
				check(game.model.snapshot().home_checkpoint == "settled" and game.model.snapshot().home.ritual == ritual, "ritual settles room " + branch)
				if ritual == "window":
					check(game.home_viewing and not game.player.visual.visible, "window ritual presents a stable seated view " + branch)
					check(game.world_container.get_child(0).get_node("WindowSitter").visible, "window ritual physically seats original protagonist " + branch)
					game.dispatch("dismiss")
					check(not game.home_viewing and game.player.enabled and game.player.visual.visible, "Back from seated choice panel returns directly to exploration " + branch)
					game.dispatch("home_state")
				check(game.hud.footer.get_children().any(func(b): return b.text == "TAKE THE TRAIN") and game.hud.footer.get_children().any(func(b): return b.text == "GO BACK TO SLEEP"), "both last choices visible " + branch)
				game.hud.footer.get_child(["train","sleep"].find(ending)).pressed.emit()
				await process_frame
				var completed = game.model.snapshot()
				check(completed.campaign_complete and completed.home.completed and completed.home.ending == ending, "equal campaign completion " + branch)
				check(game.store.load_snapshot(game.save_path).data == completed, "ending durable before presentation " + branch)
				check(completed.dimensions == seed.dimensions and completed.npc_state == seed.npc_state and completed.souvenir_ids == seed.souvenir_ids, "ending gives no rank or prior consequence advantage " + branch)
				check(game.hud.content.get_children().any(func(label): return label.text.contains("Credits")), "credits follow settled ending " + branch)
				check(game.hud.footer.get_children().any(func(b): return not b.disabled and b.text.contains("Journey Mode")), "implemented authored continuation is eligible " + branch)
				check(game.model.restore(completed), "exact ending can reopen " + branch)
				game.hud.close_all()
				game.route()
				check(not game.home_cinematic and game.hud.modal_visible(), "completed reopen shows credits without replay " + branch)
				check(game.hud.content.get_child(1).text.contains("train" if ending == "train" else "sleep"), "reopened ending keeps branch " + branch)
				game.dispatch("dismiss")
				game.dispatch("home_view")
				check(game.home_viewing and not game.player.enabled and not game.player.visual.visible, "optional stable room view " + branch)
				game.show_pause()
				check(game.world_container.get_child(0).paused, "whole home view pauses " + branch)
				game.hud.resume_pause()
				check(game.home_viewing and not game.player.enabled, "pause retains fixed home view " + branch)
				var back = InputEventAction.new()
				back.action = "ui_cancel"
				back.pressed = true
				game._unhandled_input(back)
				check(not game.home_viewing and game.player.enabled and game.player.visual.visible, "Back restores home exploration " + branch)
func verify_interruptions(game):
	var seed = completed_return("lend")
	game.model.restore(seed)
	game.route()
	game.dispatch("begin_home")
	game.dispatch("home_ticket","pocket")
	var interrupted = game.model.snapshot()
	game.hud.close_all()
	game.model.restore(interrupted)
	game.route()
	game.dispatch("home_state")
	check(game.hud.footer.get_child(0).text.contains("Make tea"), "ticket interruption resumes ritual without repeating placement")
	game.dispatch("home_ritual","neither")
	var settings = game.model.snapshot().settings
	settings.reduced_motion = false
	game.change_settings(settings)
	game.dispatch("home_end","sleep")
	var world = game.world_container.get_child(0)
	world.set_process(false)
	check(game.home_cinematic and world.ending_active, "normal ending has physical presentation")
	var durable = game.model.snapshot()
	game.dispatch("home_end","train")
	check(game.model.snapshot() == durable, "repeated ending cannot overwrite saved choice")
	game.show_pause()
	var frozen = world.cinematic_state()
	world._process(100.0)
	check(world.cinematic_state() == frozen, "pause freezes home ending presentation")
	settings.reduced_motion = true
	game.change_settings(settings)
	check(game.home_cinematic and world.ending_active, "motion setting cannot resolve an open pause")
	game.hud.resume_pause()
	await process_frame
	check(not game.home_cinematic and game.hud.modal_visible(), "resume settles reduced ending and shows credits")
	check(game.model.snapshot().home.ending == "sleep", "motion setting cannot change ending")
	game.model.restore(seed)
	game.hud.close_all()
	game.route()
	game.dispatch("begin_home")
	game.dispatch("home_ticket","kettle")
	game.dispatch("home_ritual","tea")
	settings.reduced_motion = false
	game.change_settings(settings)
	game.dispatch("home_end","train")
	var back = InputEventAction.new()
	back.action = "ui_cancel"
	back.pressed = true
	game._unhandled_input(back)
	check(not game.home_cinematic and game.hud.modal_visible(), "Back skips physical ending directly to credits")
	check(game.model.snapshot().home.ending == "train", "skip preserves legitimate train ending")

func seated_bones(sitter) -> Array:
	var poses: Array = []
	for index in range(sitter.skeleton.get_bone_count()):
		poses.append([sitter.skeleton.get_bone_pose_position(index), sitter.skeleton.get_bone_pose_rotation(index), sitter.skeleton.get_bone_pose_scale(index)])
	return poses
func verify_seated_pause(game):
	game.model.restore(completed_return("lend"))
	game.hud.close_all()
	game.route()
	game.dispatch("begin_home")
	game.dispatch("home_ticket", "kettle")
	game.dispatch("home_ritual", "window")
	await process_frame
	await process_frame
	var world = game.world_container.get_child(0)
	var sitter = world.get_node("WindowSitter")
	var hips = sitter.skeleton.global_transform * sitter.skeleton.get_bone_global_pose(sitter._bone_index("Hips")).origin
	var knee = sitter.skeleton.global_transform * sitter.skeleton.get_bone_global_pose(sitter._bone_index("ShinLeft")).origin
	check(hips.y > 0.4 and hips.y < 0.8 and absf(hips.y-knee.y) < 0.22, "window rig keeps seated geometry after actual engine frames")
	for modal_open in [true, false]:
		if not modal_open:
			game.dispatch("dismiss")
			game.dispatch("home_view")
		check(game.home_viewing and sitter.visible, "seated context is active before pause " + str(modal_open))
		game.show_pause()
		var frozen = seated_bones(sitter)
		for reduced in [false, true]:
			var settings = game.model.snapshot().settings
			settings.reduced_motion = reduced
			settings.text_scale = 1.5 if not reduced else 2.0
			game.change_settings(settings)
			await process_frame
			check(world.paused and game.hud.pause_active and game.home_viewing and sitter.visible, "settings retain paused actual seated context " + str(modal_open) + "/" + str(reduced))
			check(seated_bones(sitter) == frozen, "paused settings keep every seated bone " + str(modal_open) + "/" + str(reduced))
		game.hud.resume_pause()
		await process_frame
		check(game.home_viewing and sitter.visible and not game.player.enabled and not world.paused, "resume preserves actual seated view " + str(modal_open))
		if modal_open: check(game.hud.modal_visible(), "resume restores the settled last-choice panel")
	game.dispatch("home_leave_view")
	check(not sitter.visible and game.player.visual.visible and game.player.enabled, "seated close view exit keeps one walking protagonist")
