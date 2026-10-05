extends Node3D
# Original courtyard presentation for the campaign's second playable chapter.
# WorldFactory remains the owner of shared geometry/material helpers.
const AMBER = Color("eebf79")
const CREAM = Color("ece2cb")
const WOOD = Color("9b7355")
const TEAL = Color("587d78")
var factory: RefCounted
var snapshot: Dictionary = {}
var interactions: Node3D
var pond: Node3D
var race: Node3D
var level_label: Label3D
var level_shape: Node3D
var duck: Node3D
var reduced := false
var decorative_elapsed := 0.0

func build(value: Dictionary) -> Node3D:
	factory = load("res://world/world_factory.gd").new()
	name = "World"
	var spawn = Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = Vector3(2.5,0.1,6.5)
	add_child(spawn)
	_build_courtyard()
	_build_pond()
	_build_booth()
	_build_doors()
	_build_train()
	_build_people()
	if value.get("paper_checkpoint", "") == "complete":
		var mounted = load("res://world/paper_sign.gd").new()
		mounted.name = "MountedPaperSign"
		mounted.configure(value.paper, factory)
		mounted.position = Vector3(-6.3, 3.42, -5.26)
		mounted.scale = Vector3.ONE * 0.67
		add_child(mounted)
		get_node("Booth/BoothSign").visible = false
		for label in get_node("Booth").find_children("*", "Label3D", true, false):
			if label.text == "BOATS WITH OPINIONS": label.visible = false
		var view = Marker3D.new()
		view.name = "SignView"
		view.position = Vector3(-6.3, 2.5, -2.7)
		view.set_meta("look_at", Vector3(-6.3, 2.7, -5.26))
		add_child(view)
	interactions = Node3D.new()
	interactions.name = "Interactions"
	add_child(interactions)
	var motion = load("res://world/ambient_motion.gd").new()
	motion.name = "AmbientMotion"
	add_child(motion)
	apply_snapshot(value)
	return self

func _ready():
	# Child AmbientMotion discovers steam/water in its own ready callback first.
	apply_snapshot(snapshot)

func _build_courtyard():
	factory.box(self,"CourtyardFloor",Vector3(0,-0.3,0),Vector3(22,0.6,24),Color("827f76"))
	for x in [-11.0,11.0]: factory.box(self,"CourtyardBoundary",Vector3(x,0.7,0),Vector3(0.35,1.4,24),Color("626c69"))
	for z in [-12.0,12.0]: factory.box(self,"CourtyardBoundary",Vector3(0,0.7,z),Vector3(22,1.4,0.35),Color("626c69"))
	var surface = Node3D.new()
	surface.name = "CourtyardDetails"
	add_child(surface)
	for z in range(-10,11,2):
		for x in [-9.0,-7.0,2.5,4.5]:
			var stone = factory.box(surface,"WarmPaving",Vector3(x,0.008,z),Vector3(1.7,0.018,1.82),Color("a69b88").darkened(0.04*((z+12)%3)),false)
			stone.rotation.y = 0.02*((z+12)%3-1)
	factory.box(self,"RearCourtyardWall",Vector3(-1.4,2.1,-10.9),Vector3(17.6,4.2,0.32),Color("847e71"))
	for x in [-8.7,-5.6,-2.6,0.5,3.6,6.1]:
		factory.box(surface,"WallPilaster",Vector3(x,2.1,-10.68),Vector3(0.17,4.2,0.1),Color("b3a88e"),false)
	for i in range(7):
		factory.box(surface,"DistantRoof",Vector3(-12+i*4,4.3+(i%3)*0.4,-15),Vector3(3.7,2.8,3),Color("4b5d62"),false)
	var env_node = WorldEnvironment.new()
	env_node.name = "FairEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("324852")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b4bdb4")
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)
	var evening = DirectionalLight3D.new()
	evening.name = "EveningLight"
	evening.rotation_degrees = Vector3(-38,-28,0)
	evening.light_color = Color("c7d0c3")
	evening.light_energy = 0.55
	evening.shadow_enabled = true
	add_child(evening)
	for pair in [[Vector3(-6,3.2,-4.5),2.1],[Vector3(1.1,3.8,-1.0),2.6],[Vector3(4.5,3.2,4.0),1.5]]:
		var lamp = OmniLight3D.new()
		lamp.name = "WarmCourtyardLight"
		lamp.position = pair[0]
		lamp.light_color = AMBER
		lamp.light_energy = pair[1]
		lamp.omni_range = 9
		add_child(lamp)
	_build_string_lights(surface)
	for position_ in [Vector3(-9.2,0,-8.5),Vector3(0.8,0,-8.5),Vector3(5.4,0,-8.5),Vector3(-8.8,0,4.9)]:
		factory.rounded(surface,"ClayPlanter",position_+Vector3(0,0.35,0),0.36,0.28,0.7,Color("ac785b"),true)
		for j in range(5):
			var leaf = factory.orb(surface,position_+Vector3(sin(j*2.4)*0.23,0.87+(j%3)*0.12,cos(j*2.4)*0.22),0.22,Color("648375"))
			leaf.scale = Vector3(0.6,1.6,0.8)
	factory.label(self,"THE UNFINISHED FAIR",Vector3(-2.7,4.15,-6.9),39)
	get_child(get_child_count()-1).name = "FairTitle"
	get_child(get_child_count()-1).billboard = BaseMaterial3D.BILLBOARD_DISABLED

