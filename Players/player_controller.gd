extends CharacterBody3D

signal OnTakeDamage(damage)
signal OnUpdateScore(score)


@export var use_gamepad: bool = false
@export var movement_smoothing: float = 12.0
@export var rotation_smoothing: float = 10.0

#======================   Camera  ===================================
@onready var camera: Camera3D = $third_person_controller/SpringArm3D/Camera3D
@onready var third_person_controller: Node3D = $third_person_controller

#=========================================================
@onready var player_sync: MultiplayerSynchronizer = $player_sync
@onready var multir_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var anim_sync: MultiplayerSynchronizer = $anim_sync


var mesh 
var animator : AnimationTree
var sync_blend_amount: float = -1.0
@export var start_animate: bool = false
''' ======================= Movement Code =================================='''
# Enhanced movement constants for smoother feel
const ROTATION_SPEED = 15.0  # Slightly faster rotation for better responsiveness
const RUN_SPEED: float = 7
const WALK_SPEED: float = 2
const JUMP_VELOCITY = 4.5

# Enhanced movement variables
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

# Jump variables
var was_on_floor: bool = true
''' ======================================================================='''

var in_selection: bool = false
@export var mesh_num: int = 1

# Synced properties
@export var synced_blend: float = -1.0
@export var synced_grounded: bool = true
@export var my_id : int

func _ready() -> void:
	# Set authority using the node name (which is the peer_id)
	player_sync.set_multiplayer_authority(str(name).to_int())
	multir_spawner.set_multiplayer_authority(str(name).to_int())
	await get_tree().process_frame
	
	# Apply character model based on mesh_num (already set by spawner)
	if is_multiplayer_authority():
		mesh_num = MultiplayerGlobal.selected_player_num
		print("Player ", name, " setting mesh_num to: ", mesh_num)
		
		# Change locally first
		apply_character_mesh(mesh_num)
		
	
	if camera:
		if is_multiplayer_authority():
			camera.current = true
			print("Player %s: Camera enabled (LOCAL)" % name)
		else:
			camera.current = false
			print("Player %s: Camera disabled (REMOTE)" % name)
		third_person_controller.use_gamepad = use_gamepad
		# Register with manager (this handles all syncing)
		var manager = get_parent()
		if manager and manager.has_method("register_player"):
			manager.register_player(self, int(name), mesh_num)

# Request all existing players to send their mesh data
func request_all_player_meshes():
	print("Player ", name, " requesting all player meshes")
	# Ask all other players to send their mesh info
	rpc("send_my_mesh_to_requester")

# When someone requests mesh info, send your mesh back to them
@rpc("any_peer", "call_remote", "reliable")
func send_my_mesh_to_requester():
	var requester_id = multiplayer.get_remote_sender_id()
	print("Player ", name, " sending mesh info (", mesh_num, ") to requester: ", requester_id)
	
	# Send my mesh info back to the requester only
	rpc_id(requester_id, "receive_player_mesh", int(name), mesh_num)

# Receive another player's mesh info
@rpc("any_peer", "call_remote", "reliable")
func receive_player_mesh(player_id: int, player_mesh_num: int):
	print("Received mesh info: Player ", player_id, " has mesh ", player_mesh_num)
	
	# Find that player's node and update their mesh
	var player_node = get_tree().root.get_node_or_null("Main/" + str(player_id))
	if player_node and player_node != self:
		player_node.apply_character_mesh(player_mesh_num)

# Local function that actually changes the mesh (can be called by manager)
func apply_character_mesh(num: int):
	print("Applying character mesh: ", num, " on player: ", name)
	
	# Store the mesh number
	mesh_num = num
	
	# Clear existing meshes safely
	if num == 1:
		if has_node("Mesh"):
			$Mesh.queue_free()
		if has_node("Mesh2"):
			$Mesh2.queue_free()
		if has_node("Node3D"):
			mesh = $Node3D
			mesh.visible = true
		start_animate = false
		print("Set to Node3D mesh (no animation)")
		
	elif num == 2:
		if has_node("Mesh"):
			$Mesh.queue_free()
		if has_node("Node3D"):
			$Node3D.queue_free()
		if has_node("Mesh2"):
			mesh = $Mesh2
			mesh.visible = true
			if mesh.has_node("AnimationTree"):
				animator = mesh.get_node("AnimationTree")
				print("Got animator for Mesh2: ", animator)
				start_animate = true
		
	elif num == 3:
		if has_node("Node3D"):
			$Node3D.queue_free()
		if has_node("Mesh2"):
			$Mesh2.queue_free()
		if has_node("Mesh"):
			mesh = $Mesh
			mesh.visible = true
			if mesh.has_node("AnimationTree"):
				animator = mesh.get_node("AnimationTree")
				print("Got animator for Mesh: ", animator)
				start_animate = true
	
	# Register animation data if needed (only on authority)
	if num != 1 and is_multiplayer_authority():
		my_id = multiplayer.get_unique_id()
		if Multiplayer.is_host:
			MultiplayerGlobal.add_new_player_anim(my_id, synced_grounded, synced_blend)
		else:
			rpc_id(1, "handle_server_data", my_id, synced_grounded, synced_blend)
	
	print("Character mesh applied successfully on player: ", name)

