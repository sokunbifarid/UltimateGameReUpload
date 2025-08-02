extends CharacterBody3D

@export var speed: float = 2.0
@export var chase_distance: float = 10.0

var player: Node3D = null

func _ready():
	# You can find the player by name or use groups (recommended in larger projects)
	player = get_tree().get_root().get_node("Main/Player") # adjust the path to your player node
	if player == null:
		push_error("Player node not found!")

func _physics_process(delta):
	if player:
		var to_player = player.global_position - global_position
		var distance = to_player.length()

		if distance < chase_distance:
			var direction = to_player.normalized()
			velocity = direction * speed
			move_and_slide()
		else:
			velocity = Vector3.ZERO
			move_and_slide()
