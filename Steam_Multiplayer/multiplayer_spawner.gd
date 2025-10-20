extends MultiplayerSpawner

@export var player_Scene : PackedScene
@onready var label: Label = $"../Label"

var players = {}

func _ready() -> void:
	spawn_function = spawnPlayer
	
	# Wait for multiplayer to be set up
	if multiplayer.multiplayer_peer:
		_setup_spawner()
	else:
		# Wait for peer to be created
		await get_tree().create_timer(0.5).timeout
		_setup_spawner()

func _setup_spawner():
	print("Setting up spawner, authority: %s, unique_id: %s" % [is_multiplayer_authority(), multiplayer.get_unique_id()])
	
	if is_multiplayer_authority():
		# HOST: Spawn player for the server/host
		var host_id = multiplayer.get_unique_id()
		print("HOST: Spawning player for host ID: %s" % host_id)
		spawn(host_id)
		
		# Connect signals for when other players join/leave
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(remove_player)
	else:
		# CLIENT: Do nothing - wait for host to spawn us
		print("CLIENT: Waiting for host to spawn my player...")

func _on_peer_connected(id: int):
	# Only spawn if we're the server/host
	if is_multiplayer_authority():
		print("HOST: Peer %s connected, spawning their player" % id)
		spawn(id)

func _process(delta: float) -> void:
	label.text = "Players: " + str(players.keys())

func spawnPlayer(peer_id):
	# Prevent duplicate spawns
	if players.has(peer_id):
		print("WARNING: Player %s already exists, skipping spawn" % peer_id)
		return players[peer_id]
	
	print("Spawning player for peer ID: %s" % peer_id)
	var p = player_Scene.instantiate()
	p.name = "Player_" + str(peer_id)
	p.set_multiplayer_authority(peer_id)
	
	# Set spawn position based on number of players
	var spawn_offset = Vector3(players.size() * 3.0, 1, 0)
	p.position = spawn_offset
	
	players[peer_id] = p
	print("Player spawned at position: %s with authority: %s" % [spawn_offset, peer_id])
	return p

func remove_player(peer_id):
	print("Removing player for peer ID: %s" % peer_id)
	if players.has(peer_id):
		players[peer_id].queue_free()
		players.erase(peer_id)
