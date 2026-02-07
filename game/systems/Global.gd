extends Node

# O slot atual carregado (0, 1, 2...)
var current_slot_index: int = 0

# A sessão atual em memória
var session: SessionData = SessionData.new()

# Caminho base para salvar: user://save_slot_0.tres
const SAVE_PATH_TEMPLATE: String = "user://save_slot_%d.tres"

# --- API DE SALVAMENTO ---

# Salva o jogo no slot atual imediatamente
func save_game() -> void:
	session.last_played_date = Time.get_datetime_string_from_system()
	
	var path = SAVE_PATH_TEMPLATE % current_slot_index
	var error = ResourceSaver.save(session, path)
	
	if error == OK:
		print("Jogo salvo com sucesso no Slot ", current_slot_index)
	else:
		push_error("Erro ao salvar jogo: ", error)

# Carrega um slot específico para a memória
func load_game(slot_index: int) -> bool:
	var path = SAVE_PATH_TEMPLATE % slot_index
	if ResourceLoader.exists(path):
		var loaded_data = ResourceLoader.load(path)
		if loaded_data is SessionData:
			session = loaded_data
			current_slot_index = slot_index
			# Resetamos checkpoint ao carregar do disco (design choice estilo Mario)
			session.has_checkpoint = false 
			return true
	return false

# Cria um jogo novo num slot específico
func create_new_game(slot_index: int) -> void:
	current_slot_index = slot_index
	session = SessionData.new()
	session.reset_to_new_game()
	save_game() # Já cria o arquivo no disco

# Verifica se existe save num slot (útil para o Menu UI)
func save_exists(slot_index: int) -> bool:
	var path = SAVE_PATH_TEMPLATE % slot_index
	return ResourceLoader.exists(path)

# Deleta um save (opcional)
func delete_save(slot_index: int) -> void:
	var path = SAVE_PATH_TEMPLATE % slot_index
	if ResourceLoader.exists(path):
		DirAccess.remove_absolute(path)

# --- API DE CHECKPOINT (Mantida, mas apenas em RAM) ---
func save_checkpoint(world_pos: Vector2) -> void:
	session.has_checkpoint = true
	session.checkpoint_position = world_pos

func reset_checkpoint_ram() -> void:
	session.has_checkpoint = false
