# MainMenu.gd
extends Control
@export var new_game_scene: String = "res://game/levels/Playground.tscn"

@onready var menu_vbox: VBoxContainer = $CenterContainer/MenuVBox
@onready var options_menu = $OptionsMenu

@onready var btn_new: Button = $CenterContainer/MenuVBox/NewGameButton
@onready var btn_load: Button = $CenterContainer/MenuVBox/LoadGameButton
@onready var btn_options: Button = $CenterContainer/MenuVBox/OptionsButton
@onready var btn_quit: Button = $CenterContainer/MenuVBox/QuitButton

@onready var music: AudioStreamPlayer = $MenuMusic
@onready var sfx_move: AudioStreamPlayer = $MenuSfxMove
@onready var sfx_select: AudioStreamPlayer = $MenuSfxConfirm

var _busy := false # Pra evita double press (Enquanto _busy for true, o menu ignora novos inputs.)

func _on_any_button_focused() -> void:
	if _busy:
		return
	sfx_move.stop()
	sfx_move.play()


func _ready():
	music.play()
# Foco inicial pra navegar no teclado/controle
	btn_new.grab_focus.call_deferred()

	# Garante estado inicial correto
	menu_vbox.visible = true
	options_menu.visible = false
	
# SFX ao mudar seleção: toca quando o botão recebe foco
	btn_new.focus_entered.connect(_on_any_button_focused)
	btn_load.focus_entered.connect(_on_any_button_focused)
	btn_options.focus_entered.connect(_on_any_button_focused)
	btn_quit.focus_entered.connect(_on_any_button_focused)
	
	# Quando o OptionsMenu fechar, restaura o menu principal
	options_menu.closed.connect(_on_options_closed)

func _set_buttons_enabled(enabled: bool) -> void:
	btn_new.disabled = not enabled
	btn_options.disabled = not enabled
	btn_quit.disabled = not enabled
	
func _play_confirm_and_wait() -> void:
	sfx_select.stop()
	sfx_select.play()
	await sfx_select.finished

func _on_new_game_button_pressed() -> void:
	if _busy:
		return
	_busy = true
	_set_buttons_enabled(false)
	await _play_confirm_and_wait()
	SceneManager.start_new_game(new_game_scene)


func _on_load_game_button_pressed() -> void:
	# placeholder
	if _busy:
		return
	_busy = true
	_set_buttons_enabled(false)
	await _play_confirm_and_wait()
	_busy = false
	_set_buttons_enabled(true)



func _on_options_button_pressed() -> void:
	# placeholder
	if _busy:
		return
	_busy = true
	_set_buttons_enabled(false)
	await _play_confirm_and_wait()
	_busy = false
	_set_buttons_enabled(true)

	# Some o menu de botões e abre o OptionsMenu por cima
	menu_vbox.visible = false
	options_menu.open()
	# Não libera _busy aqui: só libera quando o Options fechar

func _on_options_closed() -> void:
	menu_vbox.visible = true
	_busy = false
	_set_buttons_enabled(true)
	btn_options.grab_focus.call_deferred()

func _on_quit_button_pressed() -> void:
	if _busy:
		return
	_busy = true
	_set_buttons_enabled(false)
	await _play_confirm_and_wait()
	SceneManager.quit_game()
