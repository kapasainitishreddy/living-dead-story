extends Node
const Model = preload("res://core/chapter_model.gd")
const Store = preload("res://core/save_store.gd")
const Factory = preload("res://world/world_factory.gd")
const Player = preload("res://player/player.gd")
var journey
var model = Model.new()
var store = Store.new()
var world_container: Node3D
var player: CharacterBody3D
var hud
var touch
var audio
var busy := false
var paused := false
var racing := false
var paper_courtyard := false
var paper_viewing := false
var paper_view_labels: Array = []
var home_viewing := false
var home_cinematic := false
var home_labels: Array = []
var home_save_warning := ""
var home_controls_text := ""
var return_cinematic := false
var return_preparing := false
var return_save_warning := ""
var return_labels: Array = []
var return_last_phase := ""
var return_controls_text := ""
var orchard_viewing := false
var orchard_observation := false
var orchard_labels: Array = []
var orchard_save_warning := ""
var kitchen_viewing := false
var kitchen_animating := false
var kitchen_caption_elapsed := 0.0
var kitchen_gesture_id := ""
var kitchen_skip_dialogue := false
var kitchen_save_warning := ""
var campaign_save_warning := ""
var kitchen_labels: Array = []
var quitting := false
var conversation_actor: Node3D
var opening_story: Node3D
var journey_save_path = "user://still_here/journey_v1.json"
var save_path = "user://still_here/save_v1.json"
func bind_action(name_: String, keys: Array, axis: int = -1, axis_value: float = 0, button: int = -1):
	if not InputMap.has_action(name_): InputMap.add_action(name_,0.2)
	for key in keys:
		var event = InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(name_,event)
	if axis >= 0:
		var event = InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = axis_value
		InputMap.action_add_event(name_,event)
	if button >= 0:
		var event = InputEventJoypadButton.new()
		event.button_index = button
		InputMap.action_add_event(name_,event)
func _ready():
	get_tree().auto_accept_quit = false
	bind_action("move_left",[KEY_A,KEY_LEFT],0,-1)
	bind_action("move_right",[KEY_D,KEY_RIGHT],0,1)
	bind_action("move_forward",[KEY_W,KEY_UP],1,-1)
	bind_action("move_back",[KEY_S,KEY_DOWN],1,1)
	bind_action("look_left",[],2,-1)
	bind_action("look_right",[],2,1)
	bind_action("look_up",[],3,-1)
	bind_action("look_down",[],3,1)
	bind_action("interact",[KEY_E],-1,0,JOY_BUTTON_A)
	bind_action("reset_camera",[KEY_R],-1,0,JOY_BUTTON_RIGHT_STICK)
	bind_action("pause",[KEY_ESCAPE,KEY_P],-1,0,JOY_BUTTON_START)
	bind_action("ui_cancel",[],-1,0,JOY_BUTTON_B)
	var loaded = store.load_snapshot(save_path)
	if loaded.ok: model.restore(loaded.data)
	world_container = Node3D.new()
	world_container.name = "WorldContainer"
	add_child(world_container)
	hud = load("res://ui/hud.gd").new()
	add_child(hud)
	hud.choice.connect(dispatch)
	hud.dismissed.connect(resume_controls)
	hud.settings_changed.connect(change_settings)
	hud.pause_requested.connect(show_pause)
	hud.quit_requested.connect(request_quit)
	touch = load("res://ui/touch_controls.gd").new()
	add_child(touch)
	touch.modal_open = func(): return hud.modal_visible()
	touch.movement_changed.connect(func(value):
		if is_instance_valid(player): player.touch_move = value
	)
	touch.look_dragged.connect(func(value):
		if is_instance_valid(player): player.look_by(value)
	)
	touch.interact_pressed.connect(func():
		if orchard_viewing and not orchard_observation:
			var state = model.snapshot()
			if state.orchard_checkpoint == "rest": dispatch_orchard("orchard_finish" if state.orchard.beat >= 3 else "orchard_advance")
		elif is_instance_valid(player) and player.enabled and is_instance_valid(player.nearest): on_interact(player.nearest)
	)
	touch.pause_pressed.connect(func():
		if hud.pause_active: hud.resume_pause()
		else: show_pause()
	)
	touch.reset_pressed.connect(func():
		if is_instance_valid(player): player.reset_view()
	)
	touch.mode_changed.connect(func(value):
		if is_instance_valid(player): player.set_touch_mode(value)
		hud.set_control_mode(value)
	)
	hud.set_control_mode(touch.touch_mode)
	audio = load("res://audio/audio_director.gd").new()
	add_child(audio)
	journey = load("res://core/journey_runtime.gd").new()
	add_child(journey)
	journey.initialize(self)
	route()
	if not journey.recovery_notice.is_empty(): hud.show_notice(journey.recovery_notice)
	if loaded.error not in ["","missing"]: hud.show_notice(loaded.error + ". You can continue; damaged data is retained.")
