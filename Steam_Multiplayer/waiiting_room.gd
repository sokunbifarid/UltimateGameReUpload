extends Node

@onready var players_names: VBoxContainer = $Control/players_names
@onready var spawn_path: Node3D = $spawn_path
@onready var start_game: Button = $start_game

func _ready() -> void:
	
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
	# Host triggers the level shift
	if Multiplayer and Multiplayer.is_host:
		print("Host starting game...")
		var level_controller = get_tree().get_first_node_in_group("level_controller")
		if level_controller:
			# Call the RPC which will execute on all clients
			level_controller.shift_to_level.rpc()
		else:
			print("ERROR: Could not find level_controller!")
	else:
		print("ERROR: Only host can start the game!")

func _process(delta: float) -> void:
	update_start_button()


func update_start_button():
	"""Enable start button when lobby is full (optional auto-start logic)"""
	if not Multiplayer or not Multiplayer.is_host:
		return
	
	var player_count = Multiplayer.get_current_player_count()
	var max_players = Multiplayer.lobby_members_max
	
	# Enable button when at least 2 players, or customize this logic
	if player_count >= 2:
		start_game.disabled = false
		start_game.text = "Start Game\npress R2 or RT"

		if Input.is_action_just_pressed("enter_game") :
			_on_start_game_pressed()
	else:
		start_game.disabled = true
		start_game.text = "Waiting for Players... (%d/%d)" % [player_count, max_players]
