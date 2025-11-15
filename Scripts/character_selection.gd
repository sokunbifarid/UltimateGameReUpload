extends Node3D

@onready var players_container: Node3D = $characters

@export var spacing: float = 1.5
@export var shift_duration: float = 0.4
@export var shift_ease: Tween.EaseType = Tween.EASE_OUT
@export var shift_trans: Tween.TransitionType = Tween.TRANS_BACK

@export_group("Mouse Rotation")
@export var mouse_sensitivity: float = 0.006

# All characters in the container
var all_characters: Array[CharacterBody3D] = []
var player_scenes: Dictionary = {}

# Current visible characters
var in_front_char: CharacterBody3D = null
var in_left_char: CharacterBody3D = null
var in_right_char: CharacterBody3D = null

# Current indices in the all_characters array
var front_index: int = 0
var left_index: int = -1
var right_index: int = -1

var is_shifting: bool = false
var rotation_y: float = 0.0
var is_dragging: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Gather all characters from the container
	gather_characters()
	
	# Disable cameras for all characters
	for character in all_characters:
		if character.has_method("disable_camera"):
			character.disable_camera()
	
	# Setup initial positions
	setup_initial_positions()

func gather_characters() -> void:
	"""Collect all CharacterBody3D children from the container and map their scenes"""
	all_characters.clear()
	player_scenes.clear()
	
	for child in players_container.get_children():
		if child is CharacterBody3D:
			all_characters.append(child)
			# Try to get the scene file path
			var scene_path = child.scene_file_path
			if scene_path != "":
				player_scenes[child] = load(scene_path)
			else:
				# If no scene path, store null
				player_scenes[child] = null
	
	print("Found %d characters" % all_characters.size())
	for character in all_characters:
		print("Character: %s, Scene: %s" % [character.name, player_scenes.get(character)])

func setup_initial_positions() -> void:
	"""Position characters based on available count"""
	if all_characters.size() == 0:
		return
	
	# Set indices
	front_index = 0
	left_index = -1
	right_index = -1
	
	if all_characters.size() >= 2:
		right_index = 1
	if all_characters.size() >= 3:
		left_index = 2
	
	# Set character references
	in_front_char = all_characters[front_index] if front_index >= 0 else null
	in_right_char = all_characters[right_index] if right_index >= 0 and right_index < all_characters.size() else null
	in_left_char = all_characters[left_index] if left_index >= 0 and left_index < all_characters.size() else null
	
	# Position characters
	if in_front_char:
		in_front_char.position.x = 0
	if in_right_char:
		in_right_char.position.x = spacing
	if in_left_char:
		in_left_char.position.x = -spacing

func get_selected_character_number() -> int:
	"""Returns the character number (1, 2, or 3) of the currently selected character"""
	if in_front_char != null:
		var name_str = str(in_front_char.name)
		# Extract the number from the character name
		# Assuming names are like "Player1", "Player2", "Player3"
		var num = int(name_str.substr(name_str.length() - 1, 1))
		return num
	return 1  # Default to character 1

func get_selected_player():
	"""Returns the scene of the currently selected character"""
	if in_front_char != null:
		var name_str = str(in_front_char.name)
		MultiplayerGlobal.selected_player_num = int(name_str.substr(name_str.length() - 1, 1))
		return player_scenes.get(in_front_char)
	return null

func get_selected_character_node():
	"""Returns the actual character node that's currently selected"""
	return in_front_char

func _input(event: InputEvent) -> void:
	# Track left mouse button state
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
	
	# Rotate only when dragging with left mouse button
	if event is InputEventMouseMotion and is_dragging and in_front_char != null:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_y = wrapf(rotation_y, -PI, PI)
		in_front_char.rotation.y = -rotation_y

func left_click():
	"""Shift characters left"""
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
		# Rotate indices
		var temp_index = right_index
		right_index = front_index
		front_index = left_index
		left_index = temp_index
		
		# Update character references
		in_front_char = all_characters[front_index] if front_index >= 0 and front_index < all_characters.size() else null
		in_right_char = all_characters[right_index] if right_index >= 0 and right_index < all_characters.size() else null
		in_left_char = all_characters[left_index] if left_index >= 0 and left_index < all_characters.size() else null
		
		reset_rotation()
		is_shifting = false
	)

func right_click():
	"""Shift characters right"""
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
		# Rotate indices
		var temp_index = left_index
		left_index = front_index
		front_index = right_index
		right_index = temp_index
		
		# Update character references
		in_front_char = all_characters[front_index] if front_index >= 0 and front_index < all_characters.size() else null
		in_right_char = all_characters[right_index] if right_index >= 0 and right_index < all_characters.size() else null
		in_left_char = all_characters[left_index] if left_index >= 0 and left_index < all_characters.size() else null
		
		reset_rotation()
		is_shifting = false
	)

func reset_rotation():
	rotation_y = 0.0
	if in_front_char != null:
		in_front_char.rotation.y = 0.0
