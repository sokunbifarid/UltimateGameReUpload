extends Camera3D

@export var player: Node3D  # Assign the player in the inspector
@export var shake_intensity := 0.0
@export var h_shake_offset := 0.0
@export var v_shake_offset := 0.0
@export var smooth_factor: float = 5.0
@export var follow_offset := Vector3(0, 3, -5)

func _process(delta):
	if player:
		# Position the camera slightly behind the player

		# Smoothly rotate the camera to match player's facing direction
		var target_rotation_y = player.rotation.y
		rotation.y = lerp_angle(rotation.y, target_rotation_y, delta * (smooth_factor * 0.5))

func _ready():
	if player.has_signal("OnTakeDamage"):
		player.OnTakeDamage.connect(_on_damage)
	print("hello from camera")

func _on_damage(hp: int):
	shake_intensity = 0.1
	print("Camera shake triggered. Hp = ", hp)

func _get_random_shake_offset() -> Vector2:
	return Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)
