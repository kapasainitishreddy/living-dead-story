extends Node3D
# Chapter Three's original, warm paper workshop. Snapshot owns every choice.
const CREAM = Color("f1e2c8")
const TEAL = Color("557e77")
const WOOD = Color("a47b55")
const BRASS = Color("c7a16b")
var factory: RefCounted
var snapshot: Dictionary = {}
var interactions: Node3D
var sign: Node3D
var silhouette: Node3D
var spare_boat: Node3D
var gift_star: Node3D
var decorative_elapsed := 0.0
var reduced := false
var raised := false

func build(value: Dictionary) -> Node3D:
	factory = load("res://world/world_factory.gd").new()
	name = "World"
	var spawn = Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = Vector3(1.1,0.12,6.1)
	add_child(spawn)
	_build_room()
	_build_worktable()
	_build_doorway()
	_build_shadow_screen()
	_build_paper_stands()
	_build_umbrella()
	_build_people()
	interactions = Node3D.new()
	interactions.name = "Interactions"
	add_child(interactions)
	var motion = load("res://world/ambient_motion.gd").new()
	motion.name = "AmbientMotion"
	add_child(motion)
	var close_view = Marker3D.new()
	close_view.name = "SignView"
	close_view.position = Vector3(-1.7,2.4,2.0)
	close_view.set_meta("look_at",Vector3(-1.7,2.45,-1.65))
	add_child(close_view)
	var shadow_view = Marker3D.new()
	shadow_view.name = "ShadowView"
	shadow_view.position = Vector3(-5.05,2.3,-1.7)
	shadow_view.set_meta("look_at",Vector3(-5.1,2.3,-6.5))
	add_child(shadow_view)
	apply_snapshot(value)
	return self

func _ready(): apply_snapshot(snapshot)

func _label(parent: Node3D, id: String, text_: String, where: Vector3, size_: int = 24, pixel: float = 0.005) -> Label3D:
	factory.label(parent,text_,where,size_)
	var label = parent.get_child(parent.get_child_count()-1) as Label3D
	label.name = id
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.pixel_size = pixel
	label.outline_size = 2
	return label

func _glass(parent: Node3D, id: String, where: Vector3, size_: Vector3, color_: Color) -> Node3D:
	var pane = factory.box(parent,id,where,size_,color_,false)
	var material = StandardMaterial3D.new()
	material.albedo_color = color_
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.42
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	pane.get_child(0).material_override = material
	pane.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return pane

