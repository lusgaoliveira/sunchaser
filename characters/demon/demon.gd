extends CharacterBody2D

@onready var animation := $DemonAnimate as AnimatedSprite2D

const SPEED = 100.0
const CHANGE_DIRECTION_TIME = 1.5  # Tempo em segundos para mudar direção

var direction := Vector2.ZERO
var last_direction := ""
var timer := 0.0

func _physics_process(delta: float) -> void:
	timer -= delta
	if timer <= 0:
		change_direction()
		timer = CHANGE_DIRECTION_TIME

	velocity = direction * SPEED
	move_and_slide()

	play_animation(direction)


func change_direction() -> void:
	var directions = [
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.DOWN,
		Vector2.UP,
		Vector2(1, 1).normalized(),   # diagonal frente-direita
		Vector2(-1, 1).normalized(),  # diagonal frente-esquerda
		Vector2(1, -1).normalized(),  # diagonal trás-direita
		Vector2(-1, -1).normalized(), # diagonal trás-esquerda
		Vector2.ZERO                 # parado
	]
	direction = directions[randi() % directions.size()]


func play_animation(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		animation.stop()
		return

	if dir.y > 0:
		last_direction = "front"
	elif dir.y < 0:
		last_direction = "back"
	elif dir.x > 0:
		last_direction = "front_diagonal_right"
	elif dir.x < 0:
		last_direction = "front_diagonal_left"

	animation.animation = last_direction
	animation.play()
