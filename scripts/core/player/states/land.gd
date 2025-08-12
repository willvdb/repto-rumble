# SPEC: Godot 4, Repto Rumble
# - States extend BaseState (Resource)
# - AnimatedSprite2D animations: idle/run/jump_start/air/land/attack_*/hurt/wall_*
# - Use MoveRunner + frame events to spawn Hitbox.tscn at HitSocketA/B

extends "res://scripts/core/player/states/base_state.gd"
class_name LandState

func enter(owner: Node, _prev_state) -> void:
	var anim_sprite = owner.get("animated_sprite")
	if anim_sprite:
		if anim_sprite.sprite_frames.has_animation("land"):
			anim_sprite.play("land")
		else:
			# Quick transition to idle if no land animation
			if owner.has_method("switch_state"):
				owner.switch_state("Idle")

func physics(owner: Node, delta: float) -> void:
	# Apply gravity (should be minimal on ground)
	if owner.has_method("apply_gravity"):
		owner.apply_gravity(delta)
	
	# Quick transition to appropriate state
	var direction = 0.0
	if owner.has_method("get_input_direction"):
		direction = owner.get_input_direction()
	
	# Transition based on input
	if abs(direction) > 0.1:
		if owner.has_method("switch_state"):
			owner.switch_state("Run")
	else:
		if owner.has_method("switch_state"):
			owner.switch_state("Idle")

func handle_event(owner: Node, event: StringName, _data := {}) -> void:
	# Auto-transition when land animation finishes
	if event == "animation_finished":
		var direction = 0.0
		if owner.has_method("get_input_direction"):
			direction = owner.get_input_direction()
		
		if abs(direction) > 0.1:
			if owner.has_method("switch_state"):
				owner.switch_state("Run")
		else:
			if owner.has_method("switch_state"):
				owner.switch_state("Idle")
