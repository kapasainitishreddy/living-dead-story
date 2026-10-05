extends Node3D
# The actual Chapter One apartment, with saved ordinary acts added to it.
# Canonical choices are owned by the chapter model, never by this performance.
signal ending_finished
const ENDING_DURATION := 5.2
const TICKET_PLACES = {
	"kettle":Vector3(4.84,1.433,-2.59),
	"drawer":Vector3(4.0,1.155,-1.87),
	"pocket":Vector3(6.78,1.495,-7.602)
}
var factory: RefCounted
var snapshot: Dictionary = {}
var interactions: Node3D
var paused := false
var reduced_motion := false
var ending_active := false
var ending_elapsed := 0.0
var ending_duration := ENDING_DURATION
var presentation_ending := "unselected"
var ending_completion := Callable()
var _lamps: Array[OmniLight3D] = []
var _lamp_base_energies: Array[float] = []
var showing_close_view := false
var window_sitter: Node3D

func build(value: Dictionary) -> Node3D:
	name = "World"
	factory = load("res://world/world_factory.gd").new()
	# Do not recreate this room from similar-looking boxes. Keep the real build.
	var apartment = factory.build("apartment")
	set_meta("efficient_medium_aa",apartment.get_meta("efficient_medium_aa",false))
	for child in apartment.get_children():
		if child.has_meta("action_id") or (child is Label3D and (child.text.begins_with("3:17") or child.text == "Go up to the roof")):
			child.free()
			continue
		apartment.remove_child(child)
		add_child(child)
		if child is OmniLight3D:
			_lamps.append(child)
			_lamp_base_energies.append(child.light_energy)
	apartment.free()
	interactions = Node3D.new()
	interactions.name = "Interactions"
	add_child(interactions)
	_marker("HomeView",Vector3(0.0,2.48,1.76),Vector3(0.0,1.55,-5.0),51.0)
	_marker("TicketView",Vector3(4.10,2.05,-1.18),Vector3(4.1,1.44,-2.93),46.0)
	_marker("WindowView",Vector3(-4.8,2.15,-7.38),Vector3(-5.0,2.5,-10.75),48.0)
	_marker("BedView",Vector3(-1.95,2.12,1.06),Vector3(-4.0,0.98,-2.1),48.0)
	_build_ticket()
	_build_steam()
	_build_window_sitter()
	apply_state(value)
	return self

func _ready():
	_pose_window_sitter()
	_apply_weather()
	get_node("AmbientMotion").apply_preferences(reduced_motion)
	_apply_weather()

func _marker(id: String, where: Vector3, look: Vector3, fov: float) -> Marker3D:
	var marker = Marker3D.new()
	marker.name = id
	marker.position = where
	marker.set_meta("look_at",look)
	marker.set_meta("fov",fov)
	add_child(marker)
	return marker

func _build_ticket():
	var ticket = Node3D.new()
	ticket.name = "HomeTicket"
	add_child(ticket)
	factory.box(ticket,"WornPaper",Vector3.ZERO,Vector3(0.36,0.012,0.20),Color("d6c7a7"),false)
	for z in [-0.078,0.078]: factory.box(ticket,"InkBorder",Vector3(0,0.008,z),Vector3(0.315,0.002,0.005),Color("727a82"),false)
	for x in [-0.153,0.153]: factory.box(ticket,"InkBorderSide",Vector3(x,0.008,0),Vector3(0.005,0.002,0.16),Color("727a82"),false)
	for line in range(3): factory.box(ticket,"OrdinaryPrint",Vector3(-0.044,0.009,-0.023+line*0.027),Vector3(0.125 if line != 1 else 0.172,0.002,0.006),Color("727a82"),false)
	for i in range(5): factory.box(ticket,"Perforation",Vector3(0.101,0.01,-0.052+i*0.025),Vector3(0.004,0.002,0.009),Color("9a927f"),false)
	ticket.set_meta("souvenir_id","platform_ticket")
	ticket.hide()

func _build_steam():
	var steam = CPUParticles3D.new()
	steam.name = "TeaSteam"
	steam.position = Vector3(3.2,1.78,-2.7)
	steam.amount = 9
	steam.lifetime = 2.4
	steam.preprocess = 2.4
	steam.direction = Vector3.UP
	steam.gravity = Vector3.ZERO
	steam.initial_velocity_min = 0.12
	steam.initial_velocity_max = 0.19
	steam.spread = 12
	steam.color = Color(0.82,0.86,0.9,0.09)
	var puff = SphereMesh.new()
	puff.radius = 0.035
	puff.height = 0.07
	steam.mesh = puff
	steam.hide()
	add_child(steam)

