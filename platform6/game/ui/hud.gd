extends CanvasLayer
signal choice(action, value)
signal dismissed
signal settings_changed(settings)
signal pause_requested
signal quit_requested
var root: Control
var modal: PanelContainer
var content: VBoxContainer
var footer: VBoxContainer
var prompt: Label
var title: Label
var notice: Label
var controls: Label
var subtitle: Label
var objective: Label
var settings = {}
var authored = {}
var fair_authored = {}
var paper_authored = {}
var orchard_authored = {}
var home_authored = {}
var return_authored = {}
var kitchen_authored = {}
var pause_active := false
var paused_context = {}
var holding: Control
var layout_mode := "center"
func _ready():
	authored = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter.json"))
	if FileAccess.file_exists("res://data/fair.json"):
		fair_authored = JSON.parse_string(FileAccess.get_file_as_string("res://data/fair.json"))
	if FileAccess.file_exists("res://data/paper.json"):
		paper_authored = JSON.parse_string(FileAccess.get_file_as_string("res://data/paper.json"))
	if FileAccess.file_exists("res://data/orchard.json"):
		orchard_authored = JSON.parse_string(FileAccess.get_file_as_string("res://data/orchard.json"))
	if FileAccess.file_exists("res://data/kitchen.json"):
		kitchen_authored = JSON.parse_string(FileAccess.get_file_as_string("res://data/kitchen.json"))
	if FileAccess.file_exists("res://data/home.json"):
		home_authored = JSON.parse_string(FileAccess.get_file_as_string("res://data/home.json"))
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	title = Label.new()
	title.position = Vector2(38,24)
	title.add_theme_font_size_override("font_size",22)
	root.add_child(title)
	controls = Label.new()
	controls.position = Vector2(38,60)
	controls.text = "WASD / left stick · Move    Mouse / right stick · Look    E / A · Interact    R · Reset view    Esc / P / Menu · Pause"
	controls.add_theme_font_size_override("font_size",15)
	root.add_child(controls)
	prompt = Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-330,-90)
	prompt.size = Vector2(660,45)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(prompt)
	notice = Label.new()
	notice.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	notice.offset_left = 38
	notice.offset_right = -38
	notice.offset_top = -48
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(notice)
	subtitle = Label.new()
	subtitle.position = Vector2(38,88)
	subtitle.add_theme_font_size_override("font_size",16)
	root.add_child(subtitle)
	objective = Label.new()
	objective.name = "StoryObjective"
	objective.position = Vector2(38, 116)
	objective.size = Vector2(930, 62)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.set_meta("base_font_size", 17)
	objective.add_theme_font_size_override("font_size", 17)
	root.add_child(objective)
	modal = PanelContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	modal.position = Vector2(-360,-245)
	modal.custom_minimum_size = Vector2(720,0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.055,0.085,0.13,0.97)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	modal.add_theme_stylebox_override("panel",style)
	root.add_child(modal)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",12)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680,250)
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation",12)
	modal.add_child(layout)
	layout.add_child(scroll)
	footer = VBoxContainer.new()
	footer.add_theme_constant_override("separation",10)
	layout.add_child(footer)
	scroll.add_child(content)
	for overlay_label in [title, controls, subtitle, objective, notice]:
		overlay_label.add_theme_color_override("font_outline_color", Color(0.025,0.045,0.065,0.96))
		overlay_label.add_theme_constant_override("outline_size", 5)
	modal.hide()
func clear():
	layout_mode = "center"
	modal.position.x = -360
	modal.custom_minimum_size.x = 720
	content.custom_minimum_size.x = 0
	content.get_parent().custom_minimum_size.x = 680
	modal.position.y = -245
	content.get_parent().custom_minimum_size.y = 250
	content.get_parent().scroll_vertical = 0
	for child in footer.get_children():
		footer.remove_child(child)
		child.queue_free()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
func text(value: String, size_: int = 23):
	var label = Label.new()
	label.text = value
	label.custom_minimum_size.x = 650
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_meta("base_font_size",size_)
	label.add_theme_font_size_override("font_size",int(size_*settings.get("text_scale",1.0)))
	content.add_child(label)
