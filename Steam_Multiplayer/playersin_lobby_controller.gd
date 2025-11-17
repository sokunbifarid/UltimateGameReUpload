extends Node

# Store player data: {player_id: {mesh_num: int, player_node: Node}}
var players_data: Dictionary = {}

# Called by player when they're ready
func register_player(player_node, player_id: int, mesh_num: int):
	print("Manager: Registering player ", player_id, " with mesh ", mesh_num)
	
	# Store player data
	players_data[player_id] = {
		"mesh_num": mesh_num,
		"player_node": player_node
	}
	
	# If this is the authority (local player), tell everyone about their mesh
	if player_node.is_multiplayer_authority():
		# Broadcast this player's mesh to everyone
		rpc("sync_new_player_mesh", player_id, mesh_num)
		
		# Request all existing players' meshes
		rpc("request_mesh_from_existing_players", player_id)

# Server/Host broadcasts new player's mesh to all clients
@rpc("any_peer", "call_local", "reliable")
func sync_new_player_mesh(player_id: int, mesh_num: int):
	print("Manager: Syncing new player ", player_id, " mesh: ", mesh_num)
	
	# Update our local record
	if players_data.has(player_id):
		players_data[player_id]["mesh_num"] = mesh_num
		
		# Apply the mesh if player node exists
		var players = get_tree().get_nodes_in_group("Player")

		var player_node = null
		for p in players:
			if p.name == str(player_id):
				player_node = p
				break

		print("found character : ", player_node)
		if player_node and player_node.has_method("apply_character_mesh"):
			print("Applying ", mesh_num)
			player_node.apply_character_mesh(mesh_num)

# When a new player joins, existing players send their mesh info back
@rpc("any_peer", "call_remote", "reliable")
func request_mesh_from_existing_players(new_player_id: int):
	print("Manager: Player ", new_player_id, " requesting existing meshes")
	
	# Each existing player sends their mesh to the new player
	for player_id in players_data:
		var player_data = players_data[player_id]
		var player_node = player_data.get("player_node")
		
		# Only send if this is MY player (I have authority)
		if player_node and player_node.is_multiplayer_authority():
			print("Manager: Sending my mesh (", player_data["mesh_num"], ") to new player ", new_player_id)
			rpc_id(new_player_id, "receive_existing_player_mesh", player_id, player_data["mesh_num"])

# New player receives an existing player's mesh
@rpc("any_peer", "call_remote", "reliable")
func receive_existing_player_mesh(player_id: int, mesh_num: int):
	print("Manager: Received existing player ", player_id, " mesh: ", mesh_num)
	
	# Wait a frame to ensure the player node exists
	await get_tree().process_frame
	
	# Update our record
	if !players_data.has(player_id):
		players_data[player_id] = {}
	players_data[player_id]["mesh_num"] = mesh_num
	
	# Apply the mesh
	var players = get_tree().get_nodes_in_group("Player")

	var player_node = null
	for p in players:
		if p.name == str(player_id):
			player_node = p
			break

	if player_node and player_node.has_method("apply_character_mesh"):
		print("Manager: Applying mesh ", mesh_num, " to player ", player_id)
		player_node.apply_character_mesh(mesh_num)
	else:
		print("Manager: WARNING - Player node ", player_id, " not found!")

# Optional: Clean up when player disconnects
func unregister_player(player_id: int):
	if players_data.has(player_id):
		players_data.erase(player_id)
		print("Manager: Unregistered player ", player_id)

# ANIMATION SYNC - Host broadcasts animation data to all clients
func _process(delta: float) -> void:
	
	# Only host broadcasts animation data
	if Multiplayer.is_host:
		# Send animation data to all clients every frame
		broadcast_animation_data()
		
		# Debug print every 60 frames
		if Engine.get_physics_frames() % 60 == 0:
			print("Players animations : ", MultiplayerGlobal.player_animations)

# Host sends animation data to all clients
func broadcast_animation_data():
	if not Multiplayer.is_host:
		return
	
	var anim_data = MultiplayerGlobal.player_animations
	if anim_data.is_empty():
		return
	
	# Get all player nodes in the scene
	var all_players = get_tree().get_nodes_in_group("Player")
	# Send animation data to each CLIENT's player node
	for player_node in all_players:
		# Send animation data to all players in lobby , including the host
		player_node.rpc("receive_animation_data", anim_data)
		#print("Sending animation data to player: ", player_node.name)
