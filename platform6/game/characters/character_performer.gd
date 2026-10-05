extends Node3D
# Reusable production-rig presentation. Gameplay owns position, collision and input.
# Imported +Z-facing 1.7 m rigs supply the mesh, materials, idle and walk clips.
const MODELS = {
	"protagonist":"res://assets/characters/protagonist/protagonist.glb",
	"mira":"res://assets/characters/mira/mira.glb",
	"ada":"res://assets/characters/ada/ada.glb",
	"noor":"res://assets/characters/noor/noor.glb",
	"rafi":"res://assets/characters/rafi/rafi.glb",
	"conductor":"res://assets/characters/conductor/conductor.glb",
	"jo":"res://assets/characters/jo/jo.glb"
}
const MAX_HEAD_YAW := 0.58
const MAX_HEAD_PITCH := 0.24
const MAX_EYE_YAW := 0.18
const RESPONSE := 8.0
# Eyes lead a new fixation; the head and torso arrive more slowly.
const EYE_RESPONSE := 24.0
const WALK_START_RESPONSE := 16.0
const WALK_STOP_RESPONSE := 20.0
# Authored, reproducible variation rather than random per-frame facial noise.
const BLINK_INTERVALS := [3.65, 5.2, 4.1, 6.0, 3.2]
const BLINK_RHYTHM_SECONDS := 22.15
# Calibrated reference for the authored in-place gait, not character translation.
# Cadence is bounded so unusually low/high speed cannot become a flickering cycle.
const WALK_REFERENCE_SPEED := 1.3165
const MIN_WALK_TIMESCALE := 0.65
const MAX_WALK_TIMESCALE := 3.2
var character_id := "protagonist"
var model: Node3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var prop_socket: BoneAttachment3D
var head_socket: BoneAttachment3D
var gaze_target: Node3D
var conversing := false
var reduced_motion := false
var secondary_motion_weight := 1.0
var locomotion_blend := 0.0
var walk_time_scale := 1.0
var conversation_blend := 0.0
var turn_amount := 0.0
var gaze_yaw := 0.0
var gaze_pitch := 0.0
var eye_yaw := 0.0
var eye_pitch := 0.0
var speed := 0.0
var desired_turn := 0.0
var elapsed := 0.0
var bones: Dictionary = {}
var props: Dictionary = {}
var rig_root: Node
var rig_path: NodePath

func configure(id: String):
	assert(MODELS.has(id),"Unknown production character: " + id)
	character_id = id
	set_meta("character_id",id)
	if is_inside_tree() and model == null: _load_rig()

func _ready():
	add_to_group("character_performers")
	_load_rig()

func _load_rig():
	if model != null: return
	var packed = load(MODELS[character_id]) as PackedScene
	if packed == null:
		push_error("Production character asset unavailable: " + MODELS[character_id])
		return
	model = packed.instantiate()
	model.name = "ProductionRig"
	add_child(model)
	var rigs = model.find_children("*","Skeleton3D",true,false)
	var players = model.find_children("*","AnimationPlayer",true,false)
	if rigs.is_empty() or players.is_empty():
		push_error("Production character requires a skeleton and imported animations")
		return
	skeleton = rigs[0]
	animation_player = players[0]
	rig_root = animation_player.get_node(animation_player.root_node)
	rig_path = rig_root.get_path_to(skeleton)
	for bone_name in ["Root","Hips","Spine","Chest","Neck","Head","HandRight","EyeLeft","EyeRight","BrowLeft","BrowRight","Mouth"]:
		bones[bone_name] = _bone_index(bone_name)
	prop_socket = _make_socket("RightHandSocket","HandRight")
	head_socket = _make_socket("HeadSocket","Head")
	_build_animation_tree()
	if character_id == "mira": _load_camera()

func _bone_index(bone_name: String) -> int:
	var index = skeleton.find_bone(bone_name)
	if index >= 0: return index
	# Godot may suffix a bone when a DCC mesh object has the same node name.
	for i in range(skeleton.get_bone_count()):
		if str(skeleton.get_bone_name(i)).begins_with(bone_name + "_"): return i
	return -1

func _make_socket(socket_name: String, bone_name: String) -> BoneAttachment3D:
	var socket = BoneAttachment3D.new()
	socket.name = socket_name
	var index = _bone_index(bone_name)
	socket.use_external_skeleton = true
	socket.external_skeleton = NodePath("../" + str(get_path_to(skeleton)))
	socket.bone_name = skeleton.get_bone_name(index) if index >= 0 else bone_name
	socket.bone_idx = index
	add_child(socket)
	return socket

