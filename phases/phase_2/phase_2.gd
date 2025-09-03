extends Node2D

const SKULL_SCENE: PackedScene = preload("res://characters/skull/skull.tscn")  # troque aqui para o caminho do seu Skull.tscn

@export_category("Objects")
@export var skulls_parent: Node2D = null
@export var exit_area: Area2D = null

const MAX_SKULLS := 1
var skulls_per_batch := 1
var spawn_interval := 8.0

var skulls_to_spawn := MAX_SKULLS
var timer_spawn := Timer.new()

var skulls_alive := []
func _ready():
	var music = get_node_or_null("Music")
	if music and GameState.music_stream:
		music.stream = GameState.music_stream
		music.play(GameState.music_position)
		
	add_child(timer_spawn)
	timer_spawn.wait_time = spawn_interval
	timer_spawn.connect("timeout", Callable(self, "_on_timer_spawn_timeout"))
	timer_spawn.start()
	
	if exit_area:
		exit_area.connect("body_entered", Callable(self, "_on_exit_area_body_entered"))
		exit_area.visible = false
		exit_area.monitoring = false

func _on_timer_spawn_timeout() -> void:
	if skulls_to_spawn <= 0:
		timer_spawn.stop()
		return

	var batch_count = min(skulls_per_batch, skulls_to_spawn)
	for i in range(batch_count):
		var skull_instance = SKULL_SCENE.instantiate()
		skull_instance.position = get_valid_spawn_position()
		skulls_parent.add_child(skull_instance)

		# sinal de morte do skull
		skull_instance.connect("skull_died", Callable(self, "_on_skull_died"))
		skulls_alive.append(skull_instance)

		skulls_to_spawn -= 1

func get_valid_spawn_position() -> Vector2:
	var spawn_area = skulls_parent.get_node_or_null("SpawnArea")
	if spawn_area:
		var collision_shape = spawn_area.get_node_or_null("CollisionShape2D")
		if collision_shape:
			var shape = collision_shape.shape
			if shape is RectangleShape2D:
				var extents = shape.extents
				for attempt in range(10):
					var pos = Vector2(
						randf_range(-extents.x + 40, extents.x - 40),
						randf_range(-extents.y + 40, extents.y - 40)
					) + spawn_area.global_position
					
					if not is_position_occupied(pos):
						return pos
				# fallback
				return spawn_area.global_position
	return skulls_parent.global_position

func is_position_occupied(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	var shape = RectangleShape2D.new()
	shape.extents = Vector2(32, 32) 
	
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var result = space_state.intersect_shape(query)
	return result.size() > 0

func _on_skull_died(skull):
	skulls_alive.erase(skull)
	if skulls_alive.size() == 0 and skulls_to_spawn == 0:
		_on_all_skulls_killed()
		
func _on_all_skulls_killed():
	print("Todos os skulls foram mortos!")
	if exit_area:
		print("Liberando área de saída...")
		exit_area.visible = true  
		exit_area.set_deferred("monitoring", true)

func _on_exit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Carregando próxima fase...")
		call_deferred("_go_to_next_phase")

func _go_to_next_phase():
	var player = get_node_or_null("Player")  # caminho relativo ao nó da fase
	if player:
		GameState.player_stats["health"] = player.health
		GameState.player_stats["sun_energy"] = player.sun_energy 
		GameState.player_stats["position"] = player.global_position

		
	var music = get_node_or_null("Music")  # caminho relativo ao nó da fase
	if music:
		GameState.music_position = music.get_playback_position()
		GameState.music_stream = music.stream

	get_tree().change_scene_to_file("res://phases/phase_3/phase_3.tscn")	
