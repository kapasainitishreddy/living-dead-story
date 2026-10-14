extends Node3D
# Optional scenery: no progression, collision, rewards or persistent state.
const IDLES = ["sleep", "stretch", "groom"]
const FOLLOW_DISTANCE := 2.0
const PET_DISTANCE := 1.4
var player: Node3D
var visual: Node3D
var body: MeshInstance3D
var head: MeshInstance3D
var tail: Node3D
var reduced := false
var paused := false
var idle_state := "sleep"
var idle_index := 0
var elapsed := 0.0
var petted := false
func configure(factory, protagonist: Node3D, reduced_motion: bool):
	player = protagonist
	name = "CatCompanion"
	set_meta("action_id", "pet_cat")
	set_meta("label", "Pet the cat · optional")
	visual = Node3D.new()
	visual.name = "CatVisual"
	add_child(visual)
	var fur = Color("a88a70")
	body = factory.orb(visual, Vector3(0, 0.26, 0), 0.28, fur)
	body.scale = Vector3(0.85, 0.85, 1.5)
	head = factory.orb(visual, Vector3(0, 0.48, -0.33), 0.20, fur)
	for side in [-1.0, 1.0]:
		factory.rounded(head, "Ear", Vector3(side * 0.12, 0.17, 0), 0.0, 0.08, 0.18, fur)
		factory.orb(head, Vector3(side * 0.075, 0.025, -0.18), 0.025, Color("354352"))
		for z in [-0.23, 0.23]:
			factory.box(visual, "Paw", Vector3(side * 0.14, 0.08, z), Vector3(0.12, 0.14, 0.19), Color("dfd4b8"), false)
	tail = factory.rounded(visual, "Tail", Vector3(0, 0.35, 0.46), 0.045, 0.055, 0.44, fur)
	tail.rotation.x = 0.7
	factory.orb(head, Vector3(0, -0.04, -0.19), 0.035, Color("b77979"))
	apply_preferences(reduced_motion)
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
func set_paused(value: bool): paused = value
func pose():
	if visual == null: return
	visual.rotation = Vector3.ZERO
	body.scale = Vector3(0.85, 0.85, 1.5)
	head.position = Vector3(0, 0.48, -0.33)
	tail.rotation.x = 0.7
	if reduced:
		# An explicit pet can hold a still lean; there is no decorative animation.
		if petted: visual.rotation.z = -0.16
		return
	match idle_state:
		"sleep":
			body.scale.y = 0.55
			head.position.y = 0.27
		"stretch":
			body.scale.z = 1.85
			head.position = Vector3(0, 0.31, -0.46)
		"groom":
			head.position = Vector3(0.09, 0.30, -0.20)
		"react":
			tail.rotation.x = 0.1
			if petted: visual.rotation.z = -0.16
func _process(delta: float):
	if paused or not is_instance_valid(player): return
	# Keep the marker out of the interaction group until petting is in reach.
	if nearby():
		if not is_in_group("interactables"): add_to_group("interactables")
		if idle_state != "react":
			idle_state = "react"
			pose()
		if not reduced and petted:
			elapsed += delta
			visual.rotation.z = -0.16 + sin(elapsed * 3.0) * 0.012 # Visual purr.
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
		# Reduced motion uses an immediate placement, with no animated following.
		global_position = destination if reduced else global_position.move_toward(destination, delta * 1.2)
		rotation.y = atan2(-offset.x, -offset.z)
		return
	if reduced: return
	elapsed += delta
	if elapsed >= 5.0:
		elapsed = 0.0
		idle_index = (idle_index + 1) % IDLES.size()
		idle_state = IDLES[idle_index]
		pose()
