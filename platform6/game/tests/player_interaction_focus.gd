extends SceneTree
# Native regression: close interactables have stable E/A, prompt and gaze owner.
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func run():
	var player = load("res://player/player.gd").new()
	root.add_child(player)
	await process_frame
	player.set_physics_process(false)
	var postcard = Node3D.new()
	postcard.name = "Postcard"
	postcard.position = Vector3(1.0, 0.0, 0.0)
	root.add_child(postcard)
	postcard.add_to_group("interactables")
	var cup = Node3D.new()
	cup.name = "WaitingCup"
	cup.position = Vector3(1.18, 0.0, 0.0)
	root.add_child(cup)
	cup.add_to_group("interactables")
	var activations: Array[Node] = []
	player.interact.connect(func(target): activations.append(target))
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == postcard, "arrival chooses nearer postcard")
	cup.position.x = 0.95
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == postcard, "five-centimeter difference does not twitch focus")
	player.update_nearby_attention(player.nearest, 0.0, 0.21)
	check(player.visual.gaze_target == postcard, "stable head attention follows prompt")
	var event = InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	player._unhandled_input(event)
	check(activations.size() == 1 and activations[0] == postcard, "E/A activates focused item")
	cup.position.x = 0.60
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == cup, "decisive approach changes interaction")
	player.update_nearby_attention(player.nearest, 0.0, 0.03)
	check(player.visual.gaze_target == null, "switch resets glance dwell")
	player.update_nearby_attention(player.nearest, 0.0, 0.21)
	check(player.visual.gaze_target == cup, "new stable item receives glance")
	cup.position.x = 1.04
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == cup, "small reverse step retains focus")
	cup.position.x = 2.5
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == postcard, "clear separation selects closer item")
	postcard.position.x = 3.23
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == cup, "out-of-range object releases focus")
	cup.position.x = 3.5
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == null, "no prompt without in-range item")
	postcard.position.x = 0.8
	cup.position.x = 0.9
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == postcard, "return into range reacquires")
	postcard.remove_from_group("interactables")
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == cup, "removed interactable cannot own prompt")
	cup.queue_free()
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == null, "queued deletion clears focus immediately")
	await process_frame
	player.update_nearby_attention(null, 0.0, 0.016)
	check(player.visual.gaze_target == null, "removed object also releases head glance")
	postcard.queue_free()
	player.queue_free()
	await process_frame
	print("Interaction focus Godot checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
