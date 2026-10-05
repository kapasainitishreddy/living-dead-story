extends RefCounted
# Station-only visual layer. Never edits collisions, interaction markers or story.
const SHADER = preload("res://art/station/painterly.gdshader")
const ATLAS = preload("res://art/station/surface_atlas.svg")
var materials: Dictionary = {}
var beveled_meshes: Dictionary = {}
var normalized_meshes: Dictionary = {}
func material(color: Color, cell: int, strength: float = 0.35) -> ShaderMaterial:
	var key = str(color) + ":" + str(cell) + ":" + str(strength)
	if materials.has(key): return materials[key]
	var result = ShaderMaterial.new()
	result.shader = SHADER
	result.set_shader_parameter("base_color", color)
	result.set_shader_parameter("surface_atlas", ATLAS)
	result.set_shader_parameter("atlas_region", Vector4(float(cell % 4) * 0.25,floor(float(cell) / 4.0) * 0.5,0.25,0.5))
	result.set_shader_parameter("mark_strength", strength)
	materials[key] = result
	return result
func apply(world: Node3D, factory: RefCounted):
	world.set_meta("painterly_station", true)
	var train_visual = world.get_node("Train").get_child(0)
	train_visual.mesh = beveled_box(Vector3(4,3.6,22),0.18)
	for node in world.find_children("*", "GeometryInstance3D", true, false):
		var source = node.material_override
		if not source is StandardMaterial3D: continue
		if source.emission_enabled: continue
		var name_ = str(node.name) if node is MultiMeshInstance3D else str(node.get_parent().name)
		var cell = -1
		var strength = 0.46
		if "TileBatch" in name_: cell = 0
		elif "BenchSlat" in name_ or "BenchBack" in name_: cell = 1
		elif "BenchLeg" in name_: cell = 3
		elif "Wall" in name_: cell = 2
		elif "Train" in name_ or "Door" in name_ or "Column" in name_ or "Board" in name_: cell = 3
		elif "CanopyGlass" in name_: cell = 4
		elif "CanopyRib" in name_ or "RoofLongitudinal" in name_: cell = 3
		elif "DistantBuilding" in name_: cell = 5
		if cell < 0: continue
		if node is MultiMeshInstance3D and node.multimesh.mesh is BoxMesh:
			node.multimesh.mesh = normalize_box_uv(node.multimesh.mesh)
		elif node is MeshInstance3D and node.mesh is BoxMesh:
			node.mesh = normalize_box_uv(node.mesh)
		if cell == 5:
			# Ordinary opaque geometry, with quiet painted windows instead of 56 bright boxes.
			var distant = StandardMaterial3D.new()
			distant.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			distant.albedo_color = Color("7787a6")
			distant.albedo_texture = ATLAS
			distant.texture_repeat = false
			distant.uv1_scale = Vector3(252.0/1024.0,252.0/512.0,1)
			distant.uv1_offset = Vector3(258.0/1024.0,258.0/512.0,0)
			node.material_override = distant
		else:
			node.material_override = material(source.albedo_color,cell,strength)
	# No walkable geometry is removed; distant window marks now live in the facade atlas.
	for window in world.get_node("StationArt").get_children():
		if "DistantWindow" in str(window.name):
			world.get_node("StationArt").remove_child(window)
			window.free()
	var art = world.get_node("StationArt")
	for i in range(3):
		var poster = MeshInstance3D.new()
		poster.name = "TravelPoster%d" % i
		var plane = PlaneMesh.new()
		plane.size = Vector2(1.2,1.7)
		poster.mesh = plane
		poster.position = Vector3(-8.72,2.45,-6.0+float(i)*4.0)
		poster.rotation_degrees = Vector3(90,90,0)
		poster.material_override = material(Color("f1e3c4"),6+i%2,1.0)
		art.add_child(poster)
		factory.label(art,"NIGHT LINE" if i != 1 else "SEA • 06",Vector3(-8.66,3.55,poster.position.z),19)
		var lettering = art.get_child(art.get_child_count()-1)
		lettering.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lettering.rotation_degrees.y = 90
	# Small authored linework: cream station clock face, warm brass rim and dark hands.
	var clock = factory.rounded(art,"StationClock",Vector3(-4.6,4.05,-8.1),0.47,0.47,0.10,Color("d7c9a5"))
	clock.rotation_degrees.x = 90
	var face = factory.rounded(art,"ClockFace",Vector3(-4.6,4.05,-8.02),0.40,0.40,0.035,Color("d3d7d8"))
	face.rotation_degrees.x = 90
	factory.box(art,"ClockMinute",Vector3(-4.6,4.19,-7.985),Vector3(0.035,0.30,0.022),Color("344357"),false)
	var hand = factory.box(art,"ClockHour",Vector3(-4.69,4.02,-7.982),Vector3(0.22,0.035,0.023),Color("344357"),false)
	hand.rotation.z = 0.25
	var environment = world.find_children("*", "WorldEnvironment", true, false)[0].environment
	environment.ambient_light_color = Color("9186b8")
	environment.ambient_light_energy = 0.32
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = Color("566480")
	environment.fog_light_energy = 0.35
	environment.fog_depth_begin = 15.0
	environment.fog_depth_end = 48.0
	for light in world.find_children("*", "DirectionalLight3D", true, false):
		light.light_color = Color("d0c9ed")
		light.light_energy = 0.75
	# Strong existing lamps remain warm, but reflections no longer dominate the stone.

