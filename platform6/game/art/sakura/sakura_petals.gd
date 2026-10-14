extends MultiMeshInstance3D
# world/petals.js from Sakura Crossing (MIT): falling cherry petals, three tones
# (petal 55 %, blossomLight 28 %, petalDeep), each with a slow large sway plus a
# fast small flutter, tumbling spin and a respawn above the volume.
const PETAL_SHADER = preload("res://art/sakura/sakura_petal.gdshader")
var P: Array = []
var top := 6.8
var half := 10.0
var depth := 14.0
var centre := Vector3.ZERO
var t := 0.0
var rng := RandomNumberGenerator.new()

func build(at: Vector3, half_width: float, half_depth: float, count := 520):
	centre = at; half = half_width; depth = half_depth
	rng.seed = 8123
	var q = QuadMesh.new()
	q.size = Vector2(0.185, 0.135)
	var mat = ShaderMaterial.new()
	mat.shader = PETAL_SHADER
	q.material = mat
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = q
	mm.instance_count = count
	multimesh = mm
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 64.0
	set_meta("sakura_skip", true)
	var tones = [Color("fcd9e4"), Color("fff0f4"), Color("f6bccf")]
	for i in count:
		var tone = 0 if i < count * 0.55 else (1 if i < count * 0.83 else 2)
		mm.set_instance_color(i, tones[tone])
		P.append({"x": rng.randf_range(-half, half), "y": rng.randf_range(0.2, top), "z": rng.randf_range(-depth, depth),
			"fall": rng.randf_range(0.42, 0.86), "sway": rng.randf_range(0.25, 0.75), "freq": rng.randf_range(0.5, 1.35),
			"phase": rng.randf_range(0, 10), "spin": Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized(),
			"rate": rng.randf_range(0.5, 2.4), "angle": rng.randf_range(0, 6.28), "scale": rng.randf_range(0.78, 1.25), "drift": rng.randf_range(-0.16, 0.16)})
	_update(0.0)

func _process(delta: float): _update(delta)

func _update(dt: float):
	t += dt
	var mm = multimesh
	for i in P.size():
		var p = P[i]
		var s = sin(t * p.freq + p.phase)
		var s2 = sin(t * p.freq * 2.7 + p.phase * 1.7)
		p.y -= p.fall * dt
		p.x += (p.sway * s * 0.55 + p.drift) * dt
		p.z += p.sway * s2 * 0.32 * dt
		p.angle += p.rate * dt
		if p.x < -half: p.x = half
		if p.x > half: p.x = -half
		if p.y < 0.02:
			p.x = rng.randf_range(-half, half); p.z = rng.randf_range(-depth, depth)
			p.y = top + rng.randf_range(0, 1.4); p.phase = rng.randf_range(0, 10)
		var b = Basis(p.spin, p.angle).scaled(Vector3.ONE * p.scale)
		mm.set_instance_transform(i, Transform3D(b, centre + Vector3(p.x, p.y, p.z)))
