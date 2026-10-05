extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://orchard_runtime_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	check(game.has_method("dispatch_orchard"), "orchard has a playable adapter")
	check(game.hud.has_method("show_orchard_dialogue"), "orchard has accessible controls")
	if game.has_method("dispatch_orchard") and game.model.has_method("apply_orchard"):
		await verify_routes(game)
	game.queue_free()
	await process_frame
	print("ORCHARD RUNTIME ",checks," checks ",failures," failures")
	quit(1 if failures else 0)

func kitchen_seed():
	var helper = load("res://tests/kitchen_model.gd").new()
	var m = helper.completed_paper()
	helper.free()
	for pair in [["begin_kitchen",null],["kitchen_join","watch"],["kitchen_share","watch"],["kitchen_departure","listen"]]: check(m.apply(pair[0],pair[1]),"seed kitchen " + pair[0])
	var settings = m.snapshot().settings
	settings.reduced_motion = true
	settings.text_scale = 2.0
	m.apply("settings",settings)
	return m.snapshot()
func verify_routes(game):
	var seed = kitchen_seed()
	for route_ in ["cart","walk","bench"]:
		check(game.model.restore(seed),"restore kitchen " + route_)
		game.route()
		game.show_kitchen_state()
		check(game.hud.footer.get_children().any(func(b): return b.text.contains("Quiet Orchard")),"explicit orchard continuation")
		game.dispatch("begin_orchard")
		await process_frame
		check(game.model.snapshot().orchard_checkpoint == "arrival","arrival " + route_)
		game.show_pause()
		game.hud.resume_pause()
		check(game.hud.content.get_child(0).text == "The Quiet Orchard","arrival pause restores")
		var b = game.hud.footer.get_child(["cart","walk","bench"].find(route_))
		b.pressed.emit()
		await process_frame
		check(game.model.snapshot().orchard.route == route_,"real route choice " + route_)
		check(not game.hud.modal_visible() and (game.orchard_viewing and not game.player.enabled if route_ == "bench" else game.player.enabled),"bench starts seated; other routes free in actual world")
		var world = game.world_container.get_child(0)
		for beat in range(1,4):
			if route_ == "bench" and beat == 1:
				var manual = InputEventAction.new()
				manual.action = "interact"
				manual.pressed = true
				game._unhandled_input(manual)
			else: game.dispatch("orchard_advance")
			await process_frame
			check(game.model.snapshot().orchard.beat == beat,"manual durable beat " + str(beat))
			check(game.store.load_snapshot(game.save_path).data.orchard.beat == beat,"beat saved before presentation")
			game.show_pause()
			check(world.paused,"whole orchard paused")
			game.hud.resume_pause()
			check(not world.paused,"whole orchard resumed")
			var durable = game.model.snapshot()
			check(game.model.restore(durable),"exact beat reload")
			game.route()
			world = game.world_container.get_child(0)
			check(game.orchard_viewing and not game.player.enabled if route_ == "bench" else game.player.enabled,"reload preserves seated bench without animation gate")
		game.dispatch("orchard_finish")
		check(game.model.snapshot().orchard.completed,"equal complete " + route_)
		check(game.model.snapshot().npc_state == seed.npc_state and game.model.snapshot().dimensions == seed.dimensions,"rest changes no ranks or autonomy")
		game.player.global_position += Vector3(0.4,0,0.3)
		var before_view_position = game.player.global_position
		game.dispatch("orchard_view")
		check(game.orchard_viewing and not game.player.enabled,"optional stable view")
		check(not game.player.visual.visible,"view avoids avatar intersection")
		game.show_pause()
		game.hud.resume_pause()
		check(game.orchard_viewing and not game.player.enabled,"pause retains optional view")
		var back = InputEventAction.new()
		back.action = "ui_cancel"
		back.pressed = true
		game._unhandled_input(back)
		check(not game.orchard_viewing and game.player.enabled and game.player.visual.visible,"Back returns to orchard")
		check(game.player.global_position.distance_to(before_view_position) < 0.05,"close view returns to same standing place")
		var before = game.model.snapshot()
		game.dispatch("orchard_advance")
		game.dispatch("orchard_route","walk")
		check(game.model.snapshot() == before,"repeat cannot rewrite completion")
		game.show_orchard_state()
		for choice in game.hud.footer.get_children():
			check(choice.text.length() > 0,"2x text complete choice labelled")
