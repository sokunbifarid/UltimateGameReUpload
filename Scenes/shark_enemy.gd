extends CharacterBody3D

@export var speed: float = 6.0
@export var damage_distance: float = 1.5

@onready var ray = $PlayerRay
var player: Node3D

#func _ready():
#	player = get_tree().get_root().find_node("Player", true, false)
#
# func _physics_process(_delta):
#	if player == null:
#		return
#
#	ray.force_raycast_update()
#
#	if ray.is_colliding() and ray.get_collider() == player:
#		var direction = (player.global_transform.origin - global_transform.origin).normalized()
		
		# Don't look_at if you're at the same position
#		if global_transform.origin.distance_to(player.global_transform.origin) > 0.1:
#			look_at(player.global_transform.origin, Vector3.UP)

#		velocity = direction * speed
#		move_and_slide()

		# Optional damage on proximity
#		if global_transform.origin.distance_to(player.global_transform.origin) < damage_distance:
#			if "take_damage" in player:
#				player.take_damage(10)  # Make sure this method exists
#	else:
#		velocity = Vector3.ZERO
#		move_and_slide()
#		print(ray.get_collider())
