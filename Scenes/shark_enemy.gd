extends CharacterBody3D
@onready var up: RayCast3D = $avoidence_ray/up
@onready var down: RayCast3D = $avoidence_ray/down

@onready var front: RayCast3D = $avoidence_ray/front
@onready var left: RayCast3D = $avoidence_ray/left
@onready var right: RayCast3D = $avoidence_ray/right
@export var attack_area: Area3D

# Movement settings
@export var patrol_speed: float = 3.0
@export var rotation_speed: float = 3.0
@export var avoidance_strength: float = 2.0

# Patrol settings
@export var patrol_area: Area3D

# Attack settings
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 2.0
@export var attack_speed: float = 6.0

var patrol_target: Vector3
var patrol_timer: float = 0.0
var change_direction_interval: float = 5.0

# Attack state
enum Shark_State { PATROL, ATTACKING, COOLDOWN }
var current_state: Shark_State = Shark_State.PATROL
var player_in_range: Node3D = null
var cooldown_timer: float = 0.0
var normal_rotation_speed : float 
var attack_rot_speed = 5
func _ready() -> void:
	normal_rotation_speed = rotation_speed
	_set_new_patrol_target()
	
	# Connect attack area signals
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)
		attack_area.body_exited.connect(_on_attack_area_exited)

func _physics_process(delta):
	match current_state:
		Shark_State.PATROL:
			_handle_patrol(delta)
		Shark_State.ATTACKING:
			_handle_attack(delta)
		Shark_State.COOLDOWN:
			_handle_cooldown(delta)

func _handle_patrol(delta):
	if rotation_speed != normal_rotation_speed:
		rotation_speed  = normal_rotation_speed
	patrol_timer += delta
	
	# Check if player is in range and can attack
	if player_in_range != null:
		current_state = Shark_State.ATTACKING
		return
	
	# Change direction periodically or when reaching target
	if patrol_timer >= change_direction_interval or global_position.distance_to(patrol_target) < 2.0:
		_set_new_patrol_target()
		patrol_timer = 0.0
		
	# Move towards patrol target
	var direction = (patrol_target - global_position).normalized()
	
	# Apply avoidance
	var avoidance = _get_avoidance_vector()
	if avoidance.length() > 0:
		direction = (direction + avoidance * avoidance_strength).normalized()
	
	velocity = direction * patrol_speed
	
	move_and_slide()
	
	# Face movement direction
	if velocity.length() > 0.1:
		_rotate_towards(velocity.normalized(), delta)

func _handle_attack(delta):
	if rotation_speed == normal_rotation_speed:
		rotation_speed = attack_rot_speed
	if player_in_range == null:
		# Player left range, go back to patrol
		current_state = Shark_State.PATROL
		return
	
	# Move towards player
	var direction = (player_in_range.global_position - global_position).normalized()
	velocity = direction * attack_speed
	
	move_and_slide()
	
	# Face player
	_rotate_towards(direction, delta)
	
	# Check if close enough to hit
	var distance = global_position.distance_to(player_in_range.global_position)
	if distance < 2.0:  # Attack range
		_perform_attack()

func _perform_attack():
	if player_in_range and player_in_range.has_method("take_damage"):
		player_in_range.take_damage(attack_damage)
	
	# Go into cooldown
	current_state = Shark_State.COOLDOWN
	cooldown_timer = 0.0

func _handle_cooldown(delta):
	cooldown_timer += delta
	
	# Continue patrol movement during cooldown
	var direction = (patrol_target - global_position).normalized()
	var avoidance = _get_avoidance_vector()
	if avoidance.length() > 0:
		direction = (direction + avoidance * avoidance_strength).normalized()
	
	velocity = direction * patrol_speed
	move_and_slide()
	
	if velocity.length() > 0.1:
		_rotate_towards(velocity.normalized(), delta)
	
	# Check if cooldown is over
	if cooldown_timer >= attack_cooldown:
		current_state = Shark_State.PATROL
		cooldown_timer = 0.0

