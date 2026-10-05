extends Node3D
# An original, lived-in room. Save data owns choices; motion never owns progression.
signal gesture_finished(action: String)
const CREAM = Color("f3e4c7")
const WOOD = Color("9d6849")
const TEAL = Color("597a72")
const BRASS = Color("c7a26c")
const TABLE_TOP := 1.235
const GESTURE_SECONDS = {"join_sit":3.6,"join_help":4.5,"join_watch":3.6,"bread":3.6,"cup":3.6,"pepper":3.6,"watch":3.6}
var factory: RefCounted
var snapshot: Dictionary = {}
var interactions: Node3D
var paper_sign: Node3D
var reduced := false
var paused := false
var decorative_elapsed := 0.0
var gesture_active := false
var gesture_action := ""
var gesture_elapsed := 0.0
var gesture_duration := 0.0
var gesture_completion: Callable
var _gesture_caption := ""
var _rest: Dictionary = {}
var _motion_ids: Array[String] = []
var _camera_choice := ""
var _paper_configuration: Dictionary = {}

func build(value: Dictionary) -> Node3D:
	factory = load("res://world/world_factory.gd").new()
	name = "World"
	_build_room()
	_build_table()
	_build_working_kitchen()
	_build_people()
	_build_callbacks()
	interactions = Node3D.new()
	interactions.name = "Interactions"
	add_child(interactions)
	var ambient = load("res://world/ambient_motion.gd").new()
	ambient.name = "AmbientMotion"
	add_child(ambient)
	_marker("Spawn",Vector3(0,0.12,6.4),Vector3(0,1.4,-0.4))
	_marker("TableView",Vector3(-0.44,2.08,2.12),Vector3(-0.45,1.4,-0.62))
	_marker("SignView",Vector3(-5.62,2.7,-2.7),Vector3(-5.62,2.7,-6.75))
	_marker("DinnerReturn",Vector3(-0.44,0.12,2.55),Vector3(-0.45,1.4,-0.62))
	_capture_rest()
	apply_snapshot(value)
	return self

func _ready():
	apply_snapshot(snapshot)

func _marker(id: String, where: Vector3, look: Vector3) -> Marker3D:
	var marker = Marker3D.new()
	marker.name = id
	marker.position = where
	marker.set_meta("look_at",look)
	add_child(marker)
	return marker

func _node(parent: Node3D, id: String, where: Vector3 = Vector3.ZERO) -> Node3D:
	var node = Node3D.new()
	node.name = id
	node.position = where
	parent.add_child(node)
	return node

func _label(parent: Node3D, id: String, text_: String, where: Vector3, size_: int = 22, pixel: float = 0.004) -> Label3D:
	var label = Label3D.new()
	label.name = id
	label.text = text_
	label.font_size = size_
	label.pixel_size = pixel
	label.position = where
	label.modulate = CREAM
	label.outline_modulate = Color("263b35")
	label.outline_size = 2
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	parent.add_child(label)
	return label

func _glass(parent: Node3D, id: String, where: Vector3, size_: Vector3, color_: Color) -> Node3D:
	var pane = factory.box(parent,id,where,size_,color_,false)
	var material = StandardMaterial3D.new()
	material.albedo_color = color_
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.28
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	pane.get_child(0).material_override = material
	pane.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return pane

