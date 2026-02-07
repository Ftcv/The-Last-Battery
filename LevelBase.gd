extends Node2D
class_name LevelBase

# Caminho da próxima fase
@export_file("*.tscn") var next_level_scene: String = ""

# --- CORREÇÃO AQUI: Ajuste para "GamePlay" com P maiúsculo ---
@onready var player: CharacterBody2D = $GamePlay/Player
@onready var player_start: Marker2D = $GamePlay/PlayerStart
@onready var death_zone: Area2D = $DeathZone

func _ready() -> void:
	# Verificação de segurança: Só tenta mover se os nós existirem
	if player and player_start:
		player.global_position = player_start.global_position
	else:
		push_warning("LevelBase: Player ou PlayerStart não encontrados em GamePlay.")
	
	if death_zone:
		# Desconecta antes de conectar para evitar erros de reload
		if death_zone.body_entered.is_connected(_on_death_zone_body_entered):
			death_zone.body_entered.disconnect(_on_death_zone_body_entered)
		death_zone.body_entered.connect(_on_death_zone_body_entered)

func _on_death_zone_body_entered(body: Node2D) -> void:
	if body == player:
		if player.has_method("take_damage"):
			player.take_damage(999, 0) 
		elif player.has_method("die"):
			player.die()
