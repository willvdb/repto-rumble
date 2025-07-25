class_name PlatformerController extends CharacterBody2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Exports
@export var move_speed: float = 100.0
@export var sprint_speed: float = 250.0
@export var coyote_time: float = 1.0
@export var jump_buffer_time: float = 0.5
@export var jump: BaseJump

@export var hit_box: HitBox

@export var wall_slide_speed: float = 80.0
@export var wall_jump_force: Vector2 = Vector2(250, -350) # (x, y) force applied on wall jump

@export var max_stamina: float = 100.0
@export var stamina_recovery_rate: float = 20.0 # per second
@export var sprint_stamina_drain: float = 25.0 # per second
@export var jump_stamina_cost: float = 20.0

# Private variables
var _can_move: bool = true
var _is_coyote_time: bool = false
var _is_jump_buffered: bool = false
var _is_wall_sliding: bool = false
@onready var _coyote_time_tween: Tween = create_tween()
@onready var _jump_buffer_tween: Tween = create_tween()
@onready var _is_on_floor: bool = is_on_floor()
@onready var _is_on_wall: bool = is_on_wall()
@onready var _animated_sprite: AnimatedSprite2D = $Circle

signal on_move_ground()
signal on_jump_start()
signal on_jump_end()
signal stamina_changed(current_stamina: float, max_stamina: float)

var stamina: float = max_stamina

func _enter_tree():
	if jump:
		jump.register(self)
	
func _exit_tree():
	if jump:
		jump.unregister()

func _ready():
	_coyote_time_tween.tween_callback(
		func(): _is_coyote_time = true
	)
	_coyote_time_tween.tween_interval(coyote_time)
	_coyote_time_tween.tween_callback(
		func(): _is_coyote_time = false
	)
	_coyote_time_tween.stop()
	
	_jump_buffer_tween.tween_callback(
		func(): _is_jump_buffered = true
	)
	_jump_buffer_tween.tween_interval(jump_buffer_time)
	_jump_buffer_tween.tween_callback(
		func(): _is_jump_buffered = false
	)
	_jump_buffer_tween.stop()
	
	if hit_box:
		hit_box.on_killed.connect(
			func(): _can_move = false
		)
	
	# Start with idle animation
	_animated_sprite.play("idle")

func _physics_process(delta):
	_check_floor()
	_check_wall()
	
	_apply_gravity(delta)
	_apply_wall_slide()
	_apply_wall_jump()
	_apply_movement(delta)
	_recover_stamina(delta)

# --- STAMINA RECOVERY ---
func _recover_stamina(delta):
	var old_stamina = stamina
	if stamina < max_stamina:
		stamina += stamina_recovery_rate * delta
		stamina = min(stamina, max_stamina)
	
	# Emit signal if stamina changed
	if old_stamina != stamina:
		stamina_changed.emit(stamina, max_stamina)

# --- WALL SLIDE LOGIC ---
func _apply_wall_slide():
	_is_wall_sliding = false
	if _is_on_wall and not _is_on_floor and velocity.y > 0:
		_is_wall_sliding = true
		velocity.y = min(velocity.y, wall_slide_speed)

# --- WALL JUMP LOGIC ---
func _apply_wall_jump():
	if not _can_move: return
	
	var can_wall_jump = _is_on_wall and not _is_on_floor

	if (Input.is_action_just_pressed("jump") or (_is_jump_buffered and _is_on_floor)):
		if _can_jump() and stamina >= jump_stamina_cost:
			stamina -= jump_stamina_cost
			stamina_changed.emit(stamina, max_stamina)
			on_jump_start.emit()
			_stop_coyote_time()
			_stop_jump_buffer()
		elif can_wall_jump and stamina >= jump_stamina_cost:
			stamina -= jump_stamina_cost
			stamina_changed.emit(stamina, max_stamina)
			on_jump_start.emit()
			_stop_coyote_time()
			_stop_jump_buffer()
			var wall_dir = get_wall_direction()
			velocity.x = wall_jump_force.x * -wall_dir
			velocity.y = wall_jump_force.y
			if _animated_sprite.animation != "wall_jump":
				_animated_sprite.play("wall_jump")
	elif Input.is_action_just_released("jump"):
		on_jump_end.emit()

