extends RefCounted
const BLUE = Color("293e62")
const AMBER = Color("eebf79")
const CREAM = Color("ece2cb")
var box_mesh_cache: Dictionary = {}
var material_cache: Dictionary = {}
func shared_material(color_: Color, roughness_: float = 0.85, toon: bool = false, emission_: float = 1.0) -> StandardMaterial3D:
	var key = str(color_) + ":" + str(roughness_) + ":" + str(toon) + ":" + str(emission_)
	if material_cache.has(key): return material_cache[key]
	var material = StandardMaterial3D.new()
	material.albedo_color = color_
	material.roughness = roughness_
	if toon:
		material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		material.specular_mode = BaseMaterial3D.SPECULAR_TOON
	if color_ == AMBER:
		material.emission_enabled = true
		material.emission = AMBER
		material.emission_energy_multiplier = emission_
	material_cache[key] = material
	return material
func shared_box_mesh(size_: Vector3) -> BoxMesh:
	var key = str(size_)
	if not box_mesh_cache.has(key):
		var cube = BoxMesh.new()
		cube.size = size_
		box_mesh_cache[key] = cube
	return box_mesh_cache[key]
func box(parent: Node3D, name_: String, position_: Vector3, size_: Vector3, color_: Color, collision: bool = true) -> Node3D:
	var body = StaticBody3D.new() if collision else Node3D.new()
	body.name = name_
	body.position = position_
	parent.add_child(body, true)
	var mesh = MeshInstance3D.new()
	mesh.mesh = shared_box_mesh(size_)
	mesh.material_override = shared_material(color_)
	body.add_child(mesh)
	if collision:
		var shape = CollisionShape3D.new()
		var geometry = BoxShape3D.new()
		geometry.size = size_
		shape.shape = geometry
		body.add_child(shape)
	return body
func orb(parent: Node3D, pos: Vector3, radius: float, color_: Color) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	mesh.mesh = sphere
	mesh.position = pos
	mesh.material_override = shared_material(color_,1.0,false,1.2)
	parent.add_child(mesh)
	return mesh
func label(parent: Node3D, text_: String, pos: Vector3, size_: int = 40):
	var sign = Label3D.new()
	sign.text = text_
	sign.position = pos
	sign.font_size = size_
	sign.pixel_size = 0.009
	sign.modulate = CREAM
	sign.outline_modulate = Color("152038")
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(sign)
func target(world: Node3D, pos: Vector3, text_: String, action: String, value: Variant = null):
	var marker = Marker3D.new()
	marker.position = pos
	marker.set_meta("action_id", action)
	marker.set_meta("value", value)
	marker.set_meta("label", text_)
	marker.add_to_group("interactables")
	world.add_child(marker)
	label(world, text_, pos + Vector3(0,2.1,0), 28)
	# Nearby interaction is already named in HUD; avoid giant foreground text.
	world.get_child(world.get_child_count()-1).visibility_range_begin = 3.5
func rounded(parent: Node3D, name_: String, pos: Vector3, top: float, bottom: float, height: float, color_: Color, collision: bool = false) -> Node3D:
	var node = StaticBody3D.new() if collision else Node3D.new()
	node.name = name_
	node.position = pos
	parent.add_child(node)
	var mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = 16
	mesh.mesh = cylinder
	mesh.material_override = shared_material(color_,0.8,true)
	node.add_child(mesh)
	if collision:
		var shape = CollisionShape3D.new()
		var cylinder_shape = CylinderShape3D.new()
		cylinder_shape.radius = max(top,bottom)
		cylinder_shape.height = height
		shape.shape = cylinder_shape
		node.add_child(shape)
	return node
