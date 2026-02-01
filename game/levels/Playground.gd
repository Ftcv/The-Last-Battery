extends Node2D

@export var player_path: NodePath

func _ready() -> void:
	var player := _get_player()
	if player == null:
		# print("Playground: Player não encontrado.")
		return

	# print("Playground: has_checkpoint=", Global.session.has_checkpoint)

	if Global.session.has_checkpoint:
		player.global_position = Global.session.checkpoint_position

func _get_player() -> Node2D:
	if player_path != NodePath():
		var n := get_node_or_null(player_path)
		if n is Node2D:
			return n

	# fallback (menos confiável)
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Node2D:
		return players[0] as Node2D

	return null