func _build_room():
	factory.box(self,"KitchenFloor",Vector3(0,-0.25,0.75),Vector3(16,0.5,17.5),Color("9a8169"))
	var tiles = _node(self,"TerracottaFloor")
	for tone in range(3):
		var batch = MultiMeshInstance3D.new()
		batch.name = "TerracottaBatch%d" % tone
		var multi = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = factory.shared_box_mesh(Vector3(1.17,0.022,1.17))
		var positions: Array[Vector3] = []
		for x in range(-6,7):
			for z in range(-5,8):
				if (x+z+30)%3 == tone: positions.append(Vector3(x*1.2,0.012,z*1.2))
		multi.instance_count = positions.size()
		for i in range(positions.size()): multi.set_instance_transform(i,Transform3D(Basis.IDENTITY,positions[i]))
		batch.multimesh = multi
		batch.material_override = factory.shared_material(Color("ac7d60").lightened(tone*0.034))
		tiles.add_child(batch)
	factory.box(self,"BackWall",Vector3(0,2.55,-7.9),Vector3(16,5.1,0.2),Color("8d9982"))
	for x in [-8.0,8.0]:
		factory.box(self,"SideWall",Vector3(x,2.5,0.7),Vector3(0.2,5,17.4),Color("789184"))
	factory.box(self,"FrontWall",Vector3(0,0.64,9.43),Vector3(16,1.28,0.18),TEAL)
	for x in [-7.87,7.87]: factory.box(self,"Skirting",Vector3(x,0.12,0.7),Vector3(0.08,0.24,17.2),WOOD,false)
	factory.box(self,"BackSkirting",Vector3(0,0.12,-7.76),Vector3(15.8,0.24,0.08),WOOD,false)
	var ceiling = _node(self,"CeilingBeams")
	for x in [-5.6,-2.8,0.0,2.8,5.6]: factory.box(ceiling,"OldBeam",Vector3(x,5.03,0.7),Vector3(0.15,0.24,17.3),Color("6d614d"),false)
	factory.box(self,"RainWindowFrame",Vector3(2.7,3.03,-7.73),Vector3(5.0,2.7,0.1),Color("465f59"),false)
	_glass(self,"RainWindow",Vector3(2.7,3.03,-7.64),Vector3(4.72,2.44,0.035),Color(0.23,0.39,0.46,0.64))
	for x in [0.28,2.7,5.12]: factory.box(self,"WindowMullion",Vector3(x,3.03,-7.57),Vector3(0.075,2.68,0.06),CREAM,false)
	factory.box(self,"WindowCrossbar",Vector3(2.7,3.1,-7.57),Vector3(4.91,0.06,0.06),CREAM,false)
	var drops = _node(self,"Condensation",Vector3(0.47,2.15,-7.545))
	for i in range(14):
		var drop = factory.orb(drops,Vector3(float(i%5)*0.91,float(i/5)*0.64,0),0.022,Color("b4c8be"))
		drop.name = "Drop%d" % i
		drop.scale = Vector3(0.8,1.65,0.35)
	for i in range(6):
		var hill = factory.box(self,"DistantCourtyardRoof",Vector3(0.8+i*0.67,2.2+(i%2)*0.24,-7.7),Vector3(0.55,0.14,0.05),Color("253d44"),false)
		hill.rotation.z = (i%2-0.5)*0.2
	factory.box(self,"DepartureDoor",Vector3(7.86,1.64,5.4),Vector3(0.075,3.25,2.15),Color("b5895d"),false)
	factory.box(self,"DoorInset",Vector3(7.8,2.13,5.4),Vector3(0.05,1.75,1.45),TEAL,false)
	factory.orb(self,Vector3(7.72,1.32,4.7),0.075,BRASS)
	var way = _label(self,"NextMorningDirection","LOWER MILL / EARLY TRAM",Vector3(7.72,3.47,5.4),19,0.0045)
	way.rotation.y = -PI/2
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("263b44")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e0c9a4")
	env.ambient_light_energy = 0.54
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var moon = DirectionalLight3D.new()
	moon.name = "QuietNightLight"
	moon.rotation_degrees = Vector3(-47,-30,0)
	moon.light_color = Color("bed1d0")
	moon.light_energy = 0.35
	add_child(moon)
	for where in [Vector3(-0.44,4.04,-0.45),Vector3(-3.4,3.9,-5.3),Vector3(4.4,3.9,4.2)]:
		var lamp = OmniLight3D.new()
		lamp.name = "SteadyKitchenLight"
		lamp.position = where
		lamp.light_color = Color("ffda9b")
		lamp.light_energy = 2.65
		lamp.omni_range = 9.5
		lamp.shadow_enabled = false
		add_child(lamp)
		factory.rounded(self,"EnamelLampShade",where+Vector3(0,0.12,0),0.12,0.39,0.25,Color("ac7657"))
		factory.orb(self,where,0.105,Color("eebf79"))
		factory.box(self,"LampCord",where+Vector3(0,0.51,0),Vector3(0.02,0.8,0.02),Color("615340"),false)
	_label(self,"RoomTitle","NIGHT KITCHEN",Vector3(-0.5,4.42,-7.56),30,0.008)

func _cup(parent: Node3D, id: String, where: Vector3, color_: Color = TEAL) -> Node3D:
	var cup = _node(parent,id,where)
	factory.rounded(cup,"CupBody",Vector3(0,0.1,0),0.09,0.075,0.2,color_)
	factory.rounded(cup,"DarkTea",Vector3(0,0.195,0),0.075,0.075,0.006,Color("584b35"))
	var handle = factory.orb(cup,Vector3(0.105,0.1,0),0.066,color_)
	handle.name = "CupHandle"
	handle.scale = Vector3(0.75,0.92,0.3)
	return cup

func _bowl(parent: Node3D, id: String, where: Vector3, full: bool = true) -> Node3D:
	var bowl = _node(parent,id,where)
	factory.rounded(bowl,"BowlBody",Vector3(0,0.067,0),0.22,0.125,0.13,CREAM)
	var soup = factory.rounded(bowl,"Soup",Vector3(0,0.13,0),0.196,0.196,0.009,Color("cd9157"))
	soup.visible = full
	for i in range(5):
		var herb = factory.box(soup,"Herb",Vector3(sin(i*2.4)*0.11,0.009,cos(i*2.4)*0.11),Vector3(0.032,0.004,0.015),Color("5e7a4a"),false)
		herb.rotation.y = i*0.8
	return bowl

func _chair(id: String, where: Vector3, angle: float):
	var chair = _node(self,id,where)
	chair.rotation.y = angle
	chair.set_meta("collision_free_seating",true)
	factory.box(chair,"WornSeat",Vector3(0,0.48,0),Vector3(0.67,0.08,0.66),WOOD,false)
	for x in [-0.27,0.27]:
		for z in [-0.26,0.26]: factory.box(chair,"ChairLeg",Vector3(x,0.24,z),Vector3(0.067,0.44,0.067),TEAL,false)
	for x in [-0.27,0.27]: factory.box(chair,"BackUpright",Vector3(x,0.9,0.27),Vector3(0.065,0.91,0.065),TEAL,false)
	for y in [0.9,1.2]: factory.box(chair,"BackSlat",Vector3(0,y,0.27),Vector3(0.64,0.115,0.06),WOOD,false)

