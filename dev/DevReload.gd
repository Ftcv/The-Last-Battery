extends Node
class_name DevReload

@export var action_reload: StringName = &"ui_r"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(action_reload):
		get_tree().call_deferred("reload_current_scene")
