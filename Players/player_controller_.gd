extends CharacterBody3D

signal OnTakeDamage(damage)
signal OnUpdateScore(score)
#developer added code
signal UpdatePlayerStats(health, powerup_exp)
##

@export var use_gamepad: bool = false
@export var movement_smoothing: float = 12.0
@export var rotation_smoothing: float = 10.0

#developer added code
#======================   Powerups Cost  ===================================
@export var powerup_cost: int = 100
#=========================================================

#======================   Powerups Delay  ===================================
@export var dw_powerup_lasting_time: int = 10
@export var anon_powerup_lasting_time_lowest: int = 5
@export var anon_powerup_lasting_time_highest: int = 10

@export var medal_powerup_lasting_time: int = 5
#=========================================================
###

#======================   Camera  ===================================
@onready var camera: Camera3D = $third_person_controller/SpringArm3D/Camera3D
@onready var third_person_controller: Node3D = $third_person_controller
@onready var animator: AnimationTree = $Mesh/AnimationTree
#=========================================================

#developer added code
#======================   Particles  ===================================
@onready var dwcpu_particles_3d: CPUParticles3D = $Particles/DWCPUParticles3D
@onready var anon_cpu_particles_3d: CPUParticles3D = $Particles/AnonCPUParticles3D
@onready var medal_cpu_particles_3d: CPUParticles3D = $Particles/MedalCPUParticles3D
#=========================================================

#======================   PowerupTimers  ===================================
@onready var dw_timer: Timer = $PowerupTimer/DWTimer
@onready var anon_timer: Timer = $PowerupTimer/AnonTimer
@onready var medal_timer: Timer = $PowerupTimer/MedalTimer
#=========================================================

#======================   PowerupArea3D  ===================================
@onready var dw_powerup_area_3d: Area3D = $PowerupsArea3DHolder/DwPowerupArea3D
#=========================================================
####

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
var is_running: bool = false
var move_direction
var knock_back_force: Vector3 = Vector3.ZERO

