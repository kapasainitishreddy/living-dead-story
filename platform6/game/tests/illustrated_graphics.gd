extends SceneTree
var checks := 0
var failures := 0
var game
var fixtures = preload("res://tests/illustrated_fixtures.gd").new()
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok: failures += 1; printerr("FAIL: "+label)
func signature(world: Node) -> Array:
	var data: Array = []
	for node in world.find_children("*","Marker3D",true,false):
		if node.has_meta("action_id"): data.append([node.get_meta("action_id"),node.position,node.get_meta("value") if node.has_meta("value") else null])
	return data
func verify(id: String):
	await process_frame
	var before = game.model.snapshot()
	var journey_before = game.journey.model.snapshot()
	var world = game.world_container.get_child(0)
	var art = world.get_node_or_null("IllustratedWorld")
	check(art != null,id+" illustrated presentation exists")
	if art == null: return
	var targets = signature(world)
	var children = art.get_child_count()
	check(art.get_node("ScenicDetails").get_child_count()>0,id+" original location dressing")
	check(art.get_meta("added_triangles") < 11000,id+" bounded added geometry")
	check(art.find_children("*","CollisionObject3D",true,false).is_empty(),id+" decorative art cannot block walking")
	check(art.find_children("*","Marker3D",true,false).is_empty(),id+" decorative art cannot invent actions")
	check(art.get_meta("styled_surfaces")>0,id+" cel shading covers original opaque art")
	check(art.get_node("PaperFinish").layer < game.hud.layer,id+" grading excludes HUD")
	if art.original_environment.get("sky") != null:
		for node in world.find_children("*","WorldEnvironment",true,false):
			check(node.environment.sky==art.original_environment.sky,id+" authored painted sky retained")
	for env in art.sky_environments:
		check(env.sky.radiance_size==Sky.RADIANCE_SIZE_32 and env.sky.process_mode==Sky.PROCESS_MODE_QUALITY,id+" static sky has bounded radiance")
	var sign = art.detail.get_node_or_null("HandmadeDestinationSign")
	if sign != null:
		var fascia = sign.get_node("WoodenFascia")
		check(fascia.position.y > 3.7 if id != "sunrise_cafe" else fascia.position.z > -3.6,id+" destination sign clears original furniture")
	for tier in ["high","low","medium"]:
		var prefs = game.model.snapshot().settings
		prefs.graphics = tier
		game.apply_graphics(prefs)
		check(art.get_child_count()==children,id+" tier changes cannot duplicate scenic art")
		for ink in art.inks: check(float(ink.get_shader_parameter("ink_pixels"))==(0.0 if tier=="low" else (1.0 if tier=="high" else 0.8)),id+" selective line width "+tier)
		for binding in art.ink_bindings: check(binding.material.next_pass==(null if tier=="low" else binding.ink),id+" low tier removes ink draw")
	check(signature(world)==targets,id+" all authored target actions and positions retained")
	check(game.model.snapshot()==before and game.journey.model.snapshot()==journey_before,id+" graphics cannot mutate saves")
	var transforms: Array = []
	for item in art.get_node("ScenicDetails").get_children(): transforms.append(item.transform)
	var prefs = game.model.snapshot().settings
	prefs.reduced_motion = true
	art.apply_settings(prefs)
	await process_frame
	check(transforms==art.get_node("ScenicDetails").get_children().map(func(item): return item.transform),id+" reduced motion keeps scenery static")
	check(art.materials.values().all(func(mat): return mat.get_meta("illustrated_owned",false)),id+" imported materials remain independently owned")
	print("ILLUSTRATED CONTRACT ",id," added_triangles=",art.get_meta("added_triangles")," surfaces=",art.get_meta("styled_surfaces"))
func run():
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://illustrated_contract_"+str(Time.get_ticks_usec())+".json"
	game.journey_save_path = "user://illustrated_contract_journey_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await process_frame
	for entry in fixtures.entries:
		check(game.model.restore(entry.snapshot),"canonical fixture "+entry.id)
		game.route(false)
		game.hud.close_all(); game.resume_controls()
		await verify(entry.id)
	check(game.model.restore(fixtures.completed),"complete seven-chapter fixture")
	game.journey.active = true
	game.journey.model = load("res://core/journey_model.gd").new()
	game.route(false)
	await verify("journey_train")
	for destination in game.journey.model.destinations():
		game.journey.model.apply("return_train")
		check(game.journey.model.apply("board",destination.journey_id),"authored destination "+destination.journey_id)
		game.route(false)
		await verify(destination.journey_id)
	game.audio.shutdown(); game.journey.profile_player.stop()
	game.journey.model.apply("return_train")
	game.journey.model.apply("board","rain_town")
	game.route(false)
	var last_art = game.world_container.get_child(0).get_node("IllustratedWorld")
	var last_skies = last_art.sky_environments.duplicate()
	check(not last_skies.is_empty(),"renderer cleanup fixture owns generated radiance")
	game.remove_child(game.world_container)
	check(last_skies.all(func(env): return env.sky == null),"world exit detaches owned radiance resources")
	game.world_container.queue_free()
	game.queue_free()
	await process_frame
	await process_frame
	await process_frame
	print("ILLUSTRATED GRAPHICS ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
