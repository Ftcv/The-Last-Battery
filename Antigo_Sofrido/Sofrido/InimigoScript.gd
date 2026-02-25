extends KinematicBody2D

export var velocidade = 100
export var gravidade = 10
var movimento = Vector2() 
var cima = Vector2(0,-1)
var direcao = -1 #direção é a direita 


func _physics_process(delta):
	movimento.y += gravidade
	movimento.x = velocidade * direcao
	movimento = move_and_slide(movimento,cima)

	if is_on_wall():
		direcao = direcao * -1
		$RayCast2D.position.x = 10*direcao
	if is_on_floor():
		if $RayCast2D.is_colliding() == false: 
			direcao = direcao * -1
			$RayCast2D.position.x = 10*direcao



func _on_levadano_area_entered(area):
	if area.name == "areadadano":
		get_tree().call_group("Player","_matouinimigo")
		queue_free()