func _build_string_lights(parent: Node3D):
	for i in range(15):
		var x = -9.0+i*0.97
		var y = 4.0-0.65*sin(float(i)/14.0*PI)
		var next_x = x+0.97
		var next_y = 4.0-0.65*sin(float(i+1)/14.0*PI)
		var cord = factory.box(parent,"FairLightCord",Vector3((x+next_x)*0.5,(y+next_y)*0.5,-4.8),Vector3(Vector2(next_x-x,next_y-y).length(),0.025,0.025),Color("52655e"),false)
		cord.rotation.z = atan2(next_y-y,next_x-x)
		var on = i%4 != 1
		var bulb = factory.orb(parent,Vector3(x,y-0.13,-4.8),0.09,AMBER if on else Color("9f9b87"))
		bulb.name = "LitFairBulb" if on else "UnconnectedFairBulb"
		bulb.set_meta("connected",on)
		factory.box(parent,"BulbHolder",Vector3(x,y-0.025,-4.8),Vector3(0.05,0.06,0.05),Color("716448"),false)
		if i%2 == 0:
			var pennant = MeshInstance3D.new()
			pennant.name = "PaperPennant"
			var surface = SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for v in [Vector3(-0.21,0,0),Vector3(0.21,0,0),Vector3(0,-0.43,0)]: surface.add_vertex(v)
			surface.generate_normals()
			pennant.mesh = surface.commit()
			var material = factory.shared_material([Color("d6ae73"),Color("8fac9f"),Color("c48d7c")][i%3]).duplicate()
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			pennant.material_override = material
			pennant.position = Vector3(x+0.48,y-0.02,-4.8)
			parent.add_child(pennant)

