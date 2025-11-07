extends Node

@onready var start_game: Button = $Control/start_game
@onready var players_names: VBoxContainer = $Control/players_names
@onready var spawn_path: Node3D = $spawn_path

func _ready() -> void:
	
	start_game.pressed.connect(_on_start_game_pressed)
	
	# Only host can see/click start button
	if Multiplayer and Multiplayer.is_host:
		start_game.disabled = false
		start_game.visible = true
		print("I am host, can start game")
	else:
		start_game.disabled = true
		start_game.visible = false
		print("I am client, waiting for host")
	
	if Multiplayer:
		print("Selected level: ", Multiplayer.selected_game_level)

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
	update_players_ui()
	update_start_button()

func update_players_ui():
	"""Updates the list of players in the waiting room"""
	if not Multiplayer:
		return
	
	# Clear existing labels
	for child in players_names.get_children():
		child.queue_free()
	
	# Add label for each player
	var players = Multiplayer.get_current_players()
	for player in players:
		var player_label = Label.new()
		player_label.text = " " + str(player.steam_name)
		players_names.add_child(player_label)

func update_start_button():
	"""Enable start button when lobby is full (optional auto-start logic)"""
	if not Multiplayer or not Multiplayer.is_host:
		return
	
	var player_count = Multiplayer.get_current_player_count()
	var max_players = Multiplayer.lobby_members_max
	
	# Enable button when at least 2 players, or customize this logic
	if player_count >= 2:
		start_game.disabled = false
		start_game.text = "Start Game (%d/%d)" % [player_count, max_players]
	else:
		start_game.disabled = true
		start_game.text = "Waiting for Players... (%d/%d)" % [player_count, max_players]
