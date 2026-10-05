extends SceneTree
var failures=0
var checks=0
func check(ok,label):
 checks+=1
 if not ok: failures+=1;printerr("FAIL "+label)
func _initialize(): call_deferred('run')
func run():
 var game=load('res://main.tscn').instantiate()
 game.save_path='user://firefly_render_cost_campaign.json'
 root.add_child(game);await process_frame
 var helper=load('res://tests/journey_runtime.gd').new()
 game.model.restore(helper.completed_campaign('sleep'));helper.free()
 game.journey.path='user://firefly_render_cost_journey.json'
 game.journey.model=load('res://core/journey_model.gd').new()
 game.dispatch('journey_enter');game.dispatch('journey_board','fireflies')
 game.hud.close_all();game.resume_controls();await process_frame
 var world=game.world_container.get_child(0)
 var flies=world.get_node('Scenery/FireflyOrbs')
 var batch=flies.get_node_or_null('InstancedFireflies')
 check(batch!=null and batch.multimesh.instance_count==58,'all 58 animated fireflies share one render batch')
 var art=world.get_node('Scenery/PaintedClearing')
 for motion in [false,true]:
  world.apply_preferences(motion)
  world._process(0.5)
  art._sync_fireflies()
  for i in world._decorative.size():
   var item=world._decorative[i]
   check(not item.node.visible,'animation proxies do not issue individual draws')
   # Dummy headless RenderingServer does not retain MultiMesh transform reads.
   # The graphical run verifies the actual submitted transforms.
   if DisplayServer.get_name()!='headless':
    check(batch.multimesh.get_instance_transform(i).origin.is_equal_approx(item.node.position),'batched fly follows world motion/rest position')
   check(not motion or item.node.position==item.rest,'reduced motion remains at authored rest')
 check(art.process_priority>world.process_priority,'batch update runs after world motion')
 if DisplayServer.get_name()!='headless':
  world.apply_preferences(false);world.set_paused(false)
  await process_frame;await RenderingServer.frame_post_draw
  for i in 58:
   check(batch.multimesh.get_instance_transform(i).origin.is_equal_approx(world._decorative[i].node.position),'automatic rendered frame synchronizes world motion without manual sync')
 world.set_paused(true)
 var transforms=[]
 for i in 58: transforms.append(batch.multimesh.get_instance_transform(i))
 world._process(1.0);art._sync_fireflies()
 for i in 58: check(batch.multimesh.get_instance_transform(i)==transforms[i],'pause holds visual instance')
 game.audio.shutdown();game.journey.profile_player.stop()
 await create_timer(0.2).timeout
 game.queue_free();game=null;batch=null;art=null;world=null
 await process_frame;await process_frame
 print('FIREFLY RENDER COST ',checks,' checks ',failures,' failures')
 quit(1 if failures else 0)