func _build_pond():
	factory.box(self,"AccessibleDeck",Vector3(-2.4,0.12,-0.5),Vector3(8.2,0.24,8.2),WOOD)
	var ramp = factory.box(self,"DeckRamp",Vector3(-2.4,0.083,4.57),Vector3(4.8,0.14,2.35),WOOD)
	ramp.rotation.x = 0.096
	for x in range(17):
		factory.box(self,"DeckBoardSeam",Vector3(-6.45+x*0.5,0.246,-0.5),Vector3(0.013,0.008,8.1),Color("77563f"),false)
	for side in [-1.0,1.0]:
		factory.box(self,"DeckAccessibleEdge",Vector3(-2.4+side*4.07,0.29,-0.5),Vector3(0.035,0.09,8.1),Color("d5b485"),false)
	pond = Node3D.new()
	pond.name = "PondAssembly"
	pond.position = Vector3(-2.6,0.78,-0.7)
	add_child(pond)
	factory.box(pond,"PondBasin",Vector3(0,-0.2,0),Vector3(4.7,0.42,4.9),Color("537b79"))
	var water = factory.box(pond,"Water",Vector3(0,0,0),Vector3(4.36,0.035,4.51),Color("628d90"),false)
	var shader = Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded; uniform float motion_scale=1.0; varying vec3 world_pos; void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float ripple=sin(world_pos.z*9.0+TIME*0.45*motion_scale+sin(world_pos.x*5.0))*0.5+0.5; ALBEDO=mix(vec3(0.24,0.43,0.46),vec3(0.45,0.64,0.62),ripple*0.23); ROUGHNESS=0.65;}"
	var material = ShaderMaterial.new()
	material.shader = shader
	water.get_child(0).material_override = material
	for x in [-2.35,2.35]: factory.box(pond,"PondRim",Vector3(x,0.04,0),Vector3(0.17,0.15,5.05),Color("d7be8f"))
	for z in [-2.45,2.45]: factory.box(pond,"PondRim",Vector3(0,0.04,z),Vector3(4.75,0.15,0.17),Color("d7be8f"))
	for x in [-1.8,1.8]:
		for z in [-1.95,1.95]: factory.box(pond,"PondLeg",Vector3(x,-0.46,z),Vector3(0.2,0.55,0.2),Color("795c48"),false)
	var wedge = Node3D.new()
	wedge.name = "PackingWedge"
	wedge.position = Vector3(2.46,-0.37,0.6)
	pond.add_child(wedge)
	var wedge_mesh = MeshInstance3D.new()
	var wedge_surface = SurfaceTool.new()
	wedge_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var v = [Vector3(-0.2,0,-0.3),Vector3(0.32,0,-0.3),Vector3(0.32,0.16,-0.3),Vector3(-0.2,0,0.3),Vector3(0.32,0,0.3),Vector3(0.32,0.16,0.3)]
	for ids in [[0,2,1],[3,4,5],[0,1,4],[0,4,3],[1,2,5],[1,5,4],[0,3,5],[0,5,2]]:
		for index in ids: wedge_surface.add_vertex(v[index])
	wedge_surface.generate_normals()
	wedge_mesh.mesh = wedge_surface.commit()
	wedge_mesh.material_override = factory.shared_material(Color("e0b36a"))
	wedge.add_child(wedge_mesh)
	factory.label(wedge,"PACKING WEDGE",Vector3(0.26,0.17,0.02),14)
	duck = Node3D.new()
	duck.name = "WoodenDuck"
	duck.position = Vector3(-1.72,0.09,-1.7)
	pond.add_child(duck)
	var body = factory.orb(duck,Vector3.ZERO,0.25,Color("be975e"))
	body.scale = Vector3(1,0.68,1.4)
	factory.orb(duck,Vector3(0,0.23,-0.19),0.15,Color("be975e"))
	factory.box(duck,"DuckBeak",Vector3(0,0.2,-0.37),Vector3(0.15,0.07,0.2),Color("d6a067"),false)
	for side in [-1.0,1.0]: factory.orb(duck,Vector3(side*0.125,0.27,-0.24),0.019,Color("453d33"))
	var wing = factory.orb(duck,Vector3(0.16,0.02,0),0.16,Color("b18652"))
	wing.scale = Vector3(0.24,0.7,1.3)
	factory.label(pond,"APPROXIMATELY TWO INCHES OF WATER",Vector3(0,0.01,2.61),18)
	pond.get_child(pond.get_child_count()-1).billboard = BaseMaterial3D.BILLBOARD_DISABLED
	level_label = _label("LevelIndicator","TILTED /",Vector3(0.4,1.28,-0.2),21)
	level_shape = factory.box(self,"LevelIndicatorBar",Vector3(0.4,1.05,-0.2),Vector3(0.64,0.055,0.05),CREAM,false)
	for side in [-1.0,1.0]: factory.rounded(self,"LevelIndicatorEnd",Vector3(0.4+side*0.36,1.02,-0.2),0.035,0.035,0.26,TEAL)
	race = load("res://world/fair_race.gd").new()
	race.configure(factory)
	race.position = pond.position+Vector3(0,0.035,0)
	add_child(race)
	# Dry viewing stool is optional; no sit/help prerequisite gates the race.
	factory.rounded(self,"ViewingStool",Vector3(-5.65,0.6,2.65),0.32,0.32,0.13,Color("c2a37b"),true)
	for offset in [Vector3(-0.2,0,0.12),Vector3(0.2,0,0.12),Vector3(0,0,-0.2)]: factory.box(self,"StoolLeg",Vector3(-5.65,0.41,2.65)+offset,Vector3(0.08,0.34,0.08),WOOD,false)

