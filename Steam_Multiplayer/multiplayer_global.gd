extends Node

var player_character_selections: Dictionary = {}  # {peer_id: character_num}
var selected_level : PackedScene 
var selected_player : PackedScene = preload("res://Players/player.tscn")
var selected_lobby 
var selected_player_num : int = 1 
var joined_lobby_id

var players_meshes: Dictionary = {
	1:null,
	2:preload("res://Players/red_player.tscn"),
	3:preload("res://Players/blue_player.tscn")
}

func set_my_character_selection(character_num: int):
	var my_id = multiplayer.get_unique_id()
	player_character_selections[my_id] = character_num
	# Broadcast to server
	rpc_id(1, "register_character_selection", my_id, character_num)

@rpc("any_peer")
func register_character_selection(peer_id: int, character_num: int):
	player_character_selections[peer_id] = character_num
	print("Player %s selected character %s" % [peer_id, character_num])