func _build_table():
	var table = factory.box(self,"DinnerTable",Vector3(-0.44,1.12,-0.5),Vector3(4.3,0.23,2.2),WOOD)
	for x in [-1.76,1.76]:
		for z in [-0.72,0.72]: factory.box(table,"TableLeg",Vector3(x,-0.5,z),Vector3(0.145,0.96,0.145),TEAL,false)
	factory.box(table,"LinenRunner",Vector3(0,0.122,0),Vector3(1.25,0.022,2.19),Color("c7b994"),false)
	for i in range(6): factory.box(table,"RunnerStitch",Vector3(-0.51+i*0.205,0.137,0),Vector3(0.01,0.004,2.11),Color("879982"),false)
	var place = _node(self,"PlayerPlace",Vector3(-0.44,TABLE_TOP,0.24))
	place.set_meta("already_set",true)
	_bowl(place,"Bowl",Vector3.ZERO,false)
	_cup(place,"Cup",Vector3(0.42,0,-0.09),Color("8caaa0"))
	factory.box(place,"Napkin",Vector3(-0.42,0.009,0.05),Vector3(0.25,0.018,0.31),CREAM,false)
	var fair_button = factory.rounded(place,"FairButton",Vector3(-0.49,0.039,0.13),0.065,0.065,0.026,Color("d4a764"))
	fair_button.set_meta("souvenir_id","fair_button")
	for x in [-0.021,0.021]:
		factory.orb(fair_button,Vector3(x,0.016,0),0.008,Color("6e694d")).scale.y = 0.35
	_label(place,"FairButtonNote","FAIR BUTTON",Vector3(-0.44,0.047,0.225),10,0.0014)
	var spoon = _node(place,"Spoon",Vector3(-0.39,0.025,0.05))
	factory.box(spoon,"Handle",Vector3(0,0,0.048),Vector3(0.026,0.018,0.22),BRASS,false)
	factory.orb(spoon,Vector3(0,0,-0.09),0.045,BRASS).scale = Vector3(0.8,0.15,1.25)
	factory.box(place,"FoldedPlaceCard",Vector3(0,0.021,0.25),Vector3(0.37,0.02,0.12),Color("d4c6aa"),false)
	_label(place,"PlaceCard","SAVED YOU A PLACE",Vector3(0,0.053,0.29),13,0.0016)
	for index in range(3):
		var setting = _node(self,"CompanionPlace%d" % index,[Vector3(-1.45,TABLE_TOP,-1.16),Vector3(0.87,TABLE_TOP,-1.16),Vector3(-2.04,TABLE_TOP,-0.48)][index])
		_bowl(setting,"Bowl",Vector3.ZERO)
		_cup(setting,"Cup",Vector3(0.34,0,0.05),[TEAL,Color("b98562"),Color("839497")][index])
	_chair("PlayerChair",Vector3(-0.44,0,1.45),0)
	_chair("NoorChair",Vector3(-1.5,0,-2.16),PI)
	_chair("MiraChair",Vector3(0.86,0,-2.16),PI)
	_chair("AdaChair",Vector3(-3.19,0,-0.48),PI/2)
	var bread = _node(self,"BreadBoard",Vector3(-1.44,TABLE_TOP,-0.16))
	factory.box(bread,"CuttingBoard",Vector3.ZERO,Vector3(0.87,0.04,0.46),Color("c59666"),false)
	var loaf = factory.orb(bread,Vector3(-0.14,0.14,0),0.24,Color("b87d43"))
	loaf.name = "MainHalf"
	loaf.scale = Vector3(0.92,0.43,0.75)
	var torn = _node(bread,"TornHalf",Vector3(0.12,0.13,0))
	factory.orb(torn,Vector3.ZERO,0.16,Color("c58d50")).scale = Vector3(1.0,0.58,1.08)
	factory.orb(torn,Vector3(-0.107,0,0),0.113,Color("efd5a2")).scale = Vector3(0.12,0.65,1)
	var tearing_hands = _node(bread,"TearingHands")
	tearing_hands.visible = false
	for side in [-1.0,1.0]:
		var hand = _node(tearing_hands,"LeftHand" if side < 0 else "RightHand",Vector3(side*0.25,0.13,0.09))
		factory.orb(hand,Vector3.ZERO,0.073,Color("e9c09d")).scale = Vector3(1.0,0.65,1.28)
		factory.box(hand,"LinenCuff",Vector3(side*0.085,-0.01,0.11),Vector3(0.1,0.06,0.17),Color("929f8c"),false)
	for i in range(3):
		var score = factory.box(bread,"FlourScore",Vector3(-0.23+i*0.095,0.235,-0.01),Vector3(0.045,0.009,0.18),Color("e1ba83"),false)
		score.rotation.y = 0.31
	var pepper = _node(self,"PepperShaker",Vector3(0.67,TABLE_TOP,-0.09))
	factory.rounded(pepper,"PepperBody",Vector3(0,0.11,0),0.068,0.092,0.22,Color("685140"))
	factory.rounded(pepper,"PepperLid",Vector3(0,0.235,0),0.075,0.075,0.035,BRASS)
	for i in range(5): factory.orb(pepper,Vector3(sin(i*TAU/5)*0.037,0.259,cos(i*TAU/5)*0.037),0.006,Color("423a30"))
	var grains = _node(self,"PepperGrains",Vector3(-0.44,TABLE_TOP+0.3,0.24))
	for i in range(6): factory.orb(grains,Vector3(sin(i*2.2)*0.1,i*0.028,cos(i*2.2)*0.09),0.007,Color("40362c"))
	grains.visible = false
	var pass_bread = _node(self,"PassingBread",Vector3(-1.9,TABLE_TOP+0.12,-0.65))
	factory.rounded(pass_bread,"BreadPlate",Vector3.ZERO,0.245,0.2,0.027,Color("8b9b83"))
	for i in range(3): factory.orb(pass_bread,Vector3(-0.12+i*0.12,0.07,0),0.09,Color("e0bb82")).scale = Vector3(0.73,0.46,1)
	var passing_hand = factory.orb(pass_bread,Vector3(-0.25,-0.025,0),0.086,Color("edc5a3"))
	passing_hand.name = "PassingHand"
	passing_hand.scale = Vector3(1.3,0.5,0.8)
	var ladle = _node(self,"Ladle",Vector3(-0.56,TABLE_TOP+0.3,-0.56))
	factory.rounded(ladle,"LadleBowl",Vector3.ZERO,0.12,0.09,0.08,BRASS)
	var shaft = factory.box(ladle,"LadleHandle",Vector3(0,0.24,-0.11),Vector3(0.035,0.57,0.035),BRASS,false)
	shaft.rotation.x = -0.45
	var serving_hand = factory.orb(ladle,Vector3(0,0.45,-0.19),0.078,Color("edc5a3"))
	serving_hand.name = "ServingHand"
	serving_hand.scale = Vector3(1.1,0.8,0.72)
	factory.rounded(ladle,"SoupInLadle",Vector3(0,0.041,0),0.095,0.095,0.006,Color("cd9157"))
	var stream = factory.rounded(ladle,"PourStream",Vector3(0,-0.12,0.04),0.018,0.021,0.26,Color("cd9157"))
	stream.visible = false

