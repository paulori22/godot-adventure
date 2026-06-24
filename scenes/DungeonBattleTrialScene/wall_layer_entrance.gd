extends TileMapLayer

func disable_wall():
	visible = false
	collision_enabled = false

func activate_wall():
	visible = true
	collision_enabled = true
