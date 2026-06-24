extends StaticBody2D

@export var buttons_needed: int = 1
@export var enemies_needed: int = 0  # 0 = enemy trigger disabled

var _tracked_buttons: Array[Area2D] = []
var _enemies_defeated: int = 0
var _opened_by_enemies: bool = false

func _on_puzzle_button_pressed(button: Area2D) -> void:
	_register_button(button)
	_update_door_state()

func _on_puzzle_button_unpressed(button: Area2D) -> void:
	_register_button(button)
	_update_door_state()

func _on_enemy_died() -> void:
	_enemies_defeated += 1
	if enemies_needed > 0 and _enemies_defeated >= enemies_needed:
		_opened_by_enemies = true
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

	var buttons_open := buttons_needed > 0 and pressed_count >= buttons_needed
	var is_open := buttons_open or _opened_by_enemies
	visible = not is_open
	$CollisionShape2D.set_deferred("disabled", is_open)
