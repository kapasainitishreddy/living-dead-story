extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _initialize(): call_deferred("run")
func state(checkpoint: String = "workshop", star: String = "crooked", layout: String = "leaf_boat_star", length_: String = "medium", fold: String = "keep") -> Dictionary:
	return {"campaign_chapter":"paper_sky","paper_checkpoint":checkpoint,"settings":{"reduced_motion":false,"graphics":"low"},"paper":{"star":star,"layout":layout,"length":length_,"fold":fold,"mode":"assemble","completed":checkpoint == "complete"}}
func find_action(world: Node, action: String) -> Node:
	for target in world.find_children("*","Marker3D",true,false):
		if target.get_meta("action_id","") == action: return target
	return null
func run():
	check(ResourceLoader.exists("res://world/paper_world.gd"),"Chapter Three owns a playable paper conservatory")
	check(ResourceLoader.exists("res://world/paper_sign.gd"),"Chapter Three owns a persistent physical paper sign")
	if failures:
		print("Paper world checks: %d; failures: %d" % [checks,failures])
		quit(1)
		return
	var world = load("res://world/paper_world.gd").new().build(state("arrival"))
	root.add_child(world)
	await process_frame
	for node_name in ["Spawn","AmbientMotion","Interactions","ConservatoryFloor","GlassRoof","Worktable","HangingRails","TestDoorway","PaperSign","ShadowScreen","UmbrellaStand","Noor","Rafi","Mira","SignView","ShadowView"]:
		check(world.has_node(node_name),"conservatory contains tangible " + node_name)
	check(world.get_node("Worktable") is StaticBody3D,"worktable collision protects the work without destructive physics")
	check(world.get_node("HangingRails").get_child_count() >= 3,"three visible hanging rails frame the work")
	for id in ["Noor","Rafi","Mira"]:
		check(world.get_node(id).get_meta("character_id","") == id.to_lower(),"distinct original character " + id)
	check(find_action(world,"paper_greeting") != null,"arrival has the sibling greeting")
	world.apply_snapshot(state())
	for action in ["paper_worktable","paper_star","paper_layout","paper_length","paper_fold","paper_raise","paper_inspect"]:
		check(find_action(world,action) != null,"workshop offers meaningful nearby " + action)
	check(find_action(world,"paper_greeting") == null,"joining clears arrival action")
	var nearby_markers = world.get_node("Interactions").find_children("*","Marker3D",true,false)
	for i in range(nearby_markers.size()):
		for j in range(i+1,nearby_markers.size()):
			check(nearby_markers[i].position.distance_to(nearby_markers[j].position) > 0.5,"each nearby control has a physically distinct, reachable inspection spot")
	for post in world.get_node("HangingRails").get_children():
		if str(post.name).begins_with("RailUpright"):
			check(post.get_child(0).mesh.size.z < 0.15,"worktable uprights remain slim frames, never opaque side panels")
	var sign = world.get_node("PaperSign")
	check(sign.get_node("Nameplate/Inscription").text == "BOATS WITH OPINIONS","physical inscription survives every configuration")
	check(sign.has_node("Nameplate/BentPropeller"),"bent shore propeller is physically fixed to nameplate")
	check(sign.has_method("build"),"physical sign exposes a reusable build API")
	check(sign.has_method("geometry_bounds"),"doorway fit is checked against actual authored geometry")
	var reference_star = sign.get_node("Slots/Right/PaperStar").get_child(0).mesh
	for star in ["crooked","clean","empty"]:
		for layout in ["leaf_boat_star","boat_star_leaf","star_leaf_boat","leaf_star_boat","boat_leaf_star","star_boat_leaf"]:
			for length_ in ["short","medium","long"]:
				for fold in ["keep","wider","enough"]:
					world.apply_snapshot(state("raised",star,layout,length_,fold))
					check(sign.get_meta("configuration").star == star,"physical state retains selected star")
					check(sign.get_meta("configuration").layout == layout,"physical state retains selected layout")
					var order = layout.split("_")
					for i in range(3):
						var slot = sign.get_node("Slots").get_child(i)
						check(slot.get_meta("piece") == order[i],"slot position follows persisted order")
						check(slot.has_node("String"),"hanging slot retains actual string geometry")
						if order[i] == "star": check(slot.has_node("PaperStar") == (star != "empty"),"empty slot is actual negative space")
						if order[i] == "boat": check(slot.has_node("TimetableBoat"),"base timetable boat remains in sign when spare fold stays on rack")
					check(world.get_node("UmbrellaStand/YellowUmbrella/UmbrellaGiftStar").visible,"sister receives umbrella star on every route")
					check(sign.fits_doorway(3.8,3.6),"each permitted configuration fits measured doorway")
					check(find_action(world,"paper_exit") != null,"raised configuration can leave for supper")
	world.apply_snapshot(state("workshop","clean"))
	check(sign.get_node("Slots/Right/PaperStar").get_child(0).mesh != reference_star,"clean star changes actual cut-paper outline")
	world.apply_snapshot(state("workshop","crooked","leaf_boat_star","short"))
	var short_y = sign.get_node("Slots/Left/PaperLeaf").position.y
	world.apply_snapshot(state("workshop","crooked","leaf_boat_star","long"))
	check(sign.get_node("Slots/Left/PaperLeaf").position.y < short_y,"length preset moves real hanging geometry")
	world.apply_snapshot(state("workshop","crooked","leaf_boat_star","medium","keep"))
	var first_width = sign.get_node("Slots/Center/TimetableBoat").get_meta("width")
	world.apply_snapshot(state("workshop","crooked","leaf_boat_star","medium","wider"))
	check(sign.get_node("Slots/Center/TimetableBoat").get_meta("width") > first_width,"wider fold changes actual boat width")
	world.apply_snapshot(state("workshop","empty","star_leaf_boat","long","enough"))
	check(world.get_node("SpareTimetableBoat").visible,"enough route keeps spare folded boat on drying rack")
	var saved = state("complete","clean","boat_star_leaf","short","wider")
	world.apply_snapshot(saved)
	var expected = sign.get_meta("configuration").duplicate(true)
	var rebuilt = load("res://world/paper_world.gd").new().build(saved)
	root.add_child(rebuilt)
	await process_frame
	check(rebuilt.get_node("PaperSign").get_meta("configuration") == expected,"freshly built world exactly restores tangible sign")
	check(rebuilt.get_node("PaperSign").position.is_equal_approx(sign.position),"raised completed placement survives reopening")
	world._process(1.0)
	world.get_node("AmbientMotion").apply_preferences(true)
	world._process(1.0)
	check(is_zero_approx(sign.get_node("Slots").rotation.z),"live reduced-motion toggle freezes paper and strings")
	check(is_zero_approx(world.get_node("ShadowScreen/SignSilhouette").rotation.z),"plain low-graphics silhouette stays stable")
	world.get_node("AmbientMotion").apply_preferences(false)
	world._process(1.0)
	check(not is_zero_approx(sign.get_node("Slots").rotation.z),"paper secondary motion restores without changing configuration")
	for caption in world.get_node("Interactions").find_children("*","Label3D",true,false): check(not caption.visible,"nearest HUD avoids overlapping object captions")
	world.free()
	rebuilt.free()
	print("Paper world checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
