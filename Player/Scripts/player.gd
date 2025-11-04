extends CharacterBody3D

#======================   Camera  ===================================
@onready var third_person_controller: Node3D = $third_person_controller
@onready var camera: Camera3D = $third_person_controller/SpringArm3D/Camera3D

#=========================================================
@onready var state_machine: LimboHSM = $LimboHSM
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var charater_mesh: Node3D = $rhead

''' ======================= Movement Settings =================================='''
@export var use_gamepad: bool = false
@export var movement_smoothing: float = 12.0
@export var rotation_smoothing: float = 10.0
@export var stick_sensitivity: float = 1.2  # adjust stick response curve

# Movement constants
const ROTATION_SPEED = 15.0
const RUN_SPEED: float = 7
const JUMP_HORIZONTAL_SPEED: float = 8
const WALK_SPEED: float = 2
const JUMP_VELOCITY = 4.5

# Movement state
var can_move: bool = true
var is_moving: bool = false
var cur_speed: float = 2
var move_direction: Vector3 = Vector3.ZERO
var movement_vector: Vector3 = Vector3.ZERO
var target_velocity: Vector3 = Vector3.ZERO
var in_selection: bool = false
''' ======================================================================='''
func _ready() -> void:

	third_person_controller.use_gamepad = use_gamepad

func _physics_process(delta: float) -> void:
	if in_selection:
		return
	handle_movement(delta)
	handle_jump()
	move_and_slide()
	update_movement_state_tracking(delta)
	check_fall()
func handle_jump():
	if use_gamepad:
		if Input.is_action_just_pressed("make_jump"):
			state_machine.dispatch("to_jump")
	else:
		if Input.is_action_just_pressed("Jump"):
			state_machine.dispatch("to_jump")
func disable_camera():
	camera.current = false
	in_selection  = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("is camera: ", camera.current)


func handle_movement(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump logic
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		if state_machine.get_active_state() == state_machine.run:
			state_machine.dispatch("to_jump")
		else:
			state_machine.dispatch("to_stand_jump")
	
	# Speed selection
	if state_machine.get_active_state() == state_machine.run:
		cur_speed = RUN_SPEED
	elif state_machine.get_active_state() == state_machine.walk:
		cur_speed = WALK_SPEED
	
	handle_third_person_movement(delta)


func handle_third_person_movement(delta: float):
	var input_dir = Vector2.ZERO

	if use_gamepad:
		# Left stick movement
		input_dir.x = Input.get_action_strength("move_r") - Input.get_action_strength("move_l")
		input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

		# X inverted by default for correct third-person feel
		input_dir.x *= -1.0

		# Apply deadzone
		if input_dir.length() < 0.15:
			input_dir = Vector2.ZERO
		else:
			input_dir = input_dir.normalized()
	else:
		# Keyboard movement
		if Input.is_action_pressed("move_forward"):
			input_dir.y -= 1
		if Input.is_action_pressed("move_back"):
			input_dir.y += 1
		if Input.is_action_pressed("move_left"):
			input_dir.x += 1
		if Input.is_action_pressed("move_right"):
			input_dir.x -= 1

	# Convert to 3D movement based on camera
	var camera_basis = third_person_controller.global_transform.basis
	move_direction = (camera_basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()

	if state_machine.get_active_state() == state_machine.jump:
		return

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
func make_it_use_gamepad(val:bool):
	use_gamepad = val
	third_person_controller.use_gamepad = val
	third_person_controller.player_index = 0 if val == false else 1
	
func face_direction(direction: Vector3, delta: float):
	if direction != Vector3.ZERO:
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


func check_fall():
	if global_position.y < -10:
		self.global_position = get_tree().get_first_node_in_group("respwan_point").global_position
func take_damage(val):
	self.global_position = get_tree().get_first_node_in_group("respwan_point").global_position

func get_movement_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func get_movement_direction() -> Vector3:
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
	return horizontal_vel.normalized() if horizontal_vel.length() > 0.1 else Vector3.ZERO


func is_airborne() -> bool:
	return not is_on_floor()

func increase_score(s):
	pass
