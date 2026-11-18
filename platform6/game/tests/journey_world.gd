extends SceneTree
# Real geometry and physics contract for bounded authored Journey scenes.
var checks := 0
var failures := 0
const IDS = ["rain_town","unsent_letters_library","arcade","beach_before_sunrise","winter_orchard","rest_room","failed_things_festival","sunrise_cafe","no_destination_road","fireflies","shelter_parade","market_rescue"]
const TYPES = ["rain_routing","letter_arrangement","arcade_paddle","constellation_tracing","observation","tea_mixing","letter_arrangement","tea_mixing","observation","constellation_tracing","shelter_parade","market_rescue"]
const FEATURES = ["RainShop","LibraryShelves","ArcadeCabinets","Lighthouse","BareOrchard","RestCushions","RejectedObjectPlinths","DawnAwning","RoadLamps","NightBridge","ShelterPorch","MarketLanterns"]
func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func _initialize(): call_deferred("run")
func run():
	check(ResourceLoader.exists("res://world/journey_world.gd"),"authored Journey world exists")
	if failures:
		print("Journey world checks: %d; failures: %d" % [checks,failures])
		quit(1)
		return
	var script = load("res://world/journey_world.gd")
	var signatures: Dictionary = {}
	for i in range(IDS.size()+1):
		var is_train = i == IDS.size()
		var destination: Dictionary = {} if is_train else {"journey_id":IDS[i],"title":IDS[i].replace("_"," "),"palette":["344754","b39a75","e9d2a0"],"npc":{"name":"Ada","role":"keeper","returning":"I have been repairing the shelf."},"activity_type":TYPES[i],"activity_prompt":"Spend a little time with this."}
		var state = {"scene_kind":"train" if is_train else "destination","journey_id":"" if is_train else IDS[i],"visits":{},"history":[],"activities":{}}
		var world = script.new().build(state,{"settings":{"reduced_motion":false}},destination)
		root.add_child(world)
		await physics_frame
		check(world.has_node("Spawn") and world.has_node("AmbientMotion"),"spawn and ambient contract " + str(i))
		check(world.find_children("*","",true,false).size() < 1000,"bounded geometry count " + str(i))
		check(world.has_node("Ground") and world.get_node("Ground") is StaticBody3D,"solid floor " + str(i))
		var targets = world.get_node("Interactions").get_children()
		var expected = ["journey_board","journey_writing","journey_home"] if is_train else ["journey_activity","journey_story","journey_return_train","journey_home"]
		for target in targets:
			check(str(target.get_meta("action_id")) in expected,"authored target action " + str(target.name))
			check(absf(target.position.x) < 6.6 and absf(target.position.z) < 6.6,"target inside bounded floor " + str(target.name))
			var query = PhysicsShapeQueryParameters3D.new()
			var capsule = CapsuleShape3D.new()
			capsule.radius = 0.3
			capsule.height = 1.7
			query.shape = capsule
			query.transform = Transform3D(Basis.IDENTITY,target.global_position+Vector3(0,0.98,0))
			check(world.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"capsule-safe standing target " + str(target.name))
		check(targets.size() == expected.size(),"all comfortable exits and actions " + str(i))
		var body = CharacterBody3D.new()
		var shape = CollisionShape3D.new()
		var capsule = CapsuleShape3D.new()
		capsule.height = 1.7
		capsule.radius = 0.3
		shape.shape = capsule
		shape.position.y = 0.85
		body.add_child(shape)
		world.add_child(body)
		body.position = world.get_node("Spawn").position
		for step in range(12):
			body.velocity = Vector3(0,-2,0)
			body.move_and_slide()
			await physics_frame
		check(body.position.y > -0.05 and body.position.y < 0.13,"spawn floor physically supports walker " + str(i))
		# The common open central aisle reaches the back of every authored scene.
		for step in range(120):
			body.velocity = Vector3(0,-2,-3)
			body.move_and_slide()
			await physics_frame
		check(body.position.z < -0.5,"open central aisle reaches activity/NPC area " + str(i))
		world.apply_preferences(true)
		check(world.reduced_motion,"reduced motion preference " + str(i))
		var ambient = world.get_node("AmbientMotion")
		check(ambient.reduced,"existing ambient script receives preference " + str(i))
		world.set_paused(true)
		check(not ambient.is_processing(),"pause freezes ambient " + str(i))
		world.set_paused(false)
		check(ambient.is_processing(),"unpause restores ambient " + str(i))
		if not is_train:
			check(world.has_node("Scenery/"+FEATURES[i]),"unique silhouette " + IDS[i])
			var geometry = world.get_node("Activity")
			var before = physical_signature(geometry)
			world.update_activity({"step":2,"selection":2,"progress":2,"done":true})
			check(before != physical_signature(geometry),"real physical activity changes " + IDS[i])
			check(geometry.get_meta("done"),"physical activity records completion without scoring " + IDS[i])
			signatures[IDS[i]] = physical_signature(world.get_node("Scenery"))
		world.free()
		await physics_frame
	check(signatures.values().size() == IDS.size(),"twelve authored destination geometries")
	var unique: Dictionary = {}
	for signature in signatures.values(): unique[signature] = true
	check(unique.size() == IDS.size(),"every destination has a distinct physical silhouette")
	var remembered = script.new().build({"scene_kind":"train","visits":{"rain_town":2,"arcade":1},"history":["rain_town","arcade"]},{})
	root.add_child(remembered)
	await physics_frame
	check(remembered.get_node("Scenery/SouvenirShelf").get_child_count() > 2,"train shelf remembers visits physically")
	check(remembered.get_node("Scenery/DestinationBoard").get_meta("history").size() == 2,"board retains travel history")
	remembered.free()
	# Integration contracts use the actual model and authored pack, not fake fields.
	var pack = JSON.parse_string(FileAccess.get_file_as_string("res://data/journey_pack.json"))
	for destination in pack.destinations:
		var id = str(destination.journey_id)
		var state = {"mode":"destination","journey_id":id,"visits":{id:1},"board_history":[id],"activity":{},"location_states":{id:"as_found"}}
		var initial = script.new().build(state,{},destination)
		root.add_child(initial)
		await physics_frame
		check(initial.get_node("Scenery/RevisitMemory").get_child_count() > 0,"first return changes lived-in objects " + id)
		check(not initial.get_node("Scenery/NPCIndependentState").text.contains("Taking care of a few things."),"authored independent NPC return line " + id)
		initial.apply_preferences(true)
		var base = physical_signature(initial.get_node("Activity"))
		if initial.has_node("Scenery/LocalConsequences"): base += physical_signature(initial.get_node("Scenery/LocalConsequences"))
		initial.free()
		for local_state in destination.local_scene_states:
			if local_state == "as_found": continue
			state.location_states[id] = local_state
			var changed = script.new().build(state,{},destination)
			root.add_child(changed)
			await physics_frame
			changed.apply_preferences(true)
			var consequence = physical_signature(changed.get_node("Activity"))
			if changed.has_node("Scenery/LocalConsequences"): consequence += physical_signature(changed.get_node("Scenery/LocalConsequences"))
			check(base != consequence,"choice has a physical local consequence " + id+"/"+local_state)
			changed.free()
			await physics_frame
	# The new paper parade must be a genuine physical animation, pause/reduced-
	# motion safe, and must not require any actual shelter cat to participate.
	var shelter_data = pack.destinations[pack.destinations.size()-2]
	check(shelter_data.journey_id == "shelter_parade","shelter precedes the market in the authored Journey")
	var shelter = script.new().build({"mode":"destination","journey_id":"shelter_parade","activity":{}},{},shelter_data)
	root.add_child(shelter)
	await physics_frame
	var paper = shelter.get_node("Activity/PaperParade/PaperCats/PaperCat0")
	var resting = shelter.get_node("Scenery/CatCorner0/RestingCat")
	shelter.update_activity({"step":2,"selection":5,"progress":1,"done":true})
	var first_position = paper.position
	shelter._process(0.65)
	check(paper.position.distance_to(first_position)>0.02,"completed paper cats visibly march in the actual scene")
	# Two gate configurations must produce different physical courses at the
	# same playback instant; the controls are not merely decorative toggles.
	var open_course_x = paper.position.x
	shelter.update_activity({"step":2,"selection":4,"progress":1,"done":true})
	check(open_course_x-paper.position.x>0.05,"turning the first cardboard gate changes its paper cat path")
	shelter.update_activity({"step":2,"selection":5,"progress":1,"done":true})
	# The miniature journey is continuous at its loop boundary, not a
	# teleporting cat that jumps between opposite ends of the shelf.
	shelter.motion_elapsed = 5.399
	shelter._update_shelter_parade_pose()
	var before_wrap = paper.position
	shelter._process(0.002)
	check(paper.position.distance_to(before_wrap)<0.01,"paper figures complete a continuous easing loop")
	shelter.motion_elapsed = 1.35
	shelter._update_shelter_parade_pose()
	var player_route = paper.position
	shelter.update_activity({"step":1,"selection":5,"progress":1,"done":true})
	check(paper.position.distance_to(player_route)>0.02,"Jo's demonstration has its own measured paper-cat pace")
	shelter.update_activity({"step":2,"selection":5,"progress":1,"done":true})
	check(resting.position==Vector3(0,0.35,0),"physical shelter cat is never made to parade")
	shelter.set_paused(true)
	var frozen_position = paper.position
	shelter._process(1.2)
	check(paper.position==frozen_position,"pausing freezes paper parade motion")
	shelter.set_paused(false)
	shelter.apply_preferences(true)
	var quiet_position = paper.position
	shelter._process(2.0)
	check(paper.position==quiet_position,"reduced motion holds an equivalent completed still arrangement")
	shelter.update_activity({"step":2,"selection":4,"progress":1,"done":true})
	check(paper.position.x<quiet_position.x-0.19,"stationary reduced-motion preview still shows selected gate route")
	shelter.update_activity({"step":2,"selection":5,"progress":1,"done":true})
	shelter.update_activity({"step":1,"selection":5,"progress":1,"done":true})
	check(shelter.get_node("Activity/ParadeNote").text.contains("JO LETS"),"spectator route visibly acknowledges Jo")
	shelter.update_activity({"step":0,"selection":4,"progress":0,"done":false})
	check(paper.position==Vector3(-0.76,0.04,0.26) and not shelter.get_node("Activity/PaperParade/ParadeRibbon").visible,"reversing a gate resets the paper parade without penalty")
	shelter.free()
	await physics_frame
	var market_data = pack.destinations[pack.destinations.size()-1]
	check(market_data.journey_id == "market_rescue","twelfth stop is the paper supermarket")
	var market = script.new().build({"mode":"destination","journey_id":"market_rescue","activity":{}},{},market_data)
	root.add_child(market)
	await physics_frame
	var cart = market.get_node("Activity/MarketRoutes/PaperCart")
	market.update_activity({"step":2,"selection":7,"progress":3,"done":true})
	var starting_cart = cart.position
	market._process(0.65)
	check(cart.position.distance_to(starting_cart)>0.02,"imaginary paper cart moves through actual 3D scene")
	# The optional route markers must physically change the paper cart's
	# route, rather than only illuminating cardboard scenery.
	var lane_checkpoints = [0.18,0.50,0.83]
	for lane in range(3):
		var lane_progress = float(lane_checkpoints[lane])
		check(market._market_lane_offset(lane_progress,1<<lane)<-0.25,"marked aisle changes real paper-cart z route "+str(lane))
		check(is_zero_approx(market._market_lane_offset(lane_progress,0)),"unmarked aisle preserves central paper road "+str(lane))
	# Each reversible marker should move the paper cart rather than teleport it.
	market.update_activity({"step":0,"selection":0,"progress":0,"done":false})
	market._process(0.44)
	var empty_route_position = cart.position
	market.update_activity({"step":0,"selection":1,"progress":1,"done":false})
	check(cart.position.distance_to(empty_route_position)<0.001,"first marker leaves cart at current position")
	market.set_paused(true)
	market._process(0.21)
	check(cart.position==empty_route_position,"pause freezes in-progress marker glide")
	market.set_paused(false)
	market._process(0.21)
	check(cart.position.x>empty_route_position.x+0.12 and cart.position.x<empty_route_position.x+0.44,"cart glides visibly toward first paper aisle")
	market._process(0.21)
	check(absf(cart.position.x-(-0.83+1.66/3.0))<0.012,"first paper aisle reaches exact endpoint")
	var first_marker_position = cart.position
	market.update_activity({"step":0,"selection":3,"progress":2,"done":false})
	check(cart.position.distance_to(first_marker_position)<0.001,"second marker starts from current paper cart")
	market._process(0.42)
	check(cart.position.x>first_marker_position.x+0.50,"second marker reaches distinct paper aisle")
	market.apply_preferences(true)
	market.update_activity({"step":0,"selection":1,"progress":1,"done":false})
	check(absf(cart.position.x-(-0.83+1.66/3.0))<0.012,"reduced motion settles chosen route immediately")
	market.apply_preferences(false)
	check(absf(cart.position.x-(-0.83+1.66/3.0))<0.012,"re-enabling motion does not replay stale glide")
	market.update_activity({"step":0,"selection":3,"progress":2,"done":false})
	var before_last_marker = cart.position
	market.update_activity({"step":2,"selection":7,"progress":3,"done":true})
	check(cart.position.distance_to(before_last_marker)<0.012,"last grocery route marker starts animation without teleporting cart")
	market.update_activity({"step":0,"selection":1,"progress":1,"done":false})
	var before_watch = cart.position
	market.update_activity({"step":1,"selection":1,"progress":3,"done":true})
	check(cart.position.distance_to(before_watch)<0.012,"Jo's demonstration starts from the current partial paper route without a jump")
	# Check each real loop boundary at its own playback rate after any
	# change-of-mind glide has finished. Jo's pace is 0.74x, not 1x.
	market._process(0.43)
	market.motion_elapsed = 4.6/0.74-0.001
	market._update_market_rescue_pose()
	var before_jo_loop = cart.position
	market._process(0.002)
	check(cart.position.distance_to(before_jo_loop)<0.012,"Jo's slower cart loop does not teleport at its actual boundary")
	market.update_activity({"step":2,"selection":7,"progress":3,"done":true})
	market._process(0.43)
	market.motion_elapsed = 4.599
	market._update_market_rescue_pose()
	var before_loop = cart.position
	market._process(0.002)
	check(cart.position.distance_to(before_loop)<0.012,"player paper-cart loop is continuous at 1x")
	market.set_paused(true)
	var paused_cart = cart.position
	market._process(0.7)
	check(cart.position==paused_cart,"pause freezes paper market")
	market.set_paused(false)
	market.apply_preferences(true)
	var still_cart = cart.position
	market._process(0.8)
	check(cart.position==still_cart,"reduced motion holds legible still paper-market route")
	market.update_activity({"step":2,"selection":2,"progress":3,"done":true})
	var marked_still = cart.position
	market.update_activity({"step":2,"selection":5,"progress":3,"done":true})
	check(cart.position.z-marked_still.z>0.24,"reduced-motion route preview visibly reflects center marker choice")
	market.update_activity({"step":1,"selection":0,"progress":3,"done":true})
	check(market.get_node("Activity/MarketRoutes/Stop0/Lantern").visible,"watching Jo provides same visible route")
	market.update_activity({"step":0,"selection":1,"progress":1,"done":false})
	check(not market.get_node("Activity/MarketRoutes/HomeRibbon").visible,"paper cart arrangement is reversible")
	market.free()
	await physics_frame
	for state_id in ["shared_bag","clear_path"]:
		var returned_market = script.new().build({"mode":"destination","journey_id":"market_rescue","location_states":{"market_rescue":state_id}},{},market_data)
		check(returned_market.has_node("Scenery/LocalConsequences/"+("SharedShoppingBag" if state_id=="shared_bag" else "ReturnedBasket")),"real shopping choice persists as a prop: "+state_id)
		returned_market.free()
	var mode_train = script.new().build({"mode":"train","board_history":["rain_town"],"visits":{}},{})
	check(mode_train.get_node("Scenery/DestinationBoard").get_meta("history") == ["rain_town"],"actual model board_history reaches the physical board")
	mode_train.free()
	var routing = script.new().build({"mode":"destination","journey_id":"rain_town","activity":{"selection":5,"done":false}}, {},pack.destinations[0])
	check(is_equal_approx(routing.get_node("Activity/RainChannels/Route0/TurnableGate").rotation.y,PI/2) and is_equal_approx(routing.get_node("Activity/RainChannels/Route2/TurnableGate").rotation.y,PI/2) and not is_equal_approx(routing.get_node("Activity/RainChannels/Route1/TurnableGate").rotation.y,PI/2),"physical gutter directions match the three-bit selection")
	routing.free()
	var day = pack.destinations[0].duplicate(true)
	day.time_state = "day"
	day.weather_state = "rain"
	var night = day.duplicate(true)
	night.time_state = "night"
	night.weather_state = "mist"
	var day_world = script.new().build({"mode":"destination","journey_id":"rain_town"},{},day)
	var night_world = script.new().build({"mode":"destination","journey_id":"rain_town"},{},night)
	check(day_world.get_node("SoftJourneyLight").light_energy > night_world.get_node("SoftJourneyLight").light_energy,"bounded time recombination changes actual light energy")
	check(day_world.get_node("JourneyEnvironment").environment.background_color != night_world.get_node("JourneyEnvironment").environment.background_color,"bounded time recombination changes actual sky color")
	check(day_world.get_node("Scenery/Rain").visible and not night_world.get_node("Scenery/Rain").visible,"authored weather state changes actual rain visibility")
	check(not day_world.get_node("FrontMovementBoundary").get_child(0).visible,"front movement bounds do not occlude the spawn camera")
	day_world.free()
	night_world.free()
	print("Journey world checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
func physical_signature(node: Node) -> String:
	var entries: Array[String] = []
	for child in node.find_children("*","Node3D",true,false):
		var stable_name = str(child.name) if not str(child.name).begins_with("@") else child.get_class()
		entries.append(stable_name+str(child.position)+str(child.rotation)+str(child.scale)+str(child.visible))
		if child is MeshInstance3D and child.material_override != null:
			entries.append(str(child.material_override.albedo_color))
	return "|".join(entries)
