extends KinematicBody2D

export var velocidade = 100
export var gravidade = 20
var movimento = Vector2() 
var cima = Vector2(0,-1)
var direcao = -1 #direção é a direita 
var hp = 5

func _physics_process(delta):
	movimento.y += gravidade
	movimento.x = velocidade * direcao
	movimento = move_and_slide(movimento,cima)
	if is_on_wall():
		direcao = direcao * -1

func _on_levadano_area_entered(area):
	if area.name == "areadadano":
		hp -= 1
		velocidade += 100
		$AnimationPlayer.play("DANADO")
		$AudioStreamPlayer.stream = load("res://SOM CHEFAO.wav")
		$AudioStreamPlayer.play()
		if hp <= 0:
			get_tree().call_group("Player","_matouboss")
			get_tree().change_scene("res://Creditos.tscn")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "DANADO": 
		$AnimationPlayer.play("BURRADO")
