extends Node3D
# Chapter state is durable before a performance begins. This scene only stages it.
signal preparation_finished
signal departure_finished
signal cinematic_phase_changed(phase: String)
const NAVY = Color("293d4c")
const BRASS = Color("b89867")
const STONE = Color("83908f")
const WOOD = Color("946e52")
const CREAM = Color("e5d5b0")
const MIRA_START = Vector3(1.8,0,-4)
const TOOL_REST = Vector3(2.1,0.25,-4.4)
const PREPARATION_DURATION := 5.8
const REPLY_DURATION := 1.4
const ARRIVAL_DURATION := 4.4
const DOOR_DURATION := 1.6
const BOARD_DURATION := 3.3
const TURN_DURATION := 2.5
const CATCH_DURATION := 2.8
const CLOSE_DURATION := 1.6
const LEAVE_DURATION := 6.0
const HOLD_DURATION := 4.2
var factory: RefCounted
var paint: RefCounted
var snapshot: Dictionary = {}
var interactions: Node3D
var mira: Node3D
var paused := false
var reduced_motion := false
var preparation_active := false
var departure_active := false
var preparation_elapsed := 0.0
var departure_elapsed := 0.0
var cinematic_phase := "arrival"
var camera_choice := "unused"
var farewell := "unselected"
var door_open := 0.0
var air_shift := 0.0
var camera_slip := 0.0
var camera_caught := false
var laughing := false
var tool_carried := false
var _camera_prop: Node3D
var _camera_rest := Transform3D.IDENTITY
var _hair_wisp: Node3D
var _coat_hem: Node3D
var _strap: Node3D
var _mira_train_offset := Vector3.ZERO
var _actor_ready := false
var _settled := false

func build(value: Dictionary) -> Node3D:
	name = "World"
	factory = load("res://world/world_factory.gd").new()
	paint = load("res://world/station_presentation.gd").new()
	_build_station()
	_build_train()
	_build_people_and_props()
	interactions = _node(self,"Interactions")
	var ambient = load("res://world/ambient_motion.gd").new()
	ambient.name = "AmbientMotion"
	add_child(ambient)
	_marker("Spawn",Vector3(-0.7,0.12,4.5),Vector3(1.8,1.2,-4))
	_marker("ReturnCamera",Vector3(-1.6,2.0,2.2),Vector3(1.8,1.15,-4),47.0)
	apply_snapshot(value)
	return self

func _ready():
	mira.set_process(false)
	for id in ["UpperArmLeft","UpperArmRight","ForearmLeft","ForearmRight","HandLeft","HandRight","ShoulderLeft","ShoulderRight"]:
		mira.bones[id] = mira._bone_index(id)
	_actor_ready = mira.skeleton != null
	_camera_prop = mira.get_attached_prop("camera")
	if is_instance_valid(_camera_prop): _camera_rest = _camera_prop.transform
	# Small original silhouette extensions make the gust legible without moving the camera.
	_hair_wisp = factory.box(mira.head_socket,"LooseHair",Vector3(0.15,-0.04,-0.02),Vector3(0.035,0.15,0.025),Color(0.2348,0.2294,0.2784),false)
	_coat_hem = _node(mira,"CoatHem",Vector3(0,0.72,-0.13))
	for x in [-0.16,0.16]:
		var hem = factory.box(_coat_hem,"CoatTail",Vector3(x,-0.065,0),Vector3(0.20,0.16,0.025),Color(0.722,0.4673,0.3656),false)
		hem.rotation.z = x * 0.18
	_strap = factory.box(mira,"ToolStrap",Vector3(-0.14,1.02,0.15),Vector3(0.035,0.57,0.025),Color("735640"),false)
	_strap.rotation.z = -0.36
	_apply_camera_ownership()
	_pose_actor(0.0,1.0 if tool_carried else 0.0,0.0,0.0)
	if tool_carried: _update_carried_tool()
	if _settled: mira.hide()

func _node(parent: Node3D, id: String, where := Vector3.ZERO) -> Node3D:
	var item = Node3D.new()
	item.name = id
	item.position = where
	parent.add_child(item)
	return item

func _marker(id: String, where: Vector3, target: Vector3, fov := 48.0):
	var item = Marker3D.new()
	item.name = id
	item.position = where
	item.set_meta("look_at",target)
	item.set_meta("fov",fov)
	add_child(item)

func _box(parent: Node3D, id: String, where: Vector3, size_: Vector3, color_: Color, collide := false, cell := -1) -> Node3D:
	var item = factory.box(parent,id,where,size_,color_,collide)
	if cell >= 0:
		var mesh = item.get_child(0)
		mesh.mesh = paint.normalize_box_uv(mesh.mesh)
		mesh.material_override = paint.material(color_,cell,0.35)
	return item

func _label(parent: Node3D, id: String, text_: String, where: Vector3, font_size := 28, yaw := 0.0) -> Label3D:
	factory.label(parent,text_,where,font_size)
	var item = parent.get_child(parent.get_child_count()-1) as Label3D
	item.name = id
	item.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	item.pixel_size = 0.006
	item.rotation.y = yaw
	item.modulate = CREAM
	item.set_meta("cinematic_visible",true)
	return item

