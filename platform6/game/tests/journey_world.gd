extends SceneTree
# Real geometry and physics contract for bounded authored Journey scenes.
var checks := 0
var failures := 0
const IDS = ["rain_town","unsent_letters_library","arcade","beach_before_sunrise","winter_orchard","rest_room","failed_things_festival","sunrise_cafe","no_destination_road","fireflies"]
const TYPES = ["rain_routing","letter_arrangement","arcade_paddle","constellation_tracing","observation","tea_mixing","letter_arrangement","tea_mixing","observation","constellation_tracing"]
const FEATURES = ["RainShop","LibraryShelves","ArcadeCabinets","Lighthouse","BareOrchard","RestCushions","RejectedObjectPlinths","DawnAwning","RoadLamps","NightBridge"]
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
	check(signatures.values().size() == IDS.size(),"ten authored destination geometries")
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
