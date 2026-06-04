extends Area2D

@export var is_single_use: bool = false
@onready var animated_sprite = $AnimatedSprite2D
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var bodies_on_top: int = 0

signal pressed
signal unpressed

func _on_body_entered(body: Node2D) -> void:
	bodies_on_top+=1
	if body.is_in_group("pushable") or body is Player:
		if bodies_on_top == 1:
			audio_stream_player.pitch_scale = 1.0
			audio_stream_player.play()
			pressed.emit()
			animated_sprite.play("pressed")

func _on_body_exited(body: Node2D) -> void:
	if is_single_use:
		return

	bodies_on_top-=1
	if body.is_in_group("pushable") or body is Player:
		if bodies_on_top == 0:
			audio_stream_player.pitch_scale = 0.8
			audio_stream_player.play()
			unpressed.emit()
			animated_sprite.play("unpressed")
