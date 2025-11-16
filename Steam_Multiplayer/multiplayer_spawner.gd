extends MultiplayerSpawner

@export var player_Scene : PackedScene
@export var _spawn_path : Node3D
@onready var label: Label = $"../Label"
@onready var player_spawn_point: Node3D = $"../Node3D"

var is_local : bool = false
var players = {}

func _ready() -> void:
	if is_local: 
		return
	
	spawn_function = spawnPlayer
	
	if multiplayer.multiplayer_peer:
		_setup_spawner()
	else:
		await get_tree().create_timer(0.5).timeout
		_setup_spawner()

func _setup_spawner():
	print("Setting up spawner, authority: %s, unique_id: %s" % [is_multiplayer_authority(), multiplayer.get_unique_id()])
	
	if is_multiplayer_authority():
		var host_id = multiplayer.get_unique_id()
		print("HOST: Spawning player for host ID: %s" % host_id)
		spawn(host_id)
		
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(remove_player)
	else:
		print("CLIENT: Requesting existing players from host...")
		rpc_id(1, "request_existing_players")

@rpc("any_peer")
func request_existing_players():
	var requesting_client = multiplayer.get_remote_sender_id()
	print("HOST: Client %s requesting existing players" % requesting_client)
	
	for peer_id in players.keys():
		var character_num = MultiplayerGlobal.player_character_selections.get(peer_id, 1)
		print("  -> Sending existing player %s (character %s) to client %s" % [peer_id, character_num, requesting_client])
		rpc_id(requesting_client, "receive_existing_player", peer_id, character_num)

@rpc("authority", "call_remote")
func receive_existing_player(peer_id: int, character_num: int):
	print("CLIENT: Received existing player %s with character %s" % [peer_id, character_num])
	
	if players.has(peer_id):
		print("  -> Already exists, skipping")
		return
	
	var p = player_Scene.instantiate()
	p.name = str(peer_id)
	p.set_multiplayer_authority(peer_id)
	
	# Add to scene FIRST
	get_node(_spawn_path.get_path()).add_child(p)
	players[peer_id] = p
	
	# Set mesh_num AFTER adding to tree
	await get_tree().process_frame  # Wait one frame to ensure _ready() has run
	if p.has_method("set"):
		p.set("mesh_num", character_num)
	else:
		p.mesh_num = character_num
	
	print("  -> Successfully spawned existing player %s" % peer_id)

func _on_peer_connected(id: int):
	if is_multiplayer_authority():
		print("HOST: Peer %s connected, spawning their player" % id)
		spawn(id)

func spawnPlayer(peer_id):
	if players.has(peer_id):
		print("WARNING: Player %s already exists, skipping spawn" % peer_id)
		return players[peer_id]
	
	print("Spawning player for peer ID: %s" % peer_id)
	var p = player_Scene.instantiate()
	p.name = str(peer_id)
	p.set_multiplayer_authority(peer_id)
	
	var character_num = MultiplayerGlobal.player_character_selections.get(peer_id, 1)
	print("Player %s spawning with character %s" % [peer_id, character_num])
	
	# Don't set mesh_num here - let _ready() handle it from the character selection
	# Or set it in a deferred way
	if p.has_method("set"):
		p.set("mesh_num", character_num)
		print("setting mesh_num ", p.mesh_num)
	
	players[peer_id] = p
	return p

func remove_player(peer_id):
	print("Removing player for peer ID: %s" % peer_id)
	if players.has(peer_id):
		players[peer_id].queue_free()
		players.erase(peer_id)

func make_local():
	_spawn_path.queue_free()