func button(label: String, callback: Callable):
	var b = Button.new()
	b.text = label
	b.custom_minimum_size.y = 46
	b.set_meta("base_font_size",19)
	b.add_theme_font_size_override("font_size",int(19*settings.get("text_scale",1.0)))
	b.pressed.connect(callback)
	footer.add_child(b)
	return b
func opening_prose(id: String, snapshot: Dictionary) -> String:
	var entry = authored.dialogues.get(id, authored.get("local_dialogues", {}).get(id, {}))
	var prose: String = entry.get("text", "")
	if snapshot.is_empty(): return prose
	for callback in authored.get("callbacks", {}).get(id, []):
		if callback.choice_id in snapshot.choice_history: prose += "\n\n" + callback.text
	return prose
func show_dialogue(id: String, snapshot: Dictionary = {}):
	var data = authored.dialogues.get(id,authored.get("local_dialogues",{}).get(id,{}))
	if data.is_empty(): return
	clear()
	modal.show()
	layout_mode = "cinematic"
	modal.custom_minimum_size.x = max(720.0, get_viewport().get_visible_rect().size.x - 76)
	content.get_parent().custom_minimum_size.x = modal.custom_minimum_size.x - 60
	text(data.title,28)
	text(opening_prose(id, snapshot))
	var first
	for option in data.choices:
		var b = button(option.label,func(): choice.emit(option.action,option.get("value",null)))
		if first == null: first = b
	button("Back · Esc / B",func(): close_modal(); dismissed.emit())
	first.grab_focus()
func close_modal():
	if pause_active:
		resume_pause()
	else: modal.hide()
func close_all():
	pause_active = false
	paused_context = {}
	if is_instance_valid(holding): holding.queue_free()
	modal.hide()
func resume_pause():
	clear()
	pause_active = false
	if not paused_context.is_empty():
		for item in paused_context.body:
			holding.remove_child(item)
			content.add_child(item)
		for item in paused_context.buttons:
			holding.remove_child(item)
			footer.add_child(item)
		modal.show()
		var focus = paused_context.focus
		if is_instance_valid(focus): call_deferred("restore_focus",focus)
		content.get_parent().scroll_vertical = paused_context.scroll
		modal.position.y = paused_context.get("modal_y", -245)
		content.get_parent().custom_minimum_size.y = paused_context.get("body_height", 250)
		layout_mode = paused_context.get("layout_mode", "center")
		modal.custom_minimum_size.x = paused_context.get("panel_width", 720)
		content.get_parent().custom_minimum_size.x = paused_context.get("body_width", 680)
		paused_context = {}
		if is_instance_valid(holding): holding.queue_free()
	else: modal.hide()
	dismissed.emit()

func modal_visible() -> bool: return modal.visible
func set_prompt(value: String): prompt.text = value
func set_chapter(data: Dictionary):
	objective.visible = data.get("campaign_chapter", "platform_six") == "platform_six"
	if objective.visible:
		objective.text = authored.get("objectives", {}).get(data.checkpoint_id, "")
		if data.checkpoint_id == "overlook": objective.text += " · %d / 3 noticed" % data.inspected_landmark_ids.size()
	title.text = "STILL HERE / PLATFORM 6 · " + str(data.checkpoint_id).replace("_"," ").capitalize()
	if data.get("campaign_chapter","") == "the_small_fair":
		title.text = "THE UNFINISHED FAIR · " + str(data.fair_checkpoint).replace("_"," ").capitalize()
	if data.get("campaign_chapter", "") == "paper_sky":
		title.text = "A SKY THAT FITS THROUGH THE DOOR · " + str(data.paper_checkpoint).capitalize()
	if data.get("campaign_chapter", "") == "night_kitchen":
		title.text = "A PLACE BEFORE A TASK · " + str(data.kitchen_checkpoint).capitalize()
	if data.get("campaign_chapter", "") == "quiet_orchard":
		title.text = "THE QUIET ORCHARD · " + str(data.orchard_checkpoint).capitalize()
	if data.get("campaign_chapter", "") == "return_platform":
		title.text = "THE RETURN PLATFORM · " + str(data.return_checkpoint).capitalize()
	if data.get("campaign_chapter", "") == "still_here":
		title.text = "STILL HERE · " + str(data.home_checkpoint).capitalize()
