extends Node2D

func _ready():
	var music = get_node_or_null("Music")
	if music and GameState.music_stream:
		music.stream = GameState.music_stream
		music.play(GameState.music_position)