func _build_room():
	factory.box(self,"ConservatoryFloor",Vector3(0,-0.3,0.75),Vector3(16,0.6,17.5),Color("9b8a74"))
	var floor_tiles = Node3D.new()
	floor_tiles.name = "ClayTileFloor"
	add_child(floor_tiles)
	for tone in range(3):
		var batch = MultiMeshInstance3D.new()
		batch.name = "ClayTileBatch%d" % tone
		var multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = factory.shared_box_mesh(Vector3(1.29,0.025,1.29))
		var positions: Array[Vector3] = []
		for x in range(-5,6):
			for z in range(-5,7):
				if (x+z+30)%3 == tone: positions.append(Vector3(x*1.32,0.014,z*1.32+0.3))
		multimesh.instance_count = positions.size()
		for i in range(positions.size()): multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,positions[i]))
		batch.multimesh = multimesh
		batch.material_override = factory.shared_material(Color("ae9278").lightened(tone*0.035))
		floor_tiles.add_child(batch)
	for x in [-8.0,8.0]:
		factory.box(self,"ConservatorySideWall",Vector3(x,0.72,0.75),Vector3(0.22,1.44,17.5),TEAL)
		for z in [-6.3,-3.5,-0.7,2.1,4.9,7.7]:
			factory.box(self,"WallMullion",Vector3(x,3.25,z),Vector3(0.12,3.65,0.12),TEAL,false)
			_glass(self,"SideGlass",Vector3(x,3.2,z+1.35),Vector3(0.045,3.6,2.65),Color(0.37,0.56,0.58,0.31))
	factory.box(self,"BackWall",Vector3(0,1.6,-7.75),Vector3(16,3.2,0.23),Color("65877d"))
	factory.box(self,"FrontBoundary",Vector3(0,0.62,9.48),Vector3(16,1.24,0.24),TEAL)
	var roof = Node3D.new()
	roof.name = "GlassRoof"
	add_child(roof)
	for z in [-6.8,-3.4,0.0,3.4,6.8]:
		for side in [-1.0,1.0]:
			var rib = factory.box(roof,"RoofRib",Vector3(side*4,5.56,z),Vector3(8.25,0.09,0.11),TEAL,false)
			rib.rotation.z = -side*0.12
			var pane = _glass(roof,"RoofGlassPane",Vector3(side*4,5.58,z+1.58),Vector3(8.13,0.045,3.14),Color(0.49,0.64,0.63,0.22))
			pane.rotation.z = rib.rotation.z
			for i in range(3):
				var patch = _glass(roof,"IrregularRainPatch",Vector3(side*(1.2+i*1.7),5.98-(1.2+i*1.7)*0.12,z+0.65+i*0.64),Vector3(0.68+i*0.2,0.009,0.2+i*0.07),Color(0.77,0.83,0.79,0.22))
				patch.rotation.z = rib.rotation.z
				patch.rotation.y = (i-1)*0.31
	for x in [-7.85,0.0,7.85]: factory.box(roof,"RoofSpine",Vector3(x,6.05-abs(x)*0.12,0.7),Vector3(0.1,0.12,17.6),TEAL,false)
	var rain = CPUParticles3D.new()
	rain.name = "Rain"
	rain.position = Vector3(0,7.8,0.2)
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(7.8,0.3,8)
	rain.amount = 90
	rain.lifetime = 0.52
	rain.preprocess = 0.5
	rain.direction = Vector3(0.04,-1,0)
	rain.initial_velocity_min = 2.8
	rain.initial_velocity_max = 3.5
	rain.gravity = Vector3(0,-1,0)
	rain.color = Color(0.75,0.85,0.88,0.3)
	var drop = BoxMesh.new()
	drop.size = Vector3(0.008,0.13,0.008)
	rain.mesh = drop
	add_child(rain)
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("263d4a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b4c1b5")
	env.ambient_light_energy = 0.62
	environment.environment = env
	add_child(environment)
	var skylight = DirectionalLight3D.new()
	skylight.name = "RainSkyLight"
	skylight.rotation_degrees = Vector3(-48,-28,0)
	skylight.light_color = Color("bad1cd")
	skylight.light_energy = 0.56
	add_child(skylight)
	for where in [Vector3(-2.4,4.6,-1.3),Vector3(4.8,4.55,-3.7)]:
		var lamp = OmniLight3D.new()
		lamp.name = "SteadyReadingLight"
		lamp.position = where
		lamp.light_color = Color("ffd69b")
		lamp.light_energy = 2.6
		lamp.omni_range = 9.0
		lamp.shadow_enabled = false
		add_child(lamp)
		factory.rounded(self,"ReadingLampShade",where+Vector3(0,0.15,0),0.15,0.38,0.28,Color("bc9367"))
		factory.orb(self,where,0.105,Color("eebf79"))
		factory.box(self,"LampCord",where+Vector3(0,0.58,0),Vector3(0.022,0.8,0.022),Color("465c55"),false)
	factory.box(self,"RoomSignBoard",Vector3(0,3.5,-7.58),Vector3(5.9,0.57,0.065),Color("385c59"),false)
	_label(self,"RoomTitle","PAPER CONSERVATORY",Vector3(0,3.52,-7.53),31,0.007)
	_label(self,"RoomSubtitle","A SKY THAT FITS THROUGH THE DOOR",Vector3(0,3.15,-7.5),18,0.005)

