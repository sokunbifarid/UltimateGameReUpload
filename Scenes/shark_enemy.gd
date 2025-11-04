extends CharacterBody3D

# Movement settings
@export var patrol_speed: float = 3.0
@export var chase_speed: float = 8.0
@export var rotation_speed: float = 3.0
@export var vertical_avoidance_strength: float = 5.0

# Detection settings
@export var detection_range: float = 15.0
@export var lose_interest_range: float = 25.0

# Combat settings
@export var bite_damage: int = 25
@export var bite_distance: float = 2.0
@export var attack_cooldown: float = 3.0

# Patrol settings
@export var patrol_radius: float = 15.0
@export var num_patrol_points: int = 6

@onready var player_ray = $PlayerRay
@onready var obstacle_ray_forward = RayCast3D.new()
@onready var obstacle_ray_up = RayCast3D.new()
@onready var obstacle_ray_down = RayCast3D.new()

# State
enum State { PATROL, CHASE, ATTACK }
var current_state: State = State.PATROL

var player: Node3D
var can_attack: bool = true
var spawn_position: Vector3
var patrol_points: Array[Vector3] = []
var current_patrol_point: int = 0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	spawn_position = global_position
	
	# Setup obstacle avoidance
	_setup_obstacle_raycasts()
	
	# Generate patrol points
	_setup_patrol_points()
	
	print("[Shark] Ready - Patrol points: ", patrol_points.size())

func _setup_obstacle_raycasts() -> void:
	# Forward obstacle detection
	add_child(obstacle_ray_forward)
	obstacle_ray_forward.enabled = true
	obstacle_ray_forward.target_position = Vector3(0, 0, -3.0)
	obstacle_ray_forward.collision_mask = 1
	
	# Upward obstacle detection
	add_child(obstacle_ray_up)
	obstacle_ray_up.enabled = true
	obstacle_ray_up.target_position = Vector3(0, 3.0, 0)
	obstacle_ray_up.collision_mask = 1
	
	# Downward obstacle detection
	add_child(obstacle_ray_down)
	obstacle_ray_down.enabled = true
	obstacle_ray_down.target_position = Vector3(0, -3.0, 0)
	obstacle_ray_down.collision_mask = 1
	
	print("[Shark] Obstacle avoidance setup")

func _setup_patrol_points() -> void:
	# Create circular patrol pattern around spawn
	for i in range(num_patrol_points):
		var angle = (TAU / num_patrol_points) * i
		var point = spawn_position + Vector3(
			cos(angle) * patrol_radius,
			0,
			sin(angle) * patrol_radius
		)
		patrol_points.append(point)

func _physics_process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Check if can see player
	player_ray.target_position = player.global_position - global_position
	player_ray.force_raycast_update()
	var can_see_player = player_ray.is_colliding() and player_ray.get_collider() == player
	
	# State machine
	match current_state:
		State.PATROL:
			_handle_patrol(delta)
			# Switch to chase if player detected
			if can_see_player and distance_to_player <= detection_range:
				print("[Shark] Player detected - chasing!")
				current_state = State.CHASE
		
		State.CHASE:
			_handle_chase(delta, distance_to_player)
			# Switch to attack if close enough
			if distance_to_player <= bite_distance and can_attack:
				print("[Shark] Attack range!")
				current_state = State.ATTACK
			# Return to patrol if lost sight or too far
			elif not can_see_player or distance_to_player > lose_interest_range:
				print("[Shark] Lost player - returning to patrol")
				current_state = State.PATROL
		
		State.ATTACK:
			_handle_attack(delta, distance_to_player)
			# Return to chase after attack
			if not can_attack or distance_to_player > bite_distance:
				current_state = State.CHASE
	
	# Apply obstacle avoidance
	_apply_obstacle_avoidance()
	
	move_and_slide()
	
	# Face movement direction
	if velocity.length() > 0.1:
		_rotate_towards(velocity.normalized(), delta)

func _handle_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		velocity = Vector3.ZERO
		return
	
	var target = patrol_points[current_patrol_point]
	
	# Move to next patrol point when close
	if global_position.distance_to(target) < 2.0:
		current_patrol_point = (current_patrol_point + 1) % patrol_points.size()
		target = patrol_points[current_patrol_point]
	
	var direction = (target - global_position).normalized()
	velocity = direction * patrol_speed

func _handle_chase(delta: float, distance: float) -> void:
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed

func _handle_attack(delta: float, distance: float) -> void:
	# Slow down during attack
	velocity = velocity * 0.3
	
	# Deal damage
	if can_attack and distance <= bite_distance:
		_deal_damage()

func _deal_damage() -> void:
	print("[Shark] BITE! Dealing ", bite_damage, " damage")
	
	if player.has_method("take_damage"):
		player.take_damage(bite_damage)
	
	# Start cooldown
	can_attack = false
	print("[Shark] Attack cooldown started (", attack_cooldown, "s)")
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	print("[Shark] Ready to attack again!")

func _apply_obstacle_avoidance() -> void:
	# Update raycast directions
	var forward = -global_transform.basis.z
	obstacle_ray_forward.target_position = forward * 3.0
	
	obstacle_ray_forward.force_raycast_update()
	obstacle_ray_up.force_raycast_update()
	obstacle_ray_down.force_raycast_update()
	
	var avoidance = Vector3.ZERO
	
	# Avoid obstacles ahead
	if obstacle_ray_forward.is_colliding():
		var collision_normal = obstacle_ray_forward.get_collision_normal()
		avoidance += collision_normal * vertical_avoidance_strength
		
		# Try to go up or down
		if not obstacle_ray_up.is_colliding():
			avoidance.y += vertical_avoidance_strength
		elif not obstacle_ray_down.is_colliding():
			avoidance.y -= vertical_avoidance_strength
	
	# Avoid ceiling
	if obstacle_ray_up.is_colliding():
		avoidance.y -= vertical_avoidance_strength * 0.5
	
	# Avoid floor
	if obstacle_ray_down.is_colliding():
		var distance_to_floor = global_position.distance_to(obstacle_ray_down.get_collision_point())
		if distance_to_floor < 1.5:
			avoidance.y += vertical_avoidance_strength * 0.5
	
	# Apply avoidance
	if avoidance.length() > 0:
		velocity += avoidance

func _rotate_towards(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return
	
	var target_pos = global_position + direction
	target_pos.y = global_position.y
	
	var target_transform = global_transform.looking_at(target_pos, Vector3.UP)
	global_transform = global_transform.interpolate_with(target_transform, rotation_speed * delta)
