extends SceneTree
func _initialize():
 var m=load('res://core/chapter_model.gd').new()
 for action in ['leave_apartment','meet_stranger','read_board','board_train']:
  assert(m.apply(action))
 var s=load('res://core/save_store.gd').new()
 var result=s.save_snapshot(m.snapshot(),'user://still_here/save_v1.json')
 print('HERO_NATIVE_SEED ',result.ok,' checkpoint=',m.data.checkpoint_id)
 quit(0 if result.ok else 1)