func _build_station():
	_box(self,"PlatformFloor",Vector3(-2.4,-0.3,0),Vector3(14.0,0.6,42.0),STONE,true)
	var art = _node(self,"StationArt")
	# Tessellated stone keeps the familiar station's material, with a new quiet framing.
	for tone in range(3):
		var batch = MultiMeshInstance3D.new()
		batch.name = "ReturnTiles%d" % tone
		var tiles = MultiMesh.new()
		tiles.transform_format = MultiMesh.TRANSFORM_3D
		tiles.mesh = paint.normalize_box_uv(factory.shared_box_mesh(Vector3(0.977,0.025,0.977)))
		var transforms: Array[Transform3D] = []
		for x in range(-9,4):
			for z in range(-18,19):
				if posmod(x+z,3) == tone: transforms.append(Transform3D(Basis.IDENTITY,Vector3(x+0.5,0.019,z+0.5)))
		tiles.instance_count = transforms.size()
		for index in range(transforms.size()): tiles.set_instance_transform(index,transforms[index])
		batch.multimesh = tiles
		batch.material_override = paint.material(STONE.lightened(tone*0.035),0,0.45)
		art.add_child(batch)
	_box(art,"SafetyLine",Vector3(4.03,0.052,0),Vector3(0.13,0.012,39),Color("d4b97f"))
	_box(self,"PlatformEdge",Vector3(4.6,-0.22,0),Vector3(0.4,0.6,42),Color("697873"),true,2)
	# Player rail is low and visually belongs to the edge; Mira's staging is independent.
	_box(self,"TrackSafety",Vector3(4.56,0.25,0),Vector3(0.12,0.5,42),Color("546463"),true)
	for x in [-9.35,4.56]: _box(self,"Boundary",Vector3(x,0.5,0),Vector3(0.12,1.0,42),NAVY,true)
	for z in [-20.6,20.6]: _box(self,"Boundary",Vector3(-2.4,0.6,z),Vector3(14,1.2,0.18),NAVY,true)
	_box(self,"RailBed",Vector3(7,-0.33,0),Vector3(4.4,0.12,130),Color("405150"))
	for x in [6.1,7.9]: _box(self,"Rail",Vector3(x,-0.22,0),Vector3(0.08,0.1,130),Color("a3aaa4"))
	for z in range(-60,61): _box(art,"Sleeper",Vector3(7,-0.25,z*1.06),Vector3(2.8,0.07,0.2),Color("59645b"))
	_box(art,"StationWall",Vector3(-9.1,2.7,0),Vector3(0.32,5.4,42),Color("6f7a7c"),true,2)
	for z in [-15.0,-9.0,-3.0,3.0,9.0,15.0]:
		_box(art,"WallPanel",Vector3(-8.91,2.1,z),Vector3(0.035,3.3,4.8),Color("7e8888"),false,2)
		_box(art,"WallSill",Vector3(-8.85,0.6,z),Vector3(0.1,0.12,4.8),BRASS)
		for x in [-7.9,3.8]:
			factory.rounded(art,"CanopyColumn",Vector3(x,2.68,z),0.1,0.14,5.35,NAVY,true)
			factory.rounded(art,"ColumnFoot",Vector3(x,0.18,z),0.25,0.25,0.36,BRASS,true)
		for i in range(14):
			var angle = float(i)/13.0 * PI
			var rib = _box(art,"CanopyRib",Vector3(-2.05+5.85*cos(angle),5.3+1.75*sin(angle),z),Vector3(1.43,0.1,0.14),NAVY,false,3)
			rib.rotation.z = atan2(-1.75*cos(angle),5.85*sin(angle))
	var roof = _node(self,"Roof")
	for x in [-7.8,-5.5,-3.2,-0.9,1.4,3.7]:
		_box(roof,"RoofBeam",Vector3(x,5.5+1.45*sin((x+7.8)/11.5*PI),0),Vector3(0.08,0.09,33),BRASS)
	# The far half retains blue glass. Near the camera, open ribs give clear silhouettes.
	for z in [-15.0,-9.0]:
		for x in [-6.5,-3.5,-0.5,2.5]:
			var glass = _box(roof,"CanopyGlass",Vector3(x,6.12+0.6*sin((x+7.8)/11.5*PI),z),Vector3(2.94,0.035,5.7),Color("829693"),false,4)
			glass.rotation.z = (x+2.0)*-0.055
	for z in [-10.0,0.0,10.0]:
		_box(art,"LampCable",Vector3(-2.05,5.5,z),Vector3(0.03,1.4,0.03),BRASS)
		var lamp = factory.orb(art,Vector3(-2.05,4.7,z),0.18,Color("eebf79"))
		lamp.name = "PlatformLamp"
		var light = OmniLight3D.new()
		light.name = "WarmLamp"
		light.position = Vector3(-2.05,4.5,z)
		light.light_color = Color("ffd2a2")
		light.light_energy = 2.2
		light.omni_range = 10
		art.add_child(light)
	var bench = _node(self,"StationBench",Vector3(-6.6,0,-4.8))
	for y in [0.44,0.56]: _box(bench,"SeatSlat",Vector3(0,y,0),Vector3(0.7,0.1,2.65),WOOD,true,1)
	_box(bench,"Back",Vector3(-0.32,1.04,0),Vector3(0.1,0.55,2.65),WOOD,false,1)
	for z in [-0.93,0.93]: _box(bench,"Leg",Vector3(0,0.22,z),Vector3(0.55,0.44,0.1),NAVY,true)
	var indicator = _node(self,"Indicator",Vector3(0,3.75,-8.8))
	_box(indicator,"Enamel",Vector3.ZERO,Vector3(4.7,1.12,0.16),NAVY,false,3)
	for y in [-0.52,0.52]: _box(indicator,"BrassBorder",Vector3(0,y,0.1),Vector3(4.62,0.035,0.025),BRASS)
	_label(indicator,"Line","LOCAL SERVICE",Vector3(0,0.31,0.12),19)
	_label(indicator,"Destination","PLEASE WAIT",Vector3(0,-0.02,0.12),37)
	_label(indicator,"Status","PLATFORM 6",Vector3(0,-0.34,0.12),20)
	_label(art,"PlatformSix","6",Vector3(3.78,3.3,-8.8),53)
	_box(art,"PlatformNumber",Vector3(3.78,3.3,-8.9),Vector3(0.85,0.96,0.14),NAVY)
	var clock = _node(self,"PlatformClock",Vector3(-5.4,3.9,-8.8))
	var rim = factory.rounded(clock,"Rim",Vector3.ZERO,0.49,0.49,0.1,BRASS)
	rim.rotation.x = PI/2
	var face = factory.rounded(clock,"Face",Vector3(0,0,0.065),0.44,0.44,0.03,CREAM)
	face.rotation.x = PI/2
	_box(clock,"Minute",Vector3(0,0.14,0.09),Vector3(0.026,0.31,0.02),NAVY)
	var hour = _box(clock,"Hour",Vector3(-0.1,-0.01,0.09),Vector3(0.22,0.028,0.02),NAVY)
	hour.rotation.z = 0.22
	for index in range(12):
		var angle = index*TAU/12.0
		var tick = _box(clock,"Tick",Vector3(sin(angle)*0.36,cos(angle)*0.36,0.09),Vector3(0.023,0.045,0.012),NAVY)
		tick.rotation.z = -angle
	for i in range(8):
		_box(art,"DistantFacade",Vector3(-17.0+i*4.7,2.4+(i%3),-37.0-(i%2)*2),Vector3(3.4,5.0+(i%3)*2,4.0),Color("596c70"),false,5)
	for z in [-13.0,8.5]:
		factory.rounded(art,"Planter",Vector3(-7.6,0.32,z),0.28,0.23,0.64,Color("8c735c"))
		for i in range(6):
			var leaf = factory.orb(art,Vector3(-7.6+sin(i*2.4)*0.18,0.94+i%2*0.18,z+cos(i*2.4)*0.18),0.19,Color("778a74"))
			leaf.scale = Vector3(0.6,1.6,0.5)
	_label(art,"ExitSign","STATION HALL",Vector3(-6.4,2.45,12.4),21)
	_box(art,"HallDoor",Vector3(-6.4,1.6,12.3),Vector3(2.1,3.2,0.12),Color("5f736e"),false,2)
	var environment = WorldEnvironment.new()
	environment.name = "ReturnEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("52696f")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b8c0b4")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color("77898b")
	env.fog_light_energy = 0.4
	env.fog_depth_begin = 20.0
	env.fog_depth_end = 85.0
	environment.environment = env
	add_child(environment)
	var evening = DirectionalLight3D.new()
	evening.name = "LastStationLight"
	evening.rotation_degrees = Vector3(-28,-52,0)
	evening.light_color = Color("f2d5aa")
	evening.light_energy = 0.9
	evening.shadow_enabled = true
	add_child(evening)
	set_meta("return_station",true)
	set_meta("music_allowed",false)

