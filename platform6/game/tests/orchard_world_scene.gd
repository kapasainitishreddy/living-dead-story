extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, note: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + note)
func _initialize(): call_deferred("run")
func state(route := "unselected", beat := 0, complete := false):
	return {"campaign_chapter":"quiet_orchard","orchard_checkpoint":"complete" if complete else ("arrival" if route == "unselected" else "rest"),"orchard":{"route":route,"beat":beat,"completed":complete},"settings":{"reduced_motion":false}}
func run():
	check(ResourceLoader.exists("res://world/orchard_world.gd"),"original orchard world exists")
	if failures: quit(1); return
	for route in ["unselected","cart","walk","bench"]:
		var world = load("res://world/orchard_world.gd").new().build(state(route))
		root.add_child(world)
		await process_frame
		world.set_process(false)
		for id in ["Spawn","AmbientMotion","Interactions","OrchardFloor","Cart","StationBench","Pear","Workers","TrainReflection","OrchardRows","StationDoor","PearBranch","PackingShed","PackingDoor"]: check(world.has_node(id),"physical " + id)
		check(world.has_node("Workers/DistantWorker/EmptyCrate") and world.get_node("Workers/DistantWorker/EmptyCrate").get_child_count() >= 5,"worker physically carries an open empty crate")
		check(world.get_node("Workers").position.z < -15,"workers belong to distant packing doorway")
		check(world.get_node("StationBuilding/Wall").position.z > 0,"station wall stays behind resting bench")
		check(world.get_node("Cart/Deck") is StaticBody3D,"cart is physically supported")
		for beat in range(4):
			world.apply_state(state(route,beat))
			check(world.get_node("Pear").position.y < 0.4 if beat >= 1 else world.get_node("Pear").position.y > 2,"pear restores canonical saved beat")
			check(not world.get_node("TrainReflection").visible,"finished train passes back into dark")
		var count = [0]
		world.begin_beat(1,func(): count[0] += 1)
		world.set_paused(true)
		world._process(20)
		check(count[0] == 0,"pause freezes bounded beat")
		world.set_paused(false)
		world.apply_preferences(true)
		check(count[0] == 1,"reduced motion completes functional presentation immediately")
		world._process(20)
		check(count[0] == 1,"completion occurs once")
		check(world.snapshot.orchard.beat == 3,"presentation never advances saved progression")
		world.apply_preferences(false)
		var arrivals = [0]
		world.begin_route(func(): arrivals[0] += 1)
		if route == "cart":
			check(world.get_node("Cart/SeatedRider").visible,"rider occupies physical cart seat")
			var before = world.get_node("Cart").position
			world._process(1.0)
			check(world.get_node("Cart").position.z < before.z,"cart route physically rides down orchard")
			check(world.get_node("RestView").position.z < 6.3,"cart camera follows physical seated ride")
			world.set_paused(true)
			var frozen = world.get_node("Cart").transform
			world._process(20)
			check(world.get_node("Cart").transform == frozen and arrivals[0] == 0,"pause freezes ride and callback")
			world.set_paused(false)
			world.apply_preferences(true)
			check(arrivals[0] == 1 and is_equal_approx(world.get_node("Cart").position.z,-3.9),"reduced motion parks cart instantly")
		world.begin_route()
		world.begin_beat(1)
		check(not world.route_active,"manual beat settles route to avoid overlapping cart motion")
		world.finish_beat()
		world.set_rest_view(true)
		check(world.get_node("StationBench/SeatedRider").visible == (route == "bench"),"bench view physically seats rider")
		world.set_rest_view(false)
		check(not world.get_node("Cart/SeatedRider").visible and not world.get_node("StationBench/SeatedRider").visible,"explorer has no duplicate seated body")
		world.free()
	print("Orchard world checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
