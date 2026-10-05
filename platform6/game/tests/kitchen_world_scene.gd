extends SceneTree
# Real scene geometry and its live motion. Missing world is the first expected red.
var checks := 0
var failures := 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _initialize(): call_deferred("run")
func state(checkpoint: String = "arrival", mode: String = "unselected", exchange: String = "unselected", camera: String = "unused") -> Dictionary:
	return {"campaign_chapter":"night_kitchen","kitchen_checkpoint":checkpoint,"camera_choice":camera,"settings":{"reduced_motion":false,"graphics":"low"},"paper":{"star":"empty","layout":"boat_star_leaf","length":"long","fold":"wider","mode":"watch","completed":true},"kitchen":{"mode":mode,"served":checkpoint in ["supper","conversation","complete"],"exchange":exchange,"departure":"listen" if checkpoint == "complete" else "unselected","completed":checkpoint == "complete"}}
func action(world: Node, id: String) -> Node:
	for target in world.get_node("Interactions").get_children():
		if target.get_meta("action_id","") == id: return target
	return null
func run():
	check(ResourceLoader.exists("res://world/kitchen_world.gd"),"Night Kitchen owns an original playable dinner world")
	if failures:
		print("Kitchen world checks: %d; failures: %d" % [checks,failures])
		quit(1)
		return
	var world = load("res://world/kitchen_world.gd").new().build(state())
	root.add_child(world)
	await process_frame
	world.set_process(false)
	for id in ["Spawn","AmbientMotion","Interactions","KitchenFloor","DinnerTable","PlayerPlace","PlayerChair","SoupPot","Steam","Ladle","BreadBoard","PepperShaker","PassingBread","Condensation","Noor","Ada","Mira","PaperSign","CameraCallback","TableView","SignView","DepartureDoor"]:
		check(world.has_node(id),"kitchen contains physical " + id)
	check(world.get_node("DinnerTable") is StaticBody3D,"table collision protects its setting")
	check(world.get_node("PlayerPlace").get_meta("already_set",false),"player's bowl, cup and spoon are already set on arrival")
	for id in ["Bowl","Cup","Spoon","Napkin"]: check(world.get_node("PlayerPlace").has_node(id),"arrival contains player's " + id)
	check(action(world,"kitchen_join") != null,"arrival allows immediate sit/help/watch")
	check(world.get_node("Mira").get_meta("character_id","") == "mira","existing Mira stays recognizable")
	check(world.get_node("Mira").get_meta("destination","") == "lower_mill","Mira retains her independent workshop plan")
	check(world.has_node("PlayerPlace/FairButton"),"actual fair button sits beside the player napkin")
	if world.has_node("PlayerPlace/FairButton"):
		check(world.get_node("PlayerPlace/FairButton").get_meta("souvenir_id","") == "fair_button","physical fair callback retains its souvenir identity")
	check(world.get_node("PaperSign").get_meta("configuration",{}).layout == "boat_star_leaf","exact saved paper order carries into kitchen")
	check(world.get_node("PaperSign/Slots/Center").get_child_count() == 2,"saved empty paper slot stays empty")
	check(world.get_node("PaperSign/Nameplate/Inscription").text == "BOATS WITH OPINIONS","real callback preserves inscription")
	check(world.get_node("PaperSign/Nameplate").has_node("BentPropeller"),"shore propeller remains on the actual callback")
	for camera in ["take","lend","unused"]:
		world.apply_snapshot(state("arrival","unselected","unselected",camera))
		check(world.get_node("CameraCallback").get_meta("camera_choice","") == camera,"physical camera callback restores " + camera)
		check(world.get_node("CameraCallback").has_node("UnopenedBox") == (camera == "unused"),"unused camera remains in unopened box")
	for checkpoint in ["supper","conversation","complete"]:
		world.apply_snapshot(state(checkpoint,"watch","bread"))
		for id in ["kitchen_table","kitchen_bread","kitchen_cup","kitchen_pepper","kitchen_mira","kitchen_sign","kitchen_camera","kitchen_exit"]:
			check(action(world,id) != null,"saved " + checkpoint + " makes " + id + " reachable")
		var markers = world.get_node("Interactions").get_children()
		for i in range(markers.size()):
			for j in range(i+1,markers.size()): check(markers[i].position.distance_to(markers[j].position) > 0.65,"each interaction has a distinct nearest-target standing spot")
		for label in world.get_node("Interactions").find_children("*","Label3D",true,false): check(not label.visible,"HUD remains the only nearest-target prompt")
	world.apply_snapshot(state("supper","help"))
	var moving = ["Steam/Puff0","Ladle","PassingBread","Noor/ArmRight","Ada/ArmLeft","Condensation/Drop0","PlayerPlace/Bowl"]
	var before: Dictionary = {}
	for id in moving: before[id] = world.get_node(id).transform
	world._process(1.2)
	for id in moving: check(not world.get_node(id).transform.is_equal_approx(before[id]),"live layered motion updates " + id)
	var paused_time = world.decorative_elapsed
	world.set_paused(true)
	var paused_pose = world.get_node("Ladle").transform
	world._process(2.0)
	check(world.decorative_elapsed == paused_time and world.get_node("Ladle").transform.is_equal_approx(paused_pose),"pause freezes kitchen presentation and time")
	world.set_paused(false)
	var completions: Array[String] = []
	world.gesture_finished.connect(func(id): completions.append(id))
	for id in ["join_sit","join_help","join_watch","bread","cup","pepper","watch"]:
		var callback_count = [0]
		world.begin_gesture(id,func(): callback_count[0] += 1)
		check(world.gesture_active,"ordinary " + id + " gets bounded real staging")
		world._process(0.5)
		check(not world.gesture_subtitle().is_empty(),"gesture supplies useful live subtitle " + id)
		check(not world.get_node("GestureCaption").visible,"world caption defers to the accessible HUD during " + id)
		world.set_paused(true)
		world._process(20.0)
		check(callback_count[0] == 0,"paused " + id + " cannot finish behind a menu")
		world.set_paused(false)
		world._process(8.0)
		check(callback_count[0] == 1 and not world.gesture_active,"bounded " + id + " completes exactly once")
		check(completions.back() == id,"completion signal identifies " + id)
	check(world.has_method("finish_gesture"),"world exposes immediate gesture exit")
	if world.has_method("finish_gesture"):
		var exit_count = [0]
		world.begin_gesture("cup",func(): exit_count[0] += 1)
		world._process(0.2)
		world.finish_gesture()
		check(exit_count[0] == 1 and not world.gesture_active,"immediate exit settles gesture once")
		world.finish_gesture()
		world._process(20.0)
		check(exit_count[0] == 1,"duplicate immediate exit never calls completion twice")
	world.apply_preferences(true)
	for id in moving: before[id] = world.get_node(id).transform
	world._process(2.0)
	for id in moving: check(world.get_node(id).transform.is_equal_approx(before[id]),"reduced motion freezes decorative " + id)
	for id in ["join_sit","join_help","join_watch","bread","cup","pepper","watch"]:
		var callback_count = [0]
		world.begin_gesture(id,func(): callback_count[0] += 1)
		check(callback_count[0] == 1 and not world.gesture_active,"reduced motion instantly preserves functionality for " + id)
	world.apply_preferences(false)
	world.begin_gesture("bread",Callable())
	world._process(0.6)
	check(world.has_node("BreadBoard/TearingHands"),"bread uses actual two-hand tearing geometry")
	if world.has_node("BreadBoard/TearingHands"):
		check(world.get_node("BreadBoard/TearingHands").visible,"bread gesture activates its physical hands")
	var bread = world.get_node("BreadBoard/TornHalf")
	check(bread.position.x > 0.1,"bread interaction tears real authored loaf geometry")
	world.apply_preferences(true)
	check(not world.gesture_active,"live reduced-motion toggle completes current gesture")
	for mode in ["sit","help","watch"]:
		for exchange in ["bread","cup","pepper","watch"]:
			var consistent = state("complete",mode,exchange,"lend")
			consistent.settings.reduced_motion = true
			world.apply_snapshot(consistent)
			world.begin_gesture(exchange,Callable())
			var resumed = load("res://world/kitchen_world.gd").new().build(consistent)
			for id in ["PlayerChair","PlayerPlace/Bowl","PlayerPlace/Cup","BreadBoard/TornHalf","PepperShaker"]:
				check(world.get_node(id).transform.is_equal_approx(resumed.get_node(id).transform),"finished and restored tangible staging agree for " + mode + "/" + exchange + "/" + id)
			resumed.free()
	var saved = state("complete","watch","pepper","lend")
	world.apply_snapshot(saved)
	var rebuilt = load("res://world/kitchen_world.gd").new().build(saved)
	root.add_child(rebuilt)
	await process_frame
	check(rebuilt.get_node("PlayerPlace/Bowl/Soup").visible,"restored watch route has a served place")
	check(rebuilt.get_node("PaperSign").get_meta("configuration") == world.get_node("PaperSign").get_meta("configuration"),"reopening restores actual carried sign exactly")
	check(rebuilt.get_node("PlayerChair").position == world.get_node("PlayerChair").position,"restored completed dinner keeps safe chair staging")
	check(world.table_view_transform().origin.is_equal_approx(world.get_node("TableView").position),"table camera API uses visible authored marker")
	world.free()
	rebuilt.free()
	print("Kitchen world checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