func _clip(name_: String) -> StringName:
	for clip in animation_player.get_animation_list():
		if str(clip).get_file().to_lower() == name_.to_lower(): return clip
	push_error("Required character animation missing: " + name_)
	return &""

func _rotation_clip(rotations: Dictionary) -> Animation:
	var animation = Animation.new()
	animation.length = 2.4
	animation.loop_mode = Animation.LOOP_LINEAR
	for bone_name in rotations:
		var index = _bone_index(bone_name)
		if index < 0: continue
		var track = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track,NodePath(str(rig_path) + ":" + str(skeleton.get_bone_name(index))))
		# Imported bone axes are not identity: presentation values are rest-local offsets.
		var rotation = skeleton.get_bone_rest(index).basis.get_rotation_quaternion() * Quaternion.from_euler(rotations[bone_name])
		animation.rotation_track_insert_key(track,0.0,rotation)
		animation.rotation_track_insert_key(track,2.4,rotation)
	return animation

func _build_animation_tree():
	# Reset poses are explicit, so missing tracks cannot leave last-frame facial offsets.
	var rest: Dictionary = {}
	for i in range(skeleton.get_bone_count()): rest[skeleton.get_bone_name(i)] = Vector3.ZERO
	var library = AnimationLibrary.new()
	library.add_animation("RestPose",_rotation_clip(rest))
	library.add_animation("TurnLeft",_rotation_clip({"Hips":Vector3(0,-0.035,0.01),"Chest":Vector3(0,-0.075,-0.018)}))
	library.add_animation("TurnRight",_rotation_clip({"Hips":Vector3(0,0.035,-0.01),"Chest":Vector3(0,0.075,0.018)}))
	# Quiet listening posture, without a loop of emphatic arm gestures.
	library.add_animation("Conversation",_rotation_clip({"Chest":Vector3(0.025,0,0),"Neck":Vector3(-0.018,0,0)}))
	animation_player.add_animation_library("presentation",library)
	for clip_name in ["idle","walk"]:
		animation_player.get_animation(_clip(clip_name)).loop_mode = Animation.LOOP_LINEAR
	animation_player.stop()
	animation_tree = AnimationTree.new()
	animation_tree.name = "PerformanceTree"
	add_child(animation_tree)
	animation_tree.anim_player = animation_tree.get_path_to(animation_player)
	animation_tree.root_node = animation_tree.get_path_to(rig_root)
	animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var graph = AnimationNodeBlendTree.new()
	for item in [["Rest","presentation/RestPose"],["Idle",_clip("idle")],["Walk",_clip("walk")],["TurnLeft","presentation/TurnLeft"],["TurnRight","presentation/TurnRight"],["ConversationPose","presentation/Conversation"]]:
		var node = AnimationNodeAnimation.new()
		node.animation = item[1]
		graph.add_node(item[0],node)
	graph.add_node("IdleMotion",AnimationNodeBlend2.new())
	graph.connect_node("IdleMotion",0,"Rest")
	graph.connect_node("IdleMotion",1,"Idle")
	graph.add_node("WalkTempo",AnimationNodeTimeScale.new())
	graph.connect_node("WalkTempo",0,"Walk")
	graph.add_node("Locomotion",AnimationNodeBlend2.new())
	graph.connect_node("Locomotion",0,"IdleMotion")
	graph.connect_node("Locomotion",1,"WalkTempo")
	graph.add_node("TurnDirection",AnimationNodeBlend2.new())
	graph.connect_node("TurnDirection",0,"TurnLeft")
	graph.connect_node("TurnDirection",1,"TurnRight")
	graph.add_node("Turn",AnimationNodeAdd2.new())
	graph.connect_node("Turn",0,"Locomotion")
	graph.connect_node("Turn",1,"TurnDirection")
	graph.add_node("Conversation",AnimationNodeAdd2.new())
	graph.connect_node("Conversation",0,"Turn")
	graph.connect_node("Conversation",1,"ConversationPose")
	graph.connect_node("output",0,"Conversation")
	animation_tree.tree_root = graph
	animation_tree.active = true
	_update_blend_parameters()
	animation_tree.advance(0.0)

func _load_camera():
	var camera_path = "res://assets/characters/mira/camera.glb"
	if ResourceLoader.exists(camera_path):
		var packed = load(camera_path) as PackedScene
		if packed:
			attach_prop("camera",packed.instantiate())
	else:
		# An imported prop node can also be supplied inside a production rig.
		var prop = model.find_child("CameraProp",true,false)
		if prop is Node3D:
			prop.get_parent().remove_child(prop)
			attach_prop("camera",prop)