func person(world: Node3D, pos: Vector3, color_: Color):
	# Keep existing chapter staging handles, but their geometry is never visible.
	var legacy_start = world.get_child_count()
	var coat = rounded(world,"Coat",pos+Vector3(0,0.92,0),0.24,0.36,0.9,color_)
	coat.scale.z = 0.65
	orb(world,pos+Vector3(0,1.59,0),0.205,Color("f5ceb0"))
	var hair = orb(world,pos+Vector3(0,1.69,-0.035),0.22,Color("352936"))
	hair.name = "Hair"
	hair.scale = Vector3(1,0.75,1.05)
	var bun = orb(world,pos+Vector3(0,1.83,-0.08),0.115,Color("352936"))
	bun.name = "HairBun"
	for x in [-0.08,0.08]:
		orb(world,pos+Vector3(x,1.61,0.183),0.035,Color("ece7dd"))
		orb(world,pos+Vector3(x,1.61,0.211),0.017,Color("35475a"))
	for x in [-0.32,0.32]:
		var limb = rounded(world,"ArmLeft" if x < 0 else "ArmRight",pos+Vector3(x,1.19,0),0.095,0.07,0.58,color_)
		limb.get_child(0).position.y = -0.22
		orb(limb,Vector3(0,-0.53,0),0.075,Color("f5ceb0"))
	for x in [-0.15,0.15]:
		var limb = rounded(world,"LegLeft" if x < 0 else "LegRight",pos+Vector3(x,0.55,0),0.085,0.065,0.4,BLUE)
		limb.get_child(0).position.y = -0.18
		var boot = orb(limb,Vector3(0,-0.46,0.045),0.12,Color("41323a"))
		boot.scale = Vector3(0.75,0.6,1.35)
	rounded(world,"Scarf",pos+Vector3(0,1.36,0),0.255,0.24,0.13,Color("e8b66c"))
	box(world,"Scarf tail",pos+Vector3(0.14,1.08,0.2),Vector3(0.12,0.5,0.035),Color("e8b66c"),false)
	var bag = orb(world,pos+Vector3(-0.32,0.8,-0.05),0.2,Color("8a593e"))
	bag.name = "Satchel"
	bag.scale = Vector3(0.55,0.9,1.1)
	var strap = box(world,"Satchel strap",pos+Vector3(0,1.05,-0.18),Vector3(0.045,0.68,0.04),Color("8a593e"),false)
	strap.rotation.z = -0.6
	for index in range(legacy_start,world.get_child_count()):
		var handle = world.get_child(index)
		handle.visible = false
		handle.set_meta("legacy_staging_handle",true)
	var actor = load("res://characters/supporting_performer.gd").new()
	actor.name = "SupportingPerformer"
	actor.position = pos
	actor.stage_owner = world
	var id = str(world.get_meta("character_id",str(world.name).to_lower()))
	if not id in ["ada","noor","rafi","conductor","jo"]:
		if color_ in [Color("b48262")]: id = "ada"
		elif color_ in [Color("879c86")]: id = "noor"
		elif color_ in [Color("627d70"),Color("728775")]: id = "conductor"
		elif str(world.name).contains("Worker") or str(world.name).contains("Driver"): id = "rafi"
		else: id = "jo"
	actor.configure(id)
	world.add_child(actor)
func production_character(world: Node3D, pos: Vector3, id: String) -> Node3D:
	var performer = load("res://characters/character_performer.gd").new()
	performer.name = "Mira" if id == "mira" else "Protagonist"
	performer.configure(id)
	performer.position = pos
	world.add_child(performer)
	return performer
func tile_transforms(tone: int, rough: int) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	for x in range(-9,5):
		for z in range(-11,12):
			if (x+z+60)%3 == tone and (x*3+z+60)%4 == rough:
				transforms.append(Transform3D(Basis.IDENTITY,Vector3(x+0.5,0.018,z+0.5)))
	return transforms