func _label(id: String, text_: String, where: Vector3, size_: int = 24) -> Label3D:
	factory.label(self,text_,where,size_)
	var sign = get_child(get_child_count()-1) as Label3D
	sign.name = id
	sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return sign

func _build_booth():
	var booth = Node3D.new()
	booth.name = "Booth"
	booth.position = Vector3(-6.3,0,-6.6)
	add_child(booth)
	factory.box(booth,"PaintedBoothBase",Vector3(0,0.85,0),Vector3(5.7,1.7,2.05),TEAL)
	factory.box(booth,"Counter",Vector3(0,1.72,0.1),Vector3(6.05,0.15,2.25),Color("c6aa79"))
	for x in [-2.75,2.75]: factory.box(booth,"BoothPost",Vector3(x,2.6,-0.6),Vector3(0.14,1.8,0.14),Color("9a794e"),false)
	var roof = factory.box(booth,"PaintedRoof",Vector3(0,3.5,-0.4),Vector3(6.3,0.18,2.9),Color("b47660"),false)
	roof.rotation.x = -0.07
	factory.box(booth,"BoothSign",Vector3(0,2.95,0.89),Vector3(4.9,0.65,0.1),Color("51716c"),false)
	factory.label(booth,"BOATS WITH OPINIONS",Vector3(0,2.95,0.97),26)
	var kettle = Node3D.new()
	kettle.name = "Kettle"
	kettle.position = Vector3(1.55,1.88,-0.55)
	booth.add_child(kettle)
	var body = factory.orb(kettle,Vector3(0,0.2,0),0.28,Color("c3b596"))
	body.scale = Vector3(1,0.85,1)
	factory.rounded(kettle,"KettleLid",Vector3(0,0.4,0),0.2,0.2,0.035,Color("a99573"))
	factory.orb(kettle,Vector3(0,0.45,0),0.045,Color("705b42"))
	var spout = factory.rounded(kettle,"KettleSpout",Vector3(-0.28,0.29,0),0.065,0.07,0.32,Color("c3b596"))
	spout.rotation.z = 0.85
	for z in [-0.17,0.17]: factory.box(kettle,"KettleHandle",Vector3(0.2,0.44,z),Vector3(0.06,0.28,0.06),Color("715f49"),false)
	factory.box(kettle,"KettleHandleTop",Vector3(0.2,0.58,0),Vector3(0.06,0.05,0.39),Color("715f49"),false)
	var steam = CPUParticles3D.new()
	steam.name = "Steam"
	steam.position = Vector3(-0.35,0.43,0)
	steam.amount = 12
	steam.lifetime = 2.4
	steam.preprocess = 2.4
	steam.direction = Vector3.UP
	steam.gravity = Vector3.ZERO
	steam.initial_velocity_min = 0.16
	steam.initial_velocity_max = 0.24
	steam.spread = 15
	steam.color = Color(0.96,0.91,0.76,0.2)
	var puff = SphereMesh.new()
	puff.radius = 0.055
	puff.height = 0.11
	steam.mesh = puff
	kettle.add_child(steam)
	factory.label(kettle,"KETTLE NEARLY READY",Vector3(0,0.95,0),15)
	var bird = Node3D.new()
	bird.name = "WoodenBird"
	bird.position = Vector3(-1.45,3.72,-0.35)
	booth.add_child(bird)
	var bird_body = factory.orb(bird,Vector3.ZERO,0.22,Color("b78855"))
	bird_body.scale = Vector3(1,0.8,1.3)
	factory.orb(bird,Vector3(0,0.16,0.18),0.13,Color("b78855"))
	var beak = factory.box(bird,"DownwardBeak",Vector3(0,0.12,0.33),Vector3(0.09,0.08,0.2),Color("d9ad69"),false)
	beak.rotation.x = 0.3
	var painted_wing = factory.orb(bird,Vector3(0.16,0,0),0.17,Color("789987"))
	painted_wing.scale = Vector3(0.24,0.8,1.1)
	for side in [-1.0,1.0]:
		factory.rounded(bird,"CarefulScrew",Vector3(side*0.13,-0.18,0),0.025,0.025,0.045,Color("cebb92"))
		factory.orb(bird,Vector3(side*0.11,0.18,0.22),0.015,Color("453d33"))
	factory.box(self,"HoursBoard",Vector3(-8.9,1.24,-3.4),Vector3(1.9,1.6,0.1),Color("516f67"))
	_label("HoursText","OPEN WHEN THE KETTLE BOILS\nCLOSE WHEN I REMEMBER",Vector3(-8.9,1.24,-3.28),17)
	factory.box(booth,"PrizeShelf",Vector3(-1.15,2.15,-0.6),Vector3(2.2,0.09,0.45),Color("c6aa79"),false)
	for i in range(4):
		var rosette = factory.orb(booth,Vector3(-2.0+i*0.45,2.35,-0.55),0.105,Color("6487a8"))
		rosette.scale.z = 0.25
		for side in [-1.0,1.0]:
			var ribbon = factory.box(booth,"RosetteRibbon",Vector3(-2.0+i*0.45+side*0.035,2.2,-0.55),Vector3(0.05,0.2,0.018),Color("6487a8"),false)
			ribbon.rotation.z = side*0.16
	factory.rounded(booth,"PrestigeJar",Vector3(-0.9,1.95,0.38),0.14,0.14,0.3,Color("93a493"))
	factory.label(booth,"PRESTIGE",Vector3(-0.9,1.99,0.55),12)
	var button = factory.rounded(booth,"FairButton",Vector3(-0.32,1.83,0.6),0.085,0.085,0.025,Color("e1bd76"))
	button.set_meta("souvenir","fair_button")
	factory.box(booth,"BoatBox",Vector3(0.2,1.92,0.2),Vector3(1.0,0.25,0.65),WOOD,false)
	factory.box(booth,"DimensionsCard",Vector3(0.55,1.84,0.6),Vector3(0.42,0.025,0.26),CREAM,false)

