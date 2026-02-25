extends KinematicBody2D


export (Vector2) var velocidade

func _physics_process(delta):
	var colisao = move_and_collide(velocidade * delta)
	if colisao: 
		velocidade = velocidade.bounce(colisao.normal)
