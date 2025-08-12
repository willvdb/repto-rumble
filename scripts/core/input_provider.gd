# SPEC: Godot 4, Repto Rumble
# - Input abstraction for multiplayer support
# - Maps player-specific input actions to generic action names
# - Supports local multiplayer with different input devices

class_name InputProvider extends RefCounted

var player_id: int = 0
var input_suffix: String = ""

# Input action mappings for multiplayer
# Player 1: "jump", "move_left", "move_right", etc.
# Player 2: "jump_p2", "move_left_p2", "move_right_p2", etc.
const BASE_ACTIONS = [
	"move_left",
	"move_right",
	"jump",
	"attack_light",
	"attack_heavy",
	"dash",
	"sprint"
]

func _init(p_player_id: int = 0) -> void:
	player_id = p_player_id
	input_suffix = "_p" + str(player_id + 1) if player_id > 0 else ""

# Get the actual input action name for this player
func _get_action_name(action: String) -> String:
	# Map simplified action names to full action names
	var mapped_action = action
	match action:
		"left":
			mapped_action = "move_left"
		"right":
			mapped_action = "move_right"
		"sprint":
			# First try "sprint", then fallback to "ui_shift"
			if InputMap.has_action("sprint" + input_suffix):
				mapped_action = "sprint"
			else:
				mapped_action = "ui_shift"
	
	return mapped_action + input_suffix

# Core input methods that mirror Godot's Input class
func is_action_pressed(action: String) -> bool:
	var actual_action = _get_action_name(action)
	if InputMap.has_action(actual_action):
		return Input.is_action_pressed(actual_action)
	else:
		# Fallback to base action for backward compatibility
		return Input.is_action_pressed(action)

func is_action_just_pressed(action: String) -> bool:
	var actual_action = _get_action_name(action)
	if InputMap.has_action(actual_action):
		return Input.is_action_just_pressed(actual_action)
	else:
		# Fallback to base action for backward compatibility
		return Input.is_action_just_pressed(action)

func is_action_just_released(action: String) -> bool:
	var actual_action = _get_action_name(action)
	if InputMap.has_action(actual_action):
		return Input.is_action_just_released(actual_action)
	else:
		# Fallback to base action for backward compatibility
		return Input.is_action_just_released(action)

func get_action_strength(action: String) -> float:
	var actual_action = _get_action_name(action)
	if InputMap.has_action(actual_action):
		return Input.get_action_strength(actual_action)
	else:
		# Fallback to base action for backward compatibility
		return Input.get_action_strength(action)

# Convenience method for movement axis
func get_axis(negative_action: String, positive_action: String) -> float:
	return get_action_strength(positive_action) - get_action_strength(negative_action)

# Utility method to set up input maps for multiple players
static func setup_multiplayer_input_maps() -> void:
	print("Setting up multiplayer input maps...")
	
	for player_idx in range(1, 4): # Players 2-4 (Player 1 uses base actions)
		var suffix = "_p" + str(player_idx + 1)
		
		for base_action in BASE_ACTIONS:
			var new_action = base_action + suffix
			
			if not InputMap.has_action(new_action):
				InputMap.add_action(new_action)
				print("Created input action: ", new_action)
				
				# Copy events from base action if it exists
				if InputMap.has_action(base_action):
					var base_events = InputMap.action_get_events(base_action)
					for event in base_events:
						# You could modify events here for different controllers/keyboards
						# For now, we'll leave them empty to be configured later
						pass

# Debug method to show current input mappings
func debug_print_actions() -> void:
	print("Player ", player_id, " input mappings:")
	for action in BASE_ACTIONS:
		var actual_action = _get_action_name(action)
		print("  ", action, " -> ", actual_action, " (exists: ", InputMap.has_action(actual_action), ")")
