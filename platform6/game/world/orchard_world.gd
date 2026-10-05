extends Node3D
# Saved choices own progression; the orchard only stages those choices.
signal beat_finished(beat: int)
const WOOD = Color("866047")
const LEAF = Color("657956")
const CREAM = Color("e7d5ac")
var factory: RefCounted
var snapshot: Dictionary = {}
var interactions: Node3D
var reduced := false
var paused := false
var decorative_elapsed := 0.0
var beat_active := false
var staged_beat := 0
var beat_elapsed := 0.0
var beat_completion: Callable
var route := "unselected"
var route_active := false
var route_elapsed := 0.0
var route_completion: Callable
var showing_rest := false

func build(value: Dictionary) -> Node3D:
	name = "World"
	factory = load("res://world/world_factory.gd").new()
	_build_landscape()
	_build_station()
	_build_cart()
	_build_beats()
	_build_rest_people()
	interactions = _node(self,"Interactions")
	var ambient = load("res://world/ambient_motion.gd").new()
	ambient.name = "AmbientMotion"
	add_child(ambient)
	_marker("Spawn",Vector3(0,0.12,6),Vector3(0,1.7,-7))
	_marker("OrchardView",Vector3(0,2.4,3),Vector3(0,2,-12))
	_marker("ObservationView",Vector3(-2.1,2.1,-2),Vector3(-4.2,1.2,-8))
	apply_state(value)
	return self

func _node(parent: Node3D, id: String, where := Vector3.ZERO) -> Node3D:
	var node = Node3D.new()
	node.name = id
	node.position = where
	parent.add_child(node)
	return node
func _marker(id: String, where: Vector3, look: Vector3):
	var marker = Marker3D.new()
	marker.name = id
	marker.position = where
	marker.set_meta("look_at",look)
	add_child(marker)
func _label(parent: Node3D, text_: String, where: Vector3, size_ := 25):
	factory.label(parent,text_,where,size_)
	var label = parent.get_child(parent.get_child_count()-1)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.pixel_size = 0.005
func _build_landscape():
	factory.box(self,"OrchardFloor",Vector3(0,-0.3,-5),Vector3(30,0.6,42),Color("697665"))
	factory.box(self,"CinderPath",Vector3(0,0.013,-5),Vector3(3.8,0.026,39),Color("a49679"),false)
	for x in [-14.7,14.7]: factory.box(self,"Boundary",Vector3(x,0.6,-5),Vector3(0.35,1.2,42),Color("424f49"))
	for z in [-25.7,15.7]: factory.box(self,"Boundary",Vector3(0,0.6,z),Vector3(30,1.2,0.35),Color("424f49"))
	var rows = _node(self,"OrchardRows")
	for x in [-10.5,-6.8,6.8,10.5]:
		for z in [-19.0,-13.2,-7.4,-1.6,4.2]:
			var tree = _node(rows,"PearTree",Vector3(x,0,z))
			tree.rotation.y = sin(x*0.7+z)*0.15
			tree.scale.y = 0.95+0.06*sin(z+x)
			factory.rounded(tree,"Trunk",Vector3(0,1.55,0),0.14,0.24,3.1,WOOD,true)
			for side in [-1.0,1.0]:
				var branch = factory.rounded(tree,"Branch",Vector3(side*0.47,2.54,0),0.055,0.11,1.5,WOOD)
				branch.rotation.z = -side*0.7
			for i in range(5):
				var crown = factory.orb(tree,Vector3(sin(i*2.3)*1.0,3.0+(i%2)*0.5,cos(i*2.3)*0.75),0.99,LEAF.lightened((i%3)*0.035))
				crown.scale = Vector3(1.0,0.68,0.85)
			for i in range(4):
				var fruit = factory.orb(tree,Vector3(sin(i*2.5)*0.94,2.72+(i%2)*0.23,cos(i*2.5)*0.65),0.115,Color("c4b269"))
				fruit.scale.y = 1.25
			factory.box(tree,"RootShadow",Vector3(0,0.019,0),Vector3(1.9,0.018,1.7),Color("556452"),false)
	for i in range(26):
		var leaf = factory.box(self,"FallenLeaf",Vector3(sin(i*2.7)*11,0.035,-19+i*1.3),Vector3(0.17,0.016,0.09),Color("b29b62"),false)
		leaf.rotation.y = i*1.1
	var tufts = _node(self,"GrassTufts")
	for i in range(40):
		var x = (-1.0 if i%2 == 0 else 1.0)*(2.5+(i%5)*1.7)
		var z = -22+(i*1.83 if i < 20 else (i-20)*1.79)
		for blade in range(3):
			var stem = factory.box(tufts,"Blade",Vector3(x+blade*0.07,0.13,z),Vector3(0.025,0.26+blade*0.03,0.045),Color("82916d"),false)
			stem.rotation.z = (blade-1)*0.24
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("344a59")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9bb2b8")
	env.ambient_light_energy = 0.52
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)
	var sun = DirectionalLight3D.new()
	sun.name = "LastEveningLight"
	sun.rotation_degrees = Vector3(-22,-65,0)
	sun.light_color = Color("f3c893")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	add_child(sun)
	factory.orb(self,Vector3(0,10,-32),1.3,Color("d4d8c5"))
	for i in range(9):
		var hill = factory.orb(self,Vector3(-27+i*7,-1.1,-37-(i%3)*3),1.0,Color("3c555d"))
		hill.name = "DistantHill"
		hill.scale = Vector3(9,3.3+(i%3)*0.8,5)

