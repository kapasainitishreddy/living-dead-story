extends Node3D
# The fair uses authored paths, not a hidden skill test or random standings.
# All positions are pond-local; the player and camera remain on the dry deck.
signal completed
const DURATION := 4.2
const WINDING_DURATION := 0.35
const STARTS = [Vector3(-1.05,0.02,1.58),Vector3(0,0.02,1.58),Vector3(1.05,0.02,1.58)]
const TITLES = {"crooked":"All three finished at the duck", "first":"First across", "second":"Second across", "third":"Third across", "circle":"A circular route", "spectator":"For the audience"}
var factory: RefCounted
var boats: Node3D
var routes: Node3D
var configuration_label: Label3D
var result_label: Label3D
var arrow: Node3D
var state: Dictionary = {}
var running := false
var paused := false
var reduced := false
var elapsed := 0.0
var pending_completion := false

func configure(helper: RefCounted):
	factory = helper
	name = "FairRace"
	boats = Node3D.new()
	boats.name = "Boats"
	add_child(boats)
	for i in range(3): _make_boat(i)
	routes = Node3D.new()
	routes.name = "RouteTraces"
	add_child(routes)
	configuration_label = _label("ConfigurationLabel","Straight rudder · Triangle sail",Vector3(0,0.93,2.15),23)
	result_label = _label("ResultLabel","",Vector3(0,1.38,-2.1),25)
	arrow = Node3D.new()
	arrow.name = "RudderPreviewArrow"
	arrow.position = Vector3(-1.05,0.04,1.1)
	add_child(arrow)
	factory.box(arrow,"ArrowStem",Vector3(0,0,-0.18),Vector3(0.035,0.025,0.36),Color("f4e7bc"),false)
	for side in [-1.0,1.0]:
		var head = factory.box(arrow,"ArrowHead",Vector3(side*0.055,0,-0.36),Vector3(0.03,0.025,0.17),Color("f4e7bc"),false)
		head.rotation.y = side*0.7
	# A high-contrast physical finish ribbon and paired flags, not color-only UI.
	factory.box(self,"FinishRibbon",Vector3(0,0.025,-1.8),Vector3(3.65,0.012,0.09),Color("f4e7bc"),false)
	for side in [-1.0,1.0]:
		factory.rounded(self,"FinishPost",Vector3(side*1.97,0.35,-1.8),0.025,0.025,0.7,Color("a98650"))
		factory.box(self,"FinishFlag",Vector3(side*1.83,0.58,-1.8),Vector3(0.24,0.16,0.025),Color("f4e7bc"),false)
	_label("FinishLabel","FINISH",Vector3(0,0.75,-2.25),20)

func _label(id: String, text_: String, where: Vector3, size_: int) -> Label3D:
	factory.label(self,text_,where,size_)
	var result = get_child(get_child_count()-1) as Label3D
	result.name = id
	return result

func _make_boat(index: int):
	var boat = Node3D.new()
	boat.name = ["PlayerBoat","MiraBoat","AdaBoat"][index]
	boat.position = STARTS[index]
	boat.set_meta("boat_number",index+1)
	boats.add_child(boat)
	var colors = [Color("527da8"),Color("bc795e"),Color("758d76")]
	var hull = factory.rounded(boat,"PaintedHull",Vector3(0,0.055,0),0.2,0.16,0.09,colors[index])
	hull.scale = Vector3(0.8,1,1.8)
	factory.box(boat,"Deck",Vector3(0,0.11,0),Vector3(0.22,0.018,0.43),Color("ead6ac"),false)
	var prow = factory.box(boat,"FoldedProw",Vector3(0,0.085,-0.23),Vector3(0.18,0.065,0.16),colors[index],false)
	prow.rotation.y = PI/4
	factory.rounded(boat,"Mast",Vector3(0,0.38,-0.04),0.017,0.017,0.53,Color("6f5038"))
	var sail = MeshInstance3D.new()
	sail.name = "PaperSail"
	sail.position = Vector3(0,0.17,-0.04)
	sail.mesh = _sail_mesh("triangle")
	var material = factory.shared_material(Color("f4e7bc"),0.9).duplicate()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	sail.material_override = material
	boat.add_child(sail)
	var rudder = factory.box(boat,"Rudder",Vector3(0,0.06,0.34),Vector3(0.025,0.13,0.19),Color("9a734e"),false)
	rudder.set_meta("rudder","straight")
	factory.rounded(boat,"WindupKeyShaft",Vector3(0.15,0.13,0.13),0.017,0.017,0.13,Color("c39b55"))
	var key = factory.orb(boat,Vector3(0.15,0.2,0.13),0.06,Color("c39b55"))
	key.name = "WindupKey"
	key.scale = Vector3(1.35,0.48,0.45)
	factory.label(boat,str(index+1),Vector3(0,0.43,0.01),18)
	boat.get_child(boat.get_child_count()-1).name = "BoatNumber"
	boat.set_meta("sail","triangle")