func _build_worktable():
	var table = factory.box(self,"Worktable",Vector3(-1.7,1.06,-1.65),Vector3(4.45,0.19,2.15),WOOD)
	for x in [-1.82,1.82]:
		for z in [-0.76,0.76]: factory.box(table,"TaperedTableLeg",Vector3(x,-0.51,z),Vector3(0.14,0.92,0.14),TEAL,false)
	factory.box(table,"TableEdge",Vector3(0,0.07,1.065),Vector3(4.43,0.028,0.025),BRASS,false)
	factory.box(table,"CuttingMat",Vector3(0,0.106,0),Vector3(3.5,0.02,1.45),Color("60887d"),false)
	for i in range(8): factory.box(table,"MatGrid",Vector3(-1.4+i*0.4,0.12,0),Vector3(0.008,0.004,1.38),Color("88a496"),false)
	for i in range(4): factory.box(table,"MatGrid",Vector3(0,0.121,-0.6+i*0.4),Vector3(3.48,0.004,0.008),Color("88a496"),false)
	factory.box(table,"SoupStainedDimensionCard",Vector3(1.5,0.126,0.65),Vector3(0.64,0.012,0.43),CREAM,false)
	var stain = factory.orb(table,Vector3(1.55,0.139,0.72),0.11,Color("d3a675"))
	stain.scale = Vector3(1.0,0.025,0.63)
	_label(table,"DimensionText","3.8 m DOOR / 2.9 m SIGN",Vector3(1.37,0.24,0.92),12,0.0018)
	factory.box(table,"SpareTimetables",Vector3(-1.65,0.145,0.3),Vector3(0.64,0.045,0.55),CREAM,false)
	for i in range(5): factory.box(table,"SparePrint",Vector3(-1.65,0.172,0.08+i*0.09),Vector3(0.5,0.008,0.009),Color("7a847c"),false)
	for i in range(2):
		var scissor = factory.rounded(table,"ScissorHandle",Vector3(-1.49+i*0.13,0.18,-0.67),0.06,0.06,0.022,Color("627681"))
		scissor.rotation.x = PI/2
	factory.box(table,"ScissorBlade",Vector3(-1.51,0.18,-0.88),Vector3(0.06,0.024,0.3),Color("b7c4bf"),false)
	var rails = Node3D.new()
	rails.name = "HangingRails"
	add_child(rails)
	for z in [-2.53,-1.65,-0.77]: factory.box(rails,"HangingRail",Vector3(-1.7,3.31,z),Vector3(4.2,0.075,0.075),TEAL,false)
	for x in [-3.85,0.45]:
		for z in [-2.53,-0.77]: factory.box(rails,"RailUpright",Vector3(x,2.21,z),Vector3(0.085,2.2,0.085),TEAL,false)
	sign = load("res://world/paper_sign.gd").new()
	sign.name = "PaperSign"
	add_child(sign)
	sign.configure({},factory)
	spare_boat = sign.make_boat(self,false,"SpareTimetableBoat")
	spare_boat.position = Vector3(-3.17,1.46,-2.06)
	spare_boat.rotation = Vector3(-0.15,0.3,-0.16)
	var rack = factory.box(self,"DryingRack",Vector3(-3.2,1.28,-2.17),Vector3(0.75,0.025,0.57),Color("c8ae84"),false)
	for i in range(4): factory.box(rack,"RackSlat",Vector3(-0.26+i*0.17,0.025,0),Vector3(0.015,0.025,0.56),BRASS,false)
	_label(self,"WorktableLabel","ARRANGE / DIRECT / WATCH",Vector3(-1.7,0.86,-0.48),18,0.0035)

