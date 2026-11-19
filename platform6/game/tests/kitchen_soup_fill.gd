extends SceneTree
# Real Godot room test: visible soup serving must move from empty to full
# without erasing an earlier, durable seated dinner choice.
var checks := 0
var failures := 0

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _initialize(): call_deferred("run")

func state(mode: String) -> Dictionary:
	return {
		"campaign_chapter":"night_kitchen",
		"kitchen_checkpoint":"supper",
		"camera_choice":"unused",
		"settings":{"reduced_motion":false,"graphics":"low"},
		"paper":{"star":"empty","layout":"boat_star_leaf","length":"long","fold":"wider","mode":"watch","completed":true},
		"kitchen":{"mode":mode,"served":true,"exchange":"unselected","departure":"unselected","completed":false}
	}

func run():
	for route in ["join_sit","join_help","join_watch"]:
		var mode: String = route.trim_prefix("join_")
		var saved: Dictionary = state(mode)
		var world = load("res://world/kitchen_world.gd").new().build(saved)
		root.add_child(world)
		await process_frame
		world.set_process(false)
		world.begin_gesture(route,Callable())
		var soup: Node3D = world.get_node("PlayerPlace/Bowl/Soup")
		check(not soup.visible,route + " begins with the real empty bowl")
		var duration: float = world.gesture_duration
		world._process(duration * 0.86)
		check(soup.visible and soup.scale.x > 0.05 and soup.scale.x < 0.95,route + " shows a partially filling bowl, not a pop")
		check(is_equal_approx(soup.scale.x,soup.scale.z) and soup.position.y > 0.09 and soup.position.y < 0.13,route + " soup spreads and rises inside its bowl")
		world.set_paused(true)
		var frozen: Transform3D = soup.transform
		world._process(duration)
		check(soup.transform.is_equal_approx(frozen),route + " freezes the pour mid-gesture when paused")
		world.set_paused(false)
		world._process(duration)
		check(not world.gesture_active and soup.visible and soup.scale.is_equal_approx(Vector3.ONE),route + " settles to one full saved bowl")
		check(is_equal_approx(soup.position.y,0.13),route + " restores the original authored surface height")
		# The next bread exchange must start from the already-served place.
		world.begin_gesture("bread",Callable())
		check(soup.visible and soup.scale.is_equal_approx(Vector3.ONE),route + " keeps soup full during the next exchange")
		world._process(0.8)
		check(soup.visible and soup.scale.is_equal_approx(Vector3.ONE),route + " keeps the dinner visible while bread is passed")
		if mode == "sit":
			check(is_equal_approx(world.get_node("PlayerChair").position.z,1.25),"sit choice keeps the pulled-in chair during bread exchange")
		world.apply_preferences(true)
		check(not world.gesture_active and soup.visible and soup.scale.is_equal_approx(Vector3.ONE),route + " reduced motion settles bread and keeps the meal")
		world.begin_gesture("join_help",Callable())
		check(not world.gesture_active and soup.visible and soup.scale.is_equal_approx(Vector3.ONE),route + " reduced motion serves immediately without a partial bowl")
		world.apply_preferences(false)
		world.queue_free()
		await process_frame
	print("Kitchen soup-fill native checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
