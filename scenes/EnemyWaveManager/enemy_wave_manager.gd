extends Node2D

const WaveDataScript = preload("res://scenes/EnemyWaveManager/wave_data.gd")

signal wave_started(wave_index: int)
signal wave_cleared(wave_index: int)
signal all_waves_complete

@export var enemy_scene: PackedScene
@export var spawn_points_path: Node2D
@export var enemies_container_path: Node2D
@export var waves: Array[WaveDataScript] = []
@export var inter_wave_delay: float = 3.0
@export var spawn_interval: float = 1.5

@onready var _timer: Timer = $Timer
@onready var _audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var _notification: CanvasLayer = $NotificationCanvasLayer

var _current_wave_index: int = 0
var _alive_enemies: int = 0
var _spawn_remaining: int = 0
var _is_running: bool = false
var _spawn_points: Array[Node2D] = []

func _ready() -> void:
	_timer.one_shot = true
	_timer.timeout.connect(_spawn_next_wave)
	_cache_spawn_points()

func _cache_spawn_points() -> void:
	_spawn_points.clear()
	if not spawn_points_path:
		return
	for child in spawn_points_path.get_children():
		if child is Node2D:
			_spawn_points.append(child)

func is_running() -> bool:
	return _is_running

func start() -> void:
	print("Start wave manager")
	if _is_running or waves.is_empty():
		return
	if not _validate_setup():
		return
	_is_running = true
	_current_wave_index = 0
	_spawn_wave(_current_wave_index)

func _validate_setup() -> bool:
	if not enemy_scene:
		push_warning("EnemyWaveManager: enemy_scene is not set.")
		return false
	if not enemies_container_path:
		push_warning("EnemyWaveManager: enemies_container_path is not set.")
		return false
	if _spawn_points.is_empty():
		push_warning("EnemyWaveManager: no spawn points found.")
		return false
	return true

func _spawn_wave(index: int) -> void:
	var wave: WaveDataScript = waves[index]
	var scene: PackedScene = wave.enemy_scene if wave.enemy_scene else enemy_scene
	var count: int = wave.enemy_count
	_alive_enemies = 0
	_spawn_remaining = count

	wave_started.emit(index)
	var msg = MessageData.new()
	msg.text = "Wave " + str(index + 1)
	msg.time = 1.5
	_notification.show_notification(msg)
	if _audio.stream:
		_audio.play()

	for i in count:
		var spawn_point := _spawn_points[i % _spawn_points.size()]
		_spawn_enemy_at(spawn_point, scene, wave)
		_spawn_remaining -= 1
		if spawn_interval > 0.0 and i < count - 1:
			await get_tree().create_timer(spawn_interval).timeout

	if _alive_enemies == 0 and _spawn_remaining == 0:
		_on_wave_cleared()

func _spawn_enemy_at(spawn_point: Node2D, scene: PackedScene, wave: WaveDataScript) -> void:
	var enemy := scene.instantiate()
	if wave.enemy_hp >= 0:
		enemy.max_hp = wave.enemy_hp
		enemy.hp = wave.enemy_hp
	if wave.enemy_speed >= 0.0:
		enemy.speed = wave.enemy_speed
	if wave.enemy_acceleration >= 0.0:
		enemy.acceleration = wave.enemy_acceleration
	if wave.enemy_detect_radius >= 0.0:
		enemy.player_detect_radius = wave.enemy_detect_radius
	enemies_container_path.add_child(enemy)
	var offset := Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))
	enemy.global_position = spawn_point.global_position + offset
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
		_alive_enemies += 1
	else:
		push_warning("EnemyWaveManager: spawned enemy lacks a 'died' signal.")
		enemy.queue_free()

func _on_enemy_died() -> void:
	_alive_enemies -= 1
	if _alive_enemies > 0 or _spawn_remaining > 0:
		return
	_on_wave_cleared()

func _on_wave_cleared() -> void:
	wave_cleared.emit(_current_wave_index)
	_current_wave_index += 1

	if _current_wave_index >= waves.size():
		_is_running = false
		all_waves_complete.emit()
		return

	var cleared_wave: WaveDataScript = waves[_current_wave_index - 1]
	var delay: float = cleared_wave.delay_after_wave if cleared_wave.delay_after_wave >= 0.0 else inter_wave_delay
	_timer.start(delay)

func _spawn_next_wave() -> void:
	_spawn_wave(_current_wave_index)
