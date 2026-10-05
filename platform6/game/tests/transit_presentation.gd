extends SceneTree
# Removing the new presentation or changing one canonical collider/target must fail.
var checks := 0
var failures := 0
const CARRIAGE = ["passenger","shoreline","return_train","breakfast","complete"]
const SHORE = ["overlook","camera_choice","optional_action"]
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func collision_signature(world: Node3D) -> Array:
	var data := []
	for shape in world.find_children("*","CollisionShape3D",true,false):
		data.append([str(shape.get_parent().name),shape.transform,shape.get_parent().transform,shape.shape.get_class(),shape.shape.size if shape.shape is BoxShape3D else Vector2(shape.shape.radius,shape.shape.height),shape.disabled])
	return data
func target_signature(world: Node3D) -> Array:
	var data := []
	for node in world.find_children("*","Marker3D",true,false):
		data.append([("Spawn" if node.name=="Spawn" else "target"),node.transform,node.get_meta("action_id",""),node.get_meta("value",""),node.get_meta("label","")])
	return data
func triangle_budget(root_: Node) -> int:
	var total := 0
	for node in root_.find_children("*","GeometryInstance3D",true,false):
		var mesh = node.multimesh.mesh if node is MultiMeshInstance3D else node.mesh
		var count = node.multimesh.instance_count if node is MultiMeshInstance3D else 1
		for surface_index in range(mesh.get_surface_count()):
			var arrays = mesh.surface_get_arrays(surface_index)
			var entries = arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null and not arrays[Mesh.ARRAY_INDEX].is_empty() else arrays[Mesh.ARRAY_VERTEX].size()
			total += entries/3*count
	return total
func visible_geometry(root_: Node) -> int:
	var result := 0
	for node in root_.find_children("*","GeometryInstance3D",true,false):
		if node.is_visible_in_tree(): result += 1
	return result
func mesh_winding(mesh: ArrayMesh) -> bool:
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var normals = arrays[Mesh.ARRAY_NORMAL]
	for i in range(0,vertices.size(),3):
		var cross_ = (vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i])
		if cross_.dot(normals[i]+normals[i+1]+normals[i+2])>0.00001: return false
	return true
func run():
	if ResourceLoader.exists("res://world/transit_presentation.gd"):
		var presentation = load("res://world/transit_presentation.gd").new()
		check(mesh_winding(presentation.rounded_box(Vector3(1.58,0.30,1.43),0.13)),"rounded upholstery uses Godot front-face winding")
		check(mesh_winding(presentation.vault_mesh()),"roof shows the intended interior face")
		check(mesh_winding(presentation.arch_mesh()),"arch shows the intended masonry surfaces")
	for checkpoint in CARRIAGE+SHORE:
		ProjectSettings.set_setting("opening/presentation_enabled",false)
		var factory = load("res://world/world_factory.gd").new()
		var baseline = factory.build(checkpoint)
		root.add_child(baseline)
		ProjectSettings.set_setting("opening/presentation_enabled",true)
		var world = factory.build(checkpoint)
		root.add_child(world)
		await process_frame
		check(collision_signature(world)==collision_signature(baseline),checkpoint+" keeps exact collider shapes/transforms/names")
		check(target_signature(world)==target_signature(baseline),checkpoint+" keeps exact story markers/spawn/action/value/label")
		var id = "CarriageArt" if checkpoint in CARRIAGE else "ShoreArt"
		check(world.has_node(id),checkpoint+" gains isolated authored scenic layer")
		if world.has_node(id):
			var art = world.get_node(id)
			check(art.find_children("*","CollisionObject3D",true,false).is_empty(),id+" never introduces physics")
			check(art.find_children("*","Marker3D",true,false).is_empty(),id+" never adds interactions")
			check(art.find_children("*","Label3D",true,false).is_empty(),id+" never adds competing text")
			check(not art.is_processing(),id+" is static under pause/reduced motion")
			check(art.find_children("*","Node",true,false).size()<=100,id+" adds at most 100 nodes")
			check(visible_geometry(art)<=28,id+" adds at most 28 visible geometry submissions")
			check(triangle_budget(art)<=(45000 if checkpoint in CARRIAGE else 25000),id+" bounds instanced triangle cost")
			for light in art.find_children("*","Light3D",true,false): check(not light.shadow_enabled,id+" adds no shadow pass")
			if checkpoint in CARRIAGE:
				for name_ in ["Upholstery","Joinery","CarriageWindowViews","CeilingDetails","Floorboards","EndBulkheads"]: check(art.has_node(name_),"carriage readable authored element "+name_)
				var cushions = art.get_node("Upholstery/SeatCushions")
				check(cushions is MultiMeshInstance3D and cushions.multimesh.instance_count==10,"all ten cushions use one geometry batch")
				check(cushions.multimesh.mesh is ArrayMesh,"upholstery has authored curved geometry")
				check(art.get_node("CarriageWindowViews/NightViews").material_override.albedo_texture!=null,"windows contain original outward painted views")
				check(not world.get_node("Seat").get_child(0).visible,"cube seat visual replaced while collider remains")
				if art.has_node("EndBulkheads"):
					check(art.get_node("EndBulkheads/Walls").multimesh.instance_count==2,"carriage closes both existing boundary ends")
					check(art.get_node("EndBulkheads/PassageDoors").multimesh.instance_count==2,"both end bulkheads have centered passage doors")
				if world.has_node("Steam"):
					world.get_node("AmbientMotion").apply_preferences(true)
					check(not world.get_node("Steam").visible,"existing steam respects reduced motion")
			else:
				for name_ in ["CurvedArch","LighthouseSilhouette","ShoreRocks","ShoreGrass"]: check(art.has_node(name_),"shore readable authored element "+name_)
				var arch = art.get_node("CurvedArch")
				check(arch.mesh is ArrayMesh,"arch is authored curved masonry geometry")
				check(arch.get_aabb().size.is_equal_approx(Vector3(4.8,4.4,1.0)),"arch keeps existing doorway silhouette envelope")
				var arrays = arch.mesh.surface_get_arrays(0)
				var clear_opening := true
				for v in arrays[Mesh.ARRAY_VERTEX]:
					if abs(v.x)<1.4 and v.y<2.0: clear_opening=false
				check(clear_opening,"curved arch never fills the sightline aperture")
				check(world.get_node("Lighthouse").position==Vector3(-8,3,-13),"lighthouse canonical landmark position preserved")
				var water = world.get_node("Water").get_child(0).material_override
				check(water.shader.code==baseline.get_node("Water").get_child(0).material_override.shader.code,"original water shader unchanged")
				world.get_node("AmbientMotion").apply_preferences(true)
				check(water.get_shader_parameter("motion_scale")==0.0,"reduced motion still freezes original water")
				world.get_node("AmbientMotion").apply_preferences(false)
				check(water.get_shader_parameter("motion_scale")==1.0,"ordinary motion restores original water")
			print("TRANSIT METRIC ",checkpoint," art_nodes=",art.find_children("*","Node",true,false).size()," visible_geometry=",visible_geometry(art)," triangles=",triangle_budget(art))
		world.queue_free()
		baseline.queue_free()
		await process_frame
	ProjectSettings.set_setting("opening/presentation_enabled",true)
	print("Transit presentation: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