func show_notice(message: String): notice.text = message
func apply_settings(value: Dictionary):
	settings = value.duplicate(true)
	for node in root.find_children("*","Control",true,false):
		if node.has_meta("base_font_size"):
			node.add_theme_font_size_override("font_size",int(node.get_meta("base_font_size")*settings.text_scale))
			if node is OptionButton: node.get_popup().add_theme_font_size_override("font_size",int(node.get_meta("base_font_size")*settings.text_scale))
	if subtitle: subtitle.visible = settings.subtitles
	prompt.add_theme_font_size_override("font_size",int(23*settings.text_scale))
	notice.add_theme_font_size_override("font_size",int(17*settings.text_scale))
func show_puzzle(data: Dictionary):
	clear()
	modal.show()
	layout_mode = "shore"
	# Leave the actual shore visible to the left of the choice panel.
	modal.position = Vector2(220, -245)
	modal.custom_minimum_size.x = 385
	content.get_parent().custom_minimum_size.x = 340
	content.get_parent().custom_minimum_size.y = 150
	text("Frame the shore", 26)
	text("Keep the lighthouse, arch and stars in one picture. Change the view and look at what fits.", 20)
	text("Noticed %d / 3" % data.inspected_landmark_ids.size(), 17)
	for child in content.get_children(): child.custom_minimum_size.x = 330
	var first
	var labels = ["Closer to the lighthouse", "Closer to the arch", "Step back"]
	for i in range(3):
		var b = button(("• " if i == int(data.overlook_alignment) else "") + labels[i],func(): choice.emit("preview_alignment",i))
		if i == int(data.overlook_alignment): first = b
	button("Keep this framing", func(): choice.emit("align", int(data.overlook_alignment)))
	button("Assist · frame for me",func(): choice.emit("assist",null))
	button("Back · Esc / B",func(): close_modal(); dismissed.emit())
	first.grab_focus()
func show_pause(value: Dictionary):
	if not pause_active:
		if modal.visible:
			paused_context = {"body":content.get_children(),"buttons":footer.get_children(),"focus":get_viewport().gui_get_focus_owner(),"scroll":content.get_parent().scroll_vertical,"modal_y":modal.position.y,"body_height":content.get_parent().custom_minimum_size.y,"layout_mode":layout_mode,"panel_width":modal.custom_minimum_size.x,"body_width":content.get_parent().custom_minimum_size.x}
			holding = Control.new()
			holding.hide()
			root.add_child(holding)
			for item in paused_context.body:
				content.remove_child(item)
				holding.add_child(item)
			for item in paused_context.buttons:
				footer.remove_child(item)
				holding.add_child(item)
		pause_active = true
	clear()
	modal.show()
	text("Take your time",28)
	var first = button("Resume · Esc / B",func(): resume_pause())
	button("Controls · keyboard and controller",show_controls)
	button("Settings",func(): show_settings(value))
	button("Start a new journey · keeps a backup",func(): choice.emit("reset",null))
	button("Quit to desktop",func(): quit_requested.emit())
	first.grab_focus()
