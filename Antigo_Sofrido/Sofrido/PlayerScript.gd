extends KinematicBody2D

var velocidade = 200
var gravidade = 10
var movimento = Vector2() # O vetor de movimento
var velpulo = -300
var cima = Vector2(0,-1) #diz ao jogo onde fica "cima"
var vida_max = 10
var estado = AFK
var vida = 2
var tempoin = 0
var tempoin_max = 60
var invencivel = 0
var score = 0
onready var player = $PlayerBody2D



enum{AFK,CORRENDO,PULANDO,MACHUCADO,MORTO,ESCALANDO}


func _conseguirvida(): 
	vida +=1
	$AudioStreamPlayer.stream = load("res://coracaosom.wav")
	$AudioStreamPlayer.play()
	
func _matouinimigo():
	score +=10
	$AudioStreamPlayer.stream = load("res://dano no inimigo.wav")
	$AudioStreamPlayer.play()
	
func _matouchefao():
	score +=100
	$AudioStreamPlayer.stream = load("res://dano no inimigo.wav")
	$AudioStreamPlayer.play()
	
func _matouboss():
	$AudioStreamPlayer.stream = load("res://SOM CHEFAO.wav")
	$AudioStreamPlayer.play()
	score +=1000

	

func _physics_process(delta):
	movimento.y += gravidade
	print (vida)
	if is_on_floor():
		velocidade = 200
		if Input.is_action_just_pressed("ui_pulo"):
			movimento.y = velpulo
			$AudioStreamPlayer.stream = load("res://pulo.wav")
			$AudioStreamPlayer.play()
		if Input.is_action_pressed("ui_y"):
			velocidade = 300
	else:	
		if movimento.y < 0:
			if Input.is_action_just_released("ui_pulo"):
				movimento.y = movimento.y/3
			
	if Input.is_action_pressed("ui_right"): 
		movimento.x = velocidade
	elif Input.is_action_pressed("ui_left"): 
		movimento.x = -velocidade
	else:
		movimento.x = 0
	
	if is_on_floor() and not Input.is_action_just_pressed("ui_pulo"):
		movimento.y = 30 
	movimento = move_and_slide(movimento,cima)
	
	if invencivel == 1:
		tempoin += 1
	if tempoin == tempoin_max:
		invencivel = 0
	
	if position.y > 9840:
		 get_tree().reload_current_scene()

func _on_areamachuca_area_entered(area):
	if invencivel == 0 :
		vida -= 1
		$AnimationPlayer.play("DANADO")
		$AudioStreamPlayer.stream = load("res://receberdano.wav")
		$AudioStreamPlayer.play()
		tempoin = 0 
		invencivel = 1
		if vida <= 0:
			get_tree().reload_current_scene()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "DANADO": 
		$AnimationPlayer.play("BURRADO")