func _build_working_kitchen():
	factory.box(self,"BackCounter",Vector3(-2.8,0.69,-6.19),Vector3(8.35,1.36,1.25),TEAL)
	factory.box(self,"CounterTop",Vector3(-2.8,1.39,-6.19),Vector3(8.55,0.1,1.39),Color("d2c4a4"),false)
	for x in [-6.13,-4.44,-2.75,-1.06,0.63]:
		factory.box(self,"CupboardDoor",Vector3(x,0.7,-5.5),Vector3(1.54,1.04,0.055),Color("759287"),false)
		factory.box(self,"CupboardPull",Vector3(x+0.42,0.85,-5.45),Vector3(0.16,0.035,0.04),BRASS,false)
	factory.box(self,"Stove",Vector3(-3.4,1.48,-6),Vector3(1.35,0.08,0.96),Color("494a40"),false)
	for x in [-3.8,-3.0]:
		for z in [-6.26,-5.84]: factory.rounded(self,"StoveRing",Vector3(x,1.54,z),0.18,0.18,0.018,Color("79765f"))
	var pot = _node(self,"SoupPot",Vector3(-3.42,1.69,-5.94))
	factory.rounded(pot,"EnamelPot",Vector3.ZERO,0.35,0.29,0.3,Color("a86548"))
	factory.rounded(pot,"SoupSurface",Vector3(0,0.154,0),0.321,0.321,0.008,Color("d49657"))
	for x in [-0.4,0.4]: factory.box(pot,"PotHandle",Vector3(x,0.065,0),Vector3(0.17,0.075,0.13),Color("5d5744"),false)
	var steam = _node(self,"Steam",Vector3(-3.42,1.93,-5.94))
	for i in range(10):
		var puff = factory.orb(steam,Vector3(sin(i*2.3)*0.14,i*0.083,cos(i*2.3)*0.14),0.057+i*0.009,Color("cdd6c4"))
		puff.name = "Puff%d" % i
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9,0.89,0.8,0.13)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material_override = mat
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shelves = _node(self,"OpenShelves",Vector3(-5.1,2.44,-7.42))
	for y in [0.0,0.58]:
		factory.box(shelves,"Shelf",Vector3(0,y,0),Vector3(4.85,0.085,0.43),WOOD,false)
		for i in range(6):
			var jar = factory.rounded(shelves,"PantryJar",Vector3(-1.98+i*0.74,y+0.19,0.02),0.095,0.1,0.3,[Color("b39765"),Color("827e50"),Color("b37855")][i%3])
			factory.rounded(jar,"JarLid",Vector3(0,0.164,0),0.107,0.107,0.035,CREAM)
	_label(shelves,"StockNote","LENTILS / BREAD / TEA / SAVE THE BIG SPOON",Vector3(0,0.95,0.06),16,0.0035)
	factory.box(self,"Sideboard",Vector3(5.96,0.62,-5.43),Vector3(2.5,1.2,1.15),WOOD)
	factory.box(self,"SideboardTop",Vector3(5.96,1.28,-5.43),Vector3(2.65,0.12,1.26),Color("d6c3a1"),false)
	var teapot = factory.rounded(self,"TeaPot",Vector3(6.08,1.58,-5.5),0.2,0.24,0.46,Color("668579"))
	factory.rounded(teapot,"TeaLid",Vector3(0,0.26,0),0.19,0.19,0.025,BRASS)
	var spout = factory.rounded(teapot,"TeaSpout",Vector3(-0.23,0.11,0),0.04,0.075,0.35,Color("668579"))
	spout.rotation.z = 0.9
	for i in range(3): _cup(self,"SideboardCup%d" % i,Vector3(5.22+i*0.33,1.35,-5.12))
	factory.box(self,"TowelRail",Vector3(5.97,0.98,-4.8),Vector3(0.9,0.035,0.035),BRASS,false)
	factory.box(self,"TeaTowel",Vector3(5.97,0.73,-4.765),Vector3(0.48,0.52,0.035),CREAM,false)
	for i in range(4): factory.box(self,"TowelStripe",Vector3(5.81+i*0.105,0.73,-4.741),Vector3(0.023,0.51,0.006),TEAL,false)
	var herbs = _node(self,"DryingHerbs",Vector3(-7.62,3.44,-3.8))
	for i in range(5):
		factory.box(herbs,"HerbString",Vector3(0,-0.17,i*0.3),Vector3(0.012,0.34,0.012),BRASS,false)
		for j in range(3): factory.orb(herbs,Vector3(0,-0.4-j*0.095,i*0.3),0.074,Color("899b62")).scale = Vector3(0.6,1.3,0.65)

