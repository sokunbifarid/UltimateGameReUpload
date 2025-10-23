extends Node

@export var level : PackedScene
@export var character_selector : PackedScene

@onready var host: Button = $host
@onready var ms: MultiplayerSpawner = $MultiplayerSpawner
@onready var refresh: Button = $refresh
@onready var lobby: Node3D = $"../lobbies_container/lobby"
@onready var lobbies_container: Node3D = $"../lobbies_container"
@onready var refresh_lobbies: Area3D = $"../refresh_Lobbies"
@onready var host_lobby: Area3D = $"../Host_Lobby"
@onready var main_menu: Area3D = $"../Main_Menu"
@onready var _main_menu: Node3D = $"../../MainMenu"
@onready var local_menu: Node3D = $"../../LocalMenu"
@onready var settings: Node3D = $"../../Settings"
@onready var world_backgrouns: Node3D = $"../../World_Backgrouns"

var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 10
var steam_id: int = 0
var steam_username: String = ""
var is_host: bool = false
var has_spawned_level: bool = false

var to_hide : Array 
func _ready() -> void:
	to_hide = [host_lobby,refresh_lobbies,lobbies_container,main_menu,
	_main_menu,local_menu,settings,world_backgrouns]
	add_to_group("lobby_manager")
	
	await get_tree().process_frame
	
	if not Steam.isSteamRunning():
		print("ERROR: Steam is not running!")
		#host.disabled = true
		#refresh.disabled = true
		return
	
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	
	if steam_id == 0 or steam_username == "":
		print("ERROR: Failed to get Steam user data!")
		#host.disabled = true
		#refresh.disabled = true
		return
	
	print("Steam initialized - ID: %s, Name: %s" % [steam_id, steam_username])
	
	#host.pressed.connect(_on_host_connected)
	#refresh.pressed.connect(_on_refresh_pressed)
	
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.persona_state_change.connect(_on_persona_change)
	Steam.lobby_match_list.connect(_on_3D_lobby_match_list)
	
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	ms.spawn_function = spawn_level
	
	open_lobby_list()
	refresh_lobbies.input_event.connect(_on_refresh_lobbies_pressed)
	host_lobby.input_event.connect(_on_host_lobby_pressed)

func _on_refresh_lobbies_pressed(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		open_lobby_list()
func _on_host_lobby_pressed(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_host_connected()

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
		#host.disabled = true
	else:
		print("Already in a lobby: %s" % lobby_id)

func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	print("Lobby created callback - connect: %s, lobby_id: %s" % [connect, this_lobby_id])
	
	if connect == 1:
		lobby_id = this_lobby_id
		print("Created a lobby: %s" % lobby_id)
		
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, "name", str(steam_username + "'s Lobby"))
		Steam.setLobbyData(lobby_id, "mode", "game")
		Steam.setLobbyData(lobby_id, "level", level.resource_path)

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
		
		MultiplayerGlobal.selected_level = level
		get_tree().change_scene_to_packed(character_selector)

		
		if not has_spawned_level:
			print("HOST: Spawning level...")
			ms.spawn(level.resource_path)
			has_spawned_level = true
		
	else:
		print("Failed to create lobby. Error code: %s" % connect)
		host.disabled = false

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
			
			# Wait a moment for connection to establish
			await get_tree().create_timer(0.5).timeout

			for ele in to_hide:
				ele.hide()
				$"../../MainCamera".current = false

			# Client spawns level AFTER connection is established
			if not has_spawned_level:
				var level_path: String = Steam.getLobbyData(lobby_id, "level")
				
				if level_path != "":
					print("CLIENT: Spawning level from lobby data: %s" % level_path)
					ms.spawn(level_path)
					has_spawned_level = true
					print("CLIENT: Level spawned, waiting for player spawn...")
				else:
					print("CLIENT: No level data found in lobby")
		
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

func _on_peer_disconnected(id: int):
	print("Peer disconnected with multiplayer ID: %s" % id)

func _on_refresh_pressed():
	if $LobbyContainer/Lobbies.get_child_count() > 0:
		for n in $LobbyContainer/Lobbies.get_children():
			n.queue_free()
	
	open_lobby_list()

func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	var changer_name: String = Steam.getFriendPersonaName(change_id)
	
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby." % changer_name)
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

func _on_lobby_match_list(these_lobbies: Array) -> void:
	print("Received %s lobbies" % these_lobbies.size())
	var lobbies_container: Node3D = $LobbyContainer/Lobbies
	for this_lobby in these_lobbies:
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")
		var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)
		
		var lobby_button: Button = Button.new()
		lobby_button.set_text("Lobby %s: %s [%s] - %s/%s Player(s)" % [this_lobby, lobby_name, lobby_mode, lobby_num_members, lobby_members_max])
		lobby_button.set_size(Vector2(800, 50))
		lobby_button.set_name("lobby_%s" % this_lobby)
		lobby_button.pressed.connect(join_lobby.bind(this_lobby))
		
		lobbies_container.add_child(lobby_button)
var curr_pos = Vector2.ZERO
func _on_3D_lobby_match_list(these_lobbies: Array) -> void:
	print("Received %s lobbies" % these_lobbies.size())
	
	# Hide the template lobby
	lobby.hide()
	
	# Clear existing lobby instances (keep the template)
	for lobbi in lobbies_container.get_children():
		if lobbi.name == "lobby": 
			continue
		lobbi.queue_free()  # Fixed: was 'lobby' instead of 'lobbi'
	
	# Reset position counter
	curr_pos.y = 0
	
	# Create lobby entries for each received lobby
	for this_lobby in these_lobbies:
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")
		var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)
		
		var display_text = str(lobby_name) if lobby_name.length() > 0 else "Unnamed Lobby"
		if display_text == "Unnamed Lobby": continue
		# Duplicate the template lobby
		var new_lobby: Node3D = lobby.duplicate()
		new_lobby.name = "lobby_%s" % this_lobby  # Give it a unique name
		
		# Set the lobby display text
		new_lobby.get_node("Label3D").text = display_text
		
		# Store lobby ID for later use (when joining)
		new_lobby.set_meta("lobby_id", this_lobby)
		new_lobby.set_meta("lobby_name", lobby_name)
		new_lobby.set_meta("lobby_mode", lobby_mode)
		new_lobby.set_meta("num_members", lobby_num_members)
		
		# Add to container
		lobbies_container.add_child(new_lobby)
		
		# Position the lobby entry
		new_lobby.position = Vector3(0, curr_pos.y, 0)
		new_lobby.show()
		
		# Increment position for next lobby
		curr_pos.y += 1.5
	
	print("Total lobbies displayed: ", lobbies_container.get_child_count() - 1)  # -1 for template
	
	# Add functionality to lobby buttons (click handlers, hover effects, etc.)
	if lobbies_container.has_method("_add_functionality"):
		lobbies_container._add_functionality()

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

func leave_lobby() -> void:
	if lobby_id != 0:
		print("Leaving lobby...")
		Steam.leaveLobby(lobby_id)
		
		lobby_id = 0
		is_host = false
		has_spawned_level = false
		lobby_members.clear()
		
		host.disabled = false
		host.show()
		refresh.show()
		$LobbyContainer/Lobbies.show()
