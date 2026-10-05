extends RefCounted
# Original static painted scenic depth. This pass never owns gameplay or physics.
var factory
var art: Node3D
var materials := {}
func material(color: Color, painted := false, unshaded := false) -> StandardMaterial3D:
	var key = str(color)+str(painted)+str(unshaded)
	if materials.has(key): return materials[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.96
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if painted:
		mat.albedo_texture = load("res://art/apartment/plaster.svg")
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3.ONE*0.23
	materials[key] = mat
	return mat
func pose(pos: Vector3, scale_: Vector3 = Vector3.ONE, rotation: Vector3 = Vector3.ZERO) -> Transform3D:
	return Transform3D(Basis.from_euler(rotation).scaled(scale_),pos)
func batch(id: String, mesh: Mesh, mat: Material, transforms: Array, colors: Array = []) -> MultiMeshInstance3D:
	var node = MultiMeshInstance3D.new()
	node.name = id
	var multi = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = not colors.is_empty()
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i,transforms[i])
		if multi.use_colors: multi.set_instance_color(i,colors[i])
	node.multimesh = multi
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	art.add_child(node)
	return node
func visual(id: String, mesh: Mesh, mat: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.name = id
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	art.add_child(node)
	return node
func apply(world: Node3D, builder, checkpoint: String):
	if checkpoint not in ["roof","overlook","camera_choice","optional_action"]: return
	factory = builder
	art = Node3D.new()
	art.name = "OpeningDepth"
	art.set_meta("original_art",true)
	world.add_child(art)
	for node in world.get_children():
		if node is WorldEnvironment:
			var sky = Sky.new()
			var panorama = PanoramaSkyMaterial.new()
			panorama.panorama = load("res://art/opening_depth/twilight_panorama.svg")
			panorama.filter = true
			sky.sky_material = panorama
			sky.radiance_size = Sky.RADIANCE_SIZE_32
			node.environment.background_mode = Environment.BG_SKY
			node.environment.sky = sky
		if checkpoint=="roof":
			if node is OmniLight3D:
				node.light_color=Color("e3b886")
				node.light_energy=0.95
				node.omni_range=8.5
				node.shadow_enabled=false
				node.set_meta("scenic_fill",true)
			if node is DirectionalLight3D:
				node.light_color=Color("bac8da")
				node.light_energy=0.42
			if node is WorldEnvironment:
				node.environment.ambient_light_color=Color("9cabbf")
				node.environment.ambient_light_energy=0.60
	if checkpoint=="roof": roof(world)
	else: shore(world)
func roof(world: Node3D):
	var stone = material(Color("596477"),true)
	world.get_node("Floor").get_child(0).material_override=stone
	for node in world.get_children():
		if str(node.name).begins_with("City"): node.get_child(0).hide()
		if str(node.name).begins_with("Lantern"): node.hide()
		if str(node.name).begins_with("Boundary"): node.get_child(0).material_override=material(Color("657181"),true)
	city_layer("FarCity",-54.0,39,3.9,Color("788395"),0)
	city_layer("MiddleCity",-33.0,26,3.4,Color("5e6b81"),1)
	city_layer("NearCity",-21.0,19,3.2,Color("4d5b71"),2)
	var tiles := []
	var tones := []
	for row in range(12):
		for col in range(22):
			tiles.append(pose(Vector3(-10.5+col,0.006,-11.0+row*2.0)))
			tones.append(Color("75818e").lerp(Color("abb1b5"),float((row*7+col*3)%5)*0.05))
	batch("RoofTiles",factory.shared_box_mesh(Vector3(0.98,0.025,1.98)),material(Color("646f80"),true),tiles,tones)
	var rail := []
	for x in [-10.87,10.87]:
		rail.append(pose(Vector3(x,1.38,0),Vector3(0.065,0.07,23.65)))
		rail.append(pose(Vector3(x,1.06,0),Vector3(0.045,0.045,23.65)))
		for z in range(-11,12,2): rail.append(pose(Vector3(x,1.08,z),Vector3(0.065,0.65,0.065)))
	for z in [-11.86,11.86]:
		rail.append(pose(Vector3(0,1.38,z),Vector3(21.8,0.07,0.065)))
		rail.append(pose(Vector3(0,1.06,z),Vector3(21.8,0.045,0.045)))
		for x in range(-10,11,2): rail.append(pose(Vector3(x,1.08,z),Vector3(0.065,0.65,0.065)))
	batch("RoofRails",factory.shared_box_mesh(Vector3.ONE),material(Color("465567")),rail)
	var entry := []
	entry.append(pose(Vector3(7.2,1.94,12.85),Vector3(4.15,3.88,1.45)))
	entry.append(pose(Vector3(7.2,3.94,12.85),Vector3(4.5,0.22,1.75)))
	batch("EntryHouse",factory.shared_box_mesh(Vector3.ONE),material(Color("6c717e"),true),entry)
	var details := []
	details.append(pose(Vector3(7.2,1.85,12.10),Vector3(1.4,2.9,0.05)))
	for x in [6.47,7.93]: details.append(pose(Vector3(x,1.85,12.055),Vector3(0.11,3.05,0.08)))
	details.append(pose(Vector3(7.2,3.35,12.055),Vector3(1.56,0.10,0.08)))
	details.append(pose(Vector3(7.2,0.42,11.84),Vector3(1.9,0.14,0.55)))
	details.append(pose(Vector3(7.63,1.66,11.998),Vector3(0.045,0.23,0.09)))
	batch("EntryDetails",factory.shared_box_mesh(Vector3.ONE),material(Color("39495d")),details)
	var lamp_parts := []
	var lamps := []
	for x in [-7.0,7.0]:
		lamp_parts.append(pose(Vector3(x,1.48,-3),Vector3(0.07,2.96,0.07)))
		lamp_parts.append(pose(Vector3(x,2.71,-3),Vector3(0.34,0.08,0.34)))
		lamp_parts.append(pose(Vector3(x,3.19,-3),Vector3(0.34,0.10,0.34)))
		for dx in [-0.12,0.12]:
			for dz in [-0.12,0.12]: lamp_parts.append(pose(Vector3(x+dx,2.96,-3+dz),Vector3(0.025,0.42,0.025)))
		lamps.append(pose(Vector3(x,2.96,-3),Vector3(0.20,0.35,0.20)))
	batch("LanternIronwork",factory.shared_box_mesh(Vector3.ONE),material(Color("475365")),lamp_parts)
	batch("WarmLanterns",factory.shared_box_mesh(Vector3.ONE),material(Color("dec497"),false,true),lamps)
	var pools := []
	for x in [-7.0,7.0]: pools.append(pose(Vector3(x,0.029,-3),Vector3(2.25,1,1.50)))
	batch("QuietLampPools",wet_patch_mesh(),material(Color("383b40"),true),pools)
	var puddles := []
	for i in range(13):
		var x=-8.2+float((i*7)%17)
		var z=-9.3+float((i*5)%18)
		puddles.append(pose(Vector3(x,0.031,z),Vector3(0.27+float(i%3)*0.16,1,0.21+float(i%4)*0.13),Vector3(0,i*0.71,0)))
	batch("PaintedWetSlate",wet_patch_mesh(),material(Color("3e4854"),true),puddles)
func wet_patch_mesh() -> ArrayMesh:
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(20):
		var a=float(i)/20*TAU
		var b=float(i+1)/20*TAU
		var ra=0.80+sin(a*3.0+0.2)*0.12+cos(a*7.0)*0.055
		var rb=0.80+sin(b*3.0+0.2)*0.12+cos(b*7.0)*0.055
		for p in [Vector3.ZERO,Vector3(cos(a)*ra,0,sin(a)*ra),Vector3(cos(b)*rb,0,sin(b)*rb)]:
			tool.set_normal(Vector3.UP)
			tool.set_uv(Vector2(p.x,p.z)*0.5+Vector2.ONE*0.5)
			tool.add_vertex(p)
	return tool.commit()
func city_layer(id: String, z: float, count: int, spacing: float, tone: Color, depth: int):
	var bodies := []
	var colors := []
	var trim := []
	var windows := []
	var window_colors := []
	var roofs := []
	for i in range(count):
		var x=(float(i)-float(count-1)*0.5)*spacing
		var width=spacing*(0.74+float((i*3)%4)*0.045)
		var height=5.0+float((i*7+depth*3)%9)*0.68+float(depth)*0.55
		var dz=float(i%3)*0.47
		bodies.append(pose(Vector3(x,height*0.5-2.9,z-dz),Vector3(width,height,2.1)))
		colors.append(tone.lightened(float(i%4)*0.026))
		if depth>0:
			trim.append(pose(Vector3(x,height-2.72,z-dz),Vector3(width+0.22,0.16,2.35)))
			for yy in range(2,int(height)-1,2):
				trim.append(pose(Vector3(x,yy-2.55,z-dz+1.07),Vector3(width+0.04,0.07,0.04)))
			for col in range(3):
				for row in range(1,int(height)-1):
					if (col*7+row*5+i*3)%5==0: continue
					windows.append(pose(Vector3(x+(col-1)*width*0.26,row-2.47,z-dz+1.065),Vector3(width*0.14,0.40,0.018)))
					window_colors.append(Color("d5b98e").lerp(Color("8596a9"),0.65 if (col+row+i)%3==0 else 0.10*float((col+i)%3)))
			if i%3==0:
				roofs.append(pose(Vector3(x,height-2.90,z-dz),Vector3(width*0.5,0.95+float(i%2)*0.3,1.22)))
	batch(id,factory.shared_box_mesh(Vector3.ONE),material(Color.WHITE,true,depth==0),bodies,colors)
	if depth>0:
		batch(id+"Cornices",factory.shared_box_mesh(Vector3.ONE),material(tone.darkened(0.10)),trim)
		batch(id+"Roofs",gable_mesh(),material(tone.darkened(0.10)),roofs)
		var window_material=material(Color.WHITE,false,true)
		var pane = QuadMesh.new()
		pane.size = Vector2.ONE
		if depth==2:
			batch("WarmWindows",pane,window_material,windows,window_colors)
		else:
			batch(id+"Windows",pane,window_material,windows,window_colors)
func gable_mesh() -> ArrayMesh:
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points=[Vector3(-1,0,-1),Vector3(1,0,-1),Vector3(0,1,-1),Vector3(-1,0,1),Vector3(1,0,1),Vector3(0,1,1)]
	for face in [[0,1,2],[3,5,4],[0,2,5,3],[1,4,5,2],[0,3,4,1]]:
		var normal=(points[face[2]]-points[face[0]]).cross(points[face[1]]-points[face[0]]).normalized()
		for index in ([0,1,2] if face.size()==3 else [0,1,2,0,2,3]):
			tool.set_normal(normal)
			tool.set_uv(Vector2(points[face[index]].x,points[face[index]].y))
			tool.add_vertex(points[face[index]])
	return tool.commit()
func shore(world: Node3D):
	# New depth stays behind the original landmark silhouettes and water aperture.
	visual("DistantRidge",ridge_mesh(380.0,7.5,0),material(Color("8190a4"),false,true),Vector3(0,-0.60,-69))
	visual("NearHeadland",ridge_mesh(280.0,6.5,1),material(Color("687c92"),false,true),Vector3(0,-0.60,-53))
	var far_sea=PlaneMesh.new()
	far_sea.size=Vector2(200,112)
	visual("FarSea",far_sea,material(Color("4c687f"),false,true),Vector3(0,-0.551,-97))
	var glints := []
	var colors := []
	for i in range(64):
		var z=-13.3-float(i)*0.75
		var width=0.18+float(i%4)*0.10+(64.0-float(i))*0.020
		var x=8.9+sin(float(i)*2.19)*(0.12+float(64-i)*0.022)
		glints.append(pose(Vector3(x,-0.432,z),Vector3(width,0.002,0.034+float(i%3)*0.028)))
		colors.append(Color("91a5b1").lerp(Color("bbbaaf"),float(i%4)*0.10))
	batch("MoonReflection",factory.shared_box_mesh(Vector3.ONE),material(Color.WHITE,false,true),glints,colors)
func ridge_mesh(width: float, height_: float, layer: int) -> ArrayMesh:
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments=32
	for i in range(segments):
		var x=-width*0.5+float(i)*width/segments
		var nx=-width*0.5+float(i+1)*width/segments
		var y=ridge_height(float(i)/segments,height_,layer)
		var ny=ridge_height(float(i+1)/segments,height_,layer)
		# Front-facing clockwise triangles, center horizon remains low and open.
		for p in [Vector3(x,-1,0),Vector3(nx,ny,0),Vector3(nx,-1,0),Vector3(x,-1,0),Vector3(x,y,0),Vector3(nx,ny,0)]:
			tool.set_normal(Vector3.BACK)
			tool.set_uv(Vector2((p.x+width*0.5)/width,p.y/height_))
			tool.add_vertex(p)
	return tool.commit()
func ridge_height(t: float, height_: float, layer: int) -> float:
	var side_weight=pow(abs(t-0.5)*2.0,1.1)
	return 0.25+side_weight*height_*(0.34+0.66*abs(sin(t*12.2+layer*2.2)))+sin(t*32.0)*0.12
