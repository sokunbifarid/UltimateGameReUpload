extends Node

signal lobbies_refreshed(lobbies)
signal waiting_room_ready()

@export var levels : Array[PackedScene]
@export var waiting_level : PackedScene
@export var character_selector : PackedScene

@onready var host: Button = $host
@onready var ms: MultiplayerSpawner = $MultiplayerSpawner
@onready var refresh: Button = $refresh
@onready var lobby: Node3D = $"../lobbies_container/lobby"
@onready var lobbies_container: Node3D = $"../lobbies_container"
@onready var refresh_lobbies: Area3D = $"../refresh_Lobbies"
@onready var host_lobby: Area3D = $"../Host_Lobby"

var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 4
var steam_id: int = 0
var steam_username: String = ""
var is_host: bool = false
var has_spawned_level: bool = false
var in_waiting_room: bool = false
var selected_game_level: PackedScene = null
var num_of_players: int = 1

func _ready() -> void:
	add_to_group("lobby_manager")
	
	await get_tree().process_frame
	
	if not Steam.isSteamRunning():
		print("ERROR: Steam is not running!")
		return
	
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	
	if steam_id == 0 or steam_username == "":
		print("ERROR: Failed to get Steam user data!")
		return
	
	print("Steam initialized - ID: %s, Name: %s" % [steam_id, steam_username])
	
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.persona_state_change.connect(_on_persona_change)
	Steam.lobby_match_list.connect(_on_3D_lobby_match_list)
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	ms.spawn_function = spawn_level
	
	open_lobby_list()

func _on_3D_lobby_match_list(lobbies):
	lobbies_refreshed.emit(lobbies)
	
func _process(_delta: float) -> void:
	Steam.run_callbacks()

func spawn_level(data):
	var scene = load(data) as PackedScene
	return scene.instantiate()

func _on_host_connected():
	if lobby_id == 0:
		if steam_id == 0:
			print("ERROR: Cannot create lobby - Steam not initialized properly!")
			return
			
		print("Creating lobby...")
		is_host = true
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max)
	else:
		print("Already in a lobby: %s" % lobby_id)

func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	print("Lobby created callback - connect: %s, lobby_id: %s" % [connect, this_lobby_id])
	
	if connect == 1:
		lobby_id = this_lobby_id
		print("Created a lobby: %s" % lobby_id)
		
		# Select the game level but don't load it yet
		selected_game_level = levels.pick_random()
		
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, "name", str(steam_username + "'s Lobby"))
		Steam.setLobbyData(lobby_id, "mode", "game")
		Steam.setLobbyData(lobby_id, "level", selected_game_level.resource_path)
		Steam.setLobbyData(lobby_id, "game_started", "false")

		# Create host peer
		var peer = SteamMultiplayerPeer.new()
		var error = peer.create_host(0)
		if error != OK:
			print("ERROR: Failed to create host: %s" % error)
			return
			
		multiplayer.multiplayer_peer = peer
		print("HOST: Multiplayer peer created with ID: %s" % multiplayer.get_unique_id())
		
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: %s" % set_relay)
		
		get_lobby_members()
		
		# Go to waiting room instead of game level
		MultiplayerGlobal.selected_level = selected_game_level
		get_tree().change_scene_to_packed(selected_game_level)
		in_waiting_room = true
		has_spawned_level = false
	else:
		print("Failed to create lobby. Error code: %s" % connect)

func join_lobby(this_lobby_id: int):
	print("Attempting to join lobby %s" % this_lobby_id)
	lobby_members.clear()
	is_host = false
	Steam.joinLobby(this_lobby_id)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	print("Lobby joined callback - lobby_id: %s, response: %s" % [this_lobby_id, response])
	
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		print("Joined lobby: %s" % lobby_id)
		
		get_lobby_members()

		# Only create client peer if we're not the host
		if not is_host and lobby_members.size() > 0:
			var peer = SteamMultiplayerPeer.new()
			var host_steam_id = lobby_members[0]["steam_id"]
			
			print("CLIENT: Connecting to host Steam ID: %s" % host_steam_id)
			var error = peer.create_client(host_steam_id, 0)
			if error != OK:
				print("ERROR: Failed to create client: %s" % error)
				return
				
			multiplayer.multiplayer_peer = peer
			print("CLIENT: Multiplayer peer created with ID: %s" % multiplayer.get_unique_id())
			
			await get_tree().create_timer(0.5).timeout
