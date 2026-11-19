extends CharacterBody3D
signal interact(target)
signal footstep_contact(side: int)
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
# A nearby object under the camera's gaze wins a close tie without making
# anything behind the player impossible to interact with.
const INTERACT_VIEW_BIAS := 0.24
const STEP_MIN_SPEED := 0.45
const STEP_MIN_INTERVAL := 0.22
const TURN_REFERENCE_RATE := 2.8 # radians/second at full planted torso turn
var foot_audio: AudioStreamPlayer3D
var step_distance := 0.0
var step_age := 0.0
var step_side := 0
var step_samples := {}
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
	foot_audio = AudioStreamPlayer3D.new()
	foot_audio.name = "FootContactAudio"
	foot_audio.position = Vector3(0.0,0.06,0.0)
	foot_audio.max_distance = 8.0
	foot_audio.unit_size = 1.3
	add_child(foot_audio)
	_update_step_volume()
func set_controls_enabled(value: bool):
	enabled = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value and not touch_mode else Input.MOUSE_MODE_VISIBLE
	if not enabled:
		_reset_footsteps()
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
	_update_step_volume()
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
	var before_slide := global_position
	move_and_slide()
	var actual_travel := Vector2(global_position.x-before_slide.x,global_position.z-before_slide.z).length()
	# Motion is measured AFTER move_and_slide. Pushing against a wall must not
	# leave the rig walking in place when the feet have stopped translating.
	var horizontal_speed := grounded_locomotion_speed(actual_travel,delta,is_on_floor())
	advance_footstep(actual_travel,horizontal_speed,delta,is_on_floor())
	# The feet can remain planted while the player chooses a new heading. Use
	# the ACTUAL body yaw gained in this physics tick, not a held directional
	# request that would make a blocked wall endlessly sway the torso.
	var yaw_before := visual.rotation.y
	if direction.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),gait_weight(delta))
	var heading_change := grounded_turn_amount(yaw_before,visual.rotation.y,delta,is_on_floor())
	visual.position.y = 0.0 # gait animates the body; no camera bob
	# Footsteps, imported walk clip and the gentle idle glance all respond
	# to the same true ground travel, even along a sliding wall.
	visual.set_locomotion(horizontal_speed,heading_change if not bool(preferences.get("reduced_motion",false)) else 0.0)
	update_nearby_attention(nearest,horizontal_speed,delta)

func interaction_focus_score(target: Node3D, distance: float) -> float:
	# Score only: actual 3.2 m reach remains a hard distance check.
	# Looking at a small joy helps you discover it, but never locks out the
	# nearby object behind you. Use planar yaw rather than camera pitch.
	var to_target := Vector2(target.global_position.x-global_position.x,target.global_position.z-global_position.z)
	if to_target.length_squared() < 0.0001 or not is_instance_valid(pivot):
		return distance
	var camera_forward: Vector3 = pivot.global_transform.basis * Vector3.FORWARD
	var flat_forward := Vector2(camera_forward.x,camera_forward.z)
	if flat_forward.length_squared() < 0.0001:
		return distance
	var facing := clampf(flat_forward.normalized().dot(to_target.normalized()),-1.0,1.0)
	return distance + INTERACT_VIEW_BIAS * (1.0-facing)

func choose_nearest_interactable() -> Node3D:
	# Keep existing focus until another close object is decisively better.
	# The HUD, E/A/touch interaction and delayed gaze share the exact target.
	var closest: Node3D = null
	var closest_score: float = INF
	var previous_distance: float = INF
	var previous_score: float = INF
	for node in get_tree().get_nodes_in_group("interactables"):
		if not (node is Node3D):
			continue
		var target: Node3D = node as Node3D
		if target.is_queued_for_deletion():
			continue
		var distance: float = global_position.distance_to(target.global_position)
		var score := interaction_focus_score(target,distance)
		if target == nearest:
			previous_distance = distance
			previous_score = score
		# Camera preference never extends the physical interaction radius.
		if distance < INTERACT_RADIUS and score < closest_score:
			closest_score = score
			closest = target
	# Never retain deleted, removed or out-of-range targets.
	if is_instance_valid(nearest) and previous_distance < INTERACT_RADIUS:
		if closest != nearest and closest_score + INTERACT_SWITCH_MARGIN >= previous_score:
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