func _sail_mesh(shape: String) -> ArrayMesh:
	var vertices: Array[Vector3]
	match shape:
		"square": vertices = [Vector3(-0.23,0.04,0),Vector3(0.23,0.04,0),Vector3(0.23,0.44,0),Vector3(-0.23,0.44,0)]
		"folded": vertices = [Vector3(-0.25,0.2,0),Vector3(0,0,0.07),Vector3(0.25,0.2,0),Vector3(0,0.48,0.07)]
		_: vertices = [Vector3(-0.23,0.02,0),Vector3(0.23,0.02,0),Vector3(-0.01,0.48,0)]
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(1,vertices.size()-1):
		for vertex in [vertices[0],vertices[j],vertices[j+1]]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()

func apply_snapshot(snapshot: Dictionary):
	state = snapshot.get("fair",{}).duplicate(true)
	apply_preferences(bool(snapshot.get("settings",{}).get("reduced_motion",false)))
	var rudder = str(state.get("rudder","straight"))
	var sail = str(state.get("sail","triangle"))
	var mode = str(state.get("mode","operate"))
	var angle = {"left":-0.45,"straight":0.0,"right":0.45}.get(rudder,0.0)
	var boat = boats.get_node("PlayerBoat")
	if str(boat.get_meta("sail","triangle")) != sail:
		boat.get_node("PaperSail").mesh = _sail_mesh(sail)
	boat.set_meta("sail",sail)
	boat.get_node("Rudder").rotation.y = angle
	boat.get_node("Rudder").set_meta("rudder",rudder)
	arrow.rotation.y = angle
	configuration_label.text = "%s rudder · %s sail\n%s" % [rudder.capitalize(),sail.capitalize(),{"operate":"Your boat is number 1","watch":"Mira will demonstrate · your boat is number 1","cooperate":"Set it together · your boat is number 1"}.get(mode,"Your boat is number 1")]
	if running: return
	_set_winding_phase(0.0)
	var checkpoint = str(snapshot.get("fair_checkpoint","workshop"))
	var at_result = checkpoint in ["crooked_race","level_pond","result","complete"]
	result_label.text = TITLES.get(str(state.get("outcome","unselected")),"") if at_result else ""
	for i in range(3): _place_boat(i,1.0 if at_result else 0.0)
	arrow.visible = not at_result
	_update_routes(at_result)

