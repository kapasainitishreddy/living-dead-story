extends Node3D
# Small living flock: hop, peck, glance around and, now and then, flutter up and
# settle again. Procedural timing; technique credit Sakura Crossing (MIT).
# Reduced motion (read from the protagonist performer) holds a still perch.
const Style = preload("res://art/sakura/sakura_style.gd")
var birds: Array = []
var time := 0.0
var _shared_sphere: SphereMesh
func configure(count: int):
	name = "SakuraBirdFlock"
	var tones = [Color("4d4760"), Color("615a74"), Color("7a6f86")]
	for i in count:
		var root = Node3D.new()
		var angle = i * 2.39996
		var spread = 0.30 + 0.13 * (i % 3)
		root.position = Vector3(sin(angle) * spread, 0.09 * (i % 2), cos(angle) * spread)
		root.rotation.y = angle
		add_child(root)
		var tone: Color = tones[i % 3]
		var body = _blob(root, Vector3(0, 0.07, 0), Vector3(0.075, 0.065, 0.10), tone)
		var head = Node3D.new()
		head.position = Vector3(0, 0.14, -0.07)
		root.add_child(head)
		_blob(head, Vector3.ZERO, Vector3(0.05, 0.05, 0.05), tone)
		_blob(head, Vector3(0, -0.005, -0.055), Vector3(0.012, 0.012, 0.025), Color("e0a64a"))
		var wings = []
		for side in [-1.0, 1.0]:
			var pivot = Node3D.new()
			pivot.position = Vector3(side * 0.06, 0.10, 0.0)
			root.add_child(pivot)
			_blob(pivot, Vector3(side * 0.03, 0, 0.02), Vector3(0.035, 0.012, 0.075), tone.darkened(0.15))
			wings.append(pivot)
		var tail = body # tail flick is carried by the body tip (triangle budget)
		birds.append({"root": root, "head": head, "wings": wings, "tail": tail, "home": root.position, "yaw": angle, "seed": i * 1.731, "hop": 0.0})
	for g in find_children("*", "GeometryInstance3D", true, false):
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _blob(parent: Node3D, pos: Vector3, size_: Vector3, colour: Color) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	if _shared_sphere == null:
		_shared_sphere = SphereMesh.new()
		_shared_sphere.radius = 1.0; _shared_sphere.height = 2.0
		_shared_sphere.radial_segments = 6; _shared_sphere.rings = 3
	m.mesh = _shared_sphere
	m.position = pos
	m.scale = size_
	var mat = Style.cel(colour, 0.12)
	m.material_override = mat
	parent.add_child(m)
	return m

func _reduced() -> bool:
	for p in get_tree().get_nodes_in_group("character_performers"):
		if p.character_id == "protagonist": return p.reduced_motion
	return false

func _process(delta: float):
	if _reduced():
		for b in birds:
			b.root.position = b.home
			b.root.rotation = Vector3(0, b.yaw, 0)
			b.head.rotation = Vector3.ZERO
			for w in b.wings: w.rotation = Vector3.ZERO
		return
	time += delta
	for b in birds:
		var t = time + b.seed * 3.0
		# A 7 s behaviour loop per bird, offset so the flock never moves in sync.
		var phase = fposmod(t, 7.0)
		var lift := 0.0
		var flap := 0.0
		var peck := 0.0
		var glance = sin(t * 1.7) * 0.6 if phase < 2.5 else 0.0
		if phase > 2.5 and phase < 3.4:
			peck = sin((phase - 2.5) / 0.9 * PI * 3.0)
			peck = maxf(peck, 0.0)
		elif phase > 4.0 and phase < 4.5:
			var h = (phase - 4.0) / 0.5
			lift = sin(h * PI) * 0.05 # little hop
			b.yaw += delta * 2.2
		elif fposmod(t + b.seed, 21.0) < 1.6:
			var f = fposmod(t + b.seed, 21.0) / 1.6
			lift = sin(f * PI) * 0.55
			flap = sin(t * 38.0)
		var k = 1.0 - exp(-12.0 * delta)
		var target = b.home + Vector3(0, lift, 0)
		b.root.position = b.root.position.lerp(target, k)
		b.root.rotation.y = lerp_angle(b.root.rotation.y, b.yaw, k)
		b.head.rotation.y = lerpf(b.head.rotation.y, glance, 1.0 - exp(-18.0 * delta))
		b.head.rotation.x = lerpf(b.head.rotation.x, -peck * 0.9, 1.0 - exp(-25.0 * delta))
		b.tail.rotation.x = sin(t * 5.0) * 0.05 + peck * 0.12
		for i in b.wings.size():
			var side = -1.0 if i == 0 else 1.0
			b.wings[i].rotation.z = side * (flap * 1.1 + absf(flap) * 0.2)
