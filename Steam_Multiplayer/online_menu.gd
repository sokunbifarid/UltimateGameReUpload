extends Node3D

@onready var character_selection: Area3D = $Character_Selection
@onready var host_lobby: Area3D = $Host_Lobby
@onready var refresh_lobbies: Area3D = $refresh_Lobbies
@onready var lobby: Node3D = $lobbies_container/lobby
@onready var lobbies_container: Node3D = $lobbies_container
var curr_pos = Vector2.ZERO

func _ready() -> void:
	character_selection.input_event.connect(_on_character_selection_input_event)
	refresh_lobbies.input_event.connect(_on_refresh_lobbies_pressed)
	host_lobby.input_event.connect(_on_host_lobby_pressed)
	Multiplayer.lobbies_refreshed.connect(_on_3D_lobby_match_list)

func _on_refresh_lobbies_pressed(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		Multiplayer.open_lobby_list()

func _on_host_lobby_pressed(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		Multiplayer._on_host_connected()

func _on_character_selection_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_packed(MultiplayerGlobal.character_selection_scene)

func _on_3D_lobby_match_list(these_lobbies: Array) -> void:
	
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
		var area : Area3D = new_lobby.get_node("Area3D")
		area.input_event.connect(_on_area_3d_input_event.bind(this_lobby))
		# Position the lobby entry
		new_lobby.position = Vector3(0, curr_pos.y, 0)
		new_lobby.show()
		
		# Increment position for next lobby
		curr_pos.y += 1.5
	
	print("Total lobbies displayed: ", lobbies_container.get_child_count() - 1)  # -1 for template
	
	# Add functionality to lobby buttons (click handlers, hover effects, etc.)
	if lobbies_container.has_method("_add_functionality"):
		lobbies_container._add_functionality()

func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int,this_lobby) -> void:
	if event is InputEventMouseButton and event.pressed:
		Multiplayer.join_lobby(this_lobby)