# Returns -1 if wall is left, 1 if right, 0 if none
func get_wall_direction() -> int:
	var space_state = get_world_2d().direct_space_state
	var left_params = PhysicsRayQueryParameters2D.new()
	left_params.from = global_position
	left_params.to = global_position + Vector2(-2, 0)
	left_params.exclude = [self]
	var left_check = space_state.intersect_ray(left_params)

	var right_params = PhysicsRayQueryParameters2D.new()
	right_params.from = global_position
	right_params.to = global_position + Vector2(2, 0)
	right_params.exclude = [self]
	var right_check = space_state.intersect_ray(right_params)

	if left_check:
		return -1
	elif right_check:
		return 1
	return 0

func _check_floor():
	if _is_on_floor and not is_on_floor():
		_on_leave_floor()
		
	if not _is_on_floor and is_on_floor():
		_on_touch_floor()
	
	_is_on_floor = is_on_floor()

func _check_wall():
	if _is_on_wall and not is_on_wall():
		_on_leave_wall()
		
	if not _is_on_wall and is_on_wall():
		_on_touch_wall()
	
	_is_on_wall = is_on_wall()

func _apply_gravity(delta):
	if not _is_on_floor:
		velocity.y += gravity * delta

func _apply_movement(_delta):
	var direction = Input.get_axis("move_left", "move_right") if _can_move else 0.0
	var speed = move_speed
	var sprinting = Input.is_action_pressed("ui_shift") and stamina > 0.0 and direction != 0.0
	var old_stamina = stamina
	if sprinting:
		speed = sprint_speed
		_animated_sprite.speed_scale = 1.8 # Increase animation speed when sprinting
		stamina -= sprint_stamina_drain * _delta
		stamina = max(stamina, 0.0)
	else:
		_animated_sprite.speed_scale = 1.0 # Normal animation speed
	
	# Emit signal if stamina changed
	if old_stamina != stamina:
		stamina_changed.emit(stamina, max_stamina)
	
	if direction:
		velocity.x = direction * speed
		# Flip sprite based on direction
		_animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)

	if _is_on_floor:
		on_move_ground.emit()
	
	# Update animations based on state
	_update_animations()
	
	move_and_slide()

func _update_animations():
	if _is_wall_sliding:
		if _animated_sprite.animation != "wall_slide":
			_animated_sprite.play("wall_slide")
	elif not _is_on_floor:
		# In air (but not wall sliding or wall jumping)
		if _animated_sprite.animation != "air":
			_animated_sprite.play("air")
	elif abs(velocity.x) > 0:
		# Moving on ground
		if _animated_sprite.animation != "moving":
			_animated_sprite.play("moving")
	else:
		# Idle on ground
		if _animated_sprite.animation != "idle":
			_animated_sprite.play("idle")

func _apply_jump():
	if not _can_move: return
	
	if Input.is_action_just_pressed("jump") or (_is_jump_buffered and _is_on_floor):
		if _can_jump():
			on_jump_start.emit()
			_stop_coyote_time()
			_stop_jump_buffer()
		else:
			_start_jump_buffer()

	elif Input.is_action_just_released("jump"):
		on_jump_end.emit()

func _on_touch_floor():
	_stop_coyote_time()
	
func _on_leave_floor():
	if velocity.y >= 0.0:
		_start_coyote_time()

func _on_touch_wall():
	pass
	
func _on_leave_wall():
	pass

func _can_jump():
	return _is_coyote_time or _is_on_floor
 
func _start_coyote_time():
	_coyote_time_tween.play()
	
func _stop_coyote_time():
	_is_coyote_time = false
	_coyote_time_tween.stop()

func _start_jump_buffer():
	if _is_jump_buffered:
		return
		
	_jump_buffer_tween.play()
	
func _stop_jump_buffer():
	_is_jump_buffered = false
	_jump_buffer_tween.stop()

# Method to change character sprite
func change_character_sprite(new_texture: Texture2D):
	# Update all animation frames to use the new texture
	var sprite_frames = _animated_sprite.sprite_frames
	for animation_name in sprite_frames.get_animation_names():
		for i in sprite_frames.get_frame_count(animation_name):
			sprite_frames.set_frame_texture(animation_name, i, new_texture)

# Method to add new animation with different sprite
func add_character_animation(animation_name: String, texture: Texture2D, frame_count: int = 1, fps: float = 5.0):
	var sprite_frames = _animated_sprite.sprite_frames
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_speed(animation_name, fps)
	sprite_frames.set_animation_loop(animation_name, true)
	
	for i in frame_count:
		sprite_frames.add_frame(animation_name, texture)
