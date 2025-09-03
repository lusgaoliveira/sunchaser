extends CharacterBody2D

signal cmon_died

@export var velocidade := 60
@onready var animation := $AnimatedSprite2D
@onready var attack_area:= $Area2D
@onready var barra_de_vida: ProgressBar = $barra_de_vida

@onready var som_ataque := $som_ataque
@onready var som_dano := $som_dano
@onready var som_morte := $som_morte
@onready var som_setar := $som_setar

var knockback_velocity := Vector2.ZERO
var is_knockback := false
var is_dead := false
var max_health := 100
var health := 100
var player: Node2D = null
var is_attacking := false
var attack_cooldown := false
var can_attack := true

func _ready():
	randomize()
	attack_area.monitoring = false
	add_to_group("cdmon")
	await get_tree().process_frame  
	som_setar.play()
	_set_player()

func _set_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		await get_tree().process_frame
		_set_player()

func _physics_process(_delta) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	if is_knockback:
		velocity = knockback_velocity
		move_and_slide()
		return

	if player and is_instance_valid(player):
		var direcao := player.global_position - global_position
		var distancia := direcao.length()

		if distancia > 25:
			velocity = direcao.normalized() * velocidade
			
			# Definir animação de movimento
			if abs(direcao.x) > abs(direcao.y):
				animation.animation = "right" if direcao.x > 0 else "left"
			else:
				animation.animation = "front" if direcao.y > 0 else "back"

			animation.play()
		else:
			velocity = Vector2.ZERO
			can_attack = true
			_attack()

		move_and_slide()

func _attack():
	if not is_dead and not is_attacking:
		is_attacking = true
		animation.play("attack")
		som_ataque.play()
		
		# Ativa a área de colisão durante o ataque
		await get_tree().create_timer(0.2).timeout
		attack_area.monitoring = true
		await get_tree().create_timer(0.2).timeout
		attack_area.monitoring = false
		
		await animation.animation_finished
		is_attacking = false
		
		# Cooldown entre ataques
		attack_cooldown = true
		await get_tree().create_timer(1.0).timeout
		attack_cooldown = false

func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and is_attacking and not is_dead:
		body.take_damage(25, global_position)
		print("Dano aplicado ao player!")
		
func apply_knockback(force: Vector2) -> void:
	if is_dead:
		return
	knockback_velocity = force
	is_knockback = true
	await get_tree().create_timer(0.15).timeout
	is_knockback = false

func take_damage(amount: int, attacker_pos: Vector2 = global_position) -> void:
	if is_dead:
		return

	health -= amount
	barra_de_vida.value = health
	som_dano.play()
	var dir = (global_position - attacker_pos).normalized()
	apply_knockback(dir * 220)

	if health <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	animation.animation = "died"
	som_morte.play()
	animation.play()
	await get_tree().create_timer(1.5).timeout
	emit_signal("cmon_died", self)
	queue_free()