func show_settings(value: Dictionary):
	clear()
	modal.show()
	var edited = value.duplicate(true)
	text("Settings",26)
	for key in ["text_scale","sensitivity","master","music","effects"]:
		var row = HBoxContainer.new()
		content.add_child(row)
		var label = Label.new()
		label.text = key.replace("_"," ").capitalize()
		label.custom_minimum_size.x = 230
		label.set_meta("base_font_size",19)
		label.add_theme_font_size_override("font_size",int(19*settings.get("text_scale",1.0)))
		row.add_child(label)
		var slider = HSlider.new()
		slider.custom_minimum_size.x = 330
		slider.min_value = 0 if key in ["master","music","effects"] else 0.5
		slider.max_value = 1 if key in ["master","music","effects"] else 2
		slider.step = 0.05
		slider.value = edited[key]
		slider.value_changed.connect(func(v): edited[key] = v; settings_changed.emit(edited))
		row.add_child(slider)
	for key in ["subtitles","reduced_motion"]:
		var toggle = CheckButton.new()
		toggle.text = key.replace("_"," ").capitalize()
		toggle.set_meta("base_font_size",19)
		toggle.add_theme_font_size_override("font_size",int(19*settings.get("text_scale",1.0)))
		toggle.button_pressed = edited[key]
		toggle.toggled.connect(func(v): edited[key] = v; settings_changed.emit(edited))
		content.add_child(toggle)
	var graphics = OptionButton.new()
	graphics.set_meta("base_font_size",19)
	graphics.add_theme_font_size_override("font_size",int(19*settings.get("text_scale",1.0)))
	graphics.get_popup().add_theme_font_size_override("font_size",int(19*settings.get("text_scale",1.0)))
	for tier in ["low","medium","high"]: graphics.add_item(tier.capitalize())
	graphics.selected = ["low","medium","high"].find(edited.graphics)
	graphics.item_selected.connect(func(i): edited.graphics = ["low","medium","high"][i]; settings_changed.emit(edited))
	content.add_child(graphics)
	var back = button("Back",func(): show_pause(edited))
	back.grab_focus()

func show_arrival(checkpoint: String):
	clear()
	modal.show()
	layout_mode = "cinematic"
	modal.custom_minimum_size.x = max(720.0, get_viewport().get_visible_rect().size.x - 76)
	content.get_parent().custom_minimum_size.x = modal.custom_minimum_size.x - 60
	var descriptions = {"platform":"Central Station. Amber light pools beneath the roof. Platform 6 waits.","passenger":"The city slips past the carriage windows. Someone has left room beside them.","overlook":"Moonlight opens a path across the sea. You can explore at your own pace.","return_train":"The warm carriage waits where you left it. There is toast on the table."}
	text(checkpoint.replace("_"," ").capitalize(),28)
	text(descriptions.get(checkpoint,"A new moment is waiting."))
	var continue_button = button("Continue · Enter / A",func(): close_modal(); dismissed.emit())
	continue_button.grab_focus()

func set_subtitle(value: String):
	subtitle.text = value
	subtitle.visible = settings.get("subtitles",true)

func _process(delta):
	var viewport_size = get_viewport().get_visible_rect().size
	var notice_height = max(48,notice.get_minimum_size().y + 12)
	notice.offset_top = -notice_height
	notice.offset_bottom = -12
	prompt.position.y = viewport_size.y - notice_height - prompt.size.y - 20
	if not modal.visible: return
	var scroll = content.get_parent()
	var available = viewport_size.y - footer.get_combined_minimum_size().y - 85
	var maximum_body = 150 if layout_mode in ["shore", "cinematic"] else 250
	scroll.custom_minimum_size.y = clamp(available,90,maximum_body)
	# Containers grow for long choices, but don't shrink when a previous panel
	# was wider/taller. Refit after the content and scrolling budget changes.
	modal.reset_size()
	if layout_mode == "cinematic":
		modal.position = Vector2((viewport_size.x - modal.size.x) * 0.5, max(12.0, viewport_size.y - modal.size.y - 38))
	elif layout_mode == "shore":
		modal.position = Vector2(max(12.0, viewport_size.x - modal.size.x - 28), (viewport_size.y - modal.size.y) * 0.5)
	else: modal.position = (viewport_size - modal.size) * 0.5
	var stick = Input.get_axis("look_up","look_down")
	if abs(stick) > 0.2: scroll.scroll_vertical += int(stick * delta * 600)

func _input(event):
	if not modal.visible: return
	if event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_page_up"):
		content.get_parent().scroll_vertical += 180 if event.is_action_pressed("ui_page_down") else -180
		get_viewport().set_input_as_handled()

