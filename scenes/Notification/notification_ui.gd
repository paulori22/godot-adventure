extends CanvasLayer

signal sequence_finished

@export var messages: Array[MessageData] = []

@onready var notification_label: Label = $Control/NotificationLabel

func _ready() -> void:
	visible = false

func start():
	print("Start Notification")
	visible = true
	for message in messages:
		await _display_message(message)
	sequence_finished.emit()
	visible = false

func show_notification(message: MessageData):
	visible = true
	await _display_message(message)
	visible = false

func _display_message(message: MessageData):
	notification_label.text = message.text
	await get_tree().create_timer(message.time).timeout
