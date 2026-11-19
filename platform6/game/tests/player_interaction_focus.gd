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
	# Close bystanders remain reachable, but a deliberate look can settle a tie.
	var ahead = Node3D.new()
	ahead.name = "FrontDiscovery"
	ahead.position = Vector3(0.0,0.0,-1.3)
	root.add_child(ahead)
	ahead.add_to_group("interactables")
	var behind = Node3D.new()
	behind.name = "BehindDiscovery"
	behind.position = Vector3(0.0,0.0,1.15)
	root.add_child(behind)
	behind.add_to_group("interactables")
	player.pivot.rotation.y = 0.0
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == ahead, "looking ahead favors a visible discovery over a slightly closer rear object")
	check(player.interaction_focus_score(ahead,1.3) < player.interaction_focus_score(behind,1.15), "camera tie-break is bounded and directional")
	player.pivot.rotation.y = PI
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == behind, "turning the camera decisively changes a close focus")
	player.pivot.rotation.y = 0.0
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == ahead, "turning back restores the visible discovery without moving")
	behind.position.z = 0.38
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == behind, "much closer rear objects remain interactable without facing them")
	var seen = activations.size()
	player._unhandled_input(event)
	check(activations.size() == seen+1 and activations.back() == behind, "E/A still activates actual rear focus")
	player.set_preferences({"sensitivity":1.0,"reduced_motion":true})
	check(player.choose_nearest_interactable() == behind, "reduced motion retains usable interaction targeting")
	behind.position.z = 3.24
	ahead.position.z = -3.24
	player.nearest = player.choose_nearest_interactable()
	check(player.nearest == null, "view preference never extends hard interaction reach")
	ahead.queue_free()
	behind.queue_free()
	postcard.queue_free()
	player.queue_free()
	await process_frame
	print("Interaction focus Godot checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
