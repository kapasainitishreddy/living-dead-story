extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize():call_deferred("run")
func signature(world):
 var items=[]
 for n in world.find_children("*","Marker3D",true,false):
  if n.has_meta("action_id"):items.append([n.position,n.get_meta("action_id"),n.get_meta("value","<none>")])
 return items
func run():
 for id in ["apartment","roof","platform","conductor","passenger","overlook","breakfast"]:
  ProjectSettings.set_setting("opening/readability_enabled",false)
  var before=load("res://world/world_factory.gd").new().build(id)
  ProjectSettings.set_setting("opening/readability_enabled",true)
  var world=load("res://world/world_factory.gd").new().build(id)
  check(signature(world)==signature(before),"world text cleanup preserves actual "+id+" interaction targets")
  var direct=[]
  for child in world.get_children():
   if child is Label3D:direct.append(child)
  check(not direct.is_empty(),id+" preserved original authoring labels as invisible source")
  for label in direct:check(not label.visible,id+" no floating instruction obscures characters")
  world.free();before.free()
 print("OPENING_READABILITY ",checks," checks; failures: ",failures);quit(1 if failures else 0)
