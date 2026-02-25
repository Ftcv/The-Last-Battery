extends Node2D

onready var player = $Player/PlayerBody2D
onready var hud = $Hud

# Called when the node enters the scene tree for the first time.
func _physics_process(delta):
	hud._vida(player.vida) 
	if Input.is_action_pressed("r"): 
		get_tree().reload_current_scene()

func _tocarmusica(): 
	$AudioStreamPlayer.stream = load("res://FASE2-MUSICA.ogg")
	$AudioStreamPlayer.play()


