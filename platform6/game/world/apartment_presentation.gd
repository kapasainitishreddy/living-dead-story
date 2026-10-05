extends RefCounted
# Both visits share this same ordinary room. Presentation is static, collision-free,
# original geometry + editable SVG brush textures; canonical state stays elsewhere.
var factory
var room: Node3D
var art: Node3D
var texture_cache := {}
var material_cache := {}
func texture(id: String) -> Texture2D:
	if not texture_cache.has(id):
		texture_cache[id] = load("res://art/apartment/"+id+".svg")
	return texture_cache[id]
func painted(color: Color, id: String, scale_: Vector3 = Vector3.ONE) -> StandardMaterial3D:
	var key = str(color)+id+str(scale_)
	if material_cache.has(key): return material_cache[key]
	var material = StandardMaterial3D.new()
	material_cache[key] = material
	material.albedo_color = color
	material.albedo_texture = texture(id)
	material.roughness = 0.95
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	material.uv1_triplanar = true
	material.uv1_scale = scale_
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material
func block(parent: Node3D, id: String, pos: Vector3, size_: Vector3, color: Color, kind := "") -> Node3D:
	var node = factory.box(parent,id,pos,size_,color,false)
	if not kind.is_empty(): node.get_child(0).material_override = painted(color,kind)
	return node
func group(id: String) -> Node3D:
	var node = Node3D.new()
	node.name = id
	art.add_child(node)
	return node
func line(parent: Node3D, id: String, start: Vector3, finish: Vector3, width: float, color: Color):
	var node = block(parent,id,(start+finish)/2,Vector3(width,start.distance_to(finish),width),color)
	node.quaternion = Quaternion(Vector3.UP,(finish-start).normalized())
func apply(world: Node3D, builder):
	factory = builder
	room = world
	art = Node3D.new()
	art.name = "ApartmentArt"
	art.set_meta("original_art",true)
	world.add_child(art)
	world.set_meta("efficient_medium_aa",true)
	# Local materials, never recolor cached materials used by other story locations.
	for child in world.get_children():
		if child.name.begins_with("Apartment wall") or child.name in ["Window wall","Ceiling"]:
			child.get_child(0).material_override = painted(Color("899697"),"plaster",Vector3(0.22,0.22,0.22))
		if child is WorldEnvironment:
			child.environment.ambient_light_color = Color("b6c7cf")
			child.environment.ambient_light_energy = 0.45
		if child is DirectionalLight3D:
			child.light_energy = 0.22
		if child is OmniLight3D:
			child.light_energy = 0.75
			child.omni_range = 7
		if child.name.begins_with("Lantern"): child.hide()
	world.get_node("Floor").get_child(0).material_override = painted(Color("64534d"),"wood",Vector3(0.4,0.4,0.4))
	world.get_node("Table").get_child(0).material_override = painted(Color("a18e78"),"wood",Vector3(0.5,0.5,0.5))
	world.get_node("Bed").get_child(0).material_override = painted(Color("768d88"),"cloth",Vector3(0.6,0.6,0.6))
	world.get_node("Pillow").get_child(0).material_override = painted(Color("f0e5d0"),"cloth")
	world.get_node("Rug").get_child(0).material_override = painted(Color("777f7c"),"cloth",Vector3(0.6,0.6,0.6))
	var door = world.get_node("Door").get_child(0)
	door.material_override = painted(Color("9d8065"),"wood",Vector3(0.4,0.4,0.4))
	var window_material = StandardMaterial3D.new()
	window_material.albedo_color = Color.WHITE
	window_material.albedo_texture = texture("city_window")
	window_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	window_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	world.get_node("Rain window").get_child(0).material_override = window_material
	# Narrow exterior rain behind a visual aperture. Original wall collision
	# stays intact; no drop can drift into the room or reach the indoor floor.
	var rain = world.get_node("Rain")
	rain.position = Vector3(-5,3.46,-11.35)
	rain.emission_box_extents = Vector3(1.91,0.02,0.002)
	rain.amount = 80
	rain.lifetime = 0.64
	rain.preprocess = 0.64
	rain.spread = 0.0
	rain.initial_velocity_min = 3.0
	rain.initial_velocity_max = 3.0
	rain.gravity = Vector3.ZERO
	_floor()
	_walls()
	_window()
	_bed()
	_door()
	_shelf()
	_lamp()
	_rug()
	_soft_furniture(world)
	_batch_static(world)
