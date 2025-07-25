extends CharacterBody2D

@onready var animation := $AnimatedSprite2D as AnimatedSprite2D
@onready var attack_area: Area2D = $hitbox
@onready var barra_de_vida: ProgressBar = $barra_de_vida
@onready var barra_de_sol: ProgressBar = $barra_de_sol

const SPEED = 150.0

var last_direction := ""
var max_health := 100
var health := 100
var is_attacking := false
var knockback_velocity := Vector2.ZERO
var is_knockback := false

var max_sun_energy := 100
var sun_energy := 100

func _ready() -> void:
	
	# Restaura a vida e posição do player a partir do GameState
	health = GameState.player_stats.get("health", health)
	sun_energy = GameState.player_stats.get("sun_energy", sun_energy)
	
	
	barra_de_vida.max_value = max_health
	barra_de_vida.value = health
	
	barra_de_sol.max_value = max_sun_energy
	barra_de_sol.value = sun_energy
	
	add_to_group("player")

func _physics_process(_delta) -> void:
	if is_knockback:
		velocity = knockback_velocity
		move_and_slide()
		return

	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	if not is_attacking:
		velocity = input_vector * SPEED
		move_and_slide()
		play_animation(input_vector)

	if Input.is_action_just_pressed("attack") and not is_attacking:
		perform_attack()
		
	if Input.is_action_just_pressed("recover_health") and not is_attacking and not is_knockback:
		if sun_energy >= 10:
			recover_health(15)  
			use_sun_energy(10)
		
	if Input.is_action_just_pressed("recover_sun_energy") and not is_attacking:
		recover_sun(10)



func play_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		# Ainda nao tenho animacao parado
		last_direction = "stop"
	else:
		if direction.y > 0:
			last_direction = "front"
		elif direction.y < 0:
			last_direction = "back"
		elif direction.x > 0:
			last_direction = "left"
		elif direction.x < 0:
			last_direction = "right"
		else:
			last_direction = "stop"


		animation.animation = last_direction
		animation.play()

func perform_attack() -> void:
	is_attacking = true

	# Toca animação
	if velocity.y > 0:
		animation.animation = "attack"
	elif velocity.y < 0 or velocity.x != 0:
		animation.animation = "attack2"
	else:
		animation.animation = "attack"

	animation.play()

	attack_area.monitoring = true
	await get_tree().create_timer(0.1).timeout

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("skulls"):
			body.take_damage(25, global_position)  

	attack_area.monitoring = false

	# Espera fim da animação
	await get_tree().create_timer(1).timeout
	is_attacking = false
	play_animation(velocity.normalized())

func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force
	is_knockback = true
	await get_tree().create_timer(0.15).timeout
	is_knockback = false
	
func take_damage(amount: int, attacker_pos: Vector2 = global_position) -> void:
	health -= amount
	barra_de_vida.value = health

	print("Player tomou dano! Vida atual: %d" % health)

	# Aplica knockback
	var dir = (global_position - attacker_pos).normalized()
	apply_knockback(dir * 220)

	if health <= 0:
		die()

func use_sun_energy(amount: int):
	sun_energy -= amount
	barra_de_sol.value = sun_energy
	
func recover_health(amount: int) -> void:
	health = min(health + amount, max_health)  # não passa do máximo
	barra_de_vida.value = health
	print("Player recuperou vida! Vida atual: %d" % health)
	animation.animation = "recover_health"
	animation.play()

func recover_sun(amount: int) -> void:
	sun_energy = min(sun_energy + amount, max_sun_energy)  
	barra_de_sol.value = sun_energy
	print("Player recuperou a energia!: %d" % sun_energy)
	animation.animation = "recover_sun_energy"
	animation.play()
	
func die() -> void:
	queue_free()

func save_state():
	GameState.player_stats["health"] = health
	GameState.player_stats["sun_energy"] = sun_energy
	GameState.player_stats["position"] = global_position