func station_art(world: Node3D):
	var art = Node3D.new()
	art.name = "StationArt"
	world.add_child(art)
	var navy = Color("24364f")
	var brass = Color("b99055")
	var stone = Color("777b87")
	# Keep every authored tile transform/tone/roughness, but render twelve batches.
	for tone in range(3):
		for rough in range(4):
			var transforms = tile_transforms(tone,rough)
			var batch = MultiMeshInstance3D.new()
			batch.name = "TileBatch%d_%d" % [tone,rough]
			var multimesh = MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = shared_box_mesh(Vector3(0.975,0.035,0.975))
			multimesh.instance_count = transforms.size()
			for i in range(transforms.size()): multimesh.set_instance_transform(i,transforms[i])
			batch.multimesh = multimesh
			batch.material_override = shared_material(stone.lightened(0.055*tone),0.4+0.1*rough)
			art.add_child(batch)
	box(art,"SafetyLine",Vector3(4.25,0.05,0),Vector3(0.14,0.02,23),Color("e0bf77"),false)
	box(world,"Train",Vector3(7,1.95,-1),Vector3(4,3.6,22),CREAM)
	box(art,"TrainNavyPanel",Vector3(4.975,0.98,-1),Vector3(0.045,1.55,22),navy,false)
	for y in [0.4,1.65,3.45]: box(art,"TrainGoldTrim",Vector3(4.94,y,-1),Vector3(0.05,0.045,22),brass,false)
	var roof = rounded(art,"TrainRoundedRoof",Vector3(7,3.7,-1),2.0,2.0,22,navy)
	roof.rotation.x = PI/2
	roof.scale.z = 0.2
	for z in [-10.0,-7.5,-5.0,-2.5,0.0,2.5,5.0,7.5,10.0]:
		box(art,"TrainWindowFrame",Vector3(4.91,2.5,z),Vector3(0.07,1.5,1.9),brass,false)
		box(art,"TrainWindow",Vector3(4.86,2.5,z),Vector3(0.03,1.25,1.64),AMBER,false)
		box(art,"WindowMullion",Vector3(4.82,2.5,z),Vector3(0.04,1.3,0.045),navy,false)
		for zz in [-0.65,0.65]: box(art,"WindowCurtain",Vector3(4.81,2.5,z+zz),Vector3(0.04,1.15,0.22),Color("b77753"),false)
		box(art,"CarriageVent",Vector3(4.9,0.8,z),Vector3(0.045,0.14,0.65),brass,false)
	box(art,"TrainDoorFrame",Vector3(4.8,1.7,-4),Vector3(0.08,3.1,1.25),brass,false)
	box(art,"TrainDoor",Vector3(4.75,1.7,-4),Vector3(0.04,2.9,1.05),navy,false)
	box(art,"DoorGlass",Vector3(4.7,2.25,-4),Vector3(0.03,1.4,0.75),AMBER,false)
	box(art,"DoorHandle",Vector3(4.66,1.55,-3.65),Vector3(0.08,0.22,0.055),brass,false)
	for z in [-9.0,-5.0,-1.0,3.0,7.0,11.0]:
		for x in [-7.5,4.1]:
			rounded(art,"Column",Vector3(x,2.7,z),0.13,0.18,5.4,navy,true)
			rounded(art,"ColumnFoot",Vector3(x,0.2,z),0.3,0.3,0.4,brass,true)
			box(art,"ColumnCapital",Vector3(x,5.25,z),Vector3(0.6,0.18,0.6),brass,false)
		for i in range(16):
			var t = float(i)/15*PI
			var rib = box(art,"CanopyRib",Vector3(-1.7+5.8*cos(t),5.3+2.3*sin(t),z),Vector3(1.2,0.12,0.14),navy,false)
			rib.rotation.z = atan2(-2.3*cos(t),5.8*sin(t))
			var glass = box(art,"CanopyGlass",rib.position+Vector3(0,0.09,0),Vector3(1.16,0.045,3.85),Color("637f9b"),false)
			glass.rotation.z = rib.rotation.z
	for x in [-7.5,-4.0,-1.7,1.0,4.1]: box(art,"RoofLongitudinal",Vector3(x,6.7 if abs(x+1.7)<3 else 5.4,1),Vector3(0.09,0.09,23),brass,false)
	box(art,"StationWall",Vector3(-9,2.7,0),Vector3(0.35,5.4,24),Color("586378"),true)
	for z in range(-11,12,2):
		box(art,"WallPanel",Vector3(-8.79,2,z),Vector3(0.05,3.1,1.8),Color("687588"),false)
		box(art,"WallSill",Vector3(-8.7,0.7,z),Vector3(0.12,0.12,1.8),brass,false)
	for z in [-7.0,1.0,7.0]:
		for y in [0.5,0.65,0.8]: box(art,"BenchSlat",Vector3(-6.7,y,z),Vector3(0.65,0.12,2.5),Color("9c7054"),true)
		for zz in [-0.85,0.85]: box(art,"BenchLeg",Vector3(-6.7,0.3,z+zz),Vector3(0.55,0.6,0.1),navy)
		box(art,"BenchBack",Vector3(-7.05,1.1,z),Vector3(0.1,0.65,2.5),Color("9c7054"),false)
	for z in [-9.0,-3.0,5.0,10.0]:
		rounded(art,"Planter",Vector3(-7.6,0.4,z),0.34,0.24,0.8,Color("a56e54"))
		for i in range(7):
			var leaf = orb(art,Vector3(-7.6+sin(i*2.4)*0.25,1.0+0.15*(i%3),z+cos(i*2.4)*0.25),0.25,Color("59847a"))
			leaf.scale = Vector3(0.45,1.8,0.7)
	for z in [-8.0,-1.0,6.0]:
		box(art,"LampStem",Vector3(-2,5.7,z),Vector3(0.05,1.3,0.05),brass,false)
		orb(art,Vector3(-2,5.0,z),0.22,AMBER)
		var lamp = OmniLight3D.new()
		lamp.position = Vector3(-2,4.8,z)
		lamp.light_color = AMBER
		lamp.light_energy = 4.5
		lamp.omni_range = 9
		lamp.shadow_enabled = z == -1.0
		art.add_child(lamp)
	box(art,"Board",Vector3(-1,4.0,-8),Vector3(6.5,1.0,0.18),navy,false)
	for y in [3.52,4.48]: box(art,"BoardTrim",Vector3(-1,y,-7.88),Vector3(6.5,0.04,0.03),brass,false)
	label(art,"WHERE DO YOU WANT TO GO?",Vector3(-1,4,-7.83),35)
	art.get_child(art.get_child_count()-1).billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label(art,"PLATFORM 6",Vector3(-6,2.8,-10),35)
	var umbrella = rounded(art,"YellowUmbrella",Vector3(-6.2,1.4,2),0.04,0.65,0.25,Color("f4cc60"))
	umbrella.rotation.z = -0.3
	box(art,"UmbrellaHandle",Vector3(-6.2,0.8,2),Vector3(0.045,1.1,0.045),brass,false)
	for i in range(14):
		var z = -19.0-i%3*3
		var x = -16.0+i*2.5
		box(art,"DistantBuilding",Vector3(x,2+i%4,z),Vector3(2,4+i%4,3),Color("34475f"),false)
		for y in range(1,5): box(art,"DistantWindow",Vector3(x,y*1.15,z+1.51),Vector3(0.4,0.6,0.02),AMBER,false)
