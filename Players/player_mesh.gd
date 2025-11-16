extends Node3D

@onready var multi_sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multi_sync.set_multiplayer_authority(str(get_parent().name).to_int())
