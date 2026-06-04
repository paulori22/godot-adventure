extends CharacterBody2D
class_name Player

@export var move_speed: float = 100
@export var acceleration: float = 10
@export var push_strength: float = 300

@onready var shadow_sprite := $ShadowSprite2D
@export var jump_height := 48.0
@export var jump_duration := 0.5

var is_jumping := false
var jump_time := 0.0
var z_offset := 0.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var interact_area = $InteractArea
var has_interactable_in_range: bool = false

@onready var scroll_ammount_label = $CanvasLayer/TreasurePanel/TreasureAmmountLabel
@onready var hp_bar: AnimatedSprite2D = $CanvasLayer/HPBar

var is_attacking: bool = false
@onready var sword: Sprite2D = $Sword
@onready var sword_area: Area2D = $Sword/SwordArea2D
@onready var sword_attack_timer: Timer = $Sword/AttackDurationTimer
@onready var sword_animation: AnimationPlayer = $SwordAnimation
@onready var attack_sfx: AudioStreamPlayer2D = $AttackSFX

@onready var death_timer: Timer = $DeathTimer
@onready var take_damage_sfx: AudioStreamPlayer2D = $TakeDamageSFX

func _ready() -> void:
	_disable_sword()
	_update_player_ui()
	update_hp_bar()
	shadow_sprite.visible = false
	if SceneManager.player_spawn_position != Vector2.ZERO:
		position = SceneManager.player_spawn_position

func _physics_process(delta: float) -> void:
	if SceneManager.is_player_dead():
		return
	if not is_attacking:
		_move_player()

	_push_blocks()
	_update_player_ui()
	
	if Input.is_action_just_pressed("interact") and not has_interactable_in_range:
		attack()

	if Input.is_action_just_pressed("jump") and !is_jumping:
		start_jump()

	# UPDATE JUMP
	if is_jumping:
		update_jump(delta)

	move_and_slide()

func start_jump():
	is_jumping = true
	jump_time = 0.0
	shadow_sprite.visible = true

func update_jump(delta):

	jump_time += delta

	var t = jump_time / jump_duration

	if t >= 1.0:

		is_jumping = false
		z_offset = 0.0
		shadow_sprite.visible = false

		animated_sprite.position.y = 0

		# Reset shadow
		shadow_sprite.scale = Vector2.ONE
		shadow_sprite.modulate.a = 0.4

		return

	# Jump parabola
	z_offset = 4.0 * jump_height * t * (1.0 - t)

	# Move sprite visually upward
	animated_sprite.position.y = -z_offset

	# Shadow effect
	var shadow_scale = lerp(1.0, 0.6, z_offset / jump_height)
	shadow_sprite.scale = Vector2.ONE * shadow_scale

	# Optional shadow fade
	shadow_sprite.modulate.a = lerp(0.4, 0.2, z_offset / jump_height)

func _move_player():
	var move_vector: Vector2 = Input.get_vector("move_left","move_right","move_up","move_down")
	var max_speed = move_vector * move_speed
	velocity = velocity.move_toward(max_speed, acceleration)


	# This fix the issue on animation if you press the same direction multipe times
	# This happens because the first frame is an idle frame, so we skip it if the animation is on play
	if !animated_sprite.is_playing():
		animated_sprite.set_frame_and_progress(1, 0.0)

	if velocity.x > 0:
		animated_sprite.play("move_right")
		_set_interact_area_position(Vector2(5,2))
	elif velocity.x <0:
		animated_sprite.play("move_left")
		_set_interact_area_position(Vector2(-5,2))
	elif velocity.y > 0:
		animated_sprite.play("move_down")
		_set_interact_area_position(Vector2(0,8))
	elif velocity.y <0:
		animated_sprite.play("move_up")
		_set_interact_area_position(Vector2(0,-4))
	else:
		animated_sprite.stop()

func _set_interact_area_position(pos: Vector2):
	interact_area.position = pos

func _push_blocks():
	var collision: KinematicCollision2D = get_last_slide_collision()
	if collision:
		var collider_node = collision.get_collider()
		#Only Block have a Rigidbody
		if collider_node.is_in_group("pushable"):
			var collision_normal: Vector2 = collision.get_normal()
			collider_node.apply_central_force(-collision_normal * push_strength)

func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("interactable"):
		body.can_interact = true
		has_interactable_in_range = true

func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("interactable"):
		body.can_interact = false
		has_interactable_in_range = false

func _update_player_ui():
	_update_treasure_ui()

func _update_treasure_ui():
	var treasure_ammount: int = SceneManager.opened_chests.size()
	scroll_ammount_label.text = str(treasure_ammount)

func _on_hit_area_2d_body_entered(body: Node2D) -> void:
	SceneManager.reduce_player_hp(1)
	play_take_damage_sfx()
	update_hp_bar()

	if SceneManager.player_hp <= 0:
		die()

	var distance_to_player: Vector2 = global_position - body.global_position
	var knockback_direction: Vector2 = distance_to_player.normalized()
	var knockback_force: float = 150
	velocity += knockback_direction * knockback_force

	var flash_white_color: Color = Color(50,50,50)
	modulate = flash_white_color
	await get_tree().create_timer(0.2).timeout
	var original_color: Color = Color(1,1,1)
	modulate = original_color

func die():
	if !death_timer.is_stopped():
		return
	animated_sprite.play("death")
	death_timer.start()

func update_hp_bar():
	match SceneManager.player_hp:
		0:
			hp_bar.play("0_hp")
		1:
			hp_bar.play("1_hp")
		2:
			hp_bar.play("2_hp")
		3:
			hp_bar.play("3_hp")
		4:
			hp_bar.play("4_hp")

func attack():
	if not sword_attack_timer.is_stopped():
		return
	_enable_sword()
	play_attack_sfx()
	sword_attack_timer.start()

	var player_animation : String = animated_sprite.animation
	match player_animation:
		"move_up":
			animated_sprite.play("attack_up")
			sword_animation.play("attack_up")
		"move_down":
			animated_sprite.play("attack_down")
			sword_animation.play("attack_down")
		"move_right":
			animated_sprite.play("attack_right")
			sword_animation.play("attack_right")
		"move_left":
			animated_sprite.play("attack_left")
			sword_animation.play("attack_left")

func _on_sword_area_2d_body_entered(body: Node2D) -> void:

	if body.has_method("knockback_effect"):
		body.knockback_effect(global_position)
	
	if body.has_method("take_damage"):
		body.take_damage(1)

	if body.has_method("damage_flash"):
		body.damage_flash()

func _on_attack_duration_timer_timeout() -> void:
	_disable_sword()

func _enable_sword():
	sword.visible = true
	sword_area.monitoring = true
	is_attacking = true
	velocity = Vector2.ZERO

func _disable_sword():
	sword.visible = false
	sword_area.monitoring = false
	is_attacking = false

	var player_animation : String = animated_sprite.animation
	match player_animation:
		"attack_up":
			animated_sprite.play("move_up")
		"attack_down":
			animated_sprite.play("move_down")
		"attack_right":
			animated_sprite.play("move_right")
		"attack_left":
			animated_sprite.play("move_left")

func _on_death_timer_timeout() -> void:
	SceneManager.reset_player_hp()
	get_tree().call_deferred("reload_current_scene")

func play_take_damage_sfx():
	take_damage_sfx.play()

func play_attack_sfx():
	attack_sfx.play()