func _build_doorway():
	var doorway = Node3D.new()
	doorway.name = "TestDoorway"
	doorway.position = Vector3(4.0,0,-4.3)
	doorway.set_meta("clear_width",3.8)
	doorway.set_meta("clear_height",4.6)
	add_child(doorway)
	for x in [-2.0,2.0]:
		factory.box(doorway,"MeasuredDoorPost",Vector3(x,2.3,0),Vector3(0.2,4.6,0.2),TEAL)
		factory.box(doorway,"BrassPostEdge",Vector3(x,2.3,0.13),Vector3(0.026,4.58,0.025),BRASS,false)
	factory.box(doorway,"MeasuredDoorLintel",Vector3(0,4.67,0),Vector3(4.2,0.16,0.24),TEAL,false)
	factory.box(doorway,"WidthRule",Vector3(0,0.05,0.15),Vector3(3.8,0.018,0.04),BRASS,false)
	for i in range(20): factory.box(doorway,"MeasureMark",Vector3(-1.9+i*0.2,0.06,0.18),Vector3(0.012,0.02,0.08),CREAM,false)
	_label(doorway,"DoorwayTitle","MEASURED DOOR / 3.8 m",Vector3(0,4.93,0.06),22,0.006)
	factory.box(self,"RaiseHandleBase",Vector3(1.2,1.08,-3.66),Vector3(0.37,0.27,0.28),TEAL)
	var lever = factory.box(self,"RaiseRailHandle",Vector3(1.2,1.28,-3.5),Vector3(0.075,0.35,0.075),BRASS,false)
	lever.rotation.x = 0.33
	factory.rounded(self,"RailHandleGrip",Vector3(1.2,1.45,-3.44),0.06,0.06,0.3,Color("875e43")).rotation.z = PI/2
	factory.box(self,"KitchenDoor",Vector3(6.34,1.55,-7.56),Vector3(2.1,3.1,0.09),Color("b78e60"))
	factory.box(self,"KitchenDoorGlass",Vector3(6.34,2.0,-7.49),Vector3(1.38,1.5,0.04),Color("eebf79"),false)
	factory.box(self,"KitchenDoorHandle",Vector3(7.01,1.25,-7.43),Vector3(0.055,0.2,0.05),CREAM,false)
	_label(self,"KitchenDirection","COURTYARD BOOTH / KITCHEN",Vector3(6.2,3.5,-7.39),19,0.0047)
	factory.box(self,"BoothDisplayAlcove",Vector3(4.0,2.26,-6.83),Vector3(4.75,4.45,0.12),Color("3c5c59"),false)
	_label(self,"MountingNote","COURTYARD BOOTH SIGN\nREADY FOR ADA",Vector3(4,0.7,-6.7),18,0.004)

func _build_shadow_screen():
	var screen = factory.box(self,"ShadowScreen",Vector3(-5.08,2.45,-6.75),Vector3(4.3,3.05,0.11),Color("e5d7b9"),false)
	for x in [-2.2,2.2]: factory.box(screen,"ScreenFrame",Vector3(x,0,0),Vector3(0.1,3.16,0.18),WOOD,false)
	for y in [-1.54,1.54]: factory.box(screen,"ScreenFrame",Vector3(0,y,0),Vector3(4.5,0.1,0.18),WOOD,false)
	silhouette = load("res://world/paper_sign.gd").new()
	silhouette.name = "SignSilhouette"
	silhouette.position = Vector3(0,1.11,0.094)
	silhouette.scale = Vector3(1.02,1.02,0.04)
	screen.add_child(silhouette)
	silhouette.configure({},factory,true)
	_label(self,"ShadowLabel","PAPER MAKES A FINE SHADOW",Vector3(-5.08,0.72,-6.59),18,0.004)

func _build_paper_stands():
	var stands = Node3D.new()
	stands.name = "PaperOffcutStands"
	add_child(stands)
	for where in [Vector3(-6.68,0,0.3),Vector3(-6.25,0,4.8),Vector3(6.85,0,2.4)]:
		factory.rounded(stands,"OffcutStandFoot",where+Vector3(0,0.12,0),0.36,0.44,0.24,Color("a98760"),true)
		factory.box(stands,"OffcutStandStem",where+Vector3(0,1.18,0),Vector3(0.045,2.22,0.045),BRASS,false)
		for i in range(5):
			var paper = sign.make_leaf(stands)
			paper.position = where+Vector3(sin(i*2.4)*0.4,1.2+i*0.22,cos(i*2.4)*0.13)
			paper.rotation = Vector3(0.1,sin(i)*0.4,(-0.65 if i%2 == 0 else 0.55))
			paper.scale = Vector3.ONE*0.65
			var clip = factory.box(stands,"VisiblePaperClip",paper.position+Vector3(0,0.22,0),Vector3(0.027,0.05,0.025),BRASS,false)
			clip.rotation.z = paper.rotation.z
	_label(self,"OffcutsLabel","PAPER OFFCUTS / NO WATER REQUIRED",Vector3(-6.25,0.74,5.08),16,0.003)

