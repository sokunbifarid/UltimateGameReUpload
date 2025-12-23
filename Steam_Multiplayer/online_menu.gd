extends Node3D

@onready var character_selection: Area3D = $Character_Selection
@onready var host_lobby: Area3D = $Host_Lobby
@onready var refresh_lobbies: Area3D = $refresh_Lobbies
@onready var lobby: Node3D = $lobbies_container/lobby
@onready var lobbies_container: Node3D = $lobbies_container
@onready var timer: Timer = $refresh_Lobbies/Timer

var curr_pos = Vector2.ZERO

func _ready() -> void:
	#character_selection.input_event.connect(_on_character_selection_input_event)
	refresh_lobbies.input_event.connect(_on_refresh_lobbies_pressed)
	host_lobby.input_event.connect(_on_host_lobby_pressed)
	Multiplayer.lobbies_refreshed.connect(_on_3D_lobby_match_list)

	timer.timeout.connect(func():
		Multiplayer.open_lobby_list())

func _on_refresh_lobbies_pressed(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		Multiplayer.open_lobby_list()

func _on_host_lobby_pressed(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		Multiplayer._on_host_connected()

func _on_3D_lobby_match_list(these_lobbies: Array) -> void:
	# Hide the template lobby
	lobby.hide()
	
# Developer commented code
	## Clear existing lobby instances (keep the template)
	#for lobbi in lobbies_container.get_children():
		#if lobbi.name == "lobby": 
			#continue
		#lobbi.queue_free()
	#
	## Reset position counter
	#curr_pos.y = 0
	#
	## Create lobby entries for each received lobby
	#for this_lobby in these_lobbies:
		#var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		#var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")
		#var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)
		#var lobby_max_members: int = Steam.getLobbyMemberLimit(this_lobby)
		#
		## Skip unnamed lobbies
		#if lobby_name.length() == 0:
			#continue
		#
		## Format the display text with player count
		#var display_text = "%s (%d/%d)" % [lobby_name, lobby_num_members, lobby_max_members]
		#
		## Duplicate the template lobby
		#var new_lobby: Node3D = lobby.duplicate()
		#new_lobby.name = "lobby_%s" % this_lobby
		#
		## Set the lobby display text with player count
		#var label = new_lobby.get_node("Label3D")
		#label.text = display_text
		#
		## Optional: Change color based on lobby fullness
		#if lobby_num_members >= lobby_max_members:
			#label.modulate = Color(0.8, 0.3, 0.3)  # Red tint for full lobbies
		#elif lobby_num_members >= lobby_max_members * 0.75:
			#label.modulate = Color(1.0, 0.8, 0.3)  # Yellow tint for nearly full
		#else:
			#label.modulate = Color(0.3, 1.0, 0.5)  # Green tint for available
		#
		## Store lobby metadata
		#new_lobby.set_meta("lobby_id", this_lobby)
		#new_lobby.set_meta("lobby_name", lobby_name)
		#new_lobby.set_meta("lobby_mode", lobby_mode)
		#new_lobby.set_meta("num_members", lobby_num_members)
		#new_lobby.set_meta("max_members", lobby_max_members)
		#
		## Add to container
		#lobbies_container.add_child(new_lobby)
		#
		## Connect input event
		#var area: Area3D = new_lobby.get_node("Area3D")
		#area.input_event.connect(_on_area_3d_input_event.bind(this_lobby, lobby_num_members, lobby_max_members))
		#
		## Add hover effects
		#area.mouse_entered.connect(_on_lobby_hover.bind(new_lobby))
		#area.mouse_exited.connect(_on_lobby_unhover.bind(new_lobby))
		#
		## Position the lobby entry
		#new_lobby.position = Vector3(0, curr_pos.y, 0)
		#new_lobby.show()
		#
		## Increment position for next lobby
		#curr_pos.y += 1.5
	#
	#print("Total lobbies displayed: ", lobbies_container.get_child_count() - 1)
	#leave the below commented
	##emit_signal("Multiplayer.notification","Total lobbies displayed: "+ str(lobbies_container.get_child_count() - 1))

func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int, this_lobby: int, num_members: int, max_members: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Check if lobby is full before attempting to join
		if num_members >= max_members:
			print("Cannot join: Lobby is full (%d/%d)" % [num_members, max_members])
			# Optional: Add visual feedback for full lobby
			return
		
		Multiplayer.join_lobby(this_lobby)

func _on_lobby_hover(lobby_node: Node3D) -> void:
	# Smooth scale animation on hover
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(lobby_node, "scale", Vector3(1.15, 1.15, 1.15), 0.3)
	
	# Optional: Brighten the label
	var label = lobby_node.get_node("Label3D")
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.2)

func _on_lobby_unhover(lobby_node: Node3D) -> void:
	# Smooth scale animation on unhover
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(lobby_node, "scale", Vector3(1.0, 1.0, 1.0), 0.3)
