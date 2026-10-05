extends Node3D
# Authored cut-paper geometry; no balancing simulation and no random arrangement.
# The same component is rebuilt from saved configuration in every later room.
const CREAM = Color("f3e7cf")
const INK = Color("465f61")
const GOLD = Color("e7bb64")
const ORDERS = ["leaf_boat_star","boat_star_leaf","star_leaf_boat","leaf_star_boat","boat_leaf_star","star_boat_leaf"]
const LENGTHS = {"short":0.47,"medium":0.72,"long":1.02}
var factory: RefCounted
var configuration: Dictionary = {}
var silhouette := false
var secondary_elapsed := 0.0

func build(value: Dictionary, geometry_factory: RefCounted = null) -> Node3D:
	configure(value,geometry_factory)
	return self

func configure(value: Dictionary, geometry_factory: RefCounted = null, as_silhouette: bool = false):
	factory = geometry_factory if geometry_factory != null else load("res://world/world_factory.gd").new()
	silhouette = as_silhouette
	configuration = {
		"star":str(value.get("star","crooked")),
		"layout":str(value.get("layout","leaf_boat_star")),
		"length":str(value.get("length","medium")),
		"mode":str(value.get("mode","assemble")),
		"fold":str(value.get("fold","keep")),
		"completed":bool(value.get("completed",false))
	}
	if configuration.star not in ["crooked","clean","empty"]: configuration.star = "crooked"
	if configuration.layout not in ORDERS: configuration.layout = ORDERS[0]
	if not LENGTHS.has(configuration.length): configuration.length = "medium"
	if configuration.fold not in ["keep","wider","enough"]: configuration.fold = "keep"
	for child in get_children():
		remove_child(child)
		child.free()
	set_meta("configuration",configuration.duplicate(true))
	set_meta("doorway_width",3.8)
	set_meta("authored_bounds",Vector2(2.9,2.05))
	_piece_box(self,"CrossRail",Vector3.ZERO,Vector3(2.85,0.075,0.075),INK)
	var slots = Node3D.new()
	slots.name = "Slots"
	add_child(slots)
	var order = configuration.layout.split("_")
	for i in range(3):
		var slot = Node3D.new()
		slot.name = ["Left","Center","Right"][i]
		slot.position.x = (i-1)*0.88
		slot.set_meta("piece",order[i])
		slots.add_child(slot)
		var drop: float = LENGTHS[configuration.length] + [-0.05,0.11,0.0][i]
		_piece_box(slot,"String",Vector3(0,-drop*0.5,0),Vector3(0.015,drop,0.015),Color("8c775d"))
		var piece: Node3D
		match order[i]:
			"leaf": piece = make_leaf(slot)
			"boat": piece = make_boat(slot,configuration.fold == "wider")
			"star":
				if configuration.star != "empty": piece = make_star(slot,configuration.star == "crooked")
		if piece != null: piece.position.y = -drop-0.25
		_piece_box(slot,"BrassAttachment",Vector3(0,-0.02,0.02),Vector3(0.035,0.06,0.025),GOLD)
	var plate = Node3D.new()
	plate.name = "Nameplate"
	plate.position = Vector3(0,-1.8,0)
	add_child(plate)
	_piece_box(plate,"Board",Vector3.ZERO,Vector3(2.76,0.46,0.075),Color("69877e"))
	for x in [-1.25,1.25]:
		_piece_box(self,"NameplateCord",Vector3(x,-0.9,-0.015),Vector3(0.018,1.8,0.018),Color("8c775d"))
		_piece_box(plate,"Pin",Vector3(x,0.16,0.06),Vector3(0.04,0.04,0.025),GOLD)
	var inscription = Label3D.new()
	inscription.name = "Inscription"
	inscription.text = "BOATS WITH OPINIONS"
	inscription.font_size = 32
	inscription.pixel_size = 0.0042
	inscription.position = Vector3(-0.08,0.035,0.056)
	inscription.modulate = CREAM
	inscription.outline_size = 0
	inscription.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	inscription.no_depth_test = false
	inscription.visible = not silhouette
	plate.add_child(inscription)
	var prop = Node3D.new()
	prop.name = "BentPropeller"
	prop.position = Vector3(1.1,-0.05,0.12)
	prop.rotation.z = -0.42
	plate.add_child(prop)
	_piece_box(prop,"Axle",Vector3.ZERO,Vector3(0.07,0.07,0.06),GOLD)
	for side in [-1.0,1.0]:
		var blade = _piece_box(prop,"PropellerBlade",Vector3(0,side*0.09,0),Vector3(0.085,0.18,0.026),Color("b29158"))
		blade.rotation.z = 0.29*side
		if side > 0:
			var tip = _piece_box(prop,"BentTip",Vector3(-0.075,0.18,0.01),Vector3(0.15,0.05,0.025),Color("b29158"))
			tip.rotation.z = -0.4

func _piece_box(parent: Node3D, id: String, where: Vector3, size_: Vector3, color_: Color) -> Node3D:
	var piece = factory.box(parent,id,where,size_,_color(color_),false)
	if silhouette: _unshade(piece.get_child(0))
	return piece

func _color(color_: Color) -> Color:
	return Color("344642") if silhouette else color_

func _unshade(mesh: MeshInstance3D):
	var material = StandardMaterial3D.new()
	material.albedo_color = _color(CREAM)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = material