func _build_umbrella():
	var stand = factory.rounded(self,"UmbrellaStand",Vector3(6.65,0.33,-1.47),0.33,0.27,0.66,Color("ad815d"),true)
	var umbrella = Node3D.new()
	umbrella.name = "YellowUmbrella"
	umbrella.position = Vector3(0,0.9,0)
	umbrella.rotation.z = -0.1
	stand.add_child(umbrella)
	factory.rounded(umbrella,"ClosedYellowCanopy",Vector3(0,0.08,0),0.07,0.18,0.95,Color("edc455"))
	for i in range(6):
		var seam = factory.box(umbrella,"FoldedUmbrellaSeam",Vector3(sin(i*TAU/6)*0.11,0.08,cos(i*TAU/6)*0.11),Vector3(0.013,0.91,0.013),Color("d6a545"),false)
		seam.rotation.z = sin(i)*0.055
	factory.rounded(umbrella,"UmbrellaHandle",Vector3(0,0.71,0),0.022,0.022,0.46,WOOD)
	factory.orb(umbrella,Vector3(0.075,0.95,0),0.077,WOOD).scale = Vector3(1.0,0.53,0.45)
	gift_star = sign.make_star(umbrella,true,"UmbrellaGiftStar")
	gift_star.position = Vector3(-0.24,0.22,0.2)
	gift_star.scale = Vector3.ONE*0.53
	factory.box(umbrella,"GiftStarString",Vector3(-0.16,0.55,0.2),Vector3(0.014,0.36,0.014),Color("8c775d"),false).rotation.z = -0.3
	_label(self,"UmbrellaLabel","RAFI'S DELIVERY / NOOR'S STAR",Vector3(6.64,0.89,-1.12),16,0.0035)

func _build_people():
	var noor = Node3D.new()
	noor.name = "Noor"
	noor.position = Vector3(-3.58,0,-3.39)
	noor.rotation.y = 0.35
	noor.set_meta("character_id","noor")
	noor.set_meta("original_geometry_rig",true)
	add_child(noor)
	factory.person(noor,Vector3.ZERO,Color("879c86"))
	noor.get_node("Hair").material_override = factory.shared_material(Color("382e2a"))
	noor.get_node("Hair").scale = Vector3(1.15,0.83,1.12)
	noor.get_node("HairBun").visible = false
	noor.get_node("Satchel").visible = false
	noor.get_node("ArmLeft").rotation.z = -0.2
	noor.get_node("ArmRight").rotation.z = 0.3
	factory.box(noor,"PracticalWorkApron",Vector3(0,0.93,0.225),Vector3(0.44,0.69,0.055),Color("427a75"),false)
	factory.box(noor,"ApronPocket",Vector3(0,0.89,0.267),Vector3(0.3,0.18,0.035),Color("a4b395"),false)
	for x in [-0.08,0.08]:
		var lens = factory.orb(noor,Vector3(x,1.61,0.223),0.055,BRASS)
		lens.scale = Vector3(1.0,0.8,0.13)
		factory.orb(noor,Vector3(x,1.61,0.232),0.029,Color("3e5b57")).scale.z = 0.2
	factory.box(noor,"SpectacleBridge",Vector3(0,1.61,0.228),Vector3(0.055,0.013,0.012),BRASS,false)
	_label(noor,"Name","NOOR",Vector3(0,2.12,0),22,0.004)
	var rafi = Node3D.new()
	rafi.name = "Rafi"
	rafi.position = Vector3(5.23,0,-2.75)
	rafi.rotation.y = -0.42
	rafi.set_meta("character_id","rafi")
	rafi.set_meta("original_geometry_rig",true)
	add_child(rafi)
	factory.person(rafi,Vector3.ZERO,Color("597286"))
	rafi.get_node("HairBun").visible = false
	rafi.get_node("Hair").material_override = factory.shared_material(Color("70492e"))
	rafi.get_node("Scarf").get_child(0).material_override = factory.shared_material(Color("d09b55"))
	for i in range(5): factory.orb(rafi,Vector3(-0.17+i*0.083,1.78+(i%2)*0.016,0.035),0.075,Color("70492e"))
	factory.box(rafi,"BreadPocket",Vector3(0.17,0.98,0.234),Vector3(0.15,0.15,0.045),Color("445f72"),false)
	factory.box(rafi,"BreadSlice",Vector3(0.17,1.08,0.252),Vector3(0.105,0.13,0.024),Color("dcc49c"),false)
	_label(rafi,"Name","RAFI",Vector3(0,2.12,0),22,0.004)
	var mira = factory.production_character(self,Vector3(0.56,0,-2.57),"mira")
	mira.rotation.y = -0.32
	_label(self,"MiraName","MIRA",Vector3(0.56,2.15,-2.57),22,0.004)

