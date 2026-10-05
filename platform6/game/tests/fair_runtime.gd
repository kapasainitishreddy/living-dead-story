extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, label: String):
	checks += 1
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func step(game, action: String, value: Variant = null):
	game.dispatch(action,value)
	while game.racing: await process_frame
	await process_frame
func run():
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://fair_runtime_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await process_frame
	check(game.has_method("show_fair_state"),"runtime routes persistent fair state")
	check(game.hud.has_method("show_fair_config"),"HUD exposes accessible boat configuration")
	check(game.hud.has_method("show_fair_dialogue"),"HUD renders fair authored callback dialogue")
	if not game.model.snapshot().has("fair"):
		game.queue_free()
		await process_frame
		quit(1)
		return
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]: await step(game,action)
	await step(game,"choose_camera","unused")
	await step(game,"resolve_action","completed")
	for action in ["return_train","have_breakfast","finish"]: await step(game,action)
	check(game.hud.footer.get_children().any(func(b): return b.text.contains("Continue to the Unfinished Fair")),"chapter one exposes optional campaign adapter")
	game.hud.close_all()
	game.route()
	var finish_target
	for node in game.world_container.get_child(0).get_children():
		if node.get_meta("action_id","") == "finish": finish_target = node
	game.on_interact(finish_target)
	check(game.hud.footer.get_children().any(func(b): return b.text.contains("Continue to the Unfinished Fair")),"reloaded finished chapter reopens handoff")
	await step(game,"begin_fair")
	check(game.model.snapshot().fair_checkpoint == "arrival","chapter two begins only on explicit Continue")
	check(game.hud.content.get_child(1).text.contains("camera"),"unopened camera callback shown")
	var settings = game.model.snapshot().settings
	settings.reduced_motion = true
	settings.text_scale = 2.0
	game.change_settings(settings)
	await step(game,"fair_greeting","watch")
	check(game.hud.modal_visible() and not game.player.enabled,"fair greeting branch is playable modal")
	await step(game,"fair_continue","fair_setup")
	await step(game,"fair_config","sail")
	check(game.hud.footer.get_child_count() == 5,"three sail choices plus safe back navigation")
	game.show_pause()
	game.hud.resume_pause()
	await process_frame
	check(game.hud.content.get_child(0).text == "Boats with opinions","pause restores configuration body")
	await step(game,"set_sail","square")
	await step(game,"set_race_mode","watch")
	await step(game,"release_boat")
	check(game.model.snapshot().fair_checkpoint == "crooked_race","first race progresses to crooked pond investigation")
	check(game.hud.modal_visible() and not game.busy,"race completion restores dialogue without deadend")
	await step(game,"inspect_fair","watch")
	await step(game,"fair_continue","fair_level")
	await step(game,"level_pond","ada")
	check(game.model.snapshot().fair_checkpoint == "race_ready","NPC repair route levels pond")
	await step(game,"release_boat")
	check(game.model.snapshot().fair.outcome == "spectator","spectator route has canonical outcome")
	var canonical = game.model.snapshot()
	await step(game,"replay_race")
	check(game.model.snapshot().choice_history == canonical.choice_history,"replay never doubles choice consequences")
	await step(game,"fair_departure","wait")
	check(game.model.snapshot().fair_checkpoint == "complete","full second chapter is playable to completion")
	check(game.hud.content.get_child(1).text.contains("available build"),"ending truthfully marks available build boundary")
	check(game.model.snapshot().chapter_complete and game.model.snapshot().camera_choice == "unused","old chapter completion and camera retained")
	var saved = game.store.load_snapshot(game.save_path)
	check(saved.ok and saved.data.fair_checkpoint == "complete","full fair progress survives local reload")
	game.hud.close_all()
	game.route()
	await step(game,"replay_race")
	check(game.model.snapshot().fair_checkpoint == "complete","postcompletion replay remains completed")
	game.dispatch("dismiss")
	check(game.player.enabled,"dismissal restores exploration at end of available build")
	game.queue_free()
	await process_frame
	print("Fair runtime checks: ",checks," failures: ",failures)
	quit(1 if failures else 0)
