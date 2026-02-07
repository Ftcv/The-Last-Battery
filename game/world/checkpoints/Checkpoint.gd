extends Area2D

@export var enabled: bool = true

func _ready() -> void:
	# Conecta o sinal de entrada
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not enabled:
		return

	# O Player é um CharacterBody2D, que é um CollisionObject2D
	var co := body as CollisionObject2D
	if co == null:
		return

	# Verifica se quem entrou foi realmente o Player (usando sua layer definida)
	if not PhysicsLayers.overlaps(co, PhysicsLayers.PLAYER_BODY):
		return

	# CORREÇÃO: Removemos a referência à cena (cs).
	# A nova versão do Global.save_checkpoint espera apenas 1 argumento (a posição).
	Global.save_checkpoint(global_position)