#
			## Check if game has already started
			#var game_started = Steam.getLobbyData(lobby_id, "game_started")
			
				# Join game in progress
			var level_path: String = Steam.getLobbyData(lobby_id, "level")
			if level_path != "":
				print("CLIENT: Game already started, joining level: %s" % level_path)
				var level_scene = load(level_path) as PackedScene
				get_tree().change_scene_to_packed(level_scene)
				has_spawned_level = true
				in_waiting_room = false

	else:
		var fail_reason: String
		
		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: 
				fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: 
				fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: 
				fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: 
				fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: 
				fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: 
				fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: 
				fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: 
				fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: 
				fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: 
				fail_reason = "A user you have blocked is in the lobby."
			_: 
				fail_reason = "Unknown error."
		
		print("Failed to join this chat room: %s" % fail_reason)
		open_lobby_list()

func _on_peer_connected(id: int):
	print("Peer connected with multiplayer ID: %s" % id)
	
	# Check if lobby is full and auto-start if enabled
	if is_host and in_waiting_room:
		check_lobby_full()

func _on_peer_disconnected(id: int):
	print("Peer disconnected with multiplayer ID: %s" % id)

func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	var changer_name: String = Steam.getFriendPersonaName(change_id)
	
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby." % changer_name)
		if is_host and in_waiting_room:
			check_lobby_full()
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s has been banned from the lobby." % changer_name)
	else:
		print("%s did... something." % changer_name)
	
	get_lobby_members()

func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	if lobby_id > 0:
		print("A user (%s) had information change, update the lobby list" % this_steam_id)
		get_lobby_members()

func open_lobby_list():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	print("Requesting a lobby list")
	Steam.requestLobbyList()

func get_lobby_members() -> void:
	lobby_members.clear()
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	print("Getting %s lobby members..." % num_of_members)
	
	for this_member in range(0, num_of_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		
		print("  Member %s: %s (ID: %s)" % [this_member, member_steam_name, member_steam_id])
		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name})
	
	print("Lobby members array: ", lobby_members)

func check_lobby_full() -> void:
	"""Check if lobby is full and auto-start game if it is"""
	get_lobby_members()
	if lobby_members.size() >= lobby_members_max:
		print("Lobby is full! Auto-starting game...")
		start_game()

func start_game() -> void:
	"""Called by host to start the game (either manually or when lobby is full)"""
	if not is_host:
		print("ERROR: Only host can start the game!")
		return
	
	if not in_waiting_room:
		print("ERROR: Not in waiting room!")
		return
	
	print("Starting game...")
	
	# Mark game as started in Steam lobby data
	Steam.setLobbyData(lobby_id, "game_started", "true")
	
	# Load the actual game level
	var level_path: String = Steam.getLobbyData(lobby_id, "level")
	if level_path != "":
		print("HOST: Broadcasting game start to all clients...")
		
		# Send RPC to clients FIRST before changing host's scene
		rpc_start_game.rpc(level_path)
		
		# Small delay to ensure RPC is sent before scene change
		await get_tree().create_timer(0.1).timeout
		
		# Then host loads the level
		in_waiting_room = false
		has_spawned_level = true
		
@rpc("any_peer", "call_remote", "reliable")
func rpc_start_game(level_path: String) -> void:
	"""RPC to tell all clients to start the game"""
	if is_host:
		# Host doesn't need to receive this
		return
	
	print("CLIENT: Received start game command, loading level: %s" % level_path)
	in_waiting_room = false
	has_spawned_level = true
	
func get_current_players() -> Array:
	"""Returns array of players currently in the lobby (waiting room or in game)"""
	return lobby_members.duplicate()

func get_current_player_count() -> int:
	"""Returns the number of players currently in the lobby"""
	return lobby_members.size()

func get_players_info() -> Dictionary:
	"""Returns detailed info about current lobby state and players"""
	return {
		"players": lobby_members.duplicate(),
		"player_count": lobby_members.size(),
		"max_players": lobby_members_max,
		"is_full": lobby_members.size() >= lobby_members_max,
		"in_waiting_room": in_waiting_room,
		"game_started": has_spawned_level,
		"is_host": is_host,
		"lobby_id": lobby_id
	}

func is_lobby_full() -> bool:
	"""Returns true if lobby has reached max capacity"""
	return lobby_members.size() >= lobby_members_max

func leave_lobby() -> void:
	if lobby_id != 0:
		print("Leaving lobby...")
		Steam.leaveLobby(lobby_id)
		
		lobby_id = 0
		is_host = false
		has_spawned_level = false
		in_waiting_room = false
		lobby_members.clear()
		
		host.disabled = false
		host.show()
		refresh.show()
		$LobbyContainer/Lobbies.show()
