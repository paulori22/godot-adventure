extends Node2D

var reward_chests: Array[StaticBody2D] = []

@onready var reward_node: Node = $Rewards
@onready var notification_canvas_layer: CanvasLayer = $NotificationCanvasLayer

@onready var wall_entrance: TileMapLayer = $WallLayerEntrance

func _ready() -> void:
	wall_entrance.activate_wall()
	for child in reward_node.get_children():
		if child is StaticBody2D:
			reward_chests.append(child)

func _on_enemy_wave_manager_all_waves_complete() -> void:
	var msg = MessageData.new()
	msg.text = "Trial Complete! Congratulations!"
	msg.time = 2.0
	notification_canvas_layer.show_notification(msg)
	for chest in reward_chests:
		chest.active()
	wall_entrance.disable_wall()
