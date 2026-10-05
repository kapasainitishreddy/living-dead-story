extends RefCounted
# Local fictional continuity and optional player-authored writing. No network, rewards,
# wellbeing inference, real clock reads, or campaign-save mutation belong here.
const SCHEMA_VERSION := 1
const DEFAULT_PACK_PATH := "res://data/journey_pack.json"
const MAX_RECORDS := 32
const MAX_TEXT := 1000
const MAX_COUNT := 1000000
const MAX_HISTORY := 128
const TINY_STATES := ["SOMEDAY", "HAPPENED", "NOT ANYMORE"]
const ACTIVITY_LIMITS := {"step":32, "selection":31, "progress":10000}
var data: Dictionary
var _catalog: Array = []
var _by_id: Dictionary = {}
var _npc_names: Array = []
func _init(pack_path: String = DEFAULT_PACK_PATH):
	_load_pack(pack_path)
	data = defaults()
func defaults() -> Dictionary:
	return {"schema_version":SCHEMA_VERSION,"mode":"train","journey_id":"","visits":{},"stage":0,"activity":{},"location_states":{},"npc_visits":{},"tiny_tomorrows":[],"future_echoes":[],"train_details":[],"board_history":[],"resumable":{}}
func snapshot() -> Dictionary:
	return data.duplicate(true)
func destinations() -> Array:
	return _catalog.duplicate(true)
func current_destination() -> Dictionary:
	return _by_id.get(data.journey_id, {}).duplicate(true)
func _load_pack(path: String):
	if not FileAccess.file_exists(path): return
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 1048576: return
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK: return
	var pack: Variant = parser.data
	if typeof(pack) != TYPE_DICTIONARY or typeof(pack.get("destinations")) != TYPE_ARRAY: return
	if pack.destinations.is_empty() or pack.destinations.size() > 32: return
	var found := {}
	var names := []
	for destination in pack.destinations:
		if typeof(destination) != TYPE_DICTIONARY or not _identifier(destination.get("journey_id")) or found.has(destination.journey_id): return
		if not _text(destination.get("npc"),80) or typeof(destination.get("story_nodes")) != TYPE_ARRAY or destination.story_nodes.size() != 3: return
		for node in destination.story_nodes:
			if not _text(node,3000): return
		if destination.has("possible_cast"):
			if typeof(destination.possible_cast) != TYPE_ARRAY or destination.possible_cast.size() > 16: return
			for name in destination.possible_cast:
				if not _text(name,80): return
				if name not in names: names.append(name)
		if destination.npc not in names: names.append(destination.npc)
		if destination.has("local_scene_states"):
			if typeof(destination.local_scene_states) != TYPE_DICTIONARY or destination.local_scene_states.size() > 8: return
			for state in destination.local_scene_states:
				if not _identifier(state) or not _text(destination.local_scene_states[state],3000): return
		if destination.has("choice_nodes"):
			if typeof(destination.choice_nodes) != TYPE_ARRAY or destination.choice_nodes.size() > 8: return
			var choices := []
			for choice in destination.choice_nodes:
				if typeof(choice) != TYPE_DICTIONARY or not _text(choice.get("choice_id"),128) or choice.choice_id in choices: return
				if not _text(choice.get("state_id"),64) or not destination.get("local_scene_states",{}).has(choice.state_id): return
				choices.append(choice.choice_id)
		found[destination.journey_id] = destination.duplicate(true)
	_by_id = found
	_catalog = pack.destinations.duplicate(true)
	_npc_names = names
func _text(value: Variant, maximum: int) -> bool:
	if typeof(value) != TYPE_STRING or value.length() == 0 or value.length() > maximum or value.strip_edges().is_empty(): return false
	for n in value.length():
		if value.unicode_at(n) == 0: return false
	return true
func _identifier(value: Variant) -> bool:
	if not _text(value,64): return false
	for n in value.length():
		var character = value.unicode_at(n)
		if not ((character >= 97 and character <= 122) or (character >= 65 and character <= 90) or (character >= 48 and character <= 57) or character in [45,95]): return false
	return true