func _build_station():
	var station = _node(self,"StationBuilding",Vector3(8,0,9))
	factory.box(station,"Wall",Vector3(0,2,1.8),Vector3(11,4,0.3),Color("8d8069"))
	factory.box(station,"Roof",Vector3(0,4.16,0),Vector3(11.8,0.3,4.8),Color("45595b"),false)
	for x in [-5.2,5.2]: factory.box(station,"CanopyPost",Vector3(x,2,1.8),Vector3(0.17,4,0.17),WOOD)
	factory.box(self,"StationDoor",Vector3(8,1.6,10.64),Vector3(2,3.2,0.06),Color("29434b"),false)
	_label(station,"ORCHARD HALT",Vector3(0,3.45,0.2),35)
	for x in [4.2,11.8]:
		factory.box(self,"StationWindow",Vector3(x,2.2,10.61),Vector3(1.8,1.3,0.04),Color("eebf79"),false)
		var light = OmniLight3D.new()
		light.position = Vector3(x,2.6,8)
		light.light_color = Color("ffd59d")
		light.light_energy = 3
		light.omni_range = 8
		add_child(light)
	var bench = _node(self,"StationBench",Vector3(4.5,0,9.7))
	bench.set_meta("stationary_rest",true)
	factory.box(bench,"Seat",Vector3(0,0.5,0),Vector3(2.5,0.12,0.75),WOOD)
	factory.box(bench,"Back",Vector3(0,0.94,0.4),Vector3(2.5,0.7,0.1),WOOD,false)
	for x in [-0.95,0.95]: factory.box(bench,"Leg",Vector3(x,0.25,0),Vector3(0.12,0.5,0.6),Color("354b4c"),false)
	factory.box(self,"RailBed",Vector3(-8,0.03,12.8),Vector3(11,0.06,2.7),Color("575a52"),false)
	for z in [12.0,13.5]: factory.box(self,"Rail",Vector3(-8,0.12,z),Vector3(11,0.11,0.08),Color("9da6a2"),false)
	for i in range(13): factory.box(self,"Sleeper",Vector3(-13+i*0.9,0.08,12.75),Vector3(0.17,0.1,2.2),WOOD,false)

func _build_cart():
	var cart = _node(self,"Cart",Vector3(-3,0,2.1))
	cart.set_meta("physical_seating",true)
	factory.box(cart,"Deck",Vector3(0,0.48,0),Vector3(1.75,0.18,2.6),WOOD)
	factory.box(cart,"Seat",Vector3(0,0.87,0.7),Vector3(1.5,0.12,0.55),Color("ba976d"),false)
	factory.box(cart,"Back",Vector3(0,1.14,0.95),Vector3(1.5,0.55,0.1),WOOD,false)
	for x in [-0.96,0.96]:
		factory.box(cart,"Side",Vector3(x,0.86,0),Vector3(0.1,0.65,2.6),WOOD,false)
		for z in [-0.83,0.83]:
			var wheel = factory.rounded(cart,"Wheel",Vector3(x,0.32,z),0.34,0.34,0.12,Color("354d50"))
			wheel.rotation.z = PI/2
	factory.box(cart,"Handle",Vector3(0,0.55,-2),Vector3(0.1,0.1,1.5),WOOD,false)
	_label(cart,"ORCHARD / HAND CART",Vector3(0,1.23,1.02),17)

