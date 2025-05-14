extends CharacterBody2D

@onready var animation := $AnimatedSprite2D as AnimatedSprite2D

const SPEED = 300.0

var last_direction := ""

func _physics_process(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	velocity = input_vector * SPEED
	move_and_slide()

	play_animation(input_vector)

func play_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		# Ainda nao tenho animacao parado
		animation.stop()
	else:
		if direction.y > 0:
			if direction.x > 0:
				last_direction = "front_diagonal_right"
			elif direction.x < 0:
				last_direction = "front_diagonal_left"
			else:
				last_direction = "front"
		elif direction.y < 0:
			if direction.x > 0:
				last_direction = "fight_right"
			elif direction.x < 0:
				last_direction = "fight_left"
			else:
				last_direction = "back"

		animation.animation = last_direction
		animation.play()