func sample_position(index: int, progress: float, fair: Dictionary) -> Vector3:
	var t = clampf(progress,0.0,1.0)
	var start: Vector3 = STARTS[clampi(index,0,2)]
	if not bool(fair.get("levelled",false)):
		var finish = Vector3(-1.64+index*0.16,0.02,-1.62+index*0.15)
		var control = Vector3(-1.65+index*0.07,0.02,0.2)
		return start*(1-t)*(1-t)+control*2*(1-t)*t+finish*t*t
	var outcome = str(fair.get("outcome","unselected"))
	if index == 0 and outcome == "circle":
		# Deliberately stays in the pond; no failure animation or lost boat.
		var phase = t*TAU
		return start+Vector3(sin(phase)*0.76,0,(-1+cos(phase))*0.78)
	var finish_progress = t
	var lateral = 0.0
	var player_finish_time: float = {"first":0.72,"second":0.85,"third":0.97,"spectator":0.85}.get(outcome,0.85)
	if index == 0:
		finish_progress = clampf(t/player_finish_time,0,1)
		lateral = {"left":-0.6,"right":0.75,"straight":0.23}.get(str(fair.get("rudder","straight")),0.23)
	else:
		var opponent_time = 0.83 if outcome == "first" else 0.74
		if index == 2: opponent_time = 0.86 if outcome == "third" else 0.96
		finish_progress = clampf(t/opponent_time,0,1)
		lateral = 0.12 if index == 1 else -0.2
	var eased = finish_progress*(0.8+0.2*finish_progress)
	return start+Vector3(lateral*sin(eased*PI/2),0,-3.68*eased)

func _place_boat(index: int, progress: float):
	var boat = boats.get_child(index) as Node3D
	var here = sample_position(index,progress,state)
	var before = sample_position(index,maxf(0,progress-0.015),state)
	var after = sample_position(index,minf(1,progress+0.015),state)
	var tangent = after-before
	boat.position = here
	if tangent.length_squared() > 0.00001: boat.rotation.y = atan2(-tangent.x,-tangent.z)
	boat.rotation.z = 0.0 # No functional camera or hull bobbing.

func _update_routes(show_paths: bool):
	for child in routes.get_children():
		routes.remove_child(child)
		child.free()
	routes.visible = show_paths
	if not show_paths: return
	# Static dashed trajectories provide the whole event in reduced motion.
	for index in range(3):
		for segment in range(16):
			var a = sample_position(index,float(segment)/16.0,state)
			var b = sample_position(index,(float(segment)+0.66)/16.0,state)
			var trace = factory.box(routes,"Boat%dTrace%02d" % [index+1,segment],(a+b)*0.5+Vector3(0,0.002,0),Vector3(0.016,0.008,a.distance_to(b)),Color("c7e3dc"),false)
			trace.rotation.y = atan2(b.x-a.x,b.z-a.z)

func play_race(snapshot: Dictionary, _replay: bool = false):
	if running: return
	apply_snapshot(snapshot)
	elapsed = 0.0
	paused = false
	_set_winding_phase(0.0)
	arrow.visible = false
	configuration_label.visible = false
	result_label.text = "Three boats · toward the duck" if not bool(state.get("levelled",false)) else "Three boats · a level pond"
	_update_routes(reduced)
	if reduced:
		for i in range(3): _place_boat(i,1.0)
		result_label.text = TITLES.get(str(state.get("outcome","unselected")),"Race complete")
		configuration_label.visible = true
		# Deferred so callers can start the race and then await completed safely.
		pending_completion = true
		call_deferred("_emit_completion")
		return
	running = true
	for i in range(3): _place_boat(i,0.0)

func set_paused(value: bool):
	paused = value

func apply_preferences(value: bool):
	reduced = value
	if running and reduced: _update_routes(true)

func _set_winding_phase(progress: float):
	for boat in boats.get_children():
		boat.get_node("WindupKey").rotation.y = TAU*2.0*progress if progress < 1.0 else 0.0

func advance_race(delta: float):
	if not running or paused: return
	elapsed = DURATION if reduced else minf(elapsed+delta,DURATION)
	_set_winding_phase(clampf(elapsed/WINDING_DURATION,0.0,1.0))
	var progress = clampf((elapsed-WINDING_DURATION)/(DURATION-WINDING_DURATION),0.0,1.0)
	for i in range(3): _place_boat(i,progress)
	if progress >= 1.0:
		running = false
		result_label.text = TITLES.get(str(state.get("outcome","unselected")),"Race complete")
		configuration_label.visible = true
		_update_routes(true)
		completed.emit()

func _emit_completion():
	if not pending_completion: return
	pending_completion = false
	completed.emit()

func _process(delta: float):
	advance_race(delta)
