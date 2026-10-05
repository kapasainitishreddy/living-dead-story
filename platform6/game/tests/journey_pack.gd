extends SceneTree

const PACK_PATH = "res://data/journey_pack.json"
const DESTINATIONS = ["rain_town", "unsent_letters_library", "arcade", "beach_before_sunrise", "winter_orchard", "rest_room", "failed_things_festival", "sunrise_cafe", "no_destination_road", "fireflies"]
const ACTIVITIES = ["rain_routing", "letter_arrangement", "arcade_paddle", "constellation_tracing", "tea_mixing", "observation"]
const TEXTURES = ["wistful", "playful", "tender", "quiet", "awe", "bittersweet", "hopeful", "ordinary"]
const REQUIRED = ["journey_id", "title", "location_scene", "available_time_states", "weather_profile", "lighting_profile", "music_profile", "required_flags", "excluded_flags", "possible_cast", "story_theme_tags", "activity_tags", "entry_variants", "story_nodes", "choice_nodes", "consequence_rules", "returning_location_states", "callback_pool", "tiny_tomorrow_hooks", "estimated_duration", "accessibility_notes", "performance_tier", "activity_type", "palette", "scene_kind", "npc", "activity_prompt", "emotional_texture_tags", "local_scene_states"]
var checks := 0
var failures := 0

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func strings(value: Variant, minimum: int = 1) -> bool:
	if not value is Array or value.size() < minimum: return false
	for entry in value:
		if not entry is String or entry.strip_edges().is_empty(): return false
	return true