func _build_beats():
	var branch = factory.rounded(self,"PearBranch",Vector3(-5.45,3.14,-7.4),0.055,0.09,2.7,WOOD)
	branch.rotation.z = -PI/2
	factory.box(self,"PearStemSupport",Vector3(-4.2,3.12,-7.4),Vector3(0.045,0.15,0.045),WOOD,false)
	var pear = _node(self,"Pear",Vector3(-4.2,2.9,-7.4))
	factory.orb(pear,Vector3.ZERO,0.16,Color("d5bc65")).scale = Vector3(0.85,1.18,0.85)
	factory.rounded(pear,"Stem",Vector3(0,0.21,0),0.013,0.02,0.13,WOOD)
	var shed = _node(self,"PackingShed",Vector3(3.5,0,-18))
	factory.box(shed,"LeftWall",Vector3(-1.8,1.45,0),Vector3(2.1,2.9,0.25),Color("85735c"))
	factory.box(shed,"RightWall",Vector3(1.8,1.45,0),Vector3(2.1,2.9,0.25),Color("85735c"))
	factory.box(shed,"Lintel",Vector3(0,2.75,0),Vector3(1.5,0.3,0.25),WOOD,false)
	var roof = factory.box(shed,"Roof",Vector3(0,3.1,-0.8),Vector3(6.1,0.22,2.6),Color("475b59"),false)
	roof.rotation.x = 0.08
	factory.box(self,"PackingDoor",Vector3(3.5,1.25,-18.23),Vector3(1.55,2.5,0.08),Color("eebf79"),false)
	var packing_light = OmniLight3D.new()
	packing_light.name = "PackingDoorGlow"
	packing_light.position = Vector3(3.5,2,-17.6)
	packing_light.light_color = Color("ffd8a0")
	packing_light.light_energy = 2.4
	packing_light.omni_range = 5
	add_child(packing_light)
	var workers = _node(self,"Workers",Vector3(1.9,0,-17.65))
	for i in range(2):
		var person = _node(workers,"DistantWorker",Vector3(i*0.9,0,0))
		factory.person(person,Vector3.ZERO,[Color("71827b"),Color("b39b71")][i])
		person.rotation.y = PI/2
		var crate = _node(person,"EmptyCrate",Vector3(0,0.95,0.52))
		factory.box(crate,"Base",Vector3.ZERO,Vector3(0.65,0.06,0.48),WOOD,false)
		for x in [-0.32,0.32]: factory.box(crate,"Side",Vector3(x,0.16,0),Vector3(0.045,0.32,0.48),WOOD,false)
		for z in [-0.24,0.24]: factory.box(crate,"End",Vector3(0,0.16,z),Vector3(0.65,0.32,0.04),WOOD,false)
		for arm_id in ["ArmLeft","ArmRight"]: person.get_node(arm_id).rotation.x = -1.1
	var reflection = _node(self,"TrainReflection")
	for x in [-6.8,6.8]:
		for z in [-13.2,-7.4,-1.6]:
			var stripe = factory.box(reflection,"LightOnTrunk",Vector3(x-0.15,1.2,z+0.13),Vector3(0.045,1.6,0.23),Color("eebf79"),false)
			stripe.rotation.y = -0.4
	var light = OmniLight3D.new()
	light.name = "PassingTrainLight"
	light.position = Vector3(-4,2,-4)
	light.light_color = Color("ffdda7")
	light.light_energy = 1.8
	light.omni_range = 14
	reflection.add_child(light)
	var view = _node(self,"Observation",Vector3(-4.2,0,-8))
	factory.box(view,"OldCrate",Vector3(-0.7,0.3,0),Vector3(0.8,0.6,0.65),WOOD)
	factory.orb(view,Vector3(-0.65,0.66,0),0.11,Color("d5bc65"))
	_label(view,"ONE PEAR LEFT IN THE CRATE",Vector3(-0.6,0.86,0.1),13)

