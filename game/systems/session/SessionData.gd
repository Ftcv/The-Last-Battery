extends Resource
class_name SessionData

# Dados vitais
@export var battery: int = 3
@export var max_battery: int = 3
@export var current_level_path: String = "res://game/levels/world1/level_1.tscn" # Fase atual/desbloqueada

# Metadados para o Menu (opcional, mas bom pra UI)
@export var last_played_date:String = ""
@export var percent_complete: int = 0

# Checkpoints (não costumam ser salvos entre sessões em jogos estilo Mario, 
# mas se quiser manter, exporte-os. Aqui vou resetá-los ao carregar para evitar bugs)
var has_checkpoint: bool = false
var checkpoint_position: Vector2 = Vector2.ZERO

func reset_to_new_game() -> void:
	battery = 3
	max_battery = 3
	current_level_path = "res://game/levels/world1/level_1.tscn" # Caminho da sua primeira fase
	percent_complete = 0
	has_checkpoint = false
