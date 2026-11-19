extends SceneTree
# Native regression for accessible optional cooking action names. Exercise
# the real main-script naming policy and actual multi-touch control signal.
var checks := 0
var failures := 0

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize(): call_deferred("run")

func run():
	# Main is deliberately not added to the tree, avoiding a save/world start.
	var game = load("res://main.gd").new()
	check(game.kitchen_gesture_action_label() == "", "ordinary exploration has no kitchen hint")
	var labels := {"join_help":"Stir soup", "bread":"Tear bread", "pepper":"Shake pepper"}
	for action in labels:
		game.kitchen_gesture_id = action
		check(game.kitchen_gesture_action_label() == labels[action], "correct contextual action for " + action)
	game.kitchen_gesture_id = "cup"
	check(game.kitchen_gesture_action_label() == "", "cup conversation cannot claim an optional cooking input")
	game.kitchen_gesture_id = ""
	check(game.kitchen_gesture_action_label() == "", "leaving kitchen clears old action text")
	var touch = load("res://ui/touch_controls.gd").new()
	root.add_child(touch)
	await process_frame
	touch.set_touch_mode(true)
	var verbs := {"Stir soup":"Stir", "Tear bread":"Tear", "Shake pepper":"Shake"}
	for action in verbs:
		touch.set_interact_label(action)
		touch.set_available(false,true,true)
		check(touch.interact_button.text == verbs[action], "real finger button describes " + action)
		check(touch.interact_button.visible and not touch.interact_button.disabled, "action reachable with walking locked: " + action)
		check(not touch.stick.visible, "dinner action does not expose walk stick: " + action)
	var presses := [0]
	touch.interact_pressed.connect(func(): presses[0] += 1)
	touch.set_interact_label("Shake pepper")
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
	check(presses[0] == 1, "label preserves exact one-press finger dispatch")
	touch.set_available(false,false,true)
	check(not touch.interact_button.visible and touch.interact_button.disabled, "closed input window cannot receive touches")
	touch.set_interact_label("")
	check(touch.interact_button.text == "Interact", "ordinary exploration clears last cooking verb")
	touch.set_available(true,true,true)
	check(touch.interact_button.visible and touch.interact_button.text == "Interact", "nearby exploration retains normal Interact")
	touch.apply_settings({"text_scale":1.5})
	touch.set_interact_label("Tear bread")
	check(touch.interact_button.text == "Tear", "large text keeps a short accessible verb")
	touch.set_interact_label("unsupported")
	check(touch.interact_button.text == "Interact", "unknown context safely falls back")
	touch.queue_free()
	game.free()
	await process_frame
	print("Kitchen contextual action checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