func _build_people():
	var noor = _node(self,"Noor",Vector3(-1.52,0,-2.24))
	noor.set_meta("character_id","noor")
	factory.person(noor,Vector3.ZERO,Color("879c86"))
	noor.get_node("HairBun").visible = false
	noor.get_node("Satchel").visible = false
	factory.box(noor,"PracticalApron",Vector3(0,0.95,0.22),Vector3(0.45,0.67,0.045),Color("477970"),false)
	for x in [-0.08,0.08]:
		factory.orb(noor,Vector3(x,1.61,0.223),0.054,BRASS).scale = Vector3(1,0.83,0.13)
	factory.box(noor,"SpectacleBridge",Vector3(0,1.61,0.229),Vector3(0.054,0.013,0.012),BRASS,false)
	var ada = _node(self,"Ada",Vector3(-3.2,0,-0.51))
	ada.rotation.y = PI/2
	ada.set_meta("character_id","ada")
	factory.person(ada,Vector3.ZERO,Color("b48262"))
	ada.get_node("HairBun").material_override = factory.shared_material(Color("928b80"))
	ada.get_node("Satchel").visible = false
	ada.get_node("Hair").material_override = factory.shared_material(Color("928b80"))
	factory.box(ada,"WorkApron",Vector3(0,0.99,0.235),Vector3(0.43,0.67,0.045),Color("d8c6a1"),false)
	factory.box(ada,"ApronPocket",Vector3(0,0.89,0.27),Vector3(0.28,0.18,0.018),Color("b3a087"),false)
	for x in [-0.08,0.08]:
		factory.orb(ada,Vector3(x,1.61,0.215),0.052,BRASS).scale = Vector3(1,0.83,0.16)
	factory.box(ada,"GlassesBridge",Vector3(0,1.61,0.221),Vector3(0.06,0.016,0.016),BRASS,false)
	factory.box(ada,"RolledSleeve",Vector3(-0.33,1.05,0),Vector3(0.19,0.14,0.18),CREAM,false)
	var mira = factory.production_character(self,Vector3(1.1,0,-2.49),"mira")
	mira.rotation.y = -0.31
	mira.set_meta("destination","lower_mill")
	mira.set_meta("independent_decision",true)
	factory.box(self,"MiraWorkshopSatchel",Vector3(1.83,0.4,-2.4),Vector3(0.41,0.46,0.21),Color("9b7053"),false)
	factory.box(self,"LowerMillDrawing",Vector3(1.84,0.66,-2.37),Vector3(0.36,0.08,0.08),CREAM,false)
	_label(self,"WorkshopAddress","LOWER MILL\nWORKSHOP KEY / 8:10",Vector3(1.85,0.55,-2.24),12,0.002)
	var thread = _label(self,"ConversationThreads","Noor: The soup needs another minute.\nAda: The bread does not.",Vector3(-0.7,2.54,-2.25),18,0.0044)
	thread.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	thread.set_meta("people_speaking_while_working",true)
	var caption = _label(self,"GestureCaption","",Vector3(-0.44,2.63,-0.47),19,0.0037)
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.visible = false

func _build_callbacks():
	paper_sign = load("res://world/paper_sign.gd").new()
	paper_sign.name = "PaperSign"
	paper_sign.position = Vector3(-5.61,4.08,-7.5)
	add_child(paper_sign)
	paper_sign.configure({},factory)
	for x in [-6.87,-4.35]: factory.box(self,"SignHook",Vector3(x,4.15,-7.61),Vector3(0.055,0.15,0.09),BRASS,false)
	factory.box(self,"CameraShelf",Vector3(3.27,1.64,-5.86),Vector3(1.85,0.12,0.78),WOOD,false)
	_node(self,"CameraCallback",Vector3(3.27,1.71,-5.86))

