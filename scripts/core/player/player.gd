# SPEC: Godot 4, Repto Rumble
# - States extend BaseState (Resource)
# - AnimatedSprite2D animations: idle/run/jump_start/air/land/attack_*/hurt/wall_*
# - Use MoveRunner + frame events to spawn Hitbox.tscn at HitSocketA/B

class_name Player extends CharacterBody2D

# Load BaseState first
const BaseState = preload("res://scripts/core/player/states/base_state.gd")

# Physics constants
const GRAVITY = 980.0
const MOVE_SPEED = 100.0
const SPRINT_SPEED = 250.0
const JUMP_VELOCITY = -400.0
const WALL_SLIDE_SPEED = 80.0
const WALL_JUMP_FORCE = Vector2(250, -350)

# Stamina system
const MAX_STAMINA = 100.0
const STAMINA_RECOVERY_RATE = 20.0
const SPRINT_STAMINA_DRAIN = 25.0
const JUMP_STAMINA_COST = 20.0

# Current state and state management
var current_state: BaseState
var states: Dictionary = {}
var stamina: float = MAX_STAMINA

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var sockets: Node2D = $Sockets
@onready var hit_socket_a: Marker2D = $Sockets/HitSocketA
@onready var hit_socket_b: Marker2D = $Sockets/HitSocketB
@onready var move_runner: Node = $MoveRunner

# State tracking
var is_on_floor_cached: bool = false
var is_on_wall_cached: bool = false
var can_move: bool = true
var facing_direction: int = 1 # 1 = right, -1 = left

# Signals
signal stamina_changed(current_stamina: float, max_stamina: float)
signal state_changed(new_state: StringName)
signal hit_landed(data: Dictionary)

func _ready() -> void:
	add_to_group("player")
	
	# Initialize states
	_initialize_states()
	
	# Connect frame events from animated sprite
	if animated_sprite:
		animated_sprite.frame_changed.connect(_on_frame_changed)
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Start in idle state
	switch_state("Idle")

func _initialize_states() -> void:
	# Load state resources - we'll create these next
	states["Idle"] = preload("res://scripts/core/player/states/idle.gd").new()
	states["Run"] = preload("res://scripts/core/player/states/run.gd").new()
	states["JumpStart"] = preload("res://scripts/core/player/states/jump_start.gd").new()
	states["Air"] = preload("res://scripts/core/player/states/air.gd").new()
	states["Land"] = preload("res://scripts/core/player/states/land.gd").new()
	states["WallSlide"] = preload("res://scripts/core/player/states/wall_slide.gd").new()
	states["WallJump"] = preload("res://scripts/core/player/states/wall_jump.gd").new()

func _physics_process(delta: float) -> void:
	# Update cached physics state
	is_on_floor_cached = is_on_floor()
	is_on_wall_cached = is_on_wall()
	
	# Recover stamina
	_recover_stamina(delta)
	
	# Let current state handle physics
	if current_state:
		current_state.physics(self, delta)
	
	# Apply movement
	move_and_slide()

func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(self, event)

func switch_state(state_name: StringName) -> void:
	var new_state = states.get(state_name)
	if not new_state:
		push_error("State not found: " + str(state_name))
		return
	
	var prev_state = current_state
	
	# Exit current state
	if current_state:
		current_state.exit(self, new_state)
	
	# Enter new state
	current_state = new_state
	current_state.enter(self, prev_state)
	
	# Emit signal
	state_changed.emit(state_name)

func _recover_stamina(delta: float) -> void:
	var old_stamina = stamina
	if stamina < MAX_STAMINA:
		stamina += STAMINA_RECOVERY_RATE * delta
		stamina = min(stamina, MAX_STAMINA)
	
	if old_stamina != stamina:
		stamina_changed.emit(stamina, MAX_STAMINA)

func consume_stamina(amount: float) -> bool:
	if stamina >= amount:
		stamina -= amount
		stamina_changed.emit(stamina, MAX_STAMINA)
		return true
	return false

func apply_gravity(delta: float) -> void:
	if not is_on_floor_cached:
		velocity.y += GRAVITY * delta

func get_input_direction() -> float:
	if not can_move:
		return 0.0
	return Input.get_axis("move_left", "move_right")

func update_facing_direction(direction: float) -> void:
	if direction != 0:
		facing_direction = 1 if direction > 0 else -1
		animated_sprite.flip_h = facing_direction < 0

func get_wall_direction() -> int:
	var space_state = get_world_2d().direct_space_state
	var test_distance = 5.0
	
	# Check left
	var left_query = PhysicsRayQueryParameters2D.new()
	left_query.from = global_position
	left_query.to = global_position + Vector2(-test_distance, 0)
	left_query.exclude = [self]
	
	# Check right  
	var right_query = PhysicsRayQueryParameters2D.new()
	right_query.from = global_position
	right_query.to = global_position + Vector2(test_distance, 0)
	right_query.exclude = [self]
	
	var left_hit = space_state.intersect_ray(left_query)
	var right_hit = space_state.intersect_ray(right_query)
	
	if left_hit:
		return -1
	elif right_hit:
		return 1
	return 0

func _on_frame_changed() -> void:
	if current_state:
		var frame_data = {
			"frame": animated_sprite.frame,
			"animation": animated_sprite.animation
		}
		current_state.handle_event(self, "frame_changed", frame_data)

func _on_animation_finished() -> void:
	if current_state:
		var anim_data = {
			"animation": animated_sprite.animation
		}
		current_state.handle_event(self, "animation_finished", anim_data)
