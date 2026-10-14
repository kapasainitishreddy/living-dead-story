extends Node3D
# Optional scenery: no progression, collision, rewards or persistent state.
# Sakura pass: rounder cel-shaded build (after Sakura Crossing's makeCat, MIT,
# (c) 2026 Kenton Wang) with soft procedural motion — eased follow with lag,
# trot bob and leg swing, breathing, blinking, a head that looks at you, ear
# flicks and a multi-segment tail sway. Pose changes blend instead of snapping.
const Style = preload("res://art/sakura/sakura_style.gd")
const IDLES = ["sleep", "stretch", "groom"]
const FOLLOW_DISTANCE := 2.0
const PET_DISTANCE := 1.4
const MAX_SPEED := 4.5
var player: Node3D
var visual: Node3D
var body: MeshInstance3D
var chest: MeshInstance3D
var head: Node3D
var tail: Node3D
var tail_segments: Array[Node3D] = []
var legs: Array[Node3D] = []
var ears: Array[Node3D] = []
var eyes: Array[MeshInstance3D] = []
var reduced := false
var paused := false
var idle_state := "sleep"
var idle_index := 0
var elapsed := 0.0
var petted := false
var anim_time := 0.0
var speed := 0.0
var stride := 0.0
var pose_target := {}
var pose_now := {}

func configure(factory, protagonist: Node3D, reduced_motion: bool):
	player = protagonist
	name = "CatCompanion"
	set_meta("action_id", "pet_cat")
	set_meta("label", "Pet the cat · optional")
	visual = Node3D.new()
	visual.name = "CatVisual"
	add_child(visual)
	var fur = Color("f0e6da")
	var saddle = Color("8a7d80")
	var dark = Color("39324f")
	body = _blob(visual, "Body", Vector3(0, 0.27, 0.02), Vector3(0.21, 0.19, 0.33), fur)
	_blob(body, "Saddle", Vector3(0, 0.38, 0.05), Vector3(0.9, 0.62, 0.85), saddle)
	chest = _blob(visual, "Chest", Vector3(0, 0.30, -0.20), Vector3(0.17, 0.18, 0.17), fur)
	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.50, -0.33)
	visual.add_child(head)
	_blob(head, "Skull", Vector3.ZERO, Vector3(0.15, 0.135, 0.135), fur)
	_blob(head, "Muzzle", Vector3(0, -0.04, -0.10), Vector3(0.07, 0.05, 0.05), Color("fbf6ee"))
	_blob(head, "Nose", Vector3(0, -0.015, -0.145), Vector3(0.018, 0.013, 0.012), Color("e0a0a8"))
	for side in [-1.0, 1.0]:
		var ear = Node3D.new()
		ear.position = Vector3(side * 0.085, 0.11, 0.0)
		ear.rotation.z = -side * 0.25
		head.add_child(ear)
		var cone = MeshInstance3D.new()
		var c = CylinderMesh.new()
		c.top_radius = 0.0; c.bottom_radius = 0.055; c.height = 0.11; c.radial_segments = 4
		cone.mesh = c
		cone.position.y = 0.045
		cone.material_override = Style.cel(saddle)
		ear.add_child(cone)
		ears.append(ear)
		eyes.append(_blob(head, "Eye", Vector3(side * 0.06, 0.02, -0.115), Vector3(0.022, 0.026, 0.012), dark, 0.0))
	for z in [-0.20, 0.20]:
		for side in [-1.0, 1.0]:
			var hip = Node3D.new()
			hip.position = Vector3(side * 0.10, 0.24, z)
			visual.add_child(hip)
			_blob(hip, "Leg", Vector3(0, -0.11, 0), Vector3(0.05, 0.12, 0.05), fur)
			_blob(hip, "Paw", Vector3(0, -0.22, -0.02), Vector3(0.055, 0.03, 0.065), Color("fbf6ee"))
			legs.append(hip)
	tail = Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.33, 0.32)
	visual.add_child(tail)
	var parent: Node3D = tail
	for i in 6:
		var seg = Node3D.new()
		seg.position = Vector3(0, 0, 0.0 if i == 0 else 0.075)
		parent.add_child(seg)
		_blob(seg, "TailSeg", Vector3(0, 0, 0.04), Vector3(0.034 - i * 0.003, 0.034 - i * 0.003, 0.05), saddle if i > 3 else fur)
		tail_segments.append(seg)
		parent = seg
	for g in visual.find_children("*", "GeometryInstance3D", true, false):
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	apply_preferences(reduced_motion)