func _build_train():
	var train = _node(self,"Train",Vector3(7,0,-55))
	train.set_meta("original_geometry",true)
	# Split near wall around the doorway: boarding has an actual opening.
	_box(train,"CarriageFloor",Vector3(0,0.13,0),Vector3(3.8,0.2,20),Color("78614c"))
	_box(train,"FarWall",Vector3(1.87,1.8,0),Vector3(0.13,3.3,20),CREAM,false,3)
	_box(train,"NearFrontWall",Vector3(-1.87,1.8,-7.4),Vector3(0.13,3.3,5.2),CREAM,false,3)
	_box(train,"NearRearWall",Vector3(-1.87,1.8,3.4),Vector3(0.13,3.3,13.2),CREAM,false,3)
	for z in [-10.0,10.0]: _box(train,"CarriageEnd",Vector3(0,1.8,z),Vector3(3.8,3.3,0.12),NAVY,false,3)
	var roof = factory.rounded(train,"RoundedRoof",Vector3(0,3.49,0),1.91,1.91,20.15,NAVY)
	roof.rotation.x = PI/2
	roof.scale.z = 0.18
	for z in [-8.3,-6.0,-1.7,0.7,3.1,5.5,7.9]:
		_box(train,"WindowFrame",Vector3(-1.98,2.38,z),Vector3(0.08,1.35,1.75),BRASS)
		_box(train,"Window",Vector3(-2.03,2.38,z),Vector3(0.035,1.17,1.57),Color("eebf79"))
		_box(train,"Mullion",Vector3(-2.06,2.38,z),Vector3(0.045,1.18,0.045),NAVY)
		for offset in [-0.6,0.6]: _box(train,"Curtain",Vector3(-2.06,2.38,z+offset),Vector3(0.04,1.13,0.17),Color("b78769"))
	for z in [-7.4,3.4]:
		var length_ = 5.2 if z < 0 else 13.2
		_box(train,"NavyPanel",Vector3(-1.96,0.85,z),Vector3(0.045,1.15,length_),NAVY,false,3)
		for y in [0.29,1.43,3.25]: _box(train,"Pinstripe",Vector3(-2.0,y,z),Vector3(0.03,0.035,length_),BRASS)
	for z in [-7.0,7.0]:
		_box(train,"Bogie",Vector3(0,-0.01,z),Vector3(2.9,0.25,1.8),Color("283b3c"))
		for x in [-1.32,1.32]:
			var wheel = factory.rounded(train,"Wheel",Vector3(x,-0.05,z),0.35,0.35,0.15,Color("243737"))
			wheel.rotation.z = PI/2
	_box(train,"DoorLintel",Vector3(-1.96,3.18,-4),Vector3(0.18,0.26,1.5),BRASS)
	for z in [-4.78,-3.22]: _box(train,"DoorJamb",Vector3(-1.96,1.7,z),Vector3(0.17,3.0,0.1),BRASS)
	var doors = _node(train,"Doors",Vector3(-2.04,0,-4))
	for pair in [["Left",-0.35],["Right",0.35]]:
		var door = _node(doors,pair[0],Vector3(0,0,pair[1]))
		_box(door,"Panel",Vector3(0,1.69,0),Vector3(0.06,2.93,0.69),NAVY,false,3)
		_box(door,"Glass",Vector3(-0.045,2.27,0),Vector3(0.025,1.16,0.5),Color("eebf79"))
		_box(door,"Handle",Vector3(-0.09,1.44,0.18 if pair[1] < 0 else -0.18),Vector3(0.04,0.24,0.045),BRASS)
	_box(train,"BoardingStep",Vector3(-2.12,0.085,-4),Vector3(0.48,0.13,1.42),Color("adac8e"))
	_box(train,"VestibuleLight",Vector3(-0.8,3.13,-4),Vector3(1.2,0.04,1.1),Color("eebf79"))
	var vestibule = OmniLight3D.new()
	vestibule.name = "VestibuleLamp"
	vestibule.position = Vector3(-0.7,2.5,-4)
	vestibule.light_color = Color("ffd9a5")
	vestibule.light_energy = 1.5
	vestibule.omni_range = 4
	train.add_child(vestibule)
	for z in [-8.0,8.0]:
		_box(train,"BenchSeat",Vector3(0.1,0.52,z),Vector3(2.3,0.18,1.1),Color("af8c66"))
		_box(train,"SeatBack",Vector3(0.1,1.04,z+0.48),Vector3(2.3,0.86,0.12),Color("af8c66"))
	train.hide()

