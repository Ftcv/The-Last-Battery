extends Node

# LLM_HINT: Autoload SceneManager = autoridade única para troca de cenas.

var _current_scene_path: String = ""

func _ready() -> void:
	_sync_current_scene_path()

func _sync_current_scene_path() -> void:
	var cs := get_tree().current_scene
	if cs != null:
		_current_scene_path = cs.scene_file_path

func goto_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		push_error("SceneManager.goto_scene: scene_path vazio.")
		return
	_current_scene_path = scene_path
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneManager.goto_scene falhou. Error=%s path=%s" % [err, scene_path])

func reload_current() -> void:
	_sync_current_scene_path()
	if _current_scene_path.is_empty():
		push_error("SceneManager.reload_current: sem cena atual.")
		return
	get_tree().change_scene_to_file(_current_scene_path)

func start_new_game(first_level_path: String) -> void:
	Global.reset_session()
	goto_scene(first_level_path)

func quit_game() -> void:
	get_tree().quit()
