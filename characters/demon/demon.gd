extends CharacterBody2D

@export var velocidade := 60

# Configs da explosão
@export var explosion_radius: float = 100.0
@export var explosion_damage: int = 30
@export var explosion_duration: float = 0.6
@export var explosion_particles: int = 90
@export var explosion_steps: int = 12

@onready var attack_area: Area2D = $hitbox
@onready var barra_de_vida: ProgressBar = $barra_de_vida
@onready var barra_de_mana: ProgressBar = $barra_de_mana
@onready var animation := $AnimatedSprite2D as AnimatedSprite2D
@onready var magic_particles: GPUParticles2D = $magic_particles
@onready var magic_explosion_area: Area2D = $magic_explosion_area
@onready var magic_collision: CollisionShape2D = $magic_explosion_area/CollisionShape2D

const CHANGE_DIRECTION_TIME = 1

var direction := Vector2.ZERO
var timer := 0.0

var knockback_velocity := Vector2.ZERO
var is_knockback := false
var is_dead := false
var max_health := 1000
var health := 1000
var player: Node2D = null
var can_attack := true

# Para evitar dano duplicado na mesma explosão
var damaged_bodies: Array = []

func _ready():
	randomize()
	add_to_group("demons")
	barra_de_vida.max_value = max_health
	barra_de_vida.value = health

	# Conexões de sinais
	attack_area.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
	magic_explosion_area.connect("body_entered", Callable(self, "_on_magic_body_entered"))

	# Configura partículas configuradas no editor
	_setup_magic_particles()

	_setup_magic_collision()

	await get_tree().process_frame
	_set_player()

func _setup_magic_particles() -> void:
	magic_particles.one_shot = true
	magic_particles.amount = explosion_particles
	magic_particles.lifetime = explosion_duration
	magic_particles.emitting = false
	magic_particles.preprocess = 0.0
	
	# Se quiser criar o material via script, faça assim:
	if magic_particles.process_material == null:
		var mat = ParticleProcessMaterial.new()
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		mat.emission_sphere_radius = 5.0  # Ajuste para o raio que quiser
		mat.gravity = Vector2.ZERO
		mat.initial_velocity = 250.0
		mat.scale = 1.0
		mat.scale_random = 0.5
		mat.damping = 0.1
		
		magic_particles.process_material = mat

func _setup_magic_collision() -> void:
	if magic_collision.shape == null:
		magic_collision.shape = CircleShape2D.new()
	magic_collision.shape.radius = 0.0
	magic_explosion_area.monitoring = false

func _set_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _attack():
	if can_attack and not is_dead and is_instance_valid(player):
		can_attack = false
		attack_area.monitoring = false
		animation.play("attack")

		await get_tree().create_timer(0.3).timeout # Momento do hit

		damaged_bodies.clear()

		# Reinicia e ativa partículas (one-shot) e área de dano
		magic_particles.emitting = false
		magic_particles.restart()
		magic_particles.emitting = true
		magic_explosion_area.monitoring = true

		await _expand_explosion()

		magic_explosion_area.monitoring = false
		magic_collision.shape.radius = 0.0

		await get_tree().create_timer(magic_particles.lifetime).timeout
		magic_particles.emitting = false

		can_attack = true

func _expand_explosion() -> void:
	var duration: float = float(explosion_duration)
	var steps: int = max(1, explosion_steps)
	var max_radius: float = float(explosion_radius)
	var step_time: float = duration / float(steps)

	for i in range(steps):
		var t: float = float(i + 1) / float(steps)
		magic_collision.shape.radius = lerp(0.0, max_radius, t)
		await get_tree().create_timer(step_time).timeout

	magic_collision.shape.radius = 0.0

func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and can_attack and not is_dead:
		body.take_damage(25, global_position)

func _on_magic_body_entered(body):
	if body.is_in_group("player") and not damaged_bodies.has(body):
		damaged_bodies.append(body)
		body.take_damage(explosion_damage, global_position)

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

	var dir = (global_position - attacker_pos).normalized()
	apply_knockback(dir * 220)

	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	animation.animation = "fall"
	animation.play()
	await get_tree().create_timer(1.5).timeout
	queue_free()

func _physics_process(_delta) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	z_index = int(global_position.y)

	if is_knockback:
		velocity = knockback_velocity
		move_and_slide()
		return

	if player and is_instance_valid(player):
		var direcao := player.global_position - global_position
		var distancia := direcao.length()

		if distancia > 10:
			velocity = direcao.normalized() * velocidade

			if abs(direcao.x) > abs(direcao.y):
				animation.animation = "left"
				animation.flip_h = direcao.x > 0
			else:
				animation.flip_h = false
				animation.animation = "front" if direcao.y > 0 else "back"

			animation.play()
		else:
			var backstep = -direcao.normalized() * 5
			global_position += backstep
			velocity = Vector2.ZERO
			_attack()

	move_and_slide()
