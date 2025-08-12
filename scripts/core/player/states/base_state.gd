# SPEC: Godot 4, Repto Rumble
# - States extend BaseState (Resource)
# - AnimatedSprite2D animations: idle/run/jump_start/air/land/attack_*/hurt/wall_*
# - Use MoveRunner + frame events to spawn Hitbox.tscn at HitSocketA/B

class_name BaseState extends Resource

# Called when entering this state from another state
func enter(_owner: Node, _prev_state: BaseState) -> void:
	pass

# Called when exiting this state to another state  
func exit(_owner: Node, _next_state: BaseState) -> void:
	pass

# Called every physics frame while in this state
func physics(_owner: Node, _delta: float) -> void:
	pass

# Called when receiving frame events from AnimatedSprite2D
func handle_event(_owner: Node, _event: StringName, _data := {}) -> void:
	pass

# Called for input events while in this state
func handle_input(_owner: Node, _event: InputEvent) -> void:
	pass
