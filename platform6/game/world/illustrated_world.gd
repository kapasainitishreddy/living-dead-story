extends Node3D
# Original, static, collision-free presentation. The model remains the sole
# owner of story and memory. Resources are owned by this world, never imported
# asset materials or the factory's shared cache.
const INK = preload("res://art/illustrated/selective_ink.gdshader")
const FINISH = preload("res://art/illustrated/paper_finish.gdshader")
var profile := ""
var scene: Node3D
var factory = preload("res://world/world_factory.gd").new()
var finish: ShaderMaterial
var inks: Array[ShaderMaterial] = []
var ink_bindings: Array = []
var materials: Dictionary = {}
var detail: Node3D
var original_environment: Dictionary = {}
var sky_environments: Array[Environment] = []
var outlined_surfaces := 0
var styled_surfaces := 0

func configure(world: Node3D, key: String):
	scene = world
	profile = key
	set_meta("original_art",true)
	set_meta("profile",profile)
	detail = Node3D.new()
	detail.name = "ScenicDetails"
	add_child(detail)
	_build_details()
	_ground_accents()
	_framed_title()
	_illustrated_sky()
	var layer = CanvasLayer.new()
	layer.name = "PaperFinish"
	layer.layer = -1 # Grade the 3D picture; HUD and touch controls stay untouched.
	add_child(layer)
	var paper = ColorRect.new()
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finish = ShaderMaterial.new()
	finish.shader = FINISH
	paper.material = finish
	layer.add_child(paper)
	set_meta("added_triangles",_detail_triangles())

func apply_settings(settings: Dictionary):
	outlined_surfaces = 0
	styled_surfaces = 0
	for item in scene.find_children("*","GeometryInstance3D",true,false):
		if item is MeshInstance3D:
			if item.mesh == null: continue
			var selected = _select_ink(item)
			if item.material_override != null:
				item.material_override = _material(item.material_override,selected)
			else:
				for index in item.mesh.get_surface_count():
					var source = item.get_surface_override_material(index)
					if source == null: source = item.mesh.surface_get_material(index)
					if source != null: item.set_surface_override_material(index,_material(source,selected))
		elif item is MultiMeshInstance3D and item.material_override != null:
			item.material_override = _material(item.material_override,false)
	var low = settings.get("graphics","medium") == "low"
	for binding in ink_bindings:
		# Low tier removes the second draw, rather than drawing zero-width ink.
		binding.material.next_pass = null if low else binding.ink
		binding.ink.set_shader_parameter("ink_pixels",0.0 if low else (1.0 if settings.get("graphics") == "high" else 0.8))
	finish.set_shader_parameter("paper_strength",0.0 if settings.get("graphics") == "low" else 0.003)
	finish.set_shader_parameter("warmth",0.06 if _night() else 0.16)
	set_meta("styled_surfaces",styled_surfaces)
	set_meta("outlined_surfaces",outlined_surfaces)

func _material(source: Material, selected: bool) -> Material:
	if not source is StandardMaterial3D: return source
	if source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or source.albedo_color.a < 0.99: return source
	styled_surfaces += 1
	if selected: outlined_surfaces += 1
	if source.get_meta("illustrated_owned",false): return source
	var key = str(source.get_instance_id()) + (":ink" if selected else ":plain")
	if materials.has(key): return materials[key]
	var copy: StandardMaterial3D = source.duplicate()
	copy.set_meta("illustrated_owned",true)
	if copy.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
		copy.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		copy.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		copy.roughness = maxf(copy.roughness,0.88)
	if selected and copy.next_pass == null and copy.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
		var ink = ShaderMaterial.new()
		ink.shader = INK
		copy.next_pass = ink
		inks.append(ink)
		ink_bindings.append({"material":copy,"ink":ink})
	materials[key] = copy
	return copy

