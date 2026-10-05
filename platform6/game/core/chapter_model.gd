extends RefCounted
const Rules = preload("res://core/choice_rules.gd")
const SCHEMA_VERSION = 2
const STATES = ["apartment","roof","platform","conductor","passenger","shoreline","overlook","camera_choice","optional_action","return_train","breakfast","complete"]
const STEPS = {"leave_apartment":"apartment","meet_stranger":"roof","read_board":"platform","board_train":"conductor","meet_passenger":"passenger","arrive_shore":"shoreline","reach_overlook":"overlook","choose_camera":"camera_choice","resolve_action":"optional_action","return_train":"return_train","have_breakfast":"breakfast","finish":"complete"}
const LANDMARKS = ["lighthouse","arch","constellation"]
const LEGACY_KEYS = ["schema_version","chapter_id","checkpoint_id","inspected_landmark_ids","overlook_alignment","puzzle_solved","camera_choice","action_resolution","souvenir_ids","chapter_world_flag","chapter_complete","settings"]
const FAIR_STATES = ["locked","arrival","workshop","crooked_race","level_pond","race_ready","result","complete"]
const FAIR_ACTIONS = ["begin_fair","fair_greeting","set_rudder","set_sail","set_race_mode","release_boat","inspect_fair","level_pond","replay_race","fair_departure"]
const PAPER_STATES = ["locked","arrival","workshop","raised","complete"]
const PAPER_TRANSITIONS = {"begin":"arrival","greeting":"workshop","raise":"raised","finish":"complete"}
const PAPER_ACTIONS = ["begin_paper","paper_greeting","set_paper_star","set_paper_layout","set_paper_length","set_paper_mode","set_paper_fold","raise_paper","finish_paper"]
const ORCHARD_STATES = ["locked","arrival","rest","complete"]
const ORCHARD_ACTIONS = ["begin_orchard","orchard_route","orchard_advance","orchard_finish"]
const RETURN_STATES = ["locked","arrival","farewell","departed","complete"]
const RETURN_ACTIONS = ["begin_return","return_arrival","return_farewell","return_departure","return_finish","return_conductor","return_jo"]
const HOME_STATES = ["locked","arrival","settled","complete"]
const HOME_ACTIONS = ["begin_home","home_ticket","home_ritual","home_finish"]
const HOME_OPTIONS = {"ticket":["kettle","drawer","pocket"],"ritual":["tea","window","neither"],"ending":["train","sleep"]}
const CAMPAIGN_CHAPTERS = ["platform_six","the_small_fair","paper_sky","night_kitchen","quiet_orchard","return_platform","still_here"]
const RETURN_FAREWELLS = ["luck","joke","thanks","wave","little"]
const KITCHEN_STATES = ["locked","arrival","supper","conversation","complete"]
const KITCHEN_ACTIONS = ["begin_kitchen","kitchen_join","kitchen_share","kitchen_departure"]
const KITCHEN_OPTIONS = {"mode":["sit","help","watch"],"exchange":["bread","cup","pepper","watch"],"departure":["ask","wish","listen"]}
const PAPER_OPTIONS = {"star":["crooked","clean","empty"],"layout":["leaf_boat_star","boat_star_leaf","star_leaf_boat","leaf_star_boat","boat_leaf_star","star_boat_leaf"],"length":["short","medium","long"],"mode":["assemble","direct","watch"],"fold":["keep","wider","enough"]}
var rules = Rules.new()
var data: Dictionary
func _init():
	data = defaults()
func fair_defaults() -> Dictionary:
	return {"rudder":"straight","sail":"triangle","mode":"operate","levelled":false,"race_count":0,"outcome":"unselected","inspected":[],"greeting":"unselected","leveller":"unselected","departure":"unselected","replay_count":0,"souvenir_ids":[]}
func paper_defaults() -> Dictionary:
	return {"star":"crooked","layout":"leaf_boat_star","length":"medium","mode":"assemble","fold":"keep","completed":false}
func kitchen_defaults() -> Dictionary:
	return {"mode":"unselected","served":false,"exchange":"unselected","departure":"unselected","completed":false}
func orchard_defaults() -> Dictionary:
	return {"route":"unselected","beat":0,"completed":false}
func return_defaults() -> Dictionary:
	return {"farewell":"unselected","conductor_revealed":false,"jo_met":false,"completed":false}
func home_defaults() -> Dictionary:
	return {"ticket":"unselected","ritual":"unselected","ending":"unselected","completed":false}
func defaults() -> Dictionary:
	return {"schema_version":SCHEMA_VERSION,"chapter_id":"platform_six","checkpoint_id":"apartment","inspected_landmark_ids":[],"overlook_alignment":0,"puzzle_solved":false,"camera_choice":"unselected","action_resolution":"unselected","souvenir_ids":[],"chapter_world_flag":false,"chapter_complete":false,"settings":{"text_scale":1.0,"subtitles":true,"reduced_motion":false,"sensitivity":1.0,"master":0.8,"music":0.65,"effects":0.6,"graphics":"medium"},"campaign_chapter":"platform_six","fair_checkpoint":"locked","fair":fair_defaults(),"paper_checkpoint":"locked","paper":paper_defaults(),"kitchen_checkpoint":"locked","kitchen":kitchen_defaults(),"orchard_checkpoint":"locked","orchard":orchard_defaults(),"return_checkpoint":"locked","return_state":return_defaults(),"home_checkpoint":"locked","home":home_defaults(),"campaign_complete":false,"history_compatibility":[],"choice_history":[],"dimensions":rules.neutral_dimensions(),"npc_state":rules.neutral_npcs()}
func snapshot() -> Dictionary:
	return data.duplicate(true)
func validate_choice_catalog(catalog: Variant) -> bool:
	return rules.validate_catalog(catalog)
func record_choice(choice_id: String) -> bool:
	# Presentation-only local replies may be recorded independently of actions.
	if not choice_id.begins_with("platform_six.dialogue."): return false
	var before = snapshot()
	if not rules.apply_choice(choice_id, data) or not valid_v2(data):
		data = before
		return false
	return true
func _record_action_choice(choice_id: String) -> bool:
	return rules.apply_choice(choice_id, data)
func apply(action: String, value: Variant = null) -> bool:
	var before = snapshot()
	if not _apply_action(action, value) or not valid_v2(data):
		data = before
		return false
	return true
