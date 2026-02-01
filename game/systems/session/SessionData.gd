extends Resource
class_name SessionData

# LLM_HINT: Sessão tipada para evitar dicionários soltos e retrabalho futuro (save/load).

@export var lives: int = 3
@export var battery: int = 100

@export var has_checkpoint: bool = false
@export var checkpoint_scene: String = ""
@export var checkpoint_position: Vector2 = Vector2.ZERO

func reset_to_defaults() -> void:
	lives = 3
	battery = 100
	has_checkpoint = false
	checkpoint_scene = ""
	checkpoint_position = Vector2.ZERO
