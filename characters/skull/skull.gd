extends CharacterBody2D

@export var velocidade := 60
@onready var animation := $AnimatedSprite2D
@onready var attack_area := $Area2D  # Certifique-se de que existe

var max_life := 30
var current_life := 30
var player: Node2D = null
var can_attack := true

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


func _attack():
	if can_attack:
		can_attack = false
		$AttackArea.monitoring = true
		animation.play("attack")
		await get_tree().create_timer(0.4).timeout  # Tempo da animação
		$AttackArea.monitoring = false
		can_attack = true

func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and can_attack:
		body.take_damage(10)  # Chama a função no player

func take_damage(value: int) -> void:
	current_life -= value
	if current_life <= 0:
		die()

func die():
	queue_free()
