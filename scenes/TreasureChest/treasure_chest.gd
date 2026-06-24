extends StaticBody2D

const ACTIVE_COLLISION_LAYER := 32
const ACTIVE_COLLISION_MASK := 32

@export var chest_name: String
@export var is_actived: bool = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var treasure_sprite: Sprite2D = $TreasureSprite2D
@onready var timer: Timer = $Timer
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var can_interact: bool = false
var is_open: bool = false

func _ready() -> void:
	if SceneManager.opened_chests.has(chest_name):
		_set_is_open_to_open_and_update_animation()
	_apply_active_state(is_actived)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact") and is_actived and can_interact and !is_open:
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

func active() -> void:
	_apply_active_state(true)

func _apply_active_state(enabled: bool) -> void:
	is_actived = enabled
	visible = enabled
	collision_shape.set_deferred("disabled", not enabled)
	set_deferred("collision_layer", ACTIVE_COLLISION_LAYER if enabled else 0)
	set_deferred("collision_mask", ACTIVE_COLLISION_MASK if enabled else 0)
	if enabled:
		add_to_group("interactable")
	else:
		remove_from_group("interactable")
		can_interact = false