func _apply_action(action: String, value: Variant = null) -> bool:
	if action == "settings":
		var candidate = snapshot()
		candidate.settings = value
		return restore(candidate)
	if action in FAIR_ACTIONS: return apply_fair(action, value)
	if action in PAPER_ACTIONS: return apply_paper(action, value)
	if action in ORCHARD_ACTIONS: return apply_orchard(action, value)
	if action in KITCHEN_ACTIONS: return apply_kitchen(action, value)
	if action in RETURN_ACTIONS: return apply_return(action, value)
	if action in HOME_ACTIONS: return apply_home(action, value)
	if data.campaign_chapter != "platform_six": return false
	var state: String = data.checkpoint_id
	if action in ["inspect_landmark","preview_alignment","align","assist"]:
		if state != "overlook": return false
		if action == "inspect_landmark":
			if value not in LANDMARKS or value in data.inspected_landmark_ids: return false
			data.inspected_landmark_ids.append(value)
		elif action in ["preview_alignment", "align"]:
			if typeof(value) != TYPE_INT or value < 0 or value > 2: return false
			data.overlook_alignment = value
			if action == "align" and value == 2 and data.inspected_landmark_ids.size() == 3:
				data.puzzle_solved = true
				data.checkpoint_id = "camera_choice"
		else:
			data.puzzle_solved = true
			data.overlook_alignment = 2
			data.checkpoint_id = "camera_choice"
		return true
	if not STEPS.has(action) or STEPS[action] != state: return false
	if action == "reach_overlook": return false # the legacy puzzle owns departure
	if action == "choose_camera":
		if value not in ["take","lend","unused"]: return false
		if not _record_action_choice("platform_six.camera." + value): return false
		data.camera_choice = value
	if action == "resolve_action":
		if value not in ["completed","skipped"]: return false
		# Both controls have exactly the same durable fictional consequences.
		if not _record_action_choice("platform_six.optional.continue"): return false
		data.action_resolution = value
	if action == "finish":
		if data.chapter_complete: return false
		if not _record_action_choice("platform_six.finish"): return false
		data.chapter_complete = true
		data.chapter_world_flag = true
		data.souvenir_ids = ["platform_six_journey"]
	else:
		data.checkpoint_id = STATES[STATES.find(state) + 1]
	return true
func apply_fair(action: String, value: Variant) -> bool:
	var state: String = data.fair_checkpoint
	if action == "begin_fair":
		if not data.chapter_complete or state != "locked": return false
		data.campaign_chapter = "the_small_fair"
		data.fair_checkpoint = "arrival"
		if not _record_action_choice("the_small_fair.begin"): return false
		return true
	if data.campaign_chapter != "the_small_fair": return false
	if action == "fair_greeting":
		if state != "arrival" or value not in ["ducks","watch","how"]: return false
		if not _record_action_choice("the_small_fair.greeting." + value): return false
		data.fair.greeting = value
		data.fair_checkpoint = "workshop"
		return true
	if action in ["set_rudder","set_sail","set_race_mode"]:
		if state not in ["workshop","race_ready"]: return false
		var field = {"set_rudder":"rudder","set_sail":"sail","set_race_mode":"mode"}[action]
		var allowed = {"rudder":["left","straight","right"],"sail":["triangle","square","folded"],"mode":["operate","watch","cooperate"]}[field]
		if value not in allowed: return false
		var id = "the_small_fair." + field + "." + value
		if data.fair[field] == value and id in data.choice_history: return false
		if id not in data.choice_history and not _record_action_choice(id): return false
		data.fair[field] = value
		return true
	if action == "release_boat":
		if state == "workshop":
			if not _record_action_choice("the_small_fair.race.crooked"): return false
			data.fair.race_count = 1
			data.fair_checkpoint = "crooked_race"
			return true
		if state != "race_ready": return false
		if not _record_action_choice("the_small_fair.race.canonical"): return false
		data.fair.outcome = race_outcome(data.fair)
		data.fair.souvenir_ids = ["fair_button"]
		data.fair.race_count = 2
		data.fair_checkpoint = "result"
		return true
	if action == "inspect_fair":
		if state not in ["crooked_race","level_pond"] or value not in ["boat","wedge","together","watch"] or value in data.fair.inspected: return false
		if not _record_action_choice("the_small_fair.inspect." + value): return false
		data.fair.inspected.append(value)
		# Watching is a complete route: Ada finds the support herself.
		if value in ["together","watch"] and "wedge" not in data.fair.inspected: data.fair.inspected.append("wedge")
		data.fair_checkpoint = "level_pond"
		return true
	if action == "level_pond":
		if state != "level_pond" or value not in ["self","ada"]: return false
		if not _record_action_choice("the_small_fair.level." + value): return false
		data.fair.levelled = true
		data.fair.leveller = value
		data.fair_checkpoint = "race_ready"
		return true
	if action == "replay_race":
		if state not in ["result","complete"]: return false
		# A replay is presentation, never another canonical choice or reward.
		data.fair.replay_count = mini(data.fair.replay_count + 1, 1000000)
		return true
	if action == "fair_departure":
		if state != "result" or value not in ["card","speak","wait"]: return false
		if not _record_action_choice("the_small_fair.departure." + value): return false
		data.fair.departure = value
		data.fair_checkpoint = "complete"
		return true
	return false
func apply_paper(action: String, value: Variant) -> bool:
	var state: String = data.paper_checkpoint
	if action == "begin_paper":
		if data.campaign_chapter != "the_small_fair" or data.fair_checkpoint != "complete" or state != "locked": return false
		data.campaign_chapter = "paper_sky"
		data.paper_checkpoint = "arrival"
		return _record_action_choice("paper_sky.begin")
	if data.campaign_chapter != "paper_sky": return false
	if action == "paper_greeting":
		if state != "arrival" or not _record_action_choice("paper_sky.greeting"): return false
		data.paper_checkpoint = "workshop"
		return true
	if action.begins_with("set_paper_"):
		if state != "workshop": return false
		var field = action.trim_prefix("set_paper_")
		if not PAPER_OPTIONS.has(field) or value not in PAPER_OPTIONS[field]: return false
		var id = "paper_sky." + field + "." + value
		if data.paper[field] == value and id in data.choice_history: return false
		if id not in data.choice_history and not _record_action_choice(id): return false
		data.paper[field] = value
		return true
	if action == "raise_paper":
		if state != "workshop" or not _record_action_choice("paper_sky.raise"): return false
		data.paper_checkpoint = "raised"
		return true
	if action == "finish_paper":
		if state != "raised" or not _record_action_choice("paper_sky.finish"): return false
		data.paper_checkpoint = "complete"
		data.paper.completed = true
		return true
	return false
