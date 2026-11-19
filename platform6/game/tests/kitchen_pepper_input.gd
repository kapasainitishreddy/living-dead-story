extends SceneTree
# Real native Godot scene, handoff and touch policy for the optional shaker.
# Neither taps nor counts are persisted, and doing nothing still passes dinner.
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
	var room = load("res://world/kitchen_world.gd").new().build(state("pepper"))
	root.add_child(room)
	await process_frame
	room.set_process(false)
	check(room.get_node("PlayerPlace/Bowl/Soup/PepperFlecks").visible, "saved pepper action leaves seasoning on the actual soup")
	check(room.get_node("PlayerPlace/Bowl/Soup/PepperFlecks").get_child_count() == 6, "six small seasoning flecks share the soup surface")
	var cues: Array[String] = []
	room.gesture_cue.connect(func(kind: String): cues.append(kind))
	room.begin_gesture("pepper", Callable())
	check(not room.get_node("PlayerPlace/Bowl/Soup/PepperFlecks").visible, "fresh gesture shows seasoning only after the pass")
	check(not room.pepper_input_window_open() and not room.offer_pepper_input(), "unprompted beginning never needs a button")
	room._process(0.90)
	check(room.pepper_input_window_open(), "comfortable optional shake window opens")
	var shaker: Node3D = room.get_node("PepperShaker")
	var tilt_before: float = shaker.rotation.x
	check(room.offer_pepper_input(), "E/A/touch shake gently accepted")
	check(shaker.rotation.x > tilt_before + 0.15, "actual shaker visibly tips for the tap")
	check(room.get_node("PepperGrains").visible, "pepper grains visibly fall during the optional shake")
	check(room.get_node("PepperGrains/Grain0").position.y < room._rest["PepperGrains/Grain0"].origin.y, "grain drops toward the actual bowl")
	check(not room.offer_pepper_input(), "held input cannot double-trigger shaker Foley")
	room._process(0.31)
	check(room.offer_pepper_input(), "second relaxed shaker tap accepted")
	room._process(0.31)
	check(room.offer_pepper_input(), "third relaxed shaker tap accepted")
	check(room.pepper_input_count == 3 and not room.offer_pepper_input(), "shakes are bounded, never scored")
	check(cues.count("pepper") == 4, "three optional shakes and one natural shake each sound once")
	room.set_paused(true)
	var frozen: Transform3D = shaker.transform
	var grain_before: Vector3 = room.get_node("PepperGrains/Grain1").position
	room._process(10.0)
	check(shaker.transform.is_equal_approx(frozen), "pause freezes the physical shaker")
	check(room.get_node("PepperGrains/Grain1").position.is_equal_approx(grain_before), "pause freezes falling grains")
	check(not room.offer_pepper_input(), "pause cannot emit another pepper cue")
	room.set_paused(false)
	room._process(5.0)
	check(not room.gesture_active and not room.get_node("PepperGrains").visible, "finish cleans up all transient pepper grains")
	check(room.get_node("PlayerPlace/Bowl/Soup/PepperFlecks").visible, "saved seasoning remains after the interaction")
	check(room.get_node("PepperShaker").position.x < 0.1, "saved shaker remains at receiving end of table")
	room.begin_gesture("cup", Callable())
	check(room.get_node("PlayerPlace/Bowl/Soup/PepperFlecks").visible, "later cup conversation does not erase the pepper")
	check(not room.offer_pepper_input(), "pepper input cannot leak into other exchanges")
	room.finish_gesture()
	room.apply_preferences(true)
	room.begin_gesture("pepper", Callable())
	check(not room.gesture_active and room.get_node("PlayerPlace/Bowl/Soup/PepperFlecks").visible, "reduced motion restores identical seasoned dinner")
	check(not room.get_node("PepperGrains").visible, "reduced motion has no falling bits")
	room.apply_preferences(false)
	var reopened = load("res://world/kitchen_world.gd").new().build(state("pepper"))
	root.add_child(reopened)
	await process_frame
	check(reopened.get_node("PlayerPlace/Bowl/Soup/PepperFlecks").visible, "fresh saved instance restores seasoning")
	reopened.queue_free()
	room.begin_gesture("pepper", Callable())
	room._process(0.90)
	var touch = load("res://ui/touch_controls.gd").new()
	root.add_child(touch)
	await process_frame
	touch.set_touch_mode(true)
	touch.set_available(false,room.pepper_input_window_open(),true)
	check(touch.interact_button.visible and not touch.interact_button.disabled and not touch.stick.visible, "touch-only shake without a walking joystick")
	touch.interact_pressed.connect(func(): room.offer_pepper_input())
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
	check(room.pepper_input_count == 1, "single finger press dispatches one tactile pepper tap")
	room.set_paused(true)
	touch.set_available(false,room.pepper_input_window_open(),true)
	check(touch.interact_button.disabled or not touch.interact_button.visible, "paused pepper disables touch interact")
	touch.queue_free()
	room.queue_free()
	await process_frame
	print("Kitchen optional pepper checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
