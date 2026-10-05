extends SceneTree
var checks := 0
var failures := 0
func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)
func _initialize():
	var factory = load("res://world/world_factory.gd")
	if factory == null:
		printerr("FAIL: world factory missing")
		quit(1)
		return
	for checkpoint in load("res://core/chapter_model.gd").STATES:
		var world = factory.new().build(checkpoint)
		check(world.get_node_or_null("Spawn") != null, "safe spawn " + checkpoint)
		check(world.get_node_or_null("Floor") is StaticBody3D, "collidable floor " + checkpoint)
		if world.get_node_or_null("Carriage floor"):
			check(world.get_node("Carriage floor").position.y > -0.1,"carriage avoids coplanar z-fighting")
		if checkpoint == "apartment": check(world.get_node("Rain").position.z < -11,"apartment rain stays outside")
		if checkpoint == "roof": check(world.get_node_or_null("Rain") != null,"roof rain ambience")
		if checkpoint == "overlook":
			check(world.get_node("Water").get_child(0).material_override is ShaderMaterial,"moonlit moving water")
			for sign in world.find_children("*","Label3D",true,false):
				if sign.text.begins_with("Viewing marker"):
					check(sign.visibility_range_begin >= 3.5,"near-camera marker lettering cannot balloon across viewport")
		if checkpoint in ["platform","conductor"]:
			check(world.find_children("*","WorldEnvironment",true,false)[0].environment.ambient_light_energy < 0.4,"station uses low ambient for warm lamp contrast")
			check(world.get_node_or_null("StationArt") != null,"layered station art exists")
			for sign in world.find_children("*","Label3D",true,false):
				if sign.text == "WHERE DO YOU WANT TO GO?": check(sign.billboard == BaseMaterial3D.BILLBOARD_DISABLED,"fixed board lettering cannot rotate into board")
			check(world.find_children("CanopyRib*", "", true, false).size() >= 5,"arched canopy has repeated structural ribs")
			var tiles = world.find_children("TileBatch*", "MultiMeshInstance3D", true, false)
			var total_tiles = 0
			var authored_positions = {}
			var tile_shapes_match = true
			for batch in tiles:
				total_tiles += batch.multimesh.instance_count
				tile_shapes_match = tile_shapes_match and batch.multimesh.mesh.get_aabb().size.is_equal_approx(Vector3(0.975,0.035,0.975))
				var parts = str(batch.name).trim_prefix("TileBatch").split("_")
				var source_transforms = factory.new().tile_transforms(int(parts[0]),int(parts[1])) if factory.new().has_method("tile_transforms") else []
				# Dummy headless RenderingServer returns identity for server-backed MultiMesh reads.
				if DisplayServer.get_name() != "headless":
					var actual_transforms_match = batch.multimesh.instance_count == source_transforms.size()
					for i in range(min(batch.multimesh.instance_count,source_transforms.size())):
						actual_transforms_match = actual_transforms_match and batch.multimesh.get_instance_transform(i).is_equal_approx(source_transforms[i])
					check(actual_transforms_match,"rendered multimesh retains every authored tile transform " + str(batch.name))
				for transform in source_transforms:
					var pos = transform.origin
					authored_positions[Vector2i(roundi(pos.x-0.5),roundi(pos.z-0.5))] = pos
			var tile_layout_matches = authored_positions.size() == 322
			for x in range(-9,5):
				for z in range(-11,12):
					tile_layout_matches = tile_layout_matches and authored_positions.get(Vector2i(x,z),Vector3.ZERO).is_equal_approx(Vector3(x+0.5,0.018,z+0.5))
			check(tile_layout_matches and tile_shapes_match,"batching preserves every authored tile transform and size")
			check(total_tiles == 322 and tiles.size() <= 12,"all322 tiles use bounded multimesh batches")
			check(world.find_children("TrainWindow*", "", true, false).size() >= 8,"detailed carriage windows")
		var person = Node3D.new()
		factory.new().person(person,Vector3.ZERO,Color("ccac88"))
		check(person.get_node("Coat").get_child(0).mesh is CylinderMesh,"rounded coat silhouette")
		check(person.get_node_or_null("Hair") != null,"original hair silhouette")
		check(person.get_node_or_null("Satchel") != null,"character clothing accessory")
		person.free()
		world.free()
	var caching_factory = factory.new()
	var parent = Node3D.new()
	var box_a = caching_factory.box(parent,"A",Vector3.ZERO,Vector3.ONE,Color.WHITE,false)
	var box_b = caching_factory.box(parent,"B",Vector3.ONE,Vector3.ONE,Color.WHITE,false)
	check(box_a.get_child(0).mesh == box_b.get_child(0).mesh,"identical box geometry shares resource")
	check(box_a.get_child(0).material_override == box_b.get_child(0).material_override,"identical materials share resource")
	parent.free()
	print("Runtime world checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
