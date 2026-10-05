extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func cameras(node: Node, visible_only: bool = false) -> Array:
	var result = []
	for child in node.find_children("*", "Node3D", true, false):
		if child.scene_file_path == "res://assets/characters/mira/camera.glb" and (not visible_only or child.is_visible_in_tree()): result.append(child)
	return result
func assert_take(game, label: String):
	var world = game.world_container.get_child(0)
	check(cameras(world).size() == 1 and cameras(world, true).size() == 1, label + " has exactly one original camera in the whole world")
	check(cameras(game.player).size() == 1 and game.player.visual.prop_socket.get_child_count() == 1, label + " has one camera and one hand-socket child on the protagonist")
	check(cameras(world.get_node("Mira")).is_empty(), label + " transfers ownership away from Mira")
func run():
	var game = load("res://main.tscn").instantiate()
	var path = "user://opening_camera_lifecycle_" + str(Time.get_ticks_usec()) + ".json"
	game.save_path = path
	root.add_child(game)
	await process_frame
	for action in ["leave_apartment", "meet_stranger", "read_board", "board_train", "meet_passenger", "arrive_shore"]: game.model.apply(action)
	game.route()
	game.dispatch("assist")
	game.dispatch("choose_camera", "take")
	await process_frame
	assert_take(game, "first take")
	for i in 3:
		var previous = game.player.get_instance_id()
		game.route()
		await process_frame
		check(game.player.get_instance_id() != previous, "route replaces rather than retains the protagonist instance " + str(i))
		assert_take(game, "same-shore rebuild " + str(i))
	game.dispatch("resolve_action", "completed")
	await process_frame
	assert_take(game, "return to carriage")
	game.dispatch("return_train")
	await process_frame
	assert_take(game, "breakfast")
	game.dispatch("have_breakfast")
	await process_frame
	assert_take(game, "complete checkpoint")
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	game.save_path = path
	root.add_child(game)
	await process_frame
	check(game.model.snapshot().camera_choice == "take", "fresh game reload restores the exact camera branch")
	assert_take(game, "fresh save reload")
	for i in 3:
		game.route()
		await process_frame
		assert_take(game, "post-reload rebuild " + str(i))
	# Existing later-world ownership remains controlled by its own saved lend route.
	var snapshot = game.model.snapshot()
	snapshot.camera_choice = "lend"
	snapshot.return_state.farewell = "thanks"
	snapshot.return_checkpoint = "arrival"
	var later = load("res://world/return_world.gd").new().build(snapshot)
	root.add_child(later)
	await process_frame
	var later_mira = later.get_node("Mira")
	var borrowed = later_mira.get_attached_prop("camera")
	check(borrowed != null and borrowed.get_parent() == later_mira.prop_socket and borrowed.is_visible_in_tree(), "existing Chapter Six borrowed camera stays on Mira’s original hand socket")
	check(cameras(later).size() == 1, "later borrowed-camera world still contains one original camera")
	later.queue_free(); game.queue_free(); await process_frame
	print("Opening camera lifecycle: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
