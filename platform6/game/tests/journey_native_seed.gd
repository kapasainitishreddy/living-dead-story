extends SceneTree
func _initialize():
 var helper=load('res://tests/journey_runtime.gd').new()
 var campaign=helper.completed_campaign('sleep')
 helper.free()
 var cs=load('res://core/save_store.gd').new()
 var j=load('res://core/journey_model.gd').new()
 j.apply('board','rain_town')
 var js=load('res://core/journey_store.gd').new()
 var a=cs.save_snapshot(campaign,'user://still_here/save_v1.json')
 var b=js.save_snapshot(j.snapshot())
 print('NATIVE_SEED ',a.ok,' ',b.ok)
 quit(0 if a.ok and b.ok else 1)
