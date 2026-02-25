extends Area2D



func _on_Coletavel_body_entered(body):
	if body.name == "PlayerBody2D": 
		get_tree().call_group("Player","_conseguirvida")
		queue_free()

