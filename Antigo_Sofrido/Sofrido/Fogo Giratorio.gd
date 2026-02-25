extends Node2D

var foguin_filho = preload("res://foguin_filho.tscn")
var velocidade = Vector2()
export var velocidade_de_rotacao = 2
var direcao = 1
export var qtd = 5
export var distancia = 20

func _ready():
	for i in range(qtd):
		var instancia = foguin_filho.instance()
		instancia.position.x = distancia + distancia*i 
		self.add_child(instancia)
func _physics_process(delta):
	rotation += direcao * velocidade_de_rotacao * delta

	
