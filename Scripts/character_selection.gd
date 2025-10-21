extends Node3D

@onready var player: CharacterBody3D = $characters/Player
@onready var player_2: CharacterBody3D = $characters/Player2

var in_front_char 
var in_left_char
var in_right_char

@export var spacing: float = 1.5
@export var shift_duration: float = 0.4
@export var shift_ease: Tween.EaseType = Tween.EASE_OUT
@export var shift_trans: Tween.TransitionType = Tween.TRANS_BACK

@export_group("Mouse Rotation")
@export var mouse_sensitivity: float = 0.006

var is_shifting: bool = false
var rotation_y: float = 0.0
var is_dragging: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.disable_camera()
	player_2.disable_camera()
	in_front_char = player
	in_right_char = player_2
	in_left_char = null

func _input(event: InputEvent) -> void:
	# Track left mouse button state
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
	
	# Rotate only when dragging with left mouse button
	if event is InputEventMouseMotion and is_dragging and in_front_char != null:
		# Full 360° horizontal rotation (Y-axis)
		rotation_y -= event.relative.x * mouse_sensitivity
		
		# No clamping - allow full rotation
		# Optionally wrap around to keep value manageable
		rotation_y = wrapf(rotation_y, -PI, PI)
		
		# Apply rotation to front character
		in_front_char.rotation.y = -rotation_y

func left_click():
	# Only move if there's a character on the left and not currently shifting
	if in_left_char == null or is_shifting:
		return
	
	is_shifting = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(shift_ease)
	tween.set_trans(shift_trans)
	
	# Tween each character's position
	if in_left_char != null:
		tween.tween_property(in_left_char, "global_position:x", 
			in_left_char.global_position.x + spacing, shift_duration)
	if in_front_char != null:
		tween.tween_property(in_front_char, "global_position:x", 
			in_front_char.global_position.x + spacing, shift_duration)
	if in_right_char != null:
		tween.tween_property(in_right_char, "global_position:x", 
			in_right_char.global_position.x + spacing, shift_duration)
	
	# Rotate positions after tween completes
	tween.finished.connect(func():
		var temp = in_right_char
		in_right_char = in_front_char
		in_front_char = in_left_char
		in_left_char = temp
		
		# Reset rotation for new front character
		reset_rotation()
		is_shifting = false
	)

func right_click():
	# Only move if there's a character on the right and not currently shifting
	if in_right_char == null or is_shifting:
		return
	
	is_shifting = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(shift_ease)
	tween.set_trans(shift_trans)
	
	# Tween each character's position
	if in_left_char != null:
		tween.tween_property(in_left_char, "global_position:x", 
			in_left_char.global_position.x - spacing, shift_duration)
	if in_front_char != null:
		tween.tween_property(in_front_char, "global_position:x", 
			in_front_char.global_position.x - spacing, shift_duration)
	if in_right_char != null:
		tween.tween_property(in_right_char, "global_position:x", 
			in_right_char.global_position.x - spacing, shift_duration)
	
	# Rotate positions after tween completes
	tween.finished.connect(func():
		var temp = in_left_char
		in_left_char = in_front_char
		in_front_char = in_right_char
		in_right_char = temp
		
		# Reset rotation for new front character
		reset_rotation()
		is_shifting = false
	)

func reset_rotation():
	rotation_y = 0.0
	if in_front_char != null:
		in_front_char.rotation.y = 0.0
