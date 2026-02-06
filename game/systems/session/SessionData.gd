# res://game/systems/session/SessionData.gd
extends Resource
class_name SessionData

@export var lives: int = 3
@export var battery: int = 3      # Bateria atual (HP)
@export var max_battery: int = 3  # Bateria máxima (Capacidade)

@export var has_checkpoint: bool = false
@export var checkpoint_scene: String = ""
@export var checkpoint_position: Vector2 = Vector2.ZERO

func reset_to_defaults() -> void:
	lives = 3
	battery = 3
	max_battery = 3
	has_checkpoint = false
	checkpoint_scene = ""
	checkpoint_position = Vector2.ZERO