func _build_doors():
	for data in [["KitchenDoor",Vector3(1.95,1.57,-10.65),"KITCHEN",Color("b29569")],["ConservatoryDoor",Vector3(5.15,1.57,-10.65),"CONSERVATORY",Color("6c8c80")]]:
		var door = factory.box(self,data[0],data[1],Vector3(2.25,3.14,0.12),data[3])
		factory.box(door,"DoorWindow",Vector3(0,0.28,0.095),Vector3(1.55,1.75,0.035),AMBER,false)
		for x in [-0.55,0.0,0.55]: factory.box(door,"WindowMullion",Vector3(x,0.28,0.12),Vector3(0.04,1.8,0.04),data[3],false)
		factory.box(door,"DoorHandle",Vector3(0.73,-0.2,0.13),Vector3(0.07,0.2,0.05),Color("dec392"),false)
		factory.label(door,data[2],Vector3(0,2.02,0.17),22)
		factory.box(door,"CoveredDoorCanopy",Vector3(0,1.97,0.4),Vector3(2.6,0.12,1.1),Color("a38162"),false)
	_label("DoorwayDirection","KITCHEN  ↑      CONSERVATORY  ↑",Vector3(3.6,0.32,-7.9),18)

func _build_train():
	var train = factory.box(self,"Train",Vector3(8.0,1.9,-0.5),Vector3(3.4,3.8,20),CREAM)
	factory.box(train,"LowerTrainPanel",Vector3(-1.73,-1.01,0),Vector3(0.045,1.45,20),Color("36546a"),false)
	for y in [-1.62,-0.21,1.57]: factory.box(train,"TrainGoldTrim",Vector3(-1.77,y,0),Vector3(0.035,0.045,20),Color("b89962"),false)
	for z in range(-8,10,3):
		factory.box(train,"TrainWindowFrame",Vector3(-1.77,0.59,z),Vector3(0.04,1.55,2.08),Color("b89962"),false)
		factory.box(train,"TrainWindow",Vector3(-1.8,0.59,z),Vector3(0.025,1.31,1.82),AMBER,false)
		factory.box(train,"TrainMullion",Vector3(-1.82,0.59,z),Vector3(0.02,1.33,0.04),Color("36546a"),false)
	factory.box(train,"TrainDoor",Vector3(-1.83,-0.15,4),Vector3(0.03,2.91,1.16),Color("36546a"),false)
	factory.box(train,"TrainDoorGlass",Vector3(-1.86,0.44,4),Vector3(0.035,1.35,0.8),AMBER,false)
	factory.label(self,"TRAIN / PLATFORM 6",Vector3(5.48,2.1,5.4),24)
	for z in range(-8,10,4):
		var wheel = factory.rounded(train,"CarriageWheel",Vector3(-1.5,-1.6,z),0.3,0.3,0.2,Color("4e5050"))
		wheel.rotation.z = PI/2

