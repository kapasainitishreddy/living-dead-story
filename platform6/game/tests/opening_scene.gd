extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok: failures += 1; printerr("FAIL "+label)
func _initialize(): call_deferred("run")
func run():
	var factory = load("res://world/world_factory.gd").new()
	var room = factory.build("apartment")
	root.add_child(room)
	await process_frame
	check(room.has_node("ApartmentArt"),"original apartment has authored presentation")
	if room.has_node("ApartmentArt"):
		var art = room.get_node("ApartmentArt")
		for id in ["Floorboards","CityWindow","Bedding","Curtains","ReadingLamp","DoorDetails","Shelf","RugBorder"]:
			check(art.has_node(id),"authored scene element "+id)
		check(art.has_node("StaticBatches"),"static art renders in material batches")
		for lamp in art.find_children("*","OmniLight3D",true,false):
			check(lamp.get_meta("scenic_fill",false),"decorative fill light never multiplies high-tier shadow passes")
		check(art.has_node("SoftFurniture"),"original softly edged furniture exists")
		check(FileAccess.file_exists("res://art/apartment/source/apartment_furniture.blend"),"editable original furniture source retained")
		check(not room.get_node("Table").get_child(0).visible,"cuboid table visual replaced without deleting collider")
		check(art.find_children("*","CollisionShape3D",true,false).is_empty(),"all new decoration collision-free")
		check(art.find_children("*","Label3D",true,false).is_empty(),"art adds no competing world-space text")
		check(not art.is_processing(),"static scenic composition cannot move under pause/reduced motion")
		check(art.get_node("Floorboards").multimesh.instance_count <= 240,"wood detail is batched with bounded instance count")
		check(room.get_node("Door").get_child(0).material_override.emission_enabled == false,"ordinary door no longer glows as a flat rectangle")
		check(room.get_node("Rain window").get_child(0).material_override.albedo_texture != null,"window shows original painted city depth")
		var mat = room.get_node("Apartment wall").get_child(0).material_override
		check(mat.shading_mode == BaseMaterial3D.SHADING_MODE_PER_VERTEX,"static painted surfaces use inexpensive vertex lighting")
		check(mat.albedo_texture != null and mat.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,"plaster uses authored painterly texture with mipmaps")
	for id in ["Bed","Table","Door","Rain window","Floor","ApartmentProps/Mug","ApartmentProps/Chair","ApartmentProps/Kettle","ApartmentProps/Crossword"]:
		check(room.has_node(id),"original ordinary identity remains "+id)
	check(room.get_node("Bed").position == Vector3(-4,0.6,-2),"bed position unchanged")
	check(room.get_node("Table").position == Vector3(4,0.7,-3),"table position unchanged")
	for label in room.get_children():
		if label is Label3D and (label.text.begins_with("3:17") or label.text == "Go up to the roof"):
			check(label.visibility_range_begin >= 8.0,"opening prose never becomes giant foreground lettering")
	var targets = []
	for child in room.get_children():
		if child.has_meta("action_id"): targets.append(child)
	check(targets.size() == 1 and targets[0].get_meta("action_id") == "leave_apartment" and targets[0].position == Vector3(0,0,-7),"single exact opening exit contract unchanged")
	var rain = room.get_node("Rain")
	check(rain.position.x == -5.0 and rain.spread == 0.0 and rain.emission_box_extents.x < 2.0,"animated rain remains inside the actual window aperture")
	check(rain.lifetime <= 0.75 and rain.position.z < -11.0,"rain stays physically outside the apartment")
	check(room.has_node("ApartmentArt/CityWindow/CityBackdrop") and room.has_node("ApartmentArt/WindowWallPanels"),"physical wall aperture exposes exterior rain and painted city")
	var motion = room.get_node("AmbientMotion")
	motion.apply_preferences(true)
	check(not room.get_node("Rain").visible,"reduced motion hides existing animated weather")
	var no_other = factory.build("passenger")
	check(not no_other.has_node("ApartmentArt"),"pass does not change unrelated train scene")
	no_other.free()
	var home = load("res://world/home_world.gd").new().build({"campaign_chapter":"still_here","home_checkpoint":"arrival","home":{},"settings":{"reduced_motion":false}})
	root.add_child(home)
	await process_frame
	check(home.has_node("ApartmentArt"),"return visit uses same authored apartment")
	for id in ["Mug","Chair","Kettle","Crossword"]:
		check(home.get_node("ApartmentProps/"+id).position == room.get_node("ApartmentProps/"+id).position,"same ordinary position in both visits "+id)
	var base_lamps = []
	for node in room.get_children():
		if node is OmniLight3D: base_lamps.append(node.light_energy)
	check(home._lamps.size() == base_lamps.size(),"both visits retain same existing lamp count")
	for i in range(base_lamps.size()):
		check(is_equal_approx(home._lamps[i].light_energy,base_lamps[i]),"return home preserves authored base light "+str(i))
	home.presentation_ending = "sleep"
	home._set_light_fraction(1.0)
	for i in range(base_lamps.size()):
		check(is_equal_approx(home._lamps[i].light_energy,base_lamps[i]*0.8),"sleep softens existing light by original proportion "+str(i))
	home.set_paused(true)
	home.apply_preferences(true)
	check(not home.get_node("Rain").visible and home.get_node("Rain").speed_scale == 0.0,"home pause/reduced-motion freezes weather")
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://opening_graphics_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await process_frame
	for tier in ["low","medium","high"]:
		var preferences = game.model.snapshot().settings
		preferences.graphics = tier
		game.change_settings(preferences)
		check(root.msaa_3d == (Viewport.MSAA_2X if tier == "high" else Viewport.MSAA_DISABLED),"shared apartment has explicit efficient AA budget "+tier)
		for lamp in game.world_container.find_children("*","Light3D",true,false):
			check(not lamp.shadow_enabled,"painted apartment light remains shadowless "+tier)
	game.model.data.checkpoint_id = "passenger"
	game.route()
	var preferences = game.model.snapshot().settings
	preferences.graphics = "medium"
	game.change_settings(preferences)
	check(root.msaa_3d == Viewport.MSAA_2X,"unrelated train retains existing medium AA")
	game.audio.shutdown()
	await create_timer(0.25).timeout
	game.queue_free()
	game = null
	home.queue_free()
	room.queue_free()
	await process_frame
	await process_frame
	factory = null
	print("Opening scene checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
