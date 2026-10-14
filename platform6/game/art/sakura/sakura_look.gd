extends RefCounted
# The Sakura Crossing look, ported into Godot for the spring-day Chapter 1
# scenes (roof, platform, overlook). Source: https://github.com/Kenton-GMI/sakura-crossing
# (MIT, (c) 2026 Kenton Wang; full text in SAKURA_CROSSING_LICENSE.txt).
# Ported pieces, by original file:
#   core/palette.js  -> PAL (subset, same hex values) and the nearest-palette remap
#   core/toon.js     -> sakura_toon.gdshader (3-band ramp, violet shadow tint)
#   core/outline.js  -> sakura_hull.gdshader (clip-space inverted hull ink)
#   core/post.js     -> sakura_post.gdshader (depth-edge ink + split-tone grade)
#   core/sky.js      -> sakura_sky.gdshader (gradient dome + flat cel clouds)
#   main.js          -> light rig (sun 0xfff1d8 2.25 / fill 0xa9bdf5 1.08 /
#                       bounce 0xd8cbe8 0.34 / hemisphere) and linear fog in PAL.fog
#   world/trees.js   -> blossom_tree() (buildSakura: trunk, limbs, twigs, 26-36
#                       icosphere blobs in three height-biased blossom tones)
#   world/petals.js  -> SakuraPetals (falling petals: slow sway + fast flutter, spin)
#   world/props.js   -> makeCat proportions/colours, used by cat_companion.gd
const TOON = preload("res://art/sakura/sakura_toon.gdshader")
const HULL = preload("res://art/sakura/sakura_hull.gdshader")
const SKY = preload("res://art/sakura/sakura_sky.gdshader")
const POST = preload("res://art/sakura/sakura_post.gdshader")
const Petals = preload("res://art/sakura/sakura_petals.gd")

const PAL := {
	"sky_top": Color("8fbdea"), "sky_mid": Color("d4e8fa"), "sky_haze": Color("fbe7e9"),
	"fog": Color("e6ecf7"), "sun": Color("fff1d8"), "fill": Color("a9bdf5"),
	"hemi_sky": Color("dcecff"), "hemi_ground": Color("b6a6c6"), "ink": Color("39324f"),
	"road": Color("8e8a9c"), "road_worn": Color("9a95a6"), "line_white": Color("f4f2f6"),
	"line_yellow": Color("f0c341"), "sidewalk": Color("dcd8e2"), "sidewalk_alt": Color("e7e2e6"),
	"curb": Color("c7c2d0"), "concrete": Color("d9d5dd"), "concrete_mid": Color("c2bdc8"),
	"concrete_dark": Color("a7a2b0"), "dirt": Color("c9bfae"), "ballast": Color("7d7686"),
	"wall_white": Color("faf6ef"), "wall_cream": Color("f2e7d3"), "wall_blue": Color("d6e3ee"),
	"wall_beige": Color("e7dbc4"), "wall_pink": Color("f0dcda"), "roof_slate": Color("59617a"),
	"roof_blue": Color("4d5c78"), "roof_brown": Color("6b585c"), "roof_teal": Color("4f6b70"),
	"trim": Color("8b8496"), "glass": Color("9dc0d4"), "glass_dark": Color("53627a"),
	"red": Color("e0453f"), "red_soft": Color("ef6a60"), "yellow": Color("f4c033"),
	"black": Color("322e3b"), "teal": Color("2f9c9a"), "blue": Color("3d6ec4"),
	"orange": Color("ef8a3c"), "purple": Color("8f6fb5"), "leaf": Color("5aa578"),
	"leaf_deep": Color("3f7f60"), "leaf_pale": Color("84bd97"), "grass": Color("86ab84"),
	"trunk": Color("9a8082"), "trunk_dark": Color("765f62"), "blossom": Color("fbc6d8"),
	"blossom_light": Color("fff0f4"), "blossom_deep": Color("f0a3c0"), "petal": Color("fcd9e4"),
	"petal_deep": Color("f6bccf"), "train_body": Color("f7f2e6"), "train_stripe": Color("2f7fd0"),
	"metal": Color("b8bcc6"), "metal_dark": Color("878b96"), "wood": Color("a9744f"),
	"wood_pale": Color("c4a074"), "cat": Color("f0e6da"), "cat_dark": Color("6a5f63"),
	"skin": Color("f3d2bd"), "hair": Color("4a4468"),
}
static var _toon_cache := {}
static var _hull_cache := {}

