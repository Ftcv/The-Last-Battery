extends Node

# LLM_HINT: Autoload Global = fonte única de verdade da sessão.
var session: SessionData = SessionData.new()

func reset_session() -> void:
	session.reset_to_defaults()

func save_checkpoint(scene_path: String, world_pos: Vector2) -> void:
	session.has_checkpoint = true
	session.checkpoint_scene = scene_path
	session.checkpoint_position = world_pos

func clear_checkpoint() -> void:
	session.has_checkpoint = false
	session.checkpoint_scene = ""
	session.checkpoint_position = Vector2.ZERO