func route(preserve_opening_position: bool = true):
	if touch != null: touch.cancel_input()
	if journey != null and journey.active:
		journey.route()
		return
	if home_cinematic and not home_controls_text.is_empty(): hud.controls.text = home_controls_text
	home_viewing = false
	home_cinematic = false
	home_labels.clear()
	if return_cinematic and not return_controls_text.is_empty(): hud.controls.text = return_controls_text
	return_cinematic = false
	return_preparing = false
	return_labels.clear()
	orchard_viewing = false
	orchard_labels.clear()
	paper_viewing = false
	paper_view_labels.clear()
	kitchen_viewing = false
	kitchen_animating = false
	kitchen_labels.clear()
	end_character_conversation()
	var previous_room := ""
	var previous_position := Vector3.ZERO
	var previous_yaw := 0.0
	var previous_pitch := -0.22
	var previous_body_yaw := PI
	if preserve_opening_position and is_instance_valid(player) and world_container.get_child_count() > 0:
		previous_room = str(world_container.get_child(0).get_meta("opening_room", ""))
		previous_position = player.global_position
		previous_yaw = player.normal_yaw if player.framed and not player.preferences.get("reduced_motion", false) else player.pivot.rotation.y
		previous_pitch = player.normal_pitch if player.framed and not player.preferences.get("reduced_motion", false) else player.arm.rotation.x
		previous_body_yaw = player.visual.rotation.y
	opening_story = null
	for child in world_container.get_children():
		world_container.remove_child(child)
		child.queue_free()
	var snapshot = model.snapshot()
	if snapshot.get("campaign_chapter", "") != "night_kitchen": kitchen_save_warning = ""
	if snapshot.get("campaign_chapter", "") != "return_platform": return_save_warning = ""
	if snapshot.get("campaign_chapter", "") != "still_here": home_save_warning = ""
	var world
	if snapshot.get("campaign_chapter", "") == "still_here": world = load("res://world/home_world.gd").new().build(snapshot)
	elif snapshot.get("campaign_chapter", "") == "return_platform": world = load("res://world/return_world.gd").new().build(snapshot)
	elif snapshot.get("campaign_chapter", "") == "quiet_orchard": world = load("res://world/orchard_world.gd").new().build(snapshot)
	elif snapshot.get("campaign_chapter", "") == "night_kitchen": world = load("res://world/kitchen_world.gd").new().build(snapshot)
	elif snapshot.get("campaign_chapter", "") == "paper_sky" and paper_courtyard: world = load("res://world/fair_world.gd").new().build(snapshot)
	elif snapshot.get("campaign_chapter", "") == "paper_sky": world = load("res://world/paper_world.gd").new().build(snapshot)
	elif snapshot.get("campaign_chapter", "") == "the_small_fair": world = load("res://world/fair_world.gd").new().build(snapshot)
	else: world = Factory.new().build(snapshot.checkpoint_id)
	world_container.add_child(world)
	player = Player.new()
	world.add_child(player)
	player.global_position = world.get_node("Spawn").global_position
	if snapshot.campaign_chapter == "platform_six":
		var rooms = {"platform":"station", "conductor":"station", "passenger":"carriage_out", "shoreline":"carriage_out", "overlook":"shore", "camera_choice":"shore", "optional_action":"shore", "return_train":"carriage_back", "breakfast":"carriage_back", "complete":"carriage_back"}
		var room: String = rooms.get(snapshot.checkpoint_id, snapshot.checkpoint_id)
		world.set_meta("opening_room", room)
		if room == previous_room:
			player.global_position = previous_position
			player.pivot.rotation.y = previous_yaw
			player.arm.rotation.x = previous_pitch
			player.visual.rotation.y = previous_body_yaw
	player.interact.connect(on_interact)
	player.set_preferences(model.snapshot().settings)
	player.set_touch_mode(touch.touch_mode)
	configure_characters(world,model.snapshot().settings)
	if snapshot.campaign_chapter == "platform_six":
		opening_story = load("res://world/opening_story.gd").new()
		opening_story.name = "OpeningStory"
		world.add_child(opening_story)
		opening_story.configure(snapshot, player)
	hud.apply_settings(model.snapshot().settings)
	touch.apply_settings(model.snapshot().settings)
	hud.set_chapter(model.snapshot())
	var location: String = "the_small_fair" if paper_courtyard else (snapshot.campaign_chapter if snapshot.campaign_chapter != "platform_six" else snapshot.checkpoint_id)
	hud.set_subtitle(audio.location_profile(location).subtitle)
	audio.apply_settings(model.snapshot().settings)
	audio.crossfade_location(location)
	apply_graphics(model.snapshot().settings)
	world.get_node("AmbientMotion").apply_preferences(model.snapshot().settings.reduced_motion)
	if world.has_method("apply_preferences"): world.apply_preferences(model.snapshot().settings.reduced_motion)
	busy = false
	resume_controls()
	if snapshot.get("campaign_chapter", "") == "quiet_orchard" and snapshot.orchard.route == "bench" and snapshot.orchard_checkpoint == "rest": orchard_close_view()
	if snapshot.get("campaign_chapter", "") == "still_here":
		show_home_notice("")
		if snapshot.home_checkpoint == "complete": show_home_state()
func resume_controls():
	if touch != null and hud.modal_visible(): touch.cancel_input()
	if is_instance_valid(opening_story):
		opening_story.set_paused(hud.pause_active)
		if not hud.modal_visible(): opening_story.end_preview()
	if model.snapshot().get("campaign_chapter", "") == "still_here" and world_container.get_child_count() > 0:
		world_container.get_child(0).set_paused(hud.pause_active)
	if model.snapshot().get("campaign_chapter", "") == "return_platform":
		var return_world = world_container.get_child(0)
		return_world.set_paused(hud.pause_active)
	if model.snapshot().get("campaign_chapter", "") == "quiet_orchard":
		var orchard = world_container.get_child(0)
		if orchard.has_method("set_paused"): orchard.set_paused(hud.pause_active)
	if model.snapshot().get("campaign_chapter", "") == "night_kitchen":
		var kitchen = world_container.get_child(0)
		if kitchen.has_method("set_paused"): kitchen.set_paused(hud.pause_active)
	if racing:
		var race = world_container.get_child(0).get_node_or_null("FairRace")
		if race != null and race.has_method("set_paused"): race.set_paused(hud.pause_active)
	if is_instance_valid(player):
		player.set_controls_enabled(not hud.modal_visible() and not busy and not return_cinematic and not home_cinematic and not home_viewing and not paper_viewing and not orchard_viewing and not kitchen_viewing and not kitchen_animating)
		if not hud.modal_visible():
			player.set_framed_view(false)
			end_character_conversation()
func on_interact(target):
	if journey != null and journey.active and is_instance_valid(target):
		if busy or hud.modal_visible(): return
		journey.dispatch(str(target.get_meta("action_id", "")), target.get_meta("value") if target.has_meta("value") else null)
		return
	if busy or hud.modal_visible() or not is_instance_valid(target): return
	var action: String = target.get_meta("action_id","")
	var target_value: Variant = target.get_meta("value") if target.has_meta("value") else null
	if action == "pet_cat":
		if is_instance_valid(opening_story) and target == opening_story.cat and target.pet():
			player.set_controls_enabled(false)
			hud.show_dialogue("pet_cat")
		return
	if action.begins_with("home_"):
		dispatch_home(action, target_value)
		return
	if action.begins_with("return_") and action != "return_train":
		dispatch_return(action, target_value)
		return
	if action.begins_with("orchard_"):
		dispatch_orchard(action, target_value)
		return
	if action.begins_with("kitchen_"):
		dispatch_kitchen(action, target_value)
		return
	if action.begins_with("paper_"):
		dispatch_paper(action, target_value)
		return
	if action.begins_with("fair_") or action in ["inspect_fair","level_pond","release_boat","replay_race"]:
		if action == "fair_greeting":
			show_fair_state()
		elif action == "fair_setup":
			show_fair_state()
		elif action in ["inspect_fair","level_pond","fair_departure","fair_end"]:
			show_fair_state()
		elif action in ["fair_hours","fair_prizes","fair_bird"]:
			player.set_controls_enabled(false)
			hud.show_fair_dialogue(action,model.snapshot())
		else: dispatch(action,target_value)
		return
	if action == "finish" and model.snapshot().chapter_complete:
		player.set_controls_enabled(false)
		hud.show_campaign_handoff()
		return
	if action == "dialogue":
		dispatch("dialogue",target_value)
		return
	if action == "inspect_landmark":
		var landmark = target_value
		if model.snapshot().checkpoint_id != "overlook" or landmark not in Model.LANDMARKS: return
		if model.apply(action,landmark): persist()
		player.set_controls_enabled(false)
		player.set_framed_view(true)
		begin_character_conversation("inspect_landmark",landmark,target)
		hud.set_chapter(model.snapshot())
		hud.show_dialogue("shore_" + str(landmark), model.snapshot())
		return
	if action not in ["puzzle","camera","optional"] and not hud.authored.dialogues.has(action): return
	player.set_controls_enabled(false)
	player.set_framed_view(true)
	begin_character_conversation(action,target_value,target)
	if action == "puzzle":
		if is_instance_valid(opening_story): opening_story.begin_preview(int(model.snapshot().overlook_alignment))
		hud.show_puzzle(model.snapshot())
	elif action == "camera": hud.show_dialogue("camera", model.snapshot())
	elif action == "optional": hud.show_dialogue("optional", model.snapshot())
	else: hud.show_dialogue(action, model.snapshot())