# Smoothing and polish variables
var health :int = 100
#developer added code
var powerup_exp:int = 0
const MAX_POWERUP_EXP: int = 100
###

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
		handle_powerups()
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
		if Input.is_action_pressed("run") or is_running:
			cur_speed = RUN_SPEED
		else:
			cur_speed = WALK_SPEED
	else:
		# For gamepad, you might want to use analog stick magnitude or a button
		if not is_running:
			cur_speed = WALK_SPEED
		else:
			cur_speed = RUN_SPEED

	# Convert to 3D movement
	if third_person_controller:
		var camera_basis = third_person_controller.global_transform.basis
		move_direction = (camera_basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
	else:
		move_direction = Vector3.ZERO

	# Movement with smoothing
	if move_direction != Vector3.ZERO:
		target_velocity = Vector3(move_direction.x * cur_speed + knock_back_force.x, velocity.y, move_direction.z * cur_speed + knock_back_force.z)
		velocity.x = lerp(velocity.x, target_velocity.x, movement_smoothing * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, movement_smoothing * delta)
		
		face_direction(move_direction, delta)
		
		if not is_moving:
			is_moving = true
	else:
		velocity.x = move_toward(velocity.x, 0 + knock_back_force.x, cur_speed * 8 * delta)
		velocity.z = move_toward(velocity.z, 0 + knock_back_force.z, cur_speed * 8 * delta)
		
		if is_moving and velocity.length() < 0.1:
			is_moving = false

	if knock_back_force.length() > 0:
		knock_back_force.x = lerpf(knock_back_force.x, 0, 10 * delta)
		knock_back_force.z = lerpf(knock_back_force.z, 0, 10 * delta)

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
		take_damage(10)
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


func handle_powerups():
	if !use_gamepad:
		if Input.is_action_just_pressed("use_powerup_1"):
			enable_dw_powerup()
		elif Input.is_action_just_pressed("user_powerup_2"):
			enable_anon_powerup()
		elif Input.is_action_just_pressed("use_powerup_3"):
			enable_medal_powerup()
	else:
		if Input.is_action_just_pressed("make_use_powerup_1"):
			enable_dw_powerup()
		elif Input.is_action_just_pressed("make_use_powerup_2"):
			enable_anon_powerup()
		elif Input.is_action_just_pressed("make_use_powerup_3"):
			enable_medal_powerup()

#this function is being called in the blue orb scene, it is triggered anytime the player collides with it
func increase_powerup_exp(collection_value: int):
	if powerup_exp < MAX_POWERUP_EXP:
		powerup_exp += collection_value
		powerup_exp = clampi(powerup_exp, 0, MAX_POWERUP_EXP)
		print("player colelcting experience")
		update_player_stats_in_ui()

#this function is called in enable_dw,anon_medal_powerup, it is triggered anytime the player enables a powerup
## this function is created to prevent powerup stacking
func disable_all_powerups():
	dw_timer.stop()
	anon_timer.stop()
	medal_timer.stop()
	disable_dw_powerup()
	disable_anon_powerup()
	disable_medal_powerup()

#this function is called in enable_dw,anon,medal_powerup, it is triggered anytime the player activates the powerup
func use_powerup_exp(cost: int):
	if powerup_exp >= cost:
		powerup_exp -= cost
		powerup_exp = clampi(powerup_exp, 0, MAX_POWERUP_EXP)
		update_player_stats_in_ui()

#this function is called in the _input function, it is triggered when the user presses a key
func enable_dw_powerup():
	if powerup_exp >= powerup_cost:
		disable_all_powerups()
		use_powerup_exp(powerup_cost)
		is_running = true
		cur_speed = RUN_SPEED 
		dw_powerup_area_3d.monitorable = true
		dw_powerup_area_3d.monitoring = true
		dwcpu_particles_3d.emitting = true
		dw_timer.wait_time = dw_powerup_lasting_time
		dw_timer.start()
		print("dw powerup activated")

func disable_dw_powerup():
	cur_speed = WALK_SPEED
	is_running = false
	dw_powerup_area_3d.monitorable = false
	dw_powerup_area_3d.monitoring = false
	print("dw powerup deactivated")

#this function is called in the _input function, it is triggered when the user presses a key
func enable_anon_powerup():
	if powerup_exp >= powerup_cost:
		disable_all_powerups()
		use_powerup_exp(powerup_cost)
		anon_cpu_particles_3d.emitting = true
		anon_timer.wait_time = randf_range(anon_powerup_lasting_time_lowest, anon_powerup_lasting_time_highest)
		anon_timer.start()
		if charater_mesh:
			charater_mesh.hide()
		print("anon powerup activated")

func disable_anon_powerup():
	if not charater_mesh.visible:
		charater_mesh.show()
		print("anon powerup deactivated")

#this function is called in the _input function, it is triggered when the user presses a key
func enable_medal_powerup():
	if powerup_exp >= powerup_cost:
		disable_all_powerups()
		use_powerup_exp(powerup_cost)
		self.set_collision_layer_value(1, false)
		self.set_collision_mask_value(1, false)
		medal_cpu_particles_3d.emitting = true
		medal_timer.wait_time = medal_powerup_lasting_time
		medal_timer.start()
		print("medal powerup activated")

func disable_medal_powerup():
	self.set_collision_layer_value(1, true)
	self.set_collision_mask_value(1, true)
	print("medal powerup deactivated")

func knock_back(direction, power):
	var knock_force: Vector3 = direction * power
	knock_back_force = knock_force

func update_player_stats_in_ui():
	UpdatePlayerStats.emit(health, powerup_exp)
	print("sending signals")

func take_damage(value):
	var respawn = get_tree().get_first_node_in_group("respwan_point")
	if respawn:
		position = respawn.position

func move_to_level():
	var respawn = get_tree().get_first_node_in_group("respwan_point")
	if respawn:
		self.global_position = respawn.position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))

func _on_dw_timer_timeout() -> void:
	disable_dw_powerup()

func _on_anon_timer_timeout() -> void:
	disable_anon_powerup()

func _on_medal_timer_timeout() -> void:
	disable_medal_powerup()

func _on_dw_powerup_area_3d_body_entered(body: Node3D) -> void:
	print("jammed")
	if body.is_in_group("Player") and body != self and is_on_floor():
		print("jammed xx2")
		var look_direction: Vector3 = self.transform.basis.z.normalized()
		look_direction.y = 0
		var knock_power: int = 1000
		body.knock_back((body.global_position - self.global_position).normalized(), knock_power)