func _select_ink(item: MeshInstance3D) -> bool:
	var extent = item.mesh.get_aabb().size * item.scale.abs()
	if maxf(extent.x,maxf(extent.y,extent.z)) < 0.28: return false
	var path = str(scene.get_path_to(item))
	for word in ["Protagonist","Mira","SupportingPerformer","Cabinet","Table","Chair","Kettle","Bench","Trunk","DoorFrame","WindowFrame","AwningPost","Planter","Pot","LanternRoom"]:
		if word in path: return true
	return false

func _night() -> bool:
	if scene.has_meta("time_state"): return scene.get_meta("time_state") in ["night","dusk"]
	return profile not in ["quiet_orchard"]

func _illustrated_sky():
	for node in scene.find_children("*","WorldEnvironment",true,false):
		var env: Environment = node.environment
		if env == null: continue
		original_environment = {"background_mode":env.background_mode,"background_color":env.background_color,"ambient":env.ambient_light_color,"sky":env.sky}
		if env.sky != null:
			# The authored panorama and firefly clearing already have a painted sky.
			env.ambient_light_color = env.ambient_light_color.lerp(Color("a8a4c7"),0.18)
			continue
		# Retain authored time/weather and lighting energy, including Home's fade.
		var sky = ProceduralSkyMaterial.new()
		var night = _night()
		sky.sky_top_color = Color("172238") if night else Color("8cafc3")
		sky.sky_horizon_color = env.background_color.lerp(Color("7b8997") if night else Color("efdbc4"),0.28 if night else 0.65)
		sky.ground_bottom_color = sky.sky_top_color
		sky.ground_horizon_color = sky.sky_horizon_color
		sky.sky_curve = 0.18
		sky.ground_curve = 0.25
		sky.sun_angle_max = 1.0
		var resource = Sky.new()
		resource.radiance_size = Sky.RADIANCE_SIZE_32
		resource.process_mode = Sky.PROCESS_MODE_QUALITY
		resource.sky_material = sky
		env.sky = resource
		sky_environments.append(env)
		env.background_mode = Environment.BG_SKY
		env.ambient_light_color = env.ambient_light_color.lerp(Color("a8a4c7"),0.18)

func _exit_tree():
	# Detach our radiance resources before the world leaves the renderer. Fast
	# scene replacement otherwise leaves GLES cubemaps allocated until shutdown.
	for env in sky_environments: env.sky = null
	sky_environments.clear()

