extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
 checks+=1
 if not ok:
  failures+=1
  printerr('FAIL: '+label)
func _initialize():
 var before=JSON.parse_string(FileAccess.get_file_as_string('res://../evidence/hero/native-save-after.json'))
 var after=JSON.parse_string(FileAccess.get_file_as_string('res://../evidence/hero/native-save-reopened.json'))
 check(before is Dictionary and after is Dictionary,'Actual native save and reopened save exist')
 if failures: quit(1);return
 var model=load('res://core/chapter_model.gd').new()
 check(model.restore(after),'Actual native saved state passes strict restore')
 check(after.checkpoint_id=='shoreline','Native conversation advanced passenger to shoreline')
 check(after.settings.reduced_motion,'Live reduced-motion toggle survived exit and reopen')
 check(before==after,'Reopening preserves the entire saved snapshot')
 check(after.schema_version==2,'Compatible save schema retained')
 check(after.action_resolution=='unselected','Optional real-world action remained private/unselected')
 check(after.choice_history.is_empty(),'Presentation polish never added choice consequences')
 print('HERO_NATIVE_SAVE ',checks,' checks; failures: ',failures)
 quit(1 if failures else 0)