static func toon(color_: Color, opts := {}) -> ShaderMaterial:
	var key = str(color_) + str(opts)
	if _toon_cache.has(key) and not opts.has("tex"): return _toon_cache[key]
	var m = ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", color_)
	m.set_shader_parameter("flat_shade", opts.get("flat", true))
	m.set_shader_parameter("soft_ramp", opts.get("soft", false))
	m.set_shader_parameter("shadow_tint", opts.get("tint", Color("6c5f8c")))
	m.set_shader_parameter("light_scale", opts.get("light", 0.82 if opts.get("soft", false) else 1.0))
	if opts.has("tex"):
		m.set_shader_parameter("albedo_tex", opts.tex)
		m.set_shader_parameter("use_tex", true)
	if opts.get("outline", true): m.next_pass = hull(opts.get("thickness", 0.0052))
	m.set_meta("sakura", true)
	if not opts.has("tex"): _toon_cache[key] = m
	return m

static func hull(thickness := 0.0052) -> ShaderMaterial:
	if _hull_cache.has(thickness): return _hull_cache[thickness]
	var m = ShaderMaterial.new()
	m.shader = HULL
	m.set_shader_parameter("ink", PAL.ink)
	m.set_shader_parameter("thickness", thickness)
	m.render_priority = -1
	_hull_cache[thickness] = m
	return m

static func nearest(c: Color) -> Color:
	# Pull an authored colour onto the Sakura palette: hue-aware nearest entry,
	# then blend 75 % of the way so the original reading (what is wood, what is
	# wall) survives while the narrow pastel range takes over.
	var best: Color = c
	var best_d := 1e9
	for k in PAL:
		var p: Color = PAL[k]
		var d = Vector3(c.r - p.r, c.g - p.g, c.b - p.b).length_squared() * 2.0 + pow(c.get_luminance() - p.get_luminance(), 2.0) * 3.0
		if d < best_d: best_d = d; best = p
	var out = c.lerp(best, 0.85)
	# Sakura's range is high-key: nothing but ink sits near black, so deep
	# navies and browns are lifted toward their palette tone's value.
	var lum = out.get_luminance()
	if lum < 0.35: out = out.lerp(best.lightened(0.45), 0.7)
	return out

