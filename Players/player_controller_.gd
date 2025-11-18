extends CharacterBody3D

signal OnTakeDamage(damage)
signal OnUpdateScore(score)

@export var use_gamepad: bool = false
@export var movement_smoothing: float = 12.0
@export var rotation_smoothing: float = 10.0

#======================   Camera  ===================================
@onready var camera: Camera3D = $third_person_controller/SpringArm3D/Camera3D
@onready var third_person_controller: Node3D = $third_person_controller
@onready var animator: AnimationTree = $Mesh/AnimationTree

#=========================================================
@export var charater_mesh: Node3D

''' ======================= Movement Code =================================='''
# Enhanced movement constants for smoother feel
const ROTATION_SPEED = 15.0
const RUN_SPEED: float = 7
const WALK_SPEED: float = 2
const JUMP_VELOCITY = 4.5

# Enhanced movement variables
var can_move: bool = true
var is_moving: bool = false
var cur_speed: float = 2
var move_direction

# Smoothing and polish variables
var health: int = 100
# State tracking for enhanced feel
var movement_vector: Vector3 = Vector3.ZERO
var target_velocity: Vector3 = Vector3.ZERO
var is_talking: bool = false

# Jump variables
var was_on_floor: bool = true
''' ======================================================================='''

var in_selection: bool = false

# Animation sync variables (these will be synchronized)
var sync_velocity: Vector3 = Vector3.ZERO
var sync_is_on_floor: bool = true
var sync_blend_amount: float = -1.0

func _ready() -> void:
	if third_person_controller:
		third_person_controller.use_gamepad = use_gamepad

func _physics_process(delta: float) -> void:

	
	if not in_selection:
		handle_movement(delta)
		handle_jump()
		move_and_slide()
		update_movement_state_tracking(delta)
		check_landing()
		fall_damage()
		check_fall()
		
		
		# Animate based on local state
		animate(delta)

func animate(delta):
	"""Animation for local player"""
	if is_on_floor():
		animator.set("parameters/ground_air_transition/transition_request", "grounded")
		
		var horizontal_speed = Vector2(velocity.x, velocity.z).length()
		
		if horizontal_speed > 0.1:
			if cur_speed == RUN_SPEED:
				sync_blend_amount = lerp(sync_blend_amount, 1.0, delta * 7.0)
			else:
				sync_blend_amount = lerp(sync_blend_amount, 0.0, delta * 7.0)
		else:
			sync_blend_amount = lerp(sync_blend_amount, -1.0, delta * 7.0)
		
		animator.set("parameters/iwr_blend/blend_amount", sync_blend_amount)
	else:
		animator.set("parameters/ground_air_transition/transition_request", "air")
		sync_blend_amount = 0.0
		animator.set("parameters/iwr_blend/blend_amount", sync_blend_amount)


func handle_movement(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta
	handle_third_person_movement(delta)

func disable_camera():
	if camera:
		camera.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	in_selection = true

func make_it_use_gamepad(val: bool):
	use_gamepad = val
	if third_person_controller:
		third_person_controller.use_gamepad = val
		third_person_controller.player_index = 0 if val == false else 1

func handle_jump():
	if !use_gamepad:
		if Input.is_action_just_pressed("Jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	else:
		if Input.is_action_just_pressed("make_jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			
func check_landing():
	was_on_floor = is_on_floor()

func handle_third_person_movement(delta: float):
	var input_dir = Vector2.ZERO

	if use_gamepad:
		input_dir.x = Input.get_action_strength("move_r") - Input.get_action_strength("move_l")
		input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		input_dir.x *= -1.0

		if input_dir.length() < 0.15:
			input_dir = Vector2.ZERO
		else:
			input_dir = input_dir.normalized()
	else:
		if Input.is_action_pressed("move_forward"):
			input_dir.y -= 1
		if Input.is_action_pressed("move_back"):
			input_dir.y += 1
		if Input.is_action_pressed("move_left"):
			input_dir.x += 1
		if Input.is_action_pressed("move_right"):
			input_dir.x -= 1

	# Check if running
	if !use_gamepad:
		if Input.is_action_pressed("run"):
			cur_speed = RUN_SPEED
		else:
			cur_speed = WALK_SPEED
	else:
		# For gamepad, you might want to use analog stick magnitude or a button
		cur_speed = WALK_SPEED

	# Convert to 3D movement
	if third_person_controller:
		var camera_basis = third_person_controller.global_transform.basis
		move_direction = (camera_basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
	else:
		move_direction = Vector3.ZERO

	# Movement with smoothing
	if move_direction != Vector3.ZERO:
		target_velocity = Vector3(move_direction.x * cur_speed, velocity.y, move_direction.z * cur_speed)
		velocity.x = lerp(velocity.x, target_velocity.x, movement_smoothing * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, movement_smoothing * delta)
		
		face_direction(move_direction, delta)
		
		if not is_moving:
			is_moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, cur_speed * 8 * delta)
		velocity.z = move_toward(velocity.z, 0, cur_speed * 8 * delta)
		
		if is_moving and velocity.length() < 0.1:
			is_moving = false

func face_direction(direction: Vector3, delta: float):
	if direction != Vector3.ZERO and charater_mesh:
		var target_rotation = atan2(direction.x, direction.z)
		var current_rotation = charater_mesh.rotation.y
		var new_rotation = lerp_angle(current_rotation, target_rotation, rotation_smoothing * delta)
		charater_mesh.rotation.y = new_rotation

func set_movements(movements: bool):
	velocity = Vector3.ZERO
	can_move = movements

func update_movement_state_tracking(delta: float):
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	is_moving = horizontal_speed > 0.1

func get_movement_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()

func get_movement_direction() -> Vector3:
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
	return horizontal_vel.normalized() if horizontal_vel.length() > 0.1 else Vector3.ZERO

func is_airborne() -> bool:
	return not is_on_floor()

func fall_damage():
	if global_position.y < -10:
		var respawn = get_tree().get_first_node_in_group("respwan_point")
		if respawn:
			position = respawn.position

func check_fall():
	if global_position.y < -10:
		var respawn = get_tree().get_first_node_in_group("respwan_point")
		if respawn:
			self.global_position = respawn.global_position
		
func increase_score(value):
	pass

func take_damage(value):
	var respawn = get_tree().get_first_node_in_group("respwan_point")
	if respawn:
		position = respawn.position

func move_to_level():
	var respawn = get_tree().get_first_node_in_group("respwan_point")
	if respawn:
		self.global_position = respawn.position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
