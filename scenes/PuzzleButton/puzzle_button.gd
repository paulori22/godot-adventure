extends Area2D

@export var is_single_use: bool = false
@onready var animated_sprite = $AnimatedSprite2D
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var _is_pressed: bool = false

signal pressed(button: Area2D)
signal unpressed(button: Area2D)

func _physics_process(_delta: float) -> void:
	if is_single_use and _is_pressed:
		return
	var should_press = _has_counting_body()
	if should_press == _is_pressed:
		return
	_is_pressed = should_press
	if should_press:
		press_button()
	else:
		release_button()

func _has_counting_body() -> bool:
	for body in get_overlapping_bodies():
		print(body.name)
		if _counts_toward_press(body):
			return true
	return false

func is_pressed() -> bool:
	return _is_pressed

func _counts_toward_press(body: Node2D) -> bool:
	if body.is_in_group("pushable"):
		return true
	return body is Player and not body.is_jumping

func press_button():
	audio_stream_player.pitch_scale = 1.0
	audio_stream_player.play()
	pressed.emit(self)
	animated_sprite.play("pressed")

func release_button():
	audio_stream_player.pitch_scale = 0.8
	audio_stream_player.play()
	unpressed.emit(self)
	animated_sprite.play("unpressed")
