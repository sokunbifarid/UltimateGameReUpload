extends MultiplayerSpawner

@export var player_Scene : PackedScene
@onready var label: Label = $"../Label"

var players = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_function = spawnPlayer
	if is_multiplayer_authority():
		spawn(1)
		multiplayer.peer_connected.connect(spawnPlayer)
		multiplayer.peer_disconnected.connect(remove_player)

func _process(delta: float) -> void:
	label.text = str(players)

func spawnPlayer(data):
	var p = player_Scene.instantiate()
	p.set_multiplayer_authority(data)
	players[data] = p
	return p

func remove_player(data):
	players[data].queue_free()
	players.erase(data)