func _target(id: String, where: Vector3, title: String, value: Variant = null):
	var marker = Marker3D.new()
	marker.name = id + ("_" + str(value) if value != null else "")
	marker.position = where
	marker.set_meta("action_id",id)
	marker.set_meta("value",value)
	marker.set_meta("label",title)
	marker.add_to_group("interactables")
	interactions.add_child(marker)
func _rest_position() -> Vector3:
	if route == "bench": return Vector3(4.5,0,8.7)
	if route == "cart": return Vector3(-1.65,0,-3.9)
	return Vector3(0,0,-3)
func apply_state(value: Dictionary):
	snapshot = value.duplicate(true)
	route = str(snapshot.get("orchard",{}).get("route","unselected"))
	if not beat_active: _canonical_beat(int(snapshot.get("orchard",{}).get("beat",0)))
	for child in interactions.get_children():
		interactions.remove_child(child)
		child.free()
	var checkpoint = str(snapshot.get("orchard_checkpoint","arrival"))
	if checkpoint == "arrival":
		_target("orchard_route",Vector3(-1.6,0,4.2),"Cart · ride between the rows","cart")
		_target("orchard_route",Vector3(0,0,2.6),"Path · walk the orchard","walk")
		_target("orchard_route",Vector3(4.5,0,8.7),"Bench · stay at the halt","bench")
	elif checkpoint == "complete":
		_target("orchard_exit",_rest_position(),"Keep this quiet evening")
	else:
		var beat = int(snapshot.get("orchard",{}).get("beat",0))
		_target("orchard_finish" if beat >= 3 else "orchard_advance",_rest_position(),"End the evening" if beat >= 3 else "Stay for the next small moment")
		_target("orchard_arrival",Vector3(0,0,6),"Orchard halt · choose how to rest")
	_target("orchard_view",Vector3(-2.2,0,-7.4),"Crate · the pear nobody took","pear")
	get_node("Spawn").position = Vector3(0,0.12,6) if route == "unselected" else _rest_position()+Vector3(0,0.12,0)
	if not has_node("RestView"):
		_marker("RestView",Vector3(0,2,0),Vector3(0,2,-12))
	var view = get_node("RestView")
	view.position = Vector3(5.9,2.4,10.4) if route == "bench" else (Vector3(0.4,2.6,0.3) if route == "cart" else Vector3(0,1.7,-3))
	view.set_meta("look_at",Vector3(-1.5,2,-11))
	get_node("Cart").set_meta("selected",route == "cart")
	get_node("StationBench").set_meta("selected",route == "bench")
	set_meta("orchard_route",route)
	set_meta("orchard_checkpoint",checkpoint)
	apply_preferences(bool(snapshot.get("settings",{}).get("reduced_motion",false)))
func apply_snapshot(value: Dictionary): apply_state(value)
func _canonical_beat(beat: int):
	get_node("Pear").position = Vector3(-4.2,0.18,-7.4) if beat >= 1 else Vector3(-4.2,2.9,-7.4)
	get_node("Workers").position = Vector3(4.3,0,-17.65) if beat >= 2 else Vector3(1.9,0,-17.65)
	get_node("Workers").visible = beat < 2
	get_node("TrainReflection").visible = false
	get_node("TrainReflection/PassingTrainLight").position = Vector3(-4,2,-15 if beat >= 3 else -4)
	get_node("Cart").position = Vector3(-3,0,-3.9 if route == "cart" else 2.1)
	get_node("Cart").rotation = Vector3.ZERO
func begin_beat(beat: int, callback: Callable = Callable()):
	if route_active: finish_route()
	if beat_active: finish_beat()
	staged_beat = clampi(beat,0,3)
	beat_elapsed = 0
	beat_completion = callback
	beat_active = true
	if reduced and not paused:
		finish_beat()
		return
	_canonical_beat(maxi(0,staged_beat-1))
	if staged_beat == 2: get_node("Workers").visible = true
	if staged_beat == 3: get_node("TrainReflection").visible = true
func finish_beat():
	if not beat_active: return
	beat_active = false
	_canonical_beat(int(snapshot.get("orchard",{}).get("beat",0)))
	var callback = beat_completion
	beat_completion = Callable()
	beat_finished.emit(staged_beat)
	if callback.is_valid(): callback.call()