func _target(where: Vector3, label_: String, action: String):
	factory.target(interactions,where,label_,action)
	var marker = interactions.get_child(interactions.get_child_count()-2)
	marker.name = action
	interactions.get_child(interactions.get_child_count()-1).visible = false

func _update_interactions():
	for child in interactions.get_children():
		interactions.remove_child(child)
		child.free()
	var checkpoint = str(snapshot.get("paper_checkpoint","arrival"))
	if checkpoint == "arrival":
		_target(Vector3(1.4,0,-1.85),"Noor and Rafi · the spirit of a door","paper_greeting")
	elif checkpoint == "workshop":
		_target(Vector3(-1.7,0,0.38),"Worktable · arrange, direct or watch","paper_worktable")
		_target(Vector3(-3.45,0,0.22),"Star · crooked, clean or a space","paper_star")
		_target(Vector3(-2.54,0,0.28),"Three attachments · choose the order","paper_layout")
		_target(Vector3(-0.7,0,0.23),"Strings · short, medium or long","paper_length")
		_target(Vector3(-4.2,0,-1.67),"Mira's fold · keep, wider or enough","paper_fold")
		_target(Vector3(1.24,0,-2.62),"Raise the rail · test the measured doorway","paper_raise")
	if checkpoint in ["workshop","raised","complete"]:
		_target(Vector3(3.87,0,-2.48) if raised else Vector3(-1.7,0,-3.42),"Finished shape · close view and shadow","paper_inspect")
	if checkpoint in ["raised","complete"]:
		_target(Vector3(6.36,0,-5.98),"Courtyard booth · take the sign to supper","paper_exit")

func apply_snapshot(value: Dictionary):
	snapshot = value.duplicate(true)
	if sign == null: return
	var config: Dictionary = snapshot.get("paper",{})
	var checkpoint = str(snapshot.get("paper_checkpoint","arrival"))
	raised = checkpoint in ["raised","complete"] or bool(config.get("completed",false))
	reduced = bool(snapshot.get("settings",{}).get("reduced_motion",false))
	sign.configure(config,factory)
	sign.position = Vector3(4.0,4.08,-4.16) if raised else Vector3(-1.7,3.19,-1.58)
	sign.visible = checkpoint != "locked"
	silhouette.configure(config,factory,true)
	spare_boat.visible = str(config.get("fold","keep")) == "enough"
	gift_star.visible = checkpoint in ["raised","complete"]
	gift_star.set_meta("delivery_received",gift_star.visible)
	gift_star.set_meta("gift_source","offcut" if str(config.get("star","crooked")) == "crooked" else "rafi")
	get_node("UmbrellaStand/YellowUmbrella/GiftStarString").visible = gift_star.visible
	get_node("AmbientMotion").apply_preferences(reduced)
	get_node("Mira").apply_preferences(reduced)
	get_node("Rafi").visible = checkpoint != "complete"
	get_node("SignView").position = Vector3(4.0,2.9,-0.7) if raised else Vector3(-1.7,2.4,2.0)
	get_node("SignView").set_meta("look_at",sign.position+Vector3(0,-1.0,0))
	_update_interactions()
	set_meta("paper_checkpoint",checkpoint)

func _process(delta: float):
	if sign == null: return
	var current_reduced: bool = get_node("AmbientMotion").reduced if has_node("AmbientMotion") else reduced
	sign.advance_secondary(delta,current_reduced)
	silhouette.advance_secondary(delta,true)
	if current_reduced:
		gift_star.rotation.z = -0.16
		return
	decorative_elapsed += delta
	gift_star.rotation.z = -0.16+sin(decorative_elapsed*0.57)*0.013
