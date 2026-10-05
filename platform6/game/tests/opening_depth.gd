extends SceneTree
# Removing scenic depth or changing any original opening collider/target must fail.
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func colliders(world: Node3D) -> Array:
	var signature := []
	for shape in world.find_children("*","CollisionShape3D",true,false):
		var geometry = shape.shape
		signature.append([str(shape.get_parent().name),shape.transform,shape.get_parent().transform,geometry.get_class(),geometry.size if geometry is BoxShape3D else Vector2(geometry.radius,geometry.height),shape.disabled])
	return signature
func targets(world: Node3D) -> Array:
	var signature := []
	for node in world.find_children("*","Marker3D",true,false):
		signature.append([("Spawn" if node.name=="Spawn" else "target"),node.transform,node.get_meta("action_id",""),node.get_meta("value",""),node.get_meta("label","")])
	return signature
func triangles(art: Node3D) -> int:
	var total := 0
	for node in art.find_children("*","GeometryInstance3D",true,false):
		var mesh = node.multimesh.mesh if node is MultiMeshInstance3D else node.mesh
		var instances = node.multimesh.instance_count if node is MultiMeshInstance3D else 1
		for index in range(mesh.get_surface_count()):
			var arrays = mesh.surface_get_arrays(index)
			var entries = arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null and not arrays[Mesh.ARRAY_INDEX].is_empty() else arrays[Mesh.ARRAY_VERTEX].size()
			total += entries/3*instances
	return total
func run():
	var exists = ResourceLoader.exists("res://world/opening_depth.gd")
	check(exists,"opening depth visual pass exists")
	if not exists:
		print("Opening depth: %d checks; %d failures" % [checks,failures])
		quit(1)
		return
	var factory = load("res://world/world_factory.gd").new()
	for checkpoint in ["roof","overlook","camera_choice","optional_action"]:
		ProjectSettings.set_setting("opening/depth_enabled",false)
		var baseline = factory.build(checkpoint)
		root.add_child(baseline)
		ProjectSettings.set_setting("opening/depth_enabled",true)
		var world = factory.build(checkpoint)
		root.add_child(world)
		await process_frame
		check(world.has_node("OpeningDepth"),checkpoint+" has isolated painted depth")
		check(colliders(world) == colliders(baseline),checkpoint+" preserves every collider shape/name/transform")
		check(targets(world) == targets(baseline),checkpoint+" preserves every story action/value/target/spawn")
		if world.has_node("OpeningDepth"):
			var art = world.get_node("OpeningDepth")
			check(art.get_meta("original_art",false),"depth uses original authored assets")
			check(not art.is_processing(),"painted depth stays static under pause and reduced motion")
			check(art.find_children("*","CollisionObject3D",true,false).is_empty(),"depth never adds physics")
			check(art.find_children("*","Marker3D",true,false).is_empty(),"depth never adds targets")
			check(art.find_children("*","Label3D",true,false).is_empty(),"depth never adds world-space text")
			check(art.find_children("*","Light3D",true,false).is_empty(),"depth never adds a lighting/shadow pass")
			var geometry = art.find_children("*","GeometryInstance3D",true,false)
			check(geometry.size() <= (20 if checkpoint=="roof" else 8),"scenic depth geometry submission budget")
			check(triangles(art) <= (18000 if checkpoint=="roof" else 4000),"scenic depth instanced triangle budget")
			for node in geometry:
				check(node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"depth batches do not cast extra shadows")
				check(node.material_override.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED,"depth does not stack transparent layers")
				if node is MultiMeshInstance3D and node.multimesh.use_colors:
					check(node.material_override.vertex_color_use_as_albedo,"painted per-instance palettes actually shade city/windows/deck")
			var environment: Environment
			for node in world.get_children():
				if node is WorldEnvironment: environment=node.environment
			check(environment.background_mode==Environment.BG_SKY and environment.sky!=null,"original painted panoramic twilight fills the empty sky")
			check(environment.sky.sky_material is PanoramaSkyMaterial,"single bounded original panoramic sky")
			check(environment.sky.sky_material.panorama!=null,"panorama asset imported")
			if checkpoint=="roof":
				for id in ["FarCity","MiddleCity","NearCity","WarmWindows","RoofRails","RoofTiles","EntryDetails"]: check(art.has_node(id),"roof composition includes "+id)
				for node in world.get_children():
					if str(node.name).begins_with("City"): check(not node.get_child(0).visible,"plain legacy towers replaced visually")
					if str(node.name).begins_with("Lantern"): check(not node.visible,"plain floating lantern cubes retired visually")
				check(art.get_node("WarmWindows").multimesh.instance_count >= 100,"painted city windows have lived-in depth in one batch")
				check(art.get_node("RoofRails").multimesh.instance_count >= 24,"roof perimeter gains readable railing detail")
				var wet = art.get_node("PaintedWetSlate")
				check(wet.multimesh.mesh is ArrayMesh,"wet slate is an irregular painted patch, never a perfect bright disk")
				check(wet.material_override.shading_mode == BaseMaterial3D.SHADING_MODE_PER_VERTEX,"wet patches share real deck lighting")
				check(wet.material_override.albedo_color.v <= 0.34,"wet-slate pigment cannot become a pale foreground plate")
				check(art.get_node("QuietLampPools").material_override.albedo_color.v <= 0.28,"lamp pools remain quiet against dark slate")
				world.get_node("AmbientMotion").apply_preferences(true)
				check(not world.get_node("Rain").visible,"existing rain retains reduced-motion preference")
			else:
				for id in ["DistantRidge","NearHeadland","FarSea","MoonReflection"]: check(art.has_node(id),"shore composition includes "+id)
				check(art.get_node("NearHeadland").get_aabb().size.x >= 260,"near headland endpoints remain beyond playable camera frustum")
				check(art.get_node("DistantRidge").get_aabb().size.x >= 360,"far ridge endpoints remain beyond playable camera frustum")
				check(world.get_node("Lighthouse").position==Vector3(-8,3,-13),"canonical lighthouse preserved")
				check(world.get_node("Arch span").position==Vector3(0,4,-15),"canonical arch preserved")
				var water = world.get_node("Water").get_child(0).material_override
				check(water.shader.code==baseline.get_node("Water").get_child(0).material_override.shader.code,"canonical animated water shader unchanged")
				world.get_node("AmbientMotion").apply_preferences(true)
				check(water.get_shader_parameter("motion_scale")==0.0,"existing water retains reduced-motion freeze")
			print("OPENING_DEPTH_METRIC ",checkpoint," submissions=",geometry.size()," triangles=",triangles(art))
		world.queue_free()
		baseline.queue_free()
		await process_frame
	for checkpoint in ["apartment","platform","passenger","breakfast"]:
		var world = factory.build(checkpoint)
		check(not world.has_node("OpeningDepth"),"depth preserves unrelated scene "+checkpoint)
		world.free()
	ProjectSettings.set_setting("opening/depth_enabled",true)
	print("Opening depth: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