func _build_people_and_props():
	mira = factory.production_character(self,MIRA_START,"mira")
	mira.rotation.y = 0.0
	var tool = _node(self,"ToolRoll",TOOL_REST)
	var roll = factory.rounded(tool,"CanvasRoll",Vector3.ZERO,0.1,0.1,0.48,Color("a78f66"))
	roll.rotation.z = PI/2
	for x in [-0.16,0.16]:
		var binding = factory.rounded(tool,"LeatherBinding",Vector3(x,0,0),0.107,0.107,0.035,Color("68523d"))
		binding.rotation.z = PI/2
	_box(tool,"Loop",Vector3(0,0.11,0),Vector3(0.17,0.04,0.06),Color("68523d"))
	var unused = _node(self,"CameraLeftBehind",Vector3(-6.6,0.64,-5.55))
	unused.hide()
	# This reserved visual never implies a camera was abandoned; protagonist owns take/unused.
	unused.set_meta("reserved_prop",true)
	var conductor = _node(self,"Conductor",Vector3(0.7,0,8.3))
	factory.person(conductor,Vector3.ZERO,Color("627d70"))
	conductor.rotation.y = PI
	var cap = factory.rounded(conductor,"ConductorCap",Vector3(0,1.78,0),0.21,0.22,0.12,NAVY)
	_box(cap,"Brim",Vector3(0,-0.04,0.17),Vector3(0.34,0.04,0.21),NAVY)
	var jo = _node(self,"Jo",Vector3(-5.7,0,10.9))
	factory.person(jo,Vector3.ZERO,Color("aa876b"))
	jo.rotation.y = PI
	jo.set_meta("seated",true)
	jo.get_node("Satchel").hide()
	for id in ["LegLeft","LegRight"]:
		var thigh = jo.get_node(id)
		thigh.rotation.x = -PI/2
		thigh.get_child(1).hide()
	for x in [-0.15,0.15]:
		factory.rounded(jo,"SeatedShin",Vector3(x,0.31,0.38),0.065,0.06,0.46,NAVY)
		factory.orb(jo,Vector3(x,0.11,0.45),0.12,Color("41323a")).scale = Vector3(0.75,0.6,1.35)
	var bench = _node(self,"JoBench",Vector3(-5.7,0,10.95))
	_box(bench,"Seat",Vector3(0,0.51,0.04),Vector3(2.4,0.12,0.75),WOOD,true,1)
	_box(bench,"Back",Vector3(0,1.04,0.38),Vector3(2.4,0.69,0.1),WOOD,false,1)
	for x in [-0.95,0.95]: _box(bench,"Leg",Vector3(x,0.24,0.04),Vector3(0.12,0.48,0.58),NAVY,true)
	var umbrella = _node(jo,"YellowUmbrella",Vector3(0.36,0,0.15))
	var canopy = factory.rounded(umbrella,"Canopy",Vector3(0,2.1,0),0.035,0.69,0.24,Color("e7bf55"))
	canopy.rotation.z = -0.06
	factory.rounded(umbrella,"Stem",Vector3(0,1.12,0),0.019,0.019,1.72,BRASS)
	var grip = factory.rounded(umbrella,"Handle",Vector3(0,0.28,0),0.038,0.038,0.15,WOOD)
	grip.rotation.z = 0.1
	for i in range(8):
		var angle = i*TAU/8.0
		var seam = _box(umbrella,"CanopySeam",Vector3(sin(angle)*0.28,2.02,cos(angle)*0.28),Vector3(0.012,0.016,0.58),Color("c69c40"))
		seam.rotation.y = angle
	var thread = _box(jo,"UmbrellaThread",Vector3(0.32,1.02,0.17),Vector3(0.01,0.38,0.01),CREAM)
	thread.rotation.z = -0.2
	var star = MeshInstance3D.new()
	star.name = "CrookedPaperStar"
	star.position = Vector3(0.32,1.27,0.2)
	star.rotation.z = -0.19
	var mesh = SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(10):
		var angle = i*TAU/10.0
		var next_angle = (i+1)*TAU/10.0
		var radius = 0.11 if i%2 == 0 else 0.045
		var next_radius = 0.11 if (i+1)%2 == 0 else 0.045
		for vertex in [Vector3.ZERO,Vector3(sin(next_angle)*next_radius,cos(next_angle)*next_radius,0),Vector3(sin(angle)*radius,cos(angle)*radius,0)]:
			mesh.set_normal(Vector3.BACK)
			mesh.add_vertex(vertex)
	star.mesh = mesh.commit()
	var paper = factory.shared_material(Color("f1ddb2")).duplicate()
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	star.material_override = paper
	jo.add_child(star)
	var crease = _box(star,"Fold",Vector3(0,0.025,0.006),Vector3(0.008,0.13,0.01),Color("bea67f"))
	crease.rotation.z = 0.12

