extends MultiplayerSpawner

@export var player_Scene : PackedScene
@export var _spawn_path : Node3D
@export var player_stats_holder: Control

const PLAYER_MATCH_STATS = preload("res://Scenes/player_match_stats.tscn")
#@onready var label: Label = $"../Label"
#@onready var player_spawn_point: Node3D = $"../Node3D"

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
		print("waiting for host to spawn my character")

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
	set_player_match_stats_node(p, peer_id)
	
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
		remove_player_match_stats_node(peer_id)

func make_local():
	_spawn_path.queue_free()

func set_player_match_stats_node(player: CharacterBody3D, peer_id: int):
	if ScenesGlobal.current_match_type == ScenesGlobal.MATCH_TYPE.ONLINE:
		if is_multiplayer_authority():
			var player_data: VBoxContainer = PLAYER_MATCH_STATS.instantiate()
			player_stats_holder.add_child(player_data)
			print("assigned, player_health: " + str(player.health))
			player_data.set_monitor(player)

func remove_player_match_stats_node(peer_id: int):
	if ScenesGlobal.current_match_type == ScenesGlobal.MATCH_TYPE.ONLINE:
		if is_multiplayer_authority():
			player_stats_holder.get_child(0).queue_free()
