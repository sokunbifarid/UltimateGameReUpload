extends CharacterBody3D

signal OnTakeDamage(damage)
signal OnUpdateScore(score)


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

#=========================================================
@onready var player_sync: MultiplayerSynchronizer = $player_sync
@onready var multir_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var anim_sync: MultiplayerSynchronizer = $anim_sync

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

#======================   PowerupType  ===================================
enum AllPowerups{DW, ANON, MEDAL}
@export var character_1_powerup: AllPowerups = AllPowerups.MEDAL
@export var character_2_powerup: AllPowerups = AllPowerups.DW
@export var character_3_powerup: AllPowerups = AllPowerups.ANON
#=========================================================

enum AllCharacter{Character1, Character2, Character3}
@export var current_character: AllCharacter = AllCharacter.Character1

####

var mesh 
var animator : AnimationTree
var sync_blend_amount: float = -1.0
@export var start_animate: bool = false

var player_stats_ui: VBoxContainer

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
@export var mesh_num: int = 1

# Synced properties
@export var synced_blend: float = -1.0
@export var synced_grounded: bool = true
@export var my_id : int
var sync_manager : Node

func _ready() -> void:
	use_gamepad = Multiplayer.use_gamepad
	sync_manager = get_tree().get_first_node_in_group("Players_sync_manager")
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
		if sync_manager and sync_manager.has_method("register_player"):
			sync_manager.register_player(self, int(name), mesh_num)

func set_player_stats_ui(the_node: VBoxContainer):
	player_stats_ui = the_node
	update_player_stats_in_ui()


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
	handle_powerups()
	move_and_slide()
	update_movement_state_tracking(delta)
	check_landing()
	fall_damage()
	check_fall()
	if Multiplayer.is_host:
		receive_animation_data(MultiplayerGlobal.player_animations)

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
@rpc("any_peer","call_remote", "unreliable")
func receive_animation_data(anims_data: Dictionary):
	
	# Get this player's peer ID
	var my_peer_id = int(name)  # Player node name is their peer ID
	
	# Apply animation data for all OTHER players
	for player_id in anims_data:
		# Skip self - we animate locally
		if player_id == my_peer_id:
			print("player id and my id is same ",player_id," == ",my_peer_id)
			continue
		
		# Find the player node
		var player_node = null
		var players = get_tree().get_nodes_in_group("Player")
		for p in players:
			if p.name == str(player_id):
				player_node = p
				break
		if !player_node:
				print("Could not find player for animation sync ", player_id)
				continue
		# Skip if they don't have animation
		if player_node.mesh_num == 1 or not player_node.start_animate or not player_node.animator:
			print("This Player mesh num is : ",player_node.mesh_num, " start animation is : ",player_node.start_animate," animator is : ",player_node.animator)
			continue
		
		# Apply the animation data
		var anim_array = anims_data[player_id]
		var is_grounded = anim_array[0]
		var blend_value = anim_array[1]
		print("This player anim array is ",anim_array)
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
		#developer commented code
		#position = get_tree().get_first_node_in_group("respwan_point").position
		take_damage(10)
		knock_back_force = Vector3.ZERO

func check_fall():
	if global_position.y < -10:
		self.global_position = get_tree().get_first_node_in_group("respwan_point").global_position
		
func increase_score(value):
	pass

func handle_powerups():
	if !use_gamepad:
		if Input.is_action_just_pressed("use_powerup"):
			if current_character == AllCharacter.Character1:
				if character_1_powerup == AllPowerups.DW:
					enable_dw_powerup()
				elif character_1_powerup == AllPowerups.ANON:
					enable_anon_powerup()
				elif character_1_powerup == AllPowerups.MEDAL:
					enable_medal_powerup()
			elif current_character == AllCharacter.Character2:
				if character_2_powerup == AllPowerups.DW:
					enable_dw_powerup()
				elif character_2_powerup == AllPowerups.ANON:
					enable_anon_powerup()
				elif character_2_powerup == AllPowerups.MEDAL:
					enable_medal_powerup()
			elif current_character == AllCharacter.Character3:
				if character_3_powerup == AllPowerups.DW:
					enable_dw_powerup()
				elif character_3_powerup == AllPowerups.ANON:
					enable_anon_powerup()
				elif character_3_powerup == AllPowerups.MEDAL:
					enable_medal_powerup()
	else:
		if Input.is_action_just_pressed("make_use_powerup"):
			if current_character == AllCharacter.Character1:
				if character_1_powerup == AllPowerups.DW:
					enable_dw_powerup()
				elif character_1_powerup == AllPowerups.ANON:
					enable_anon_powerup()
				elif character_1_powerup == AllPowerups.MEDAL:
					enable_medal_powerup()
			elif current_character == AllCharacter.Character2:
				if character_2_powerup == AllPowerups.DW:
					enable_dw_powerup()
				elif character_2_powerup == AllPowerups.ANON:
					enable_anon_powerup()
				elif character_2_powerup == AllPowerups.MEDAL:
					enable_medal_powerup()
			elif current_character == AllCharacter.Character3:
				if character_3_powerup == AllPowerups.DW:
					enable_dw_powerup()
				elif character_3_powerup == AllPowerups.ANON:
					enable_anon_powerup()
				elif character_3_powerup == AllPowerups.MEDAL:
					enable_medal_powerup()

	if player_stats_ui:
		if dw_timer.time_left != 0:
			player_stats_ui.set_powerup_use_count_down(dw_timer.time_left, dw_timer.wait_time)
		elif anon_timer.time_left != 0:
			player_stats_ui.set_powerup_use_count_down(anon_timer.time_left, anon_timer.wait_time)
		elif medal_timer.time_left != 0:
			player_stats_ui.set_powerup_use_count_down(medal_timer.time_left, medal_timer.wait_time)

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
	if player_stats_ui:
		player_stats_ui.set_powerup_use_count_down(0,0)

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
		cur_speed = RUN_SPEED
		dw_powerup_area_3d.monitorable = true
		dw_powerup_area_3d.monitoring = true
		dwcpu_particles_3d.emitting = true
		dw_timer.wait_time = dw_powerup_lasting_time
		dw_timer.start()
		print("dw powerup activated")

func disable_dw_powerup():
	cur_speed = WALK_SPEED
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
		if mesh:
			mesh.hide()
		print("anon powerup activated")

func disable_anon_powerup():
	if not mesh.visible:
		mesh.show()
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

func take_damage(value):
	position = get_tree().get_first_node_in_group("respwan_point").position
	#developer added code
	if health > 0:
		health -= value
		update_player_stats_in_ui()

func update_player_stats_in_ui():
	player_stats_ui.set_player_stats(health, powerup_exp)

func go_to_level():
	print("moving to new spawn point")
	var spwan_point = get_tree().get_first_node_in_group("respwan_point")
	self.global_position = spwan_point.position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	print(spwan_point," ", spwan_point.position)

func _on_dw_timer_timeout() -> void:
	disable_dw_powerup()


func _on_anon_timer_timeout() -> void:
	disable_anon_powerup()


func _on_medal_timer_timeout() -> void:
	disable_medal_powerup()


func _on_dw_powerup_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and body != self and is_on_floor():
		var look_direction: Vector3 = self.transform.basis.z.normalized()
		look_direction.y = 0
		var knock_back_power: int = 1000
		body.knock_back((body.global_position - self.global_position).normalized(), knock_back_power)