func _build_window_sitter():
	# This is the same protagonist asset as the walking player, shown only while
	# the runtime hides its walking instance for the optional stationary view.
	window_sitter = factory.production_character(self,Vector3(-6.35,-0.28,-8.65),"protagonist")
	window_sitter.name = "WindowSitter"
	window_sitter.rotation.y = PI
	window_sitter.set_meta("seated",true)
	window_sitter.set_process(false)
	window_sitter.hide()

func _pose_window_sitter():
	if not is_instance_valid(window_sitter) or window_sitter.skeleton == null: return
	# Script _process is enabled automatically when a node enters the tree.
	# Disable it after the rig is ready: it manually advances even an inactive tree.
	window_sitter.set_process(false)
	window_sitter.animation_tree.active = false
	window_sitter.skeleton.reset_bone_poses()
	for id in ["ThighLeft","ThighRight","ShinLeft","ShinRight","UpperArmLeft","UpperArmRight","ForearmLeft","ForearmRight"]:
		window_sitter.bones[id] = window_sitter._bone_index(id)
	for side in ["Left","Right"]:
		window_sitter._offset_bone("Thigh"+side,0.0,-PI/2)
		window_sitter._offset_bone("Shin"+side,0.0,PI/2)
		window_sitter._offset_bone("UpperArm"+side,0.0,-0.20)
		window_sitter._offset_bone("Forearm"+side,0.0,-0.95)
	window_sitter._offset_bone("Chest",0.0,0.055)
	window_sitter._offset_bone("Head",0.0,0.045)
	window_sitter.skeleton.force_update_all_bone_transforms()

func set_close_view(value: bool):
	showing_close_view = value
	var home: Dictionary = snapshot.get("home",{})
	window_sitter.visible = value and str(home.get("ritual","unselected")) == "window" and str(home.get("ending","unselected")) != "sleep"
	_pose_window_sitter()

func apply_state(value: Dictionary):
	snapshot = value.duplicate(true)
	ending_active = false
	ending_elapsed = 0.0
	ending_completion = Callable()
	var home: Dictionary = snapshot.get("home",{})
	var ticket = str(home.get("ticket","unselected"))
	var ritual = str(home.get("ritual","unselected"))
	var ending = str(home.get("ending","unselected"))
	set_meta("ending",ending)
	set_meta("home_checkpoint",snapshot.get("home_checkpoint","arrival"))
	presentation_ending = ending
	var physical_ticket = get_node("HomeTicket")
	physical_ticket.visible = TICKET_PLACES.has(ticket)
	physical_ticket.set_meta("location",ticket)
	physical_ticket.position = TICKET_PLACES.get(ticket,Vector3.ZERO)
	physical_ticket.rotation = Vector3.ZERO
	physical_ticket.scale = Vector3.ONE
	if ticket == "pocket":
		physical_ticket.rotation.x = PI/2
		physical_ticket.scale.x = 0.55
	elif ticket == "kettle": physical_ticket.rotation.y = -0.13
	var drawer = get_node("ApartmentProps/Drawer")
	drawer.get_node("Tray").visible = ticket == "drawer"
	drawer.get_node("Tray").position.z = 0.43 if ticket == "drawer" else 0.0
	drawer.get_node("Front").position.z = 0.43 if ticket == "drawer" else 0.0
	drawer.get_node("Pull").position.z = 0.466 if ticket == "drawer" else 0.036
	get_node("ApartmentProps/Mug/Tea").visible = ritual == "tea"
	get_node("ApartmentProps/Mug").set_meta("ritual",ritual)
	get_node("WindowView").set_meta("ritual",ritual)
	var home_view = get_node("HomeView")
	if ending == "sleep":
		var bed_view = get_node("BedView")
		home_view.position = bed_view.position
		home_view.set_meta("look_at",bed_view.get_meta("look_at"))
		home_view.set_meta("fov",bed_view.get_meta("fov"))
	elif ritual == "window":
		home_view.position = Vector3(-4.28,1.72,-6.72)
		home_view.set_meta("look_at",Vector3(-6.15,1.03,-8.82))
		home_view.set_meta("fov",48.0)
	else:
		home_view.position = Vector3(0.0,2.48,1.76)
		home_view.set_meta("look_at",Vector3(0.0,1.55,-5.0))
		home_view.set_meta("fov",51.0)
	set_close_view(showing_close_view)
	_set_light_fraction(1.0 if ending in ["train","sleep"] else 0.0)
	_build_interactions()
	set_reduced_motion(bool(snapshot.get("settings",{}).get("reduced_motion",false)))

