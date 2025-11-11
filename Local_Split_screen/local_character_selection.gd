extends Node3D

@export var player_index: int = 0  # Which player is this selection screen for (0 or 1)

@export var characters : Array[PackedScene]

@export var spacing: float = 1.5
@export var shift_duration: float = 0.4
@export var shift_ease: Tween.EaseType = Tween.EASE_OUT
@export var shift_trans: Tween.TransitionType = Tween.TRANS_BACK

@export_group("Mouse Rotation")
@export var mouse_sensitivity: float = 0.006

@onready var character_1_containers: Node3D = $characters
@onready var character_2_containers: Node3D = $characters2

# Array of all available characters for this player
var player_1_characters: Array[CharacterBody3D] = []
var player_1_character_scenes: Dictionary = {}

# Array of all available characters for this player
var player_2_characters: Array[CharacterBody3D] = []
var player_2_character_scenes: Dictionary = {}

# Character positions (indices in characters array)
var in_front_index_1: int = 0
var in_left_index_1: int = -1  # -1 means no character
var in_right_index_1: int = -1

# Character positions (indices in characters array)
var in_front_index_2: int = 0
var in_left_index_2: int = -1  # -1 means no character
var in_right_index_2: int = -1

var is_shifting: bool = false
var rotation_y: float = 0.0
var is_dragging: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Instantiate characters from the exported array
	instantiate_characters()
	
	# Disable cameras for all characters
	for character in player_1_characters:
		if character != null:
			character.disable_camera()
	
	for character in player_2_characters:
		if character != null:
			character.disable_camera()

	# Setup initial positions
	setup_initial_positions()

func instantiate_characters() -> void:
	# Clear any existing children (optional, for safety)
	for child in character_1_containers.get_children():
		child.queue_free()
	for child in character_2_containers.get_children():
		child.queue_free()

	var _pos = -1.5
	# Instantiate characters for player 1
	for scene in characters:
		if scene != null:
			var character_instance = scene.instantiate()
			character_1_containers.add_child(character_instance)
			character_instance.position.x = _pos
			character_instance.position.y = 0.5
			_pos += 1.5
			player_1_characters.append(character_instance)
			player_1_character_scenes[character_instance] = scene
	
	_pos = -1.5
	# Instantiate characters for player 2
	for scene in characters:
		if scene != null:
			var character_instance = scene.instantiate()
			character_2_containers.add_child(character_instance)
			character_instance.position = Vector3(0,.5,0)
			character_instance.position.x = _pos
			_pos += 1.5
			player_2_characters.append(character_instance)
			player_2_character_scenes[character_instance] = scene

func setup_initial_positions() -> void:
	# Setup for Player 1
	in_front_index_1 = 0
	in_right_index_1 = -1
	in_left_index_1 = -1
	
	if player_1_characters.size() >= 2:
		in_right_index_1 = 1
	if player_1_characters.size() >= 3:
		in_left_index_1 = 2
	
	# Position Player 1 characters
	if in_front_index_1 >= 0 and in_front_index_1 < player_1_characters.size():
		player_1_characters[in_front_index_1].global_position.x = 0
	if in_right_index_1 >= 0 and in_right_index_1 < player_1_characters.size():
		player_1_characters[in_right_index_1].global_position.x = spacing
	if in_left_index_1 >= 0 and in_left_index_1 < player_1_characters.size():
		player_1_characters[in_left_index_1].global_position.x = -spacing
	
	# Setup for Player 2
	in_front_index_2 = 0
	in_right_index_2 = -1
	in_left_index_2 = -1
	
	if player_2_characters.size() >= 2:
		in_right_index_2 = 1
	if player_2_characters.size() >= 3:
		in_left_index_2 = 2
	
	# Position Player 2 characters
	if in_front_index_2 >= 0 and in_front_index_2 < player_2_characters.size():
		player_2_characters[in_front_index_2].position.x = 0
	if in_right_index_2 >= 0 and in_right_index_2 < player_2_characters.size():
		player_2_characters[in_right_index_2].position.x = spacing
	if in_left_index_2 >= 0 and in_left_index_2 < player_2_characters.size():
		player_2_characters[in_left_index_2].position.x = -spacing

func get_selected_character(player: int = 1):
	"""Returns the scene of the currently selected character for the specified player"""
	if player == 1:
		if in_front_index_1 >= 0 and in_front_index_1 < player_1_characters.size():
			return player_1_character_scenes.get(player_1_characters[in_front_index_1])
	else:
		if in_front_index_2 >= 0 and in_front_index_2 < player_2_characters.size():
			return player_2_character_scenes.get(player_2_characters[in_front_index_2])
	return null

