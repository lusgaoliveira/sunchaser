extends CharacterBody2D

@export var velocidade := 60
@onready var animation := $AnimatedSprite2D

var max_life := 30
var current_life := 30
var player: Node2D = null

func _ready():
	add_to_group("skulls")
	await get_tree().process_frame  
	_set_player()


	
func _set_player():
	var players = get_tree().get_nodes_in_group("player")
	print("Tentando achar player, achou:", players.size())
	for p in players:
		print("Player encontrado:", p.name, p.global_position)

	if players.size() > 0:
		player = players[0]
	else:
		print("Nenhum player encontrado. Tentando de novo em breve.")
		call_deferred("_set_player")

		
func _physics_process(_delta) -> void:
	if player and is_instance_valid(player):
		var direcao := player.global_position - global_position
		var distancia := direcao.length()

		if distancia > 10:
			velocity = direcao.normalized() * velocidade
		else:
			velocity = Vector2.ZERO

		move_and_slide()



func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(10)  # Cria no player essa função

func take_damage(value: int) -> void:
	current_life -= value
	if current_life <= 0:
		die()

func die():
	queue_free()