func _build_details():
	match profile:
		"apartment", "still_here": _plant(Vector3(4.87,1.42,-3.1),0.38,Color("9daa88"))
		"roof":
			_tree(Vector3(-7.8,0,-5.5),0.85); _tree(Vector3(8.2,0,-7.8),0.78)
			_sapling(Vector3(-8.4,0,3.6),0.9); _sapling(Vector3(8.3,0,3.4),0.88)
			_potted(Vector3(-6.4,0,2.5),0.9,Color("8ea389"))
			_flowers(Vector3(-5.7,0,4.3),0.9)
			_birds(Vector3(6.6,3.0,3.0),4)
		"platform", "conductor", "return_platform":
			_plant(Vector3(-7.45,0,-6.2),1.15,Color("839d88")); _plant(Vector3(-7.4,0,5.0),0.9,Color("93a18a"))
			_tree(Vector3(-8.4,0,-10.6),0.7)
			_sapling(Vector3(-6.1,0,9.4),0.8)
			_potted(Vector3(-5.7,0,8.2),0.82,Color("8ea389"))
			_flowers(Vector3(-8.4,0,10.2),0.85)
			_birds(Vector3(6.9,3.95,2.2),4)
		"passenger", "shoreline", "return_train", "breakfast", "complete", "journey_train": _plant(Vector3(-2.7,0,-8.6),0.72,Color("879e8a"))
		"overlook", "camera_choice", "optional_action":
			_grass(Vector3(-8,0,-6),1.4); _grass(Vector3(7.8,0,-3),1.3)
			_tree(Vector3(-8.5,0,-8.6),0.75)
			_sapling(Vector3(8.4,0,-6.4),0.8)
			_potted(Vector3(6.9,0,-5.2),0.82,Color("8ea389"))
			_flowers(Vector3(8.6,0,-3.4),0.85)
			_birds(Vector3(7.0,2.6,-4.4),4)
		"the_small_fair": _tree(Vector3(-8.5,0,-7.5),0.98); _tree(Vector3(8.8,0,-8.8),0.9)
		"paper_sky": _plant(Vector3(-6.9,0,-5.4),0.95,Color("8d9b7d")); _plant(Vector3(6.6,0,2.7),0.8,Color("819680"))
		"night_kitchen": _plant(Vector3(-6.5,0,-5.7),0.9,Color("95a47e")); _plant(Vector3(6.4,0,4.8),0.8,Color("8a9b7f"))
		"quiet_orchard": _tree(Vector3(-9.2,0,-10.5),1.05,false); _grass(Vector3(8.7,0,-6),1.2)
		"rain_town": _tree(Vector3(5.9,0,1.3),0.72); _tree(Vector3(-5.9,0,2.7),0.7); _hills()
		"unsent_letters_library": _plant(Vector3(-6.1,0,-2.6),0.9,Color("8d9e89")); _plant(Vector3(6.1,0,0.8),0.78,Color("95a18a"))
		"arcade": _plant(Vector3(-6.1,0,0.5),0.78,Color("8f9d8e")); _plant(Vector3(6.1,0,0.5),0.78,Color("8f9d8e"))
		"beach_before_sunrise": _grass(Vector3(-5.9,0,1.5),0.75); _grass(Vector3(5.8,0,2.3),0.9); _hills(); _coastal_lines()
		"winter_orchard": _tree(Vector3(-5.7,0,2.6),0.8,false); _tree(Vector3(5.7,0,2.3),0.72,false); _hills()
		"rest_room": _plant(Vector3(-5.9,0,1.7),0.87,Color("96a68b")); _curtains()
		"failed_things_festival": _tree(Vector3(-5.8,0,2.4),0.75); _plant(Vector3(5.8,0,2.4),0.8,Color("9ca682")); _hills()
		"sunrise_cafe": _tree(Vector3(5.9,0,1.5),0.73); _plant(Vector3(-5.9,0,1.9),0.85,Color("95a480")); _hills()
		"no_destination_road": _tree(Vector3(-5.7,0,2.8),0.82); _tree(Vector3(5.6,0,0.5),0.74); _hills()
		"fireflies": _grass(Vector3(-5.5,0,2.5),0.8); _grass(Vector3(5.5,0,2.4),0.8)

func _batch(id: String, shape: Mesh, transforms: Array[Transform3D], colours: Array[Color], unlit := false) -> MultiMeshInstance3D:
	var batch = MultiMeshInstance3D.new()
	batch.name = id
	var multi = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = shape
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i,transforms[i])
		multi.set_instance_color(i,colours[i])
	batch.multimesh = multi
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if unlit: mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	batch.material_override = mat
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	detail.add_child(batch)
	return batch

func _no_shadows(node: Node3D):
	# Mobile dressing never adds a shadow pass.
	for item in node.find_children("*","GeometryInstance3D",true,false):
		item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _bud() -> SphereMesh:
	# Cheap painted blob shared by flowers, leaves, saplings and birds.
	var shape = SphereMesh.new()
	shape.radius = 1.0
	shape.height = 2.0
	shape.radial_segments = 6
	shape.rings = 3
	return shape

func _sphere() -> SphereMesh:
	var shape = SphereMesh.new()
	shape.radius = 1.0
	shape.height = 2.0
	shape.radial_segments = 12
	shape.rings = 6
	return shape

