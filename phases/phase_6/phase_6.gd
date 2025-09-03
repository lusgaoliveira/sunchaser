extends Node2D

# -------------------------------
# CENAS 
# -------------------------------
const SKULL_SCENE: PackedScene = preload("res://characters/skull/skull.tscn")
const CDEMON_SCENE: PackedScene = preload("res://characters/cdemon/cdemon.tscn")
const _DIALOG_SCREEN: PackedScene = preload("res://phases/dialogue/dialogue1.tscn")

# -------------------------------
# DIÁLOGOS
# -------------------------------
var _dialog_data: Dictionary = {
	0: { "faceset": "res://sprites/characters/bartender/dialogue/shai/wife.png", "dialog": "Shai, sinto tanta a sua falta!", "title": "Adelaide" },
	1: { "faceset": "res://sprites/characters/bartender/dialogue/shai/wife.png", "dialog": "Me desculpe por tudo o que aconteceu, eu acreditei que voce conseguiria seguir em frente!", "title": "Adeilaide" },
	2: { "faceset": "res://sprites/characters/bartender/dialogue/shai/sha6.png", "dialog": "Sinto muitas saudades de voce Adelaide!! Me perdoe de como tudo isso acabou!", "title": "Shai" },
	3: { "faceset": "res://sprites/characters/bartender/dialogue/shai/wife.png", "dialog": "MALDITOS DEMÔNIOS!! IREI ME VINGAR!!", "title": "Shai" },
	4: { "faceset": "res://sprites/characters/bartender/dialogue/shai/sha6.png", "dialog": "IREI RECUPERAR A ALMA DELA E MASSACRAR ESSES DEMÔNIOS", "title": "Shai" },
	5: { "faceset": "res://sprites/characters/bartender/dialogue/shai/shai11.png", "dialog": "VOLTAREI A CAÇAR E ELIMINAREI TODOS OS DEMÔNIOS EM NOME DE DEUS", "title": "Shai" },
	6: { "faceset": "res://sprites/characters/bartender/dialogue/shai/shai13.png", "dialog": "ELES ENFRENTARÃO A MINHA IRA!!!", "title": "Shai" },
	7: { "faceset": "res://sprites/characters/bartender/dialogue/shai/shai13.png", "dialog": "Irei descer ao inferno pela última vez", "title": "Shai" },
	8: { "faceset": "res://sprites/characters/bartender/dialogue/shai/shai13.png", "dialog": "ELES SERÃO INCINERADOS PELO BRILHO DO SOL QUE NOS AQUECE!!!", "title": "Shai" },
	9: { "faceset": "res://sprites/characters/bartender/dialogue/shai/sha6.png", "dialog": "IREI RECUPERAR A ALMA DELA E MASSACRAR ESSES DEMÔNIOS", "title": "Shai" },

}

# -------------------------------
# EXPORTS
# -------------------------------
@export_category("Objects")
@export var _hud: CanvasLayer
@export var skulls_parent: Node2D
@export var cdemon_parent: Node2D
@export var exit_area: Area2D

# -------------------------------
# CONFIG - SKULLS
# -------------------------------
const MAX_SKULLS := 3
var skulls_per_batch := 3
var spawn_interval := 8.0
var skulls_to_spawn := MAX_SKULLS
var skulls_alive: Array = []
var timer_spawn := Timer.new()

# -------------------------------
# CONFIG - CDEMONS
# -------------------------------
const MAX_CDEMONS := 3
var cdemons_per_batch := 1
var spawn_interval_cd := 1.0
var cdemons_to_spawn := MAX_CDEMONS
var cdemons_alive: Array = []
var timer_spawn_cd := Timer.new()

