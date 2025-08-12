# SPEC: Godot 4, Repto Rumble
# - States extend BaseState (Resource)
# - AnimatedSprite2D animations: idle/run/jump_start/air/land/attack_*/hurt/wall_*
# - Use MoveRunner + frame events to spawn Hitbox.tscn at HitSocketA/B

extends "res://scripts/core/player/states/base_state.gd"
class_name WallJumpState

func enter(owner: Node, _prev_state) -> void:
	var anim_sprite = owner.get("animated_sprite")
	if anim_sprite:
		if anim_sprite.sprite_frames.has_animation("wall_jump"):
			anim_sprite.play("wall_jump")
		else:
			anim_sprite.play("air")
	
	# Apply wall jump force
	if owner.has_method("get_wall_direction"):
		var wall_dir = owner.get_wall_direction()
		var wall_jump_force = owner.get("WALL_JUMP_FORCE") if owner.get("WALL_JUMP_FORCE") else Vector2(250, -350)
		
		owner.velocity.x = wall_jump_force.x * -wall_dir
		owner.velocity.y = wall_jump_force.y
		
		# Update facing direction
		if owner.has_method("update_facing_direction"):
			owner.update_facing_direction(-wall_dir)

func physics(owner: Node, delta: float) -> void:
	# Apply gravity
	if owner.has_method("apply_gravity"):
		owner.apply_gravity(delta)
	
	# Limited air control during wall jump
	var direction = 0.0
	if owner.has_method("get_input_direction"):
		direction = owner.get_input_direction()
	
	if abs(direction) > 0.1:
		var move_speed = owner.get("MOVE_SPEED") if owner.get("MOVE_SPEED") else 100.0
		# Reduced air control during wall jump
		owner.velocity.x = move_toward(owner.velocity.x, direction * move_speed, move_speed * 0.5 * delta)
	
	# Transition to air state after a short time or when falling
	if owner.velocity.y > 100: # Falling fast enough
		if owner.has_method("switch_state"):
			owner.switch_state("Air")
	
	# Check for landing
	if owner.get("is_on_floor_cached"):
		if owner.has_method("switch_state"):
			owner.switch_state("Land")