static var remap_textures := true
static var ground_hint := false
static var foliage_hint := false
static var window_hint := false
static func restyle(root: Node, low := false, skip: Array = [], remap := true):
	remap_textures = remap
	# Every opaque StandardMaterial3D under root becomes a palette-mapped Sakura
	# toon material with an ink hull. Idempotent: originals are remembered in meta.
	for mm in root.find_children("*", "MultiMeshInstance3D", true, false):
		if mm.get_meta("sakura_skip", false) or mm.material_override == null or mm.multimesh == null: continue
		if mm.get_parent() != null and mm.get_parent().name.begins_with("SakuraTree"): continue
		var mab: AABB = mm.multimesh.mesh.get_aabb() if mm.multimesh.mesh else AABB()
		ground_hint = mab.size.y < 0.08 and mab.size.x > 0.5 and mab.size.z > 0.5
		window_hint = "Window" in str(mm.name)
		foliage_hint = "Blossom" in str(mm.name) or "Sapling" in str(mm.name) or "Leaves" in str(mm.name) or "Bush" in str(mm.name)
		mm.material_override = _convert(mm.material_override, low, mab.size.length() > 0.5)
	ground_hint = false
	foliage_hint = false
	window_hint = false
	for item in root.find_children("*", "MeshInstance3D", true, false):
		if item.mesh == null or item.get_meta("sakura_skip", false): continue
		remap_textures = remap and item.skin == null and not (item.get_parent() is Skeleton3D)
		var skipped := false
		for s in skip: if s != null and (item == s or s.is_ancestor_of(item)): skipped = true
		if skipped: continue
		var big = item.get_aabb().size.length() * item.scale.length() > 0.35
		var ab = item.get_aabb()
		var path_ = str(item.get_path()) if item.is_inside_tree() else str(item.name)
		window_hint = "Window" in path_ or "Glass" in path_
		ground_hint = ab.size.x * item.scale.x > 7.0 and ab.size.z * item.scale.z > 7.0 and ab.size.y * item.scale.y < 1.0
		if item.is_inside_tree() and root.has_meta("time_state") and item.global_position.y + item.get_aabb().position.y * item.global_basis.get_scale().y > 2.6:
			# Canopies and roofs stop shading the whole platform: the Sakura frame
			# is an open, sunlit street, so overhead structure casts no shadow.
			item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if item.material_override != null:
			item.material_override = _convert(item.material_override, low, big)
		else:
			for i in item.mesh.get_surface_count():
				var src = item.get_surface_override_material(i)
				if src == null: src = item.mesh.surface_get_material(i)
				if src != null: item.set_surface_override_material(i, _convert(src, low, big))

static var _converted := {}
static func _convert(src: Material, low: bool, outline: bool) -> Material:
	if src.has_meta("sakura_from"):
		if src is ShaderMaterial: src.next_pass = null if (low or not outline) else hull()
		return src
	if src is ShaderMaterial and src.shader != null and src.shader.resource_path.ends_with("station/painterly.gdshader"):
		# The station's painterly layer becomes flat Sakura toon in palette colour.
		var pkey = str(src.get_instance_id()) + str(outline)
		if not _converted.has(pkey):
			var pm = toon(nearest(src.get_shader_parameter("base_color")), {"outline": outline and not low}).duplicate()
			if outline and not low: pm.next_pass = hull()
			pm.set_meta("sakura_from", src)
			_converted[pkey] = pm
		return _converted[pkey]
	if not src is StandardMaterial3D: return src
	var s: StandardMaterial3D = src
	if s.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or s.albedo_color.a < 0.99: return src
	if s.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		# Flat backdrops (distant city) go to Sakura's pale far-hill lilac.
		var ukey = str(s.get_instance_id()) + "u"
		if not _converted.has(ukey):
			var u: StandardMaterial3D = s.duplicate()
			u.albedo_color = Color("c6cfe6") if s.albedo_texture != null else nearest(s.albedo_color).lerp(Color("d8dded"), 0.5)
			u.albedo_texture = null # sky.js buildDistantHills: flat pale masses, no detail
			u.set_meta("sakura_from", s)
			_converted[ukey] = u
		return _converted[ukey]
	var key = str(s.get_instance_id()) + str(outline) + str(ground_hint) + str(foliage_hint) + str(window_hint and s.emission_enabled)
	if _converted.has(key):
		var m0: ShaderMaterial = _converted[key]
		m0.next_pass = null if (low or not outline) else hull()
		return m0
	var opts := {"outline": outline and not low}
	var col = s.albedo_color
	if s.albedo_texture != null:
		opts.tex = s.albedo_texture
		opts.flat = false
		col = Color(1, 1, 1).lerp(Color("fff4ee"), 0.3)
		if remap_textures:
			# Scenery textures (tiles, boards) get their average pulled onto the
			# palette with an albedo multiplier, so the platform reads pale.
			var img: Image = s.albedo_texture.get_image()
			if img != null:
				img = img.duplicate()
				if img.is_compressed(): img.decompress()
				img.resize(1, 1, Image.INTERPOLATE_BILINEAR)
				var tex_avg = img.get_pixel(0, 0)
				var avg = tex_avg * s.albedo_color
				var want = PAL.road.lerp(avg, 0.12) if ground_hint else nearest(avg)
				# the toon shader multiplies albedo by the texture, so divide by the texture alone
				col = Color(clampf(want.r / maxf(tex_avg.r, 0.02), 0.2, 3.0), clampf(want.g / maxf(tex_avg.g, 0.02), 0.2, 3.0), clampf(want.b / maxf(tex_avg.b, 0.02), 0.2, 3.0))
	else:
		# Big flat ground reads as Sakura's grey-violet street, not white paving.
		col = PAL.road.lerp(col, 0.12) if ground_hint else nearest(col)
		# Low painted bushes become Sakura's teal-leaning shrub greens (trees.js buildShrubs).
		if foliage_hint: col = Color("8cb884").lerp(col, 0.1)
		# Lit night windows read as daytime glass: PAL.glass reflecting the sky.
		if window_hint and s.emission_enabled: col = PAL.glass
	var m = toon(col, opts).duplicate() if not opts.has("tex") else toon(col, opts)
	if opts.outline: m.next_pass = hull()
	m.set_meta("sakura_from", s)
	_converted[key] = m
	return m

