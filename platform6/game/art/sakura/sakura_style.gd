extends RefCounted
# Shared Sakura-pass look. Palette, two-light setup and cel/ink approach are
# adapted from Sakura Crossing (MIT, (c) 2026 Kenton Wang).
const CEL = preload("res://art/sakura/sakura_cel.gdshader")
const INK = preload("res://art/sakura/sakura_ink.gdshader")
const SUN := Color("fff1d8")
const FILL := Color("a9bdf5")
const INK_COLOR := Color("39324f")
static var _cel_cache := {}
static var _ink_cache := {}

static func cel(color_: Color, rim := 0.18) -> ShaderMaterial:
	# Now the ported Sakura Crossing toon + hull (see sakura_look.gd).
	return preload("res://art/sakura/sakura_look.gd").toon(color_, {"flat": false, "outline": rim > 0.0})
	var key = str(color_) + ":" + str(rim)
	if _cel_cache.has(key): return _cel_cache[key]
	var m = ShaderMaterial.new()
	m.shader = CEL
	m.set_shader_parameter("albedo", color_)
	m.set_shader_parameter("rim_strength", rim)
	m.next_pass = ink(0.010)
	_cel_cache[key] = m
	return m

static func ink(thickness: float) -> ShaderMaterial:
	if _ink_cache.has(thickness): return _ink_cache[thickness]
	var m = ShaderMaterial.new()
	m.shader = INK
	m.set_shader_parameter("ink", INK_COLOR)
	m.set_shader_parameter("thickness", thickness)
	_ink_cache[thickness] = m
	return m

static func stylize_rig(rig: Node):
	# Toon diffuse + an ink hull on imported character materials. Materials are
	# duplicated so the shared imported resources stay untouched.
	if true:
		# Sakura look: textured toon ramp + clip-space ink hull on every rig.
		preload("res://art/sakura/sakura_look.gd").restyle(rig, false, [], false)
		return
	for mesh in rig.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null: continue
		for i in mesh.mesh.get_surface_count():
			var source = mesh.get_active_material(i)
			if not (source is BaseMaterial3D): continue
			var m: BaseMaterial3D = source.duplicate()
			m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			m.rim_enabled = true
			m.rim = 0.25
			m.rim_tint = 0.6
			mesh.set_surface_override_material(i, m)

static func light_scene(scene: Node):
	# Cool fill from the opposite quarter: coloured, not black, shadow sides.
	if scene.get_node_or_null("SakuraFill") != null: return
	var key: DirectionalLight3D = null
	for node in scene.find_children("*", "DirectionalLight3D", true, false):
		key = node
		break
	var fill = DirectionalLight3D.new()
	fill.name = "SakuraFill"
	fill.light_color = FILL
	fill.light_energy = 0.32
	fill.shadow_enabled = false
	fill.set_meta("scenic_fill", true)
	fill.light_specular = 0.0
	fill.rotation = Vector3(-0.45, (key.global_rotation.y + PI) if key and key.is_inside_tree() else 2.4, 0.0)
	scene.add_child(fill)
	for node in scene.find_children("*", "WorldEnvironment", true, false):
		var env: Environment = node.environment
		if env == null: continue
		env.adjustment_enabled = true
		env.adjustment_saturation = 1.08
		env.adjustment_contrast = 1.04
