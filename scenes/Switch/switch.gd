extends StaticBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

signal switch_activated
signal switch_deactivated
signal switch_toggled

var can_interact: bool = false
var is_activated: bool = false

# 2. OPTIMIZATION FOR MOBILE/WEB: 
# Changed from _process to _unhandled_input. 
# Checking inputs 60+ times a second in _process on mobile web can lag the browser.
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact") and can_interact:
		audio_stream_player.play()
		if is_activated:
			deactivate_switch()
		else:
			activate_switch()

func activate_switch():
	animated_sprite.play("activated")
	is_activated = true
	_handle_signals()

func deactivate_switch():
	animated_sprite.play("deactivated")
	is_activated = false
	_handle_signals()

func _handle_signals():
	if is_activated:
		switch_activated.emit()
	else:
		switch_deactivated.emit()
	switch_toggled.emit()