func _set_camera_callback(choice: String):
	if choice == _camera_choice: return
	_camera_choice = choice
	var callback = get_node("CameraCallback")
	for child in callback.get_children():
		callback.remove_child(child)
		child.free()
	callback.set_meta("camera_choice",choice)
	if choice == "unused":
		var box = factory.box(callback,"UnopenedBox",Vector3(0,0.12,0),Vector3(0.58,0.24,0.39),Color("b99e76"),false)
		factory.box(box,"PaperSeal",Vector3(0,0.126,0),Vector3(0.06,0.013,0.4),CREAM,false)
		_label(callback,"CallbackNote","THE BOX IS STILL SEALED",Vector3(0,0.38,0.11),13,0.0026)
	else:
		var camera = factory.box(callback,"Camera",Vector3(-0.17,0.1,0),Vector3(0.33,0.19,0.13),Color("4d5149"),false)
		factory.rounded(camera,"Lens",Vector3(0,0,0.11),0.07,0.08,0.1,Color("9a997f")).rotation.x = PI/2
		factory.orb(camera,Vector3(0,0,0.16),0.053,Color("334f58")).scale.z = 0.23
		factory.box(camera,"Viewfinder",Vector3(0.07,0.116,0),Vector3(0.1,0.045,0.07),BRASS,false)
		factory.box(callback,"CameraStrap",Vector3(-0.12,0.015,-0.12),Vector3(0.4,0.014,0.025),Color("806b53"),false)
		var photo = factory.box(callback,"ShorePhotograph",Vector3(0.28,0.023,0.09),Vector3(0.29,0.016,0.34),CREAM,false)
		factory.box(photo,"BlueShore",Vector3(0,0.011,0),Vector3(0.245,0.004,0.255),Color("58777c"),false)
		factory.box(photo,"Lighthouse",Vector3(0.06,0.017,-0.04),Vector3(0.036,0.004,0.13),Color("e6c786"),false)
		_label(callback,"CallbackNote","YOUR SHORE FRAME" if choice == "take" else "MIRA'S SHORE FRAME",Vector3(0,0.36,0.13),13,0.0027)

func _capture_rest():
	_motion_ids = ["Ladle","BreadBoard/TornHalf","PepperShaker","PassingBread","PlayerChair","PlayerPlace/Cup","PlayerPlace/Bowl","Noor/ArmRight","Noor/ArmLeft","Ada/ArmLeft","Ada/ArmRight","Mira"]
	for i in range(10): _motion_ids.append("Steam/Puff%d" % i)
	for i in range(14): _motion_ids.append("Condensation/Drop%d" % i)
	for id in _motion_ids: _rest[id] = get_node(id).transform

func _reset_pose():
	for id in _rest:
		if has_node(id): get_node(id).transform = _rest[id]
	get_node("PepperGrains").visible = false
	get_node("Ladle/PourStream").visible = false
	get_node("BreadBoard/TearingHands").visible = false

func _target(where: Vector3, label_: String, id: String):
	var marker = Marker3D.new()
	marker.name = id
	marker.position = where
	marker.set_meta("action_id",id)
	marker.set_meta("value",null)
	marker.set_meta("label",label_)
	marker.add_to_group("interactables")
	interactions.add_child(marker)

func _update_interactions():
	for child in interactions.get_children():
		interactions.remove_child(child)
		child.free()
	var checkpoint = str(snapshot.get("kitchen_checkpoint","arrival"))
	if checkpoint == "locked": return
	if checkpoint == "arrival": _target(Vector3(0.1,0,3.08),"Your place is set · sit, help or watch","kitchen_join")
	else:
		_target(Vector3(-0.44,0,2.05),"Table · settle into supper","kitchen_table")
		_target(Vector3(-2.95,0,1.04),"Bread · tear a piece to pass","kitchen_bread")
		_target(Vector3(2.25,0,0.8),"Cup · pass the tea","kitchen_cup")
		_target(Vector3(2.43,0,-1.31),"Pepper · slide it across","kitchen_pepper")
		_target(Vector3(1.2,0,-3.95),"Mira · the morning workshop","kitchen_mira")
		_target(Vector3(6.55,0,5.37),"Door · the evening can end here","kitchen_exit")
	_target(Vector3(-5.59,0,-5.14),"The sign · boats with opinions","kitchen_sign")
	_target(Vector3(3.34,0,-4.76),"Camera shelf · the shore frame","kitchen_camera")

func apply_snapshot(value: Dictionary):
	snapshot = value.duplicate(true)
	if paper_sign == null: return
	var configuration: Dictionary = snapshot.get("paper",{})
	if configuration != _paper_configuration:
		paper_sign.configure(configuration,factory)
		_paper_configuration = configuration.duplicate(true)
	_set_camera_callback(str(snapshot.get("camera_choice","unused")))
	var kitchen: Dictionary = snapshot.get("kitchen",{})
	get_node("PlayerPlace/Bowl/Soup").visible = bool(kitchen.get("served",false))
	get_node("PlayerPlace").set_meta("served",bool(kitchen.get("served",false)))
	get_node("PlayerPlace").set_meta("arrival_mode",str(kitchen.get("mode","unselected")))
	if not gesture_active: _apply_saved_staging()
	apply_preferences(bool(snapshot.get("settings",{}).get("reduced_motion",false)))
	_update_interactions()
	set_meta("kitchen_checkpoint",str(snapshot.get("kitchen_checkpoint","arrival")))
	set_meta("dinner_mode",str(kitchen.get("mode","unselected")))

