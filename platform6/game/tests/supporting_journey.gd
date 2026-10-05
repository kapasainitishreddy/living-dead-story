extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok: failures+=1; printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func run():
 var pack=JSON.parse_string(FileAccess.get_file_as_string("res://data/journey_pack.json"))
 var helper=load("res://tests/journey_runtime.gd").new()
 var campaign=helper.completed_campaign("train"); helper.free()
 var jm=load("res://core/journey_model.gd").new()
 for d in jm.destinations():
  check(jm.apply("board",d.journey_id),"board actual Journey "+d.journey_id)
  var world=load("res://world/journey_world.gd").new().build(jm.snapshot(),campaign,d)
  root.add_child(world); await process_frame; await process_frame
  for actor in world.find_children("SupportingPerformer","Node3D",true,false):
   check(not actor.stage_owner.get_node("HairBun").visible,"Journey legacy bun stays retired "+d.journey_id)
   world.apply_preferences(true)
   check(actor.reduced_motion,"Journey world preference reaches nested original cast "+d.journey_id)
   world.set_paused(true)
   var before=actor.elapsed
   await create_timer(.035).timeout
   check(actor.elapsed==before,"Journey world pause freezes nested original cast "+d.journey_id)
   world.set_paused(false)
  world.queue_free(); await process_frame; await process_frame
  jm.apply("return_train")
 print("SUPPORTING_JOURNEY ",checks," checks; failures: ",failures); quit(1 if failures else 0)