func build_apartment_props(world: Node3D) -> Node3D:
	# Both visits use these ordinary objects. Chapter Seven never swaps in a
	# reward-room version of the apartment or changes its original floorplan.
	var props = Node3D.new()
	props.name = "ApartmentProps"
	world.add_child(props)
	var mug = Node3D.new()
	mug.name = "Mug"
	mug.position = Vector3(3.2,1.405,-2.7)
	props.add_child(mug)
	rounded(mug,"CeramicBody",Vector3(0,0.14,0),0.145,0.13,0.28,Color("8cabb4"))
	rounded(mug,"EmptyMouth",Vector3(0,0.282,0),0.122,0.122,0.006,Color("354352"))
	var tea = rounded(mug,"Tea",Vector3(0,0.286,0),0.12,0.12,0.007,Color("68543d"))
	tea.hide()
	var handle = orb(mug,Vector3(0.168,0.14,0),0.105,Color("8cabb4"))
	handle.name = "MugHandle"
	handle.scale = Vector3(0.68,1,0.32)
	box(mug,"SmallRimChip",Vector3(-0.073,0.282,0.11),Vector3(0.026,0.014,0.013),CREAM,false)
	var kettle = Node3D.new()
	kettle.name = "Kettle"
	kettle.position = Vector3(4.8,1.405,-3.22)
	props.add_child(kettle)
	rounded(kettle,"EnamelBody",Vector3(0,0.23,0),0.22,0.27,0.43,Color("8a919c"))
	rounded(kettle,"Lid",Vector3(0,0.459,0),0.225,0.225,0.035,Color("616c80"))
	box(kettle,"LidKnob",Vector3(0,0.505,0),Vector3(0.08,0.06,0.07),Color("3e4959"),false)
	var spout = rounded(kettle,"Spout",Vector3(-0.28,0.25,0),0.07,0.095,0.31,Color("8a919c"))
	spout.rotation.z = -0.95
	box(kettle,"HandleLeft",Vector3(0.24,0.35,-0.11),Vector3(0.045,0.32,0.04),Color("3e4959"),false)
	box(kettle,"HandleRight",Vector3(0.24,0.35,0.11),Vector3(0.045,0.32,0.04),Color("3e4959"),false)
	box(kettle,"HandleGrip",Vector3(0.24,0.52,0),Vector3(0.048,0.045,0.26),Color("3e4959"),false)
	var crossword = Node3D.new()
	crossword.name = "Crossword"
	crossword.position = Vector3(3.68,1.413,-3.23)
	crossword.rotation.y = -0.1
	props.add_child(crossword)
	box(crossword,"FoldedPaper",Vector3.ZERO,Vector3(0.75,0.012,0.73),Color("d9d0b8"),false)
	for line in range(8):
		box(crossword,"GridHorizontal",Vector3(-0.105,0.01,-0.30+line*0.063),Vector3(0.442,0.002,0.005),Color("6e7180"),false)
		box(crossword,"GridVertical",Vector3(-0.326+line*0.063,0.01,-0.079),Vector3(0.005,0.002,0.442),Color("6e7180"),false)
	for cell in [Vector2i(0,0),Vector2i(3,0),Vector2i(6,1),Vector2i(1,2),Vector2i(4,2),Vector2i(2,4),Vector2i(5,5),Vector2i(0,6)]:
		box(crossword,"BlackSquare",Vector3(-0.294+cell.x*0.063,0.012,-0.268+cell.y*0.063),Vector3(0.058,0.002,0.058),Color("4d5364"),false)
	for line in range(9): box(crossword,"UnfinishedClue",Vector3(0.232,0.011,-0.26+line*0.056),Vector3(0.19 if line%3 else 0.12,0.002,0.007),Color("6e7180"),false)
	var pencil = box(crossword,"Pencil",Vector3(-0.08,0.027,0.253),Vector3(0.39,0.014,0.014),Color("bc925f"),false)
	pencil.rotation.y = -0.17
	var chair = Node3D.new()
	chair.name = "Chair"
	chair.position = Vector3(-6.35,0,-8.65)
	# Back slats stay behind the seated protagonist, who faces the window (-Z).
	chair.rotation.y = 0.0
	chair.set_meta("collision_free_seating",true)
	props.add_child(chair)
	box(chair,"WornSeat",Vector3(0,0.48,0),Vector3(0.78,0.09,0.77),Color("8b7160"),false)
	for x in [-0.3,0.3]:
		for z in [-0.3,0.3]: box(chair,"ChairLeg",Vector3(x,0.25,z),Vector3(0.065,0.45,0.065),Color("746a69"),false)
		box(chair,"BackUpright",Vector3(x,0.92,0.3),Vector3(0.065,0.92,0.065),Color("746a69"),false)
	for y in [0.91,1.23]: box(chair,"BackSlat",Vector3(0,y,0.3),Vector3(0.65,0.12,0.06),Color("8b7160"),false)
	var drawer = Node3D.new()
	drawer.name = "Drawer"
	drawer.position = Vector3(4.0,1.06,-2.17)
	props.add_child(drawer)
	box(drawer,"Front",Vector3.ZERO,Vector3(0.92,0.3,0.04),Color("916b4a"),false)
	box(drawer,"Pull",Vector3(0,0,0.036),Vector3(0.20,0.035,0.035),Color("b7a380"),false)
	var tray = Node3D.new()
	tray.name = "Tray"
	drawer.add_child(tray)
	box(tray,"DrawerBottom",Vector3(0,0.08,-0.22),Vector3(0.87,0.022,0.43),Color("7e604d"),false)
	for x in [-0.43,0.43]: box(tray,"DrawerSide",Vector3(x,0.13,-0.22),Vector3(0.02,0.1,0.43),Color("7e604d"),false)
	tray.hide()
	var coat = Node3D.new()
	coat.name = "Coat"
	coat.position = Vector3(6.6,0,-7.72)
	props.add_child(coat)
	box(coat,"WallHook",Vector3(0,2.14,-0.04),Vector3(0.08,0.08,0.17),Color("b7a380"),false)
	box(coat,"WoolBody",Vector3(0,1.55,0.025),Vector3(0.72,1.1,0.17),Color("667588"),false)
	for side in [-1.0,1.0]:
		var sleeve = box(coat,"Sleeve",Vector3(side*0.45,1.68,0.017),Vector3(0.23,0.78,0.15),Color("667588"),false)
		sleeve.rotation.z = side*0.25
	box(coat,"Pocket",Vector3(0.18,1.34,0.119),Vector3(0.22,0.25,0.026),Color("5c6b7e"),false)
	var shoes = Node3D.new()
	shoes.name = "Shoes"
	shoes.position = Vector3(1.85,0,-7.91)
	shoes.rotation.y = -0.22
	props.add_child(shoes)
	for x in [-0.18,0.18]:
		var shoe = orb(shoes,Vector3(x,0.088,0),0.21,Color("51464c"))
		shoe.name = "LeftShoe" if x < 0 else "RightShoe"
		shoe.scale = Vector3(0.62,0.41,1.45)
		for z in [-0.05,0.01,0.07]: box(shoes,"Lace",Vector3(x,0.168,z),Vector3(0.12,0.009,0.013),Color("9c9292"),false)
	return props