func _paper_polygon(parent: Node3D, id: String, outline: PackedVector2Array, color_: Color, fold_depth: float = 0.035) -> Node3D:
	var piece = Node3D.new()
	piece.name = id
	parent.add_child(piece)
	var mesh = MeshInstance3D.new()
	mesh.name = "CutPaperMesh"
	piece.add_child(mesh)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices = Geometry2D.triangulate_polygon(outline)
	for face in [-1.0,1.0]:
		for i in range(0,indices.size(),3):
			var order = [indices[i],indices[i+1],indices[i+2]] if face > 0 else [indices[i+2],indices[i+1],indices[i]]
			for index in order:
				var point = outline[index]
				st.add_vertex(Vector3(point.x,point.y,face*fold_depth*0.5))
	for i in range(outline.size()):
		var p = outline[i]
		var q = outline[(i+1)%outline.size()]
		for point in [Vector3(p.x,p.y,-fold_depth*0.5),Vector3(q.x,q.y,-fold_depth*0.5),Vector3(q.x,q.y,fold_depth*0.5),Vector3(p.x,p.y,-fold_depth*0.5),Vector3(q.x,q.y,fold_depth*0.5),Vector3(p.x,p.y,fold_depth*0.5)]: st.add_vertex(point)
	st.generate_normals()
	mesh.mesh = st.commit()
	mesh.material_override = factory.shared_material(_color(color_))
	if silhouette: _unshade(mesh)
	piece.set_meta("outline",outline)
	return piece

func make_leaf(parent: Node3D) -> Node3D:
	var points = PackedVector2Array([Vector2(0,0.43),Vector2(-0.28,0.16),Vector2(-0.24,-0.19),Vector2(0,-0.4),Vector2(0.24,-0.12),Vector2(0.29,0.21)])
	var leaf = _paper_polygon(parent,"PaperLeaf",points,Color("a0b8a0"))
	leaf.rotation.z = -0.18
	if not silhouette:
		_piece_box(leaf,"PaperCrease",Vector3(0,0,0.024),Vector3(0.016,0.66,0.012),Color("647e70"))
		for side in [-1.0,1.0]:
			var vein = _piece_box(leaf,"FoldEdge",Vector3(side*0.085,0.04,0.025),Vector3(0.018,0.24,0.012),Color("748f7c"))
			vein.rotation.z = side*0.72
	return leaf

func make_star(parent: Node3D, crooked: bool = true, id: String = "PaperStar") -> Node3D:
	var outline = PackedVector2Array()
	for i in range(10):
		var angle = PI/2.0+float(i)*TAU/10.0
		var radius = 0.36 if i%2 == 0 else 0.17
		var x_offset = 0.035 if crooked and i in [0,1,2] else 0.0
		var y_offset = -0.075 if crooked and i == 4 else 0.0
		outline.append(Vector2(cos(angle)*radius+x_offset,sin(angle)*radius+y_offset))
	var star = _paper_polygon(parent,id,outline,GOLD)
	star.rotation.z = -0.16 if crooked else 0.0
	star.set_meta("star_style","crooked" if crooked else "clean")
	if not silhouette:
		var crease = _piece_box(star,"StarFold",Vector3(0,0,0.025),Vector3(0.012,0.44,0.014),Color("ca9950"))
		crease.rotation.z = 0.4 if crooked else 0.0
	return star

func make_boat(parent: Node3D, wider: bool = false, id: String = "TimetableBoat") -> Node3D:
	var width = 0.83 if wider else 0.66
	var bow_y = 0.1 if wider else 0.025
	var outline = PackedVector2Array([Vector2(-width*0.5,0.07),Vector2(-width*0.33,-0.2),Vector2(width*0.33,-0.2),Vector2(width*0.5,bow_y),Vector2(0.22,0.01),Vector2(0,0.38),Vector2(-0.17,0.03)])
	var boat = _paper_polygon(parent,id,outline,CREAM,0.11)
	boat.set_meta("width",width)
	boat.set_meta("fold_style","wider" if wider else "keep")
	if not silhouette:
		for i in range(3):
			_piece_box(boat,"TimetablePrint",Vector3(-0.06,-0.045-i*0.04,0.06),Vector3(width*0.52,0.009,0.008),Color("7e8a7c"))
		var fold = _piece_box(boat,"BowCrease",Vector3(0.0,0.08,0.061),Vector3(0.013,0.36,0.01),Color("c7b89a"))
		fold.rotation.z = -0.15 if wider else 0.27
	return boat

func geometry_bounds() -> AABB:
	var result = AABB()
	var initialized := false
	for mesh in find_children("*","MeshInstance3D",true,false):
		if mesh.mesh == null: continue
		var transform_: Transform3D = mesh.transform
		var ancestor = mesh.get_parent()
		while ancestor != self and ancestor is Node3D:
			transform_ = ancestor.transform * transform_
			ancestor = ancestor.get_parent()
		var local_bounds: AABB = mesh.mesh.get_aabb()
		for corner in range(8):
			var point = transform_ * local_bounds.get_endpoint(corner)
			if not initialized:
				result = AABB(point,Vector3.ZERO)
				initialized = true
			else: result = result.expand(point)
	return result

func fits_doorway(width: float, height: float) -> bool:
	var bounds = geometry_bounds()
	return bounds.size.x <= width and bounds.size.y <= height

func advance_secondary(delta: float, reduced: bool):
	if not has_node("Slots"): return
	if reduced or silhouette:
		get_node("Slots").rotation.z = 0.0
		return
	secondary_elapsed += delta
	get_node("Slots").rotation.z = sin(secondary_elapsed*0.63)*0.012
