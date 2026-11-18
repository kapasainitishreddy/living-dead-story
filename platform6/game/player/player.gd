extends CharacterBody3D
signal interact(target)
var enabled := true
var preferences = {"sensitivity":1.0,"reduced_motion":false}
var pivot: Node3D
var arm: SpringArm3D
var visual: Node3D
const Performer = preload("res://characters/character_performer.gd")
var nearest: Node3D
var touch_move := Vector2.ZERO
# Delay idle attention so nearby props feel discoverable without distracting jitter.
var glance_candidate: Node3D
var glance_dwell := 0.0
const INTERACT_RADIUS := 3.2
const INTERACT_SWITCH_MARGIN := 0.28
var touch_mode := OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
func _ready():
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	var shape = CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	visual = Performer.new()
	visual.name = "Protagonist"
	visual.configure("protagonist")
	add_child(visual)
	visual.rotation.y = PI
	pivot = Node3D.new()
	pivot.position = Vector3(0.62,1.55,0)
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.spring_length = 3.9
	arm.margin = 0.25
	arm.rotation.x = -0.22
	pivot.add_child(arm)
	arm.add_excluded_object(get_rid())
	var camera = Camera3D.new()
	camera.current = true
	camera.fov = 54
	arm.add_child(camera)
	_make_contact_shadow()
func set_controls_enabled(value: bool):
	enabled = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value and not touch_mode else Input.MOUSE_MODE_VISIBLE
	if not enabled:
		update_nearby_attention(null,0.0,0.0)
		touch_move = Vector2.ZERO
		velocity = Vector3.ZERO
		if visual: visual.set_locomotion(0.0)
func set_touch_mode(value: bool):
	if touch_mode == value: return
	touch_mode = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled and not value else Input.MOUSE_MODE_VISIBLE
func look_by(relative: Vector2):
	if not enabled: return
	pivot.rotation.y -= relative.x * 0.003 * preferences.sensitivity
	arm.rotation.x = clamp(arm.rotation.x - relative.y * 0.0025 * preferences.sensitivity,-0.65,0.65)
func reset_view():
	if not enabled: return
	pivot.rotation.y = 0
	arm.rotation.x = -0.22
func set_preferences(settings: Dictionary):
	preferences = settings.duplicate(true)
	if visual: visual.apply_preferences(bool(preferences.get("reduced_motion",false)))
	update_nearby_attention(null,0.0,0.0)
	if preferences.reduced_motion and framing_tween and framing_tween.is_running():
		framing_tween.kill()
func _unhandled_input(event):
	if not enabled: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look_by(event.relative)
	if event.is_action_pressed("reset_camera"):
		reset_view()
	if event.is_action_pressed("interact") and is_instance_valid(nearest): interact.emit(nearest)
func _physics_process(delta):
	nearest = choose_nearest_interactable()
	if not enabled: return
	pivot.rotation.y -= Input.get_axis("look_left","look_right") * delta * 1.8 * preferences.sensitivity
	arm.rotation.x = clamp(arm.rotation.x + Input.get_axis("look_up","look_down") * delta * 1.2 * preferences.sensitivity,-0.65,0.65)
	var input = (Input.get_vector("move_left","move_right","move_forward","move_back") + touch_move).limit_length()
	var direction = pivot.global_basis * Vector3(input.x,0,input.y)
	velocity.x = move_toward(velocity.x,direction.x*4.2,delta*15)
	velocity.z = move_toward(velocity.z,direction.z*4.2,delta*15)
	if not is_on_floor(): velocity.y -= 18*delta
	else: velocity.y = 0
	move_and_slide()
	var heading_change := 0.0
	if direction.length() > 0.1:
		heading_change = wrapf(atan2(direction.x,direction.z)-visual.rotation.y,-PI,PI)
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),gait_weight(delta))
	var horizontal_speed = Vector2(velocity.x,velocity.z).length()
	visual.position.y = 0.0 # gait animates the body; no camera bob
	visual.set_locomotion(horizontal_speed,heading_change)
	update_nearby_attention(nearest,horizontal_speed,delta)

