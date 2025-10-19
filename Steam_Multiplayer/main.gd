extends Node

var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 10
var steam_id: int = 0
var steam_username: String = ""
var is_host: bool = false

@onready var host: Button = $host
@onready var ms: MultiplayerSpawner = $MultiplayerSpawner
@onready var refresh: Button = $refresh

func _ready() -> void:
	# Wait a frame for Steam to fully initialize
	await get_tree().process_frame
	
	# Check if Steam is running
	if not Steam.isSteamRunning():
		print("ERROR: Steam is not running!")
		host.disabled = true
		refresh.disabled = true
		return
	
	# Get Steam ID and username
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	
	# Verify we got valid Steam data
	if steam_id == 0 or steam_username == "":
		print("ERROR: Failed to get Steam user data!")
		host.disabled = true
		refresh.disabled = true
		return
	
	print("Steam initialized - ID: %s, Name: %s" % [steam_id, steam_username])
	
	# Connect buttons
	host.pressed.connect(_on_host_connected)
	refresh.pressed.connect(_on_refresh_pressed)
	
	# Connect Steam lobby signals
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.persona_state_change.connect(_on_persona_change)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	
	# Set up MultiplayerSpawner
	ms.spawn_function = spawn_level
	
	# Initial lobby list request
	open_lobby_list()

func _process(_delta: float) -> void:
	# CRITICAL: Must call this every frame for callbacks to work!
	Steam.run_callbacks()

func spawn_level(data):
	var scene = load(data) as PackedScene
	return scene.instantiate()

func _on_host_connected():
	# Make sure a lobby is not already set
	if lobby_id == 0:
		if steam_id == 0:
			print("ERROR: Cannot create lobby - Steam not initialized properly!")
			return
			
		print("Creating lobby...")
		is_host = true
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max)
		host.disabled = true
	else:
		print("Already in a lobby: %s" % lobby_id)

func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	print("Lobby created callback - connect: %s, lobby_id: %s" % [connect, this_lobby_id])
	
	if connect == 1:
		# Set the lobby ID
		lobby_id = this_lobby_id
		print("Created a lobby: %s" % lobby_id)
		
		# Set this lobby as joinable
		Steam.setLobbyJoinable(lobby_id, true)
		
		# Set some lobby data
		Steam.setLobbyData(lobby_id, "name", str(steam_username + "'s Lobby"))
		Steam.setLobbyData(lobby_id, "mode", "game")
		Steam.setLobbyData(lobby_id, "level", "res://Steam_Multiplayer/level.tscn")

		# After setting lobby data, add:
		var peer = SteamMultiplayerPeer.new()
		peer.create_host(0)  # 0 = no channel limit
		multiplayer.multiplayer_peer = peer
		print("HOST: Multiplayer peer created")	
		
		# Allow P2P connections to fallback to being relayed through Steam if needed
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: %s" % set_relay)
		
		# Get initial lobby members (should just be host)
		get_lobby_members()
		
		# Hide lobby UI
		host.hide()
		refresh.hide()
		$LobbyContainer/Lobbies.hide()
		
		# Spawn the level for host
		print("HOST: Spawning level...")
		ms.spawn("res://Steam_Multiplayer/level.tscn")
		
	else:
		print("Failed to create lobby. Error code: %s" % connect)
		host.disabled = false

