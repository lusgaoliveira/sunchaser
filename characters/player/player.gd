extends CharacterBody2D

@onready var animation := $AnimatedSprite2D as AnimatedSprite2D

const SPEED = 150.0

var last_direction := ""
var health := 100

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up"),
	).normalized()

	velocity = input_vector * SPEED
	move_and_slide()

	play_animation(input_vector)
	
	if Input.is_action_pressed("attack1"):
		perform_attack()

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
		else:
			last_direction = "right"

		animation.animation = last_direction
		animation.play()

func perform_attack() -> void:
	print("Ataque realizado!")
	match last_direction:
		"front":
			animation.animation = "load"
		"back":
			animation.animation = "attack2"
		"left":
			animation.animation = "attack2"
		"right":
			animation.animation = "attack2"
		_:
			animation.animation = "attack2"  
	animation.play()    


func take_damage(amount: int) -> void:
	health -= amount
	print("Player tomou dano! Vida atual: %d" % health)
	if health <= 0:
		die()

func die() -> void:
	queue_free()