func apply_kitchen(action: String, value: Variant) -> bool:
	var state: String = data.kitchen_checkpoint
	if action == "begin_kitchen":
		if data.campaign_chapter != "paper_sky" or data.paper_checkpoint != "complete" or state != "locked": return false
		data.campaign_chapter = "night_kitchen"
		data.kitchen_checkpoint = "arrival"
		return _record_action_choice("night_kitchen.begin")
	if data.campaign_chapter != "night_kitchen": return false
	if action == "kitchen_join":
		if state != "arrival" or value not in KITCHEN_OPTIONS.mode: return false
		if not _record_action_choice("night_kitchen.mode." + value): return false
		data.kitchen.mode = value
		# The place is already set. Sitting, helping and watching receive supper equally.
		data.kitchen.served = true
		data.kitchen_checkpoint = "supper"
		return true
	if action == "kitchen_share":
		if state != "supper" or value not in KITCHEN_OPTIONS.exchange: return false
		if not _record_action_choice("night_kitchen.exchange." + value): return false
		data.kitchen.exchange = value
		data.kitchen_checkpoint = "conversation"
		return true
	if action == "kitchen_departure":
		if state != "conversation" or value not in KITCHEN_OPTIONS.departure: return false
		if not _record_action_choice("night_kitchen.departure." + value): return false
		data.kitchen.departure = value
		data.kitchen.completed = true
		data.kitchen_checkpoint = "complete"
		return true
	return false
func apply_orchard(action: String, value: Variant) -> bool:
	var state: String = data.orchard_checkpoint
	if action != "orchard_route" and value != null: return false
	if action == "begin_orchard":
		if data.campaign_chapter != "night_kitchen" or data.kitchen_checkpoint != "complete" or state != "locked": return false
		data.campaign_chapter = "quiet_orchard"
		data.orchard_checkpoint = "arrival"
		return _record_action_choice("quiet_orchard.begin")
	if data.campaign_chapter != "quiet_orchard": return false
	if action == "orchard_route":
		if state != "arrival" or value not in ["cart","walk","bench"]: return false
		if not _record_action_choice("quiet_orchard.route." + value): return false
		data.orchard.route = value
		data.orchard_checkpoint = "rest"
		return true
	if action == "orchard_advance":
		if state != "rest" or data.orchard.beat >= 3: return false
		if not _record_action_choice("quiet_orchard.beat." + str(int(data.orchard.beat) + 1)): return false
		data.orchard.beat += 1
		return true
	if action == "orchard_finish":
		if state != "rest" or data.orchard.beat != 3: return false
		if not _record_action_choice("quiet_orchard.finish"): return false
		data.orchard.completed = true
		data.orchard_checkpoint = "complete"
		return true
	return false
func apply_return(action: String, value: Variant) -> bool:
	if action != "return_farewell" and value != null: return false
	var state: String = data.return_checkpoint
	if action == "begin_return":
		if data.campaign_chapter != "quiet_orchard" or data.orchard_checkpoint != "complete" or state != "locked": return false
		data.campaign_chapter = "return_platform"
		data.return_checkpoint = "arrival"
		return _record_action_choice("return_platform.begin")
	if data.campaign_chapter != "return_platform": return false
	if action in ["return_conductor","return_jo"]:
		if state not in ["arrival","farewell","departed","complete"]: return false
		var field = "conductor_revealed" if action == "return_conductor" else "jo_met"
		if data.return_state[field] or not _record_action_choice("return_platform." + action.trim_prefix("return_")): return false
		data.return_state[field] = true
		return true
	if action == "return_arrival":
		if state != "arrival" or not _record_action_choice("return_platform.arrival"): return false
		data.return_checkpoint = "farewell"
		return true
	if action == "return_farewell":
		if state != "farewell" or data.return_state.farewell != "unselected" or value not in RETURN_FAREWELLS: return false
		if not _record_action_choice("return_platform.farewell." + value): return false
		data.return_state.farewell = value
		return true
	if action == "return_departure":
		if state != "farewell" or data.return_state.farewell == "unselected" or not _record_action_choice("return_platform.departure"): return false
		# Mira's established Lower Mill plan is unchanged by the player's reply.
		data.return_checkpoint = "departed"
		return true
	if action == "return_finish":
		if state != "departed" or not _record_action_choice("return_platform.finish"): return false
		data.return_checkpoint = "complete"
		data.return_state.completed = true
		return true
	return false
func apply_home(action: String, value: Variant) -> bool:
	if action == "begin_home":
		if value != null or data.campaign_chapter != "return_platform" or data.return_checkpoint != "complete" or not data.return_state.completed or data.home_checkpoint != "locked": return false
		data.campaign_chapter = "still_here"
		data.home_checkpoint = "arrival"
		return _record_action_choice("still_here.begin")
	if data.campaign_chapter != "still_here": return false
	var state: String = data.home_checkpoint
	if action == "home_ticket":
		if state != "arrival" or data.home.ticket != "unselected" or value not in HOME_OPTIONS.ticket: return false
		if not _record_action_choice("still_here.ticket." + value): return false
		data.home.ticket = value
		return true
	if action == "home_ritual":
		if state != "arrival" or data.home.ticket == "unselected" or value not in HOME_OPTIONS.ritual: return false
		if not _record_action_choice("still_here.ritual." + value): return false
		data.home.ritual = value
		data.home_checkpoint = "settled"
		return true
	if action == "home_finish":
		if state != "settled" or value not in HOME_OPTIONS.ending: return false
		if not _record_action_choice("still_here.finish." + value): return false
		# Both authored final choices close the campaign without a rank or reward.
		data.home.ending = value
		data.home.completed = true
		data.home_checkpoint = "complete"
		data.campaign_complete = true
		return true
	return false
func race_outcome(config: Dictionary) -> String:
	if config.mode == "watch": return "spectator"
	if config.mode == "cooperate": return "second"
	if config.sail == "folded": return "circle"
	if config.rudder == "left": return "third"
	if config.rudder == "right" or config.sail == "square": return "second"
	return "first"
