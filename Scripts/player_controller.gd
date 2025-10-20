extends CharacterBody3D

signal OnTakeDamage(damage)
signal OnUpdateScore(score)


@export var movement_smoothing: float = 12.0
@export var rotation_smoothing: float = 10.0
#======================   Camera  ===================================
@onready var camera: Camera3D = $third_person_controller/SpringArm3D/Camera3D
@onready var third_person_controller: Node3D = $third_person_controller

#=========================================================
@onready var charater_mesh: MeshInstance3D = $Model

''' ======================= Movement Code =================================='''
# Enhanced movement constants for smoother feel
const ROTATION_SPEED = 15.0  # Slightly faster rotation for better responsiveness
const RUN_SPEED: float = 7
const WALK_SPEED: float = 2
const JUMP_VELOCITY = 4.5

# Enhanced movement variablabel_2les
var can_move: bool = true
var is_moving: bool = false
var cur_speed: float = 2
var move_direction

# Smoothing and polish variables
var health :int = 100
# State tracking for enhanced feel
var movement_vector: Vector3 = Vector3.ZERO
var target_velocity: Vector3 = Vector3.ZERO
var is_talking: bool = false
''' ======================================================================='''

func _ready() -> void:
	if is_multiplayer_authority():
		camera.current = true
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return

	# Enhanced movement with polish
	handle_movement(delta)
	move_and_slide()
	update_movement_state_tracking(delta)
	#if Input.is_action_just_pressed("free_mouse"):
		#if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#else:
			#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func handle_movement(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta


	
	
	# Handle movement based on camera mode
	handle_third_person_movement(delta)

# PRESERVED: Original third person movement
func handle_third_person_movement(delta: float):

	# Get input direction
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_back"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x += 1
	if Input.is_action_pressed("move_right"):
		input_dir.x -= 1
	
	# Calculate movement direction based on camera orientation
	var camera_basis = third_person_controller.global_transform.basis
	move_direction = (camera_basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()


	# Enhanced movement with smoother transitions
	if move_direction != Vector3.ZERO:
		# Smooth movement transition
		target_velocity = Vector3(move_direction.x * cur_speed, velocity.y, move_direction.z * cur_speed)
		velocity.x = lerp(velocity.x, target_velocity.x, movement_smoothing * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, movement_smoothing * delta)
		
		face_direction(move_direction, delta)

		# Emit movement started signal
		if not is_moving:
			is_moving = true
	else:
		#velocity = Vector3.ZERO
		# Enhanced friction with smoothing
		velocity.x = move_toward(velocity.x, 0, cur_speed * 8 * delta)
		velocity.z = move_toward(velocity.z, 0, cur_speed * 8 * delta)
		
		# Emit movement stopped signal
		if is_moving and velocity.length() < 0.1:
			is_moving = false

# PRESERVED: Original rotation function
func face_direction(direction: Vector3, delta: float):
	if direction != Vector3.ZERO:
		# Calculate target rotation
		var target_rotation = atan2(direction.x, direction.z)
		
		# Smoothly rotate towards target with enhanced smoothing
		var current_rotation = charater_mesh.rotation.y
	
		var new_rotation = lerp_angle(current_rotation, target_rotation, rotation_smoothing * delta)

		charater_mesh.rotation.y = new_rotation



# PRESERVED: Original movement setter
func set_movements(movements: bool):
	velocity = Vector3.ZERO
	can_move = movements

# NEW: Additional utility functions for enhanced feel
func update_movement_state_tracking(delta: float):
	# Update movement state based on actual velocity
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	is_moving = horizontal_speed > 0.1

# NEW: Get current movement info (useful for other systems)
func get_movement_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()

func get_movement_direction() -> Vector3:
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
	return horizontal_vel.normalized() if horizontal_vel.length() > 0.1 else Vector3.ZERO

func is_airborne() -> bool:
	return not is_on_floor()

# NEW: Enhanced landing and impact system
func _on_player_landed(impact_force: float):
	# Hook for landing effects - screen shake, particles, sound, etc.
	# You can connect this signal to other systems
	pass

func _on_player_jumped():
	# Hook for jump effects - particles, sound, etc.
	pass

func _on_movement_started():
	# Hook for movement start effects - dust particles, footstep sounds, etc.
	pass

func _on_movement_stopped():
	# Hook for movement stop effects - stopping dust, etc.
	pass
func apply_item_effects(item):
	pass