func get_selected_character_node(player: int = 1):
	"""Returns the actual character node that's currently selected for the specified player"""
	if player == 1:
		if in_front_index_1 >= 0 and in_front_index_1 < player_1_characters.size():
			return player_1_characters[in_front_index_1]
	else:
		if in_front_index_2 >= 0 and in_front_index_2 < player_2_characters.size():
			return player_2_characters[in_front_index_2]
	return null

func _input(event: InputEvent) -> void:
	# Track left mouse button state
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
	
	# Rotate only when dragging with left mouse button
	if event is InputEventMouseMotion and is_dragging:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_y = wrapf(rotation_y, -PI, PI)
		
		# Apply rotation to front character of both players
		if in_front_index_1 >= 0 and in_front_index_1 < player_1_characters.size():
			player_1_characters[in_front_index_1].rotation.y = -rotation_y
		if in_front_index_2 >= 0 and in_front_index_2 < player_2_characters.size():
			player_2_characters[in_front_index_2].rotation.y = -rotation_y

func left_click(player: int = 1):
	"""Shift characters left for the specified player"""
	var chars = player_1_characters if player == 1 else player_2_characters
	var in_left = in_left_index_1 if player == 1 else in_left_index_2
	var in_front = in_front_index_1 if player == 1 else in_front_index_2
	var in_right = in_right_index_1 if player == 1 else in_right_index_2
	
	if in_left < 0 or is_shifting:
		return
	
	is_shifting = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(shift_ease)
	tween.set_trans(shift_trans)
	
	if in_left >= 0 and in_left < chars.size():
		tween.tween_property(chars[in_left], "global_position:x", 
			chars[in_left].global_position.x + spacing, shift_duration)
	if in_front >= 0 and in_front < chars.size():
		tween.tween_property(chars[in_front], "global_position:x", 
			chars[in_front].global_position.x + spacing, shift_duration)
	if in_right >= 0 and in_right < chars.size():
		tween.tween_property(chars[in_right], "global_position:x", 
			chars[in_right].global_position.x + spacing, shift_duration)
	
	tween.finished.connect(func():
		var temp = in_right
		if player == 1:
			in_right_index_1 = in_front_index_1
			in_front_index_1 = in_left_index_1
			in_left_index_1 = temp
		else:
			in_right_index_2 = in_front_index_2
			in_front_index_2 = in_left_index_2
			in_left_index_2 = temp
		
		reset_rotation(player)
		is_shifting = false
	)

func right_click(player: int = 1):
	"""Shift characters right for the specified player"""
	var chars = player_1_characters if player == 1 else player_2_characters
	var in_left = in_left_index_1 if player == 1 else in_left_index_2
	var in_front = in_front_index_1 if player == 1 else in_front_index_2
	var in_right = in_right_index_1 if player == 1 else in_right_index_2
	
	if in_right < 0 or is_shifting:
		return
	
	is_shifting = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(shift_ease)
	tween.set_trans(shift_trans)
	
	if in_left >= 0 and in_left < chars.size():
		tween.tween_property(chars[in_left], "global_position:x", 
			chars[in_left].global_position.x - spacing, shift_duration)
	if in_front >= 0 and in_front < chars.size():
		tween.tween_property(chars[in_front], "global_position:x", 
			chars[in_front].global_position.x - spacing, shift_duration)
	if in_right >= 0 and in_right < chars.size():
		tween.tween_property(chars[in_right], "global_position:x", 
			chars[in_right].global_position.x - spacing, shift_duration)
	
	tween.finished.connect(func():
		var temp = in_left
		if player == 1:
			in_left_index_1 = in_front_index_1
			in_front_index_1 = in_right_index_1
			in_right_index_1 = temp
		else:
			in_left_index_2 = in_front_index_2
			in_front_index_2 = in_right_index_2
			in_right_index_2 = temp
		
		reset_rotation(player)
		is_shifting = false
	)

func reset_rotation(player: int = 1):
	rotation_y = 0.0
	if player == 1:
		if in_front_index_1 >= 0 and in_front_index_1 < player_1_characters.size():
			player_1_characters[in_front_index_1].rotation.y = 0.0
	else:
		if in_front_index_2 >= 0 and in_front_index_2 < player_2_characters.size():
			player_2_characters[in_front_index_2].rotation.y = 0.0