func _target(id: String, where: Vector3, title: String):
	var item = Marker3D.new()
	item.name = id
	item.position = where
	item.set_meta("action_id",id)
	item.set_meta("label",title)
	item.set_meta("value",null)
	item.add_to_group("interactables")
	interactions.add_child(item)

func _rebuild_interactions():
	for child in interactions.get_children():
		interactions.remove_child(child)
		child.free()
	var checkpoint = str(snapshot.get("return_checkpoint","arrival"))
	if checkpoint in ["locked","arrival"]:
		_target("return_arrival",Vector3(0.2,0,-2.4),"Mira · the next local train")
	elif checkpoint == "farewell":
		_target("return_farewell",Vector3(0.2,0,-2.4),"Mira · say goodbye in your own way")
	else:
		_target("return_conductor",Vector3(0.7,0,6.8),"Conductor · stay a moment")
		_target("return_jo",Vector3(-5.7,0,9.4),"Jo · the station hall")
		_target("return_exit" if checkpoint == "complete" else "return_finish",Vector3(-2.8,0,10.8),"Keep this return" if checkpoint == "complete" else "The station is still here")

func apply_snapshot(value: Dictionary):
	snapshot = value.duplicate(true)
	camera_choice = str(snapshot.get("camera_choice","unused"))
	farewell = str(snapshot.get("return_state",snapshot.get("return",{})).get("farewell","unselected"))
	var checkpoint = str(snapshot.get("return_checkpoint","arrival"))
	_rebuild_interactions()
	set_reduced_motion(bool(snapshot.get("settings",{}).get("reduced_motion",false)))
	if not preparation_active and not departure_active:
		if checkpoint in ["departed","complete"]: _settle_departure()
		else: _restore_waiting(checkpoint == "farewell")
	_apply_camera_ownership()

func apply_state(value: Dictionary): apply_snapshot(value)
func apply_preferences(reduced: bool): set_reduced_motion(reduced)
func cinematic_camera_path() -> NodePath: return NodePath("ReturnCamera")
func cinematic_state() -> Dictionary:
	return {"phase":cinematic_phase,"preparation_active":preparation_active,"departure_active":departure_active,"elapsed":departure_elapsed,"door_open":door_open,"air_shift":air_shift,"camera_with_mira":camera_choice == "lend","camera_slip":camera_slip,"camera_caught":camera_caught,"laughing":laughing,"silence":true,"music_allowed":false,"holding_ambience":cinematic_phase == "ambience_hold"}

func _phase(value: String):
	if cinematic_phase == value: return
	cinematic_phase = value
	set_meta("cinematic_phase",value)
	cinematic_phase_changed.emit(value)