func beveled_box(size_: Vector3, bevel: float) -> ArrayMesh:
	var key = str(size_) + ":" + str(bevel)
	if beveled_meshes.has(key): return beveled_meshes[key]
	var half = size_ * 0.5
	var inset = half - Vector3.ONE * min(bevel,min(half.x,min(half.y,half.z)) * 0.4)
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Six inset flat faces, twelve chamfer strips, eight clipped corner triangles.
	for axis in range(3):
		var a = (axis+1)%3
		var b = (axis+2)%3
		for side in [-1.0,1.0]:
			var polygon: Array[Vector3] = []
			for pair in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var v = Vector3.ZERO
				v[axis] = half[axis] * side
				v[a] = inset[a] * pair.x
				v[b] = inset[b] * pair.y
				polygon.append(v)
			add_face(surface, polygon)
	for axis in range(3):
		var a = (axis+1)%3
		var b = (axis+2)%3
		for sa in [-1.0,1.0]:
			for sb in [-1.0,1.0]:
				var polygon: Array[Vector3] = []
				for pair in [Vector2(-1,0),Vector2(1,0),Vector2(1,1),Vector2(-1,1)]:
					var v = Vector3.ZERO
					v[axis] = inset[axis] * pair.x
					v[a] = (half[a] if pair.y == 0 else inset[a]) * sa
					v[b] = (inset[b] if pair.y == 0 else half[b]) * sb
					polygon.append(v)
				add_face(surface,polygon)
	for x in [-1.0,1.0]:
		for y in [-1.0,1.0]:
			for z in [-1.0,1.0]:
				var sign_ = Vector3(x,y,z)
				var polygon: Array[Vector3] = []
				for axis in range(3):
					var v = inset * sign_
					v[axis] = half[axis] * sign_[axis]
					polygon.append(v)
				add_face(surface,polygon)
	var result = surface.commit()
	beveled_meshes[key] = result
	return result
func add_face(surface: SurfaceTool, polygon: Array[Vector3]):
	var normal = (polygon[1]-polygon[0]).cross(polygon[2]-polygon[0]).normalized()
	var center = Vector3.ZERO
	for vertex in polygon: center += vertex
	if center.dot(normal) < 0:
		polygon.reverse()
		normal = -normal
	var axis = 0 if abs(normal.x) > abs(normal.y) and abs(normal.x) > abs(normal.z) else (1 if abs(normal.y) > abs(normal.z) else 2)
	var a = (axis+1)%3
	var b = (axis+2)%3
	var minimum = Vector2(INF,INF)
	var maximum = Vector2(-INF,-INF)
	for v in polygon:
		minimum = minimum.min(Vector2(v[a],v[b]))
		maximum = maximum.max(Vector2(v[a],v[b]))
	var span = (maximum-minimum).max(Vector2(0.001,0.001))
	# Godot front faces use clockwise winding when viewed from the exterior.
	for i in range(1,polygon.size()-1):
		for index in [0,i+1,i]:
			var v = polygon[index]
			surface.set_normal(normal)
			surface.set_uv((Vector2(v[a],v[b])-minimum)/span)
			surface.add_vertex(v)

func normalize_box_uv(mesh: BoxMesh) -> ArrayMesh:
	var key = str(mesh.size)
	if normalized_meshes.has(key): return normalized_meshes[key]
	var arrays = mesh.get_mesh_arrays()
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var limits: Dictionary = {}
	for i in range(normals.size()):
		var n = normals[i]
		if not limits.has(n): limits[n] = [uv[i], uv[i]]
		limits[n][0] = limits[n][0].min(uv[i])
		limits[n][1] = limits[n][1].max(uv[i])
	for i in range(normals.size()):
		var bounds = limits[normals[i]]
		uv[i] = (uv[i]-bounds[0])/(bounds[1]-bounds[0])
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var result = ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	normalized_meshes[key] = result
	return result