func _floor():
	var batch = MultiMeshInstance3D.new()
	batch.name = "Floorboards"
	var multi = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = factory.shared_box_mesh(Vector3(0.735,0.018,3.64))
	multi.instance_count = 24*6
	var index = 0
	for row in range(24):
		for col in range(6):
			var pos = Vector3(-8.625+row*0.75,0.012,-9.16+col*3.68)
			multi.set_instance_transform(index,Transform3D(Basis.IDENTITY,pos))
			multi.set_instance_color(index,Color.WHITE.darkened(float((row*7+col*3)%5)*0.025))
			index += 1
	batch.multimesh = multi
	var material = painted(Color("a28970"),"wood",Vector3(0.65,0.65,0.32))
	material.vertex_color_use_as_albedo = true
	batch.material_override = material
	art.add_child(batch)
func _walls():
	var trim = group("WallTrim")
	for x in [-8.86,8.86]:
		block(trim,"Skirting",Vector3(x,0.16,0),Vector3(0.08,0.3,21.8),Color("697777"),"wood")
		block(trim,"PictureRail",Vector3(x,3.6,0),Vector3(0.08,0.07,21.8),Color("d0c5ad"))
	block(trim,"BackSkirting",Vector3(0,0.16,-10.86),Vector3(17.7,0.3,0.08),Color("697777"),"wood")
	block(trim,"BackRail",Vector3(0,3.6,-10.86),Vector3(17.7,0.07,0.08),Color("d0c5ad"))
	# Small framed shoreline study, no readable instructions or progression clues.
	block(trim,"PictureFrame",Vector3(4.1,2.5,-10.83),Vector3(1.22,0.85,0.09),Color("a78d69"),"wood")
	block(trim,"PictureMat",Vector3(4.1,2.5,-10.77),Vector3(1.05,0.69,0.015),Color("e8dcc3"))
	block(trim,"PaintedSea",Vector3(4.1,2.45,-10.75),Vector3(0.86,0.4,0.015),Color("688794"),"plaster")
	block(trim,"Horizon",Vector3(4.1,2.6,-10.739),Vector3(0.85,0.02,0.008),Color("bcc2b3"))
func _window():
	var window = group("CityWindow")
	# Retain the original full wall/Window node and every collider, but visually
	# split the plaster around the opening instead of putting a blue decal on it.
	room.get_node("Window wall").get_child(0).hide()
	room.get_node("Rain window").get_child(0).hide()
	var wall = group("WindowWallPanels")
	for info in [
		[Vector3(-8,2,-11),Vector3(2,4,0.2)],
		[Vector3(3,2,-11),Vector3(12,4,0.2)],
		[Vector3(-5,0.75,-11),Vector3(4,1.5,0.2)],
		[Vector3(-5,3.75,-11),Vector3(4,0.5,0.2)]]:
		block(wall,"PlasterPanel",info[0],info[1],Color("899697"),"plaster")
	var backdrop = block(window,"CityBackdrop",Vector3(-5,2.5,-11.85),Vector3(4.7,2.7,0.04),Color.WHITE)
	backdrop.get_child(0).material_override = room.get_node("Rain window").get_child(0).material_override
	for y in [1.45,3.55]: block(window,"WindowBorder",Vector3(-5,y,-10.7),Vector3(4.27,0.13,0.16),Color("b2b6ac"),"wood")
	for x in [-7.08,-2.92]: block(window,"WindowJamb",Vector3(x,2.5,-10.69),Vector3(0.14,2.2,0.16),Color("b2b6ac"),"wood")
	block(window,"Crossbar",Vector3(-5,2.51,-10.68),Vector3(4.13,0.05,0.12),Color("b2b6ac"))
	block(window,"DeepSill",Vector3(-5,1.39,-10.50),Vector3(4.45,0.13,0.62),Color("c3b79e"),"wood")
	var curtains = group("Curtains")
	line(curtains,"BrassRail",Vector3(-7.55,3.74,-10.49),Vector3(-2.45,3.74,-10.49),0.055,Color("ad956c"))
	for side in [-1.0,1.0]:
		for fold in range(6):
			var x = -5+side*(2.04+float(fold)*0.13)
			var curtain = factory.rounded(curtains,"SoftFold",Vector3(x,2.39,-10.34+sin(fold*1.1)*0.055),0.10,0.14,2.45,Color("a79185"))
			curtain.scale.z = 0.75
			curtain.get_child(0).material_override = painted(Color("b4a092").darkened(float(fold%3)*0.045),"cloth")
		block(curtains,"Tie",Vector3(-5+side*2.36,2.13,-10.16),Vector3(0.81,0.075,0.07),Color("7f7971"))
	# A small blue pot and restrained silhouettes do not obscure the night city.
	factory.rounded(window,"PlantPot",Vector3(-3.4,1.64,-10.44),0.18,0.13,0.36,Color("597d83"))
	for i in range(5):
		var leaf = factory.orb(window,Vector3(-3.4+sin(i*2.4)*0.14,1.99+float(i%2)*0.10,-10.45+cos(i*2.4)*0.08),0.15,Color("648c79"))
		leaf.scale = Vector3(0.43,1.4,0.66)
	var light = OmniLight3D.new()
	light.name = "CoolWindowLight"
	light.position = Vector3(-5,2.5,-9.5)
	light.light_color = Color("a3c6dd")
	light.light_energy = 1.6
	light.omni_range = 7
	window.add_child(light)
