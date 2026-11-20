extends SceneTree
# Native source-and-audio lifecycle checks for the real shelter's optional care.
var checks := 0
var failures := 0
func check(ok: bool, label: String):
 checks += 1
 if not ok:
  failures += 1
  printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func run():
 var audio=load("res://audio/audio_director.gd").new()
 root.add_child(audio)
 await process_frame
 var porch=audio.location_profile("shelter_porch")
 check(porch.ambience=="orchard_hush" and porch.subtitle.contains("shelter"),"original quieter shelter ambience and matching subtitle")
 check(not audio.play_shelter_cue("water_bowl"),"other locations never play shelter Foley")
 audio.crossfade_location("shelter_porch")
 check(audio.play_shelter_cue("water_bowl"),"new water care creates original Foley")
 var water=audio.shelter_cue_player.stream as AudioStreamWAV
 check(water!=null and water.format==AudioStreamWAV.FORMAT_16_BITS and water.mix_rate==22050 and not water.stereo,"original 16-bit mono water")
 check(water!=null and water.data.size()>12000 and water.data.size()<19000 and water.loop_mode==AudioStreamWAV.LOOP_DISABLED,"water sample short and non-looping")
 check(audio.play_shelter_cue("soft_nook"),"folded towel creates separate Foley")
 var fabric=audio.shelter_cue_player.stream as AudioStreamWAV
 check(fabric!=null and fabric.data.size()>10000 and fabric.data.size()<16000 and fabric.data!=water.data,"fabric PCM distinct and finite")
 check(audio.shelter_cue_cache.size()==2 and audio.play_shelter_cue("water_bowl") and audio.shelter_cue_cache.size()==2,"one cached stream per cue")
 check(not audio.play_shelter_cue("as_found") and not audio.play_shelter_cue("invalid"),"undisturbed choice and invalid ID remain silent")
 audio.apply_settings({"master":0.0,"music":0.0,"effects":0.0})
 check(audio.shelter_cue_player.volume_db<=-80.0,"master/effects mute original shelter Foley")
 audio.crossfade_location("return_train")
 check(not audio.play_shelter_cue("soft_nook"),"train exit blocks shelter audio")
 audio.shutdown()
 check(audio.shelter_cue_player.stream==null and audio.shelter_cue_cache.is_empty(),"shutdown retires care voice and caches")
 audio.queue_free()
 await process_frame
 print("SHELTER CARE SOUND ",checks," checks ",failures," failures")
 quit(1 if failures else 0)
