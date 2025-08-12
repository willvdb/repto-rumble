# SPEC: Godot 4, Repto Rumble
# - States extend BaseState (Resource)
# - AnimatedSprite2D animations: idle/run/jump_start/air/land/attack_*/hurt/wall_*
# - Use MoveRunner + frame events to spawn Hitbox.tscn at HitSocketA/B

extends "res://scripts/core/player/states/base_state.gd"
class_name IdleState

func enter(owner: Node, _prev_state) -> void:
	if owner.has_method("animated_sprite") or owner.get("animated_sprite"):
		var anim_sprite = owner.get("animated_sprite")
		if anim_sprite and anim_sprite.sprite_frames:
			if anim_sprite.sprite_frames.has_animation("idle"):
				anim_sprite.play("idle")
			else:
				anim_sprite.play("default")

func physics(owner: Node, delta: float) -> void:
	# Apply gravity
	if owner.has_method("apply_gravity"):
		owner.apply_gravity(delta)
	
	# Check for input to transition to run
	var direction = 0.0
	if owner.has_method("get_input_direction"):
		direction = owner.get_input_direction()
	
	if abs(direction) > 0.1:
		if owner.has_method("switch_state"):
			owner.switch_state("Run")
		return
	
	# Check for jump input
	if owner.input_provider.is_action_just_pressed("jump") and owner.get("is_on_floor_cached"):
		var jump_cost = owner.get("JUMP_STAMINA_COST") if owner.get("JUMP_STAMINA_COST") else 20.0
		if owner.has_method("consume_stamina") and owner.consume_stamina(jump_cost):
			var jump_velocity = owner.get("JUMP_VELOCITY") if owner.get("JUMP_VELOCITY") else -400.0
			owner.velocity.y = jump_velocity
			if owner.has_method("switch_state"):
				owner.switch_state("JumpStart")
		return
	
	# Friction when idle
	var move_speed = owner.get("MOVE_SPEED") if owner.get("MOVE_SPEED") else 100.0
	owner.velocity.x = move_toward(owner.velocity.x, 0, move_speed)
