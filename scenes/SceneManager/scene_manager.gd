extends Node2D

var player_spawn_position: Vector2
var max_player_hp: int = 4
var player_hp: int = 4

var opened_chests: Array[String] = []

func reduce_player_hp(ammount: int):
	var current_player_hp = player_hp - ammount
	set_player_hp(current_player_hp)

func reset_player_hp():
	set_player_hp(max_player_hp)

func set_player_hp(hp: int):
	player_hp = clamp(hp, 0, max_player_hp)

func is_player_dead() -> bool:
	return player_hp <= 0
