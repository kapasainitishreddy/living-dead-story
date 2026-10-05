extends RefCounted
# These are authored fictional story weights, never a profile of the real player.
const DIMENSIONS = ["joy","calm","connection","wonder","agency","energy","future_pull","meaning"]
const LEGACY_STATES = ["apartment","roof","platform","conductor","passenger","shoreline","overlook","camera_choice","optional_action","return_train","breakfast","complete"]
const FAIR_STATES = ["locked","arrival","workshop","crooked_race","level_pond","race_ready","result","complete"]
const PAPER_STATES = ["locked","arrival","workshop","raised","complete"]
const ORCHARD_STATES = ["locked","arrival","rest","complete"]
const RETURN_STATES = ["locked","arrival","farewell","departed","complete"]
const KITCHEN_STATES = ["locked","arrival","supper","conversation","complete"]
const HOME_STATES = ["locked","arrival","settled","complete"]
const CAMPAIGN_CHAPTERS = ["platform_six","the_small_fair","paper_sky","night_kitchen","quiet_orchard","return_platform","still_here"]
const NPC_FIELDS = {"mira":{"connection":"weight","camera_memory":["unselected","take","lend","unused"],"destination":["unselected","lower_mill"],"independent_decision":"boolean"},"ada":{"connection":"weight"}}
var choices: Dictionary = {}
var catalog_ok := false
func _init():
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/choices.json"))
	var return_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/return.json"))
	var home_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/home_choices.json"))
	if not validate_catalog(parsed) or not validate_catalog(return_catalog) or not validate_catalog(home_catalog): return
	parsed.choices.append_array(return_catalog.choices)
	parsed.choices.append_array(home_catalog.choices)
	catalog_ok = validate_catalog(parsed)
	if catalog_ok:
		for choice in parsed.choices: choices[choice.choice_id] = choice.duplicate(true)
func neutral_dimensions() -> Dictionary:
	var result = {}
	for dimension in DIMENSIONS: result[dimension] = 0.0
	return result
func neutral_npcs() -> Dictionary:
	return {"mira":{"connection":0.0,"camera_memory":"unselected","destination":"unselected","independent_decision":false},"ada":{"connection":0.0}}
