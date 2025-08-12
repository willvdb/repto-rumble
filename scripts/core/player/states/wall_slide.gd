# SPEC: Godot 4, Repto Rumble
# - States extend BaseState (Resource)
# - AnimatedSprite2D animations: idle/run/jump_start/air/land/attack_*/hurt/wall_*
# - Use MoveRunner + frame events to spawn Hitbox.tscn at HitSocketA/B

extends "res://scripts/core/player/states/base_state.gd"
class_name WallSlideState

func enter(owner: Node, _prev_state) -> void:
	var anim_sprite = owner.get("animated_sprite")
	if anim_sprite:
		if anim_sprite.sprite_frames.has_animation("wall_slide"):
			anim_sprite.play("wall_slide")
		else:
			# Fallback to air animation
			anim_sprite.play("air")

func physics(owner: Node, delta: float) -> void:
	# Apply limited gravity (wall slide effect)
	if not owner.get("is_on_floor_cached"):
		var slide_speed = owner.get("WALL_SLIDE_SPEED") if owner.get("WALL_SLIDE_SPEED") else 80.0
		owner.velocity.y = min(owner.velocity.y + owner.get("GRAVITY") * delta * 0.3, slide_speed)
	
	# Check for wall jump
	if owner.input_provider.is_action_just_pressed("jump"):
		var jump_cost = owner.get("JUMP_STAMINA_COST") if owner.get("JUMP_STAMINA_COST") else 20.0
		if owner.has_method("consume_stamina") and owner.consume_stamina(jump_cost):
			if owner.has_method("switch_state"):
				owner.switch_state("WallJump")
	
	# Check for leaving wall or landing
	if owner.get("is_on_floor_cached"):
		if owner.has_method("switch_state"):
			owner.switch_state("Land")
	elif not owner.get("is_on_wall_cached"):
		if owner.has_method("switch_state"):
			owner.switch_state("Air")
