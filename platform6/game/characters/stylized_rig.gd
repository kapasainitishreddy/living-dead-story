extends Node3D
# Real rigged CC0 model (Kenney Mini Characters / Cube Pets) driven by an
# AnimationTree: idle/walk/run speed blend plus sit and a one-shot gesture.
# Every weight approaches its target with a ~0.2 s time constant, so clip
# changes are crossfades, never pops. Gameplay owns position and heading.
const CROSSFADE := 0.2
var model: Node3D
var player: AnimationPlayer
var tree: AnimationTree
var skeleton: Skeleton3D
var clips := {}
var walk_speed := 1.3
var run_speed := 4.0
var speed := 0.0
var sit_target := 0.0
var sit_weight := 0.0
var loco := 0.0
var reduced := false

func setup(path: String, height_scale: float, clip_map: Dictionary, walk_ref := 1.3, run_ref := 4.0) -> Node3D:
	name = "StylizedRig"
	clips = clip_map
	walk_speed = walk_ref
	run_speed = run_ref
	scale = Vector3.ONE * height_scale
	model = (load(path) as PackedScene).instantiate()
	add_child(model)
	player = model.find_children("*", "AnimationPlayer", true, false)[0]
	var rigs = model.find_children("*", "Skeleton3D", true, false)
	skeleton = rigs[0] if rigs.size() > 0 else null
	for key in clips:
		var a: Animation = player.get_animation(clips[key])
		if key != "gesture": a.loop_mode = Animation.LOOP_LINEAR
	for g in model.find_children("*", "GeometryInstance3D", true, false):
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_build_tree()
	return self

func _anim(graph: AnimationNodeBlendTree, id: String, clip: String):
	var n = AnimationNodeAnimation.new()
	n.animation = clip
	graph.add_node(id, n)

func _build_tree():
	var graph = AnimationNodeBlendTree.new()
	var space = AnimationNodeBlendSpace1D.new()
	space.min_space = 0.0
	space.max_space = 1.0
	var pts = [["idle", 0.0], ["walk", 0.5], ["run", 1.0]]
	for p in pts:
		if clips.has(p[0]):
			var n = AnimationNodeAnimation.new()
			n.animation = clips[p[0]]
			space.add_blend_point(n, p[1])
	graph.add_node("Move", space)
	graph.add_node("Speed", AnimationNodeTimeScale.new())
	graph.connect_node("Speed", 0, "Move")
	_anim(graph, "SitClip", clips.get("sit", clips["idle"]))
	graph.add_node("Sit", AnimationNodeBlend2.new())
	graph.connect_node("Sit", 0, "Speed")
	graph.connect_node("Sit", 1, "SitClip")
	_anim(graph, "GestureClip", clips.get("gesture", clips["idle"]))
	var shot = AnimationNodeOneShot.new()
	shot.fadein_time = CROSSFADE
	shot.fadeout_time = CROSSFADE
	graph.add_node("Gesture", shot)
	graph.connect_node("Gesture", 0, "Sit")
	graph.connect_node("Gesture", 1, "GestureClip")
	graph.connect_node("output", 0, "Gesture")
	tree = AnimationTree.new()
	tree.name = "RigTree"
	add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	tree.root_node = tree.get_path_to(player.get_node(player.root_node))
	tree.tree_root = graph
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	tree.active = true
	_apply()
	tree.advance(0.0)

func set_hold_clip(clip: String):
	# Swap which clip the "Sit" layer holds (sit / sleep / groom for the cat).
	var node = tree.tree_root.get_node("SitClip") if tree else null
	if node and node.animation != StringName(clip):
		node.animation = clip
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR

func set_speed(v: float): speed = maxf(v, 0.0)
func set_sitting(v: bool): sit_target = 1.0 if v else 0.0
func gesture():
	if tree and not reduced: tree.set("parameters/Gesture/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
func set_reduced(v: bool):
	reduced = v
	if tree:
		_apply()
		tree.advance(0.0)

func _target_loco() -> float:
	if speed <= walk_speed: return 0.5 * clampf(speed / walk_speed, 0.0, 1.0)
	return 0.5 + 0.5 * clampf((speed - walk_speed) / maxf(run_speed - walk_speed, 0.01), 0.0, 1.0)

func _apply():
	var k_loco = loco
	tree.set("parameters/Move/blend_position", k_loco)
	# Match cadence to ground speed so feet don't skate (bounded).
	var cadence = 1.0
	if speed > 0.05:
		var ref = walk_speed if speed <= walk_speed else run_speed
		cadence = clampf(speed / ref, 0.7, 1.4)
	tree.set("parameters/Speed/scale", 0.0 if reduced and speed < 0.05 else cadence)
	tree.set("parameters/Sit/blend_amount", sit_weight)

func advance(delta: float):
	if tree == null: return
	var k = 1.0 - exp(-delta / (CROSSFADE * 0.5)) if delta > 0.0 else 1.0
	loco = lerpf(loco, _target_loco(), k)
	sit_weight = lerpf(sit_weight, sit_target, k)
	_apply()
	tree.advance(delta)