func _bed():
	var bed = group("Bedding")
	block(bed,"Headboard",Vector3(-4,1.19,-4.63),Vector3(3.18,1.12,0.17),Color("8c7765"),"wood")
	for x in [-5.48,-2.52]: block(bed,"BedRail",Vector3(x,0.46,-2),Vector3(0.13,0.57,5.05),Color("8c7765"),"wood")
	block(bed,"LinenSheet",Vector3(-4,0.935,-2.65),Vector3(2.96,0.085,3.6),Color("d8d1bb"),"cloth")
	block(bed,"Duvet",Vector3(-4,1.015,-1.06),Vector3(3.08,0.17,2.65),Color("78958c"),"cloth")
	block(bed,"FoldedBlanket",Vector3(-4,1.13,-0.38),Vector3(3.10,0.08,0.64),Color("a57e68"),"cloth")
	for x in [-5.37,-2.63]: block(bed,"BlanketHem",Vector3(x,1.18,-0.38),Vector3(0.026,0.012,0.62),Color("d0baa0"))
	for x in [-5.10,-4.4,-3.8,-3.0]:
		block(bed,"DuvetSeam",Vector3(x,1.104,-1.38),Vector3(0.022,0.005,1.77),Color("91a79a"))
func _door():
	var door = group("DoorDetails")
	for x in [-1.16,1.16]: block(door,"DoorFrame",Vector3(x,1.72,-8.83),Vector3(0.14,3.56,0.18),Color("d5c6ae"),"wood")
	block(door,"DoorHeader",Vector3(0,3.51,-8.83),Vector3(2.46,0.16,0.18),Color("d5c6ae"),"wood")
	for y in [0.9,2.35]:
		block(door,"RecessedPanel",Vector3(0,y,-8.876),Vector3(1.75,1.05,0.018),Color("967b61"),"wood")
		for x in [-0.89,0.89]: block(door,"PanelBead",Vector3(x,y,-8.853),Vector3(0.027,1.10,0.035),Color("bd9d77"))
	block(door,"HandlePlate",Vector3(0.81,1.61,-8.825),Vector3(0.09,0.28,0.035),Color("b99c70"))
	factory.orb(door,Vector3(0.81,1.63,-8.77),0.068,Color("c8b083"))
	block(door,"DoorGap",Vector3(0,0.045,-8.84),Vector3(2.12,0.038,0.045),Color("e8ca8a"))
	var spill = OmniLight3D.new()
	spill.name = "HallwaySpill"
	spill.position = Vector3(0,0.35,-8.54)
	spill.light_color = Color("e7bc81")
	spill.light_energy = 0.55
	spill.omni_range = 3.2
	door.add_child(spill)
func _shelf():
	var shelf = group("Shelf")
	for y in [0.61,1.37,2.14]: block(shelf,"ShelfBoard",Vector3(7.70,y,-3.50),Vector3(1.1,0.09,2.85),Color("8f7862"),"wood")
	for z in [-4.83,-2.17]: block(shelf,"ShelfSide",Vector3(7.70,1.28,z),Vector3(1.1,1.79,0.07),Color("8f7862"),"wood")
	for i in range(13):
		var book = block(shelf,"Book",Vector3(7.44,1.67,-4.66+i*0.13),Vector3(0.43,0.49+(i%3)*0.04,0.09),[Color("a78470"),Color("789085"),Color("767e93"),Color("c1ac84")][i%4],"cloth")
		book.rotation.x = 0.05 if i == 12 else 0.0
		block(shelf,"BookSpine",Vector3(7.215,1.63,-4.66+i*0.13),Vector3(0.018,0.023,0.067),Color("d5c4a2"))
	block(shelf,"LinenBasket",Vector3(7.5,0.86,-3.3),Vector3(0.82,0.40,1.07),Color("b0a18a"),"cloth")