func show_controls():
	clear()
	modal.show()
	text("Controls",28)
	text("WASD / arrows or left stick: walk\nMouse or right stick: look around\nE / A: interact with the labelled nearby object\nEnter / A: choose; arrows / D-pad: change choice\nR / right-stick click: reset your view\nEsc / B: back; P / Menu: pause even during a conversation\nPageUp / PageDown, wheel or right stick: read long text",20)
	text("Walk toward a label until the interaction prompt appears. There is no timer. The viewing marker also offers Assist. In Settings, Reduced motion keeps your chosen camera angle and quiets decorative movement.",18)
	var back = button("Back to pause",func(): show_pause(settings))
	back.grab_focus()

func restore_focus(focus: Control):
	# A player can back out again before deferred focus restoration runs.
	if is_instance_valid(focus) and focus.is_inside_tree() and focus.is_visible_in_tree() and modal.visible:
		focus.grab_focus()

func show_fair_dialogue(id: String, snapshot: Dictionary):
	var entry = fair_authored.get("dialogues",{}).get(id,{})
	if entry.is_empty(): return
	clear()
	modal.show()
	text(entry.title,28)
	var prose: String = entry.text
	if id == "fair_arrival": prose += "\n\n" + fair_authored.get("camera_callbacks",{}).get(snapshot.camera_choice,"")
	if id == "fair_result": prose = fair_authored.get("outcomes",{}).get(snapshot.fair.outcome,"") + "\n\n" + prose
	if id == "fair_complete": prose = fair_authored.get("departures",{}).get(snapshot.fair.departure,"") + "\n\n" + prose
	text(prose)
	var first
	for option in entry.choices:
		var b = button(option.label,func(): choice.emit(option.action,option.get("value",null)))
		if first == null: first = b
	button("Back to exploring · Esc / B",func(): close_modal(); dismissed.emit())
	if id == "fair_complete": button("Continue through the conservatory door", func(): choice.emit("begin_paper", null))
	if first != null: first.grab_focus()

func show_fair_config(snapshot: Dictionary, page: String = "main"):
	clear()
	modal.show()
	text("Boats with opinions",28)
	text("Rudder: %s · Sail: %s · Route: %s\nOne winding press. No timer, tapping or rank advantage." % [snapshot.fair.rudder,snapshot.fair.sail,snapshot.fair.mode],18)
	var first
	if page == "main":
		first = button("Set rudder",func(): choice.emit("fair_config","rudder"))
		button("Fold a paper sail",func(): choice.emit("fair_config","sail"))
		button("Operate, watch or work together",func(): choice.emit("fair_config","mode"))
		button("Wind and release",func(): choice.emit("release_boat",null))
	else:
		var values = {"rudder":["left","straight","right"],"sail":["triangle","square","folded"],"mode":["operate","watch","cooperate"]}
		var captions = {"left":"Left ←","straight":"Straight ↑","right":"Right →","triangle":"Triangle · catches the current","square":"Square · steady and broad","folded":"Folded · quick small sail","operate":"I'll release the boat","watch":"Mira releases; I'll watch","cooperate":"Mira and I set it together"}
		for value in values.get(page,[]):
			var b = button(captions[value],func(): choice.emit("set_" + ("race_mode" if page == "mode" else page),value))
			if first == null: first = b
		button("Back to boat setup",func(): choice.emit("fair_config","main"))
	button("Back to exploring · Esc / B",func(): close_modal(); dismissed.emit())
	if first != null: first.grab_focus()

func show_campaign_handoff():
	show_dialogue("ending")
	button("Continue to the Unfinished Fair",func(): choice.emit("begin_fair",null))
	button("Save and leave",func(): close_modal(); dismissed.emit())

