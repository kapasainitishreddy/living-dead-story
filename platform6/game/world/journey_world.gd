extends Node3D
# Ten intentionally small authored stops. The model owns memory and choices;
# this world only presents their physical consequences, with no score or clock.
const CREAM = Color("f1e5cc")
const WOOD = Color("8f6b53")
const INK = Color("29384b")
const WARM = Color("eebf79")
const IDS = ["rain_town","unsent_letters_library","arcade","beach_before_sunrise","winter_orchard","rest_room","failed_things_festival","sunrise_cafe","no_destination_road","fireflies"]
var factory: RefCounted
var snapshot: Dictionary = {}
var campaign: Dictionary = {}
var destination: Dictionary = {}
var journey_id := ""
var scene_kind := "train"
var visit_count := 0
var reduced_motion := false
var paused := false
var interactions: Node3D
var scenery: Node3D
var activity: Node3D
var palette: Array[Color] = []
var activity_type := "observation"
var time_state := "day"
var weather_state := "clear"
var motion_elapsed := 0.0
var _decorative: Array[Dictionary] = []
var _activity_state: Dictionary = {}

func build(journey_snapshot: Dictionary, campaign_snapshot: Dictionary, destination_dictionary: Dictionary = {}) -> Node3D:
	factory = load("res://world/world_factory.gd").new()
	name = "World"
	snapshot = journey_snapshot.duplicate(true)
	campaign = campaign_snapshot.duplicate(true)
	destination = destination_dictionary.duplicate(true)
	journey_id = str(destination.get("journey_id",snapshot.get("journey_id",snapshot.get("current_destination",""))))
	scene_kind = str(snapshot.get("mode",snapshot.get("scene_kind","destination" if not destination.is_empty() else "train")))
	if scene_kind != "train" and destination.is_empty(): scene_kind = "train"
	visit_count = _visits_for(journey_id)
	var colors = destination.get("palette",["344754","b39a75","e9d2a0"])
	for i in range(3): palette.append(Color(str(colors[i])) if colors is Array and colors.size() > i else [INK,WOOD,WARM][i])
	var time_options = destination.get("available_time_states",["day"])
	time_state = str(destination.get("time_state",time_options[visit_count%time_options.size()] if time_options is Array and not time_options.is_empty() else "day"))
	var weather_options = destination.get("weather_profile",{}).get("states",["clear"])
	weather_state = str(destination.get("weather_state",weather_options[visit_count%weather_options.size()] if weather_options is Array and not weather_options.is_empty() else "clear"))
	set_meta("time_state",time_state)
	set_meta("weather_state",weather_state)
	set_meta("scene_kind",scene_kind)
	set_meta("journey_id",journey_id)
	set_meta("visits",visit_count)
	scenery = _node(self,"Scenery")
	interactions = _node(self,"Interactions")
	_build_ground()
	_build_lighting()
	var spawn = Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = Vector3(0,0.12,4.8)
	spawn.set_meta("look_at",Vector3(0,1.3,-2.0))
	add_child(spawn)
	if scene_kind == "train": _build_train()
	else:
		_build_destination()
		_build_npc()
		_build_activity()
		_apply_local_state()
		_build_weather()
		_target("journey_activity",Vector3(-2,0,-0.9),"Trace the stars" if journey_id == "fireflies" else str(destination.get("activity_prompt","Spend a little time here")))
		_target("journey_story",Vector3(2.8,0,-0.9),"Talk with " + _npc_name())
		_build_exits()
	var ambient = load("res://world/ambient_motion.gd").new()
	ambient.name = "AmbientMotion"
	add_child(ambient)
	apply_preferences(bool(campaign.get("settings",{}).get("reduced_motion",false)))
	return self

func _ready():
	# ambient_motion discovers its children in its own _ready before this callback.
	apply_preferences(reduced_motion)

func _node(parent: Node3D, id: String, where: Vector3 = Vector3.ZERO) -> Node3D:
	var value = Node3D.new()
	value.name = id
	value.position = where
	parent.add_child(value)
	return value

func _box(parent: Node3D, id: String, where: Vector3, size: Vector3, color: Color, solid: bool = false) -> Node3D:
	return factory.box(parent,id,where,size,color,solid)