func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	# JSON numbers arrive as floats; only finite exact integers are accepted.
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(value) and value == floor(value) and value >= minimum and value <= maximum
func _keys(value: Variant, required: Array, optional: Array = []) -> bool:
	if typeof(value) != TYPE_DICTIONARY: return false
	for key in required:
		if not value.has(key): return false
	for key in value:
		if typeof(key) != TYPE_STRING or key not in required + optional: return false
	return true
func _activity(value: Variant) -> bool:
	if not _keys(value, [], ["step","selection","progress","done"]): return false
	for key in value:
		if key == "done":
			if typeof(value[key]) != TYPE_BOOL: return false
		elif not _integer(value[key],0,ACTIVITY_LIMITS[key]): return false
	return true
func _normalized_activity(value: Dictionary) -> Dictionary:
	var result = value.duplicate(true)
	for key in ACTIVITY_LIMITS:
		if result.has(key): result[key] = int(result[key])
	return result
func _local_datetime(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING or value.length() != 16: return false
	if value[4] != "-" or value[7] != "-" or value[10] != " " or value[13] != ":": return false
	for n in [0,1,2,3,5,6,8,9,11,12,14,15]:
		if value.unicode_at(n) < 48 or value.unicode_at(n) > 57: return false
	var year = int(value.substr(0,4))
	var month = int(value.substr(5,2))
	var day = int(value.substr(8,2))
	if year < 1 or month < 1 or month > 12 or int(value.substr(11,2)) > 23 or int(value.substr(14,2)) > 59: return false
	var days = [31,28,31,30,31,30,31,31,30,31,30,31]
	if year % 400 == 0 or (year % 4 == 0 and year % 100 != 0): days[1] = 29
	return day >= 1 and day <= days[month - 1]
func _writing_records(value: Variant, echoes: bool) -> bool:
	if typeof(value) != TYPE_ARRAY or value.size() > MAX_RECORDS: return false
	var seen := []
	for record in value:
		var required = ["id","text","due_local","created_local","delivered"] if echoes else ["id","text","state"]
		if not _keys(record,required) or not _identifier(record.id) or not _text(record.text,MAX_TEXT) or record.id in seen: return false
		seen.append(record.id)
		if echoes:
			if not _local_datetime(record.due_local) or not _local_datetime(record.created_local) or typeof(record.delivered) != TYPE_BOOL: return false
		elif typeof(record.state) != TYPE_STRING or record.state not in TINY_STATES: return false
	return true
func valid(candidate: Variant) -> bool:
	if not _keys(candidate,defaults().keys()): return false
	if not _integer(candidate.schema_version,SCHEMA_VERSION,SCHEMA_VERSION) or typeof(candidate.mode) != TYPE_STRING or candidate.mode not in ["train","destination","home"]: return false
	if typeof(candidate.journey_id) != TYPE_STRING or not _integer(candidate.stage,0,3) or not _activity(candidate.activity): return false
	if candidate.mode == "destination":
		if not _by_id.has(candidate.journey_id): return false
	elif candidate.journey_id != "" or candidate.stage != 0 or not candidate.activity.is_empty(): return false
	for field in ["visits","location_states","resumable"]:
		if typeof(candidate[field]) != TYPE_DICTIONARY or candidate[field].size() > _catalog.size(): return false
		for id in candidate[field]:
			if typeof(id) != TYPE_STRING or not _by_id.has(id): return false
			var value = candidate[field][id]
			if field == "visits" and not _integer(value,1,MAX_COUNT): return false
			if field == "location_states":
				if typeof(value) != TYPE_STRING or value not in _by_id[id].get("local_scene_states",{"as_found":""}): return false
			if field == "resumable" and (not _keys(value,["stage","activity"]) or not _integer(value.stage,0,3) or not _activity(value.activity)): return false
	if typeof(candidate.npc_visits) != TYPE_DICTIONARY or candidate.npc_visits.size() > _npc_names.size(): return false
	for name in candidate.npc_visits:
		if typeof(name) != TYPE_STRING or name not in _npc_names or not _integer(candidate.npc_visits[name],1,MAX_COUNT): return false
	for field in ["train_details","board_history"]:
		if typeof(candidate[field]) != TYPE_ARRAY or candidate[field].size() > (MAX_HISTORY if field == "board_history" else _catalog.size()): return false
		var seen := []
		for id in candidate[field]:
			if typeof(id) != TYPE_STRING or not _by_id.has(id): return false
			if field == "train_details" and (id in seen or not candidate.visits.has(id)): return false
			seen.append(id)
	return _writing_records(candidate.tiny_tomorrows,false) and _writing_records(candidate.future_echoes,true)
func restore(candidate: Variant) -> bool:
	if not valid(candidate): return false
	data = candidate.duplicate(true)
	data.schema_version = SCHEMA_VERSION
	data.stage = int(data.stage)
	data.activity = _normalized_activity(data.activity)
	for field in ["visits","npc_visits"]:
		for key in data[field]: data[field][key] = int(data[field][key])
	for key in data.resumable:
		data.resumable[key].stage = int(data.resumable[key].stage)
		data.resumable[key].activity = _normalized_activity(data.resumable[key].activity)
	return true
func apply(action: String, value: Variant = null) -> bool:
	var before = snapshot()
	if not _apply(action,value) or not valid(data):
		data = before
		return false
	return true
func _leave(mode: String):
	if data.mode == "destination": data.resumable[data.journey_id] = {"stage":data.stage,"activity":data.activity.duplicate(true)}
	data.mode = mode
	data.journey_id = ""
	data.stage = 0
	data.activity = {}
func _record_id(records: Array, prefix: String) -> String:
	# Creation is deterministic and local; no timestamps or identifying data.
	var used := []
	for record in records: used.append(record.id)
	for n in range(1,MAX_RECORDS + 2):
		var id = prefix + "_" + str(n)
		if id not in used: return id
	return ""
func _apply(action: String, value: Variant) -> bool:
	if action == "board":
		if data.mode == "destination" or typeof(value) != TYPE_STRING or not _by_id.has(value): return false
		data.mode = "destination"
		data.journey_id = value
		var progress = data.resumable.get(value,{"stage":0,"activity":{}})
		data.stage = progress.stage
		data.activity = progress.activity.duplicate(true)
		data.resumable.erase(value)
		if not data.location_states.has(value): data.location_states[value] = "as_found"
		data.board_history.append(value)
		if data.board_history.size() > MAX_HISTORY: data.board_history.pop_front()
		return true
	if action == "activity":
		if data.mode != "destination" or not _activity(value): return false
		data.activity = _normalized_activity(value)
		return true
	if action == "choose":
		if data.mode != "destination" or typeof(value) != TYPE_STRING: return false
		for choice in _by_id[data.journey_id].get("choice_nodes",[]):
			if choice.choice_id == value:
				data.location_states[data.journey_id] = choice.state_id
				return true
		return false
	if action in ["advance","finish","return_train","home"]:
		if value != null: return false
		if action == "return_train" or action == "home":
			_leave("train" if action == "return_train" else "home")
			return true
		if data.mode != "destination": return false
		if action == "advance":
			if data.stage >= 3: return false
			data.stage += 1
			return true
		var id: String = data.journey_id
		data.visits[id] = mini(data.visits.get(id,0) + 1,MAX_COUNT)
		var name: String = _by_id[id].npc
		data.npc_visits[name] = mini(data.npc_visits.get(name,0) + 1,MAX_COUNT)
		if id not in data.train_details: data.train_details.append(id)
		data.resumable.erase(id)
		data.mode = "train"
		data.journey_id = ""
		data.stage = 0
		data.activity = {}
		return true
	if action == "tiny_create":
		if not _keys(value,["text"],["id","state"]) or data.tiny_tomorrows.size() >= MAX_RECORDS: return false
		var record = {"id":value.get("id",_record_id(data.tiny_tomorrows,"tiny")),"text":value.text,"state":value.get("state","SOMEDAY")}
		if not _writing_records([record],false): return false
		for existing in data.tiny_tomorrows:
			if existing.id == record.id: return false
		data.tiny_tomorrows.append(record)
		return true
	if action == "tiny_change":
		if not _keys(value,["id","state"]) or not _identifier(value.id): return false
		for n in data.tiny_tomorrows.size():
			if data.tiny_tomorrows[n].id == value.id:
				var record = data.tiny_tomorrows[n].duplicate(true)
				record.state = value.state
				if not _writing_records([record],false): return false
				data.tiny_tomorrows[n] = record
				return true
		return false
	if action == "echo_create":
		if not _keys(value,["text","due_local","created_local"],["id"]) or data.future_echoes.size() >= MAX_RECORDS: return false
		var record = value.duplicate(true)
		if not record.has("id"): record["id"] = _record_id(data.future_echoes,"echo")
		record["delivered"] = false
		if not _writing_records([record],true): return false
		for existing in data.future_echoes:
			if existing.id == record.id: return false
		data.future_echoes.append(record)
		return true
	if action == "resolve_echoes":
		if not _local_datetime(value): return false
		for echo in data.future_echoes:
			if not echo.delivered and echo.due_local <= value: echo.delivered = true
		return true
	return false
func due_echoes(local_datetime: Variant) -> Array:
	var result := []
	if not _local_datetime(local_datetime): return result
	for echo in data.future_echoes:
		if not echo.delivered and echo.due_local <= local_datetime: result.append(echo.duplicate(true))
	return result
func callback(campaign: Variant) -> Array:
	# Select authored fictional memories only. User writing never enters this path.
	var result := []
	if typeof(campaign) != TYPE_DICTIONARY: return result
	var camera = campaign.get("camera_choice")
	if typeof(camera) == TYPE_STRING:
		if camera == "take": result.append("Mira remembers the camera you carried down to the shore.")
		elif camera == "lend": result.append("Mira still has a story about the camera you lent her.")
		elif camera == "unused": result.append("Mira remembers the shore, and the unopened camera that stayed in your pocket.")
	var fair = campaign.get("fair")
	if typeof(fair) == TYPE_DICTIONARY and fair.get("rudder") in ["left","straight","right"] and fair.get("sail") in ["triangle","square","folded"]:
		result.append("Ada remembers the little boat: %s rudder, %s sail." % [fair.rudder,fair.sail])
	var paper = campaign.get("paper")
	if typeof(paper) == TYPE_DICTIONARY and paper.get("layout") in ["leaf_boat_star","boat_star_leaf","star_leaf_boat","leaf_star_boat","boat_leaf_star","star_boat_leaf"]:
		result.append("The paper sky keeps the arrangement you chose: " + paper.layout.replace("_",", ") + ".")
	var home = campaign.get("home")
	if typeof(home) == TYPE_DICTIONARY and home.get("ending") in ["train","sleep"]:
		result.append("The ticket waited while you slept." if home.ending == "sleep" else "The ticket remembers the train you chose to take.")
	var npcs = campaign.get("npc_state")
	if typeof(npcs) == TYPE_DICTIONARY and typeof(npcs.get("mira")) == TYPE_DICTIONARY and npcs.mira.get("destination") == "lower_mill":
		result.append("Mira chose Lower Mill for her own next journey. Sometimes her train takes a different track.")
	var returning = campaign.get("return_state")
	if typeof(returning) == TYPE_DICTIONARY:
		var farewells = {"luck":"Mira remembers the luck you wished her at Lower Mill.","joke":"Mira still remembers your last joke about the boats.","thanks":"Mira remembers your thank-you for the company.","wave":"Mira remembers the small wave from your farewell.","little":"Mira remembers standing beside you for the last few moments before her train."}
		if typeof(returning.get("farewell")) == TYPE_STRING and farewells.has(returning.farewell): result.append(farewells[returning.farewell])
	return result
