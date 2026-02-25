extends KinematicBody2D

var movimento = Vector2()
export var velocidade_de_rotacao = 2
export var degraus = 0


func _physics_process(delta):
	#rotation += direcao * velocidade_de_rotacao * delta
	degraus += 1 * delta
	movimento = Vector2(cos(degraus),sin(degraus)).normalized()*200
	movimento = move_and_slide(movimento) 
	

func _on_Area2D_area_entered(area):
	if area.name == "areadadano":
		get_tree().call_group("Player","_matouinimigo")
		queue_free()

