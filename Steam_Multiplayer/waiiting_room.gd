extends Node

@onready var start_game: Button = $Control/start_game
@onready var players_names: VBoxContainer = $Control/players_names
@onready var spawn_path: Node3D = $spawn_path

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_game.pressed.connect(_on_start_game_pressed)
	if !Multiplayer.is_host:
		
		print("Selected level : ",Multiplayer.selected_game_level) 
	else:
		print("I am host and selected level : ", Multiplayer.selected_game_level)

func _on_start_game_pressed():
	get_tree().get_first_node_in_group("level_controller").shift_to_level()
	Multiplayer.start_game()
func _process(delta: float) -> void:
	add_players_ui()
func add_players_ui():
	# Get all players
	var players = Multiplayer.get_current_players()
	for player in players_names.get_children():
		player.queue_free()
		
	for player in players:
		var player_info_label : Label = Label.new()
		players_names.add_child(player_info_label)
		player_info_label.text = " "+str(player.steam_name)

	# Get player count for UI
	#var count = Multiplayer.get_current_player_count()
	#player_count_label.text = "%d/%d Players" % [count, Multiplayer.lobby_members_max]
#
	## Get full info
	#var info = Multiplayer.get_players_info()
	#if info.in_waiting_room:
		#status_label.text = "Waiting for players... (%d/%d)" % [info.player_count, info.max_players]
	#else:
		#status_label.text = "Game in progress!"
#
	## Check if full
	#if Multiplayer.is_lobby_full():
		#start_button.disabled = false
