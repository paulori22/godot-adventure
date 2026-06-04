extends StaticBody2D

@onready var canvas_layer = $CanvasLayer
@onready var dialog_text = $CanvasLayer/DialogText
@onready var audio_stream_player = $AudioStreamPlayer2D

var can_interact: bool = false

@export var dialogue_lines: Array[String] = ["Hi", "How are you?","Bye"]
var dialogue_index: int = 0

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and can_interact:
		audio_stream_player.play()
		if dialogue_index < dialogue_lines.size():
			canvas_layer.visible = true
			get_tree().paused = true
			dialog_text.text = dialogue_lines[dialogue_index]
			dialogue_index += 1
		else:
			canvas_layer.visible = false
			get_tree().paused = false
			dialogue_index = 0
	
	
	#My solution withou the pausing
	#if !can_interact and canvas_layer.visible:
	#	canvas_layer.visible = false