static func apply_day(scene: Node3D, owner: Node3D):
	# Light rig and atmosphere from main.js, scaled for rooms ~25 m across
	# (Fog 44..205 m there covers a 200 m street; here the far wall is ~40 m).
	scene.set_meta("time_state", "day")
	for node in scene.find_children("*", "WorldEnvironment", true, false):
		var env: Environment = node.environment
		if env == null: continue
		var sm = ShaderMaterial.new()
		sm.shader = SKY
		var sky = Sky.new()
		sky.sky_material = sm
		sky.radiance_size = Sky.RADIANCE_SIZE_32
		sky.process_mode = Sky.PROCESS_MODE_QUALITY
		env.sky = sky
		env.background_mode = Environment.BG_SKY
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = PAL.hemi_sky
		env.ambient_light_energy = 0.0 # hemisphere is evaluated in the toon shader
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR # renderer.toneMapping = NoToneMapping
		env.tonemap_exposure = 1.0
		env.glow_enabled = false
		env.adjustment_enabled = false
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_light_color = PAL.fog
		env.fog_light_energy = 1.0
		env.fog_density = 1.0
		env.fog_sky_affect = 0.0
		env.fog_depth_curve = 1.0
		env.fog_depth_begin = 16.0
		env.fog_depth_end = 95.0
	var key: DirectionalLight3D = null
	for light in scene.find_children("*", "DirectionalLight3D", true, false):
		if key == null and light.shadow_enabled: key = light
		else: light.visible = false
	if key == null:
		key = DirectionalLight3D.new()
		scene.add_child(key)
	key.name = "SakuraSun"
	key.visible = true
	key.rotation_degrees = Vector3(-38, -32, 0)
	key.light_color = PAL.sun
	key.light_energy = 1.95
	key.light_specular = 0.0
	key.shadow_enabled = OS.get_environment("SAKURA_NOSHADOW") == ""
	key.shadow_opacity = 1.0
	key.shadow_blur = 1.0
	key.directional_shadow_max_distance = 36.0
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	for spec in [["SakuraFillLight", PAL.fill, 1.08, Vector3(-30, 148, 0)], ["SakuraBounce", Color("d8cbe8"), 0.34, Vector3(60, 60, 0)]]:
		var l = DirectionalLight3D.new()
		l.name = spec[0]; l.light_color = spec[1]; l.light_energy = spec[2]
		l.rotation_degrees = spec[3]; l.shadow_enabled = false; l.light_specular = 0.0
		scene.add_child(l)
	var old_fill = scene.get_node_or_null("SakuraFill")
	if old_fill: old_fill.visible = false
	for n in scene.find_children("Rain*", "", true, false): if n is Node3D: n.visible = false
	for l in scene.find_children("*", "OmniLight3D", true, false): l.visible = false
	for l in scene.find_children("*", "SpotLight3D", true, false): l.visible = false
	# Full-screen ink + grade pass.
	var quad = MeshInstance3D.new()
	quad.name = "SakuraPost"
	var qm = QuadMesh.new()
	qm.size = Vector2(2, 2)
	quad.mesh = qm
	quad.extra_cull_margin = 16384.0
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm = ShaderMaterial.new()
	pm.shader = POST
	pm.render_priority = 127
	quad.material_override = pm
	quad.set_meta("sakura_skip", true)
	owner.add_child(quad)
	var petals = Petals.new()
	petals.name = "SakuraPetals"
	owner.add_child(petals)
	petals.build(Vector3(0, 0, 0), 11.0, 14.0)