func finish():
	print("JourneyPack content checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)

func _initialize():
	check(FileAccess.file_exists(PACK_PATH), "authored JourneyPack exists")
	if not FileAccess.file_exists(PACK_PATH):
		finish()
		return
	var pack = JSON.parse_string(FileAccess.get_file_as_string(PACK_PATH))
	check(pack is Dictionary, "JourneyPack parses to an object")
	if not pack is Dictionary:
		finish()
		return
	check(pack.get("pack_id", "") == "platform6_journeys_v1", "stable authored pack identifier")
	check(pack.get("version", 0) == 1, "JourneyPack version is explicit")
	check(pack.get("emotional_texture_tags", []) == TEXTURES, "exactly eight named emotional textures")
	check(pack.get("npc_lives", {}) is Dictionary, "independent recurring cast lives are authored")
	for cast_id in ["mira", "ada", "noor", "jo"]:
		check(pack.get("npc_lives", {}).has(cast_id), "returning cast life " + cast_id)
		var life = pack.get("npc_lives", {}).get(cast_id, {})
		check(life is Dictionary and strings([life.get("name", ""), life.get("independent_life", ""), life.get("current_work", "")]), "grounded name and work for " + cast_id)
	var destinations = pack.get("destinations", [])
	check(destinations is Array and destinations.size() == 10, "ten authored destinations")
	if not destinations is Array:
		finish()
		return
	var ids = []
	var kinds = []
	var activity_types = []
	var used_textures = []
	var all_choice_ids = []
	var colors = RegEx.new()
	colors.compile("^#[0-9A-Fa-f]{6}$")
	for destination in destinations:
		check(destination is Dictionary, "destination is a schema object")
		if not destination is Dictionary: continue
		var id = str(destination.get("journey_id", "missing"))
		for field in REQUIRED: check(destination.has(field), id + " required field " + field)
		if not REQUIRED.all(func(field): return destination.has(field)): continue
		check(DESTINATIONS.has(id) and not ids.has(id), id + " stable unique destination")
		ids.append(id)
		check(strings([destination.title, destination.location_scene, destination.scene_kind, destination.npc, destination.activity_prompt]), id + " scene identity and activity prompt")
		check(not kinds.has(destination.scene_kind), id + " distinct visual scene kind")
		kinds.append(destination.scene_kind)
		check(ACTIVITIES.has(destination.activity_type), id + " supported activity")
		activity_types.append(destination.activity_type)
		check(destination.required_flags == ["campaign_complete"] and destination.excluded_flags == [], id + " same access after either campaign ending")
		check(strings(destination.available_time_states), id + " authored time states")
		for time_state in destination.available_time_states: check(["dawn", "day", "dusk", "night"].has(time_state), id + " supported time " + str(time_state))
		check(strings(destination.possible_cast) and destination.possible_cast.has(destination.npc), id + " active cast is eligible")
		for cast_id in destination.possible_cast: check(pack.get("npc_lives", {}).has(cast_id), id + " independently grounded possible cast " + str(cast_id))
		check(strings(destination.story_theme_tags) and strings(destination.activity_tags), id + " meaningful content tags")
		check(strings(destination.emotional_texture_tags), id + " authored emotional texture")
		for texture in destination.emotional_texture_tags:
			check(TEXTURES.has(texture), id + " supported texture " + str(texture))
			if not used_textures.has(texture): used_textures.append(texture)
		check(destination.palette is Array and destination.palette.size() == 3, id + " three-color palette")
		for color in destination.palette: check(color is String and colors.search(color) != null, id + " valid palette hex")
		check(destination.entry_variants is Dictionary and strings([destination.entry_variants.get("first", ""), destination.entry_variants.get("return", "")]), id + " first and revisit entries")
		check(destination.entry_variants.get("first", "") != destination.entry_variants.get("return", ""), id + " revisit is newly authored")
		check(strings(destination.story_nodes) and destination.story_nodes.size() == 3, id + " three authored scene beats")
		check(strings(destination.returning_location_states) and destination.returning_location_states.size() == 3, id + " three authored local return states")
		check(destination.local_scene_states is Dictionary and destination.local_scene_states.size() == 3 and destination.local_scene_states.has("as_found"), id + " three stable local-state keys")
		for state_id in destination.local_scene_states: check(destination.returning_location_states.has(destination.local_scene_states[state_id]), id + " state text included for " + str(state_id))
		check(destination.callback_pool is Dictionary, id + " callback object")
		for history in ["camera", "fair", "sign", "mira"]: check(strings([destination.callback_pool.get(history, "")]), id + " authored history callback " + history)
		check(destination.choice_nodes is Array and destination.choice_nodes.size() == 3, id + " two local alternatives and unchanged choice")
		check(destination.consequence_rules is Array and destination.consequence_rules.size() == destination.choice_nodes.size(), id + " every choice has one local consequence")
		var choice_ids = []
		for choice in destination.choice_nodes:
			check(choice is Dictionary and strings([choice.get("choice_id", ""), choice.get("label", ""), choice.get("response", ""), choice.get("state_id", "")]), id + " authored choice schema")
			check(not all_choice_ids.has(choice.get("choice_id", "")), id + " globally unique choice id")
			all_choice_ids.append(choice.get("choice_id", ""))
			choice_ids.append(choice.get("choice_id", ""))
			check(destination.local_scene_states.has(choice.get("state_id", "")), id + " choice names a known local state")
		var ruled_ids = []
		for rule in destination.consequence_rules:
			check(rule is Dictionary and rule.get("scope", "") == "destination", id + " consequence bounded to local scene")
			check(choice_ids.has(rule.get("choice_id", "")) and not ruled_ids.has(rule.get("choice_id", "")), id + " one rule per known choice")
			ruled_ids.append(rule.get("choice_id", ""))
			check(destination.local_scene_states.has(rule.get("set_state", "")) and strings([rule.get("callback", "")]), id + " authored local consequence")
			check(not rule.has("dimensions") and not rule.has("rewards") and not rule.has("global_flags"), id + " no score, reward or global consequence")
		check(destination.tiny_tomorrow_hooks is Array and destination.tiny_tomorrow_hooks.size() == 1, id + " one optional invitation")
		for hook in destination.tiny_tomorrow_hooks: check(hook is Dictionary and hook.get("optional", false) and strings([hook.get("hook_id", ""), hook.get("text", "")]), id + " invitation is explicitly optional")
		check(destination.estimated_duration is float and destination.estimated_duration >= 3 and destination.estimated_duration <= 8, id + " short estimated minutes")
		check(strings(destination.accessibility_notes, 3), id + " actionable accessibility notes")
		check(destination.performance_tier == "low", id + " low bounded performance tier")
		check(destination.weather_profile is Dictionary and strings(destination.weather_profile.get("states", [])), id + " authored weather states")
		check(destination.lighting_profile is Dictionary and strings([destination.lighting_profile.get("key", "")]), id + " lighting profile")
		check(destination.music_profile is Dictionary and strings([destination.music_profile.get("track", ""), destination.music_profile.get("ambience", "")]), id + " music and ambience profile")
		check(FileAccess.file_exists(destination.music_profile.get("track", "res://missing")), id + " soundtrack exists")
	for expected_id in DESTINATIONS: check(ids.has(expected_id), "destination included " + expected_id)
	for activity in ACTIVITIES: check(activity_types.has(activity), "implemented activity represented " + activity)
	for texture in TEXTURES: check(used_textures.has(texture), "texture represented " + texture)
	finish()
