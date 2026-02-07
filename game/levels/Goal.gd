# No script do seu objeto de Final de Fase (Goal.gd)
@export var next_level_scene: String # Caminho da proxima fase, ex: "res://game/levels/level_2.tscn"

func _on_body_entered(body: Node2D):
	if body.name == "Player":
		# 1. Atualiza a sessão com a próxima fase
		if next_level_scene != "":
			Global.session.current_level_path = next_level_scene
		
		# 2. Recupera vida ou dá bonus (opcional)
		
		# 3. SALVA NO DISCO AUTOMATICAMENTE
		Global.save_game()
		
		# 4. Muda de cena
		SceneManager.goto_scene(Global.session.current_level_path)
