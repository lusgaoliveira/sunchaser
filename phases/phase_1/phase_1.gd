extends Node2D
class_name PhaseOne

const _DIALOG_SCREEN: PackedScene = preload("res://phases/phase_1/dialogue1.tscn")
const SKULL_SCENE: PackedScene = preload("res://characters/skull/skull.tscn")  # troque aqui para o caminho do seu Skull.tscn

var _dialog_data: Dictionary = {
	0: {
		"faceset": "res://sprites/characters/bartender/dialogue/alessander/alessander1.png",
		"dialog": "Os demônios precisam deadead",
		"title": "Padre Leusas"
	},
	1: {
		"faceset": "res://sprites/characters/bartender/dialogue/alessander/alessander2.png",
		"dialog": "Shai, precisamos damdoea suas ajudasd",
		"title": "Padre Leusas"
	},
	2: {
		"faceset": "res://sprites/characters/bartender/dialogue/alessander/alessander4.png",
		"dialog": "Eles ao so cuados pelo assiantidoas da sua espoca",
		"title": "Padre Leusas"
	},
	3: {
		"faceset": "res://sprites/characters/bartender/dialogue/alessander/alessander3.png",
		"dialog": "IREI ME VINGAR DESSESADAS D",
		"title": "Shai"
	},
	4: {
		"faceset": "res://sprites/characters/bartender/dialogue/shai/sha6.png",
		"dialog": "Nenhum deles irá sobrar no mundo",
		"title": "Shai"
	},
	5: {
		"faceset": "res://sprites/characters/bartender/dialogue/shai/shai11.png",
		"dialog": "Todos eles serão subjugados",
		"title": "Shai"
	},
	
	6: {
		"faceset": "res://sprites/characters/bartender/dialogue/shai/shai14.png",
		"dialog": "Todos eles serão subjugados",
		"title": "Shai"
	},
	
	7: {
		"faceset": "res://sprites/characters/bartender/dialogue/shai/shai13.png",
		"dialog": "Todos eles serão subjugados",
		"title": "Shai"
	},
	
	8: {
		"faceset": "res://sprites/characters/bartender/dialogue/shai/shai15.png",
		"dialog": "Todos eles serão subjugados",
		"title": "Shai"
	},
}

@export_category("Objects")
@export var _hud: CanvasLayer = null
@export var skulls_parent: Node2D = null

const MAX_SKULLS := 35
var skulls_per_batch := 3
var spawn_interval := 8.0  

var skulls_to_spawn := MAX_SKULLS
var timer_spawn := Timer.new()

func _ready() -> void:
	var dialog_screen: DialogScreen = _DIALOG_SCREEN.instantiate()
	dialog_screen.data = _dialog_data
	_hud.add_child(dialog_screen)
	
	add_child(timer_spawn)
	timer_spawn.wait_time = spawn_interval
	timer_spawn.connect("timeout", Callable(self, "_on_timer_spawn_timeout"))
	timer_spawn.start()

func _on_timer_spawn_timeout() -> void:
	if skulls_to_spawn <= 0:
		timer_spawn.stop()
		return

	var batch_count = min(skulls_per_batch, skulls_to_spawn)
	for i in range(batch_count):
		var skull_instance = SKULL_SCENE.instantiate()
		skull_instance.position = Vector2(
			randf_range(0, 700),
			randf_range(0, 700)
		)

		skulls_parent.add_child(skull_instance)
		skulls_to_spawn -= 1
