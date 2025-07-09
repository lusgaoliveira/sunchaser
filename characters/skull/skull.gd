extends CharacterBody2D

@export var velocidade := 60
@onready var animation := $AnimatedSprite2D
@onready var attack_area := $Area2D  
@onready var barra_de_vida: ProgressBar = $ProgressBar

var knockback_velocity := Vector2.ZERO
var is_knockback := false
var max_health := 100
var health := 100
var player: Node2D = null
var can_attack := true

func _ready():
	add_to_group("skulls")
	await get_tree().process_frame  
	_set_player()

func _set_player():
	var players = get_tree().get_nodes_in_group("player")

	if players.size() > 0:
		player = players[0]
	else:
		call_deferred("_set_player")

		
func _physics_process(_delta) -> void:
	if is_knockback:
		velocity = knockback_velocity
		move_and_slide()
		return
	
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
		await get_tree().create_timer(0.4).timeout  
		$AttackArea.monitoring = false
		can_attack = true

func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and can_attack:
		body.take_damage(5, global_position)
		
func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force
	is_knockback = true
	await get_tree().create_timer(0.15).timeout
	is_knockback = false

func take_damage(amount: int, attacker_pos: Vector2 = global_position) -> void:
	health -= amount
	barra_de_vida.value = health

	# Aplicar knockback
	var dir = (global_position - attacker_pos).normalized()
	apply_knockback(dir * 200)

	if health <= 0:
		die()


func die() -> void:
	queue_free()