func _tree(where: Vector3, size_: float, blossom := true):
	var tree = Node3D.new()
	tree.name = "BlossomPlanter" if blossom else "WinterBranches"
	tree.position = where
	tree.scale = Vector3.ONE * size_
	detail.add_child(tree)
	factory.rounded(tree,"Planter",Vector3(0,0.16,0),0.61,0.53,0.32,Color("988379"))
	factory.rounded(tree,"Soil",Vector3(0,0.326,0),0.54,0.54,0.018,Color("655450"))
	factory.rounded(tree,"Trunk",Vector3(0,1.65,0),0.09,0.16,2.8,Color("74606a"))
	for i in range(4):
		var branch = factory.rounded(tree,"Branch",Vector3((i%2*2-1)*0.32,2.35+(i/2)*0.4,0.08*(i%3)),0.035,0.07,1.4,Color("74606a"))
		branch.rotation.z = (i%2*2-1)*0.65
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	if blossom:
		for i in range(15):
			var angle = i * 2.39996
			var radius = 0.18 + (i%4)*0.28
			var pos = where + Vector3(sin(angle)*radius,3.1+(i%3)*0.34,cos(angle)*radius)*size_
			transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.62,0.45,0.54)*size_),pos))
			colours.append([Color("ddb7c7"),Color("f2d1d2"),Color("f5dfdc")][i%3])
		_batch("PaintedBlossomMasses",_sphere(),transforms,colours,true)
	else:
		transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.57,0.065,0.54)*size_),where+Vector3(0,0.34,0)*size_))
		colours.append(Color("d7e0dd"))
		_batch("SnowAtRoots",_sphere(),transforms,colours)

func _sapling(where: Vector3, size_: float):
	# Low-poly roadside tree: one trunk plus a single batched painted canopy.
	var tree = Node3D.new()
	tree.name = "RoadsideSapling"
	tree.position = where
	tree.scale = Vector3.ONE * size_
	detail.add_child(tree)
	_no_shadows(factory.rounded(tree,"SaplingTrunk",Vector3(0,0.62,0),0.05,0.085,1.24,Color("6f5b52")))
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for i in range(4):
		var angle = i * 2.39996
		var pos = where + Vector3(sin(angle)*0.22,1.32+(i%2)*0.22,cos(angle)*0.22)*size_
		transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.36,0.30,0.36)*size_),pos))
		colours.append([Color("ddb7c7"),Color("f2d1d2"),Color("c98fae"),Color("e9c9cf")][i%4])
	_batch("PaintedSaplingCanopy",_bud(),transforms,colours,true)

func _plant(where: Vector3, size_: float, colour: Color):
	var plant = Node3D.new()
	plant.name = "EverydayPot"
	plant.position = where
	plant.scale = Vector3.ONE * size_
	detail.add_child(plant)
	factory.rounded(plant,"Pot",Vector3(0,0.24,0),0.25,0.18,0.48,Color("bd8e7a"))
	factory.rounded(plant,"PotRim",Vector3(0,0.45,0),0.28,0.28,0.07,Color("cba38b"))
	factory.rounded(plant,"Soil",Vector3(0,0.492,0),0.24,0.24,0.02,Color("5e5552"))
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for i in range(9):
		var angle = i * 2.39996
		var basis = Basis(Vector3.UP,angle) * Basis(Vector3.FORWARD,0.55)
		basis = basis.scaled(Vector3(0.09,0.35,0.18)*size_)
		transforms.append(Transform3D(basis,where+Vector3(sin(angle)*0.19,0.72+(i%3)*0.11,cos(angle)*0.19)*size_))
		colours.append(colour.lightened(0.035*(i%3)))
	_batch("PaintedLeaves",_sphere(),transforms,colours)