func migrated(candidate: Dictionary) -> Dictionary:
	if not valid_legacy(candidate): return {}
	var migrated_data = defaults()
	for key in LEGACY_KEYS: migrated_data[key] = candidate[key]
	migrated_data.schema_version = SCHEMA_VERSION
	# Explicit legacy choice only. Unknown story/relationship history stays neutral.
	migrated_data.npc_state.mira.camera_memory = candidate.camera_choice
	if candidate.camera_choice != "unselected": migrated_data.choice_history.append("platform_six.camera." + candidate.camera_choice)
	migrated_data.history_compatibility = compatibility_missing(migrated_data)
	return migrated_data.duplicate(true)
func restore(candidate: Dictionary) -> bool:
	if not rules.numeric(candidate.get("schema_version")): return false
	if candidate.has("campaign_chapter") and typeof(candidate.campaign_chapter) != TYPE_STRING: return false
	if candidate.get("campaign_chapter") == "still_here":
		for key in ["home_checkpoint","home","campaign_complete","history_compatibility","return_checkpoint","return_state","orchard_checkpoint","orchard","kitchen_checkpoint","kitchen","paper_checkpoint","paper"]:
			if not candidate.has(key): return false
	if candidate.get("schema_version") == SCHEMA_VERSION and candidate.get("campaign_chapter") == "night_kitchen" and (not candidate.has("kitchen_checkpoint") or not candidate.has("kitchen")): return false
	if candidate.get("campaign_chapter") == "quiet_orchard" and (not candidate.has("orchard_checkpoint") or not candidate.has("orchard")): return false
	if candidate.get("campaign_chapter") == "return_platform":
		for key in ["return_checkpoint","return_state","orchard_checkpoint","orchard","kitchen_checkpoint","kitchen","paper_checkpoint","paper"]:
			if not candidate.has(key): return false
	var normalized = migrated(candidate) if candidate.get("schema_version") == 1 else candidate.duplicate(true)
	# Earlier schema 2 files predate the optional conservatory and supper states.
	if not normalized.has("paper_checkpoint"): normalized.paper_checkpoint = "locked"
	if not normalized.has("paper"): normalized.paper = paper_defaults()
	if not normalized.has("kitchen_checkpoint"): normalized.kitchen_checkpoint = "locked"
	if not normalized.has("kitchen"): normalized.kitchen = kitchen_defaults()
	if not normalized.has("orchard_checkpoint"): normalized.orchard_checkpoint = "locked"
	if not normalized.has("orchard"): normalized.orchard = orchard_defaults()
	if not normalized.has("return_checkpoint"): normalized.return_checkpoint = "locked"
	if not normalized.has("return_state"): normalized.return_state = return_defaults()
	if not normalized.has("home_checkpoint"): normalized.home_checkpoint = "locked"
	if not normalized.has("home"): normalized.home = home_defaults()
	if not normalized.has("campaign_complete"): normalized.campaign_complete = false
	if not normalized.has("history_compatibility"): normalized.history_compatibility = compatibility_missing(normalized)
	if not valid_v2(normalized): return false
	data = {}
	for key in defaults(): data[key] = normalized[key]
	data = data.duplicate(true)
	data.schema_version = SCHEMA_VERSION
	data.overlook_alignment = int(data.overlook_alignment)
	data.orchard.beat = int(data.orchard.beat)
	data.fair.race_count = int(data.fair.race_count)
	data.fair.replay_count = int(data.fair.replay_count)
	for dimension in data.dimensions: data.dimensions[dimension] = float(data.dimensions[dimension])
	for npc in data.npc_state: data.npc_state[npc].connection = float(data.npc_state[npc].connection)
	for setting in ["text_scale","sensitivity","master","music","effects"]: data.settings[setting] = float(data.settings[setting])
	return true
func valid(candidate: Dictionary) -> bool:
	if not rules.numeric(candidate.get("schema_version")): return false
	if candidate.get("schema_version") == 1: return valid_legacy(candidate)
	return valid_v2(candidate)
func integer(value: Variant, low: int, high: int) -> bool:
	return rules.numeric(value) and value >= low and value <= high and value == int(value)
func valid_legacy(c: Dictionary) -> bool:
	for key in LEGACY_KEYS:
		if not c.has(key): return false
	if not rules.numeric(c.schema_version) or (c.schema_version != 1 and c.schema_version != SCHEMA_VERSION) or typeof(c.chapter_id) != TYPE_STRING or c.chapter_id != "platform_six" or c.checkpoint_id not in STATES: return false
	for key in ["puzzle_solved","chapter_world_flag","chapter_complete"]:
		if typeof(c[key]) != TYPE_BOOL: return false
	if typeof(c.inspected_landmark_ids) != TYPE_ARRAY or typeof(c.souvenir_ids) != TYPE_ARRAY: return false
	var seen = []
	for id in c.inspected_landmark_ids:
		if id not in LANDMARKS or id in seen: return false
		seen.append(id)
	if c.souvenir_ids != [] and c.souvenir_ids != ["platform_six_journey"]: return false
	if not integer(c.overlook_alignment,0,2): return false
	if c.camera_choice not in ["unselected","take","lend","unused"] or c.action_resolution not in ["unselected","completed","skipped"]: return false
	if typeof(c.settings) != TYPE_DICTIONARY: return false
	for key in defaults().settings:
		if not c.settings.has(key): return false
	for key in ["text_scale","sensitivity","master","music","effects"]:
		var lo = 0.0 if key in ["master","music","effects"] else 0.5
		var hi = 1.0 if key in ["master","music","effects"] else 2.0
		if not rules.numeric(c.settings[key]) or c.settings[key] < lo or c.settings[key] > hi: return false
	for key in ["subtitles","reduced_motion"]:
		if typeof(c.settings[key]) != TYPE_BOOL: return false
	if c.settings.graphics not in ["low","medium","high"]: return false
	var index = STATES.find(c.checkpoint_id)
	if c.chapter_complete != c.chapter_world_flag: return false
	if c.chapter_complete and (c.checkpoint_id != "complete" or c.souvenir_ids != ["platform_six_journey"]): return false
	if not c.chapter_complete and not c.souvenir_ids.is_empty(): return false
	if c.puzzle_solved != (index >= STATES.find("camera_choice")): return false
	if (c.camera_choice != "unselected") != (index >= STATES.find("optional_action")): return false
	if (c.action_resolution != "unselected") != (index >= STATES.find("return_train")): return false
	return true