func apply_snapshot(value: Dictionary):
	apply_state(value)

func _target(id: String, where: Vector3, text_: String):
	var target = Marker3D.new()
	target.name = id
	target.position = where
	target.set_meta("action_id",id)
	target.set_meta("label",text_)
	target.set_meta("value",null)
	target.add_to_group("interactables")
	interactions.add_child(target)

func _build_interactions():
	for child in interactions.get_children(): child.free()
	var home: Dictionary = snapshot.get("home",{})
	var checkpoint = str(snapshot.get("home_checkpoint","arrival"))
	_target("home_state",Vector3(0,0,3.4),"The same apartment")
	_target("home_view",Vector3(2,0,1),"Look around the room")
	_target("home_ticket",Vector3(4,0,-1.6),"The ticket · kettle, drawer or pocket")
	if str(home.get("ticket","unselected")) in ["kettle","drawer","pocket"]:
		_target("home_ritual",Vector3(-6.15,0,-7.0),"Tea, the window, or neither")
	if checkpoint in ["settled","complete"]:
		_target("home_end",Vector3(-1.25,0,-1),"Think of the train, or sleep")

func _apply_weather():
	if not has_node("Rain"): return
	get_node("Rain").visible = not reduced_motion
	get_node("Rain").speed_scale = 0.0 if paused else 1.0
	var tea_selected = str(snapshot.get("home",{}).get("ritual","unselected")) == "tea"
	get_node("TeaSteam").visible = tea_selected and not reduced_motion
	get_node("TeaSteam").speed_scale = 0.0 if paused else 1.0
	get_node("AmbientMotion").set_process(not paused)

func set_reduced_motion(value: bool):
	reduced_motion = value
	get_node("AmbientMotion").apply_preferences(value)
	_apply_weather()
	_pose_window_sitter()
	if reduced_motion and ending_active and not paused: finish_ending()

func apply_preferences(value: bool):
	set_reduced_motion(value)

func set_paused(value: bool):
	paused = value
	_apply_weather()
	if not paused and reduced_motion and ending_active: finish_ending()

func begin_ending(value: String, completion: Callable = Callable()):
	if value not in ["train","sleep"]: return
	# The runtime has already persisted the chosen ending. No light or wait gates it.
	presentation_ending = value
	ending_elapsed = 0.0
	ending_completion = completion
	ending_active = true
	_set_light_fraction(0.0)
	if reduced_motion and not paused: finish_ending()

func _set_light_fraction(fraction: float):
	# Only the existing room lamps soften. There is no new glow, reward prop or song.
	var multiplier = lerpf(1.0,0.8,fraction) if presentation_ending == "sleep" else 1.0
	for i in range(_lamps.size()): _lamps[i].light_energy = _lamp_base_energies[i]*multiplier

func _process(delta: float):
	if paused or not ending_active: return
	ending_elapsed = minf(ending_duration,ending_elapsed+delta)
	_set_light_fraction(smoothstep(0.0,1.0,ending_elapsed/ending_duration))
	if ending_elapsed >= ending_duration: finish_ending()

func finish_ending():
	if not ending_active: return
	ending_active = false
	ending_elapsed = ending_duration
	_set_light_fraction(1.0)
	var completion = ending_completion
	ending_completion = Callable()
	ending_finished.emit()
	if completion.is_valid(): completion.call()

func cinematic_camera_path() -> NodePath:
	return NodePath("HomeView")

func cinematic_state() -> Dictionary:
	return {"active":ending_active,"elapsed":ending_elapsed,"ending":presentation_ending,"camera":get_node("HomeView").transform,"rain_speed":get_node("Rain").speed_scale,"steam_speed":get_node("TeaSteam").speed_scale,"light_energy":_lamps[0].light_energy if not _lamps.is_empty() else 0.0}