func _blob(parent: Node3D, n: String, pos: Vector3, size_: Vector3, colour: Color, rim := 0.18) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	m.name = n
	var s = SphereMesh.new()
	s.radius = 1.0; s.height = 2.0; s.radial_segments = 14; s.rings = 8
	m.mesh = s
	m.position = pos
	m.scale = size_
	m.material_override = Style.cel(colour, rim)
	parent.add_child(m)
	return m

func nearby() -> bool:
	return is_instance_valid(player) and global_position.distance_to(player.global_position) <= PET_DISTANCE

func pet() -> bool:
	if paused or not nearby(): return false
	petted = true
	idle_state = "react"
	pose()
	return true

func apply_preferences(value: bool):
	reduced = value
	pose()
	if reduced: _settle()

func set_paused(value: bool): paused = value

func pose():
	# Choose the target silhouette; _animate eases toward it every frame.
	if visual == null: return
	var t = {"crouch": 0.0, "stretch": 0.0, "head_y": 0.50, "head_z": -0.33, "head_side": 0.0, "head_tilt": 0.0, "tail_lift": 0.35, "lean": 0.0}
	match idle_state:
		"sleep": t.crouch = 1.0; t.head_y = 0.27; t.head_z = -0.30; t.tail_lift = -0.2
		"stretch": t.stretch = 1.0; t.head_y = 0.33; t.head_z = -0.46; t.tail_lift = 0.9
		"groom": t.crouch = 0.4; t.head_y = 0.33; t.head_side = 0.10; t.head_z = -0.22; t.head_tilt = 0.5
		"react":
			t.tail_lift = 1.1
			if petted: t.lean = -0.16; t.head_tilt = -0.3
	pose_target = t
	if pose_now.is_empty(): pose_now = t.duplicate()
	if reduced:
		visual.rotation = Vector3.ZERO
		if petted: visual.rotation.z = -0.16

func _settle():
	pose_now = pose_target.duplicate()
	_apply_pose(0.0, 0.0, 1.0)

func _process(delta: float):
	if paused or not is_instance_valid(player): return
	if nearby():
		if not is_in_group("interactables"): add_to_group("interactables")
		if idle_state != "react":
			idle_state = "react"
			pose()
		if reduced: return
		if petted: elapsed += delta
		speed = lerpf(speed, 0.0, 1.0 - exp(-8.0 * delta))
		_face(player.global_position - global_position, delta, 4.0)
		_animate(delta)
		return
	remove_from_group("interactables")
	if idle_state == "react":
		petted = false
		idle_state = IDLES[idle_index]
		elapsed = 0.0
		pose()
	var offset = player.global_position - global_position
	offset.y = 0
	if offset.length() > FOLLOW_DISTANCE + 0.3:
		var destination = player.global_position - offset.normalized() * FOLLOW_DISTANCE
		destination.y = global_position.y
		if reduced:
			# Reduced motion uses an immediate placement, with no animated following.
			global_position = destination
			rotation.y = atan2(-offset.x, -offset.z)
			return
		# Eased follow with lag: speed approaches a distance-scaled target
		# (critically damped), integrated with the trapezoid rule.
		var gap = global_position.distance_to(destination)
		var wanted = clampf(gap * 1.6 + 0.6, 0.0, MAX_SPEED)
		var old_speed = speed
		speed = lerpf(speed, wanted, 1.0 - exp(-2.0 * delta))
		global_position = global_position.move_toward(destination, (old_speed + speed) * 0.5 * delta)
		if idle_state != "walk_follow":
			pose_target = {"crouch": 0.0, "stretch": 0.0, "head_y": 0.50, "head_z": -0.33, "head_side": 0.0, "head_tilt": 0.0, "tail_lift": 0.55, "lean": 0.0}
		_face(offset, delta, 6.0)
		_animate(delta)
		return
	speed = lerpf(speed, 0.0, 1.0 - exp(-6.0 * delta))
	if reduced: return
	elapsed += delta
	if elapsed >= 5.0:
		elapsed = 0.0
		idle_index = (idle_index + 1) % IDLES.size()
		idle_state = IDLES[idle_index]
		pose()
	elif pose_target.get("tail_lift", 0.0) == 0.55:
		pose()
	_animate(delta)