func valid_history_context(c: Dictionary) -> bool:
	var legacy_index = STATES.find(c.checkpoint_id)
	var fair_index = FAIR_STATES.find(c.fair_checkpoint)
	for id in c.choice_history:
		if id.begins_with("platform_six.camera."):
			if id != "platform_six.camera." + c.camera_choice or c.camera_choice == "unselected": return false
		elif id == "platform_six.optional.continue":
			if legacy_index < STATES.find("return_train"): return false
		elif id == "platform_six.finish":
			if not c.chapter_complete: return false
		elif id.begins_with("platform_six.dialogue."):
			var choice = rules.choices[id]
			if legacy_index < STATES.find(choice.checkpoints[0]): return false
		elif id.begins_with("paper_sky."):
			if c.campaign_chapter not in ["paper_sky","night_kitchen","quiet_orchard","return_platform","still_here"]: return false
			var paper_index = PAPER_STATES.find(c.paper_checkpoint)
			var first_checkpoint = rules.choices[id].checkpoints[0]
			if paper_index < PAPER_STATES.find(first_checkpoint): return false
		elif id.begins_with("night_kitchen."):
			if c.campaign_chapter not in ["night_kitchen","quiet_orchard","return_platform","still_here"]: return false
			var kitchen_index = KITCHEN_STATES.find(c.kitchen_checkpoint)
			if id == "night_kitchen.begin":
				if kitchen_index < KITCHEN_STATES.find("arrival"): return false
			else:
				var parts = id.split(".")
				var field = parts[1]
				var reached = {"mode":"supper","exchange":"conversation","departure":"complete"}[field]
				if kitchen_index < KITCHEN_STATES.find(reached) or parts[2] != c.kitchen[field]: return false
		elif id.begins_with("quiet_orchard."):
			if c.campaign_chapter not in ["quiet_orchard","return_platform","still_here"]: return false
		elif id.begins_with("return_platform."):
			if c.campaign_chapter not in ["return_platform","still_here"]: return false
		elif id.begins_with("still_here."):
			if c.campaign_chapter != "still_here": return false
		else:
			if c.campaign_chapter not in ["the_small_fair","paper_sky","night_kitchen","quiet_orchard","return_platform","still_here"] or fair_index < FAIR_STATES.find("arrival"): return false
			if id.begins_with("the_small_fair.greeting."):
				if fair_index < FAIR_STATES.find("workshop") or id != "the_small_fair.greeting." + c.fair.greeting: return false
			elif id.begins_with("the_small_fair.rudder.") or id.begins_with("the_small_fair.sail.") or id.begins_with("the_small_fair.mode."):
				if fair_index < FAIR_STATES.find("workshop"): return false
			elif id == "the_small_fair.race.crooked":
				if fair_index < FAIR_STATES.find("crooked_race"): return false
			elif id == "the_small_fair.race.canonical":
				if fair_index < FAIR_STATES.find("result"): return false
			elif id.begins_with("the_small_fair.inspect."):
				if fair_index < FAIR_STATES.find("level_pond") or id.trim_prefix("the_small_fair.inspect.") not in c.fair.inspected: return false
			elif id.begins_with("the_small_fair.level."):
				if fair_index < FAIR_STATES.find("race_ready") or id != "the_small_fair.level." + c.fair.leveller: return false
			elif id.begins_with("the_small_fair.departure."):
				if fair_index < FAIR_STATES.find("complete") or id != "the_small_fair.departure." + c.fair.departure: return false
	return true
func valid_paper(c: Dictionary) -> bool:
	if c.paper_checkpoint not in PAPER_STATES or typeof(c.paper) != TYPE_DICTIONARY or c.paper.size() != paper_defaults().size(): return false
	for field in paper_defaults():
		if not c.paper.has(field): return false
	for field in PAPER_OPTIONS:
		if c.paper[field] not in PAPER_OPTIONS[field]: return false
	if typeof(c.paper.completed) != TYPE_BOOL or c.paper.completed != (c.paper_checkpoint == "complete"): return false
	if c.paper_checkpoint == "locked":
		return c.campaign_chapter != "paper_sky" and c.paper == paper_defaults()
	if c.campaign_chapter not in ["paper_sky","night_kitchen","quiet_orchard","return_platform","still_here"] or c.fair_checkpoint != "complete": return false
	if c.campaign_chapter in ["night_kitchen","quiet_orchard","return_platform","still_here"] and c.paper_checkpoint != "complete": return false
	var index = PAPER_STATES.find(c.paper_checkpoint)
	# Paper did not exist in old saves; each active checkpoint has its own trace.
	for transition in PAPER_TRANSITIONS:
		var reached = index >= PAPER_STATES.find(PAPER_TRANSITIONS[transition])
		if ("paper_sky." + transition in c.choice_history) != reached: return false
	if c.paper_checkpoint == "arrival" and c.paper != paper_defaults(): return false
	for field in PAPER_OPTIONS:
		if c.paper[field] != paper_defaults()[field] and "paper_sky." + field + "." + c.paper[field] not in c.choice_history: return false
	return true
func valid_kitchen(c: Dictionary) -> bool:
	if c.kitchen_checkpoint not in KITCHEN_STATES or typeof(c.kitchen) != TYPE_DICTIONARY or c.kitchen.size() != kitchen_defaults().size(): return false
	for field in kitchen_defaults():
		if not c.kitchen.has(field): return false
	for field in KITCHEN_OPTIONS:
		if typeof(c.kitchen[field]) != TYPE_STRING or (c.kitchen[field] != "unselected" and c.kitchen[field] not in KITCHEN_OPTIONS[field]): return false
	for field in ["served","completed"]:
		if typeof(c.kitchen[field]) != TYPE_BOOL: return false
	if c.kitchen_checkpoint == "locked":
		return c.campaign_chapter != "night_kitchen" and c.kitchen == kitchen_defaults()
	if c.campaign_chapter not in ["night_kitchen","quiet_orchard","return_platform","still_here"] or c.paper_checkpoint != "complete": return false
	if c.campaign_chapter in ["quiet_orchard","return_platform","still_here"] and c.kitchen_checkpoint != "complete": return false
	var index = KITCHEN_STATES.find(c.kitchen_checkpoint)
	var expected_history = ["night_kitchen.begin"]
	for field in KITCHEN_OPTIONS:
		var reached = index >= KITCHEN_STATES.find({"mode":"supper","exchange":"conversation","departure":"complete"}[field])
		if (c.kitchen[field] != "unselected") != reached: return false
		if reached: expected_history.append("night_kitchen." + field + "." + c.kitchen[field])
	var kitchen_history = []
	for id in c.choice_history:
		if id.begins_with("night_kitchen."): kitchen_history.append(id)
	if kitchen_history != expected_history: return false
	if c.kitchen.served != (index >= KITCHEN_STATES.find("supper")): return false
	if c.kitchen.completed != (c.kitchen_checkpoint == "complete"): return false
	return true
