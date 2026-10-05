extends Node
# Original Godot implementation of small asynchronous environmental motion.
# Reference: Sakura Crossing cat idle and petals, MIT © 2026 Kenton Wang.
var reduced := false
var elapsed := 0.0
var sways: Array = []
var waters: Array = []
var weather: Array = []
func _ready():
	for node in get_parent().find_children("*","Node3D",true,false):
		if node.name in ["UmbrellaCanopy","Steam"]:
			sways.append({"node":node,"rest":node.rotation,"phase":float(sways.size())*1.7})
		if node.name == "Rain" or node.name == "Steam": weather.append(node)
		if node.name == "Water": waters.append(node.get_child(0).material_override)
func apply_preferences(value: bool):
	reduced = value
	for node in weather: node.visible = not reduced
	for material in waters: material.set_shader_parameter("motion_scale",0.0 if reduced else 1.0)
	for item in sways:
		if is_instance_valid(item.node): item.node.rotation = item.rest
func _process(delta):
	if reduced: return
	elapsed += delta
	for item in sways:
		if is_instance_valid(item.node):
			item.node.rotation.z = item.rest.z + sin(elapsed*0.7+item.phase)*0.012