func dispatch(action: String, value: Variant = null):
	if action.begins_with("journey_"):
		journey.dispatch(action,value)
		return
	if action == "begin_home" or action.begins_with("home_"):
		dispatch_home(action, value)
		return
	if action == "begin_return" or (action.begins_with("return_") and action != "return_train"):
		dispatch_return(action, value)
		return
	if action == "begin_orchard" or action.begins_with("orchard_"):
		dispatch_orchard(action, value)
		return
	if action == "begin_kitchen" or action.begins_with("kitchen_"):
		dispatch_kitchen(action, value)
		return
	if action == "begin_paper" or action.begins_with("paper_") or action.begins_with("set_paper_") or action in ["raise_paper", "finish_paper"]:
		dispatch_paper(action, value)
		return
	if action in ["begin_fair","fair_greeting","set_rudder","set_sail","set_race_mode","release_boat","inspect_fair","level_pond","replay_race","fair_departure","fair_config","fair_continue","fair_end"]:
		dispatch_fair(action,value)
		return
	if action == "dialogue":
		var branch = hud.authored.get("local_dialogues",{}).get(str(value),{})
		if busy or branch.is_empty() or branch.checkpoint != model.snapshot().checkpoint_id: return
		if model.record_choice("platform_six.dialogue." + str(value)): persist()
		if is_instance_valid(opening_story): opening_story.local_beat(str(value))
		player.set_controls_enabled(false)
		player.set_framed_view(true)
		begin_character_conversation(action,value)
		if is_instance_valid(opening_story): opening_story.begin_local_view(str(value))
		hud.show_dialogue(str(value), model.snapshot())
		return
	if action == "preview_alignment":
		if busy or not hud.modal_visible() or not model.apply(action, value): return
		persist()
		if is_instance_valid(opening_story): opening_story.set_alignment(int(value))
		hud.show_puzzle(model.snapshot())
		return
	if action == "reset":
		if racing:
			hud.show_notice("Resume the pond race before starting a new journey.")
			return
		var reset = store.reset_snapshot(save_path)
		if reset.ok:
			model = Model.new()
			# A reset is a successful replacement of the blocked journey. Clear
			# warning state from every chapter as well as its visible HUD notice;
			# otherwise the fresh apartment still claims it cannot be saved.
			campaign_save_warning = ""
			kitchen_save_warning = ""
			orchard_save_warning = ""
			return_save_warning = ""
			home_save_warning = ""
			hud.show_notice("")
			paper_courtyard = false
			hud.close_all()
			route(false)
		else: hud.show_notice(reset.error)
		return
	if action == "dismiss":
		hud.close_modal()
		if home_viewing and not hud.pause_active: home_end_view()
		else: resume_controls()
		return
	if busy: return
	busy = true
	if not model.apply(action,value):
		busy = false
		show_campaign_notice("Look around a little more. This moment is still here.")
		resume_controls()
		return
	hud.show_notice("") # Clear prior checkpoint/retry prose before new save status.
	persist()
	if action == "align" and model.snapshot().checkpoint_id == "overlook":
		busy = false
		hud.show_puzzle(model.snapshot())
		show_campaign_notice("That framing leaves a shape outside. Try another; there's no rush.")
		return
	hud.close_modal()
	route()
	if action in ["meet_stranger","board_train","arrive_shore","resolve_action"]:
		player.set_framed_view(true)
		hud.show_arrival(model.snapshot().checkpoint_id)
		resume_controls()
	if action == "choose_camera":
		var responses = {"take":"Mira holds the box while you take one photograph. ‘I nearly photographed my thumb on every frame. You’ve avoided my signature technique.’","lend":"Mira lifts the camera, lowers it, then catches a wave through the arch. ‘There. A doorway with no door.’","unused":"Mira puts the unopened box in her pocket. ‘Then it can come to the fair. I’d like to remember the sound here anyway.’"}
		show_campaign_notice(responses[value])
	if action == "resolve_action": show_campaign_notice("The carriage is waiting. There is a place set for you.")
	if action == "finish":
		hud.show_campaign_handoff()
		resume_controls()
func persist() -> bool:
	var result = store.save_snapshot(model.snapshot(),save_path)
	if result.ok and not campaign_save_warning.is_empty(): hud.show_notice("")
	campaign_save_warning = "Unsaved progress: " + result.error + ". Save and leave will retry; this scene is currently only in memory." if not result.ok and model.snapshot().campaign_chapter in ["platform_six", "the_small_fair", "paper_sky"] else ""
	if model.snapshot().get("campaign_chapter", "") == "still_here":
		if result.ok and not home_save_warning.is_empty(): hud.show_notice("")
		home_save_warning = "Unsaved progress: " + result.error + ". Save and leave will retry; this scene is currently only in memory." if not result.ok else ""
	if model.snapshot().get("campaign_chapter", "") == "return_platform":
		if result.ok and not return_save_warning.is_empty(): hud.show_notice("")
		return_save_warning = "Unsaved progress: " + result.error + ". Save and leave will retry; this scene is currently only in memory." if not result.ok else ""
	if model.snapshot().get("campaign_chapter", "") == "quiet_orchard":
		if result.ok and not orchard_save_warning.is_empty(): hud.show_notice("")
		orchard_save_warning = "Unsaved progress: " + result.error + ". Save and leave will retry; this scene is currently only in memory." if not result.ok else ""
	if model.snapshot().get("campaign_chapter", "") == "night_kitchen":
		if result.ok and not kitchen_save_warning.is_empty(): hud.show_notice("")
		kitchen_save_warning = "Unsaved progress: " + result.error + ". Save and leave will retry; this scene is currently only in memory." if not result.ok else ""
	if not result.ok: hud.show_notice(campaign_save_warning if not campaign_save_warning.is_empty() else home_save_warning if not home_save_warning.is_empty() else return_save_warning if not return_save_warning.is_empty() else orchard_save_warning if not orchard_save_warning.is_empty() else (kitchen_save_warning if not kitchen_save_warning.is_empty() else "Unsaved progress: " + result.error))
	return result.ok

func show_campaign_notice(message: String):
	hud.show_notice(campaign_save_warning + ("\n" if not campaign_save_warning.is_empty() and not message.is_empty() else "") + message)
