# SPEC: Godot 4, Repto Rumble
# - States extend BaseState (Resource)
# - AnimatedSprite2D animations: idle/run/jump_start/air/land/attack_*/hurt/wall_*
# - Use MoveRunner + frame events to spawn Hitbox.tscn at HitSocketA/B

extends "res://scripts/core/player/states/base_state.gd"
class_name RunState

func enter(owner: Node, _prev_state) -> void:
	var anim_sprite = owner.get("animated_sprite")
	if anim_sprite:
		# Try 'run' first, fallback to 'moving' for compatibility
		if anim_sprite.sprite_frames.has_animation("run"):
			anim_sprite.play("run")
		elif anim_sprite.sprite_frames.has_animation("moving"):
			anim_sprite.play("moving")

func physics(owner: Node, delta: float) -> void:
	# Apply gravity
	if owner.has_method("apply_gravity"):
		owner.apply_gravity(delta)
	
	# Get input direction
	var direction = 0.0
	if owner.has_method("get_input_direction"):
		direction = owner.get_input_direction()
	
	# Update facing direction
	if owner.has_method("update_facing_direction"):
		owner.update_facing_direction(direction)
	
	# Handle movement
	if abs(direction) > 0.1:
		# Check for sprinting
		var speed = owner.get("MOVE_SPEED") if owner.get("MOVE_SPEED") else 100.0
		var is_sprinting = Input.is_action_pressed("ui_shift") and owner.get("stamina") > 0.0
		
		if is_sprinting:
			var sprint_speed = owner.get("SPRINT_SPEED") if owner.get("SPRINT_SPEED") else 250.0
			var drain_rate = owner.get("SPRINT_STAMINA_DRAIN") if owner.get("SPRINT_STAMINA_DRAIN") else 25.0
			speed = sprint_speed
			
			# Drain stamina
			if owner.has_method("consume_stamina"):
				owner.consume_stamina(drain_rate * delta)
			
			# Speed up animation
			var anim_sprite = owner.get("animated_sprite")
			if anim_sprite:
				anim_sprite.speed_scale = 1.8
		else:
			# Normal animation speed
			var anim_sprite = owner.get("animated_sprite")
			if anim_sprite:
				anim_sprite.speed_scale = 1.0
		
		owner.velocity.x = direction * speed
	else:
		# No input - transition to idle
		if owner.has_method("switch_state"):
			owner.switch_state("Idle")
		return
	
	# Check for jump
	if Input.is_action_just_pressed("jump") and owner.get("is_on_floor_cached"):
		var jump_cost = owner.get("JUMP_STAMINA_COST") if owner.get("JUMP_STAMINA_COST") else 20.0
		if owner.has_method("consume_stamina") and owner.consume_stamina(jump_cost):
			var jump_velocity = owner.get("JUMP_VELOCITY") if owner.get("JUMP_VELOCITY") else -400.0
			owner.velocity.y = jump_velocity
			if owner.has_method("switch_state"):
				owner.switch_state("JumpStart")

func exit(owner: Node, _next_state) -> void:
	# Reset animation speed
	var anim_sprite = owner.get("animated_sprite")
	if anim_sprite:
		anim_sprite.speed_scale = 1.0
