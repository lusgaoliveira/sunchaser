extends CharacterBody2D

@export var velocidade := 60

@onready var attack_area: Area2D = $hitbox
@onready var barra_de_vida: ProgressBar = $barra_de_vida
@onready var barra_de_mana: ProgressBar = $barra_de_mana
@onready var animation := $AnimatedSprite2D as AnimatedSprite2D

const CHANGE_DIRECTION_TIME = 1  # Tempo em segundos para mudar direção

var direction := Vector2.ZERO
var timer := 0.0

var knockback_velocity := Vector2.ZERO
var is_knockback := false
var is_dead := false
var max_health := 1000
var health := 1000
var player: Node2D = null
var can_attack := true

# Função para adicionar o demônio ao grupo
func _ready():
	randomize()
	add_to_group("demon")
	barra_de_vida.max_value = max_health
	barra_de_vida.value = health
	await get_tree().process_frame
	_set_player()

# Identifica o player
func _set_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

# Ataque
func _attack():
	if can_attack and not is_dead and is_instance_valid(player):
		can_attack = false

		# Verificar mana, se quiser usar no futuro
		# if barra_de_mana.value < 10:
		#     animation.animation = "load"
		#     animation.play()
		#     return

		animation.play("attack")
		await get_tree().create_timer(0.4).timeout
		can_attack = true

# Detecta se o player entrou na área de ataque
func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and can_attack and not is_dead:
		body.take_damage(25, global_position)

# Aplica knockback após levar dano
func apply_knockback(force: Vector2) -> void:
	if is_dead:
		return
	knockback_velocity = force
	is_knockback = true
	await get_tree().create_timer(0.15).timeout
	is_knockback = false

# Recebe dano
func take_damage(amount: int, attacker_pos: Vector2 = global_position) -> void:
	if is_dead:
		return

	health -= amount
	barra_de_vida.value = health

	var dir = (global_position - attacker_pos).normalized()
	apply_knockback(dir * 220)

	if health <= 0:
		die()

# Morre e executa animação aleatória
func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	var mortes = ["fall1", "fall2"]
	var anim_aleatoria = mortes[randi() % mortes.size()]
	animation.animation = anim_aleatoria
	animation.play()
	await get_tree().create_timer(1.5).timeout
	emit_signal("skull_died", self)
	queue_free()

# Movimento e ataque
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

		if distancia > 10:
			velocity = direcao.normalized() * velocidade

			# Animação com flip horizontal para "right"
			if abs(direcao.x) > abs(direcao.y):
				animation.animation = "left"
				animation.flip_h = direcao.x > 0
			else:
				animation.flip_h = false
				animation.animation = "front" if direcao.y > 0 else "back"

			animation.play()
		else:
			velocity = Vector2.ZERO
			_attack()

	move_and_slide()