func choose_nearest_interactable() -> Node3D:
	# Keep an existing nearby discovery until another is clearly closer.
	# The HUD, E/A interaction and delayed eye/head attention use this target.
	var closest: Node3D = null
	var closest_distance: float = INTERACT_RADIUS
	var previous_distance: float = INF
	for node in get_tree().get_nodes_in_group("interactables"):
		if not (node is Node3D):
			continue
		var target: Node3D = node as Node3D
		if target.is_queued_for_deletion():
			continue
		var distance: float = global_position.distance_to(target.global_position)
		if target == nearest:
			previous_distance = distance
		if distance < closest_distance:
			closest_distance = distance
			closest = target
	# Never retain deleted, removed or out-of-range targets.
	if is_instance_valid(nearest) and previous_distance < INTERACT_RADIUS:
		if closest != nearest and closest_distance + INTERACT_SWITCH_MARGIN >= previous_distance:
			return nearest
	return closest

func update_nearby_attention(target: Node3D, horizontal_speed: float, delta: float):
	# Use the existing character eye-first/head-follow rig, not camera motion.
	# Require 200ms at rest near a stable target; never stare while walking.
	var calm: bool = enabled and not bool(preferences.get("reduced_motion",false)) and horizontal_speed < 0.36 and is_instance_valid(target)
	if not calm:
		glance_candidate = null
		glance_dwell = 0.0
		if is_instance_valid(visual): visual.set_attention_target(null)
		return
	if glance_candidate != target:
		glance_candidate = target
		glance_dwell = 0.0
	glance_dwell += maxf(0.0,delta)
	if is_instance_valid(visual):
		visual.set_attention_target(target if glance_dwell >= 0.2 else null)

func gait_weight(delta: float) -> float:
	# Frame-rate independent damping, inspired by Sakura Crossing (MIT).
	return 1.0-exp(-10.0*delta)

var framed := false
var normal_yaw := 0.0
var normal_pitch := 0.0
var framing_tween: Tween
var dialogue_camera: Camera3D
var dialogue_visual_was_visible := true
func set_framed_view(value: bool):
	if not value and is_instance_valid(dialogue_camera):
		dialogue_camera.current=false
		dialogue_camera.queue_free()
		dialogue_camera=null
		arm.get_child(0).current=true
		visual.visible=dialogue_visual_was_visible
	if framed == value: return
	if framing_tween and framing_tween.is_running(): framing_tween.kill()
	framed = value
	if value:
		normal_yaw = pivot.rotation.y
		normal_pitch = arm.rotation.x
	var yaw = normal_yaw
	var pitch = -0.12 if value else normal_pitch
	if preferences.reduced_motion:
		# Leave the player-selected orbit untouched; no automated pan or snap.
		return
	else:
		framing_tween = create_tween().set_parallel(true)
		framing_tween.tween_property(pivot,"rotation:y",yaw,0.45)
		framing_tween.tween_property(arm,"rotation:x",pitch,0.45)

func _make_contact_shadow():
	var shadow = MeshInstance3D.new()
	shadow.name = "ContactShadow"
	var plane = PlaneMesh.new()
	plane.size = Vector2(0.82,0.70)
	shadow.mesh = plane
	shadow.position.y = 0.018
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader = Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded, cull_disabled, depth_draw_never; void fragment(){ vec2 p=(UV-vec2(.5))*2.; float edge=1.-smoothstep(.20,1.,dot(p,p)); ALBEDO=vec3(.07,.08,.11); ALPHA=edge*.22; }"
	var mat = ShaderMaterial.new()
	mat.shader = shader
	shadow.material_override = mat
	add_child(shadow)

func frame_speaker(target: Node3D):
	if not framed or not is_instance_valid(target) or preferences.get("reduced_motion",false): return
	if framing_tween and framing_tween.is_running(): framing_tween.kill()
	var away=global_position-target.global_position
	away.y=0.0
	if away.length()<.2:return
	away=away.normalized()
	var side=Vector3(away.z,0,-away.x)
	if not is_instance_valid(dialogue_camera):
		dialogue_camera=Camera3D.new()
		dialogue_camera.name="SpeakerCamera"
		add_child(dialogue_camera)
		dialogue_visual_was_visible=visual.visible
	# An authored portrait, composed above the lower dialogue panel. Gameplay
	# position/orbit remain unchanged, and Back restores the spring-arm camera.
	dialogue_camera.global_position=target.global_position+away*3.8+side*.30+Vector3(0,1.90,0)
	dialogue_camera.look_at(target.global_position+Vector3(0,.75,0),Vector3.UP)
	dialogue_camera.fov=44.0
	dialogue_camera.current=true
	visual.hide()
