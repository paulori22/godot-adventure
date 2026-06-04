extends StaticBody2D

@export var chest_name: String

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var treasure_sprite: Sprite2D = $TreasureSprite2D
@onready var timer: Timer = $Timer
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var can_interact: bool = false
var is_open: bool = false

func _ready() -> void:
	if SceneManager.opened_chests.has(chest_name):
		_set_is_open_to_open_and_update_animation()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact") and can_interact and !is_open:
		open_chest()

func open_chest():
	_set_is_open_to_open_and_update_animation()
	treasure_sprite.visible = true
	timer.start()
	SceneManager.opened_chests.append(chest_name)
	audio_stream_player.play()

func _set_is_open_to_open_and_update_animation():
	is_open = true
	animated_sprite.play("open")

func _on_timer_timeout() -> void:
	treasure_sprite.visible = false