func valid_orchard(c: Dictionary) -> bool:
	if c.orchard_checkpoint not in ORCHARD_STATES or typeof(c.orchard) != TYPE_DICTIONARY or c.orchard.size() != 3: return false
	for field in orchard_defaults():
		if not c.orchard.has(field): return false
	var o: Dictionary = c.orchard
	if o.route not in ["unselected","cart","walk","bench"] or not integer(o.beat,0,3) or typeof(o.completed) != TYPE_BOOL: return false
	if c.orchard_checkpoint == "locked": return c.campaign_chapter != "quiet_orchard" and o.route == "unselected" and o.beat == 0 and not o.completed
	if c.campaign_chapter not in ["quiet_orchard","return_platform","still_here"] or c.kitchen_checkpoint != "complete": return false
	if c.campaign_chapter in ["return_platform","still_here"] and c.orchard_checkpoint != "complete": return false
	var resting = c.orchard_checkpoint in ["rest","complete"]
	if (o.route != "unselected") != resting or o.completed != (c.orchard_checkpoint == "complete"): return false
	if not resting and o.beat != 0: return false
	if o.completed and o.beat != 3: return false
	var expected = ["quiet_orchard.begin"]
	if resting: expected.append("quiet_orchard.route." + o.route)
	for beat in range(1,int(o.beat)+1): expected.append("quiet_orchard.beat." + str(beat))
	if o.completed: expected.append("quiet_orchard.finish")
	var history = []
	for id in c.choice_history:
		if id.begins_with("quiet_orchard."): history.append(id)
	# Orchard remains the final prior-chapter trace once the return has begun.
	var prior_history = []
	for id in c.choice_history:
		if not id.begins_with("return_platform.") and not id.begins_with("still_here."): prior_history.append(id)
	return history == expected and prior_history.slice(prior_history.size() - expected.size()) == expected
func valid_return(c: Dictionary) -> bool:
	if c.return_checkpoint not in RETURN_STATES or typeof(c.return_state) != TYPE_DICTIONARY or c.return_state.size() != return_defaults().size(): return false
	for field in return_defaults():
		if not c.return_state.has(field): return false
	var r: Dictionary = c.return_state
	if typeof(r.farewell) != TYPE_STRING or (r.farewell != "unselected" and r.farewell not in RETURN_FAREWELLS): return false
	for field in ["conductor_revealed","jo_met","completed"]:
		if typeof(r[field]) != TYPE_BOOL: return false
	var history = []
	for id in c.choice_history:
		if id.begins_with("return_platform."): history.append(id)
	if c.return_checkpoint == "locked":
		return c.campaign_chapter not in ["return_platform","still_here"] and r == return_defaults() and history.is_empty()
	if c.campaign_chapter not in ["return_platform","still_here"] or c.orchard_checkpoint != "complete": return false
	if c.campaign_chapter == "still_here" and c.return_checkpoint != "complete": return false
	var prior_history = []
	for id in c.choice_history:
		if not id.begins_with("still_here."): prior_history.append(id)
	if history.is_empty() or prior_history.slice(prior_history.size() - history.size()) != history: return false
	var chapter_order = CAMPAIGN_CHAPTERS
	var previous_chapter = 0
	for id in c.choice_history:
		var chapter = chapter_order.find(rules.choices[id].campaign_chapter)
		if chapter < previous_chapter: return false
		previous_chapter = chapter
	# Replay the authored trace to reject future, missing and reordered transitions.
	# Optional conversations can be visited on either side of Mira's departure.
	var phase = "locked"
	var farewell = "unselected"
	var conductor = false
	var jo = false
	for id in history:
		if id == "return_platform.begin":
			if phase != "locked": return false
			phase = "arrival"
		elif id == "return_platform.arrival":
			if phase != "arrival": return false
			phase = "farewell"
		elif id.begins_with("return_platform.farewell."):
			if phase != "farewell" or farewell != "unselected": return false
			farewell = id.trim_prefix("return_platform.farewell.")
			if farewell not in RETURN_FAREWELLS: return false
		elif id == "return_platform.departure":
			if phase != "farewell" or farewell == "unselected": return false
			phase = "departed"
		elif id == "return_platform.finish":
			if phase != "departed": return false
			phase = "complete"
		elif id == "return_platform.conductor":
			if phase not in ["arrival","farewell","departed","complete"] or conductor: return false
			conductor = true
		elif id == "return_platform.jo":
			if phase not in ["arrival","farewell","departed","complete"] or jo: return false
			jo = true
		else: return false
	return phase == c.return_checkpoint and farewell == r.farewell and conductor == r.conductor_revealed and jo == r.jo_met and r.completed == (phase == "complete")
func compatibility_prerequisites(c: Dictionary) -> Array:
	# Older formats did not retain every authored trace. Only already-reached
	# Chapter One/Fair facts may be grandfathered when those files are loaded.
	var expected = []
	var legacy_index = STATES.find(c.get("checkpoint_id"))
	if legacy_index >= STATES.find("optional_action"):
		expected.append("platform_six.camera." + str(c.get("camera_choice")))
	if legacy_index >= STATES.find("return_train"): expected.append("platform_six.optional.continue")
	if typeof(c.get("chapter_complete")) == TYPE_BOOL and c.chapter_complete: expected.append("platform_six.finish")
	var fair_index = FAIR_STATES.find(c.get("fair_checkpoint"))
	if fair_index < FAIR_STATES.find("arrival") or typeof(c.get("fair")) != TYPE_DICTIONARY: return expected
	var f: Dictionary = c.fair
	expected.append("the_small_fair.begin")
	if fair_index >= FAIR_STATES.find("workshop"):
		expected.append("the_small_fair.greeting." + str(f.get("greeting")))
		for field in ["rudder","sail","mode"]:
			if typeof(f.get(field)) == TYPE_STRING and f[field] != fair_defaults()[field]: expected.append("the_small_fair." + field + "." + f[field])
	if fair_index >= FAIR_STATES.find("crooked_race"): expected.append("the_small_fair.race.crooked")
	if fair_index >= FAIR_STATES.find("level_pond") and typeof(f.get("inspected")) == TYPE_ARRAY:
		for id in f.inspected:
			if typeof(id) != TYPE_STRING: continue
			if id == "wedge" and ("watch" in f.inspected or "together" in f.inspected): continue
			expected.append("the_small_fair.inspect." + str(id))
	if fair_index >= FAIR_STATES.find("race_ready"): expected.append("the_small_fair.level." + str(f.get("leveller")))
	if fair_index >= FAIR_STATES.find("result"): expected.append("the_small_fair.race.canonical")
	if fair_index >= FAIR_STATES.find("complete"): expected.append("the_small_fair.departure." + str(f.get("departure")))
	return expected