func _camera(where: Vector3, target: Vector3, fov := 47.0):
	var marker = get_node("ReturnCamera")
	marker.position = where
	marker.set_meta("look_at",target)
	marker.set_meta("fov",fov)

func _restore_waiting(prepared: bool):
	_settled = false
	mira.show()
	mira.position = MIRA_START
	mira.rotation = Vector3.ZERO
	get_node("Train").hide()
	get_node("Train").position = Vector3(7,0,-55)
	tool_carried = prepared
	get_node("ToolRoll").show()
	get_node("ToolRoll").position = MIRA_START+Vector3(0.30,0.94,0.35) if prepared else TOOL_REST
	get_node("ToolRoll").rotation = Vector3.ZERO
	door_open = 0.0
	air_shift = 0.0
	camera_slip = 0.0
	camera_caught = false
	laughing = false
	_update_doors()
	get_node("Indicator/Destination").text = "LOWER MILL" if prepared else "PLEASE WAIT"
	get_node("Indicator/Status").text = "LOCAL · APPROACHING" if prepared else "PLATFORM 6"
	_camera(Vector3(-1.6,2.0,2.2),Vector3(1.8,1.15,-4))
	_phase("farewell" if prepared else "arrival")
	_pose_actor(0.0,1.0 if prepared else 0.0,0.0,0.0)
	if prepared and _actor_ready: _update_carried_tool()

func _apply_camera_ownership():
	if is_instance_valid(_camera_prop): _camera_prop.visible = camera_choice == "lend" and mira.visible
	get_node("CameraLeftBehind").hide()

func begin_preparation():
	if preparation_active: return
	if departure_active: return
	_restore_waiting(false)
	preparation_elapsed = 0.0
	preparation_active = true
	get_node("Indicator/Destination").text = "LOWER MILL"
	get_node("Indicator/Status").text = "LOCAL · APPROACHING"
	_phase("notice")
	_camera(Vector3(-0.45,1.9,-0.15),Vector3(1.8,1.35,-4),43.0)
	if reduced_motion and not paused: finish_preparation()

func finish_preparation():
	if not preparation_active: return
	preparation_active = false
	preparation_elapsed = PREPARATION_DURATION
	_restore_waiting(true)
	_camera(Vector3(-0.45,1.9,-0.15),Vector3(1.8,1.35,-4),43.0)
	_pose_actor(0.0,1.0,0.0,0.0)
	preparation_finished.emit()

func begin_departure(selected_farewell: String, selected_camera: String):
	if departure_active: return
	if preparation_active: finish_preparation()
	farewell = selected_farewell
	camera_choice = selected_camera
	_restore_waiting(true)
	departure_elapsed = 0.0
	departure_active = true
	get_node("Train").show()
	get_node("Train").position = Vector3(7,0,-55)
	get_node("Indicator/Status").text = "LOCAL · ARRIVING"
	_apply_camera_ownership()
	_phase("approach")
	_stage_departure()
	if reduced_motion and not paused: finish_departure()

func finish_departure():
	if not departure_active: return
	departure_active = false
	departure_elapsed = departure_duration()
	_settle_departure()
	departure_finished.emit()

func departure_duration() -> float:
	return REPLY_DURATION+ARRIVAL_DURATION+DOOR_DURATION+BOARD_DURATION+TURN_DURATION+(CATCH_DURATION if camera_choice == "lend" else 0.0)+CLOSE_DURATION+LEAVE_DURATION+HOLD_DURATION

func _settle_departure():
	_settled = true
	mira.hide()
	mira.position = Vector3(5.8,0.23,-4)
	get_node("Train").hide()
	get_node("Train").position = Vector3(7,0,58)
	get_node("ToolRoll").hide()
	get_node("Indicator/Destination").text = "LOWER MILL"
	get_node("Indicator/Status").text = "LOCAL · DEPARTED"
	door_open = 0.0
	air_shift = 0.0
	camera_slip = 0.0
	laughing = false
	_update_doors()
	_camera(Vector3(-1.6,2.7,5.2),Vector3(4.3,1.7,-4.0),51.0)
	_phase("settled")
	_apply_camera_ownership()

func set_paused(value: bool):
	paused = value
	if not paused and reduced_motion:
		if preparation_active: finish_preparation()
		if departure_active: finish_departure()

func set_reduced_motion(value: bool):
	reduced_motion = value
	if _actor_ready and not paused: mira.apply_preferences(value)
	if value and not paused:
		if preparation_active: finish_preparation()
		if departure_active: finish_departure()

func _process(delta: float):
	if paused: return
	if preparation_active:
		if reduced_motion: finish_preparation(); return
		preparation_elapsed += maxf(delta,0.0)
		if preparation_elapsed >= PREPARATION_DURATION: finish_preparation()
		else: _stage_preparation(delta)
	elif departure_active:
		if reduced_motion: finish_departure(); return
		departure_elapsed += maxf(delta,0.0)
		if departure_elapsed >= departure_duration(): finish_departure()
		else: _stage_departure(delta)
	elif _actor_ready and mira.visible:
		_pose_actor(delta,1.0 if tool_carried else 0.0,0.0,0.0)