# -------------------------------
# READY
# -------------------------------
func _ready():
	# Configura HUD
	if _hud == null:
		_hud = get_node_or_null("HUD")
		if _hud == null:
			_hud = CanvasLayer.new()
			add_child(_hud)

	var dialog_screen: DialogScreen = _DIALOG_SCREEN.instantiate()
	dialog_screen.data = _dialog_data
	_hud.add_child(dialog_screen)

	dialog_screen.connect("dialog_finished", Callable(self, "_on_dialog_finished"))	
	# Recupera parents automaticamente se não estiverem no Inspector
	if skulls_parent == null:
		skulls_parent = get_node_or_null("SkullsParent")
	if cdemon_parent == null:
		cdemon_parent = get_node_or_null("CdemonParent")
	
	# Música
	var music = get_node_or_null("Music")
	if music and GameState.music_stream:
		music.stream = GameState.music_stream
		music.play(GameState.music_position)
	
	# Timer Skull
	add_child(timer_spawn)
	timer_spawn.wait_time = spawn_interval
	timer_spawn.timeout.connect(_on_timer_spawn_timeout)
	timer_spawn.start()

	# Timer Cdemon
	add_child(timer_spawn_cd)
	timer_spawn_cd.wait_time = spawn_interval_cd
	timer_spawn_cd.timeout.connect(_on_timer_spawn_cd_timeout)
	timer_spawn_cd.start()
	
	# Área de saída
	if exit_area:
		exit_area.body_entered.connect(_on_exit_area_body_entered)
		exit_area.visible = false
		exit_area.monitoring = false
	else:
		push_error("Exit area não atribuída!")

func _on_timer_spawn_timeout() -> void:
	if skulls_to_spawn <= 0:
		timer_spawn.stop()
		return
	if skulls_parent == null:
		push_error("SkullsParent não encontrado!")
		return

	var batch_count = min(skulls_per_batch, skulls_to_spawn)
	for i in range(batch_count):
		var skull_instance = SKULL_SCENE.instantiate()
		skull_instance.position = get_valid_spawn_position(skulls_parent, "SpawnArea")
		skulls_parent.add_child(skull_instance)

		skull_instance.skull_died.connect(_on_skull_died)
		skulls_alive.append(skull_instance)
		skulls_to_spawn -= 1

func _on_timer_spawn_cd_timeout() -> void:
	if cdemons_to_spawn <= 0:
		timer_spawn_cd.stop()
		return
	if cdemon_parent == null:
		push_error("CdemonParent não encontrado!")
		return

	var batch_count = min(cdemons_per_batch, cdemons_to_spawn)
	for i in range(batch_count):
		var cdemon_instance = CDEMON_SCENE.instantiate()
		cdemon_instance.position = get_valid_spawn_position(cdemon_parent, "SpawnAreaC")
		cdemon_parent.add_child(cdemon_instance)

		cdemon_instance.cmon_died.connect(_on_cdemon_died)
		cdemons_alive.append(cdemon_instance)
		cdemons_to_spawn -= 1

func get_valid_spawn_position(parent_node: Node2D, spawn_area_name: String) -> Vector2:
	if parent_node == null:
		push_error("Parent de spawn está nulo: %s" % spawn_area_name)
		return Vector2.ZERO
	
	var spawn_area = parent_node.get_node_or_null(spawn_area_name)
	if spawn_area:
		var collision_shape = spawn_area.get_node_or_null("CollisionShape2D")
		if collision_shape and collision_shape.shape is RectangleShape2D:
			var extents = collision_shape.shape.extents
			for attempt in range(10):
				var pos = Vector2(
					randf_range(-extents.x + 40, extents.x - 40),
					randf_range(-extents.y + 40, extents.y - 40)
				) + spawn_area.global_position
				
				if not is_position_occupied(pos):
					return pos
			return spawn_area.global_position
	return parent_node.global_position

func is_position_occupied(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = RectangleShape2D.new()
	shape.extents = Vector2(32, 32)
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	return space_state.intersect_shape(query).size() > 0

func _on_skull_died(skull):
	skulls_alive.erase(skull)
	if skulls_alive.is_empty() and skulls_to_spawn == 0:
		_on_all_skulls_killed()

func _on_cdemon_died(cdemon):
	cdemons_alive.erase(cdemon)
	if cdemons_alive.is_empty() and cdemons_to_spawn == 0:
		print("Todos os Cdemons foram mortos!")

func _on_all_skulls_killed():
	print("Todos os Skulls foram mortos!")
	if exit_area:
		exit_area.visible = true
		exit_area.set_deferred("monitoring", true)

func _on_exit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		call_deferred("_go_to_next_phase")

func _go_to_next_phase():
	var player = get_node_or_null("Player")
	if player:
		GameState.player_stats["health"] = player.health
		GameState.player_stats["sun_energy"] = player.sun_energy
		GameState.player_stats["position"] = player.global_position
	
	var music = get_node_or_null("Music")
	if music:
		GameState.music_position = music.get_playback_position()
		GameState.music_stream = music.stream

	get_tree().change_scene_to_file("res://phases/phase_7/phase_7.tscn")