func change_settings(settings):
	if model.apply("settings",settings):
		persist()
		player.set_preferences(settings)
		configure_characters(world_container.get_child(0),settings)
		if is_instance_valid(opening_story): opening_story.apply_preferences(bool(settings.reduced_motion))
		hud.apply_settings(settings)
		touch.apply_settings(settings)
		audio.apply_settings(settings)
		if journey != null and journey.active:
			journey.audio_profile()
			if is_instance_valid(journey.activity_view): journey.activity_view.apply_preferences(settings.reduced_motion)
		apply_graphics(settings)
		world_container.get_child(0).get_node("AmbientMotion").apply_preferences(settings.reduced_motion)
		if world_container.get_child(0).has_method("apply_preferences"): world_container.get_child(0).apply_preferences(settings.reduced_motion)
		var race = world_container.get_child(0).get_node_or_null("FairRace")
		if race != null and race.has_method("apply_preferences"): race.apply_preferences(settings.reduced_motion)
func show_pause():
	if busy and not racing: return
	if touch != null: touch.cancel_input()
	if is_instance_valid(opening_story): opening_story.set_paused(true)
	if model.snapshot().get("campaign_chapter", "") == "still_here":
		world_container.get_child(0).set_paused(true)
	if model.snapshot().get("campaign_chapter", "") == "return_platform":
		world_container.get_child(0).set_paused(true)
	if model.snapshot().get("campaign_chapter", "") == "quiet_orchard":
		var orchard = world_container.get_child(0)
		if orchard.has_method("set_paused"): orchard.set_paused(true)
	if model.snapshot().get("campaign_chapter", "") == "night_kitchen":
		var kitchen = world_container.get_child(0)
		if kitchen.has_method("set_paused"): kitchen.set_paused(true)
	if racing:
		var race = world_container.get_child(0).get_node_or_null("FairRace")
		if race != null and race.has_method("set_paused"): race.set_paused(true)
	player.set_controls_enabled(false)
	hud.show_pause(model.snapshot().settings)
	if racing or (journey != null and journey.active):
		for button_ in hud.footer.get_children():
			if button_.text.begins_with("Start a new journey"): button_.disabled = true
func _unhandled_input(event):
	if home_cinematic and not hud.pause_active and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE)):
		world_container.get_child(0).finish_ending()
		get_viewport().set_input_as_handled()
		return
	if home_viewing and not hud.pause_active and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE)):
		hud.close_all()
		dispatch_home("home_leave_view")
		get_viewport().set_input_as_handled()
		return
	if return_cinematic and not hud.pause_active and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE)):
		var return_world = world_container.get_child(0)
		if return_preparing: return_world.finish_preparation()
		else: return_world.finish_departure()
		get_viewport().set_input_as_handled()
		return
	if orchard_viewing and not hud.modal_visible() and event.is_action_pressed("interact"):
		var orchard_state = model.snapshot()
		if orchard_state.orchard_checkpoint == "rest": dispatch_orchard("orchard_finish" if orchard_state.orchard.beat >= 3 else "orchard_advance")
		get_viewport().set_input_as_handled()
		return
	if orchard_viewing and not hud.modal_visible() and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE)):
		dispatch_orchard("orchard_leave_view")
		get_viewport().set_input_as_handled()
		return
	if kitchen_viewing and not hud.modal_visible() and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE)):
		dispatch_kitchen("kitchen_leave_view")
		get_viewport().set_input_as_handled()
		return
	if paper_viewing and not hud.modal_visible() and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE)):
		dispatch_paper("paper_leave_view")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F12:
		capture_frame()
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		var dedicated_pause = event.is_action_pressed("pause") and (event is InputEventJoypadButton or (event is InputEventKey and event.physical_keycode == KEY_P))
		if hud.pause_active:
			hud.resume_pause()
		elif dedicated_pause or not hud.modal_visible():
			show_pause()
		else:
			hud.close_modal()
			resume_controls()
		get_viewport().set_input_as_handled()

func _process(delta):
	update_return_cinematic()
	if orchard_viewing and not orchard_observation and not hud.pause_active:
		var orchard = world_container.get_child(0)
		var camera = orchard.get_node_or_null("OrchardCloseCamera")
		var marker = orchard.get_node_or_null("RestView")
		if camera != null and marker != null:
			camera.global_position = marker.global_position
			camera.look_at(marker.get_meta("look_at"),Vector3.UP)
	update_kitchen_caption(delta)
	if is_instance_valid(player):
		player.set_touch_mode(touch.touch_mode)
		touch.bottom_inset = maxf(72.0,hud.notice.get_minimum_size().y + 24.0)
		touch.set_available(player.enabled, (player.enabled and is_instance_valid(player.nearest)) or (orchard_viewing and not orchard_observation), not busy or racing)
		var hint = ""
		if is_instance_valid(player.nearest) and player.enabled:
			hint = ("Tap Interact" if touch.touch_mode else ("A" if Input.get_connected_joypads().size() else "E")) + " · " + str(player.nearest.get_meta("label"))
		hud.set_prompt(hint)

func apply_graphics(settings: Dictionary):
	var world = world_container.get_child(0)
	var illustrated = world.get_node_or_null("IllustratedWorld")
	if illustrated == null:
		illustrated = load("res://world/illustrated_world.gd").new()
		illustrated.name = "IllustratedWorld"
		world.add_child(illustrated)
		var profile = str(model.snapshot().campaign_chapter)
		if profile == "platform_six": profile = str(model.snapshot().checkpoint_id)
		if world.has_meta("journey_id"): profile = "journey_train" if world.get_meta("scene_kind") == "train" else str(world.get_meta("journey_id"))
		illustrated.configure(world,profile)
	illustrated.apply_settings(settings)
	var viewport = get_viewport()
	var efficient_medium = settings.graphics == "medium" and world_container.get_child(0).get_meta("efficient_medium_aa",false)
	viewport.msaa_3d = Viewport.MSAA_DISABLED if settings.graphics == "low" or efficient_medium else Viewport.MSAA_2X
	viewport.scaling_3d_scale = 0.8 if settings.graphics == "low" else 1.0
	for light in world_container.find_children("*","Light3D",true,false):
		light.shadow_enabled = settings.graphics == "high" and not light.get_meta("scenic_fill",false)

func capture_frame():
	if DisplayServer.get_name() == "headless": return
	var directory = ProjectSettings.globalize_path("res://../evidence/screenshots")
	DirAccess.make_dir_recursive_absolute(directory)
	get_viewport().get_texture().get_image().save_png(directory + "/" + model.snapshot().checkpoint_id + "_" + str(Time.get_ticks_msec()) + ".png")

func configure_characters(world: Node3D, settings: Dictionary):
	for actor in world.find_children("*","Node3D",true,false):
		if actor.has_method("apply_preferences") and actor.has_method("set_conversation"):
			# Return-world acting owns its paused skeleton; resume applies the new preference.
			if world.has_method("cinematic_state") and world.paused and actor == world.get_node_or_null("Mira"): continue
			actor.apply_preferences(bool(settings.get("reduced_motion",false)))
			if actor.get_meta("character_id", "") != "protagonist": actor.set_attention_target(player)