func _potted(where: Vector3, size_: float, colour: Color):
	# Small village pot: three pot rings and one batched leaf clump.
	var pot = Node3D.new()
	pot.name = "VillagePot"
	pot.position = where
	pot.scale = Vector3.ONE * size_
	detail.add_child(pot)
	for part in [factory.rounded(pot,"Pot",Vector3(0,0.22,0),0.24,0.17,0.44,Color("bd8e7a")),factory.rounded(pot,"PotRim",Vector3(0,0.42,0),0.27,0.27,0.06,Color("cba38b")),factory.rounded(pot,"Soil",Vector3(0,0.462,0),0.23,0.23,0.02,Color("5e5552"))]:
		_no_shadows(part)
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for i in range(8):
		var angle = i * 2.39996
		var basis = Basis(Vector3.UP,angle) * Basis(Vector3.FORWARD,0.55)
		basis = basis.scaled(Vector3(0.11,0.32,0.19)*size_)
		transforms.append(Transform3D(basis,where+Vector3(sin(angle)*0.18,0.68+(i%3)*0.10,cos(angle)*0.18)*size_))
		colours.append(colour.lightened(0.04*(i%3)))
	_batch("PaintedPotLeaves",_bud(),transforms,colours)

func _flowers(where: Vector3, size_: float):
	# One collision-free draw call per cluster: petals and a few leaves.
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for i in range(9):
		var angle = i * 2.39996
		var pos = where + Vector3(sin(angle)*0.44,0.15+(i%3)*0.10,cos(angle)*0.44)*size_
		transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.17,0.13,0.17)*size_),pos))
		colours.append([Color("d99ab4"),Color("f0d98c"),Color("f3efe0"),Color("c98fae")][i%4])
	for i in range(3):
		var angle = i * 2.39996 + 0.7
		var pos = where + Vector3(sin(angle)*0.52,0.08,cos(angle)*0.52)*size_
		transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.15,0.11,0.15)*size_),pos))
		colours.append(Color("7c9a74").lightened(0.05*i))
	_batch("PaintedFlowerClusters",_bud(),transforms,colours,true)

func _birds(where: Vector3, count: int):
	# Static perched flock. Reduced motion is unknown at build time, so the
	# birds never process and never change their node transform.
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for i in range(count):
		var angle = i * 2.39996
		var spread = 0.30 + 0.13*(i%3)
		var pos = where + Vector3(sin(angle)*spread,0.09*(i%2),cos(angle)*spread)
		var basis = Basis(Vector3.UP,angle).scaled(Vector3(0.13,0.11,0.17))
		transforms.append(Transform3D(basis,pos))
		colours.append([Color("454052"),Color("575166"),Color("6a6478")][i%3])
	_batch("PaintedBirdFlock",_bud(),transforms,colours)

func _grass(where: Vector3, size_: float):
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for i in range(12):
		var basis = Basis(Vector3.FORWARD,(i%5-2)*0.14).scaled(Vector3(0.035,0.26+(i%3)*0.08,0.10)*size_)
		transforms.append(Transform3D(basis,where+Vector3(sin(i*2.4)*0.45,0.22,cos(i*2.4)*0.34)*size_))
		colours.append([Color("71877c"),Color("9eaf95"),Color("b6b998")][i%3])
	_batch("PaintedGrass",_sphere(),transforms,colours)

func _hills():
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for i in range(8):
		var scale_ = Vector3(5.0,2.6+(i%3)*1.1,3.5)
		transforms.append(Transform3D(Basis.IDENTITY.scaled(scale_),Vector3(-17.5+i*5,-1.1,-16.0-(i%2)*5.5)))
		colours.append((Color("4c6276") if _night() else Color("889eaa")).lightened((i%2)*0.07))
	_batch("LayeredDistantHills",_sphere(),transforms,colours,true)

func _curtains():
	for side in [-1.0,1.0]:
		for fold in range(5):
			factory.rounded(detail,"LinenFold",Vector3(side*(2.18+fold*0.08),2.23,-5.99),0.065,0.085,1.94,Color("c9c2b2"))