func _orb(parent: Node3D, id: String, where: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var value = factory.orb(parent,where,radius,color)
	value.name = id
	return value

func _label(parent: Node3D, id: String, text: String, where: Vector3, size: int = 23, pixel: float = 0.0045) -> Label3D:
	var value = Label3D.new()
	value.name = id
	value.text = text
	value.position = where
	value.font_size = size
	value.pixel_size = pixel
	value.modulate = CREAM
	value.outline_modulate = INK
	value.outline_size = 3
	value.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	parent.add_child(value)
	return value

func _target(id: String, where: Vector3, text: String):
	var value = Marker3D.new()
	value.name = id
	value.position = where
	value.set_meta("action_id",id)
	value.set_meta("value",journey_id)
	value.set_meta("label",text)
	value.add_to_group("interactables")
	interactions.add_child(value)

func _visits_for(id: String) -> int:
	var visits = snapshot.get("visits",{})
	if visits is Dictionary:
		var count = visits.get(id,0)
		if count is Dictionary: return int(count.get("count",count.get("visits",0)))
		return int(count)
	if visits is Array: return visits.count(id)
	return 0

func _build_ground():
	var floor_color = palette[1].darkened(0.08)
	if scene_kind == "train": floor_color = Color("786858")
	elif journey_id == "beach_before_sunrise": floor_color = Color("bbaa89")
	elif journey_id == "winter_orchard": floor_color = Color("a7b7b6")
	elif journey_id == "fireflies": floor_color = Color("46594e")
	_box(self,"Ground",Vector3(0,-0.22,0),Vector3(14,0.44,14),floor_color,true)
	if journey_id == "fireflies" and scene_kind != "train":
		get_node("Ground").get_child(0).hide()
	# The visible curbs contain movement, while keeping the camera side low.
	for x in [-6.9,6.9]: _box(self,"BoundarySide",Vector3(x,0.6,0),Vector3(0.2,1.2,14),palette[0],true)
	_box(self,"BoundaryBack",Vector3(0,0.55,-6.9),Vector3(14,1.1,0.2),palette[0],true)
	var front_boundary = _box(self,"FrontMovementBoundary",Vector3(0,0.55,6.9),Vector3(14,1.1,0.2),palette[0],true)
	front_boundary.get_child(0).hide()
	if journey_id == "fireflies" and scene_kind != "train":
		for boundary in get_children():
			if str(boundary.name).begins_with("Boundary"): boundary.get_child(0).hide()
	if scene_kind != "train" and journey_id != "fireflies":
		_label(scenery,"DestinationTitle",str(destination.get("title",journey_id.replace("_"," "))).to_upper(),Vector3(0,3.65,-6.45),34,0.007)
		_label(scenery,"UnhurriedNote","STAY A WHILE. LEAVE WHEN YOU LIKE.",Vector3(0,3.26,-6.43),17,0.004)

func _build_lighting():
	var environment = WorldEnvironment.new()
	environment.name = "JourneyEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = palette[0].darkened({"dawn":0.12,"day":0.02,"dusk":0.22,"night":0.43}.get(time_state,0.23))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = palette[2]
	env.ambient_light_energy = {"dawn":0.65,"day":0.78,"dusk":0.61,"night":0.47}.get(time_state,0.65)
	env.fog_enabled = weather_state == "mist"
	env.fog_light_color = palette[1]
	env.fog_density = 0.012 if weather_state == "mist" else 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.name = "SoftJourneyLight"
	sun.rotation_degrees = Vector3(-43,-27,0)
	sun.light_color = {"dawn":Color("edbd96"),"day":Color("ffedce"),"dusk":Color("dfb6b0"),"night":Color("aebdcc")}.get(time_state,palette[2]).lerp(palette[2],float(destination.get("lighting_profile",{}).get("warmth",0.35)))
	sun.light_energy = {"dawn":0.48,"day":0.9,"dusk":0.55,"night":0.22}.get(time_state,0.7)
	add_child(sun)
	var warm = OmniLight3D.new()
	warm.name = "UnhurriedLamp"
	warm.position = Vector3(0,3.8,-1.4)
	warm.light_color = Color("ffe0ae")
	warm.light_energy = 2.3
	warm.omni_range = 10
	warm.shadow_enabled = false
	add_child(warm)
	if journey_id == "fireflies" and scene_kind != "train":
		env.background_color = Color("141d38")
		env.ambient_light_color = Color("8b9ec0")
		env.ambient_light_energy = 0.72
		env.fog_enabled = false
		sun.light_color = Color("a3b5df")
		sun.light_energy = 0.7
		warm.light_energy = 0.0

func _build_train():
	_box(scenery,"CarriageBack",Vector3(0,2.3,-6.65),Vector3(13.2,4.6,0.25),Color("a49b88"),true)
	for x in [-6.5,6.5]:
		_box(scenery,"CarriageWall",Vector3(x,1.8,0),Vector3(0.25,3.6,13.2),Color("b6ad98"),true)
		for z in [-4.4,-0.8,2.8]:
			_box(scenery,"WindowFrame",Vector3(x*0.97,2.3,z),Vector3(0.08,1.7,2.45),WOOD)
			_box(scenery,"Window",Vector3(x*0.96,2.3,z),Vector3(0.08,1.46,2.17),Color("78979e"))
			_box(scenery,"WindowHorizon",Vector3(x*0.952,2.03,z),Vector3(0.04,0.14,2.17),Color("a1ac90"))
			for offset in [-0.96,0.96]: _box(scenery,"WindowCurtain",Vector3(x*0.95,2.3,z+offset),Vector3(0.07,1.45,0.23),Color("9a7055"))
	var seats = _node(scenery,"TrainSeats")
	for x in [-4.7,4.7]:
		for z in [-2.8,1.2]:
			var seat = _node(seats,"Seat",Vector3(x,0,z))
			_box(seat,"Cushion",Vector3(0,0.52,0),Vector3(1.7,0.3,1.6),Color("546d72"),true)
			_box(seat,"SeatBack",Vector3(signf(x)*0.68,1.0,0),Vector3(0.22,1.2,1.6),Color("3d555d"),true)
			for zz in [-0.65,0.65]: _box(seat,"SeatLeg",Vector3(0,0.2,zz),Vector3(1.4,0.4,0.08),INK)
	var board = _node(scenery,"DestinationBoard",Vector3(0,2.25,-6.38))
	_box(board,"BoardFrame",Vector3.ZERO,Vector3(5.3,2.0,0.18),WOOD)
	_box(board,"BoardFace",Vector3(0,0,0.105),Vector3(5.04,1.73,0.025),INK)
	_label(board,"BoardTitle","THE NEXT SMALL JOURNEY",Vector3(0,0.52,0.13),29,0.006)
	var history = snapshot.get("board_history",snapshot.get("history",snapshot.get("recent_destinations",[])))
	board.set_meta("history",history.duplicate(true) if history is Array else [])
	var board_text = "RAIN / LETTERS / ARCADE / DAWN\nORCHARD / REST / FESTIVAL / CAFE\nNO DESTINATION / FIREFLIES"
	if history is Array and not history.is_empty(): board_text = "LAST STOP: " + str(history[-1]).replace("_"," ").to_upper() + "\nTHERE IS STILL NO HURRY"
	_label(board,"BoardChoices",board_text,Vector3(0,-0.12,0.14),19,0.005)
	_target("journey_board",Vector3(0,0,-4.6),"Choose a destination")
	var desk = _node(scenery,"WritingDesk",Vector3(-2.5,0,-2.4))
	_box(desk,"DeskTop",Vector3(0,1.0,0),Vector3(1.6,0.13,1.0),WOOD,true)
	for x in [-0.63,0.63]: _box(desk,"DeskLeg",Vector3(x,0.48,0),Vector3(0.12,0.96,0.75),INK)
	_box(desk,"Notebook",Vector3(0,1.09,0),Vector3(0.66,0.035,0.49),CREAM)
	for i in range(4): _box(desk,"NotebookLine",Vector3(0,1.11,-0.13+i*0.08),Vector3(0.53,0.005,0.01),Color("9b9a89"))
	_box(desk,"Pencil",Vector3(0.46,1.11,0.02),Vector3(0.034,0.025,0.43),WARM)
	_target("journey_writing",Vector3(-2.5,0,-0.9),"Write something private")
	var shelf = _node(scenery,"SouvenirShelf",Vector3(4.1,1.6,-5.9))
	_box(shelf,"ShelfBoard",Vector3.ZERO,Vector3(3.7,0.15,0.75),WOOD)
	_label(shelf,"ShelfNote","THINGS YOU HAVE KEPT",Vector3(0,0.94,0.04),19,0.004)
	var kept = 0
	for id in IDS:
		if _visits_for(id) <= 0: continue
		var memory = _node(shelf,"Remembered_"+id,Vector3(-1.5+(kept%5)*0.7,0.22+(kept/5)*0.42,0))
		memory.set_meta("journey_id",id)
		memory.set_meta("visits",_visits_for(id))
		if id == "unsent_letters_library": _box(memory,"UnsentEnvelope",Vector3.ZERO,Vector3(0.44,0.08,0.25),CREAM)
		elif id == "arcade": factory.rounded(memory,"Button",Vector3.ZERO,0.13,0.13,0.08,palette[2])
		elif id == "winter_orchard": _box(memory,"Twig",Vector3.ZERO,Vector3(0.04,0.33,0.04),WOOD)
		else: _orb(memory,"KeptObject",Vector3.ZERO,0.16,[Color("88aab0"),WARM,Color("a798b2")][kept%3]).scale = Vector3(1,0.7,1)
		kept += 1
	_label(scenery,"CarriageTitle","A TRAIN WITH TIME TO SPARE",Vector3(0,4.0,-6.36),30,0.006)
	_box(scenery,"HomeDoor",Vector3(4.7,1.5,6.4),Vector3(1.8,3,0.16),Color("6f7c73"))
	_label(scenery,"HomeDoorNote","HOME WHEN YOU LIKE",Vector3(4.7,2.7,6.28),21,0.004).rotation.y = PI
	_target("journey_home",Vector3(4.7,0,4.8),"Go home")

func _build_exits():
	for x in [-4.6,4.6]:
		var door = _node(scenery,"TrainExit" if x < 0 else "HomeExit",Vector3(x,0,6.3))
		_box(door,"DoorFrame",Vector3(0,1.42,0),Vector3(1.9,2.84,0.16),palette[0])
		_box(door,"WarmPanel",Vector3(0,1.6,-0.095),Vector3(1.53,1.6,0.05),palette[2].darkened(0.18))
		_label(door,"ExitName","TRAIN" if x < 0 else "HOME",Vector3(0,2.7,-0.14),26,0.005).rotation.y = PI
		if journey_id == "fireflies":
			door.get_node("DoorFrame").hide()
			door.get_node("WarmPanel").hide()
			door.get_node("ExitName").visibility_range_end = 3.5
	_target("journey_return_train",Vector3(-4.6,0,4.8),"Return to the train")
	_target("journey_home",Vector3(4.6,0,4.8),"Go home")

func _build_destination():
	match journey_id:
		"rain_town": _rain_town()
		"unsent_letters_library": _library()
		"arcade": _arcade()
		"beach_before_sunrise": _beach()
		"winter_orchard": _orchard()
		"rest_room": _rest_room()
		"failed_things_festival": _festival()
		"sunrise_cafe": _cafe()
		"no_destination_road": _road()
		"fireflies": _fireflies()
		_: _rest_room()
	var memory = _node(scenery,"RevisitMemory",Vector3(-5.5,0,-0.7))
	memory.set_meta("visits",visit_count)
	if visit_count > 0:
		# Nothing becomes a trophy. An ordinary object moves as the place lives on.
		_box(memory,"MovedStool",Vector3(0,0.35,0),Vector3(0.6,0.12,0.6),WOOD)
		_box(memory,"SetAsideCup",Vector3(0.16,0.52,0),Vector3(0.12,0.18,0.12),palette[2])
		var memory_note = _label(memory,"PassageOfTime","A cup has been set aside.",Vector3(0,0.92,0),15,0.003)
		if journey_id == "fireflies": memory_note.visibility_range_end = 3.5

func _rain_town():
	var shop = _node(scenery,"RainShop",Vector3(-4.4,0,-4.7))
	_box(shop,"ShopFront",Vector3(0,1.4,0),Vector3(3.8,2.8,1.5),palette[0],true)
	_box(shop,"ShopWindow",Vector3(0,1.55,0.77),Vector3(2.9,1.55,0.07),Color("dab674"))
	_box(shop,"SlopingRoof",Vector3(0,3.03,0.18),Vector3(4.3,0.19,2.05),Color("576a73")).rotation.x = -0.13
	_box(shop,"RoofGutter",Vector3(0,2.96,1.13),Vector3(4.3,0.15,0.18),Color("8b9fa4"))
	_box(shop,"Downpipe",Vector3(1.93,1.45,1.12),Vector3(0.12,2.9,0.12),Color("8b9fa4"))
	_label(shop,"ShopName","THE RAIN REPAIR SHOP",Vector3(0,2.42,0.82),20,0.004)
	for i in range(3):
		factory.rounded(scenery,"RainBarrel",Vector3(4.6+i*0.44,0.43,-5.2),0.2,0.17,0.86,Color("719493"))
	var rain = _node(scenery,"Rain")
	for i in range(42):
		var drop = _box(rain,"Drop",Vector3(-5.8+(i*1.71)-floor(i*1.71/11.6)*11.6,1.8+(i%5)*0.45,-5.8+(i%7)*1.08),Vector3(0.016,0.24,0.016),Color("a4c7cb"))
		drop.rotation.z = -0.14
	for x in [-4.7,4.6]: _orb(scenery,"RainPuddle",Vector3(x,0.025,1.8),0.55,Color("668b94")).scale = Vector3(1.8,0.035,0.75)

func _library():
	var shelves = _node(scenery,"LibraryShelves")
	_box(shelves,"LibraryBackWall",Vector3(0,2.1,-6.5),Vector3(13,4.2,0.22),palette[0],true)
	for x in [-4.6,0,4.6]:
		var row = _node(shelves,"ShelfRow",Vector3(x,0,-5.7))
		for side in [-1.55,1.55]: _box(row,"ShelfUpright",Vector3(side,1.65,0),Vector3(0.13,3.3,0.8),WOOD,true)
		for y in [0.4,1.2,2.0,2.8]:
			_box(row,"Shelf",Vector3(0,y,0),Vector3(3.2,0.1,0.9),WOOD)
			for i in range(7):
				var book = _box(row,"UnsentVolume",Vector3(-1.26+i*0.4,y+0.23,0.1),Vector3(0.2,0.44,0.52),[palette[1],palette[2],Color("7d8e8a")][i%3])
				book.rotation.z = 0.1 if i%4 == 0 else 0
	_label(shelves,"SortingNote","YOU MAY LEAVE A LETTER UNFINISHED",Vector3(0,3.13,-4.9),22,0.005)
	for x in [-5.5,5.5]:
		_box(scenery,"ReadingChair",Vector3(x,0.45,0),Vector3(0.8,0.18,0.8),palette[1],true)
		_box(scenery,"ReadingChairBack",Vector3(x,0.95,-0.38),Vector3(0.8,0.95,0.1),WOOD)

func _arcade():
	var cabinets = _node(scenery,"ArcadeCabinets")
	for x in [-4.8,-2.4,2.4,4.8]:
		var cabinet = _node(cabinets,"Cabinet",Vector3(x,0,-5.0))
		_box(cabinet,"CabinetBody",Vector3(0,1.1,0),Vector3(1.6,2.2,1.2),palette[0],true)
		_box(cabinet,"ScreenFrame",Vector3(0,1.65,0.64),Vector3(1.38,0.94,0.07),palette[1])
		_box(cabinet,"Screen",Vector3(0,1.65,0.69),Vector3(1.15,0.7,0.02),Color("427575"))
		_box(cabinet,"ControlShelf",Vector3(0,0.98,0.83),Vector3(1.6,0.15,0.65),palette[1])
		factory.rounded(cabinet,"Joystick",Vector3(-0.34,1.14,0.83),0.038,0.038,0.19,INK)
		_orb(cabinet,"JoystickGrip",Vector3(-0.34,1.25,0.83),0.08,palette[2])
		for dx in [0.16,0.39]: factory.rounded(cabinet,"Button",Vector3(dx,1.08,0.87),0.07,0.07,0.04,Color("c78674"))
	var floor = _node(scenery,"CheckerFloor")
	for x in range(-6,7):
		for z in range(-6,7):
			if (x+z)%2 == 0: _box(floor,"Checker",Vector3(x,0.014,z),Vector3(0.97,0.026,0.97),palette[0].lightened(0.16))
	_label(cabinets,"ArcadeNote","PLAY WITHOUT A HIGH SCORE",Vector3(0,3.1,-5.1),24,0.005)

func _beach():
	var sea = _node(scenery,"BeforeSunriseSea")
	_box(sea,"StillSea",Vector3(0,0.04,-5.3),Vector3(13.3,0.06,2.6),Color("66898f"))
	for i in range(4): _box(sea,"ShoreFoam",Vector3(0,0.082,-4.2-i*0.47),Vector3(12.6,0.012,0.035),Color("b3c5bd"))
	var lighthouse = _node(scenery,"Lighthouse",Vector3(5.2,0,-5.25))
	factory.rounded(lighthouse,"Tower",Vector3(0,1.65,0),0.39,0.65,3.3,CREAM,true)
	factory.rounded(lighthouse,"LanternRoom",Vector3(0,3.46,0),0.53,0.53,0.52,palette[0])
	_orb(lighthouse,"Lantern",Vector3(0,3.48,0),0.29,WARM)
	factory.rounded(lighthouse,"Roof",Vector3(0,3.89,0),0.04,0.69,0.35,palette[1])
	_orb(sea,"DawnSun",Vector3(-4.5,1.25,-6.65),0.55,Color("ce9e82")).scale.z = 0.2
	for i in range(7): _orb(scenery,"SandShell",Vector3(-5.4+i*1.7,0.025,1.5+(i%3)*0.35),0.07,CREAM).scale.y = 0.35

func _orchard():
	var trees = _node(scenery,"BareOrchard")
	for pos in [Vector3(-5,0,-4.8),Vector3(-1.2,0,-5.5),Vector3(2.5,0,-5.4),Vector3(5.3,0,-4.0)]:
		var tree = _node(trees,"BareTree",pos)
		factory.rounded(tree,"Trunk",Vector3(0,1.15,0),0.15,0.22,2.3,WOOD,true)
		for i in range(5):
			var twig = _box(tree,"Branch",Vector3((i%2*2-1)*0.43,2.08+(i/2)*0.23,0.1*(i%3)),Vector3(0.09,1.25,0.09),WOOD)
			twig.rotation.z = (i%2*2-1)*0.72
		_orb(tree,"SnowAtRoots",Vector3(0,0.035,0),0.55,CREAM).scale = Vector3(1,0.08,0.85)
	for i in range(3):
		var crate = _node(scenery,"OrchardCrate",Vector3(-5.5+i*0.65,0.33,1.1))
		_box(crate,"CrateBody",Vector3.ZERO,Vector3(0.6,0.6,0.55),palette[1],true)
		for j in range(4): _box(crate,"CrateSlat",Vector3(0,-0.18+j*0.12,0.285),Vector3(0.59,0.07,0.028),WOOD)
	_label(trees,"OrchardNote","THE TREES DO NOT NEED AN ANSWER TODAY",Vector3(0,3.2,-5.2),21,0.0046)

func _rest_room():
	_box(scenery,"RestBackWall",Vector3(0,2.1,-6.4),Vector3(13,4.2,0.25),Color("8b9b93"),true)
	_box(scenery,"RestWindowFrame",Vector3(0,2.25,-6.21),Vector3(4.8,2.1,0.15),WOOD)
	_box(scenery,"RestWindow",Vector3(0,2.25,-6.1),Vector3(4.5,1.82,0.05),Color("a0b6b0"))
	_box(scenery,"RestWindowMullion",Vector3(0,2.25,-6.04),Vector3(0.07,1.92,0.04),CREAM)
	var cushions = _node(scenery,"RestCushions")
	for x in [-5.1,4.8]:
		var couch = _node(cushions,"SoftBench",Vector3(x,0,-3.8))
		_box(couch,"Bench",Vector3(0,0.35,0),Vector3(2.3,0.6,1.25),palette[0],true)
		for dx in [-0.68,0,0.68]:
			_orb(couch,"Cushion",Vector3(dx,0.73,-0.24),0.44,palette[1]).scale = Vector3(0.9,0.53,0.8)
		_box(couch,"FoldedBlanket",Vector3(0.5,0.68,0.4),Vector3(0.8,0.08,0.52),palette[2])
	factory.rounded(scenery,"RestRug",Vector3(0,0.018,0.1),2.65,2.65,0.025,Color("aaa28c"))
	_label(scenery,"RestNote","YOU CAN SIMPLY SIT HERE",Vector3(0,3.58,-6.03),23,0.005)

func _festival():
	var plinths = _node(scenery,"RejectedObjectPlinths")
	for i in range(4):
		var plinth = _node(plinths,"ObjectStand",Vector3(-5.1+i*3.4,0,-4.6))
		_box(plinth,"Plinth",Vector3(0,0.6,0),Vector3(1.4,1.2,1.25),palette[1],true)
		if i == 0:
			_box(plinth,"BentChairSeat",Vector3(0,1.34,0),Vector3(0.8,0.14,0.65),WOOD).rotation.z = 0.18
			_box(plinth,"OneChairLeg",Vector3(-0.2,1.63,0.2),Vector3(0.07,0.6,0.07),WOOD).rotation.z = 0.28
		elif i == 1:
			_orb(plinth,"CrackedVase",Vector3(0,1.55,0),0.32,palette[0]).scale = Vector3(0.7,1.0,0.7)
			_box(plinth,"VaseCrack",Vector3(0.05,1.55,0.227),Vector3(0.025,0.43,0.016),CREAM).rotation.z = -0.17
		elif i == 2:
			_box(plinth,"UnfinishedMachine",Vector3(0,1.44,0),Vector3(0.9,0.46,0.67),palette[0])
			factory.rounded(plinth,"UnusedWheel",Vector3(0.38,1.51,0.28),0.18,0.18,0.09,palette[2]).rotation.x = PI/2
		else: _box(plinth,"RejectedCanvas",Vector3(0,1.65,0),Vector3(0.92,0.8,0.09),palette[2]).rotation.z = -0.08
		_label(plinth,"ObjectCaption",["STILL A CHAIR","IT HELD WATER ONCE","A GOOD FIRST TRY","AN UNFINISHED SKY"][i],Vector3(0,0.98,0.65),15,0.0034)
	var flags = _node(scenery,"FestivalFlags")
	for i in range(12):
		var flag = _box(flags,"Flag",Vector3(-5.5+i,3.2+sin(i*0.4)*0.2,-5.1),Vector3(0.4,0.55,0.04),[palette[0],palette[1],palette[2]][i%3])
		flag.rotation.z = 0.1
	_label(flags,"FestivalNote","A FESTIVAL FOR THINGS THAT DID NOT WORK",Vector3(0,3.92,-5.1),20,0.0045)

func _cafe():
	var awning = _node(scenery,"DawnAwning",Vector3(0,0,-4.7))
	_box(awning,"CafeBack",Vector3(0,1.5,-1.2),Vector3(11,3,0.24),palette[0],true)
	for x in [-5.1,5.1]: factory.rounded(awning,"AwningPost",Vector3(x,1.65,0.7),0.055,0.055,3.3,WOOD,true)
	_box(awning,"Awning",Vector3(0,3.25,-0.15),Vector3(11.3,0.16,2.3),palette[2]).rotation.x = -0.1
	for i in range(11): _box(awning,"AwningStripe",Vector3(-5+i,3.36,-0.15),Vector3(0.35,0.035,2.26),palette[1]).rotation.x = -0.1
	_label(awning,"CafeSign","THE EARLY TABLE",Vector3(0,2.5,-1.05),28,0.006)
	for x in [-5.1,4.9]:
		var table = _node(scenery,"CafeTable",Vector3(x,0,0.2))
		factory.rounded(table,"RoundTable",Vector3(0,0.8,0),0.58,0.58,0.08,WOOD,true)
		factory.rounded(table,"TableLeg",Vector3(0,0.4,0),0.06,0.08,0.8,palette[0])
		_cup(table,"SomeoneElseCup",Vector3(0.1,0.87,0),palette[2])
		_box(table,"FoldedNewspaper",Vector3(-0.22,0.865,0.16),Vector3(0.4,0.015,0.3),CREAM)
	_orb(scenery,"CafeDawn",Vector3(4.4,2.5,-6.2),0.6,Color("d7af8c")).scale.z = 0.3

func _road():
	var road = _node(scenery,"NoDestinationRoad")
	_box(road,"RoadSurface",Vector3(0,0.014,-0.5),Vector3(3.2,0.025,11),Color("687374"))
	for i in range(7): _box(road,"FadedRoadMark",Vector3(0,0.031,-5.5+i*1.65),Vector3(0.09,0.008,0.55),palette[2].darkened(0.18))
	var lamps = _node(scenery,"RoadLamps")
	for x in [-5.4,5.4]:
		for z in [-5.5,-1.1]:
			factory.rounded(lamps,"LampPost",Vector3(x,1.65,z),0.04,0.09,3.3,palette[0],true)
			_orb(lamps,"RoadLamp",Vector3(x,3.24,z),0.2,palette[2])
	_box(road,"RoadBench",Vector3(5.15,0.45,2.3),Vector3(1.3,0.15,0.8),WOOD,true)
	_box(road,"BenchBack",Vector3(5.6,0.87,2.3),Vector3(0.08,0.85,0.8),WOOD)
	_label(road,"RoadSign","NO DESTINATION REQUIRED",Vector3(-4.6,2.16,-4.7),20,0.0045)
	_box(road,"SignPost",Vector3(-4.6,1,-4.7),Vector3(0.08,2,0.08),WOOD)

func _fireflies():
	var clearing = load("res://world/firefly_clearing.gd").new()
	clearing.name = "PaintedClearing"
	scenery.add_child(clearing)
	clearing.build(self)


func _npc_name() -> String:
	var npc = destination.get("npc",{})
	if npc is Dictionary: return str(npc.get("name","Keeper"))
	return str(npc).capitalize() if not str(npc).is_empty() else "Keeper"

func _build_npc():
	var npc = destination.get("npc",{})
	var name_ = _npc_name()
	var person: Node3D
	if name_.to_lower() == "mira": person = factory.production_character(scenery,Vector3(2.8,0,-2.65),"mira")
	else:
		person = _node(scenery,"JourneyNPC",Vector3(2.8,0,-2.65))
		person.set_meta("character_id",name_.to_lower())
		factory.person(person,Vector3.ZERO,palette[1])
		person.get_node("Satchel").hide()
		person.get_node("HairBun").visible = name_.to_lower() in ["ada","noor"]
		if name_.to_lower() == "ada": person.get_node("Hair").material_override = factory.shared_material(Color("928b80"))
	person.set_meta("character_name",name_)
	person.set_meta("independent_life",true)
	person.set_meta("returning",visit_count > 0)
	var line = "Taking care of a few things."
	if npc is Dictionary:
		line = str(npc.get("returning",npc.get("return_line",line))) if visit_count > 0 else str(npc.get("role",npc.get("arrival",line)))
	else:
		var entries = destination.get("entry_variants",{})
		var authored_line = str(entries.get("return" if visit_count > 0 else "first","")) if entries is Dictionary else ""
		for sentence in authored_line.split(". "):
			if sentence.to_lower().contains(name_.to_lower()): line = sentence
	if line.length() > 86: line = line.substr(0,83)+"..."
	var npc_note = _label(scenery,"NPCIndependentState",name_+"\n"+line,Vector3(2.8,2.24,-2.67),18,0.0037)
	if journey_id == "fireflies": npc_note.visibility_range_end = 4.0

func _build_activity():
	activity_type = str(destination.get("activity_type","observation"))
	activity = _node(self,"Activity",Vector3(-2,0,-2.55))
	activity.set_meta("activity_type",activity_type)
	_box(activity,"WorkSurface",Vector3(0,0.93,0),Vector3(2.65,0.12,1.5),WOOD,true)
	for x in [-1.12,1.12]: _box(activity,"WorkLeg",Vector3(x,0.44,0),Vector3(0.1,0.88,1.1),palette[0])
	match activity_type:
		"rain_routing": _build_routing()
		"letter_arrangement": _build_letters()
		"arcade_paddle": _build_paddle()
		"constellation_tracing": _build_constellation()
		"tea_mixing": _build_tea()
		_: _build_observation()
	var saved = snapshot.get("activities",snapshot.get("activity_states",{}))
	var current = saved.get(journey_id,{}) if saved is Dictionary else {}
	if snapshot.get("activity",{}) is Dictionary and not snapshot.get("activity",{}).is_empty(): current = snapshot.activity
	update_activity(current if current is Dictionary else {})
	if journey_id == "fireflies":
		activity.scale = Vector3(0.72,0.72,0.72)
		activity.position = Vector3(-2,0,-2.55)
		activity.get_node("Constellation/TraceNote").visibility_range_end = 3.5

func _build_routing():
	var channels = _node(activity,"RainChannels",Vector3(0,1.02,0))
	for i in range(3):
		var channel = _node(channels,"Route%d" % i,Vector3(-0.78+i*0.78,0,0))
		for side in [-0.1,0.1]: _box(channel,"ChannelLip",Vector3(side,0.06,0),Vector3(0.05,0.1,1.14),Color("91a7a9"))
		_box(channel,"ChannelBed",Vector3(0,0,0),Vector3(0.23,0.045,1.16),palette[0])
		_box(channel,"RoutedWater",Vector3(0,0.032,0.18),Vector3(0.13,0.018,0.77),Color("83bcc4"))
		var gate = _box(channel,"TurnableGate",Vector3(0,0.11,-0.14),Vector3(0.06,0.18,0.4),palette[2])
		gate.rotation.y = 0.5
		factory.rounded(channel,"CatchBasin",Vector3(0,0.12,0.65),0.21,0.2,0.17,palette[1])
		factory.rounded(channel,"CollectedRain",Vector3(0,0.214,0.65),0.175,0.175,0.008,Color("83bcc4"))

func _build_letters():
	var letters = _node(activity,"Envelopes",Vector3(0,1.04,0))
	for i in range(3):
		var envelope = _node(letters,"Envelope%d" % i,Vector3(-0.9+i*0.42,0,0))
		_box(envelope,"Paper",Vector3.ZERO,Vector3(0.38,0.023,0.29),CREAM)
		var flap = _box(envelope,"Fold",Vector3(0,0.016,-0.055),Vector3(0.19,0.006,0.15),Color("d4c8b0"))
		flap.rotation.y = PI/4
		_box(envelope,"Stamp",Vector3(0.105,0.019,-0.085),Vector3(0.05,0.005,0.058),palette[1])
		_box(envelope,"Address",Vector3(-0.028,0.02,0.062),Vector3(0.19,0.005,0.016),palette[0])
	_label(activity,"UnsentNote","NO LETTER HAS TO BE SENT",Vector3(0,1.68,-0.47),17,0.0035)

func _build_paddle():
	var machine = _node(activity,"PaddleMachine",Vector3(0,1.05,-0.14))
	_box(machine,"Housing",Vector3(0,0.49,0),Vector3(2.36,1.15,0.22),palette[0])
	_box(machine,"PlayingField",Vector3(0,0.52,0.13),Vector3(2.12,0.91,0.025),Color("3d6666"))
	for i in range(5): _box(machine,"Midline",Vector3(0,0.17+i*0.17,0.15),Vector3(0.017,0.08,0.01),CREAM)
	_box(machine,"PlayerPaddle",Vector3(-0.85,0.55,0.17),Vector3(0.055,0.24,0.035),palette[2])
	_box(machine,"OtherPaddle",Vector3(0.85,0.49,0.17),Vector3(0.055,0.24,0.035),CREAM)
	_orb(machine,"Ball",Vector3(-0.26,0.57,0.18),0.053,CREAM)
	_label(machine,"PaddleNote","A FEW RALLIES",Vector3(0,1.18,0.15),18,0.0038)

func _build_constellation():
	var stars = _node(activity,"Constellation",Vector3(0,1.63,-0.2))
	_box(stars,"NightPanel",Vector3(0,0.2,-0.08),Vector3(2.45,1.37,0.1),palette[0])
	var points = [Vector3(-0.92,0.12,0),Vector3(0,0.67,0),Vector3(0.92,0.17,0)]
	for i in range(points.size()): _orb(stars,"Point%d" % i,points[i],0.065,palette[2])
	for i in range(points.size()-1):
		var from = points[i]
		var to = points[i+1]
		var connection = _box(stars,"Connection%d" % i,(from+to)*0.5,Vector3(from.distance_to(to),0.02,0.02),CREAM)
		connection.rotation.z = atan2(to.y-from.y,to.x-from.x)
	_label(stars,"TraceNote","CONNECT WHAT YOU NOTICE",Vector3(0,-0.4,0),16,0.0033)

func _cup(parent: Node3D, id: String, where: Vector3, color: Color) -> Node3D:
	var cup = _node(parent,id,where)
	factory.rounded(cup,"CeramicCup",Vector3(0,0.13,0),0.17,0.145,0.26,color)
	factory.rounded(cup,"TeaSurface",Vector3(0,0.254,0),0.142,0.142,0.008,Color("716744"))
	_orb(cup,"Handle",Vector3(0.18,0.14,0),0.092,color).scale = Vector3(0.4,0.9,1)
	return cup

func _build_tea():
	var tray = _node(activity,"TeaTray",Vector3(0,1.035,0))
	_box(tray,"Tray",Vector3.ZERO,Vector3(2.3,0.035,1.05),palette[0])
	for i in range(3):
		var jar = _node(tray,"Ingredient%d" % i,Vector3(-0.75+i*0.72,0.2,-0.27))
		factory.rounded(jar,"Jar",Vector3.ZERO,0.15,0.15,0.38,[Color("9e7c54"),Color("829468"),Color("b08082")][i])
		factory.rounded(jar,"Lid",Vector3(0,0.215,0),0.164,0.164,0.05,CREAM)
		_label(jar,"IngredientName",["AMBER LEAF","MINT","HIBISCUS"][i],Vector3(0,0.35,0.15),12,0.002)
	_cup(tray,"MixedCup",Vector3(0,0.03,0.23),CREAM)
	_cup(tray,"WaitingCup",Vector3(0.74,0.03,0.24),palette[1])
	var steam = _node(tray,"Steam",Vector3(0,0.31,0.23))
	for i in range(4): _orb(steam,"TeaPuff",Vector3(sin(i)*0.045,i*0.07,0),0.022,Color("cbd4cb"))

func _build_observation():
	var objects = _node(activity,"ObservationObjects",Vector3(0,1.035,0))
	for i in range(3):
		var item = _orb(objects,"NoticedObject%d" % i,Vector3(-0.72+i*0.72,0.09,0.0),0.13,[palette[1],palette[2],CREAM][i])
		item.scale = Vector3(1,0.55,0.9)
	_box(objects,"RestingCard",Vector3(0,0.025,0.38),Vector3(1.55,0.03,0.24),CREAM)
	_label(activity,"ObservationNote","NOTHING TO FINISH",Vector3(0,1.6,-0.36),20,0.004)

func update_activity(value: Dictionary):
	if not is_instance_valid(activity): return
	_activity_state = value.duplicate(true)
	var step = maxi(0,int(value.get("step",0)))
	var selection = maxi(0,int(value.get("selection",0)))
	var progress = maxi(0,int(value.get("progress",0)))
	var done = bool(value.get("done",false))
	activity.set_meta("step",step)
	activity.set_meta("selection",selection)
	activity.set_meta("progress",progress)
	activity.set_meta("done",done)
	match activity_type:
		"rain_routing":
			for i in range(3):
				var route = activity.get_node("RainChannels/Route%d" % i)
				route.get_node("TurnableGate").rotation.y = PI/2 if (selection & (1 << i)) != 0 else 0.25+0.12*(step%3)
				route.get_node("RoutedWater").scale.z = 1.0 if done or i == step%3 else 0.25
				route.get_node("CollectedRain").visible = done or (selection & (1 << i)) != 0
		"letter_arrangement":
			for i in range(3):
				var envelope = activity.get_node("Envelopes/Envelope%d" % i)
				var orders = [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]
				var order = orders[selection%6]
				var place = order.find(i) if i < 3 else i
				envelope.position = Vector3(-0.9+place*0.42,0.008*i,0.11*(i%2)) if done else Vector3(-0.8+(place%3)*0.72,0.018*i,-0.25+(place/3)*0.42)
				envelope.rotation.y = 0.0 if done else (i-2)*0.18+(selection%6-1)*0.08
		"arcade_paddle":
			var machine = activity.get_node("PaddleMachine")
			machine.get_node("PlayerPaddle").position = Vector3(-0.85+clampf(selection/10.0,0,1)*1.7,0.17,0.17)
			machine.get_node("PlayerPaddle").rotation.z = PI/2
			machine.get_node("OtherPaddle").position.y = 0.2+((step+1)%3)*0.27
			machine.get_node("Ball").position = Vector3(-0.55+(step%4)*0.36,0.24+((progress+selection)%3)*0.26,0.18)
		"constellation_tracing":
			for i in range(2): activity.get_node("Constellation/Connection%d" % i).visible = done or i < progress
			for i in range(3): activity.get_node("Constellation/Point%d" % i).scale = Vector3.ONE*(1.35 if i == (step%3) else 1.0)
		"tea_mixing":
			var tray = activity.get_node("TeaTray")
			var tints = [Color("8d6942"),Color("7c9162"),Color("af7a80")]
			var tint = Color("b78351")
			for i in range(3):
				if (selection & (1 << i)) != 0: tint = tint.lerp(tints[i],0.4)
			var tea = tray.get_node("MixedCup/TeaSurface")
			tea.get_child(0).material_override = factory.shared_material(tint.lightened(minf(progress*0.03,0.15)))
			tea.position.y = 0.17+minf(progress,3)*0.028
			tray.get_node("WaitingCup").position.x = 0.61 if done else 0.9
			for i in range(3): tray.get_node("Ingredient%d" % i).position.y = 0.25 if (selection & (1 << i)) != 0 else 0.2
			tray.get_node("Steam").visible = (done or progress > 0) and not reduced_motion
		_:
			for i in range(3): activity.get_node("ObservationObjects/NoticedObject%d" % i).rotation.y = step*0.15+i*0.22
			activity.get_node("ObservationObjects/RestingCard").rotation.y = 0.12 if done else 0

func apply_preferences(value: bool):
	reduced_motion = value
	if has_node("AmbientMotion"): get_node("AmbientMotion").apply_preferences(value)
	for item in _decorative:
		if is_instance_valid(item.node): item.node.position = item.rest
	for rain in find_children("Rain","Node3D",true,false): rain.visible = not value and weather_state == "rain"
	for snow in find_children("Snow","Node3D",true,false): snow.visible = not value and weather_state == "snow"
	if is_instance_valid(activity) and activity_type == "tea_mixing":
		activity.get_node("TeaTray/Steam").visible = not value and (bool(_activity_state.get("done",false)) or int(_activity_state.get("progress",0)) > 0)
	for person in scenery.find_children("*","Node3D",true,false):
		if person.has_method("apply_preferences"): person.apply_preferences(value)

func set_paused(value: bool):
	paused = value
	if has_node("AmbientMotion"): get_node("AmbientMotion").set_process(not value)
	for person in scenery.find_children("*","Node3D",true,false):
		if person.has_method("set_paused"): person.set_paused(value)
		elif person.has_method("advance_performance"): person.set_process(not value)

func _process(delta: float):
	if paused or reduced_motion: return
	motion_elapsed += delta
	for item in _decorative:
		if is_instance_valid(item.node): item.node.position = item.rest + Vector3(sin(motion_elapsed*0.37+item.phase)*0.035,sin(motion_elapsed*0.49+item.phase)*0.04,0)

func _apply_local_state():
	var states = snapshot.get("location_states",{})
	var state = str(states.get(journey_id,"as_found")) if states is Dictionary else "as_found"
	var changed = _node(scenery,"LocalConsequences")
	changed.set_meta("state_id",state)
	set_meta("location_state",state)
	match state:
		"pot_route":
			factory.rounded(changed,"PotSaucer",Vector3(-4.5,0.07,-2.7),0.4,0.36,0.06,CREAM)
			factory.rounded(changed,"RainPot",Vector3(-4.5,0.33,-2.7),0.28,0.22,0.5,palette[1])
			_box(changed,"PotWaterFeed",Vector3(-4.5,0.035,-3.6),Vector3(0.08,0.018,1.5),Color("83bcc4"))
		"wheel_route":
			var wheel = factory.rounded(changed,"LittleRainWheel",Vector3(-4.7,0.63,-2.7),0.43,0.43,0.09,palette[1])
			wheel.rotation.x = PI/2
			for i in range(6): _box(wheel,"WheelSpoke",Vector3.ZERO,Vector3(0.06,0.07,0.76),WOOD).rotation.y = i*PI/3
			_box(changed,"DryParcelShelf",Vector3(-4.7,1.3,-3.7),Vector3(1.3,0.1,0.72),WOOD)
			_box(changed,"DryParcel",Vector3(-4.7,1.52,-3.7),Vector3(0.64,0.34,0.4),CREAM)
		"letter_together", "cards_together":
			_box(changed,"BlankPracticeSheet",Vector3(-2,1.015,-2.55),Vector3(1.1,0.015,0.62),CREAM)
			_box(changed,"PracticeLetterClip",Vector3(-2,1.1,-2.89),Vector3(0.33,0.055,0.06),palette[0])
			for i in range(3): activity.get_node("Envelopes/Envelope%d" % i).position = Vector3(0,0.035+i*0.015,-0.2+i*0.17)
		"lines_apart", "cards_apart":
			_box(changed,"FeltArrangementBoard",Vector3(-2,1.02,-2.55),Vector3(2.35,0.03,1.08),palette[0])
			for i in range(3): activity.get_node("Envelopes/Envelope%d" % i).position = Vector3(-0.83+i*0.83,0.04,0)
		"wide_paddle", "practice_card":
			activity.get_node("PaddleMachine/PlayerPaddle").scale.y = 1.7
			_box(changed,"PublicPracticeCard",Vector3(-2.93,1.055,-2.09),Vector3(0.35,0.02,0.24),CREAM)
			_box(changed,"WiderPaddlePart",Vector3(-4.8,2.4,-4.32),Vector3(0.7,0.12,0.045),palette[2])
		"slow_ball", "demo_notice":
			activity.get_node("PaddleMachine/Ball").position.x = 0.52
			_label(changed,"UprightDemonstrationNotice","DEMONSTRATION AVAILABLE",Vector3(-2,2.55,-2.51),14,0.0035)
			_box(changed,"CabinetSlowSwitch",Vector3(-4.8,1.09,-4.08),Vector3(0.18,0.035,0.18),palette[2])
		"long_line", "traced_line", "star_line":
			for i in range(2): activity.get_node("Constellation/Connection%d" % i).show()
			_box(changed,"BeachPracticeLine",Vector3(-4.5,0.04,-1.5),Vector3(2.0,0.025,0.04),CREAM).rotation.y = 0.23
		"open_shape", "unjoined_points":
			for i in range(2): activity.get_node("Constellation/Connection%d" % i).visible = false
			_box(changed,"UnjoinedLineEnd",Vector3(-4.5,0.04,-1.5),Vector3(0.65,0.025,0.04),CREAM).rotation.y = -0.25
		"bench_cloth":
			_box(changed,"OrchardBench",Vector3(4.9,0.5,1.6),Vector3(2,0.16,0.8),WOOD)
			_box(changed,"LeftBenchCloth",Vector3(4.62,0.605,1.6),Vector3(0.83,0.045,0.84),palette[2])
		"crate_stack":
			for i in range(2):
				_box(changed,"RestackedOrchardCrate",Vector3(4.75+i*0.77,0.27,-5.15),Vector3(0.67,0.5,0.6),palette[1])
		"mint_tin":
			factory.rounded(changed,"MintTinAtHand",Vector3(-2.82,1.34,-2.65),0.18,0.18,0.38,Color("829468"))
			activity.get_node("TeaTray/Ingredient1").position.x = -0.5
		"plain_tray":
			_box(changed,"PlainWoodTray",Vector3(-2,1.08,-2.55),Vector3(1.9,0.035,1.15),CREAM)
			activity.get_node("TeaTray/WaitingCup").position.z = -0.4
		"kept_first", "letter_first":
			_box(changed,"FirstExhibitKeptLabel",Vector3(-5.1,1.24,-3.94),Vector3(1.15,0.08,0.16),CREAM)
			activity.get_node("Envelopes/Envelope1").position.x = -0.82
		"surprise_first", "stamp_first":
			_box(changed,"FirstExhibitSurpriseLabel",Vector3(-1.7,1.24,-3.94),Vector3(1.15,0.08,0.16),palette[2])
			activity.get_node("Envelopes/Envelope0").position.x = -0.82
		"orange_dish", "hibiscus_tin":
			factory.rounded(changed,"HibiscusTinFacingRoom",Vector3(-2.65,1.32,-2.11),0.17,0.17,0.37,Color("b08082"))
			_label(changed,"HibiscusTinLabel","HIBISCUS",Vector3(-2.65,1.35,-1.93),13,0.0022)
			factory.rounded(changed,"OrangePeelDish",Vector3(-3.0,1.09,-2.2),0.26,0.22,0.035,CREAM)
			for i in range(3): _orb(changed,"OrangePeel",Vector3(-3.08+i*0.08,1.125,-2.2),0.058,Color("d6a65f")).scale = Vector3(1,0.2,0.65)
		"window_cup":
			_cup(changed,"CupByDawnWindow",Vector3(4.5,1.55,-5.45),CREAM)
			_box(changed,"WindowCupShelf",Vector3(4.5,1.5,-5.45),Vector3(0.92,0.08,0.6),WOOD)
		"gate_note":
			_box(changed,"RoadGatePost",Vector3(-4.75,0.8,-2.55),Vector3(0.12,1.6,0.12),WOOD)
			_box(changed,"SmallGateNote",Vector3(-4.75,1.2,-2.47),Vector3(0.33,0.25,0.022),CREAM)
		"wall_stone":
			_orb(changed,"StoneOnRoadWall",Vector3(6.35,0.13,-2.5),0.17,palette[1]).scale = Vector3(0.7,0.5,1.05)
		"low_arc":
			for i in range(3): activity.get_node("Constellation/Point%d" % i).position.y = 0.16+sin(i*PI/4)*0.22
			for i in range(2): activity.get_node("Constellation/Connection%d" % i).hide()
			_box(changed,"LowArcPracticeCard",Vector3(-4.4,1.04,-3.8),Vector3(0.84,0.025,0.32),CREAM)
		"two_lines":
			for i in range(2): activity.get_node("Constellation/Connection%d" % i).visible = i in [0,3]
			_box(changed,"TwoLinesPracticeCard",Vector3(-4.4,1.04,-3.8),Vector3(0.84,0.025,0.32),palette[2])

func _build_weather():
	# Visit-derived variants are a finite authored palette, not a real-world clock.
	if weather_state == "rain" and not scenery.has_node("Rain"):
		var rain = _node(scenery,"Rain")
		for i in range(18):
			_box(rain,"WindowRain",Vector3(-5.8+(i%9)*1.45,2+(i%4)*0.4,-5.4-(i%2)*0.45),Vector3(0.015,0.22,0.015),Color("a7c1c7"))
	if weather_state == "snow":
		var snow = _node(scenery,"Snow")
		for i in range(18):
			_orb(snow,"Snowflake",Vector3(-5.5+(i%8)*1.55,1.7+(i%5)*0.37,-4.8+(i%3)*0.8),0.025,CREAM)
	if weather_state == "mist":
		var mist = _node(scenery,"StillMist")
		for i in range(3):
			var band = _box(mist,"MistBand",Vector3(0,0.17+i*0.18,-5.1+i*0.53),Vector3(12.2,0.045,0.43),palette[1])
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(palette[1],0.13)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			band.get_child(0).material_override = material
