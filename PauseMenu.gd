extends CanvasLayer

# -----------------------------------------------------------------------------
# REFERÊNCIAS DE NÓS (Baseadas na sua imagem)
# -----------------------------------------------------------------------------
# O MenuOptions é filho do Background
@onready var menu_options: Control = $Background/MenuOptions

# Botões Principais
@onready var btn_resume: Button = $Background/MenuOptions/BtnResume
@onready var btn_options: Button = $Background/MenuOptions/BtnOptions
@onready var btn_map: Button = $Background/MenuOptions/BtnMap
@onready var btn_quit: Button = $Background/MenuOptions/BtnQuit


# -----------------------------------------------------------------------------
# CONSTANTES DE ARQUIVO (Corrigidas para Maiúsculas)
# -----------------------------------------------------------------------------
# O erro dizia que não achava "main_menu.tscn", então mudamos para "MainMenu.tscn"
const MAIN_MENU_PATH: String = "res://game/ui/MainMenu.tscn"

# Assumindo que você criará (ou criou) o mapa como "WorldMap.tscn"
# Se o arquivo ainda não existe, crie uma Cena de Interface vazia e salve com este nome.
const MAP_SCENE_PATH: String = "res://game/ui/WorldMap.tscn"

# -----------------------------------------------------------------------------
# CICLO DE VIDA
# -----------------------------------------------------------------------------
func _ready() -> void:
	# Configuração Inicial
	visible = false
	menu_options.visible = true
	
	# CRÍTICO: Permite que o menu funcione enquanto o jogo está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Conexão Segura de Sinais
	_connect_btn(btn_resume, _on_resume_pressed)
	_connect_btn(btn_options, _on_options_pressed)
	_connect_btn(btn_map, _on_map_pressed)
	_connect_btn(btn_quit, _on_quit_pressed)
	

# Helper para evitar erros de conexão duplicada
func _connect_btn(btn: Button, method: Callable) -> void:
	if btn.pressed.is_connected(method):
		btn.pressed.disconnect(method)
	btn.pressed.connect(method)

# -----------------------------------------------------------------------------
# INPUT (TECLA START / ESC)
# -----------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Start"):
			_toggle_pause()
			get_viewport().set_input_as_handled()

# -----------------------------------------------------------------------------
# LÓGICA DE PAUSE
# -----------------------------------------------------------------------------
func _toggle_pause() -> void:
	var is_paused: bool = not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused
	
	if is_paused:
		# Entrando no Pause
		menu_options.visible = true
		btn_resume.grab_focus() # Foco para Gamepad/Teclado

# -----------------------------------------------------------------------------
# FUNÇÕES DOS BOTÕES
# -----------------------------------------------------------------------------
func _on_resume_pressed() -> void:
	_toggle_pause()

func _on_options_pressed() -> void:
	print("Log: Botão Opções pressionado")
	# Futuro: Instanciar cena de opções aqui

func _on_map_pressed() -> void:
	# IMPORTANTE: Despausar antes de mudar de cena
	_toggle_pause()
	
	if SceneManager.has_method("goto_scene"):
		SceneManager.goto_scene(MAP_SCENE_PATH)
	else:
		# Fallback se não tiver SceneManager (mas você tem)
		get_tree().change_scene_to_file(MAP_SCENE_PATH)

func _on_quit_pressed() -> void:
	# CRÍTICO: Despausar a árvore de cena antes de sair
	get_tree().paused = false
	
	if SceneManager.has_method("goto_scene"):
		SceneManager.goto_scene(MAIN_MENU_PATH)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