func show_paper_dialogue(id: String, snapshot: Dictionary, shadow_available: bool = true):
	var entry = paper_authored.get("dialogues", {}).get(id, {})
	if entry.is_empty(): return
	clear()
	modal.show()
	text(entry.title, 28)
	var prose: String = entry.text
	if id == "paper_arrival": prose += "\n\n" + paper_authored.get("camera_callbacks", {}).get(snapshot.camera_choice, "")
	if id == "paper_raised":
		var mode_line = {"assemble":"You set the pieces on the rail; Noor holds the string while you raise it.", "direct":"Noor follows the arrangement you chose, setting each piece in its place before raising the rail.", "watch":"Mira and Noor set your chosen pieces on the rail. There is a clear spot beside the lamp to watch."}.get(snapshot.paper.mode, "")
		var fold_line = {"keep":"Mira: ‘Paper has fewer moving parts and is winning.’ Noor keeps the folded boat: ‘It casts a fine shadow.’", "wider":"Mira follows Noor’s wider fold: ‘Now it resembles a boat that has seen a boat.’", "enough":"Mira leaves her folded boat beside the drying rack: ‘A shore career, then.’"}.get(snapshot.paper.fold, "")
		prose = mode_line + "\n\n" + fold_line + "\n\n" + paper_authored.get("star_callbacks", {}).get(snapshot.paper.star, "") + "\n\n" + prose
	if id in ["paper_complete", "paper_inspect"]: prose += "\n\nYour sign: " + str(snapshot.paper.star) + " star · " + str(snapshot.paper.layout).replace("_", " / ") + " · " + str(snapshot.paper.length) + " strings."
	text(prose)
	var first
	for option in entry.choices:
		var b = button(option.label, func(): choice.emit(option.action, option.get("value", null)))
		if first == null: first = b
	if id == "paper_inspect":
		button("Close view of the physical sign", func(): choice.emit("paper_close_view", null))
		if shadow_available: button("Look at its shadow", func(): choice.emit("paper_shadow_view", null))
	button("Back to exploring · Esc / B", func(): close_modal(); dismissed.emit())
	if first != null: first.grab_focus()

func show_paper_config(snapshot: Dictionary, page: String = "main"):
	clear()
	modal.show()
	text("The hanging rail", 28)
	text("Your preview is on the worktable. Every arrangement fits the measured doorway.\n" + str(snapshot.paper.star).capitalize() + " star · " + str(snapshot.paper.length) + " strings · " + str(snapshot.paper.mode), 18)
	var first
	if page == "main":
		first = button("Arrange the shapes", func(): choice.emit("set_paper_mode", "assemble"))
		button("Choose pieces; direct Noor", func(): choice.emit("set_paper_mode", "direct"))
		button("Watch Mira and Noor make it", func(): choice.emit("set_paper_mode", "watch"))
	elif page == "watch":
		text("Name one shape to keep, or leave this preview to Mira and Noor.", 18)
		first = button("Keep the crooked star", func(): choice.emit("set_paper_star", "crooked"))
		button("Keep the clean-cut star", func(): choice.emit("set_paper_star", "clean"))
		button("Keep the empty space", func(): choice.emit("set_paper_star", "empty"))
		button("Their choice · keep the preview", func(): choice.emit("dismiss", null))
	else:
		var values = {"star":["crooked","clean","empty"], "layout":["leaf_boat_star","boat_star_leaf","star_leaf_boat"], "layout_other":["leaf_star_boat","boat_leaf_star","star_boat_leaf"], "length":["short","medium","long"], "fold":["keep","wider","enough"]}
		var labels = {"crooked":"Use Rafi’s crooked star", "clean":"Use Noor’s clean-cut star", "empty":"Leave a space for the rain", "leaf_boat_star":"Leaf · Boat · Star", "boat_star_leaf":"Boat · Star · Leaf", "star_leaf_boat":"Star · Leaf · Boat", "leaf_star_boat":"Leaf · Star · Boat", "boat_leaf_star":"Boat · Leaf · Star", "star_boat_leaf":"Star · Boat · Leaf", "short":"Short strings · a compact sky", "medium":"Medium strings · room to move", "long":"Long strings · a low horizon", "keep":"Keep Mira’s folded boat", "wider":"Try a wider fold", "enough":"We have enough pieces"}
		for value in values.get(page, []):
			var b = button(labels[value], func(): choice.emit("set_paper_" + ("layout" if page == "layout_other" else page), value))
			if first == null: first = b
		if page in ["layout", "layout_other"]: button("Other three arrangements", func(): choice.emit("paper_config", "layout_other" if page == "layout" else "layout"))
	button("Back to the room · Esc / B", func(): close_modal(); dismissed.emit())
	if first != null: first.grab_focus()