func _lamp():
	var lamp = group("ReadingLamp")
	block(lamp,"BedsideTop",Vector3(-6.1,0.81,-3.18),Vector3(0.88,0.10,0.94),Color("a28a6f"),"wood")
	for x in [-6.45,-5.75]:
		for z in [-3.52,-2.84]: block(lamp,"BedsideLeg",Vector3(x,0.41,z),Vector3(0.055,0.76,0.055),Color("a28a6f"),"wood")
	factory.rounded(lamp,"LampBase",Vector3(-6.1,0.92,-3.18),0.21,0.25,0.08,Color("748782"))
	factory.rounded(lamp,"LampStem",Vector3(-6.1,1.18,-3.18),0.034,0.034,0.52,Color("aa9575"))
	var shade = factory.rounded(lamp,"LinenShade",Vector3(-6.1,1.58,-3.18),0.28,0.43,0.43,Color("dfc49a"))
	shade.get_child(0).material_override = painted(Color("f0d6ad"),"cloth")
	shade.get_child(0).material_override.emission_enabled = true
	shade.get_child(0).material_override.emission = Color("bd8f55")
	shade.get_child(0).material_override.emission_energy_multiplier = 0.30
	var glow = OmniLight3D.new()
	glow.name = "ReadingGlow"
	glow.position = Vector3(-6.1,1.42,-3.18)
	glow.light_color = Color("f4c990")
	glow.light_energy = 1.8
	glow.omni_range = 5.5
	lamp.add_child(glow)
func _rug():
	var rug = group("RugBorder")
	for x in [-6.37,-1.63]:
		block(rug,"WovenBorder",Vector3(x,0.052,1),Vector3(0.12,0.008,6.78),Color("b8b29c"),"cloth")
	for z in [-2.39,4.39]: block(rug,"WovenBorder",Vector3(-4,0.052,z),Vector3(4.78,0.008,0.12),Color("b8b29c"),"cloth")
	for x in range(21):
		for z in [-2.54,4.54]: block(rug,"Fringe",Vector3(-6.30+x*0.23,0.053,z),Vector3(0.025,0.008,0.13),Color("c5baa2"))

func _soft_furniture(world: Node3D):
	var furniture = load("res://art/apartment/apartment_furniture.glb").instantiate()
	furniture.name = "SoftFurniture"
	art.add_child(furniture)
	for mesh in furniture.find_children("*","MeshInstance3D",true,false):
		var tint = Color("a18e78")
		var kind = "wood"
		if str(mesh.name).begins_with("RoundedDuvet"):
			tint = Color("78958c")
			kind = "cloth"
		elif str(mesh.name).begins_with("SoftPillow") or str(mesh.name).begins_with("LinenQuilt"):
			tint = Color("f0e5d0")
			kind = "cloth"
		elif str(mesh.name).begins_with("FoldedThrow"):
			tint = Color("b08b71")
			kind = "cloth"
		mesh.material_override = painted(tint,kind,Vector3(0.6,0.6,0.6))
	world.get_node("Table").get_child(0).hide()
	world.get_node("Pillow").get_child(0).hide()
	for node in art.get_node("Bedding").get_children():
		if node.name.begins_with("Duvet") or node.name.begins_with("FoldedBlanket") or node.name.begins_with("BlanketHem"): node.hide()

func _relative_transform(node: Node3D, world: Node3D) -> Transform3D:
	var result = node.transform
	var parent = node.get_parent()
	while parent != world:
		result = parent.transform * result
		parent = parent.get_parent()
	return result
func _visible_to(node: Node3D, world: Node3D) -> bool:
	var parent = node
	while parent != world:
		if not parent.visible: return false
		parent = parent.get_parent()
	return true
func _batch_static(world: Node3D):
	# Keep all original identities/collision and the movable ordinary prop tree.
	# Only their immutable visible surfaces submit material-batched draw calls.
	var sources := {}
	var protected = world.get_node("ApartmentProps")
	for node in world.find_children("*","MeshInstance3D",true,false):
		if protected.is_ancestor_of(node) or not _visible_to(node,world): continue
		var material = node.material_override
		if material == null: continue
		var key = material.get_instance_id()
		if not sources.has(key): sources[key] = {"material":material,"meshes":[]}
		sources[key].meshes.append({"node":node,"transform":_relative_transform(node,world)})
	var batches = group("StaticBatches")
	for key in sources:
		var surface = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_material(sources[key].material)
		for item in sources[key].meshes:
			for index in range(item.node.mesh.get_surface_count()): surface.append_from(item.node.mesh,index,item.transform)
			item.node.hide()
		var visual = MeshInstance3D.new()
		visual.name = "MaterialBatch"+str(batches.get_child_count())
		visual.mesh = surface.commit()
		visual.material_override = sources[key].material
		batches.add_child(visual)
	for light in world.find_children("*","Light3D",true,false):
		light.set_meta("scenic_fill",true)
		light.shadow_enabled = false