func grounded_turn_amount(before_yaw: float, after_yaw: float, delta: float, grounded: bool) -> float:
	# A stationary turn is purposeful movement, but it never counts as a step.
	# Wrap across +/-PI; only the measured angular change can bend the torso.
	if not grounded or delta <= 0.00001: return 0.0
	return clampf(wrapf(after_yaw-before_yaw,-PI,PI)/(TURN_REFERENCE_RATE*delta),-1.0,1.0)

func grounded_locomotion_speed(actual_travel: float,delta: float,grounded: bool) -> float:
	# The requested velocity is not proof of movement after a collision.
	# An airborne or zero-duration tick never drives grounded walk animation.
	if not grounded or delta <= 0.00001: return 0.0
	return clampf(maxf(0.0,actual_travel)/delta,0.0,4.2)

func _reset_footsteps():
	step_distance = 0.0
	step_age = 0.0
	if is_instance_valid(foot_audio): foot_audio.stop()

func _update_step_volume():
	if not is_instance_valid(foot_audio): return
	# Share the user-facing Master/Effects levels without a new setting.
	var gain := clampf(float(preferences.get("master",0.8))*float(preferences.get("effects",0.6))*0.24,0.0,1.0)
	foot_audio.volume_db = linear_to_db(gain) if gain > 0.0 else -80.0
	if gain <= 0.0: foot_audio.stop()

func _original_footstep(side: int) -> AudioStreamWAV:
	# Locally synthesized soft cloth scuff and sole tap; left/right are different.
	var rate := 22050
	var count := 2205
	var samples := PackedByteArray()
	samples.resize(count*2)
	for i in range(count):
		var t := float(i)/float(rate)
		var attack := minf(1.0,float(i)/85.0)
		var tail := pow(maxf(0.0,1.0-float(i)/float(count)),2.6)
		var cloth := sin(float(i)*(13.37+float(side)*1.11))*sin(float(i)*2.717)
		var sole := sin(TAU*(112.0+float(side)*17.0)*t)*exp(-t*32.0)
		var pcm := clampi(roundi((cloth*0.45+sole*0.55)*attack*tail*0.29*32767.0),-32768,32767)
		samples[2*i] = pcm & 255
		samples[2*i+1] = (pcm >> 8) & 255
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.stereo = false
	sound.loop_mode = AudioStreamWAV.LOOP_DISABLED
	sound.data = samples
	return sound

func advance_footstep(actual_travel: float, speed: float, delta: float, grounded: bool):
	# Use distance travelled after collision, not held keys: walls stay silent.
	if not enabled or not grounded or speed < STEP_MIN_SPEED:
		_reset_footsteps()
		return
	step_distance += clampf(actual_travel,0.0,0.50)
	step_age += maxf(0.0,delta)
	var distance_per_step := lerpf(0.68,1.42,clampf(speed/4.2,0.0,1.0))
	if step_distance < distance_per_step or step_age < STEP_MIN_INTERVAL: return
	step_distance = maxf(0.0,step_distance-distance_per_step)
	step_age = 0.0
	var side := step_side
	step_side = 1-step_side
	footstep_contact.emit(side)
	if not is_instance_valid(foot_audio): return
	if not step_samples.has(side): step_samples[side] = _original_footstep(side)
	foot_audio.stream = step_samples[side]
	if foot_audio.volume_db > -79.0 and DisplayServer.get_name() != "headless":
		foot_audio.play()

func _exit_tree():
	_reset_footsteps()
	step_samples.clear()

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
