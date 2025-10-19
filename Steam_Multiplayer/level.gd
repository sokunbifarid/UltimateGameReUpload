# level.tscn script
extends Node
#
#const player_scene = preload("uid://ce48elb3fsyic")
#
#func _ready():
	## Wait for multiplayer to be ready
	#if multiplayer.is_server():
		#multiplayer.peer_connected.connect(_add_player)
		#multiplayer.peer_disconnected.connect(_remove_player)
		#
		## Spawn player for server/host
		#_add_player(1)
	#
	## Spawn player for this client
	#if not multiplayer.is_server():
		#_add_player.call_deferred(multiplayer.get_unique_id())
#
#func _add_player(id: int):
	#var player = player_scene.instantiate()
	#player.name = str(id)
	#player.set_multiplayer_authority(id)
	#add_child(player)
	#print("Spawned player for peer: %s" % id)
#
#func _remove_player(id: int):
	#var player = get_node_or_null(str(id))
	#if player:
		#player.queue_free()
