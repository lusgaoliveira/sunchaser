extends Node2D
@export var exit_area: Area2D

func _ready():
	if exit_area:
		exit_area.body_entered.connect(_on_exit_area_body_entered)
	else:
		push_error("Aqui!")

func _on_exit_area_body_entered(body: Node2D) -> void:
	print("Entrou na área!")
	if body.is_in_group("player"):
		print("É o player, chamando troca de fase...")
		call_deferred("_go_to_next_phase")  # evita erro de física

func _go_to_next_phase():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		GameState.player_stats["health"] = player.health
		GameState.player_stats["sun_energy"] = player.sun_energy
		GameState.player_stats["position"] = player.global_position

	var music = get_node_or_null("Music")
	if music:
		GameState.music_position = music.get_playback_position()
		GameState.music_stream = music.stream

	get_tree().change_scene_to_file("res://phases/phase_9/phase_9.tscn")