func apply_preferences(value: bool):
	reduced = value
	if has_node("AmbientMotion"): get_node("AmbientMotion").apply_preferences(value)
	if reduced and beat_active and not paused: finish_beat()
	if reduced and route_active and not paused: finish_route()
func set_paused(value: bool):
	paused = value
	if has_node("AmbientMotion"): get_node("AmbientMotion").set_process(not value)
	if not paused and reduced and beat_active: finish_beat()
	if not paused and reduced and route_active: finish_route()
func _process(delta: float):
	if paused: return
	if not reduced: decorative_elapsed += delta
	if route_active and not reduced:
		route_elapsed += delta
		var travel = clampf(route_elapsed/3.2,0,1)
		get_node("Cart").position.z = lerpf(2.1,-3.9,travel)
		get_node("RestView").position = get_node("Cart").position+Vector3(3.4,2.6,4.2)
		for wheel in get_node("Cart").get_children():
			if str(wheel.name).begins_with("Wheel"): wheel.rotation.x = travel*6/0.34
		if travel >= 1: finish_route()
	if not beat_active or reduced: return
	beat_elapsed += delta
	var t = clampf(beat_elapsed/2.2,0,1)
	if staged_beat == 1:
		get_node("Pear").position.y = lerpf(2.9,0.18,t*t)
	elif staged_beat == 2:
		get_node("Workers").position.x = lerpf(1.9,4.3,t)
	elif staged_beat == 3:
		get_node("TrainReflection/PassingTrainLight").position.z = lerpf(4,-15,t)
	if route == "cart":
		get_node("Cart").position.z = -3.9 - sin(t*PI)*0.15
		get_node("Cart").rotation.x = sin(t*TAU)*0.008
	if t >= 1: finish_beat()
func rest_view_transform() -> Transform3D:
	var marker = get_node("RestView")
	return Transform3D(Basis.looking_at(marker.get_meta("look_at")-marker.position,Vector3.UP),marker.position)
func observation_view_transform() -> Transform3D:
	var marker = get_node("ObservationView")
	return Transform3D(Basis.looking_at(marker.get_meta("look_at")-marker.position,Vector3.UP),marker.position)

func _seated_person(parent: Node3D, id: String, where: Vector3, coat: Color) -> Node3D:
	var person = _node(parent,id,where)
	factory.person(person,Vector3.ZERO,coat)
	person.position.y -= 0.32
	for limb_id in ["LegLeft","LegRight"]:
		person.get_node(limb_id).rotation.x = -PI/2
	person.get_node("Satchel").visible = false
	person.get_node("HairBun").visible = false
	person.rotation.y = PI
	person.set_meta("seated",true)
	return person
func _build_rest_people():
	var rider = _seated_person(get_node("Cart"),"SeatedRider",Vector3(0,0.55,0.7),Color("68858d"))
	rider.visible = false
	var driver = _node(get_node("Cart"),"OrchardDriver",Vector3(0,0,-2.65))
	factory.person(driver,Vector3.ZERO,Color("b29a74"))
	driver.rotation.y = PI
	var sitter = _seated_person(get_node("StationBench"),"SeatedRider",Vector3(0,0.55,0),Color("68858d"))
	sitter.visible = false
func set_rest_view(value: bool):
	showing_rest = value
	get_node("Cart/SeatedRider").visible = route == "cart" and (value or route_active)
	get_node("StationBench/SeatedRider").visible = route == "bench" and value
func begin_route(callback: Callable = Callable()):
	if route_active: finish_route()
	route_completion = callback
	route_elapsed = 0
	route_active = true
	set_rest_view(true)
	if route != "cart" or reduced:
		if not paused: finish_route()
		return
	get_node("Cart").position.z = 2.1
	get_node("RestView").position = get_node("Cart").position+Vector3(3.4,2.6,4.2)
func finish_route():
	if not route_active: return
	route_active = false
	get_node("Cart").position.z = -3.9 if route == "cart" else 2.1
	if route == "cart": get_node("RestView").position = Vector3(0.4,2.6,0.3)
	set_rest_view(showing_rest)
	var callback = route_completion
	route_completion = Callable()
	if callback.is_valid(): callback.call()