func build(checkpoint: String) -> Node3D:
	var world = Node3D.new()
	world.name = "World"
	var spawn = Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = Vector3(0,0.1,5)
	world.add_child(spawn)
	box(world,"Floor",Vector3(0,-0.3,0),Vector3(22,0.6,24),BLUE)
	for x in [-11.0,11.0]: box(world,"Boundary",Vector3(x,0.45,0),Vector3(0.4,0.9,24),BLUE)
	for z in [-12.0,12.0]: box(world,"Boundary",Vector3(0,0.45,z),Vector3(22,0.9,0.4),BLUE)
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("101f3a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("97accf")
	env.ambient_light_energy = 0.65
	environment.environment = env
	world.add_child(environment)
	var moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-40,-35,0)
	moon.light_color = Color("b4c9e9")
	moon.light_energy = 0.75
	world.add_child(moon)
	for x in [-7.0,7.0]:
		var light = OmniLight3D.new()
		light.position = Vector3(x,3,-3)
		light.light_color = AMBER
		light.light_energy = 3
		light.omni_range = 12
		world.add_child(light)
		box(world,"Lantern",Vector3(x,3,-3),Vector3(0.3,0.5,0.3),AMBER,false)
	if checkpoint in ["apartment","roof"]:
		var rain = CPUParticles3D.new()
		rain.name = "Rain"
		rain.amount = 180
		rain.lifetime = 2.0
		rain.preprocess = 2.0
		rain.position = Vector3(0,7,-4)
		rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		rain.emission_box_extents = Vector3(10,1,10)
		if checkpoint == "apartment":
			rain.position.z = -12
			rain.emission_box_extents = Vector3(8,1,0.3)
		rain.direction = Vector3(0,-1,0)
		rain.initial_velocity_min = 4
		rain.initial_velocity_max = 6
		rain.gravity = Vector3(0,-2,0)
		rain.color = Color(0.6,0.75,0.9,0.22)
		var drop = BoxMesh.new()
		drop.size = Vector3(0.008,0.16,0.008)
		rain.mesh = drop
		world.add_child(rain)
	if checkpoint == "apartment":
		for x in [-9.0,9.0]: box(world,"Apartment wall",Vector3(x,2,0),Vector3(0.2,4,22),Color("546174"))
		box(world,"Ceiling",Vector3(0,4.2,0),Vector3(18,0.2,22),Color("546174"))
		box(world,"Window wall",Vector3(0,2,-11),Vector3(18,4,0.2),Color("546174"))
		box(world,"Rain window",Vector3(-5,2.5,-10.85),Vector3(4,2,0.05),Color("345a77"),false)
		for x in [-7.0,-5.0,-3.0]: box(world,"Window frame",Vector3(x,2.5,-10.75),Vector3(0.08,2.2,0.08),CREAM,false)
		box(world,"Rug",Vector3(-4,0.025,1),Vector3(5,0.04,7),Color("737d90"),false)

		box(world,"Bed",Vector3(-4,0.6,-2),Vector3(3,0.6,5),Color("897a89"))
		box(world,"Pillow",Vector3(-4,1,-3.5),Vector3(2,0.25,0.8),CREAM,false)
		box(world,"Table",Vector3(4,0.7,-3),Vector3(3,1.4,1.6),Color("a37c56"))
		box(world,"Door",Vector3(0,1.7,-9),Vector3(2.2,3.4,0.2),AMBER)
		build_apartment_props(world)
		load("res://world/apartment_presentation.gd").new().apply(world,self)
		label(world,"3:17\nThe rain has softened the city",Vector3(0,3,-5))
		world.get_child(world.get_child_count()-1).visibility_range_begin = 8.0
		target(world,Vector3(0,0,-7),"Go up to the roof","leave_apartment")
		world.get_child(world.get_child_count()-1).visibility_range_begin = 8.0
	elif checkpoint == "roof":
		person(world,Vector3(0,0,-4),Color("a2b7ac"))
		var umbrella = MeshInstance3D.new()
		var canopy = CylinderMesh.new()
		canopy.top_radius = 0.06
		canopy.bottom_radius = 1.5
		canopy.height = 0.5
		umbrella.name = "UmbrellaCanopy"
		umbrella.mesh = canopy
		umbrella.position = Vector3(0,2.5,-4)
		var yellow = StandardMaterial3D.new()
		yellow.albedo_color = Color("f3ce58")
		umbrella.material_override = yellow
		world.add_child(umbrella)
		box(world,"Umbrella stem",Vector3(0,1.9,-4),Vector3(0.05,1.1,0.05),CREAM,false)
		for i in range(16): box(world,"City",Vector3(-14+i*2,2+i%4,-18),Vector3(1.4,4+i%4,2),BLUE,false)
		label(world,"A roof above the rain",Vector3(0,4,-7))
		target(world,Vector3(0,0,-3),"Stranger · yellow umbrella","meet_stranger")
	elif checkpoint in ["platform","conductor"]:
		env.ambient_light_energy = 0.24
		env.ambient_light_color = Color("7183a7")
		moon.light_energy = 0.25
		moon.shadow_enabled = false
		station_art(world)
		if ProjectSettings.get_setting("station/painterly_enabled", true):
			load("res://world/station_presentation.gd").new().apply(world, self)
		if checkpoint == "platform": target(world,Vector3(0,0,-6),"A blank ticket · read the board","read_board")
		else:
			person(world,Vector3(2,0,-4),Color("728775"))
			target(world,Vector3(2,0,-3),"Conductor · board the train","board_train")
	elif checkpoint in ["passenger","shoreline","return_train","breakfast","complete"]:
		box(world,"Carriage floor",Vector3(0,-0.07,0),Vector3(8,0.2,22),Color("805d49"))
		for x in [-4.0,4.0]:
			box(world,"Carriage side",Vector3(x,1.2,0),Vector3(0.2,2.4,22),Color("72918d"))
			for z in [-7,-3,1,5,9]:
				box(world,"Seat",Vector3(x*0.7,0.5,z),Vector3(1.6,1,1.5),Color("ab876d"))
				box(world,"Window",Vector3(x,2.8,z),Vector3(0.15,1.4,2.8),Color("234b72"),false)
		for x in [-2.6,2.6]:
			var lamp = OmniLight3D.new()
			lamp.position = Vector3(x,2.6,-4)
			lamp.light_color = AMBER
			lamp.light_energy = 3
			lamp.omni_range = 10
			world.add_child(lamp)
		production_character(world,Vector3(1.8,0,-4),"mira")
		var titles = {"passenger":"The first passenger","shoreline":"The sea is waiting","return_train":"The carriage smells of toast","breakfast":"Breakfast at night","complete":"STILL HERE\nA journey to keep"}
		label(world,titles[checkpoint],Vector3(0,3.5,-7))
		if checkpoint == "passenger":
			target(world,Vector3(1,0,-3),"Mira · unopened camera","meet_passenger")
			target(world,Vector3(-2.2,0,1),"Window seat · a paper boat","dialogue","train_window")
			var paper_boat = box(world,"PaperBoat",Vector3(-3.3,1.55,1),Vector3(0.45,0.08,0.25),CREAM,false)
			paper_boat.rotation.z = -0.12
			var sail = box(world,"PaperSail",Vector3(-3.3,1.7,1),Vector3(0.035,0.3,0.28),CREAM,false)
			sail.rotation.x = -0.3
		elif checkpoint == "shoreline": target(world,Vector3(0,0,-8),"Step onto the moonlit shore","arrive_shore")
		elif checkpoint == "return_train": target(world,Vector3(1,0,-3),"Sit down for breakfast","return_train")
		elif checkpoint == "breakfast": target(world,Vector3(1,0,-3),"Share breakfast","have_breakfast")
		else: target(world,Vector3(1,0,-3),"Keep this journey","finish")
		if checkpoint in ["return_train","breakfast","complete"]:
			box(world,"Breakfast table",Vector3(0,0.7,-4),Vector3(2.2,0.15,1.2),CREAM)
			orb(world,Vector3(0.5,0.9,-4),0.18,AMBER)
			box(world,"FairPostcard",Vector3(-0.45,0.79,-4),Vector3(0.5,0.015,0.32),Color("d5b88c"),false)
			label(world,"THE UNFINISHED FAIR",Vector3(-0.4,1.5,-4.2),16)
			var steam = CPUParticles3D.new()
			steam.name = "Steam"
			steam.position = Vector3(0.5,1.02,-4)
			steam.amount = 12
			steam.lifetime = 2.0
			steam.preprocess = 2.0
			steam.direction = Vector3.UP
			steam.gravity = Vector3.ZERO
			steam.initial_velocity_min = 0.18
			steam.initial_velocity_max = 0.3
			steam.spread = 16.0
			steam.scale_amount_min = 0.4
			steam.scale_amount_max = 0.8
			steam.color = Color(0.9,0.94,1.0,0.12)
			var puff = SphereMesh.new()
			puff.radius = 0.055
			puff.height = 0.11
			steam.mesh = puff
			world.add_child(steam)
	else:
		var water = box(world,"Water",Vector3(0,-0.5,-22),Vector3(90,0.12,42),Color("426d89"),false)
		var shader = Shader.new()
		shader.code = "shader_type spatial; render_mode unshaded; uniform float motion_scale = 1.0; varying vec3 world_pos; void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float wave=sin(world_pos.z*2.5+TIME*0.7*motion_scale+sin(world_pos.x*0.4))*0.5+0.5; float path=exp(-pow((world_pos.x-7.0)/4.0,2.0)); ALBEDO=mix(vec3(0.08,0.19,0.3),vec3(0.36,0.57,0.68),wave*0.22+path*wave*0.55);}"
		var sea_material = ShaderMaterial.new()
		sea_material.shader = shader
		water.get_child(0).material_override = sea_material
		orb(world,Vector3(11,12,-28),2,Color("f3e6b8"))
		box(world,"Lighthouse",Vector3(-8,3,-13),Vector3(1.2,6,1.2),CREAM,false)
		orb(world,Vector3(-8,6.5,-13),0.45,AMBER)
		for x in [-2.0,2.0]: box(world,"Arch pillar",Vector3(x,2,-15),Vector3(1,4,1),Color("7997ab"),false)
		box(world,"Arch span",Vector3(0,4,-15),Vector3(5,0.8,1),Color("7997ab"),false)
		for i in range(5): orb(world,Vector3(5+i*0.7,7+sin(i),-18),0.12,CREAM)
		label(world,"The moonlit overlook",Vector3(0,4,-7))
		if checkpoint == "overlook":
			production_character(world,Vector3(3.0,0,-5),"mira")
			target(world,Vector3(-6,0,-4),"Lighthouse · one tall line","inspect_landmark","lighthouse")
			target(world,Vector3(0,0,-7),"Arch · a doorway","inspect_landmark","arch")
			target(world,Vector3(6,0,-4),"Constellation · a rising trail","inspect_landmark","constellation")
			target(world,Vector3(0,0,-1),"Viewing marker · align or use assist","puzzle")
		elif checkpoint == "camera_choice":
			production_character(world,Vector3(1,0,-3),"mira")
			target(world,Vector3(1,0,-2),"Passenger · a moment together","camera")
		else: target(world,Vector3(0,0,-2),"A small invitation · optional","optional")
	if ProjectSettings.get_setting("opening/presentation_enabled",true):
		if checkpoint in ["passenger","shoreline","return_train","breakfast","complete"]:
			load("res://world/transit_presentation.gd").new().apply_carriage(world,self)
		elif checkpoint in ["overlook","camera_choice","optional_action"]:
			load("res://world/transit_presentation.gd").new().apply_shore(world,self)
	if ProjectSettings.get_setting("opening/readability_enabled",true):
		for source_label in world.get_children():
			if source_label is Label3D: source_label.hide()
	if ProjectSettings.get_setting("opening/depth_enabled",true):
		load("res://world/opening_depth.gd").new().apply(world,self,checkpoint)
	var motion = load("res://world/ambient_motion.gd").new()
	motion.name = "AmbientMotion"
	world.add_child(motion)
	return world
