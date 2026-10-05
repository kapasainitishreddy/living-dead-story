extends "res://characters/character_performer.gd"
# Authored supporting bodies share the production rig. Existing chapter pivots
# remain the authority for serving, carrying and seated poses, without showing
# the retired primitive meshes or changing story/collision root transforms.
var stage_owner: Node3D
var stage_handles: Dictionary = {}
var seated_offset := 0.0
var game_owner: Node
var world_owner: Node
const RETIRED_ACCESSORIES = ["WorkApron","PracticalWorkApron","PracticalApron","ApronPocket","SpectacleBridge","GlassesBridge","RolledSleeve","ConductorCap","BreadPocket","SeatedShin"]
func _ready():
 super._ready()
 elapsed = float(abs(character_id.hash()) % 500) / 50.0
 for side in ["Left","Right"]:
  for part in ["UpperArm","Forearm","Hand","Thigh","Shin","Foot"]:
   bones[part+side]=_bone_index(part+side)
 for id in ["ArmLeft","ArmRight","LegLeft","LegRight"]:
  stage_handles[id] = stage_owner.get_node_or_null(id)
 var ancestor: Node=stage_owner
 while ancestor != null:
  if ancestor.has_method("show_pause") and ancestor.has_method("configure_characters"): game_owner=ancestor
  if ancestor.has_method("set_paused"): world_owner=ancestor
  ancestor=ancestor.get_parent()
 call_deferred("_settle_accessories")
func _settle_accessories():
 # Those former rigid decorations are now part of the skinned original costume.
 # Meaningful props (umbrella, crate, paper star, bread) stay with the chapter.
 for handle in stage_owner.get_children():
  if handle.get_meta("legacy_staging_handle",false): handle.hide()
 if str(stage_owner.name) == "World": return
 for child in stage_owner.get_children():
  if str(child.name) in RETIRED_ACCESSORIES or (child is MeshInstance3D and (str(child.name)=="MeshInstance3D" or str(child.name).begins_with("@MeshInstance3D@"))):
   child.hide()
 # Use the actual authored seat height; never move its collision or story owner.
 if str(stage_owner.name) == "Jo": seated_offset=-0.22
 elif str(stage_owner.name).contains("SeatedRider"):
  seated_offset=-0.46 if str(stage_owner.get_parent().name)=="StationBench" else -0.10
func _presentation_paused() -> bool:
 if is_instance_valid(game_owner): return game_owner.hud.pause_active
 if is_instance_valid(world_owner): return bool(world_owner.get("paused"))
 return false
func _process(delta: float):
 if not _presentation_paused(): advance_performance(delta)
func apply_preferences(reduced: bool):
 if _presentation_paused():
  # Apply the preference on resume, preserving the complete frozen pose now.
  reduced_motion=reduced
  secondary_motion_weight=0.0 if reduced else 1.0
  return
 super.apply_preferences(reduced)
 _apply_stage_pose()
func advance_performance(delta: float):
 super.advance_performance(delta)
 _apply_stage_pose()
func _apply_stage_pose():
 if skeleton == null: return
 for side in ["Left","Right"]:
  var arm=stage_handles.get("Arm"+side)
  if is_instance_valid(arm):
   _offset_bone("UpperArm"+side,arm.rotation.y,arm.rotation.x,arm.rotation.z)
  var leg=stage_handles.get("Leg"+side)
  if is_instance_valid(leg) and abs(leg.rotation.x)>0.5:
   _offset_bone("Thigh"+side,leg.rotation.y,leg.rotation.x,leg.rotation.z)
   # On the raised cart, calves tuck beneath the seat and soles stay above
   # its deck. The ordinary station bench keeps the vertical shin pose.
   var tuck=0.85 if str(stage_owner.get_parent().name)=="Cart" else 0.0
   _offset_bone("Shin"+side,0,-leg.rotation.x+tuck)
   _offset_bone("Foot"+side,0,0.08-tuck)
 if model: model.position.y=seated_offset