func begin_character_conversation(action: String, value: Variant = null, fallback: Node3D = null):
	end_character_conversation()
	var mira = world_container.get_child(0).get_node_or_null("Mira")
	var mira_exchange = action.begins_with("fair_") or action in ["meet_passenger","camera","return_train","have_breakfast","inspect_landmark"]
	if action == "dialogue":
		mira_exchange = str(value).begins_with("passenger_") or str(value).begins_with("shore_") or str(value) in ["train_window","breakfast_postcard"]
	var speaker: Node3D = mira if mira_exchange else fallback
	if action in ["meet_stranger", "board_train"] or (action == "dialogue" and str(value).begins_with("umbrella_")):
		var supporting = world_container.get_child(0).get_node_or_null("SupportingPerformer")
		if supporting != null: speaker = supporting
	if not is_instance_valid(speaker): return
	if not speaker.has_method("set_conversation"):
		var supporting = speaker.get_node_or_null("SupportingPerformer")
		if supporting != null and supporting.has_method("set_conversation"): speaker = supporting
	conversation_actor = speaker
	if player.has_method("frame_speaker"): player.frame_speaker(speaker)
	player.visual.set_conversation(true,speaker)
	if speaker.has_method("set_conversation"): speaker.set_conversation(true,player)

func end_character_conversation():
	if is_instance_valid(conversation_actor) and conversation_actor.has_method("set_conversation"):
		conversation_actor.set_conversation(false)
	conversation_actor = null
	if is_instance_valid(player) and is_instance_valid(player.visual):
		player.visual.set_conversation(false)
		player.visual.set_attention_target(null)

func show_fair_state(dialogue_id: String = ""):
	var snapshot = model.snapshot()
	if snapshot.get("campaign_chapter","") != "the_small_fair": return
	var ids = {"arrival":"fair_arrival","workshop":"fair_setup","crooked_race":"fair_crooked","level_pond":"fair_level","race_ready":"fair_ready","result":"fair_result","complete":"fair_complete"}
	var id: String = dialogue_id if not dialogue_id.is_empty() else ids.get(snapshot.fair_checkpoint,"fair_arrival")
	player.set_controls_enabled(false)
	player.set_framed_view(true)
	begin_character_conversation("fair_conversation")
	hud.show_fair_dialogue(id,snapshot)

func dispatch_fair(action: String, value: Variant = null):
	if busy: return
	var snapshot = model.snapshot()
	if action == "fair_config":
		if snapshot.get("fair_checkpoint","") not in ["workshop","race_ready"]: return
		player.set_controls_enabled(false)
		hud.show_fair_config(snapshot,"main" if value == null else str(value))
		return
	if action == "fair_continue":
		var allowed = {"workshop":"fair_setup","level_pond":"fair_level","race_ready":"fair_ready"}
		if allowed.get(snapshot.get("fair_checkpoint",""),"") == str(value): show_fair_state(str(value))
		return
	if action == "fair_end":
		if snapshot.get("fair_checkpoint","") == "complete":
			hud.close_all()
			resume_controls()
		return
	if not model.apply(action,value):
		show_campaign_notice("This moment is still here. You can explore or try another arrangement.")
		return
	persist()
	snapshot = model.snapshot()
	if action == "begin_fair":
		hud.close_all()
		route()
		show_fair_state()
		return
	var world = world_container.get_child(0)
	if world.has_method("apply_snapshot"): world.apply_snapshot(snapshot)
	hud.set_chapter(snapshot)
	if action in ["release_boat","replay_race"]:
		hud.close_all()
		player.set_controls_enabled(false)
		player.set_framed_view(true)
		busy = true
		racing = true
		show_campaign_notice("Three boats drift to the duck" if snapshot.fair_checkpoint == "crooked_race" else "The pond is level · your boat takes its own route")
		var race = world.get_node_or_null("FairRace")
		if race != null:
			race.play_race(snapshot,action == "replay_race")
			await race.completed
		racing = false
		busy = false
		show_campaign_notice("")
		show_fair_state()
	elif action in ["set_rudder","set_sail","set_race_mode"]:
		hud.show_fair_config(snapshot)
	elif action == "fair_greeting": show_fair_state("fair_greeting_"+str(value))
	elif action == "inspect_fair": show_fair_state("fair_inspect_"+str(value))
	elif action == "level_pond": show_fair_state("fair_leveller_"+str(value))
	else: show_fair_state()

func show_paper_state(id: String = ""):
	var snapshot = model.snapshot()
	if snapshot.get("campaign_chapter", "") != "paper_sky": return
	var ids = {"arrival":"paper_arrival", "workshop":"paper_workshop", "raised":"paper_raised", "complete":"paper_complete"}
	player.set_controls_enabled(false)
	player.set_framed_view(true)
	hud.show_paper_dialogue(ids.get(snapshot.paper_checkpoint, "paper_arrival") if id.is_empty() else id, snapshot, not paper_courtyard)

func dispatch_paper(action: String, value: Variant = null):
	if busy: return
	var snapshot = model.snapshot()
	if action in ["paper_close_view", "paper_shadow_view"]:
		if snapshot.get("campaign_chapter", "") != "paper_sky": return
		var world = world_container.get_child(0)
		var marker = world.get_node_or_null("ShadowView" if action == "paper_shadow_view" else "SignView")
		if marker == null: return
		var camera = world.get_node_or_null("PaperCloseCamera")
		if camera == null:
			camera = Camera3D.new()
			camera.name = "PaperCloseCamera"
			world.add_child(camera)
		camera.global_position = marker.global_position
		camera.look_at(marker.get_meta("look_at"), Vector3.UP)
		camera.fov = 52
		camera.current = true
		if not paper_viewing:
			for label in world.find_children("*", "Label3D", true, false):
				if label.visible and label.get_parent().name != "Nameplate":
					paper_view_labels.append(label)
					label.visible = false
		paper_viewing = true
		hud.close_all()
		player.set_controls_enabled(false)
		show_campaign_notice("Esc / B · return to the room     P / Menu · pause")
		return
	if action == "paper_leave_view":
		for label in paper_view_labels:
			if is_instance_valid(label): label.visible = true
		paper_view_labels.clear()
		paper_viewing = false
		player.arm.get_child(0).current = true
		show_campaign_notice("")
		resume_controls()
		return
	if action in ["paper_courtyard", "paper_return"]:
		if snapshot.get("paper_checkpoint", "") != "complete": return
		paper_courtyard = action == "paper_courtyard"
		hud.close_all()
		route()
		return
	if action in ["paper_worktable", "paper_star", "paper_layout", "paper_length", "paper_fold", "paper_config"]:
		if snapshot.get("paper_checkpoint", "") != "workshop": return
		player.set_controls_enabled(false)
		var page = str(value) if action == "paper_config" and value != null else action.trim_prefix("paper_")
		hud.show_paper_config(snapshot, "main" if page == "worktable" or page == "config" else page)
		return
	if action in ["paper_inspect", "paper_exit"] or (action == "paper_greeting" and value == null):
		show_paper_state("paper_inspect" if action == "paper_inspect" else "")
		return
	if action == "paper_raise": action = "raise_paper"
	if not model.apply(action, value):
		show_campaign_notice("The pieces are still here. You can change the arrangement or come back to it.")
		return
	var saved = persist()
	snapshot = model.snapshot()
	if action == "begin_paper":
		paper_courtyard = false
		hud.close_all()
		route()
		show_paper_state()
		return
	var world = world_container.get_child(0)
	if world.has_method("apply_snapshot"): world.apply_snapshot(snapshot)
	hud.set_chapter(snapshot)
	if action == "set_paper_mode" and value == "watch":
		hud.show_paper_config(snapshot, "watch")
	elif action.begins_with("set_paper_"):
		hud.close_all()
		resume_controls()
		if saved: hud.show_notice("The preview keeps your " + action.trim_prefix("set_paper_") + " choice · " + str(value).replace("_", " "))
	else: show_paper_state()

