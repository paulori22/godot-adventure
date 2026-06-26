extends CanvasLayer

func _ready() -> void:
	visible = _is_mobile()

func _is_mobile() -> bool:
	if OS.has_feature("mobile"):
		return true
	# Treat touchscreen web builds as mobile too.
	if OS.has_feature("web") and DisplayServer.is_touchscreen_available():
		return true
	return false
