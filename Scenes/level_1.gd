extends Node3D
@export var enviroment : PackedScene
@onready var world_environment: WorldEnvironment = $waiting_room/WorldEnvironment
@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

@export var level_spawn_point: Node3D
@onready var waiting_spawn_path: Node3D = $waiting_room/spawn_path
@onready var waiting_room: Node3D = $waiting_room

func _ready() -> void:
	pass

func shift_to_level():
	world_environment.queue_free()
	add_child(enviroment.instantiate())
	multiplayer_spawner.spawn_path = level_spawn_point.get_path()
	multiplayer_spawner._spawn_path = level_spawn_point
	waiting_room.queue_free()

	for player : CharacterBody3D in waiting_spawn_path.get_children():
		player.global_position = level_spawn_point.global_position
		player.reparent(level_spawn_point)