static func blossom_tree(parent: Node3D, where: Vector3, s := 1.0, seed_ := 1) -> Node3D:
	# world/trees.js buildSakura(), one tree. Same dimensions and random ranges.
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_
	var tree = Node3D.new()
	tree.name = "SakuraTree"
	tree.position = where
	parent.add_child(tree)
	var wood = toon(PAL.trunk, {"tint": Color("8a7290")})
	var trunk_h = 2.5 * s * rng.randf_range(0.9, 1.12)
	var trunk_r = 0.2 * s
	_cyl(tree, wood, Vector3(0, trunk_h / 2, 0), Vector3.UP, trunk_h, trunk_r * 0.7, trunk_r, 7)
	_cyl(tree, wood, Vector3(0, 0.16 * s, 0), Vector3.UP, 0.34 * s, trunk_r * 1.05, trunk_r * 1.5, 7)
	var top = Vector3(0, trunk_h, 0)
	var limbs = 3 + rng.randi_range(0, 1)
	var centres: Array[Vector3] = []
	for i in limbs:
		var a = float(i) / limbs * TAU + rng.randf_range(-0.4, 0.4)
		var len_ = 1.9 * s * rng.randf_range(0.82, 1.2)
		var tilt = rng.randf_range(0.5, 0.85)
		var e = top + Vector3(cos(a) * sin(tilt), cos(tilt), sin(a) * sin(tilt)) * len_
		_cyl(tree, wood, (top + e) / 2, (e - top).normalized(), len_, 0.25 * 0.13 * s, 0.55 * 0.13 * s, 5)
		centres.append(e)
		if rng.randf() < 0.75:
			var d2 = ((e - top).normalized() + Vector3(rng.randf_range(-0.7, 0.7), rng.randf_range(0.1, 0.6), rng.randf_range(-0.7, 0.7))).normalized()
			var l2 = len_ * rng.randf_range(0.5, 0.8)
			var e2 = e + d2 * l2
			_cyl(tree, wood, (e + e2) / 2, d2, l2, 0.12 * 0.09 * s, 0.3 * 0.09 * s, 4)
			centres.append(e2)
	var y_min = 1e9; var y_max = -1e9
	for c in centres: y_min = minf(y_min, c.y); y_max = maxf(y_max, c.y)
	var tones = [[PAL.blossom_light, Color("e2c3d2")], [PAL.blossom, Color("d8b2c6")], [PAL.blossom_deep, Color("c99cba")]]
	var lists = [[], [], []]
	var count = 26 + rng.randi_range(0, 9)
	for i in count:
		var c = centres[rng.randi_range(0, centres.size() - 1)]
		var r = 0.56 * s * rng.randf_range(0.68, 1.3)
		var p = c + Vector3(rng.randf_range(-1.15, 1.15), rng.randf_range(-0.55, 0.95), rng.randf_range(-1.15, 1.15)) * s
		var hi = (p.y - y_min) / maxf(0.5, y_max + 1.2 * s - y_min)
		var tone = 0 if hi > 0.62 else (2 if hi < 0.28 else 1)
		if rng.randf() < 0.22: tone = (tone + 1) % 3
		lists[tone].append(Transform3D(Basis.from_euler(Vector3(rng.randf() * 3, rng.randf() * 3, rng.randf() * 3)).scaled(Vector3(r, r * rng.randf_range(0.68, 0.88), r)), p))
	for i in 4:
		var r = 0.6 * s * rng.randf_range(0.8, 1.15)
		var p = top + Vector3(rng.randf_range(-0.7, 0.7) * s, (1.25 + rng.randf_range(0, 0.5)) * s, rng.randf_range(-0.7, 0.7) * s)
		lists[0].append(Transform3D(Basis.from_euler(Vector3(rng.randf() * 3, rng.randf() * 3, rng.randf() * 3)).scaled(Vector3(r, r * 0.8, r)), p))
	var blob = icosphere()
	for t in 3:
		if lists[t].is_empty(): continue
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = blob
		mm.instance_count = lists[t].size()
		for k in lists[t].size(): mm.set_instance_transform(k, lists[t][k])
		var mi = MultiMeshInstance3D.new()
		mi.name = "SakuraCanopy%d" % t
		mi.multimesh = mm
		mi.material_override = toon(tones[t][0], {"soft": true, "tint": tones[t][1], "thickness": 0.0042})
		tree.add_child(mi)
	return tree