func _build_people():
	var mira = factory.production_character(self,Vector3(0.8,0.24,2.75),"mira")
	mira.rotation.y = -0.5
	var ada = Node3D.new()
	ada.name = "Ada"
	ada.position = Vector3(-6.7,0.24,-3.55)
	ada.set_meta("character_id","ada")
	add_child(ada)
	factory.person(ada,Vector3.ZERO,Color("b48262"))
	# A practical apron, grey bun and brass spectacles give Ada her own silhouette.
	ada.get_node("Hair").material_override = factory.shared_material(Color("928b80"))
	ada.get_node("HairBun").material_override = factory.shared_material(Color("928b80"))
	factory.box(ada,"WorkApron",Vector3(0,0.99,0.235),Vector3(0.43,0.67,0.045),Color("d8c6a1"),false)
	factory.box(ada,"ApronPocket",Vector3(0,0.89,0.27),Vector3(0.28,0.18,0.018),Color("b3a087"),false)
	for x in [-0.08,0.08]:
		var glasses = factory.orb(ada,Vector3(x,1.61,0.215),0.052,Color("b7a178"))
		glasses.scale = Vector3(1,0.83,0.16)
		factory.orb(ada,Vector3(x,1.61,0.226),0.03,Color("465753"))
	factory.box(ada,"GlassesBridge",Vector3(0,1.61,0.221),Vector3(0.06,0.016,0.016),Color("b7a178"),false)
	factory.label(ada,"ADA",Vector3(0,2.09,0),20)
	_label("MiraName","MIRA",Vector3(0.8,2.32,2.75),20)

func _target(position_: Vector3, label_: String, action: String, value: Variant = null):
	factory.target(interactions,position_,label_,action,value)
	var marker = interactions.get_child(interactions.get_child_count()-2)
	marker.name = action+"_"+str(value) if value != null else action
	# The HUD already prints the exact closest interaction; floating all captions
	# into the same courtyard sightline hides the pond and its small boats.
	interactions.get_child(interactions.get_child_count()-1).visible = false