func numeric(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(value)
func valid_weights(weights: Variant) -> bool:
	if typeof(weights) != TYPE_DICTIONARY or weights.size() != DIMENSIONS.size(): return false
	for dimension in DIMENSIONS:
		if not weights.has(dimension) or not numeric(weights[dimension]) or weights[dimension] < 0 or weights[dimension] > 100: return false
	return true
func valid_npcs(npcs: Variant) -> bool:
	if typeof(npcs) != TYPE_DICTIONARY or npcs.size() != NPC_FIELDS.size(): return false
	for npc in NPC_FIELDS:
		if not npcs.has(npc) or typeof(npcs[npc]) != TYPE_DICTIONARY or npcs[npc].size() != NPC_FIELDS[npc].size(): return false
		for field in NPC_FIELDS[npc]:
			if not npcs[npc].has(field): return false
			var kind = NPC_FIELDS[npc][field]
			var value = npcs[npc][field]
			if kind is Array:
				if value not in kind: return false
			elif kind == "boolean":
				if typeof(value) != TYPE_BOOL: return false
			elif not numeric(value) or value < 0 or value > 100: return false
	return true
func validate_catalog(catalog: Variant) -> bool:
	if typeof(catalog) != TYPE_DICTIONARY or catalog.get("schema_version") != 1 or typeof(catalog.get("choices")) != TYPE_ARRAY: return false
	if catalog.get("dimensions") != DIMENSIONS or catalog.choices.is_empty() or catalog.choices.size() > 256: return false
	var seen = []
	for choice in catalog.choices:
		if typeof(choice) != TYPE_DICTIONARY: return false
		for key in ["choice_id","campaign_chapter","checkpoints","consequences"]:
			if not choice.has(key): return false
		if typeof(choice.choice_id) != TYPE_STRING or choice.choice_id.is_empty() or choice.choice_id.length() > 96 or choice.choice_id in seen: return false
		if choice.campaign_chapter not in CAMPAIGN_CHAPTERS: return false
		if not choice.choice_id.begins_with(choice.campaign_chapter + "."): return false
		if typeof(choice.checkpoints) != TYPE_ARRAY or choice.checkpoints.is_empty(): return false
		var allowed = {"platform_six":LEGACY_STATES,"the_small_fair":FAIR_STATES,"paper_sky":PAPER_STATES,"night_kitchen":KITCHEN_STATES,"quiet_orchard":ORCHARD_STATES,"return_platform":RETURN_STATES,"still_here":HOME_STATES}[choice.campaign_chapter]
		for checkpoint in choice.checkpoints:
			if checkpoint not in allowed: return false
		if typeof(choice.consequences) != TYPE_DICTIONARY or choice.consequences.size() != 2: return false
		if typeof(choice.consequences.get("dimensions")) != TYPE_DICTIONARY or typeof(choice.consequences.get("npc")) != TYPE_DICTIONARY: return false
		if choice.campaign_chapter in ["night_kitchen","quiet_orchard","return_platform","still_here"] and (not choice.consequences.dimensions.is_empty() or not choice.consequences.npc.is_empty()): return false
		for dimension in choice.consequences.dimensions:
			var delta = choice.consequences.dimensions[dimension]
			if dimension not in DIMENSIONS or not numeric(delta) or abs(delta) > 100: return false
		for npc in choice.consequences.npc:
			if not NPC_FIELDS.has(npc) or typeof(choice.consequences.npc[npc]) != TYPE_DICTIONARY: return false
			for field in choice.consequences.npc[npc]:
				if not NPC_FIELDS[npc].has(field): return false
				var kind = NPC_FIELDS[npc][field]
				var value = choice.consequences.npc[npc][field]
				if kind is Array:
					if value not in kind: return false
				elif kind == "boolean":
					if typeof(value) != TYPE_BOOL: return false
				elif not numeric(value) or abs(value) > 100: return false
		seen.append(choice.choice_id)
	return true
func valid_history(history: Variant) -> bool:
	if not catalog_ok or typeof(history) != TYPE_ARRAY or history.size() > choices.size(): return false
	var seen = []
	for id in history:
		if typeof(id) != TYPE_STRING or not choices.has(id) or id in seen: return false
		seen.append(id)
	return true
func apply_choice(id: String, state: Dictionary) -> bool:
	if not catalog_ok or not choices.has(id) or id in state.choice_history: return false
	var choice: Dictionary = choices[id]
	if state.campaign_chapter != choice.campaign_chapter: return false
	var checkpoint = {"platform_six":state.checkpoint_id,"the_small_fair":state.fair_checkpoint,"paper_sky":state.get("paper_checkpoint","locked"),"night_kitchen":state.get("kitchen_checkpoint","locked"),"quiet_orchard":state.get("orchard_checkpoint","locked"),"return_platform":state.get("return_checkpoint","locked"),"still_here":state.get("home_checkpoint","locked")}[choice.campaign_chapter]
	if checkpoint not in choice.checkpoints: return false
	for dimension in choice.consequences.dimensions:
		state.dimensions[dimension] = clampf(state.dimensions[dimension] + choice.consequences.dimensions[dimension], 0.0, 100.0)
	for npc in choice.consequences.npc:
		for field in choice.consequences.npc[npc]:
			var value = choice.consequences.npc[npc][field]
			var kind = NPC_FIELDS[npc][field]
			state.npc_state[npc][field] = clampf(state.npc_state[npc][field] + value, 0.0, 100.0) if typeof(kind) == TYPE_STRING and kind == "weight" else value
	state.choice_history.append(id)
	return true
