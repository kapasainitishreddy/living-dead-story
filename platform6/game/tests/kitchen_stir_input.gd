extends SceneTree
# Native regression for the optional, real E/A/touch ladle interaction.
# This deliberately uses the authored KitchenWorld, not a re-created model.
var checks := 0
var failures := 0

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize(): call_deferred("run")

func run():
	var saved = {
		"campaign_chapter":"night_kitchen", "kitchen_checkpoint":"supper",
		"camera_choice":"unused", "settings":{"reduced_motion":false,"graphics":"low"},
		"paper":{"star":"empty","layout":"boat_star_leaf","length":"long","fold":"wider","mode":"watch","completed":true},
		"kitchen":{"mode":"help","served":true,"exchange":"unselected","departure":"unselected","completed":false}
	}
	var room = load("res://world/kitchen_world.gd").new().build(saved)
	root.add_child(room)
	await process_frame
	room.set_process(false)
	var heard: Array[String] = []
	room.gesture_cue.connect(func(kind: String): heard.append(kind))
	room.begin_gesture("join_help",Callable())
	check(not room.stir_input_window_open() and not room.offer_stir_input(), "input before stirring begins is ignored")
	room._process(0.60)
	var soup_before: float = room.get_node("SoupPot/SoupSurface").rotation.y
	var ladle_before: Vector3 = room.get_node("Ladle").position
	check(room.stir_input_window_open() and room.offer_stir_input(), "a real interact press contributes a turn")
	check(room.stir_input_count == 1, "first nudge is counted only once")
	check(room.get_node("SoupPot/SoupSurface").rotation.y > soup_before + 0.30, "input visibly moves the actual soup surface")
	check(room.get_node("Ladle").position.distance_to(ladle_before) > 0.04, "input moves the actual ladle instead of only a caption")
	check(not room.offer_stir_input(), "held or rapid inputs do not pile up sounds")
	room._process(0.30)
	check(room.offer_stir_input(), "second deliberate nudge responds")
	room._process(0.30)
	check(room.offer_stir_input(), "third deliberate nudge responds")
	room._process(0.30)
	check(not room.offer_stir_input() and room.stir_input_count == 3, "input remains bounded, with no grind mechanic")
	room.set_paused(true)
	check(not room.offer_stir_input(), "pause never stirs or generates sound")
	room.set_paused(false)
	room._process(2.8)
	check(not room.offer_stir_input(), "serving does not accept a late stirring press")
	room.finish_gesture()
	check(not room.gesture_active and room.get_node("PlayerPlace/Bowl/Soup").visible, "identical durable served meal without tap requirement")
	check(heard.count("stir") == 4, "three nudges add exactly three sounds to one automatic stir")
	room.begin_gesture("join_watch",Callable())
	room._process(0.65)
	check(not room.offer_stir_input() and room.stir_input_count == 0, "spectator mode never requires or receives cooking input")
	room.finish_gesture()
	room.apply_preferences(true)
	room.begin_gesture("join_help",Callable())
	check(not room.gesture_active and not room.offer_stir_input(), "reduced motion completes the same meal without animation or taps")
	check(room.get_node("PlayerPlace/Bowl/Soup").visible, "reduced motion preserves the actual bowl")
	# The actual touch button must stay available during a modal-free help gesture,
	# even though the player's walking controls are deliberately disabled.
	room.apply_preferences(false)
	room.begin_gesture("join_help",Callable())
	room._process(0.6)
	var touch = load("res://ui/touch_controls.gd").new()
	root.add_child(touch)
	await process_frame
	touch.set_touch_mode(true)
	touch.set_available(false,room.stir_input_window_open(),true)
	check(touch.interact_button.visible and not touch.interact_button.disabled and not touch.stick.visible, "touch can stir while walking stays locked")
	touch.interact_pressed.connect(func(): room.offer_stir_input())
	var tap_point = touch.interact_button.get_global_rect().get_center()
	var down = InputEventScreenTouch.new()
	down.index = 0
	down.position = tap_point
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up = InputEventScreenTouch.new()
	up.index = 0
	up.position = tap_point
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	check(room.stir_input_count == 1, "genuine finger press and release dispatches one optional soup stir")
	room.set_paused(true)
	touch.set_available(false,room.stir_input_window_open(),true)
	check(touch.interact_button.disabled or not touch.interact_button.visible, "paused help hides the cooking interaction")
	touch.queue_free()
	room.free()
	await process_frame
	print("Kitchen optional stir Godot checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
