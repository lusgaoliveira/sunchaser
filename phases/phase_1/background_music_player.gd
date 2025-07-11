extends AudioStreamPlayer2D

var musicas: Array = []
var musica_atual := 0

func _ready():
	# Carrega músicas numeradas na pasta
	for i in range(1, 100):
		var path = "res://assets/sounds/%d.mp3" % i
		if ResourceLoader.exists(path):
			musicas.append(load(path))
		else:
			break
	
	if musicas.size() > 0:
		play_musica(musica_atual)

func _process(_delta):
	if not is_playing() and musicas.size() > 0:
		avancar_musica()

func play_musica(index: int):
	stream = musicas[index]
	play()

func avancar_musica():
	musica_atual += 1
	if musica_atual >= musicas.size():
		musica_atual = 0  # reinicia o álbum
	play_musica(musica_atual)