func _coastal_lines():
	var shape = BoxMesh.new()
	shape.size = Vector3(1.0,0.01,0.025)
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for row in range(3):
		for i in range(11):
			transforms.append(Transform3D(Basis(Vector3.UP,sin(i*0.72)*0.035),Vector3(-5.5+i,0.091,-4.4-row*0.61+sin(i*0.72)*0.10)))
			colours.append(Color("d0d8c8").darkened(row*0.04))
	_batch("DrawnShoreRibbons",shape,transforms,colours,true)

func _ground_accents():
	if profile not in ["rain_town","unsent_letters_library","rest_room","failed_things_festival","sunrise_cafe"]: return
	var shape = BoxMesh.new()
	var indoor = profile in ["unsent_letters_library","rest_room"]
	shape.size = Vector3(0.38,0.012,1.52) if indoor else Vector3(0.87,0.012,0.87)
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	var base = Color("a3a99f") if profile == "rain_town" else (Color("b89c82") if indoor else Color("c9c1ad"))
	for x in range(24 if indoor else 12):
		for z in range(8 if indoor else 12):
			var pos = Vector3(-4.6+x*0.4,0.018,-5.4+z*1.56) if indoor else Vector3(-4.95+x*0.9,0.018,-4.95+z*0.9)
			# Preserve the original soft rest rug in the open centre.
			if profile == "rest_room" and Vector2(pos.x,pos.z).length() < 2.85: continue
			transforms.append(Transform3D(Basis.IDENTITY,pos))
			colours.append(base.lightened(0.018*((x*3+z*5)%4)))
	_batch("AuthoredPaving" if not indoor else "LinenRoomFloorboards",shape,transforms,colours)

func _framed_title():
	if not scene.has_meta("journey_id") or profile in ["journey_train","fireflies"]: return
	var title = scene.get_node_or_null("Scenery/DestinationTitle")
	var note = scene.get_node_or_null("Scenery/UnhurriedNote")
	if title == null or note == null: return
	# Give the existing words a physical sign. No new story text or targets.
	var sign = Node3D.new()
	sign.name = "HandmadeDestinationSign"
	detail.add_child(sign)
	# Mount the cafe fascia under the front awning. Back-wall signs clear the
	# library's upper shelves and retain the existing small prop labels below.
	var center = Vector3(0,2.82,-3.50) if profile == "sunrise_cafe" else Vector3(0,3.90,-6.18)
	var height = 0.70 if profile == "sunrise_cafe" else 0.92
	factory.box(sign,"WoodenFascia",center,Vector3(7.6,height,0.10),Color("b79b85"),false)
	factory.box(sign,"PaintedFace",center+Vector3(0,0,0.061),Vector3(7.34,height-0.18,0.018),Color("485965"),false)
	for x in [-3.59,3.59]: factory.box(sign,"SignBolt",center+Vector3(x,0,0.08),Vector3(0.04,0.04,0.018),Color("d7c4a5"),false)
	if profile not in ["sunrise_cafe","unsent_letters_library","rest_room"]:
		for x in [-3.57,3.57]: factory.box(sign,"SignUpright",Vector3(x,1.91,-6.18),Vector3(0.075,3.82,0.075),Color("887e72"),false)
	title.position = center + Vector3(0,0.14,0.085)
	note.position = center + Vector3(0,-0.16,0.085)

func _detail_triangles() -> int:
	var count := 0
	for item in detail.find_children("*","GeometryInstance3D",true,false):
		var shape: Mesh = item.mesh if item is MeshInstance3D else (item.multimesh.mesh if item is MultiMeshInstance3D else null)
		if shape == null: continue
		var instances: int = item.multimesh.instance_count if item is MultiMeshInstance3D else 1
		for index in shape.get_surface_count():
			var arrays = shape.surface_get_arrays(index)
			count += ((arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null and arrays[Mesh.ARRAY_INDEX].size() > 0 else arrays[Mesh.ARRAY_VERTEX].size()) / 3) * instances
	return count
