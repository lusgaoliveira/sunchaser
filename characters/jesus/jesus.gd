extends CharacterBody2D

@export var velocidade := 80

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area := $Area2D
@onready var barra_de_vida: ProgressBar = $barra_de_vida

var knockback_velocity := Vector2.ZERO
var is_knockback := false
var is_dead := false
var is_passive := true   
var max_health := 550
var health := 550

var player: Node2D = null
var can_attack := true


func _ready():
	randomize()
	add_to_group("jesus")
	barra_de_vida.max_value = max_health
	barra_de_vida.value = health
	animation.animation = "initial"  
	animation.play()
	_set_player()


func _set_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		call_deferred("_set_player")


func _physics_process(_delta: float) -> void:
	if is_dead or is_passive:
		velocity = Vector2.ZERO
		return

	if is_knockback:
		velocity = knockback_velocity
		move_and_slide()
		return

	if player and is_instance_valid(player):
		var direcao := player.global_position - global_position
		var distancia := direcao.length()

		if distancia > 40:  # segue o player
			velocity = direcao.normalized() * velocidade
			_play_move_animation(direcao)
		else:
			velocity = Vector2.ZERO
			_play_attack()
		
		move_and_slide()


func _play_move_animation(direcao: Vector2) -> void:
	if abs(direcao.x) > abs(direcao.y):
		animation.animation = "right" if direcao.x > 0 else "left"
	else:
		animation.animation = "front" if direcao.y > 0 else "back"
	animation.play()


func _play_attack() -> void:
	if not can_attack or is_dead:
		return
	
	can_attack = false

	# alterna entre attack e attack2
	animation.animation = ["attack", "attack2"][randi() % 2]
	animation.play()

	# ativa hitbox para causar dano
	attack_area.monitoring = true

	# duração do ataque
	await get_tree().create_timer(0.5).timeout
	attack_area.monitoring = false

	# cooldown
	await get_tree().create_timer(0.5).timeout
	can_attack = true


func apply_knockback(force: Vector2) -> void:
	if is_dead:
		return
	knockback_velocity = force
	is_knockback = true
	await get_tree().create_timer(0.20).timeout
	is_knockback = false


func take_damage(amount: int, attacker_pos: Vector2 = global_position) -> void:
	if is_dead:
		return

	health -= amount
	barra_de_vida.value = health

	var dir = (global_position - attacker_pos).normalized()
	apply_knockback(dir * 220)

	if health <= 0:
		die()


func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	animation.animation = "died"
	animation.play()
	await get_tree().create_timer(2.0).timeout
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_passive:
		is_passive = false   
	if body.is_in_group("player") and not is_passive and can_attack == false:
		if attack_area.monitoring:
			body.take_damage(25, global_position)