func request_quit():
	if journey != null and journey.active and not journey.save():
		journey.show_save_problem()
		return
	if model.snapshot().get("campaign_chapter", "") == "still_here" and not persist():
		show_home_notice("Please keep this window open until the save succeeds.")
		return
	if model.snapshot().get("campaign_chapter", "") == "return_platform" and not persist():
		show_return_notice("Please keep this window open until the save succeeds.")
		return
	if model.snapshot().get("campaign_chapter", "") == "quiet_orchard" and not persist():
		show_orchard_notice("Please keep this window open until the save succeeds.")
		return
	if model.snapshot().campaign_chapter in ["platform_six", "the_small_fair", "paper_sky", "night_kitchen"] and not persist(): return
	quit_to_desktop()

func quit_to_desktop():
	if quitting: return
	quitting = true
	busy = true
	if is_instance_valid(player): player.set_controls_enabled(false)
	if is_instance_valid(audio): audio.shutdown()
	if journey != null and is_instance_valid(journey.profile_player): journey.profile_player.stop()
	# Give the audio mixer a frame to release stopped WAV playback references.
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _notification(what: int):
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_inside_tree(): request_quit()

func show_kitchen_notice(message: String):
	hud.show_notice((kitchen_save_warning + ("\n" if not message.is_empty() else "")) + message)

func show_kitchen_state(id: String = ""):
	var snapshot = model.snapshot()
	if snapshot.get("campaign_chapter", "") != "night_kitchen": return
	var ids = {"arrival":"kitchen_arrival", "supper":"kitchen_supper", "conversation":"kitchen_conversation", "complete":"kitchen_complete"}
	player.set_controls_enabled(false)
	player.set_framed_view(true)
	hud.show_kitchen_dialogue(ids.get(snapshot.kitchen_checkpoint, "kitchen_arrival") if id.is_empty() else id, snapshot)

func kitchen_close_view(sign_view: bool = false):
	var world = world_container.get_child(0)
	var marker = world.get_node_or_null("SignView" if sign_view else "TableView")
	if marker == null: return
	var camera = world.get_node_or_null("KitchenCloseCamera")
	if camera == null:
		camera = Camera3D.new()
		camera.name = "KitchenCloseCamera"
		world.add_child(camera)
	camera.global_position = marker.global_position
	camera.look_at(marker.get_meta("look_at"), Vector3.UP)
	camera.fov = 52
	camera.current = true
	if not kitchen_viewing:
		for label in world.find_children("*", "Label3D", true, false):
			if label.visible and label.get_parent().name != "Nameplate":
				kitchen_labels.append(label)
				label.visible = false
	kitchen_viewing = true
	player.visual.visible = false
	hud.close_all()
	player.set_controls_enabled(false)
	show_kitchen_notice("Esc / B · return to the room     P / Menu · pause")

func kitchen_end_view():
	for label in kitchen_labels:
		if is_instance_valid(label): label.visible = true
	kitchen_labels.clear()
	kitchen_viewing = false
	if is_instance_valid(player):
		player.arm.get_child(0).current = true
		player.visual.visible = true
	show_kitchen_notice("")
	resume_controls()

func dispatch_kitchen(action: String, value: Variant = null):
	if busy or quitting: return
	var snapshot = model.snapshot()
	if action != "begin_kitchen" and snapshot.get("campaign_chapter", "") != "night_kitchen": return
	if action == "kitchen_leave_view":
		if kitchen_animating:
			kitchen_skip_dialogue = true
			var kitchen = world_container.get_child(0)
			if kitchen.has_method("finish_gesture"): kitchen.finish_gesture()
		kitchen_end_view()
		return
	if kitchen_animating: return
	if action in ["kitchen_view", "kitchen_sign_view"]:
		kitchen_close_view(action == "kitchen_sign_view")
		return
	if action == "kitchen_leave":
		if persist(): quit_to_desktop()
		else: show_kitchen_notice("Please keep this window open until the save succeeds.")
		return
	if action in ["kitchen_table", "kitchen_mira", "kitchen_exit"] or (action == "kitchen_join" and value == null):
		show_kitchen_state()
		return
	if action in ["kitchen_sign", "kitchen_camera"]:
		show_kitchen_state(action)
		return
	if action in ["kitchen_bread", "kitchen_cup", "kitchen_pepper"]:
		# Physical exchanges are optional. In later states they remain viewable.
		if snapshot.kitchen_checkpoint == "supper": show_kitchen_state(action)
		else: show_kitchen_state()
		return
	if not model.apply(action, value): return
	var saved = persist()
	snapshot = model.snapshot()
	if action == "begin_kitchen":
		paper_courtyard = false
		hud.close_all()
		route()
		show_kitchen_state()
		return
	var world = world_container.get_child(0)
	world.apply_snapshot(snapshot)
	hud.set_chapter(snapshot)
	if action in ["kitchen_join", "kitchen_share"]:
		kitchen_gesture_id = "join_" + str(value) if action == "kitchen_join" else str(value)
		kitchen_caption_elapsed = 0.0
		kitchen_animating = true
		kitchen_skip_dialogue = false
		kitchen_close_view()
		var lines = hud.kitchen_authored.get("gesture_lines", {}).get(kitchen_gesture_id, [])
		if not lines.is_empty(): show_kitchen_notice(lines[0])
		world.begin_gesture(kitchen_gesture_id, func():
			if not is_instance_valid(world) or world != world_container.get_child(0): return
			kitchen_animating = false
			kitchen_end_view()
			if not kitchen_skip_dialogue: show_kitchen_state()
		)
	elif action == "kitchen_departure": show_kitchen_state()
	if not saved: show_kitchen_notice("")

func update_kitchen_caption(delta):
	if not kitchen_animating or hud.pause_active: return
	kitchen_caption_elapsed += delta
	var lines = hud.kitchen_authored.get("gesture_lines", {}).get(kitchen_gesture_id, [])
	if lines.size() > 1 and kitchen_caption_elapsed >= 2.0: show_kitchen_notice(lines[1])