func _stage_preparation(delta: float):
	var time = preparation_elapsed
	var lift := 0.0
	var adjust := 0.0
	var notice := 0.0
	if time < 1.5:
		_phase("notice")
		notice = sin(clampf(time/1.5,0.0,1.0)*PI)
	elif time < 3.5:
		_phase("lift_tool_roll")
		lift = smoothstep(0.0,1.0,(time-1.5)/2.0)
		tool_carried = time >= 1.8
	elif time < 4.9:
		_phase("adjust_strap")
		lift = 1.0
		tool_carried = true
		adjust = sin((time-3.5)/1.4*PI)
	else:
		_phase("look_to_player")
		lift = 1.0
		tool_carried = true
	mira.rotation.y = -1.65*notice
	_pose_actor(delta,lift,adjust,notice)
	if not tool_carried:
		get_node("ToolRoll").position = TOOL_REST
	else:
		var carry = _left_grip() - Vector3(0,0.12,0)
		get_node("ToolRoll").position = TOOL_REST.lerp(carry,smoothstep(0.0,1.0,clampf((time-1.8)/1.0,0.0,1.0)))
	if _strap: _strap.rotation.z = -0.36+adjust*0.12

func _stage_departure(delta := 0.0):
	var time = departure_elapsed-REPLY_DURATION
	var open_end = ARRIVAL_DURATION+DOOR_DURATION
	var board_end = open_end+BOARD_DURATION
	var turn_end = board_end+TURN_DURATION
	var catch_end = turn_end+(CATCH_DURATION if camera_choice == "lend" else 0.0)
	var close_end = catch_end+CLOSE_DURATION
	var leave_end = close_end+LEAVE_DURATION
	var train = get_node("Train")
	var lift := 1.0
	mira.show()
	train.show()
	camera_slip = 0.0
	laughing = false
	air_shift = 0.0
	if time < 0.0:
		_phase("farewell_reply")
		train.hide()
		mira.position = MIRA_START
		mira.rotation.y = 0.0
		door_open = 0.0
	elif time < ARRIVAL_DURATION:
		_phase("approach")
		var fraction = clampf(time/ARRIVAL_DURATION,0.0,1.0)
		train.position.z = lerpf(-55.0,0.0,1.0-pow(1.0-fraction,2.6))
		door_open = 0.0
		air_shift = sin(fraction*PI)*0.75
		mira.position = MIRA_START
		mira.rotation.y = 0.0
	elif time < open_end:
		_phase("doors_open")
		train.position.z = 0.0
		door_open = smoothstep(0.0,1.0,(time-ARRIVAL_DURATION)/DOOR_DURATION)
		air_shift = (1.0-door_open)*0.18
		mira.position = MIRA_START
		mira.rotation.y = lerp_angle(0.0,PI/2,door_open)
	elif time < board_end:
		_phase("boarding")
		door_open = 1.0
		var fraction = smoothstep(0.0,1.0,(time-open_end)/BOARD_DURATION)
		mira.position = MIRA_START.lerp(Vector3(5.8,0.23,-4),fraction)
		mira.rotation.y = PI/2
	elif time < turn_end:
		_phase("turn_back")
		door_open = 1.0
		mira.position = Vector3(5.8,0.23,-4)
		mira.rotation.y = lerp_angle(PI/2,-PI/2,smoothstep(0.0,1.0,(time-board_end)/TURN_DURATION))
	elif time < catch_end:
		_phase("camera_slip" if time-turn_end < 0.95 else "camera_catch")
		door_open = 1.0
		mira.position = Vector3(5.8,0.23,-4)
		mira.rotation.y = -PI/2
		var catch_time = time-turn_end
		camera_slip = sin(clampf(catch_time/0.95,0.0,1.0)*PI) if catch_time < 0.95 else 0.0
		camera_caught = catch_time >= 0.95
		laughing = catch_time >= 1.05 and catch_time < 2.7
	elif time < close_end:
		_phase("doors_close")
		door_open = 1.0-smoothstep(0.0,1.0,(time-catch_end)/CLOSE_DURATION)
		mira.position = Vector3(5.8,0.23,-4)
		mira.rotation.y = -PI/2
	elif time < leave_end:
		_phase("train_leaves")
		door_open = 0.0
		var fraction = (time-close_end)/LEAVE_DURATION
		train.position.z = lerpf(0.0,58.0,fraction*fraction)
		mira.position = Vector3(5.8,0.23,train.position.z-4)
		mira.rotation.y = -PI/2
		air_shift = sin(fraction*PI)*0.22
		get_node("Indicator/Status").text = "LOCAL · DEPARTED"
	else:
		_phase("ambience_hold")
		door_open = 0.0
		train.hide()
		mira.hide()
		get_node("ToolRoll").hide()
	_update_doors()
	# One stationary rail-following camera. Slow reframing has no shake or tracking chase.
	var reframe = smoothstep(0.0,1.0,clampf(time/board_end,0.0,1.0))
	var widen = smoothstep(0.0,1.0,clampf((time-close_end)/LEAVE_DURATION,0.0,1.0))
	var camera_position = Vector3(-0.45,1.9,-0.15).lerp(Vector3(-1.25,2.05,-2.4),reframe).lerp(Vector3(-1.6,2.7,5.2),widen)
	var target = Vector3(1.8,1.35,-4).lerp(Vector3(5.25,1.45,-4),reframe).lerp(Vector3(4.3,1.7,-4),widen)
	var close_in = smoothstep(0.0,1.0,clampf((time-(open_end+BOARD_DURATION*0.55))/(BOARD_DURATION*0.45+TURN_DURATION*0.5),0.0,1.0))
	var ease_out = smoothstep(0.0,1.0,clampf((time-catch_end)/(CLOSE_DURATION+1.2),0.0,1.0))
	var portrait = close_in*(1.0-ease_out)
	camera_position = camera_position.lerp(Vector3(2.15,1.8,-4.7),portrait)
	target = target.lerp(Vector3(5.8,1.28,-4),portrait)
	_camera(camera_position,target,lerpf(lerpf(43.0,51.0,widen),38.0,portrait))
	_pose_actor(delta,lift,0.0,0.0)
	if mira.visible:
		_update_carried_tool()
		get_node("ToolRoll").show()
	_apply_camera_ownership()

