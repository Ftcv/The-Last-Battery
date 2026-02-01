extends Area2D

@export var enabled: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not enabled:
		return

	var co := body as CollisionObject2D
	if co == null:
		return



	if not PhysicsLayers.overlaps(co, PhysicsLayers.PLAYER_BODY):
		return

	var cs := get_tree().current_scene
	if cs == null:
		return


	Global.save_checkpoint(cs.scene_file_path, global_position)