func join_lobby(this_lobby_id: int):
	print("Attempting to join lobby %s" % this_lobby_id)
	
	# Clear any previous lobby members lists
	lobby_members.clear()
	is_host = false
	
	# Make the lobby join request to Steam
	Steam.joinLobby(this_lobby_id)
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	print("Lobby joined callback - lobby_id: %s, response: %s" % [this_lobby_id, response])
	
	# If joining was successful
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		# Set this lobby ID as your lobby ID
		lobby_id = this_lobby_id
		print("Joined lobby: %s" % lobby_id)
		
		# Get the lobby members
		get_lobby_members()

		# After getting lobby members, add:
		var peer = SteamMultiplayerPeer.new()
		var host_id = lobby_members[0]["steam_id"]  # First member is the host
		peer.create_client(host_id)  # Connect to host's Steam ID
		multiplayer.multiplayer_peer = peer
		print("CLIENT: Multiplayer peer created, connecting to host ID: %s" % host_id)

		# Hide lobby UI
		host.hide()
		refresh.hide()
		$LobbyContainer/Lobbies.hide()
		
		# If we're not the host (we're a client joining), spawn the level
		if not is_host:
			# Get the level path from lobby data
			var level_path: String = Steam.getLobbyData(lobby_id, "level")
			
			if level_path != "":
				print("CLIENT: Spawning level from lobby data: %s" % level_path)
				print(level_path)
				ms.spawn(level_path)
			else:
				print("CLIENT: No level data found in lobby, using default")
				ms.spawn("res://Steam_Multiplayer/level.tscn")
		else:
			print("HOST: Already in lobby (this shouldn't happen)")
		
	# Else it failed for some reason
	else:
		# Get the failure reason
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
		
		# Reopen the lobby list
		open_lobby_list()

func _on_refresh_pressed():
	# Clear existing lobby buttons
	if $LobbyContainer/Lobbies.get_child_count() > 0:
		for n in $LobbyContainer/Lobbies.get_children():
			n.queue_free()
	
	# Request fresh lobby list
	open_lobby_list()

func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var changer_name: String = Steam.getFriendPersonaName(change_id)
	
	# If a player has joined the lobby
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby." % changer_name)
	
	# Else if a player has left the lobby
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)
	
	# Else if a player has been kicked
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)
	
	# Else if a player has been banned
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s has been banned from the lobby." % changer_name)
	
	# Else there was some unknown change
	else:
		print("%s did... something." % changer_name)
	
	# Update the lobby member list
	get_lobby_members()

func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	# Make sure you're in a lobby and this user is valid
	if lobby_id > 0:
		print("A user (%s) had information change, update the lobby list" % this_steam_id)
		get_lobby_members()

func open_lobby_list():
	# Set distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	
	print("Requesting a lobby list")
	Steam.requestLobbyList()

func _on_lobby_match_list(these_lobbies: Array) -> void:
	print("Received %s lobbies" % these_lobbies.size())
	
	for this_lobby in these_lobbies:
		# Pull lobby data from Steam
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")
		
		# Get the current number of members
		var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)
		
		# Create a button for the lobby
		var lobby_button: Button = Button.new()
		lobby_button.set_text("Lobby %s: %s [%s] - %s/%s Player(s)" % [this_lobby, lobby_name, lobby_mode, lobby_num_members, lobby_members_max])
		lobby_button.set_size(Vector2(800, 50))
		lobby_button.set_name("lobby_%s" % this_lobby)
		lobby_button.pressed.connect(join_lobby.bind(this_lobby))
		
		# Add the new lobby to the list
		$LobbyContainer/Lobbies.add_child(lobby_button)

func get_lobby_members() -> void:
	# Clear your previous lobby list
	lobby_members.clear()
	
	# Get the number of members from this lobby from Steam
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	print("Getting %s lobby members..." % num_of_members)
	
	# Get the data of these players from Steam
	for this_member in range(0, num_of_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		
		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		
		print("  Member %s: %s (ID: %s)" % [this_member, member_steam_name, member_steam_id])
		
		# Add them to the list
		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name})
	
	print("Lobby members array: ", lobby_members)

func leave_lobby() -> void:
	# If in a lobby, leave it
	if lobby_id != 0:
		print("Leaving lobby...")
		# Send leave request to Steam
		Steam.leaveLobby(lobby_id)
		
		# Wipe the Steam lobby ID
		lobby_id = 0
		is_host = false
		
		# Clear the local lobby list
		lobby_members.clear()
		
		# Re-enable host button
		host.disabled = false
		host.show()
		refresh.show()
		$LobbyContainer/Lobbies.show()