func _face(direction: Vector3, delta: float, rate: float):
	direction.y = 0
	if direction.length() < 0.05: return
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-rate * delta))

func _animate(delta: float):
	if reduced or visual == null: return
	anim_time += delta
	var k = 1.0 - exp(-5.0 * delta)
	for key in pose_target:
		pose_now[key] = lerpf(pose_now.get(key, pose_target[key]), pose_target[key], k)
	stride = lerpf(stride, clampf(speed / 2.5, 0.0, 1.0), 1.0 - exp(-8.0 * delta))
	_apply_pose(anim_time, stride, k)

func _apply_pose(t: float, move: float, _k: float):
	var p = pose_now
	var gait = t * (6.0 + 6.0 * move)
	var breath = sin(t * (1.4 if p.crouch > 0.5 else 2.2)) * (1.0 - move)
	# Soft body: footfall bounce, squash on contact, breathing in the chest.
	var bounce = absf(sin(gait)) * 0.035 * move
	var squash = (0.5 - absf(sin(gait))) * 0.06 * move
	visual.position = Vector3(0, bounce - p.crouch * 0.11, 0)
	visual.rotation = Vector3(sin(gait * 2.0) * 0.03 * move, 0, p.lean + sin(gait) * 0.03 * move)
	body.scale = Vector3(0.21 * (1.0 + breath * 0.025 - squash * 0.5), 0.19 * (1.0 + breath * 0.04 + squash - p.crouch * 0.25), 0.33 * (1.0 + p.stretch * 0.35))
	chest.position = Vector3(0, 0.30 - p.stretch * 0.08, -0.20 - p.stretch * 0.08)
	# Head: blends to the pose, then looks at the player when awake.
	var look_yaw := 0.0
	var look_pitch := 0.0
	if is_instance_valid(player) and p.crouch < 0.6:
		var local = to_local(player.global_position + Vector3(0, 1.2, 0)) - head.position
		look_yaw = clampf(atan2(-local.x, -local.z), -0.8, 0.8)
		look_pitch = clampf(atan2(local.y, Vector2(local.x, local.z).length()), -0.2, 0.5)
	head.position = Vector3(p.head_side, p.head_y + sin(gait * 2.0 + 0.6) * 0.012 * move + breath * 0.004, p.head_z)
	head.rotation = Vector3(lerpf(head.rotation.x, look_pitch * (1.0 - move * 0.6), 0.15), lerp_angle(head.rotation.y, look_yaw * (1.0 - move * 0.5), 0.12), p.head_tilt + sin(t * 0.7) * 0.05 * (1.0 - move))
	# Legs: diagonal pairs swing opposite; tucked when sleeping.
	for i in legs.size():
		var pair = 1.0 if i in [0, 3] else -1.0
		legs[i].rotation.x = sin(gait) * 0.6 * move * pair
		legs[i].scale.y = 1.0 - p.crouch * 0.6
	# Ears: occasional flick.
	var flick = fposmod(t, 4.3)
	for i in ears.size():
		var side = -1.0 if i == 0 else 1.0
		ears[i].rotation.z = -side * 0.25 + (side * 0.35 * sin(flick / 0.25 * PI) if flick < 0.25 and i == 1 else 0.0)
	# Blink (closed while asleep).
	var blink = 1.0
	var bp = fposmod(t, 3.7)
	if bp < 0.14: blink = absf(cos(bp / 0.14 * PI))
	if p.crouch > 0.6: blink = 0.1
	for e in eyes: e.scale.y = 0.026 * maxf(blink, 0.08)
	# Tail: a travelling wave down the chain, lifted by mood.
	tail.rotation.x = -p.tail_lift
	for i in tail_segments.size():
		var amp = 0.10 + i * 0.05
		tail_segments[i].rotation.y = sin(t * (1.8 + move * 2.5) - i * 0.6) * amp
		tail_segments[i].rotation.x = -0.12 * p.tail_lift + (0.18 if p.crouch > 0.6 else 0.0)
