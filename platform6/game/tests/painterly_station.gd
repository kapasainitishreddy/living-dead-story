extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func collision_signature(world: Node3D) -> Array:
	var result: Array = []
	for node in world.find_children("*", "CollisionShape3D", true, false):
		var dimensions = node.shape.size if node.shape is BoxShape3D else Vector2(node.shape.radius,node.shape.height)
		result.append([node.global_transform,node.get_parent().transform,node.transform,node.disabled,node.shape.get_class(),dimensions])
	return result
func _initialize():
	call_deferred("run")
func run():
	var shader_source = FileAccess.get_file_as_string("res://art/station/painterly.gdshader")
	check(not shader_source.contains("DIFFUSE_LIGHT += ALBEDO"), "Compatibility applies albedo once after custom diffuse light")
	var factory = load("res://world/world_factory.gd").new()
	var world = factory.build("conductor")
	root.add_child(world)
	var train = world.get_node("Train").get_child(0)
	check(train.material_override is ShaderMaterial, "train gets custom station material")
	check(train.mesh is ArrayMesh, "train visual uses authored bevel geometry")
	check(train.mesh.get_aabb().size.is_equal_approx(Vector3(4,3.6,22)), "train bevel preserves original visual extents")
	check(world.has_meta("painterly_station"), "station records isolated presentation")
	check(world.find_children("TravelPoster*", "MeshInstance3D", true, false).size() == 3, "three original illustrated station posters")
	check(world.find_children("DistantWindow*", "Node3D", true, false).size() == 0, "distance windows replaced by painted opaque facades")
	check(world.get_node("StationArt/TileBatch0_0").material_override is ShaderMaterial, "tile wear atlas is active")
	var tiles = world.get_node("StationArt/TileBatch0_0").multimesh.mesh
	check(tiles is ArrayMesh, "atlas surfaces normalize each box face UV")
	if tiles is ArrayMesh:
		var uv = tiles.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
		check(uv.has(Vector2.ONE), "normalized face UV reaches full cell")
		var normals = tiles.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
		var faces: Dictionary = {}
		for i in range(normals.size()):
			if not faces.has(normals[i]): faces[normals[i]] = [uv[i],uv[i]]
			faces[normals[i]][0] = faces[normals[i]][0].min(uv[i])
			faces[normals[i]][1] = faces[normals[i]][1].max(uv[i])
		check(faces.size() == 6, "normalized box retains six complete face normals")
		for bounds in faces.values(): check(bounds[0].is_equal_approx(Vector2.ZERO) and bounds[1].is_equal_approx(Vector2.ONE), "every box face spans full atlas cell")
	check(train.material_override.get_shader_parameter("surface_atlas") is Texture2D if train.material_override is ShaderMaterial else false, "authored atlas bound")
	var collision_before = collision_signature(world)
	ProjectSettings.set_setting("station/painterly_enabled", false)
	var fallback = load("res://world/world_factory.gd").new().build("conductor")
	root.add_child(fallback)
	check(fallback.get_node("Train").get_child(0).material_override is StandardMaterial3D, "fallback retains standard material")
	var collision_after = collision_signature(fallback)
	check(collision_before == collision_after, "presentation leaves all collision transforms, classes and full dimensions unchanged")
	ProjectSettings.set_setting("station/painterly_enabled", true)
	var apartment = load("res://world/world_factory.gd").new().build("apartment")
	root.add_child(apartment)
	check(not apartment.has_meta("painterly_station"), "art treatment isolated to station")
	check(apartment.get_node("Floor").get_child(0).material_override is StandardMaterial3D, "other checkpoints keep their materials")
	for light in world.find_children("*", "OmniLight3D", true, false):
		check(not light.shadow_enabled or light.position == Vector3(-2,4.8,-1), "no additional shadow casting local lights")
	world.queue_free()
	fallback.queue_free()
	apartment.queue_free()
	await process_frame
	print("PAINTERLY STATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
