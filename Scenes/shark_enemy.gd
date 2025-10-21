extends CharacterBody3D

@export var speed: float = 6.0
@export var damage_distance: float = 1.5
@export var damage_amount: int = 10
@export var damage_cooldown: float = 1.0

@onready var ray = $PlayerRay

var player: Node3D
var can_damage: bool = true

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta):
	if player == null:
		return
	
	ray.force_raycast_update()
	
	if ray.is_colliding() and ray.get_collider() == player:
		var direction = (player.global_transform.origin - global_transform.origin).normalized()
		
		# Don't look_at if you're at the same position
		if global_transform.origin.distance_to(player.global_transform.origin) > 0.1:
			look_at(player.global_transform.origin, Vector3.UP)
		
		velocity = direction * speed
		move_and_slide()
		
		# Damage on proximity with cooldown
		var distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)
		if distance_to_player < damage_distance and can_damage:
			if player.has_method("take_damage"):
				player.take_damage(damage_amount)
				can_damage = false
				# Start cooldown timer
				get_tree().create_timer(damage_cooldown).timeout.connect(_on_damage_cooldown_finished)
	else:
		velocity = Vector3.ZERO
		move_and_slide()

func _on_damage_cooldown_finished() -> void:
	can_damage = true
