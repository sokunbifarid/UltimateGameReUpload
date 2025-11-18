extends Node

#@onready var players_names: VBoxContainer = $Control/players_names
@onready var spawn_path: Node3D = $"../playerSpwanPoint"
@onready var start_game: Button = $start_game
@onready var timer: Timer = $Timer

func _ready() -> void:
	_randomize_spawn_pos()

	var random_x = randf_range(spawn_path.global_position.x - 1, spawn_path.global_position.x + 1)
	var random_z = randf_range(spawn_path.global_position.z - 1, spawn_path.global_position.z + 1)
	var new_pos = Vector3(random_x, spawn_path.global_position.y, random_z)
	
	spawn_path.global_position = new_pos
	timer.timeout.connect(_on_start_game_pressed)
	
	if Multiplayer and !Multiplayer.is_host:
		$start_game.queue_free()


	if Multiplayer and Multiplayer.is_host:
		for pl in spawn_path.get_children():
			if pl.is_multiplayer_authority() and pl.use_gamepad:
				start_game.text = "Start Game\n[press R2 or RT]"

func _randomize_spawn_pos():
	var random_x = randf_range(spawn_path.global_position.x - 5, spawn_path.global_position.x + 5)
	var random_z = randf_range(spawn_path.global_position.z - 5, spawn_path.global_position.z + 5)
	var new_pos = Vector3(random_x, spawn_path.global_position.y, random_z)
	spawn_path.global_position = new_pos

func _on_start_game_pressed():
	print("Enter game pressed")
	# Host triggers the level shift
	if Multiplayer and Multiplayer.is_host:
		print("Host starting game...")
		var level_controller = get_tree().get_first_node_in_group("level_controller")
		if level_controller:
			# Call the RPC which will execute on all clients
			#rpc("level_controller.shift_to_level")
			level_controller.shift_to_level()
		else:
			print("ERROR: Could not find level_controller!")
	else:
		print("ERROR: Only host can start the game!")

func _start_game():
	print("Starting game")
	if Multiplayer and Multiplayer.is_host:
		print("Host starting game...")
		var level_controller = get_tree().get_first_node_in_group("level_controller")
		print(level_controller)
		if level_controller:
			level_controller.move_to_level.rpc()

func _input(event: InputEvent) -> void:
	
	if Multiplayer.is_host:
		update_start_button()
		if event.is_action_pressed("enter_game"):
			print("pressed Enter game")
			_start_game()
	else:
		return

func update_start_button():
	"""Enable start button when lobby is full (optional auto-start logic)"""
	if not Multiplayer or not Multiplayer.is_host:
		print("returning, not a host")
		return
	
	var player_count = Multiplayer.get_current_player_count()
	var max_players = Multiplayer.lobby_members_max
	#print("player count : ",player_count, " max players allowed : ", max_players)
	# Enable button when at least 2 players, or customize this logic
	if player_count >= 2:
		if start_game.disabled:
			start_game.disabled = false
		start_game.text = "Start Game (%d/%d)" % [player_count, max_players]
		start_game.text += "\n[Press Enter]"
	else:
		start_game.disabled = true
		start_game.text = "Waiting for Players... (%d/%d)" % [player_count, max_players]