func _update_interactions():
	for child in interactions.get_children():
		interactions.remove_child(child)
		child.free()
	_target(Vector3(-8.6,0,-2.45),"Opening hours · kettle time","fair_hours")
	_target(Vector3(-6.85,0.24,-4.28),"Prize shelf · ceremonial prestige","fair_prizes")
	_target(Vector3(-4.6,0.24,-4.05),"Painted wooden bird","fair_bird")
	if snapshot.get("campaign_chapter", "") == "paper_sky":
		_target(Vector3(-6.3,0.24,-3.8), "BOATS WITH OPINIONS · your mounted sign", "paper_inspect")
		_target(Vector3(4.95,0,-8.15), "Conservatory · return to the warm room", "paper_return")
		return
	var checkpoint = str(snapshot.get("fair_checkpoint","arrival"))
	match checkpoint:
		"arrival": _target(Vector3(-6.7,0.24,-2.8),"Ada · nearly open","fair_greeting")
		"workshop","race_ready":
			_target(Vector3(-2.0,0.24,3.05),"Boat 1 · rudder, sail and company","fair_setup")
			_target(Vector3(-3.7,0.24,2.75),"Wind and release · three boats","release_boat")
		"crooked_race","level_pond":
			_target(Vector3(-2.7,0.24,2.83),"Check boat 1 · the rudder","inspect_fair","boat")
			_target(Vector3(0.73,0.24,-0.12),"Inspect pond · packing wedge","inspect_fair","wedge")
			_target(Vector3(0.68,0.24,2.25),"Ask Mira · check together","inspect_fair","together")
			_target(Vector3(-5.7,0.24,1.65),"Watch Ada check the waterline","inspect_fair","watch")
			if checkpoint == "level_pond": _target(Vector3(0.74,0.24,-1.45),"Level the pond · shift wedge or ask Ada","level_pond")
		"result":
			_target(Vector3(-2.2,0.24,2.97),"Watch the race again","replay_race")
			_target(Vector3(0.76,0.24,2.28),"Mira · the sign card and supper","fair_departure")
		"complete":
			_target(Vector3(-2.2,0.24,2.97),"Watch the race again","replay_race")
			_target(Vector3(4.95,0,-8.15),"Conservatory doorway · keep the fair button","fair_end")

func apply_snapshot(value: Dictionary):
	snapshot = value.duplicate(true)
	if pond == null: return
	var fair = snapshot.get("fair",{})
	var levelled = bool(fair.get("levelled",false))
	reduced = bool(snapshot.get("settings",{}).get("reduced_motion",false))
	pond.rotation.z = 0.0 if levelled else 0.035
	race.rotation.z = pond.rotation.z
	pond.get_node("PackingWedge").visible = not levelled
	level_shape.rotation.z = 0.0 if levelled else 0.2
	level_label.text = "LEVEL ─" if levelled else "TILTED /"
	race.apply_snapshot(snapshot)
	get_node("AmbientMotion").apply_preferences(reduced)
	if has_node("Mira"): get_node("Mira").apply_preferences(reduced)
	duck.position.y = 0.09
	_update_interactions()
	set_meta("fair_checkpoint",snapshot.get("fair_checkpoint","arrival"))

func play_race(value: Dictionary, replay: bool = false):
	race.play_race(value,replay)

func _process(delta: float):
	if duck == null: return
	# Settings can change through the existing AmbientMotion API while walking
	# or while the race is paused, without rebuilding this world snapshot.
	var current_reduced = get_node("AmbientMotion").reduced if has_node("AmbientMotion") else reduced
	if current_reduced:
		duck.position.y = 0.09
		return
	decorative_elapsed += delta
	duck.position.y = 0.09+sin(decorative_elapsed*0.72)*0.012