static var _ico: ArrayMesh
static func icosphere() -> ArrayMesh:
	# THREE.IcosahedronGeometry(1, 1): icosahedron, each face split in four = 80 faces.
	if _ico: return _ico
	var t = (1.0 + sqrt(5.0)) / 2.0
	var v = [Vector3(-1,t,0),Vector3(1,t,0),Vector3(-1,-t,0),Vector3(1,-t,0),Vector3(0,-1,t),Vector3(0,1,t),Vector3(0,-1,-t),Vector3(0,1,-t),Vector3(t,0,-1),Vector3(t,0,1),Vector3(-t,0,-1),Vector3(-t,0,1)]
	var f = [[0,11,5],[0,5,1],[0,1,7],[0,7,10],[0,10,11],[1,5,9],[5,11,4],[11,10,2],[10,7,6],[7,1,8],[3,9,4],[3,4,2],[3,2,6],[3,6,8],[3,8,9],[4,9,5],[2,4,11],[6,2,10],[8,6,7],[9,8,1]]
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in f:
		var a: Vector3 = v[tri[0]].normalized(); var b: Vector3 = v[tri[1]].normalized(); var c: Vector3 = v[tri[2]].normalized()
		var ab = ((a + b) / 2).normalized(); var bc = ((b + c) / 2).normalized(); var ca = ((c + a) / 2).normalized()
		for q in [[a, ab, ca], [ab, b, bc], [ca, bc, c], [ab, bc, ca]]:
			for p in [q[0], q[2], q[1]]: # Godot front faces are clockwise
				st.set_normal(p); st.add_vertex(p)
	_ico = st.commit()
	return _ico

static func _cyl(parent: Node3D, mat: Material, at: Vector3, up: Vector3, h: float, r_top: float, r_bot: float, seg: int):
	var m = MeshInstance3D.new()
	var c = CylinderMesh.new()
	c.top_radius = r_top; c.bottom_radius = r_bot; c.height = h; c.radial_segments = seg; c.rings = 1
	m.mesh = c
	m.material_override = mat
	var b = Basis.IDENTITY
	if absf(up.dot(Vector3.UP)) < 0.999:
		var axis = Vector3.UP.cross(up).normalized()
		b = Basis(axis, Vector3.UP.angle_to(up))
	m.transform = Transform3D(b, at)
	parent.add_child(m)