func show_kitchen_dialogue(id: String, snapshot: Dictionary):
	var entry = kitchen_authored.get("dialogues", {}).get(id, {})
	if entry.is_empty(): return
	clear()
	modal.show()
	text(entry.title, 28)
	var prose: String = entry.text
	if id in ["kitchen_arrival", "kitchen_camera"]:
		prose += "\n\n" + kitchen_authored.get("camera_callbacks", {}).get(snapshot.camera_choice, "")
	if id == "kitchen_supper":
		prose = kitchen_authored.get("mode_callbacks", {}).get(snapshot.kitchen.mode, "") + "\n\n" + prose
	if id == "kitchen_conversation":
		prose = kitchen_authored.get("exchange_callbacks", {}).get(snapshot.kitchen.exchange, "") + "\n\n" + prose
	if id == "kitchen_complete":
		prose = kitchen_authored.get("departure_callbacks", {}).get(snapshot.kitchen.departure, "") + "\n\n" + prose
	if id == "kitchen_sign":
		prose += "\n\n" + str(snapshot.paper.star).capitalize() + " star · " + str(snapshot.paper.layout).replace("_", " / ") + " · " + str(snapshot.paper.length) + " strings"
	text(prose)
	var first
	for option in entry.choices:
		var b = button(option.label, func(): choice.emit(option.action, option.get("value", null)))
		if first == null: first = b
	button("Back to exploring · Esc / B", func(): close_modal(); dismissed.emit())
	if first != null: first.grab_focus()

func show_orchard_dialogue(snapshot: Dictionary):
	var id = "orchard_arrival" if snapshot.orchard_checkpoint == "arrival" else ("orchard_complete" if snapshot.orchard_checkpoint == "complete" else "orchard_rest_" + str(snapshot.orchard.beat))
	var entry = orchard_authored.get("dialogues", {}).get(id, {})
	if entry.is_empty(): return
	clear()
	modal.show()
	text(entry.title, 28)
	var prose: String = entry.text
	if snapshot.orchard_checkpoint == "arrival":
		prose += "\n\n" + orchard_authored.get("camera_callbacks", {}).get(snapshot.camera_choice, "")
	elif snapshot.orchard_checkpoint == "rest":
		prose += "\n\n" + orchard_authored.get("route_callbacks", {}).get(snapshot.orchard.route, "")
	elif snapshot.orchard_checkpoint == "complete":
		prose += "\n\nChapter Five is complete."
	text(prose)
	var first
	for option in entry.choices:
		var b = button(option.label, func(): choice.emit(option.action, option.get("value", null)))
		if first == null: first = b
	if snapshot.orchard_checkpoint != "arrival":
		button("Look across the orchard", func(): choice.emit("orchard_view", null))
	if snapshot.orchard_checkpoint == "complete":
		button("Continue to the Return Platform", func(): choice.emit("begin_return", null))
		button("Save and leave", func(): choice.emit("orchard_leave", null))
	button("Back to exploring · Esc / B", func(): close_modal(); dismissed.emit())
	if first != null: first.grab_focus()