func show_orchard_notice(message: String):
	hud.show_notice(orchard_save_warning + ("\n" if not orchard_save_warning.is_empty() and not message.is_empty() else "") + message)

func show_orchard_state():
	var snapshot = model.snapshot()
	if snapshot.get("campaign_chapter", "") != "quiet_orchard": return
	player.set_controls_enabled(false)
	hud.show_orchard_dialogue(snapshot)

func orchard_close_view(observation: bool = false):
	orchard_observation = observation
	var world = world_container.get_child(0)
	var marker = world.get_node_or_null("ObservationView" if observation else "RestView")
	if marker == null: return
	var camera = world.get_node_or_null("OrchardCloseCamera")
	if camera == null:
		camera = Camera3D.new()
		camera.name = "OrchardCloseCamera"
		world.add_child(camera)
	camera.global_position = marker.global_position
	camera.look_at(marker.get_meta("look_at"), Vector3.UP)
	camera.fov = 55
	camera.current = true
	if not orchard_viewing:
		for label in world.find_children("*", "Label3D", true, false):
			if label.visible:
				orchard_labels.append(label)
				label.visible = false
	orchard_viewing = true
	if world.has_method("set_rest_view"): world.set_rest_view(not observation)
	player.visual.visible = false
	hud.close_all()
	player.set_controls_enabled(false)
	show_orchard_notice("E / A · next moment when you choose     Esc / B · return     P / Menu · pause" if model.snapshot().orchard_checkpoint == "rest" else "Esc / B · return to the orchard     P / Menu · pause")

func orchard_end_view():
	var world = world_container.get_child(0)
	if world.has_method("finish_route"): world.finish_route()
	if world.has_method("set_rest_view"): world.set_rest_view(false)
	for label in orchard_labels:
		if is_instance_valid(label): label.visible = true
	orchard_labels.clear()
	orchard_viewing = false
	if is_instance_valid(player):
		player.arm.get_child(0).current = true
		player.visual.visible = true
	show_orchard_notice("")
	resume_controls()

func dispatch_orchard(action: String, value: Variant = null):
	if busy or quitting: return
	var snapshot = model.snapshot()
	if action != "begin_orchard" and snapshot.get("campaign_chapter", "") != "quiet_orchard": return
	if action == "orchard_leave_view":
		orchard_end_view()
		return
	if action == "orchard_view":
		orchard_close_view(value == "pear")
		return
	if action == "orchard_leave":
		if persist(): quit_to_desktop()
		else: show_orchard_notice("Please keep this window open until the save succeeds.")
		return
	if action in ["orchard_arrival", "orchard_exit", "orchard_rest"] or (action == "orchard_route" and value == null):
		show_orchard_state()
		return
	if not model.apply(action, value): return
	persist()
	snapshot = model.snapshot()
	if action in ["begin_orchard", "orchard_route"]:
		paper_courtyard = false
		hud.close_all()
		route()
		if action == "begin_orchard": show_orchard_state()
		else:
			show_orchard_notice("A pear hangs above the path. Continue whenever you choose · E at your resting place")
			var orchard = world_container.get_child(0)
			if value == "cart" and orchard.has_method("begin_route"):
				orchard_close_view()
				orchard.begin_route(func():
					if is_instance_valid(orchard) and orchard == world_container.get_child(0):
						player.global_position = orchard.get_node("Spawn").global_position
						orchard_end_view()
						show_orchard_notice("The handcart rests between the trees · E at the cart to continue whenever you choose")
				)
		return
	var world = world_container.get_child(0)
	world.apply_state(snapshot)
	hud.set_chapter(snapshot)
	hud.close_all()
	resume_controls()
	if action == "orchard_advance":
		var captions = ["", "A pear drops into the grass. The branch is still.", "Two workers cross the distant doorway, carrying an empty crate.", "Train light slips across the trunks, then leaves the orchard blue again."]
		show_orchard_notice(captions[snapshot.orchard.beat])
		if world.has_method("begin_beat"): world.begin_beat(snapshot.orchard.beat, func(): pass)
	elif action == "orchard_finish": show_orchard_state()

func show_return_notice(message: String):
	hud.show_notice(return_save_warning + ("\n" if not return_save_warning.is_empty() and not message.is_empty() else "") + message)

func show_return_state(id: String = ""):
	if model.snapshot().get("campaign_chapter", "") != "return_platform" or return_cinematic: return
	player.set_controls_enabled(false)
	hud.show_return_dialogue(model.snapshot(), id)

func start_return_camera(preparing: bool):
	var world = world_container.get_child(0)
	return_cinematic = true
	return_preparing = preparing
	return_controls_text = hud.controls.text
	hud.controls.text = "Esc / B · skip presentation    P / Menu · pause"
	hud.title.text = "THE RETURN PLATFORM"
	return_last_phase = ""
	var camera = world.get_node_or_null("ReturnCinematicCamera")
	if camera == null:
		camera = Camera3D.new()
		camera.name = "ReturnCinematicCamera"
		camera.fov = 47
		world.add_child(camera)
	camera.current = true
	for label in world.find_children("*", "Label3D", true, false):
		if label.visible and not label.has_meta("cinematic_visible"):
			return_labels.append(label)
			label.visible = false
	hud.close_all()
	player.set_controls_enabled(false)
	player.visual.visible = false
	update_return_cinematic()

func end_return_camera():
	if world_container.get_child_count() > 0:
		world_container.get_child(0).apply_state(model.snapshot())
	return_cinematic = false
	return_preparing = false
	hud.controls.text = return_controls_text
	hud.set_chapter(model.snapshot())
	for label in return_labels:
		if is_instance_valid(label): label.visible = true
	return_labels.clear()
	if is_instance_valid(player):
		player.arm.get_child(0).current = true
		player.visual.visible = true
	audio.set_return_phase("hold")
	show_return_notice("")
	resume_controls()

func update_return_cinematic():
	if not return_cinematic or hud.pause_active or world_container.get_child_count() == 0: return
	var world = world_container.get_child(0)
	var marker = world.get_node_or_null("ReturnCamera")
	var camera = world.get_node_or_null("ReturnCinematicCamera")
	if marker != null and camera != null:
		camera.global_position = marker.global_position
		camera.fov = marker.get_meta("fov", 47.0)
		if marker.has_meta("look_at"): camera.look_at(marker.get_meta("look_at"), Vector3.UP)
	var phase: String = world.cinematic_phase
	if phase != return_last_phase:
		return_last_phase = phase
		audio.set_return_phase(phase)
		var captions = {"indicator":"The departure indicator changes to LOWER MILL.", "notice":"Mira glances up. A small pause.", "lift_tool_roll":"She lifts the tool roll.", "adjust_strap":"She adjusts the strap.", "look_to_player":"She looks toward you.", "approach":"[The train approaches; a little air moves under the canopy]", "doors_open":"[The doors open]", "boarding":"Mira steps aboard.", "turn_back":"She turns back toward the platform.", "camera_slip":"The borrowed camera slips; she catches it.", "camera_catch":"Mira laughs at herself.", "doors_close":"[The doors close]", "train_leaves":"[Wheels recede along the rails]", "ambience_hold":"[The platform settles into its ordinary hum]"}
		var caption: String = captions.get(phase, "") if model.snapshot().settings.subtitles else ""
		if phase == "farewell_reply" and model.snapshot().settings.subtitles:
			caption = hud.return_authored.get("farewell_reply_captions", {}).get(model.snapshot().return_state.farewell, "")
		show_return_notice(caption + ("\n" if not caption.is_empty() else "") + "Esc / B · skip presentation     P / Menu · pause")

