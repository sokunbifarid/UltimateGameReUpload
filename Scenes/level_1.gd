extends Node3D
@export var enviroment : PackedScene
@onready var world_environment: WorldEnvironment = $waiting_room/WorldEnvironment
@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

@export var level_spawn_point: Node3D
@onready var waiting_spawn_path: Node3D = $waiting_room/spawn_path
@onready var waiting_room: Node3D = $waiting_room
@onready var players_names: VBoxContainer = $Control/players_names

func _ready() -> void:
	var random_x = randf_range(level_spawn_point.global_position.x - 1, level_spawn_point.global_position.x + 1)
	var random_z = randf_range(level_spawn_point.global_position.z - 1, level_spawn_point.global_position.z + 1)
	var new_pos = Vector3(random_x, level_spawn_point.global_position.y, random_z)
	
	level_spawn_point.global_position = new_pos

#func _process(delta: float) -> void:
	#update_players_ui()


@rpc("authority", "call_local", "reliable")
func shift_to_level():
	"""Transitions from waiting room to actual game level - called by host, executed on all clients"""
	print("Shifting to level...")
	
	# Remove waiting room environment
	if world_environment and is_instance_valid(world_environment):
		world_environment.queue_free()
	
	# Add game environment
	if enviroment:
		var env_instance = enviroment.instantiate()
		add_child(env_instance)
	
	# Update spawner to use level spawn point
	if multiplayer_spawner and level_spawn_point:
		multiplayer_spawner.spawn_path = level_spawn_point.get_path()
	
	# Move all players from waiting room to level
	if waiting_spawn_path and level_spawn_point:
		for player in waiting_spawn_path.get_children():
			if player is CharacterBody3D:
				print("Moving player %s to level spawn" % player.name)
				player.move_to_level()
				player.reparent(level_spawn_point)
	
	# Remove waiting room
	if waiting_room and is_instance_valid(waiting_room):
		waiting_room.queue_free()
	
	print("Level transition complete!")
func update_players_ui():
	"""Updates the list of players in the waiting room"""
	if not Multiplayer:
		return
	
	# Clear existing labels
	for child in players_names.get_children():
		child.queue_free()
	
	# Add label for each player
	var players = Multiplayer.get_current_players()
	for player in players:
		var player_label = Label.new()
		player_label.text = " " + str(player.steam_name)
		players_names.add_child(player_label)
func make_local():
	"""Making it local, removing waiting level and adding enviroment"""
	print("Make level local ...")
	
	# Remove waiting room environment
	if world_environment and is_instance_valid(world_environment):
		world_environment.queue_free()
	
	# Add game environment
	if enviroment:
		var env_instance = enviroment.instantiate()
		add_child(env_instance)
	if waiting_room:
		waiting_room.queue_free()