func _get_avoidance_vector() -> Vector3:
	var avoidance = Vector3.ZERO
	
	# Check front - if blocked, try to go around
	if _is_ray_blocked(front):
		var left_clear = not _is_ray_blocked(left)
		var right_clear = not _is_ray_blocked(right)
		
		if left_clear and right_clear:
			# Both sides clear, pick one randomly
			avoidance += -global_transform.basis.x if randf() > 0.5 else global_transform.basis.x
		elif left_clear:
			# Only left is clear
			avoidance += -global_transform.basis.x * 2.0
		elif right_clear:
			# Only right is clear
			avoidance += global_transform.basis.x * 2.0
		else:
			# Both blocked, go back and pick new target
			_set_new_patrol_target()
			patrol_timer = 0.0
			avoidance += global_transform.basis.z * 2.0
	
	# Check up - avoid ceiling
	if _is_ray_blocked(up):
		avoidance += -global_transform.basis.y * 1.5
	
	# Check down - avoid floor
	if _is_ray_blocked(down):
		avoidance += global_transform.basis.y * 1.5
	
	# Side avoidance (subtle steering)
	if _is_ray_blocked(left):
		avoidance += global_transform.basis.x * 0.5
	
	if _is_ray_blocked(right):
		avoidance += -global_transform.basis.x * 0.5
	
	return avoidance

func _is_ray_blocked(ray: RayCast3D) -> bool:
	if not ray.is_colliding():
		return false
	
	var collider = ray.get_collider()
	if collider and collider.is_in_group("Player"):
		return false
	
	return true

func _on_attack_area_entered(body: Node3D):
	if body.is_in_group("Player"):
		player_in_range = body

func _on_attack_area_exited(body: Node3D):
	if body.is_in_group("Player") and body == player_in_range:
		player_in_range = null

func _set_new_patrol_target() -> void:
	if patrol_area == null:
		return
	
	# Get the CollisionShape3D from the Area3D
	var collision_shape = patrol_area.get_child(0) as CollisionShape3D
	if collision_shape == null:
		return
	
	var shape = collision_shape.shape
	
	# Get the CollisionShape3D global position
	var glo_pos : Vector3 = collision_shape.global_position
	
	# Generate random point based on shape type
	if shape is CylinderShape3D:
		var radius = shape.radius
		var height = shape.height
		var min_y = glo_pos.y - height/2
		var max_y = glo_pos.y + height/2
		var min_x = glo_pos.x - radius
		var max_x = glo_pos.x + radius
		var min_z = glo_pos.z - radius
		var max_z = glo_pos.z + radius
		
		patrol_target = Vector3(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y),
			randf_range(min_z, max_z)
		)
	elif shape is BoxShape3D:
		var box_size = shape.size
		var min_x = glo_pos.x - box_size.x / 2
		var max_x = glo_pos.x + box_size.x / 2
		var min_y = glo_pos.y - box_size.y / 2
		var max_y = glo_pos.y + box_size.y / 2
		var min_z = glo_pos.z - box_size.z / 2
		var max_z = glo_pos.z + box_size.z / 2
		
		patrol_target = Vector3(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y),
			randf_range(min_z, max_z)
		)
	elif shape is SphereShape3D:
		var radius = shape.radius
		var min_x = glo_pos.x - radius
		var max_x = glo_pos.x + radius
		var min_y = glo_pos.y - radius
		var max_y = glo_pos.y + radius
		var min_z = glo_pos.z - radius
		var max_z = glo_pos.z + radius
		
		patrol_target = Vector3(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y),
			randf_range(min_z, max_z)
		)

func _rotate_towards(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return
	
	var target_transform = global_transform.looking_at(global_position + direction, Vector3.UP)
	global_transform = global_transform.interpolate_with(target_transform, rotation_speed * delta)
