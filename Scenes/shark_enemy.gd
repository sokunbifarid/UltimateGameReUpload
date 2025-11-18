extends CharacterBody3D

@export var detection_area: Area3D
@export var petrol_area: Area3D

@export var patrol_speed: float = 3.0
@export var chase_speed: float = 8.0
@export var rotation_speed: float = 3.0
@export var vertical_avoidance_strength: float = 5.0

@export var lose_interest_range: float = 25.0

@export var bite_damage: int = 25
@export var bite_distance: float = 2.0
@export var attack_cooldown: float = 4.0

@export var patrol_radius: float = 15.0
@export var num_patrol_points: int = 6

@onready var player_ray = $PlayerRay

# Raycasts created in code must be added to the scene
@onready var obstacle_ray_forward := RayCast3D.new()
@onready var obstacle_ray_up := RayCast3D.new()
@onready var obstacle_ray_down := RayCast3D.new()

enum State { PATROL, CHASE, ATTACK }
var current_state: State = State.PATROL

var player: Node3D
var can_attack := true
var spawn_position: Vector3
var patrol_points: Array[Vector3] = []
var current_patrol_point := 0


func _ready():
	spawn_position = global_position
	
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)

	_setup_patrol_points()

	# Setup raycasts
	_add_rays()

	print("[Shark] Ready - Patrol points:", patrol_points.size())


func _add_rays() -> void:
	add_child(obstacle_ray_forward)
	add_child(obstacle_ray_up)
	add_child(obstacle_ray_down)

	obstacle_ray_forward.enabled = true
	obstacle_ray_up.enabled = true
	obstacle_ray_down.enabled = true

	obstacle_ray_forward.target_position = Vector3.FORWARD * 3.0
	obstacle_ray_up.target_position = Vector3.UP * 2.0
	obstacle_ray_down.target_position = Vector3.DOWN * 2.0


func _on_player_entered(body):
	if body.is_in_group("Player"):
		player = body


func _on_player_exited(body):
	if body == player:
		player = null


func _setup_patrol_points():
	var shape = petrol_area.get_child(0).shape
	var radius = shape.radius
	var height = shape.height

	for i in range(num_patrol_points):
		var angle = randf() * TAU
		var distance = randf() * radius
		var x = cos(angle) * distance
		var z = sin(angle) * distance
		var y = randf_range(-height / 2, height / 2)

		var point = petrol_area.global_position + Vector3(x, y, z)
		patrol_points.append(point)


func _physics_process(delta):
	var distance_to_player := INF
	if player:
		distance_to_player = global_position.distance_to(player.global_position)

	match current_state:
		State.PATROL:
			_handle_patrol(delta)

			if player:
				current_state = State.CHASE

		State.CHASE:
			if player:
				_handle_chase(delta)

				if distance_to_player <= bite_distance and can_attack:
					current_state = State.ATTACK

				elif distance_to_player > lose_interest_range:
					player = null
					current_state = State.PATROL
			else:
				current_state = State.PATROL

		State.ATTACK:
			_handle_attack(delta, distance_to_player)

			if distance_to_player > bite_distance or not can_attack:
				current_state = State.CHASE

	_apply_obstacle_avoidance()
	move_and_slide()

	if velocity.length() > 0.1:
		_rotate_towards(velocity.normalized(), delta)


func _handle_patrol(delta):
	if patrol_points.is_empty():
		velocity = Vector3.ZERO
		return

	var target = patrol_points[current_patrol_point]

	if global_position.distance_to(target) < 2.0:
		current_patrol_point = (current_patrol_point + 1) % patrol_points.size()
		target = patrol_points[current_patrol_point]

	var direction = (target - global_position).normalized()
	velocity = direction * patrol_speed


func _handle_chase(delta):
	if not player:
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed


func _handle_attack(delta, distance):
	velocity *= 0.3

	if can_attack and distance <= bite_distance:
		_deal_damage()


func _deal_damage():
	if player and player.has_method("take_damage"):
		player.take_damage(bite_damage)

	can_attack = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func _apply_obstacle_avoidance():
	var forward = -global_transform.basis.z
	obstacle_ray_forward.target_position = forward * 3.0

	obstacle_ray_forward.force_raycast_update()
	obstacle_ray_up.force_raycast_update()
	obstacle_ray_down.force_raycast_update()

	var avoidance := Vector3.ZERO

	if obstacle_ray_forward.is_colliding():
		avoidance += obstacle_ray_forward.get_collision_normal() * vertical_avoidance_strength

		if not obstacle_ray_up.is_colliding():
			avoidance.y += vertical_avoidance_strength
		elif not obstacle_ray_down.is_colliding():
			avoidance.y -= vertical_avoidance_strength

	if obstacle_ray_up.is_colliding():
		avoidance.y -= vertical_avoidance_strength * 0.5

	if obstacle_ray_down.is_colliding():
		avoidance.y += vertical_avoidance_strength * 0.5

	if avoidance.length() > 0:
		velocity += avoidance


func _rotate_towards(direction, delta):
	if direction.length() < 0.01:
		return

	var target_pos = global_position + direction
	target_pos.y = global_position.y

	var target_transform = global_transform.looking_at(target_pos, Vector3.UP)
	global_transform = global_transform.interpolate_with(target_transform, rotation_speed * delta)
