extends CharacterBody2D

@onready var animation := $AnimatedSprite2D as AnimatedSprite2D

const SPEED = 150.0

var last_direction := ""
var health := 100
var is_attacking := false

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	if not is_attacking:
		velocity = input_vector * SPEED
		move_and_slide()
		play_animation(input_vector)

	if Input.is_action_just_pressed("attack1") and not is_attacking:
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
		elif direction.x < 0:
			last_direction = "right"
		else:
			last_direction = "stop"


		animation.animation = last_direction
		animation.play()

func perform_attack() -> void:
	is_attacking = true
	
	var direction = velocity.normalized()
	
	if direction.y > 0:
		animation.animation = "load"  # ataque frente
	elif direction.y < 0 or direction.x != 0:
		animation.animation = "attack2"  # ataque trás ou lateral
	else:
		animation.animation = "attack2"

	animation.play()
	await get_tree().create_timer(0.4).timeout
	is_attacking = false
	play_animation(velocity.normalized())

 


func take_damage(amount: int) -> void:
	health -= amount
	print("Player tomou dano! Vida atual: %d" % health)
	if health <= 0:
		die()

func die() -> void:
	queue_free()
