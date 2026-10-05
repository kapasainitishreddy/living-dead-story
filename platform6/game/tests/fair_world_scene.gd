extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _initialize(): call_deferred("run")
func state(checkpoint: String = "workshop") -> Dictionary:
	return {"campaign_chapter":"the_small_fair", "fair_checkpoint":checkpoint, "settings":{"reduced_motion":false}, "fair":{"rudder":"straight","sail":"triangle","mode":"operate","levelled":false,"race_count":0,"outcome":"unselected","inspected":[]}}
func find_action(world: Node, action: String, value: Variant = null) -> Node:
	for target in world.find_children("*", "Marker3D", true, false):
		if target.get_meta("action_id","") == action and (value == null or target.get_meta("value",null) == value): return target
	return null
func run():
	check(ResourceLoader.exists("res://world/fair_world.gd"),"Chapter Two owns a playable fair world")
	check(ResourceLoader.exists("res://world/fair_race.gd"),"Chapter Two owns a visible authored boat race")
	if failures:
		print("Fair world checks: %d; failures: %d" % [checks,failures])
		quit(1)
		return
	var world = load("res://world/fair_world.gd").new().build(state("arrival"))
	root.add_child(world)
	await process_frame
	check(world.has_node("Spawn"),"fair exposes safe player spawn")
	check(world.has_node("AmbientMotion"),"fair owns reduced-motion environmental presentation")
	for item in ["CourtyardFloor","AccessibleDeck","DeckRamp","PondAssembly","PondAssembly/PackingWedge","PondAssembly/WoodenDuck","Booth","Booth/Kettle","Booth/WoodenBird","KitchenDoor","ConservatoryDoor","Train","Mira","Ada","FairRace"]:
		check(world.has_node(item),"fair has tangible " + item)
	check(world.get_node("Mira").get_meta("character_id","") == "mira","fair preserves original production Mira rig")
	check(world.get_node("AccessibleDeck") is StaticBody3D,"deck carries real collision")
	check(world.get_node("DeckRamp") is StaticBody3D,"broad accessible ramp carries real collision")
	world._process(1.0)
	world.get_node("AmbientMotion").apply_preferences(true)
	world._process(1.0)
	check(is_equal_approx(world.get_node("PondAssembly/WoodenDuck").position.y,0.09),"live reduced-motion toggle also stills decorative duck")
	world.get_node("AmbientMotion").apply_preferences(false)
	world._process(1.0)
	check(not is_equal_approx(world.get_node("PondAssembly/WoodenDuck").position.y,0.09),"decorative duck restores after live preference toggle")
	check(find_action(world,"fair_greeting") != null,"arrival offers Ada greeting")
	for item in ["fair_hours","fair_prizes","fair_bird"]:
		check(find_action(world,item) != null,"optional fair object remains explorable through fair dialogue: " + item)
	for caption in world.get_node("Interactions").find_children("*","Label3D",true,false):
		check(not caption.visible,"nearest-target HUD avoids overlapping courtyard billboard captions")
	world.apply_snapshot(state())
	check(find_action(world,"fair_setup") != null,"workshop offers configurable boat setup")
	check(find_action(world,"release_boat") != null,"workshop offers one press release")
	check(find_action(world,"fair_greeting") == null,"old required greeting cannot retrigger after join")
	var race = world.get_node("FairRace")
	check(race.get_node("Boats").get_child_count() == 3,"race contains three physical boats")
	for boat in race.get_node("Boats").get_children():
		check(boat.has_node("PaperSail") and boat.has_node("Rudder"),"each boat displays sail and rudder")
	var first = state("crooked_race")
	first.fair.race_count = 1
	first.fair.outcome = "crooked"
	world.apply_snapshot(first)
	check(find_action(world,"inspect_fair","wedge") != null,"crooked pond can be inspected from dry edge")
	for i in range(3):
		var end = race.sample_position(i,1.0,first.fair)
		check(end.x < -1.25 and end.z < -1.2,"first boat %d arcs to the duck irrespective of rudder" % i)
	var crooked_end = race.sample_position(0,1.0,first.fair)
	first.fair.rudder = "right"
	check(race.sample_position(0,1.0,first.fair).is_equal_approx(crooked_end),"crooked race ignores configured rudder")
	var level = state("race_ready")
	level.fair.levelled = true
	level.fair.race_count = 1
	world.apply_snapshot(level)
	check(is_zero_approx(world.get_node("PondAssembly").rotation.z),"levelled pond geometry becomes visibly level")
	check(not world.get_node("PondAssembly/PackingWedge").visible,"shifted packing wedge no longer props up pond")
	check(find_action(world,"release_boat") != null,"levelled race is available to play or watch")
	var before_sail = race.get_node("Boats/PlayerBoat/PaperSail").mesh
	level.fair.sail = "square"
	level.fair.rudder = "right"
	world.apply_snapshot(level)
	check(race.get_node("Boats/PlayerBoat/PaperSail").mesh != before_sail,"paper sail selection changes actual silhouette")
	check(race.get_node("Boats/PlayerBoat/Rudder").rotation.y > 0.1,"rudder selection changes visible rudder angle")
	check(race.get_node("ConfigurationLabel").text.contains("Right") and race.get_node("ConfigurationLabel").text.contains("Square"),"configuration is readable without relying on color")
	var result = state("result")
	result.fair.levelled = true
	result.fair.race_count = 2
	result.fair.outcome = "first"
	world.apply_snapshot(result)
	check(race.sample_position(0,1.0,result.fair).z < -1.65,"straight triangular boat visibly crosses finish")
	for outcome in ["first","second","third","spectator"]:
		var finish_state = result.fair.duplicate(true)
		finish_state.outcome = outcome
		for i in range(3): check(race.sample_position(i,1.0,finish_state).z < -1.8,"%s race boat %d crosses before the event ends" % [outcome,i+1])
		var player_crossing := 1.0
		var opponent_crossings: Array[float] = []
		for i in range(3):
			var crossing := 1.0
			for step in range(101):
				if race.sample_position(i,float(step)/100.0,finish_state).z <= -1.8:
					crossing = float(step)/100.0
					break
			if i == 0: player_crossing = crossing
			else: opponent_crossings.append(crossing)
		if outcome == "first": check(player_crossing < opponent_crossings.min(),"first-place text matches visible crossing order")
		if outcome == "second": check(player_crossing > opponent_crossings.min() and player_crossing < opponent_crossings.max(),"second-place text matches visible crossing order")
		if outcome == "third": check(player_crossing > opponent_crossings.max(),"third-place text matches visible crossing order")
	for pair in [["watch","spectator"],["cooperate","second"]]:
		var shared_state = result.fair.duplicate(true)
		shared_state.mode = pair[0]
		shared_state.sail = "folded"
		shared_state.outcome = pair[1]
		check(race.sample_position(0,1.0,shared_state).z < -1.8,"%s canonical result overrides a folded-sail circular route" % pair[0])
	check(find_action(world,"replay_race") != null and find_action(world,"fair_departure") != null,"result offers replay and story continuation")
	var counted := 0
	race.completed.connect(func(): counted += 1)
	race.play_race(result)
	check(race.running,"normal preferences animate functional boat race")
	var initial = race.get_node("Boats/PlayerBoat").position
	var key = race.get_node("Boats/PlayerBoat/WindupKey")
	race.advance_race(0.1)
	check(race.get_node("Boats/PlayerBoat").position.is_equal_approx(initial),"release begins with one bounded visual wind-up")
	check(not is_zero_approx(key.rotation.y),"wind-up visibly turns the original boat key")
	race.advance_race(0.9)
	check(not race.get_node("Boats/PlayerBoat").position.is_equal_approx(initial),"functional animation changes visible boat position")
	race.advance_race(5.0)
	check(not race.running,"functional race reaches a bounded finish")
	check(is_zero_approx(key.rotation.y),"finished winding key has no ongoing decorative animation")
	race.play_race(result,true)
	check(is_zero_approx(key.rotation.y),"replay begins with reset winding key")
	race.advance_race(0.1)
	race.set_paused(true)
	initial = race.get_node("Boats/PlayerBoat").position
	var paused_key_rotation = key.rotation.y
	race.advance_race(2.0)
	check(race.get_node("Boats/PlayerBoat").position.is_equal_approx(initial),"pause holds functional race without changing boat position")
	check(is_equal_approx(key.rotation.y,paused_key_rotation),"pause holds winding key as well as functional race")
	check(race.has_method("apply_preferences"),"live race receives preference changes without restarting")
	if race.has_method("apply_preferences"):
		race.apply_preferences(true)
		check(race.running,"reduced-motion toggle does not close pause or skip its resume")
		race.set_paused(false)
		race.advance_race(0.01)
		check(not race.running,"resumed reduced-motion race resolves without remaining animation")
	else:
		race.set_paused(false)
		race.advance_race(5.0)
	var reduced = result.duplicate(true)
	reduced.settings.reduced_motion = true
	world.apply_snapshot(reduced)
	race.play_race(reduced,true)
	check(not race.running,"reduced-motion race resolves without decorative motion or forced wait")
	check(is_zero_approx(key.rotation.y),"reduced-motion winding key stays still")
	check(race.get_node("RouteTraces").visible,"reduced-motion retains readable authored boat paths")
	check(race.get_node("ResultLabel").text.contains("First"),"reduced-motion provides textual functional result")
	world.free()
	print("Fair world checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
