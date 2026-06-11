extends CharacterBody2D
class_name Player

@export var move_speed: float = 100
@export var acceleration: float = 10
@export var push_strength: float = 300

@onready var shadow_sprite: Sprite2D = $ShadowSprite2D
@export var jump_height: float = 48.0
@export var jump_duration: float = 0.5
var is_jumping: bool = false
var jump_time: float = 0.0
var z_offset: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea
var has_interactable_in_range: bool = false

@onready var scroll_ammount_label = $CanvasLayer/TreasurePanel/TreasureAmmountLabel
@onready var hp_bar: AnimatedSprite2D = $CanvasLayer/HPBar

var is_attacking: bool = false
@onready var sword: Sprite2D = $Sword
@onready var sword_area: Area2D = $Sword/SwordArea2D
@onready var sword_attack_timer: Timer = $Sword/AttackDurationTimer
@onready var sword_animation: AnimationPlayer = $SwordAnimation
@onready var attack_sfx: AudioStreamPlayer2D = $AttackSFX
@onready var hit_area = $HitArea2D

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
	if Input.is_action_just_pressed("jump") and !is_jumping:
		start_jump()

	if is_jumping:
		update_jump(delta)

	if not is_attacking:
		_move_player()

	_update_player_ui()
	
	if Input.is_action_just_pressed("interact") and not has_interactable_in_range and not is_jumping:
		attack()

	move_and_slide()
	if not is_jumping:
		_push_blocks()

func start_jump():
	is_jumping = true
	jump_time = 0.0
	shadow_sprite.visible = true
	_set_jump_collision_state(is_jumping)

	if velocity.x > 0:
		animated_sprite.play("jump_right")
	elif velocity.x < 0:
		animated_sprite.play("jump_left")
	elif velocity.y > 0:
		animated_sprite.play("jump_down")
	elif velocity.y < 0:
		animated_sprite.play("jump_up")
	else:
		animated_sprite.stop()

func update_jump(delta):
	jump_time += delta

	var t = jump_time / jump_duration

	if t >= 1.0:
		is_jumping = false
		z_offset = 0.0
		shadow_sprite.visible = false
		_set_jump_collision_state(is_jumping)

		animated_sprite.position.y = 0

		# Reset shadow
		shadow_sprite.scale = Vector2.ONE
		shadow_sprite.modulate.a = 0.4

		return

	# Jump parabola
	z_offset = 4.0 * jump_height * t * (1.0 - t)

	# Move sprite visually upward
	animated_sprite.position.y = - z_offset

	# Shadow effect
	var shadow_scale = lerp(1.0, 0.6, z_offset / jump_height)
	shadow_sprite.scale = Vector2.ONE * shadow_scale

	# Optional shadow fade
	shadow_sprite.modulate.a = lerp(0.4, 0.2, z_offset / jump_height)

func _set_jump_collision_state(in_air: bool):
	# Walls ALWAYS collide
	set_collision_mask_value(1, true)

	# Disable some collisions while airborne
	set_collision_mask_value(3, !in_air) # Puzzle Elements
	set_collision_mask_value(6, !in_air) # Jumpable Objects
	set_collision_mask_value(7, !in_air) # NPC
	
	# For enemy hits, only the hit_area that matter
	hit_area.set_collision_mask_value(5, !in_air) # Enemies
	
	# Disable interact area (no npc talk in the air)
	interact_area.set_collision_mask_value(7, !in_air) # Enemies

	_set_pushable_collision_exceptions(in_air)

func _move_player():
	var move_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var max_speed = move_vector * move_speed
	velocity = velocity.move_toward(max_speed, acceleration)

	# This fix the issue on animation if you press the same direction multipe times
	# This happens because the first frame is an idle frame, so we skip it if the animation is on play
	if !animated_sprite.is_playing():
		animated_sprite.set_frame_and_progress(1, 0.0)

	if is_jumping:
		return

	if velocity.x > 0:
		animated_sprite.play("move_right")
		_set_interact_area_position(Vector2(5, 2))
	elif velocity.x < 0:
		animated_sprite.play("move_left")
		_set_interact_area_position(Vector2(-5, 2))
	elif velocity.y > 0:
		animated_sprite.play("move_down")
		_set_interact_area_position(Vector2(0, 8))
	elif velocity.y < 0:
		animated_sprite.play("move_up")
		_set_interact_area_position(Vector2(0, -4))
	else:
		_reset_standing_animation()

func _reset_standing_animation() -> void:
	var anim: String = animated_sprite.animation
	if anim.begins_with("jump_"):
		animated_sprite.play(anim.replace("jump_", "move_"))
	animated_sprite.stop()

func _set_interact_area_position(pos: Vector2):
	interact_area.position = pos

func _set_pushable_collision_exceptions(in_air: bool) -> void:
	for node in get_tree().get_nodes_in_group("pushable"):
		if node is PhysicsBody2D:
			if in_air:
				add_collision_exception_with(node)
			else:
				remove_collision_exception_with(node)

func _push_blocks():
	if is_jumping:
		return

	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider_node = collision.get_collider()
		if not collider_node.is_in_group("pushable"):
			continue

		var collision_normal: Vector2 = collision.get_normal()
		if velocity.dot(-collision_normal) <= 0:
			continue

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
	print(body.name)
	SceneManager.reduce_player_hp(1)
	play_take_damage_sfx()
	update_hp_bar()

	if SceneManager.player_hp <= 0:
		die()

	var distance_to_player: Vector2 = global_position - body.global_position
	var knockback_direction: Vector2 = distance_to_player.normalized()
	var knockback_force: float = 150
	velocity += knockback_direction * knockback_force

	var flash_white_color: Color = Color(50, 50, 50)
	modulate = flash_white_color
	await get_tree().create_timer(0.2).timeout
	var original_color: Color = Color(1, 1, 1)
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

	var player_animation: String = animated_sprite.animation
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

	var player_animation: String = animated_sprite.animation
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