func _apply_saved_staging():
	var kitchen: Dictionary = snapshot.get("kitchen",{})
	_reset_pose()
	get_node("PlayerPlace/Bowl/Soup").visible = bool(kitchen.get("served",false))
	if str(kitchen.get("mode","unselected")) == "sit": get_node("PlayerChair").position.z = 1.25
	if str(kitchen.get("exchange","unselected")) == "bread": get_node("BreadBoard/TornHalf").position.x = 0.36
	if str(kitchen.get("exchange","unselected")) == "cup": get_node("PlayerPlace/Cup").position.x = 0.65
	if str(kitchen.get("exchange","unselected")) == "pepper": get_node("PepperShaker").position = Vector3(-0.03,TABLE_TOP,-0.3)

func apply_preferences(value: bool):
	reduced = value
	if has_node("AmbientMotion"): get_node("AmbientMotion").apply_preferences(value)
	if has_node("Mira"): get_node("Mira").apply_preferences(value)
	if value:
		paper_sign.advance_secondary(0.0,true)
		if gesture_active and not paused: _finish_gesture()

func set_paused(value: bool):
	paused = value
	if has_node("AmbientMotion"): get_node("AmbientMotion").set_process(not value)
	if has_node("Mira"): get_node("Mira").set_process(not value)
	if not paused and reduced and gesture_active: _finish_gesture()

func table_view_transform() -> Transform3D:
	var marker = get_node("TableView")
	return Transform3D(Basis.looking_at(marker.get_meta("look_at")-marker.position,Vector3.UP),marker.position)

func arrival_transform() -> Transform3D:
	return get_node("Spawn").transform

func gesture_subtitle() -> String:
	return _gesture_caption

func begin_gesture(action: String, completion: Callable = Callable()):
	# Cancel presentation only; the persisted snapshot already owns its outcome.
	if gesture_active:
		gesture_active = false
		gesture_completion = Callable()
	gesture_action = action.trim_prefix("kitchen_")
	gesture_completion = completion
	gesture_elapsed = 0.0
	gesture_duration = float(GESTURE_SECONDS.get(gesture_action,0.0))
	gesture_active = true
	_gesture_caption = _caption_for(gesture_action,0.0)
	get_node("GestureCaption").text = _gesture_caption
	get_node("GestureCaption").visible = false # Accessible HUD owns captions; projected text would duplicate it
	_reset_pose()
	if gesture_action.begins_with("join_"):
		get_node("PlayerPlace/Bowl/Soup").visible = false
	if reduced or gesture_duration <= 0.0:
		if not paused: _finish_gesture()
	else:
		_stage_gesture(0.0)

func _caption_for(action: String, progress: float) -> String:
	match action:
		"join_sit": return "Ada slides the chair out." if progress < 0.5 else "Noor fills the bowl beside your spoon."
		"join_help": return "Noor holds the pot steady." if progress < 0.5 else "The ladle empties into your bowl."
		"join_watch": return "Steam uncurls above the pot." if progress < 0.5 else "Soup reaches the bowl beside your spoon."
		"bread": return "The crust cracks under two hands." if progress < 0.5 else "Ada catches the piece on a plate."
		"cup": return "You nudge the cup within reach." if progress < 0.5 else "Mira moves the tea, still talking."
		"pepper": return "Noor asks for the pepper." if progress < 0.5 else "The shaker travels across the linen."
		"watch": return "Ada passes bread while Noor pours." if progress < 0.5 else "Mira turns the workshop key in her hand."
	return ""