func dispatch_return(action: String, value: Variant = null):
	if busy or quitting: return
	var snapshot = model.snapshot()
	if action != "begin_return" and snapshot.get("campaign_chapter", "") != "return_platform": return
	if action == "return_leave":
		if persist(): quit_to_desktop()
		else: show_return_notice("Please keep this window open until the save succeeds.")
		return
	if return_cinematic: return
	if action in ["return_state", "return_exit"] or (action == "return_farewell" and value == null):
		show_return_state()
		return
	if action in ["return_conductor", "return_jo"]:
		var field = "conductor_revealed" if action == "return_conductor" else "jo_met"
		if snapshot.return_state[field]:
			show_return_state(action)
			return
	if not model.apply(action, value): return
	persist()
	snapshot = model.snapshot()
	if action == "begin_return":
		paper_courtyard = false
		hud.close_all()
		route()
		show_return_state()
		return
	var world = world_container.get_child(0)
	hud.set_chapter(snapshot)
	if action == "return_arrival":
		world.apply_state(snapshot)
		start_return_camera(true)
		world.preparation_finished.connect(func():
			if is_instance_valid(world) and world == world_container.get_child(0):
				end_return_camera()
				show_return_state()
		, CONNECT_ONE_SHOT)
		world.begin_preparation()
	elif action in ["return_farewell", "return_departure"]:
		# The accepted response and autonomous departure are durable before staging.
		if action == "return_farewell":
			if not model.apply("return_departure"): return
			persist()
		hud.set_chapter(model.snapshot())
		world.apply_state(model.snapshot())
		start_return_camera(false)
		world.departure_finished.connect(func():
			if is_instance_valid(world) and world == world_container.get_child(0):
				end_return_camera()
				# No immediate dialogue covers the empty platform.
		, CONNECT_ONE_SHOT)
		world.begin_departure(snapshot.return_state.farewell, snapshot.camera_choice)
	elif action in ["return_conductor", "return_jo"]:
		show_return_state(action)
	else:
		if world.has_method("apply_state"): world.apply_state(snapshot)
		show_return_state()

func show_home_notice(message: String):
	hud.show_notice(home_save_warning + ("\n" if not home_save_warning.is_empty() and not message.is_empty() else "") + message)

func show_home_state(id: String = ""):
	var snapshot = model.snapshot()
	if snapshot.get("campaign_chapter", "") != "still_here": return
	player.set_controls_enabled(false)
	player.set_framed_view(true)
	hud.show_home_dialogue(snapshot, id)
	if snapshot.get("campaign_complete", false): hud.show_journey_available()
	show_home_notice("")

func home_close_view(ending: bool = false):
	var world = world_container.get_child(0)
	var marker = world.get_node_or_null("HomeView")
	if marker == null: return
	var camera = world.get_node_or_null("HomeCloseCamera")
	if camera == null:
		camera = Camera3D.new()
		camera.name = "HomeCloseCamera"
		world.add_child(camera)
	camera.global_position = marker.global_position
	if marker.has_meta("look_at"): camera.look_at(marker.get_meta("look_at"), Vector3.UP)
	camera.fov = marker.get_meta("fov", 50.0)
	camera.current = true
	if not home_viewing and not home_cinematic:
		for label in world.find_children("*", "Label3D", true, false):
			if label.visible:
				home_labels.append(label)
				label.visible = false
	home_viewing = not ending
	home_cinematic = ending
	if ending:
		home_controls_text = hud.controls.text
		hud.controls.text = "Esc / B · skip presentation     P / Menu · pause"
	hud.close_all()
	player.set_controls_enabled(false)
	player.visual.visible = false
	if world.has_method("set_close_view"): world.set_close_view(true)
	show_home_notice("Esc / B · skip presentation     P / Menu · pause" if ending else "Esc / B · return to the room     P / Menu · pause")

func home_end_view():
	if home_cinematic: hud.controls.text = home_controls_text
	home_viewing = false
	home_cinematic = false
	for label in home_labels:
		if is_instance_valid(label): label.visible = true
	home_labels.clear()
	if is_instance_valid(player):
		player.arm.get_child(0).current = true
		player.visual.visible = true
	if world_container.get_child_count() > 0 and world_container.get_child(0).has_method("apply_state"):
		var world = world_container.get_child(0)
		if world.has_method("set_close_view"): world.set_close_view(false)
		world.apply_state(model.snapshot())
	show_home_notice("")
	resume_controls()

func dispatch_home(action: String, value: Variant = null):
	if busy or quitting: return
	var snapshot = model.snapshot()
	if action != "begin_home" and snapshot.get("campaign_chapter", "") != "still_here": return
	if action == "home_leave":
		if persist(): quit_to_desktop()
		else: show_home_notice("Please keep this window open until the save succeeds.")
		return
	if home_cinematic: return
	if action == "home_leave_view":
		home_end_view()
		return
	if action == "home_view":
		home_close_view()
		return
	if action in ["home_state", "home_exit", "home_credits"]:
		if home_viewing: home_end_view()
		show_home_state()
		return
	if action in ["home_ticket", "home_ritual", "home_end", "home_finish"] and value == null:
		var page = ""
		if action == "home_ticket" and snapshot.home.ticket == "unselected": page = "home_ticket"
		elif action == "home_ritual" and snapshot.home.ticket != "unselected" and snapshot.home.ritual == "unselected": page = "home_ritual"
		show_home_state(page)
		return
	if action == "home_end": action = "home_finish"
	if not model.apply(action, value): return
	persist()
	snapshot = model.snapshot()
	if action == "begin_home":
		paper_courtyard = false
		hud.close_all()
		route()
		show_home_state()
		return
	var world = world_container.get_child(0)
	world.apply_state(snapshot)
	hud.set_chapter(snapshot)
	if action == "home_finish":
		# The exact ending is durable before its quiet physical hold. Reopen never replays it.
		home_close_view(true)
		world.begin_ending(str(value), func():
			if is_instance_valid(world) and world_container.get_child_count() > 0 and world == world_container.get_child(0):
				home_end_view()
				show_home_state()
		)
	else:
		if home_viewing: home_end_view()
		if action == "home_ritual" and value == "window": home_close_view()
		show_home_state()
