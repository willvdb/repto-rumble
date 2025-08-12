# SPEC: Godot 4, Repto Rumble
# - States extend BaseState (Resource)
# - AnimatedSprite2D animations: idle/run/jump_start/air/land/attack_*/hurt/wall_*
# - Use MoveRunner + frame events to spawn Hitbox.tscn at HitSocketA/B

extends "res://scripts/core/player/states/base_state.gd"
class_name AirState

func enter(owner: Node, _prev_state) -> void:
	var anim_sprite = owner.get("animated_sprite")
	if anim_sprite:
		anim_sprite.play("air")

func physics(owner: Node, delta: float) -> void:
	# Apply gravity
	if owner.has_method("apply_gravity"):
		owner.apply_gravity(delta)
	
	# Allow horizontal movement in air
	var direction = 0.0
	if owner.has_method("get_input_direction"):
		direction = owner.get_input_direction()
	
	if abs(direction) > 0.1:
		var move_speed = owner.get("MOVE_SPEED") if owner.get("MOVE_SPEED") else 100.0
		owner.velocity.x = direction * move_speed
		
		if owner.has_method("update_facing_direction"):
			owner.update_facing_direction(direction)
	
	# Check for landing
	if owner.get("is_on_floor_cached"):
		if owner.has_method("switch_state"):
			owner.switch_state("Land")
	
	# Check for wall slide
	elif owner.get("is_on_wall_cached") and owner.velocity.y > 0:
		if owner.has_method("switch_state"):
			owner.switch_state("WallSlide")
