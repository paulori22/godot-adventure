extends StaticBody2D

@export var buttons_needed: int = 1

var _tracked_buttons: Array[Area2D] = []

func _on_puzzle_button_pressed(button: Area2D) -> void:
	_register_button(button)
	_update_door_state()

func _on_puzzle_button_unpressed(button: Area2D) -> void:
	_register_button(button)
	_update_door_state()

func _register_button(button: Area2D) -> void:
	if button == null or button in _tracked_buttons:
		return
	_tracked_buttons.append(button)

func _update_door_state() -> void:
	var pressed_count := 0
	for button in _tracked_buttons:
		if is_instance_valid(button) and button.is_pressed():
			pressed_count += 1

	var is_open := pressed_count >= buttons_needed
	visible = not is_open
	$CollisionShape2D.set_deferred("disabled", is_open)