func show_return_dialogue(snapshot: Dictionary, id: String = ""):
	if return_authored.is_empty() and FileAccess.file_exists("res://data/return.json"):
		return_authored = JSON.parse_string(FileAccess.get_file_as_string("res://data/return.json"))
	if id.is_empty():
		id = "return_selected" if snapshot.return_checkpoint == "farewell" and snapshot.return_state.farewell != "unselected" else "return_" + snapshot.return_checkpoint
	var entry = return_authored.get("dialogues", {}).get(id, {})
	if entry.is_empty(): return
	clear()
	modal.show()
	text(entry.title, 28)
	var prose: String = entry.text
	if id == "return_arrival":
		prose += "\n\n" + return_authored.get("arrival_camera_callbacks", {}).get(snapshot.camera_choice, "")
	if snapshot.return_checkpoint in ["departed", "complete"] and id not in ["return_conductor", "return_jo"]:
		prose = return_authored.get("farewell_callbacks", {}).get(snapshot.return_state.farewell, "") + "\n\n" + prose
		prose += "\n\n" + return_authored.get("camera_callbacks", {}).get(snapshot.camera_choice, "")
	if id == "return_jo":
		var jo_history = "unselected"
		for previous in snapshot.choice_history:
			if previous == "platform_six.dialogue.umbrella_question": jo_history = "umbrella_question"
			elif previous == "platform_six.dialogue.umbrella_quiet": jo_history = "umbrella_quiet"
		prose += "\n\n" + return_authored.get("jo_history_callbacks", {}).get(jo_history, "")
	text(prose)
	# Five equal farewell choices stay visible even at 2x; long prose remains scrollable.
	modal.position.y = -285
	content.get_parent().custom_minimum_size.y = 140
	var first
	for option in entry.get("choices", []):
		var b = button(option.label, func(): choice.emit(option.action, option.get("value", null)))
		if first == null: first = b
	if snapshot.return_checkpoint == "complete":
		button("Continue home", func(): choice.emit("begin_home", null))
		button("Save and leave", func(): choice.emit("return_leave", null))
	button("Back to the platform · Esc / B", func(): close_modal(); dismissed.emit())
	if first != null: first.grab_focus()

func show_home_dialogue(snapshot: Dictionary, id: String = ""):
	if home_authored.is_empty(): return
	clear()
	modal.show()
	if snapshot.home_checkpoint == "complete":
		text("Still Here", 28)
		text(home_authored.get("endings", {}).get(snapshot.home.ending, ""))
		text(home_authored.get("credits", ""), 20)
		text(home_authored.get("availability", ""), 18)
		var first = button("Return to the apartment", func(): choice.emit("dismiss", null))
		button("Look at the room", func(): choice.emit("home_view", null))
		var unavailable = button("Journey Mode · unavailable", func(): pass)
		unavailable.disabled = true
		button("Save and leave", func(): choice.emit("home_leave", null))
		first.grab_focus()
		return
	if id.is_empty():
		id = "home_settled" if snapshot.home_checkpoint == "settled" else ("home_ritual" if snapshot.home.ticket != "unselected" else "home_arrival")
	var entry = home_authored.get("dialogues", {}).get(id, {})
	if entry.is_empty():
		modal.hide()
		return
	text(entry.title, 28)
	var prose: String = entry.text
	if id == "home_arrival": prose += "\n\n" + home_authored.get("camera_callbacks", {}).get(snapshot.camera_choice, "")
	if id == "home_ritual": prose = home_authored.get("ticket_callbacks", {}).get(snapshot.home.ticket, "") + "\n\n" + prose
	if id == "home_settled": prose = home_authored.get("ritual_callbacks", {}).get(snapshot.home.ritual, "") + "\n\n" + prose
	text(prose)
	var first
	for option in entry.get("choices", []):
		var b = button(option.label, func(): choice.emit(option.action, option.get("value", null)))
		if first == null: first = b
	button("Back to the room · Esc / B", func(): choice.emit("dismiss", null))
	button("Save and leave", func(): choice.emit("home_leave", null))
	if first != null: first.grab_focus()

func show_journey_available():
	for child in footer.get_children():
		if child is Button and child.text == "Journey Mode · unavailable":
			child.text = "PLATFORM 6 CONTINUES · Journey Mode"
			child.disabled = false
			for connection in child.pressed.get_connections(): child.pressed.disconnect(connection.callable)
			child.pressed.connect(func(): choice.emit("journey_enter",null))