func _update_doors():
	get_node("Train/Doors/Left").position.z = -0.35-door_open*0.76
	get_node("Train/Doors/Right").position.z = 0.35+door_open*0.76

func _pose_actor(delta: float, lift: float, adjust: float, notice: float):
	if not _actor_ready: return
	mira.set_locomotion(1.3 if cinematic_phase == "boarding" else 0.0)
	mira.set_conversation(false)
	mira.apply_preferences(reduced_motion)
	mira.advance_performance(delta)
	# Rest-local additive acting is reset by the imported performance graph every frame.
	mira._offset_bone("Head",-notice*0.38,-notice*0.16)
	mira._offset_bone("Chest",0.0,lift*-0.025,0.0)
	mira._offset_bone("UpperArmLeft",0.0,-0.74*lift,-0.14*lift)
	mira._offset_bone("ForearmLeft",0.0,-0.73*lift)
	mira._offset_bone("UpperArmRight",-adjust*0.17,-adjust*0.91,-adjust*0.13)
	mira._offset_bone("ForearmRight",0.0,-adjust*0.72)
	if cinematic_phase == "farewell_reply":
		var acknowledgement = sin(clampf(departure_elapsed/REPLY_DURATION,0.0,1.0)*PI)
		match farewell:
			"luck":
				mira._offset_bone("Head",0.0,0.14*acknowledgement)
				mira._offset_bone("UpperArmLeft",0.0,-0.12*acknowledgement)
			"joke":
				mira._offset_bone("Chest",0.0,-0.025*acknowledgement,sin(departure_elapsed*9.0)*0.01*acknowledgement)
				mira._offset_bone("Mouth",0.0,0.075*acknowledgement)
				mira._offset_bone("Head",0.035*acknowledgement,-0.035*acknowledgement)
			"thanks":
				mira._offset_bone("UpperArmRight",0.12*acknowledgement,-0.4*acknowledgement,-0.1*acknowledgement)
				mira._offset_bone("ForearmRight",0.0,-0.85*acknowledgement)
			"wave":
				mira._offset_bone("UpperArmRight",0.0,-1.06*acknowledgement,-0.18*acknowledgement)
				mira._offset_bone("ForearmRight",0.0,-1.02*acknowledgement)
				mira._offset_bone("HandRight",sin(departure_elapsed*9.0)*0.08*acknowledgement,0.0)
			"little":
				mira._offset_bone("Head",0.0,0.065*acknowledgement)
				mira._offset_bone("Chest",0.0,0.018*acknowledgement)
	if cinematic_phase in ["camera_slip","camera_catch"]:
		mira._offset_bone("UpperArmRight",0.0,-0.25-camera_slip*0.33,-camera_slip*0.12)
		mira._offset_bone("ForearmRight",0.0,-0.44-camera_slip*0.3)
		mira._offset_bone("HandRight",0.0,camera_slip*0.15)
	if laughing:
		var laugh = sin((departure_elapsed-(REPLY_DURATION+ARRIVAL_DURATION+DOOR_DURATION+BOARD_DURATION+TURN_DURATION))*11.0)*0.013
		mira._offset_bone("Chest",0.0,-0.035+laugh)
		mira._offset_bone("Head",0.0,-0.04)
		mira._offset_bone("Mouth",0.0,0.08)
		mira._offset_bone("BrowLeft",0.0,0.0,-0.06)
		mira._offset_bone("BrowRight",0.0,0.0,0.06)
	if _hair_wisp: _hair_wisp.rotation.x = air_shift*0.32
	if _coat_hem: _coat_hem.rotation.x = air_shift*0.2
	if is_instance_valid(_camera_prop):
		_camera_prop.transform = _camera_rest
		_camera_prop.position += Vector3(0,-camera_slip*0.31,camera_slip*0.06)
		_camera_prop.rotation.z += camera_slip*0.32

func _update_carried_tool():
	# Tools stay at Mira's left grip while she crosses the threshold and rides away.
	get_node("ToolRoll").global_position = _left_grip() - Vector3(0,0.12,0)
	get_node("ToolRoll").rotation = Vector3(0,mira.rotation.y,0)

func _left_grip() -> Vector3:
	if not _actor_ready: return mira.global_position+Vector3(0.3,1.06,0.35)
	return mira.skeleton.global_transform * mira.skeleton.get_bone_global_pose(mira._bone_index("HandLeft")).origin
