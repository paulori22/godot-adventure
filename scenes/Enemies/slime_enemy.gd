extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_sfx: AudioStreamPlayer2D = $DamageSFX
@onready var death_particle_effect: GPUParticles2D = $DeathParticleEffect

@export var speed: float = 30
@export var acceleration: float = 5
@export var hp: int = 2
@export var max_hp: int = 2

var target: Node2D

func _physics_process(delta: float) -> void:
	if is_dead():
		return
	chase_target()
	animate_enemy()
	move_and_slide()

func chase_target():
	if target:
		var distance_to_player: Vector2 = target.global_position - global_position
		var direction_normal: Vector2 = distance_to_player.normalized()
		#velocity = direction_normal * speed
		velocity = velocity.move_toward(direction_normal * speed, acceleration)

func animate_enemy():
	var normal_velocity: Vector2 = velocity.normalized()
	var treshold_value = 0.707
	if normal_velocity.x > treshold_value:
		animated_sprite.play("move_right")
	elif  normal_velocity.x < -treshold_value:
		animated_sprite.play("move_left")
	elif normal_velocity.y > treshold_value:
		animated_sprite.play("move_down")
	elif normal_velocity.y < -treshold_value:
		animated_sprite.play("move_up")

func _on_player_detect_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		target = body

func take_damage(ammount: int):
	play_damage_sfx()
	var current_hp = hp - ammount
	set_hp(current_hp)
	if is_dead():
		die()

func set_hp(hp: int):
	self.hp = clamp(hp, 0, max_hp)

func knockback_effect(source_position: Vector2):
	var distance_to_source: Vector2 = global_position - source_position
	var knockback_direction: Vector2 = distance_to_source.normalized()
	var knockback_force: float  = 200
	velocity += knockback_direction * knockback_force

func damage_flash():
	var flash_white_color: Color = Color(50,0,0)
	modulate = flash_white_color
	await get_tree().create_timer(0.2).timeout
	var original_color: Color = Color(1,1,1)
	modulate = original_color

func play_damage_sfx():
	damage_sfx.play()

func is_dead() -> bool:
	return hp <= 0;

func die():
	death_particle_effect.emitting = true

	animated_sprite.visible = false
	collision_shape.set_deferred("disabled", true)

	await get_tree().create_timer(1).timeout
	queue_free()
