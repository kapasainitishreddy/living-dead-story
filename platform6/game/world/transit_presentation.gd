extends RefCounted
# Original static scenic geometry; canonical physics/markers remain in world_factory.
var factory
var art: Node3D
var materials := {}
var meshes := {}
func group(parent: Node3D, id: String) -> Node3D:
	var node = Node3D.new()
	node.name = id
	parent.add_child(node)
	return node
func painted(color: Color, kind: String, scale_: float = 0.65) -> StandardMaterial3D:
	var key = str(color)+kind+str(scale_)
	if materials.has(key): return materials[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_texture = load("res://art/apartment/"+kind+".svg")
	mat.roughness = 0.96
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE*scale_
	materials[key] = mat
	return mat
func solid(color: Color) -> StandardMaterial3D:
	var key = str(color)
	if materials.has(key): return materials[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.96
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	materials[key] = mat
	return mat
func pose(pos: Vector3, scale_: Vector3 = Vector3.ONE, rotation: Vector3 = Vector3.ZERO) -> Transform3D:
	return Transform3D(Basis.from_euler(rotation).scaled(scale_),pos)
func batch(parent: Node3D, id: String, mesh: Mesh, mat: Material, transforms: Array) -> MultiMeshInstance3D:
	var node = MultiMeshInstance3D.new()
	node.name = id
	var multi = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()): multi.set_instance_transform(i,transforms[i])
	node.multimesh = multi
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node
func visual(parent: Node3D, id: String, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.name = id
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node
func cylinder(top: float, bottom: float, height_: float) -> CylinderMesh:
	var mesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height_
	mesh.radial_segments = 16
	mesh.rings = 0
	return mesh
func rounded_box(size_: Vector3, radius: float) -> ArrayMesh:
	var key = str(size_)+str(radius)
	if meshes.has(key): return meshes[key]
	var half = size_*0.5
	var inner = half-Vector3.ONE*radius
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Rounded Minkowski shell, six edge-biased samples per face axis. Soft normals,
	# complete rounded corners, no imported tessellation or scene dependency.
	for axis in range(3):
		var a = (axis+1)%3
		var b = (axis+2)%3
		for side in [-1.0,1.0]:
			for row in range(5):
				for col in range(5):
					var corners = [Vector2(row,col),Vector2(row+1,col),Vector2(row+1,col+1),Vector2(row,col+1)]
					for index in ([0,2,1,0,3,2] if side>0 else [0,1,2,0,2,3]):
						var uv = corners[index]/5.0
						var p = Vector3.ZERO
						p[axis]=half[axis]*side
						p[a]=[-half[a],-half[a]+radius*0.5,-inner[a],inner[a],half[a]-radius*0.5,half[a]][int(corners[index].x)]
						p[b]=[-half[b],-half[b]+radius*0.5,-inner[b],inner[b],half[b]-radius*0.5,half[b]][int(corners[index].y)]
						var core = p.clamp(-inner,inner)
						var normal = (p-core).normalized()
						tool.set_normal(normal)
						tool.set_uv(uv)
						tool.add_vertex(core+normal*radius)
	var mesh = tool.commit()
	meshes[key]=mesh
	return mesh
func apply_carriage(world: Node3D, builder):
	factory = builder
	art = group(world,"CarriageArt")
	art.set_meta("original_art",true)
	var wood = painted(Color("9b7a5c"),"wood",0.48)
	var trim = solid(Color("b8a07a"))
	var seat_mat = painted(Color("7e8d86"),"cloth",0.8)
	var wall_mat = painted(Color("929a8c"),"plaster",0.3)
	world.get_node("Carriage floor").get_child(0).material_override = wood
	world.get_node("Floor").get_child(0).material_override = solid(Color("252e3e"))
	for child in world.get_children():
		if str(child.name).begins_with("Seat") or str(child.name).begins_with("Window") or str(child.name).begins_with("Carriage side"):
			child.get_child(0).hide()
		if child is OmniLight3D:
			child.light_energy = 1.35 if abs(child.position.x)<4 else 0.4
			child.omni_range = 7
			child.shadow_enabled = false
			child.set_meta("scenic_fill",true)
		if child is DirectionalLight3D: child.light_energy=0.20
		if child is WorldEnvironment:
			child.environment.ambient_light_color=Color("b7c2cd")
			child.environment.ambient_light_energy=0.5
		if str(child.name).begins_with("Lantern"): child.hide()
	var upholstery = group(art,"Upholstery")
	var cushions := []
	var backs := []
	var arms := []
	var bases := []
	var legs := []
	var side_panels := []
	var jambs := []
	var horizontal_frames := []
	var vertical_frames := []
	var sills := []
	var curtain_folds := []
	var view_transforms := []
	for side in [-1.0,1.0]:
		side_panels.append(pose(Vector3(side*4,1.0,0)))
		for z in [-7.0,-3.0,1.0,5.0,9.0]:
			cushions.append(pose(Vector3(side*2.8,1.00,z)))
			backs.append(pose(Vector3(side*3.43,1.60,z)))
			bases.append(pose(Vector3(side*2.8,0.75,z)))
			for dz in [-0.65,0.65]:
				arms.append(pose(Vector3(side*2.8,1.30,z+dz)))
				for dx in [-0.61,0.61]: legs.append(pose(Vector3(side*2.8+dx,0.36,z+dz)))
			for dz in [-1.49,1.49]:
				vertical_frames.append(pose(Vector3(side*3.85,2.80,z+dz)))
				for fold in range(3): curtain_folds.append(pose(Vector3(side*3.72,2.79,z+dz-sign(dz)*fold*0.075)))
			for y in [2.04,3.56]: horizontal_frames.append(pose(Vector3(side*3.85,y,z)))
			sills.append(pose(Vector3(side*3.78,2.02,z)))
			var basis = Basis(Vector3(0,0,-side),Vector3(-side,0,0),Vector3.UP)
			view_transforms.append(Transform3D(basis,Vector3(side*4.02,2.8,z)))
		for z in [-10.75,-5.0,-1.0,3.0,7.0,10.75]: jambs.append(pose(Vector3(side*4,2.82,z)))
	batch(upholstery,"SeatCushions",rounded_box(Vector3(1.58,0.30,1.43),0.13),seat_mat,cushions)
	batch(upholstery,"SeatBacks",rounded_box(Vector3(0.28,1.37,1.43),0.13),seat_mat,backs)
	batch(upholstery,"Armrests",rounded_box(Vector3(1.53,0.15,0.14),0.065),wood,arms)
	var joinery = group(art,"Joinery")
	batch(joinery,"SeatFrames",rounded_box(Vector3(1.64,0.15,1.50),0.06),wood,bases)
	batch(joinery,"SeatLegs",cylinder(0.06,0.07,0.70),solid(Color("566267")),legs)
	batch(joinery,"LowerWallPanels",factory.shared_box_mesh(Vector3(0.18,2.0,22)),wall_mat,side_panels)
	batch(joinery,"WindowJambPanels",factory.shared_box_mesh(Vector3(0.18,1.68,1.05)),wall_mat,jambs)
	batch(joinery,"WindowFramesHorizontal",factory.shared_box_mesh(Vector3(0.14,0.095,3.1)),wood,horizontal_frames)
	batch(joinery,"WindowFramesVertical",factory.shared_box_mesh(Vector3(0.14,1.60,0.10)),wood,vertical_frames)
	batch(joinery,"DeepWindowSills",rounded_box(Vector3(0.38,0.09,3.1),0.035),trim,sills)
	batch(joinery,"CurtainFolds",cylinder(0.065,0.084,1.49),painted(Color("b59985"),"cloth",0.85),curtain_folds)
	var views = group(art,"CarriageWindowViews")
	var plane = PlaneMesh.new()
	plane.size=Vector2(2.89,1.43)
	var night = StandardMaterial3D.new()
	night.albedo_texture=load("res://art/transit/night_view.svg")
	night.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	night.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	batch(views,"NightViews",plane,night,view_transforms)
	var ends = group(art,"EndBulkheads")
	var end_walls := []
	var end_doors := []
	var end_frames := []
	var end_handles := []
	var end_windows := []
	for side in [-1.0,1.0]:
		# Faces sit immediately inside the original boundary collider; no new barrier.
		end_walls.append(pose(Vector3(0,1.84,side*11.83)))
		end_doors.append(pose(Vector3(0,1.62,side*11.74)))
		for x in [-0.99,0.99]: end_frames.append(pose(Vector3(x,1.66,side*11.66),Vector3(0.12,3.3,0.08)))
		for y in [0.09,3.30]: end_frames.append(pose(Vector3(0,y,side*11.66),Vector3(2.10,0.12,0.08)))
		for x in [-0.50,0.50]: end_frames.append(pose(Vector3(x,2.20,side*11.62),Vector3(0.06,1.38,0.08)))
		for y in [1.54,2.86]: end_frames.append(pose(Vector3(0,y,side*11.62),Vector3(1.06,0.06,0.08)))
		end_handles.append(pose(Vector3(0.70,1.34,side*11.58)))
		end_windows.append(pose(Vector3(0,2.20,side*11.61),Vector3.ONE,Vector3(0,PI if side>0 else 0,0)))
	batch(ends,"Walls",factory.shared_box_mesh(Vector3(8,3.68,0.12)),wall_mat,end_walls)
	batch(ends,"PassageDoors",rounded_box(Vector3(1.85,3.15,0.09),0.04),wood,end_doors)
	batch(ends,"DoorFrames",factory.shared_box_mesh(Vector3.ONE),trim,end_frames)
	batch(ends,"DoorHandles",rounded_box(Vector3(0.06,0.26,0.09),0.025),trim,end_handles)
	var end_window = QuadMesh.new()
	end_window.size=Vector2(0.93,1.23)
	batch(ends,"PassageWindows",end_window,night,end_windows)
	var ceiling = group(art,"CeilingDetails")
	visual(ceiling,"SoftVault",vault_mesh(),painted(Color("ddd1b6"),"plaster",0.28))
	var beams := []
	var lamps := []
	var shades := []
	for z in [-9.0,-5.0,-1.0,3.0,7.0,10.5]:
		beams.append(pose(Vector3(0,3.64,z)))
		for x in [-2.2,2.2]:
			shades.append(pose(Vector3(x,3.64,z)))
			lamps.append(pose(Vector3(x,3.46,z)))
	batch(ceiling,"RoofCrossRibs",rounded_box(Vector3(7.65,0.10,0.10),0.04),wood,beams)
	batch(ceiling,"BrassLampBases",cylinder(0.14,0.20,0.08),trim,shades)
	var glow = solid(Color("ecd2a1"))
	glow.emission_enabled=true
	glow.emission=Color("e3b879")
	glow.emission_energy_multiplier=0.35
	batch(ceiling,"WarmLampShades",cylinder(0.12,0.26,0.27),glow,lamps)
	var boards := []
	for x in range(12):
		for z in range(7): boards.append(pose(Vector3(-3.62+x*0.66,0.04,-9.4+z*3.12)))
	batch(art,"Floorboards",factory.shared_box_mesh(Vector3(0.645,0.025,3.10)),wood,boards)
func vault_mesh() -> ArrayMesh:
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(20):
		var a=-PI/2+float(i)/20*PI
		var b=-PI/2+float(i+1)/20*PI
		var points=[Vector3(sin(a)*4,3.68+cos(a)*0.55,-11),Vector3(sin(b)*4,3.68+cos(b)*0.55,-11),Vector3(sin(b)*4,3.68+cos(b)*0.55,11),Vector3(sin(a)*4,3.68+cos(a)*0.55,11)]
		for index in [0,2,1,0,3,2]:
			var p=points[index]
			tool.set_normal(Vector3(-p.x/4,-1,0).normalized())
			tool.set_uv(Vector2(float(i)/20 if index in [0,3] else float(i+1)/20,(p.z+11)/22))
			tool.add_vertex(p)
	return tool.commit()
func arch_mesh() -> ArrayMesh:
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# One continuous round arch, two short legs; original center/depth preserved.
	for i in range(24):
		var a=float(i)/24*PI
		var b=float(i+1)/24*PI
		var inner_a=Vector2(cos(a)*1.43,2+sin(a)*1.43)
		var inner_b=Vector2(cos(b)*1.43,2+sin(b)*1.43)
		var outer_a=Vector2(cos(a)*2.4,2+sin(a)*2.4)
		var outer_b=Vector2(cos(b)*2.4,2+sin(b)*2.4)
		arch_segment(tool,inner_a,inner_b,outer_a,outer_b)
	for side in [-1.0,1.0]:
		arch_segment(tool,Vector2(side*1.43,0),Vector2(side*1.43,2),Vector2(side*2.4,0),Vector2(side*2.4,2))
	return tool.commit()
func arch_segment(tool: SurfaceTool, ia: Vector2, ib: Vector2, oa: Vector2, ob: Vector2):
	for depth in [-0.5,0.5]:
		quad(tool,[Vector3(ia.x,ia.y,depth),Vector3(ib.x,ib.y,depth),Vector3(ob.x,ob.y,depth),Vector3(oa.x,oa.y,depth)],Vector3(0,0,sign(depth)))
	quad(tool,[Vector3(ia.x,ia.y,-0.5),Vector3(ia.x,ia.y,0.5),Vector3(ib.x,ib.y,0.5),Vector3(ib.x,ib.y,-0.5)],Vector3(-((ia+ib)/2).x,-((ia+ib)/2).y+2,0).normalized())
	quad(tool,[Vector3(oa.x,oa.y,-0.5),Vector3(ob.x,ob.y,-0.5),Vector3(ob.x,ob.y,0.5),Vector3(oa.x,oa.y,0.5)],Vector3(((oa+ob)/2).x,((oa+ob)/2).y-2,0).normalized())
func quad(tool: SurfaceTool, points: Array, normal: Vector3):
	if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0: points.reverse()
	for index in [0,1,2,0,2,3]:
		tool.set_normal(normal)
		tool.set_uv(Vector2(points[index].x*0.2,points[index].y*0.2))
		tool.add_vertex(points[index])
func apply_shore(world: Node3D, builder):
	factory=builder
	art=group(world,"ShoreArt")
	art.set_meta("original_art",true)
	var stone=painted(Color("82959f"),"plaster",0.52)
	world.get_node("Floor").get_child(0).material_override=painted(Color("4e626b"),"plaster",0.45)
	for child in world.get_children():
		if str(child.name).begins_with("Arch ") or child.name=="Lighthouse" or str(child.name).begins_with("Boundary"):
			child.get_child(0).hide()
		if child is OmniLight3D:
			child.light_energy=0.65
			child.shadow_enabled=false
			child.set_meta("scenic_fill",true)
		if str(child.name).begins_with("Lantern"): child.hide()
		if child is DirectionalLight3D:
			child.light_color=Color("b2cbdc")
			child.light_energy=0.72
		if child is WorldEnvironment:
			child.environment.ambient_light_color=Color("91aac2")
			child.environment.ambient_light_energy=0.52
	visual(art,"CurvedArch",arch_mesh(),stone,Vector3(0,0,-15))
	var lighthouse=group(art,"LighthouseSilhouette")
	visual(lighthouse,"TaperedTower",cylinder(0.43,0.70,5.83),painted(Color("d6d1bb"),"plaster",0.8),Vector3(-8,2.915,-13))
	visual(lighthouse,"StoneFoot",cylinder(0.73,0.86,0.30),stone,Vector3(-8,0.15,-13))
	visual(lighthouse,"LanternBalcony",cylinder(0.75,0.75,0.13),solid(Color("65777c")),Vector3(-8,5.88,-13))
	visual(lighthouse,"LanternRoof",cylinder(0.0,0.75,0.47),solid(Color("526777")),Vector3(-8,7.00,-13))
	var posts:=[]
	for i in range(8):
		var angle=float(i)/8*TAU
		posts.append(pose(Vector3(-8+cos(angle)*0.52,6.36,-13+sin(angle)*0.52)))
	batch(lighthouse,"LanternPosts",cylinder(0.035,0.035,0.85),solid(Color("647478")),posts)
	var rail:=TorusMesh.new()
	rail.inner_radius=0.70
	rail.outer_radius=0.75
	rail.rings=16
	rail.ring_segments=6
	visual(lighthouse,"BalconyRim",rail,solid(Color("798786")),Vector3(-8,6.17,-13))
	var windows:=[]
	for y in [1.5,3.0,4.5]: windows.append(pose(Vector3(-8,y,-12.40),Vector3(1,1,1)))
	batch(lighthouse,"TowerWindows",rounded_box(Vector3(0.22,0.40,0.035),0.016),solid(Color("435b68")),windows)
	var rocks:=[]
	var pebbles:=[]
	var grasses:=[]
	for i in range(38):
		var side=-1.0 if i%2==0 else 1.0
		var x=side*(8.0+float(i%7)*0.43)
		var z=-10.7+float(i/7)*3.7
		var scale_=Vector3(0.54+float(i%3)*0.22,0.22+float(i%4)*0.12,0.56+float(i%5)*0.13)
		rocks.append(pose(Vector3(x,scale_.y*0.32,z),scale_,Vector3(0,i*1.37,0)))
		for j in range(3): grasses.append(pose(Vector3(x+0.4+float(j)*0.15,0.19,z+0.17),Vector3(0.07,0.44+float(j%2)*0.22,0.07),Vector3(0.16*(j-1),float(i),0.15*(j-1))))
	for i in range(42):
		var side=-1.0 if i%2==0 else 1.0
		pebbles.append(pose(Vector3(side*(3.3+float(i%8)*0.64),0.018,-10.0+float(i/8)*4.05),Vector3(0.15+float(i%3)*0.08,0.055,0.2+float(i%4)*0.08),Vector3(0,i*0.7,0)))
	var rock_mesh=SphereMesh.new()
	rock_mesh.radius=1
	rock_mesh.height=2
	rock_mesh.radial_segments=10
	rock_mesh.rings=5
	batch(art,"ShoreRocks",rock_mesh,painted(Color("677d87"),"plaster",0.8),rocks)
	batch(art,"ShorePebbles",rock_mesh,stone,pebbles)
	var grass_mesh=cylinder(0,0.7,1)
	grass_mesh.radial_segments=6
	batch(art,"ShoreGrass",grass_mesh,solid(Color("7e9390")),grasses)
	# Quiet painted paving strips break the wide slab while leaving the center clear.
	var paving:=[]
	for row in range(12):
		for col in range(5):
			paving.append(pose(Vector3(-3.4+col*1.55+float(row%2)*0.25,0.009,-8.75+row*1.60),Vector3(1,1,1),Vector3(0,0.015*sin(row+col),0)))
	var paving_mesh=load("res://world/station_presentation.gd").new().beveled_box(Vector3(1.42,0.025,1.45),0.011)
	batch(art,"WeatheredPaving",paving_mesh,painted(Color("667a80"),"plaster",0.6),paving)
