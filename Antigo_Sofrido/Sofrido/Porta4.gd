extends Node2D


func _on_Porta_body_entered(body):
	if body.name == "PlayerBody2D": #and qtd_chaves ==1 entao fase2 // se qtd ==2 entao fase3...
		get_tree().change_scene("res://Fase5.tscn")
	pass # Replace with function body.
