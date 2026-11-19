extends SceneTree
# Actual Godot room and touch-button checks for tactile, entirely optional
# bread-sharing: the saved dinner exists without any rhythmic inputs.
var checks := 0
var failures := 0

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _initialize(): call_deferred("run")

func state(exchange: String = "unselected") -> Dictionary:
	return {
		"campaign_chapter":"night_kitchen", "kitchen_checkpoint":"supper",
		"camera_choice":"unused", "settings":{"reduced_motion":false,"graphics":"low"},
		"paper":{"star":"empty","layout":"boat_star_leaf","length":"long","fold":"wider","mode":"watch","completed":true},
		"kitchen":{"mode":"watch","served":true,"exchange":exchange,"departure":"unselected","completed":false}
	}

func run():
	var room = load("res://world/kitchen_world.gd").new().build(state())
	root.add_child(room)
	await process_frame
	room.set_process(false)
	check(not room.get_node("AdaSharedBread").visible, "unselected supper has no already-shared bread")
	room.apply_snapshot(state("bread")) # Real action persists before gesture is presented.
	check(room.get_node("AdaSharedBread").visible, "saved bread exchange places bread near Ada")
	var cues: Array[String] = []
	room.gesture_cue.connect(func(kind: String): cues.append(kind))
	room.begin_gesture("bread",Callable())
	check(not room.get_node("AdaSharedBread").visible, "the receiving plate waits until the handoff")
	check(not room.bread_input_window_open() and not room.offer_bread_input(), "early press is never required")
	room._process(0.68)
	check(room.bread_input_window_open(), "unhurried tear window opens")
	var right_hand = room.get_node("BreadBoard/TearingHands/RightHand")
	var hand_before: Vector3 = right_hand.position
	check(room.offer_bread_input(), "first E/A/touch tear is accepted")
	check(right_hand.position.distance_to(hand_before) > 0.06, "torn piece and actual hand move on input")
	check(room.get_node("BreadBoard/TearCrumbs").visible, "first tear releases visible original bread crumbs")
	check(not room.offer_bread_input(), "a held or double-triggered press is debounced")
	room._process(0.32)
	check(room.offer_bread_input(), "second relaxed tear is accepted")
	room._process(0.32)
	check(room.offer_bread_input(), "third relaxed tear is accepted")
	check(not room.offer_bread_input() and room.bread_input_count == 3, "exactly three optional nudges, no scoring loop")
	check(cues.count("bread") == 4, "three direct tears and one automatic tear each issue one Foley cue")
	room.set_paused(true)
	var frozen: Vector3 = right_hand.position
	room._process(5.0)
	check(right_hand.position.is_equal_approx(frozen), "pause freezes the half-torn hand pose")
	check(not room.offer_bread_input(), "pause cannot create an extra crumb or sound")
	room.set_paused(false)
	room._process(5.0)
	check(not room.gesture_active and not room.get_node("BreadBoard/TearCrumbs").visible, "gesture finishes and cleans up crumbs")
	check(room.get_node("AdaSharedBread").visible, "shared bread remains after the gesture")
	check(room.get_node("BreadBoard/TornHalf").position.x > 0.3, "the saved loaf remains visibly torn")
	room.begin_gesture("cup",Callable())
	check(room.get_node("AdaSharedBread").visible, "a later exchange does not erase Ada's bread")
	check(not room.offer_bread_input(), "bread presses do not leak into cup exchange")
	room.finish_gesture()
	room.apply_preferences(true)
	room.begin_gesture("bread",Callable())
	check(not room.gesture_active and room.get_node("AdaSharedBread").visible, "reduced motion settles to identical shared dinner")
	check(not room.get_node("BreadBoard/TearCrumbs").visible, "reduced motion leaves no transient bits")
	room.apply_preferences(false)
	var resumed = load("res://world/kitchen_world.gd").new().build(state("bread"))
	root.add_child(resumed)
	await process_frame
	check(resumed.get_node("AdaSharedBread").visible, "reopening a save restores the plate")
	check(resumed.get_node("BreadBoard/TornHalf").position.x > 0.3, "reopening a save restores torn loaf")
	resumed.queue_free()
	# Finger input uses the same accessible Interact control as the existing stir.
	room.begin_gesture("bread",Callable())
	room._process(0.65)
	var touch = load("res://ui/touch_controls.gd").new()
	root.add_child(touch)
	await process_frame
	touch.set_touch_mode(true)
	touch.set_available(false,room.bread_input_window_open(),true)
	check(touch.interact_button.visible and not touch.interact_button.disabled and not touch.stick.visible, "touch offers tear without requiring walking")
	touch.interact_pressed.connect(func(): room.offer_bread_input())
	var point = touch.interact_button.get_global_rect().get_center()
	var down = InputEventScreenTouch.new()
	down.index = 0
	down.position = point
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up = InputEventScreenTouch.new()
	up.index = 0
	up.position = point
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	check(room.bread_input_count == 1, "real finger press dispatches exactly one optional bread tear")
	room.set_paused(true)
	touch.set_available(false,room.bread_input_window_open(),true)
	check(touch.interact_button.disabled or not touch.interact_button.visible, "paused bread hides interact")
	touch.queue_free()
	room.queue_free()
	await process_frame
	print("Kitchen optional bread-share native checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
