extends SceneTree
var failed := 0
func check(ok: bool, label: String):
	if not ok:
		failed += 1
		printerr("FAIL: "+label)
func winding(mesh: ArrayMesh) -> bool:
	var arrays=mesh.surface_get_arrays(0)
	var vertices=arrays[Mesh.ARRAY_VERTEX]
	var normals=arrays[Mesh.ARRAY_NORMAL]
	for i in range(0,vertices.size(),3):
		if (vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).dot(normals[i]+normals[i+1]+normals[i+2])>0.00001: return false
	return true
func _initialize():
	var pass_=load("res://world/opening_depth.gd").new()
	check(pass_.material(Color.WHITE).vertex_color_use_as_albedo,"palette colors are enabled on original city/window materials")
	check(winding(pass_.wet_patch_mesh()),"painted wet patches face the player from above")
	check(winding(pass_.gable_mesh()),"roof gables face outwards")
	check(winding(pass_.ridge_mesh(130,2.8,0)),"painted ridges face the playable shore")
	for t in [0.0,0.25,0.50,0.75,1.0]: check(pass_.ridge_height(t,4.4,1)>=0,"ridge has stable positive crest")
	check(pass_.ridge_height(0.5,4.4,1)<0.5,"middle horizon stays low behind puzzle arch")
	print("Opening depth mesh: failures=",failed)
	quit(1 if failed else 0)