func _stage_gesture(progress: float):
	var p = clampf(progress,0.0,1.0)
	var curve = sin(p*PI)
	var eased = smoothstep(0.0,1.0,p)
	_gesture_caption = _caption_for(gesture_action,p)
	get_node("GestureCaption").text = _gesture_caption
	match gesture_action:
		"join_sit","join_help","join_watch":
			get_node("PlayerChair").position.z = 1.45+curve*0.31-eased*0.2 if gesture_action == "join_sit" else 1.45
			var pot_position = Vector3(-3.42,2.08,-5.94)
			var bowl_position = Vector3(-0.44,TABLE_TOP+0.38,0.24)
			get_node("Ladle").position = pot_position.lerp(bowl_position,eased)+Vector3(0,curve*0.24,0)
			get_node("Ladle").rotation.z = -maxf(0.0,p-0.64)*1.2
			get_node("Ladle/PourStream").visible = p > 0.64 and p < 0.94
			get_node("PlayerPlace/Bowl/Soup").visible = p > 0.75
			get_node("PlayerPlace/Bowl").position = Vector3(curve*0.025,curve*0.028,0)
			get_node("Noor/ArmRight").rotation.x = -0.6*curve
			get_node("Noor/ArmRight").rotation.z = 0.13+curve*0.33
		"bread":
			get_node("BreadBoard/TearingHands").visible = p < 0.85
			get_node("BreadBoard/TearingHands/LeftHand").position.x = -0.25-eased*0.065
			get_node("BreadBoard/TearingHands/RightHand").position = Vector3(0.25+eased*0.32,0.13+curve*0.15,0.09)
			get_node("BreadBoard/TornHalf").position = Vector3(0.12+eased*0.32,0.13+curve*0.18,0.0)
			get_node("BreadBoard/TornHalf").rotation.y = curve*0.26
			get_node("PassingBread").position = Vector3(-1.9+eased*1.32,TABLE_TOP+0.12+curve*0.14,-0.65+eased*0.28)
			get_node("Ada/ArmLeft").rotation.x = -0.72*curve
		"cup":
			get_node("PlayerPlace/Cup").position = Vector3(0.42+eased*0.23,curve*0.09,-0.09-eased*0.21)
			get_node("PlayerPlace/Cup").rotation.z = curve*0.055
			get_node("Mira").rotation.y = -0.31+curve*0.09
		"pepper":
			get_node("PepperShaker").position = Vector3(0.67,TABLE_TOP,-0.09).lerp(Vector3(-0.03,TABLE_TOP,-0.3),eased)+Vector3(0,curve*0.15,0)
			get_node("PepperShaker").rotation.z = sin(p*TAU*4)*curve*0.21
			get_node("PepperGrains").visible = p > 0.25 and p < 0.7
			get_node("Noor/ArmLeft").rotation.x = -0.52*curve
		"watch":
			get_node("PassingBread").position.x = -1.9+eased*1.5
			get_node("PassingBread").position.y = TABLE_TOP+0.12+curve*0.12
			get_node("Ladle").rotation.z = curve*0.15
			get_node("Ada/ArmLeft").rotation.x = -0.53*curve

func finish_gesture():
	# Explicit exit can settle immediately even while a menu has paused time.
	_finish_gesture()

func _finish_gesture():
	if not gesture_active: return
	var finished = gesture_action
	var completion = gesture_completion
	_stage_gesture(1.0)
	gesture_active = false
	gesture_completion = Callable()
	get_node("GestureCaption").visible = false
	get_node("PepperGrains").visible = false
	get_node("Ladle/PourStream").visible = false
	# End and reload share one staging source; no transient prop pose leaks into saves.
	_apply_saved_staging()
	gesture_finished.emit(finished)
	if completion.is_valid(): completion.call()

func _process(delta: float):
	if paper_sign == null or paused: return
	# Main has historically toggled AmbientMotion directly; honor that live setting.
	var current_reduced: bool = get_node("AmbientMotion").reduced
	if current_reduced != reduced: apply_preferences(current_reduced)
	if gesture_active:
		if reduced:
			_finish_gesture()
		else:
			gesture_elapsed += maxf(0.0,delta)
			_stage_gesture(gesture_elapsed / maxf(gesture_duration,0.001))
			if gesture_elapsed >= gesture_duration: _finish_gesture()
	if reduced: return
	decorative_elapsed += maxf(0.0,delta)
	var t = decorative_elapsed
	paper_sign.advance_secondary(delta,false)
	for i in range(10):
		var puff = get_node("Steam/Puff%d" % i)
		var base: Transform3D = _rest["Steam/Puff%d" % i]
		puff.position = base.origin+Vector3(sin(t*0.53+i*1.3)*0.033,fmod(t*0.085+i*0.083,0.8)-i*0.083,cos(t*0.43+i)*0.025)
		puff.scale = Vector3.ONE*(0.72+sin(t*0.71+i)*0.16)
	for i in range(14):
		var base: Transform3D = _rest["Condensation/Drop%d" % i]
		get_node("Condensation/Drop%d" % i).position.y = base.origin.y-fmod(t*0.018+float(i)*0.015,0.29)
	if not gesture_active:
		get_node("Ladle").position = _rest.Ladle.origin+Vector3(sin(t*0.56)*0.065,sin(t*0.73)*0.052,cos(t*0.56)*0.04)
		get_node("Ladle").rotation.z = sin(t*0.66)*0.12
		get_node("PassingBread").position = _rest.PassingBread.origin+Vector3((sin(t*0.36)+1)*0.61,sin(t*0.72)*0.035,sin(t*0.4)*0.055)
		get_node("Noor/ArmRight").rotation = Vector3(-0.2+sin(t*0.66)*0.1,0,0.12+sin(t*0.56)*0.075)
		get_node("Noor/ArmLeft").rotation.x = -0.19+sin(t*0.51)*0.065
		get_node("Ada/ArmLeft").rotation.x = -0.22+sin(t*0.36)*0.12
		get_node("Ada/ArmRight").rotation.z = -0.18+sin(t*0.45)*0.065
		get_node("PlayerPlace/Cup").rotation.z = sin(t*0.27)*0.009
		get_node("PlayerPlace/Bowl").position = _rest["PlayerPlace/Bowl"].origin+Vector3(sin(t*0.34)*0.012,0,sin(t*0.29)*0.01)
	var lines = ["Noor: The soup needs another minute.\nAda: The bread does not.","Mira: Lower Mill. Early tram tomorrow.\nNoor: Take the big thermos.","Ada: The duck has retired undefeated.\nNoor: Let it keep its title.","Mira: Someone kept the bent propeller.\nAda: It has a good opinion of this room."]
	get_node("ConversationThreads").text = lines[int(t/11.0)%lines.size()]
