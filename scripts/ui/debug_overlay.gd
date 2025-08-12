# SPEC: Godot 4, Repto Rumble
# - Debug overlay for displaying player state, physics info, and performance metrics
# - Shows FSM state, facing direction, velocity, stamina, etc.

extends Control
class_name DebugOverlay

@onready var fps_label: Label = $VBoxContainer/FPSLabel
@onready var state_label: Label = $VBoxContainer/StateLabel
@onready var velocity_label: Label = $VBoxContainer/VelocityLabel
@onready var facing_label: Label = $VBoxContainer/FacingLabel
@onready var stamina_label: Label = $VBoxContainer/StaminaLabel
@onready var input_label: Label = $VBoxContainer/InputLabel

var target_player: CharacterBody2D

func _ready() -> void:
	# Find the player in the scene
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func _process(_delta: float) -> void:
	# Update FPS
	fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	
	if not target_player:
		return
	
	# Update state info
	var current_state_name = "Unknown"
	if target_player.current_state:
		current_state_name = target_player.current_state.get_script().get_global_name()
		if current_state_name.is_empty():
			current_state_name = str(target_player.current_state).get_file().get_basename()
	
	state_label.text = "State: " + current_state_name
	
	# Update velocity
	var vel = target_player.velocity
	velocity_label.text = "Velocity: (%.1f, %.1f)" % [vel.x, vel.y]
	
	# Update facing direction
	var facing = target_player.get("facing_direction")
	if facing != null:
		facing_label.text = "Facing: " + ("Right" if facing > 0 else "Left")
	else:
		facing_label.text = "Facing: Unknown"
	
	# Update stamina
	var stamina = target_player.get("stamina")
	var max_stamina = target_player.get("MAX_STAMINA")
	if stamina != null and max_stamina != null:
		stamina_label.text = "Stamina: %.1f/%.1f" % [stamina, max_stamina]
	else:
		stamina_label.text = "Stamina: Unknown"
	
	# Update input info
	var input_dir = target_player.get_input_direction() if target_player.has_method("get_input_direction") else 0.0
	var on_floor = target_player.is_on_floor()
	var on_wall = target_player.is_on_wall()
	input_label.text = "Input: %.2f | Floor: %s | Wall: %s" % [input_dir, on_floor, on_wall]