func attach_prop(id: String, prop: Node3D, offset: Transform3D = Transform3D.IDENTITY):
	if props.has(id) and is_instance_valid(props[id]): props[id].queue_free()
	prop_socket.add_child(prop)
	prop.transform = offset
	props[id] = prop

func get_attached_prop(id: String) -> Node3D:
	return props.get(id,null)

func apply_preferences(reduced: bool):
	reduced_motion = reduced
	secondary_motion_weight = 0.0 if reduced else 1.0
	if reduced:
		# Preference changes settle a dart immediately, including paused staging.
		eye_yaw = 0.0
		eye_pitch = 0.0
	if animation_tree:
		_update_blend_parameters()
		animation_tree.advance(0.0)
		_apply_gaze_and_face()

func set_locomotion(horizontal_speed: float, heading_change: float = 0.0):
	speed = maxf(0.0,horizontal_speed)
	desired_turn = clampf(heading_change,-1.0,1.0)

func set_attention_target(target: Node3D):
	gaze_target = target

func set_conversation(active: bool, listener: Node3D = null):
	conversing = active
	if is_instance_valid(listener): gaze_target = listener
	if active: speed = 0.0

func _process(delta: float):
	advance_performance(delta)

func advance_performance(delta: float):
	if animation_tree == null or skeleton == null: return
	elapsed += delta
	var weight = 1.0 - exp(-RESPONSE * delta)
	var desired_stride = 0.0 if conversing else clampf(speed/(WALK_REFERENCE_SPEED * MIN_WALK_TIMESCALE),0.0,1.0)
	# Gameplay decelerates the body separately. Release the remaining swing promptly
	# when it stops rather than leaving a visibly partial stride after translation.
	var stride_response = WALK_START_RESPONSE if desired_stride > locomotion_blend else WALK_STOP_RESPONSE
	locomotion_blend = lerpf(locomotion_blend,desired_stride,1.0 - exp(-stride_response * delta))
	var cadence = clampf(speed / WALK_REFERENCE_SPEED,MIN_WALK_TIMESCALE,MAX_WALK_TIMESCALE)
	walk_time_scale = lerpf(walk_time_scale,cadence,weight)
	conversation_blend = lerpf(conversation_blend,1.0 if conversing else 0.0,weight)
	turn_amount = lerpf(turn_amount,0.0 if conversing else desired_turn,weight)
	_update_gaze(delta)
	_update_blend_parameters()
	animation_tree.advance(delta)
	_apply_gaze_and_face()

func _update_blend_parameters():
	animation_tree.set("parameters/IdleMotion/blend_amount",secondary_motion_weight)
	animation_tree.set("parameters/Locomotion/blend_amount",locomotion_blend)
	animation_tree.set("parameters/WalkTempo/scale",walk_time_scale)
	animation_tree.set("parameters/TurnDirection/blend_amount",0.0 if turn_amount < 0.0 else 1.0)
	animation_tree.set("parameters/Turn/add_amount",absf(turn_amount))
	animation_tree.set("parameters/Conversation/add_amount",conversation_blend)

func _update_gaze(delta: float):
	var target_yaw := 0.0
	var target_pitch := 0.0
	if is_instance_valid(gaze_target) and bones.get("Head",-1) >= 0:
		var head_world = skeleton.global_transform * skeleton.get_bone_global_pose(bones.Head).origin
		var target_world = gaze_target.global_position + Vector3(0,1.5,0)
		var direction = to_local(target_world) - to_local(head_world)
		var distance = direction.length()
		# Idle notices a nearby companion; conversation sustains eye contact farther away.
		if conversing or distance < 4.8:
			target_yaw = clampf(atan2(direction.x,direction.z),-MAX_HEAD_YAW,MAX_HEAD_YAW)
			target_pitch = clampf(-atan2(direction.y,Vector2(direction.x,direction.z).length()),-MAX_HEAD_PITCH,MAX_HEAD_PITCH)
	var weight = 1.0 - exp(-5.0 * delta)
	gaze_yaw = lerp_angle(gaze_yaw,target_yaw,weight)
	gaze_pitch = lerp_angle(gaze_pitch,target_pitch,weight)
	# Residual fixation error creates the eye-first/head-follow action. A small held
	# dart shifts between a listener's eyes/face, instead of continuous eye wobble.
	var dart := Vector2.ZERO
	if not reduced_motion:
		var phase = fposmod(elapsed + (2.7 if character_id == "mira" else 0.0),10.3)
		if phase < 1.7: dart = Vector2(0.028,-0.014)
		elif phase < 2.9: dart = Vector2(-0.032,0.008)
		elif phase < 5.35: dart = Vector2.ZERO
		elif phase < 6.75: dart = Vector2(0.050,0.018)
		elif phase < 8.85: dart = Vector2(0.0,-0.022)
		else: dart = Vector2(-0.020,0.0)
		# Travelling prioritizes the route; listening permits the fullest micro-acting.
		dart *= secondary_motion_weight * (1.0 - locomotion_blend * 0.8)
	var eye_weight = 1.0 - exp(-EYE_RESPONSE * delta)
	eye_yaw = lerpf(eye_yaw,clampf(target_yaw - gaze_yaw + dart.x,-MAX_EYE_YAW,MAX_EYE_YAW),eye_weight)
	eye_pitch = lerpf(eye_pitch,clampf(target_pitch - gaze_pitch + dart.y,-0.10,0.10),eye_weight)