func compatibility_missing(c: Dictionary) -> Array:
	var missing = []
	if typeof(c.get("choice_history")) != TYPE_ARRAY: return missing
	for id in compatibility_prerequisites(c):
		if id not in c.choice_history: missing.append(id)
	return missing
func valid_history_compatibility(c: Dictionary) -> bool:
	if typeof(c.history_compatibility) != TYPE_ARRAY or c.history_compatibility.size() > 32: return false
	var allowed = compatibility_prerequisites(c)
	# An old unrecorded workshop setting can later be changed legitimately.
	if FAIR_STATES.find(c.fair_checkpoint) >= FAIR_STATES.find("workshop"):
		for id in rules.choices:
			if id.begins_with("the_small_fair.rudder.") or id.begins_with("the_small_fair.sail.") or id.begins_with("the_small_fair.mode."): allowed.append(id)
	var seen = []
	for id in c.history_compatibility:
		if typeof(id) != TYPE_STRING or id not in allowed or id in seen or id in c.choice_history: return false
		seen.append(id)
	return true
func compatible_fair_phase(c: Dictionary, phase: int, target: int) -> int:
	var transitions = {0:"the_small_fair.begin",1:"the_small_fair.greeting." + c.fair.greeting,2:"the_small_fair.race.crooked",4:"the_small_fair.level." + c.fair.leveller,5:"the_small_fair.race.canonical",6:"the_small_fair.departure." + c.fair.departure}
	while phase < target:
		if phase == 3:
			var skipped_inspection = false
			for id in c.history_compatibility:
				if id.begins_with("the_small_fair.inspect."): skipped_inspection = true
			if not skipped_inspection: return -1
		elif transitions.get(phase,"") not in c.history_compatibility: return -1
		phase += 1
	return phase
func valid_home_prior_history(c: Dictionary) -> bool:
	for id in compatibility_prerequisites(c):
		if id not in c.choice_history and id not in c.history_compatibility: return false
	var legacy_phase = -1
	var fair_phase = 0
	var paper_phase = "locked"
	for id in c.choice_history:
		if id.begins_with("platform_six."):
			var reached = STATES.find(rules.choices[id].checkpoints[0])
			if reached < legacy_phase: return false
			legacy_phase = reached
		elif id.begins_with("the_small_fair."):
			if id.begins_with("the_small_fair.rudder.") or id.begins_with("the_small_fair.sail.") or id.begins_with("the_small_fair.mode."):
				if fair_phase not in [2,5]:
					fair_phase = compatible_fair_phase(c,fair_phase,2 if fair_phase < 2 else 5)
				if fair_phase not in [2,5]: return false
				continue
			var required_phase = 0
			var next_phase = 1
			if id.begins_with("the_small_fair.greeting."):
				required_phase = 1
				next_phase = 2
			elif id == "the_small_fair.race.crooked":
				required_phase = 2
				next_phase = 3
			elif id.begins_with("the_small_fair.inspect."):
				required_phase = 3 if fair_phase < 4 else 4
				next_phase = 4
			elif id.begins_with("the_small_fair.level."):
				required_phase = 4
				next_phase = 5
			elif id == "the_small_fair.race.canonical":
				required_phase = 5
				next_phase = 6
			elif id.begins_with("the_small_fair.departure."):
				required_phase = 6
				next_phase = 7
			elif id != "the_small_fair.begin": return false
			fair_phase = compatible_fair_phase(c,fair_phase,required_phase)
			if fair_phase != required_phase: return false
			fair_phase = next_phase
		elif id.begins_with("paper_sky."):
			if id == "paper_sky.begin":
				if paper_phase != "locked": return false
				paper_phase = "arrival"
			elif id == "paper_sky.greeting":
				if paper_phase != "arrival": return false
				paper_phase = "workshop"
			elif id == "paper_sky.raise":
				if paper_phase != "workshop": return false
				paper_phase = "raised"
			elif id == "paper_sky.finish":
				if paper_phase != "raised": return false
				paper_phase = "complete"
			elif paper_phase != "workshop": return false
	return compatible_fair_phase(c,fair_phase,7) == 7 and paper_phase == "complete"
func valid_home(c: Dictionary) -> bool:
	if c.home_checkpoint not in HOME_STATES or typeof(c.home) != TYPE_DICTIONARY or c.home.size() != home_defaults().size(): return false
	for field in home_defaults():
		if not c.home.has(field): return false
	var h: Dictionary = c.home
	for field in HOME_OPTIONS:
		if typeof(h[field]) != TYPE_STRING or (h[field] != "unselected" and h[field] not in HOME_OPTIONS[field]): return false
	if typeof(h.completed) != TYPE_BOOL or typeof(c.campaign_complete) != TYPE_BOOL: return false
	var history = []
	for id in c.choice_history:
		if id.begins_with("still_here."): history.append(id)
	if c.home_checkpoint == "locked":
		return c.campaign_chapter != "still_here" and h == home_defaults() and history.is_empty() and not c.campaign_complete
	if c.campaign_chapter != "still_here" or c.return_checkpoint != "complete" or not c.return_state.completed: return false
	if history.is_empty() or c.choice_history.slice(c.choice_history.size() - history.size()) != history: return false
	# Replay the exact ordinary choices, rejecting impossible and reordered saves.
	var phase = "locked"
	var ticket = "unselected"
	var ritual = "unselected"
	var ending = "unselected"
	for id in history:
		if id == "still_here.begin":
			if phase != "locked": return false
			phase = "arrival"
		elif id.begins_with("still_here.ticket."):
			if phase != "arrival" or ticket != "unselected": return false
			ticket = id.trim_prefix("still_here.ticket.")
			if ticket not in HOME_OPTIONS.ticket: return false
		elif id.begins_with("still_here.ritual."):
			if phase != "arrival" or ticket == "unselected": return false
			ritual = id.trim_prefix("still_here.ritual.")
			if ritual not in HOME_OPTIONS.ritual: return false
			phase = "settled"
		elif id.begins_with("still_here.finish."):
			if phase != "settled": return false
			ending = id.trim_prefix("still_here.finish.")
			if ending not in HOME_OPTIONS.ending: return false
			phase = "complete"
		else: return false
	return phase == c.home_checkpoint and ticket == h.ticket and ritual == h.ritual and ending == h.ending and h.completed == (phase == "complete") and c.campaign_complete == (phase == "complete")