# This function runs on the server
@rpc("any_peer", "call_remote", "reliable")
func handle_server_data(id: int, synced_grounded_: bool, sync_blend_amount_: float):
	if not Multiplayer.is_host:
		return  # Security: only server should process this
	
	print("Server received data from peer %d: %s, %s" % [id, synced_grounded_, sync_blend_amount_])
	
	MultiplayerGlobal.add_new_player_anim(id, synced_grounded_, sync_blend_amount_)

func update_animation_data(id: int, grounded: bool, blend_value: float):
	if Multiplayer.is_host:
		MultiplayerGlobal.update_animations_data(
			multiplayer.get_unique_id(), synced_grounded, synced_blend
		)
	else:
		rpc_id(1, "update_client_animations_date", multiplayer.get_unique_id(), synced_grounded, synced_blend)

# This function runs on the server
@rpc("any_peer", "call_remote", "reliable")
func update_client_animations_date(id: int, grounded: bool, blend_value: float):
	MultiplayerGlobal.update_animations_data(id, grounded, blend_value)
	
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority() or in_selection:
		return
	
	# Enhanced movement with polish
	handle_movement(delta)
	handle_jump()
	move_and_slide()
	update_movement_state_tracking(delta)
	check_landing()
	fall_damage()
	check_fall()
	
	# Local player animation
	if is_multiplayer_authority() and start_animate:
		animate_local(delta)
		# Update synced values
		synced_blend = sync_blend_amount
		synced_grounded = is_on_floor()
		
		# Send to server/host
		if Multiplayer.is_host:
			# If we're the host, update directly
			MultiplayerGlobal.update_animations_data(
				multiplayer.get_unique_id(), 
				synced_grounded, 
				synced_blend
			)
		else:
			# If we're a client, send to host
			rpc_id(1, "update_server_animation_data", 
				multiplayer.get_unique_id(), 
				synced_grounded, 
				synced_blend
			)

# NEW: Server receives animation updates from clients
@rpc("any_peer", "call_remote", "reliable")
func update_server_animation_data(id: int, grounded: bool, blend_value: float):
	if not Multiplayer.is_host:
		return  # Security: only server should process this
	
	# Update the global animation data
	MultiplayerGlobal.update_animations_data(id, grounded, blend_value)
# Add this function to your player.gd script

# Receive animation data from host (runs on clients only)
@rpc("authority", "call_remote", "unreliable")
func receive_animation_data(anims_data: Dictionary):
	# Skip if this is a non-animated mesh
	if mesh_num == 1 or not start_animate or not animator:
		return
	
	# Get this player's peer ID
	var my_peer_id = int(name)  # Player node name is their peer ID
	
	# Apply animation data for all OTHER players
	for player_id in anims_data:
		# Skip self - we animate locally
		if player_id == my_peer_id:
			continue
		
		# Find the player node
		var player_node = get_parent().get_node_or_null(str(player_id))
		if not player_node:
			continue
		
		# Skip if they don't have animation
		if player_node.mesh_num == 1 or not player_node.start_animate or not player_node.animator:
			continue
		
		# Apply the animation data
		var anim_array = anims_data[player_id]
		var is_grounded = anim_array[0]
		var blend_value = anim_array[1]
		
		# Apply to their animator
		if is_grounded:
			player_node.animator.set("parameters/ground_air_transition/transition_request", "grounded")
			player_node.animator.set("parameters/iwr_blend/blend_amount", blend_value)
		else:
			player_node.animator.set("parameters/ground_air_transition/transition_request", "air")
			player_node.animator.set("parameters/iwr_blend/blend_amount", 0.0)


func animate_local(delta):
	"""Animation for local player"""
	if not animator:
		return
		
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
	# Handle movement based on camera mode
	handle_third_person_movement(delta)

func disable_camera():
	camera.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	in_selection = true

func make_it_use_gamepad(val: bool):
	use_gamepad = val
	third_person_controller.use_gamepad = val
	third_person_controller.player_index = 0 if val == false else 1

func handle_jump():
	# Jump handling
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

# PRESERVED: Original rotation function
func face_direction(direction: Vector3, delta: float):
	if direction != Vector3.ZERO and mesh:
		# Calculate target rotation
		var target_rotation = atan2(direction.x, direction.z)
		
		# Smoothly rotate towards target with enhanced smoothing
		var current_rotation = mesh.rotation.y
	
		var new_rotation = lerp_angle(current_rotation, target_rotation, rotation_smoothing * delta)
		
		mesh.rotation.y = new_rotation

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

func fall_damage():
	if global_position.y < -10:
		position = get_tree().get_first_node_in_group("respwan_point").position

func check_fall():
	if global_position.y < -10:
		self.global_position = get_tree().get_first_node_in_group("respwan_point").global_position
		
func increase_score(value):
	pass

func take_damage(value):
	position = get_tree().get_first_node_in_group("respwan_point").position

func move_to_level():
	self.global_position = get_tree().get_first_node_in_group("respwan_point").position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