func _blink_scale() -> float:
	if reduced_motion: return 1.0
	# Offset the two people so a shared shot never starts with synchronized blinks.
	var time = elapsed - (4.0 if character_id == "mira" else 0.0)
	if time < 0.0: return 1.0
	var phase = fposmod(time,BLINK_RHYTHM_SECONDS)
	for interval in BLINK_INTERVALS:
		if phase < interval: break
		phase -= interval
	# Quick closing, a short closed hold, and a slower reopening. The eye scale
	# always returns exactly to ONE, including after a preference change.
	if phase < 0.06: return lerpf(1.0,0.08,smoothstep(0.0,0.06,phase))
	if phase < 0.085: return 0.08
	if phase < 0.20: return lerpf(0.08,1.0,smoothstep(0.085,0.20,phase))
	return 1.0

func _offset_bone(bone_name: String, yaw: float, pitch: float, roll: float = 0.0):
	var index: int = bones.get(bone_name,-1)
	if index < 0: return
	var rest_basis = skeleton.get_bone_global_rest(index).basis
	var local_up = (rest_basis.inverse() * Vector3.UP).normalized()
	var local_right = (rest_basis.inverse() * Vector3.RIGHT).normalized()
	var local_forward = (rest_basis.inverse() * Vector3.BACK).normalized()
	var offset = Quaternion(local_up,yaw) * Quaternion(local_right,pitch) * Quaternion(local_forward,roll)
	skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index) * offset)

func _apply_gaze_and_face():
	_offset_bone("Chest",gaze_yaw * 0.10,gaze_pitch * 0.05)
	_offset_bone("Neck",gaze_yaw * 0.30,gaze_pitch * 0.25)
	_offset_bone("Head",gaze_yaw * 0.60,gaze_pitch * 0.70)
	_offset_bone("EyeLeft",eye_yaw,eye_pitch)
	_offset_bone("EyeRight",eye_yaw,eye_pitch)
	# Add only upper-body acting: the authored stance, seated staging, hands and
	# sockets stay under their existing animation/chapter owners.
	var quiet_weight = secondary_motion_weight * (1.0 - locomotion_blend)
	var breath = sin(elapsed * 1.43 + (0.7 if character_id == "mira" else 0.0)) * 0.008
	_offset_bone("Chest",0.0,breath * quiet_weight)
	var listening_weight = conversation_blend * quiet_weight
	var tilt = sin(elapsed * 0.57) * 0.032 + sin(elapsed * 1.11 + 0.5) * 0.012
	var nod_phase = fposmod(elapsed + (2.2 if character_id == "mira" else 0.0),6.8)
	var nod = sin((nod_phase - 1.0) / 0.85 * PI) * 0.070 if nod_phase > 1.0 and nod_phase < 1.85 else 0.0
	_offset_bone("Neck",0.0,nod * listening_weight * 0.3)
	_offset_bone("Head",0.0,nod * listening_weight * 0.7,tilt * listening_weight)
	# Authored facial bones support small readable changes, not simulated dialogue audio.
	var blink = _blink_scale()
	for bone_name in ["EyeLeft","EyeRight"]:
		var index: int = bones.get(bone_name,-1)
		if index >= 0: skeleton.set_bone_pose_scale(index,Vector3(1,blink,1))
	# A listening expression rises, holds and softens rather than staying a
	# permanent smile. Decorative facial acting obeys reduced motion immediately.
	var smile_phase = fposmod(elapsed + (0.55 if character_id == "mira" else 0.0),7.6)
	var acknowledgement = smoothstep(1.5,2.6,smile_phase) * (1.0 - smoothstep(4.1,5.7,smile_phase))
	var expression = conversation_blend * secondary_motion_weight * (0.018 + 0.022 * acknowledgement)
	_offset_bone("BrowLeft",0,0,-expression)
	_offset_bone("BrowRight",0,0,expression)
	_offset_bone("Mouth",0,conversation_blend * secondary_motion_weight * (0.006 + acknowledgement * 0.021))
