extends CharacterBody2D

@export var velocidade := 60

# Configs da explosão
@export var explosion_radius: float = 100.0
@export var explosion_damage: int = 12        # <<< DANO REDUZIDO
@export var explosion_duration: float = 0.4   # <<< DURAÇÃO MENOR
@export var explosion_particles: int = 50     # <<< MENOS PARTÍCULAS
@export var explosion_steps: int = 10         # <<< PASSOS PARA EXPLOSÃO

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
var max_health := 400
var health := 400

# Mana configs
var mana := 250
var mana_cost := 40              # <<< custo por ataque
var mana_regen_rate := 15        # <<< quanto regenera por segundo
var is_recharging := false       # <<< flag de recarga
var mana_needed := 40            # <<< mínimo para atacar

var player: Node2D = null
var can_attack := true

# Para evitar dano duplicado na mesma explosão
var damaged_bodies: Array = []

func _ready():
	randomize()
	add_to_group("demons")
	barra_de_vida.max_value = max_health
	barra_de_vida.value = health
	barra_de_mana.max_value = mana
	barra_de_mana.value = mana

	# Conexões de sinais
	attack_area.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
	magic_explosion_area.connect("body_entered", Callable(self, "_on_magic_body_entered"))

	# Configura partículas e colisão
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
	magic_particles.explosiveness = 1.0
	magic_particles.speed_scale = 3.0
	
	var material := ParticleProcessMaterial.new()

	# Gradiente vermelho
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1, 0, 0, 1))   # início vermelho
	gradient.add_point(1.0, Color(1, 0, 0, 0))   # desaparecendo transparente

	var grad_texture := GradientTexture2D.new()
	grad_texture.gradient = gradient

	material.color_ramp = grad_texture

	# Gravidade e direção
	material.gravity = Vector3(0, 200, 0)
	material.direction = Vector3(0, -1, 0)

	# Velocidade inicial: min/max
	material.initial_velocity = Vector2(180, 220)

	# Ângulo min/max
	material.angle = Vector2(0, 180)

	# Escala min/max
	material.scale = Vector2(0.4, 0.6)

	# Damping min/max
	material.damping = Vector2(0.05, 0.15)

	# Outros
	material.spread = 180.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0

	magic_particles.process_material = material
	magic_particles.emitting = false
	magic_particles.one_shot = true

	
func _setup_magic_collision() -> void:
	if magic_collision.shape == null:
		magic_collision.shape = CircleShape2D.new()
	magic_collision.shape.radius = 0.0
	magic_explosion_area.monitoring = false

func _set_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

# ======================
#      ATAQUE
# ======================
func _attack():
	if can_attack and not is_dead and is_instance_valid(player):
		if mana < mana_cost:
			is_recharging = true
			return
		
		# Consome mana
		mana -= mana_cost
		barra_de_mana.value = mana

		can_attack = false
		attack_area.monitoring = false
		animation.play("attack")
		
		await get_tree().create_timer(0.5).timeout
		damaged_bodies.clear()

		# Partículas visíveis
		magic_particles.emitting = false
		magic_particles.restart()
		magic_particles.emitting = true
		magic_explosion_area.monitoring = true

		await _expand_explosion()

		magic_explosion_area.monitoring = false
		magic_collision.shape.radius = 180.0

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

# ======================
#   COLISÕES
# ======================
func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and can_attack and not is_dead:
		body.take_damage(15, global_position)

func _on_magic_body_entered(body):
	if body.is_in_group("player") and not damaged_bodies.has(body):
		damaged_bodies.append(body)
		body.take_damage(explosion_damage, global_position)

# ======================
#   COMBATE E VIDA
# ======================
func apply_knockback(force: Vector2) -> void:
	if is_dead:
		return
	knockback_velocity = force
	is_knockback = true
	await get_tree().create_timer(0.15).timeout
	is_knockback = false

func lost_mana(amount: int) -> void:
	mana -= amount
	barra_de_mana.value = mana
	
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

# ======================
#     MOVIMENTO
# ======================
func _physics_process(delta) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	# REGENERAÇÃO DE MANA
	if is_recharging:
		mana += mana_regen_rate * delta
		if mana >= mana_needed:
			is_recharging = false
		barra_de_mana.value = mana
		velocity = Vector2.ZERO
		animation.play("idle")   # parado recarregando
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