func valid_v2(c: Dictionary) -> bool:
	if typeof(c.get("campaign_chapter")) != TYPE_STRING: return false
	if c.is_empty() or not valid_legacy(c) or c.schema_version != SCHEMA_VERSION: return false
	if c.get("campaign_chapter") == "still_here":
		for key in ["home_checkpoint","home","campaign_complete","history_compatibility","return_checkpoint","return_state","orchard_checkpoint","orchard","kitchen_checkpoint","kitchen","paper_checkpoint","paper"]:
			if not c.has(key): return false
	if not c.has("history_compatibility"):
		c = c.duplicate(true)
		c.history_compatibility = compatibility_missing(c)
	if not c.has("home_checkpoint") or not c.has("home") or not c.has("campaign_complete"):
		c = c.duplicate(true)
		if not c.has("home_checkpoint"): c.home_checkpoint = "locked"
		if not c.has("home"): c.home = home_defaults()
		if not c.has("campaign_complete"): c.campaign_complete = false
	if c.get("campaign_chapter") == "return_platform":
		for key in ["return_checkpoint","return_state","orchard_checkpoint","orchard","kitchen_checkpoint","kitchen","paper_checkpoint","paper"]:
			if not c.has(key): return false
	if not c.has("return_checkpoint") or not c.has("return_state"):
		c = c.duplicate(true)
		if not c.has("return_checkpoint"): c.return_checkpoint = "locked"
		if not c.has("return_state"): c.return_state = return_defaults()
	if c.get("campaign_chapter") == "night_kitchen" and (not c.has("kitchen_checkpoint") or not c.has("kitchen")): return false
	if c.get("campaign_chapter") == "quiet_orchard" and (not c.has("orchard_checkpoint") or not c.has("orchard")): return false
	if not c.has("orchard_checkpoint") or not c.has("orchard"):
		c = c.duplicate(true)
		if not c.has("orchard_checkpoint"): c.orchard_checkpoint = "locked"
		if not c.has("orchard"): c.orchard = orchard_defaults()
	if not c.has("paper_checkpoint") or not c.has("paper") or not c.has("kitchen_checkpoint") or not c.has("kitchen"):
		c = c.duplicate(true)
		if not c.has("paper_checkpoint"): c.paper_checkpoint = "locked"
		if not c.has("paper"): c.paper = paper_defaults()
		if not c.has("kitchen_checkpoint"): c.kitchen_checkpoint = "locked"
		if not c.has("kitchen"): c.kitchen = kitchen_defaults()
	for key in ["campaign_chapter","fair_checkpoint","fair","choice_history","dimensions","npc_state"]:
		if not c.has(key): return false
	if c.campaign_chapter not in CAMPAIGN_CHAPTERS or c.fair_checkpoint not in FAIR_STATES: return false
	if not rules.valid_history(c.choice_history) or not rules.valid_weights(c.dimensions) or not rules.valid_npcs(c.npc_state) or not valid_history_compatibility(c): return false
	if not valid_paper(c) or not valid_kitchen(c) or not valid_orchard(c) or not valid_return(c) or not valid_home(c): return false
	if c.npc_state.mira.camera_memory != c.camera_choice: return false
	if typeof(c.fair) != TYPE_DICTIONARY or c.fair.size() != fair_defaults().size(): return false
	for key in fair_defaults():
		if not c.fair.has(key): return false
	var f: Dictionary = c.fair
	if f.rudder not in ["left","straight","right"] or f.sail not in ["triangle","square","folded"] or f.mode not in ["operate","watch","cooperate"]: return false
	if typeof(f.levelled) != TYPE_BOOL or not integer(f.race_count,0,2) or not integer(f.replay_count,0,1000000): return false
	if f.outcome not in ["unselected","first","second","third","circle","spectator"] or f.greeting not in ["unselected","ducks","watch","how"] or f.leveller not in ["unselected","self","ada"] or f.departure not in ["unselected","card","speak","wait"]: return false
	if typeof(f.souvenir_ids) != TYPE_ARRAY or (f.souvenir_ids != [] and f.souvenir_ids != ["fair_button"]): return false
	if typeof(f.inspected) != TYPE_ARRAY: return false
	var seen = []
	for id in f.inspected:
		if id not in ["boat","wedge","together","watch"] or id in seen: return false
		seen.append(id)
	if ("watch" in f.inspected or "together" in f.inspected) and "wedge" not in f.inspected: return false
	if not valid_history_context(c): return false
	if c.fair_checkpoint == "locked":
		var neutral_fair = fair_defaults()
		for key in neutral_fair:
			if f[key] != neutral_fair[key]: return false
		return c.campaign_chapter == "platform_six" and c.npc_state.mira.destination == "unselected" and not c.npc_state.mira.independent_decision
	if c.campaign_chapter not in ["the_small_fair","paper_sky","night_kitchen","quiet_orchard","return_platform","still_here"] or not c.chapter_complete: return false
	var index = FAIR_STATES.find(c.fair_checkpoint)
	if (f.greeting != "unselected") != (index >= FAIR_STATES.find("workshop")): return false
	var expected_races = 2 if index >= FAIR_STATES.find("result") else (1 if index >= FAIR_STATES.find("crooked_race") else 0)
	if f.race_count != expected_races: return false
	if not f.inspected.is_empty() != (index >= FAIR_STATES.find("level_pond")): return false
	if f.levelled != (index >= FAIR_STATES.find("race_ready")) or (f.leveller != "unselected") != f.levelled: return false
	if (f.outcome != "unselected") != (index >= FAIR_STATES.find("result")): return false
	if (f.souvenir_ids == ["fair_button"]) != (index >= FAIR_STATES.find("result")): return false
	if f.outcome != "unselected" and f.outcome != race_outcome(f): return false
	if f.replay_count > 0 and index < FAIR_STATES.find("result"): return false
	var complete = c.fair_checkpoint == "complete"
	if (f.departure != "unselected") != complete or c.npc_state.mira.independent_decision != complete: return false
	if c.npc_state.mira.destination != ("lower_mill" if complete else "unselected"): return false
	return valid_home_prior_history(c) if c.campaign_chapter == "still_here" else true
