extends Marker2D

signal puzzle_solved
signal puzzle_failed

# Define the solution in the inspector using binary notation!
# For example, if switches 0 and 2 must be ON: 0101 in binary is 5.
# In Godot, you can write binary directly using '0b' prefix:
@export var target_mask: int = 0b0101 

#the order of the switches is the array is important, the mask will be based on it
@export var switches: Array[Node2D] = []

@export var solved_music: AudioStreamPlayer2D

func _ready() -> void:
	# Loop through assigned switches and connect their signals
	for switch in switches:
		if switch.has_signal("switch_toggled"):
			switch.switch_toggled.connect(_on_switch_changed)

func _on_switch_changed() -> void:
	var current_mask: int = 0
	
	# 1. Use a counted loop to get the exact index position (i) of each switch
	for i in range(switches.size()):
		var switch = switches[i]
		
		# 2. If the switch at this index position is active, flip its corresponding binary bit
		if switch.is_activated:
			current_mask |= (1 << i)
	
	print("Current Mask: ", bin(current_mask), " | Target Mask: ", bin(target_mask))
	
	# 3. Check solution
	if current_mask == target_mask:
		_resolve_puzzle_success()
	else:
		puzzle_failed.emit()

func _resolve_puzzle_success() -> void:
	print("🔓 Puzzle Solved!")
	puzzle_solved.emit()
	if solved_music:
		solved_music.play()

# Helper function to print binary numbers clearly in the console
func bin(n: int) -> String:
	var s = ""
	while n > 0:
		s = str(n & 1) + s
		n = n >> 1
	return s if s != "" else "0"
